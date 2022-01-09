import Foundation
import Network

// MARK: -
public final class LocalPeerConnection {
  private var connection: NWConnection?
  private var queue: DispatchQueue
  
  public let initiatedConnection: Bool
  public weak var delegate: LocalPeerConnectionDelegate?
  
  public func start() {
    guard let connection = connection else { preconditionFailure() }
    precondition(connection.state == .setup)
    
    connection.stateUpdateHandler = { [unowned self] (newState) in stateUpdate(with: newState) }
    connection.viabilityUpdateHandler = { [unowned self] (isViable) in viabilityUpdate(with: isViable) }
    listen()
    connection.start(queue: queue)
  }
  public func stop() {
    connection?.cancel()
  }
  //
  public func send(message: String) {
    guard let connection = connection else { preconditionFailure() }
    precondition(connection.state == .ready)
    
    guard let data = message.data(using: .utf8) else { return }
    let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
    let contentContext = NWConnection.ContentContext(identifier: "textContext", metadata: [metadata])
    
    connection.send(content: data, contentContext: contentContext, isComplete: true, completion: .contentProcessed({ [unowned self] (error) in
      if let socketMetadata = contentContext.protocolMetadata.first as? NWProtocolWebSocket.Metadata, socketMetadata.opcode == .close {
        delegate?.localPeerConnectiondDidDisconnected(self)
      }
      
      if let error = error {
        delegate?.localPeerConnection(self, didFailedWith: error)
      }
    }))
  }
  
  // Inbound
  public init(connection: NWConnection, queue: DispatchQueue = .main) {
    self.initiatedConnection = false
    self.queue = queue
    
    self.connection = connection
  }
  
  // Outbound
  public init(endpoint: NWEndpoint, options: NWProtocolWebSocket.Options = .default, queue: DispatchQueue = .main) {
    self.initiatedConnection = true
    self.queue = queue
    
    let tcpOptions = NWProtocolTCP.Options()
    tcpOptions.enableKeepalive = true
    tcpOptions.keepaliveIdle = 2
    
    let webSocketOptions = options
 
    let parameters = NWParameters(tls: nil, tcp: tcpOptions)
    parameters.includePeerToPeer = true
    parameters.defaultProtocolStack.applicationProtocols.insert(webSocketOptions, at: 0)
    
    self.connection = .init(to: endpoint, using: parameters)
  }
  
  deinit {
    stop()
  }
}

extension LocalPeerConnection {
  private func stateUpdate(with state: NWConnection.State) {
    switch state {
    case .ready:
      listen()
      delegate?.localPeerConnectionDidConnected(self)
      
    case .failed(let error):
      delegate?.localPeerConnection(self, didFailedWith: error)
      
    case .cancelled:
      delegate?.localPeerConnectiondDidDisconnected(self)
      connection = nil
      
    default:
      break
    }
  }
  private func viabilityUpdate(with isViable: Bool) {
    // TODO:
  }
}

extension LocalPeerConnection {
  private func listen() {
    guard let connection = connection else { preconditionFailure() }
    
    connection.receiveMessage { [weak self] (completeContent, contentContext, isComplete, error) in
        guard let self = self else { return }
        
      if let completeContent = completeContent, !completeContent.isEmpty, let contentContext = contentContext {
        guard let metadata = contentContext.protocolMetadata.first as? NWProtocolWebSocket.Metadata else { return }
        
        switch metadata.opcode {
        case .text:
          guard let text = String(data: completeContent, encoding: .utf8) else { return }
            self.delegate?.localPeerConnection(self, didReceivedMessage: text)
          
        case .close:
            self.delegate?.localPeerConnectiondDidDisconnected(self)
          
        default:
          break
        }
      }
      
      if let error = error {
          self.delegate?.localPeerConnection(self, didFailedWith: error)
      } else {
          self.listen()
      }
    }
  }
}

// MARK: -
public protocol LocalPeerConnectionDelegate: AnyObject {
  func localPeerConnectionDidConnected(_ connection: LocalPeerConnection)
  func localPeerConnectiondDidDisconnected(_ connection: LocalPeerConnection)
  func localPeerConnection(_ connection: LocalPeerConnection, didReceivedMessage message: String)
  func localPeerConnection(_ connection: LocalPeerConnection, didFailedWith error: NWError)
}
