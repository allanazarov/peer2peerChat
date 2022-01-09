import Foundation
import Network

// MARK: -
public final class LocalPeerListener {
  private var listener: NWListener?
  private let queue: DispatchQueue
  private var isRestarting = false
  
  public weak var delegate: LocalPeerListenerDelegate?
  public var port: NWEndpoint.Port? { listener?.port }
  
  public func start() {
    precondition(listener == nil)
    
    let tcpOptions = NWProtocolTCP.Options()
    tcpOptions.enableKeepalive = true
    tcpOptions.keepaliveIdle = 2
    
    let webSocketOptions = NWProtocolWebSocket.Options.default

    let parameters = NWParameters(tls: nil, tcp: tcpOptions)
    parameters.includePeerToPeer = true
    parameters.defaultProtocolStack.applicationProtocols.insert(webSocketOptions, at: 0)
    
    let listener: NWListener
    do {
      listener = try NWListener(using: parameters)
    } catch {
      preconditionFailure()
    }
    listener.service = .init(type: "_ibrosTest._tcp")
    listener.stateUpdateHandler = { [unowned self] (newState) in stateUpdate(with: newState) }
    listener.newConnectionHandler = { [unowned self] (connection) in recieveNewConnection(connection) }
    listener.start(queue: queue)
    
    self.listener = listener
  }
  public func stop() {
    listener?.cancel()
  }
  
  public init(queue: DispatchQueue = .main) {
    self.queue = queue
  }
  
  deinit {
    stop()
  }
}

extension LocalPeerListener {
  private func stateUpdate(with state: NWListener.State) {
    switch state {
    case .ready:
      isRestarting = false
      delegate?.localPeerListenerIsReady(self)

    case .failed(let error):
      if error == NWError.dns(.init(kDNSServiceErr_DefunctConnection)) {
        isRestarting = true
        stop()
      } else {
        delegate?.localPeerListener(self, didFailedWith: error)
        stop()
      }
      
    case .cancelled:
      delegate?.localPeerListenerDidCancelled(self, isRestarting: isRestarting)
      if isRestarting {
        listener = nil
        start()
      }
      
    default:
      break
    }
  }
}

extension LocalPeerListener {
  private func recieveNewConnection(_ connection: NWConnection) {
    delegate?.localPeerListener(self, didRecieveNew: connection)
  }
}

// MARK: -
public protocol LocalPeerListenerDelegate: AnyObject {
  func localPeerListenerIsReady(_ listener: LocalPeerListener)
  func localPeerListener(_ listener: LocalPeerListener, didRecieveNew connection: NWConnection)
  func localPeerListener(_ listener: LocalPeerListener, didFailedWith error: NWError)
  func localPeerListenerDidCancelled(_ listener: LocalPeerListener, isRestarting: Bool)
}
