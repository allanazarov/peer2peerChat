import Foundation
import Network
import LocalPeer

public final class ListenerResolver {
  private var shared: ListenerResolver?
  
  private var monitor: NWPathMonitor?
  private var listener: LocalPeerListener?
  private var completionHandler: ((_ result: Result<(ipAddress: IPv4Address, port: NWEndpoint.Port), Error>) -> Void)?
  
  @discardableResult
  public static func resolve(listener: LocalPeerListener, completionHandler: @escaping (_ result: Result<(ipAddress: IPv4Address, port: NWEndpoint.Port), Error>) -> Void) -> ListenerResolver {
    precondition(Thread.isMainThread)
    
    let resolver = ListenerResolver(listener: listener, completionHandler: completionHandler)
    resolver.start()
    return resolver
  }
  
  public func stop() {
    stop(with: .failure(CocoaError(.userCancelled)))
  }
  
  private init(listener: LocalPeerListener,  completionHandler: @escaping (_ result: Result<(ipAddress: IPv4Address, port: NWEndpoint.Port), Error>) -> Void) {
    self.listener = listener
    self.completionHandler = completionHandler
  }
  
  deinit {
    precondition(monitor == nil)
    precondition(listener == nil)
    precondition(shared == nil)
  }
}

extension ListenerResolver {
  private func start() {
    precondition(Thread.isMainThread)
    
    monitor = .init()
    monitor?.pathUpdateHandler = { [unowned self ] (newPath) in pathUpdate(with: newPath) }
    monitor?.start(queue: .main)
    
    shared = self
  }
}

extension ListenerResolver {
  private func stop(with result: Result<(ipAddress: IPv4Address, port: NWEndpoint.Port), Error>) {
    precondition(Thread.isMainThread)
    
    monitor?.cancel()
    monitor = nil
    
    listener = nil
    
    let completionHandler = self.completionHandler
    self.completionHandler = nil
    completionHandler?(result)
    
    shared = nil
  }
}

extension ListenerResolver {
  private func pathUpdate(with newPath: NWPath) {
    guard let name = newPath.availableInterfaces.first?.name,
          let type = newPath.availableInterfaces.first?.type,
          type == .wifi || type == .wiredEthernet
    else {
      stop(with: .failure(CocoaError(.executableRuntimeMismatch)))
      return
    }
    
    stop(with: resolve(onNetworkInterface: name))
  }
}

extension ListenerResolver {
  private func resolve(onNetworkInterface networkInterface: String) -> Result<(ipAddress: IPv4Address, port: NWEndpoint.Port), Error> {
    var ipAddressRawValue = ""
    
    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
      return .failure(CocoaError(.executableRuntimeMismatch))
    }
    
    for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
      let interface = ifptr.pointee
      let addrFamily = interface.ifa_addr.pointee.sa_family
      if addrFamily == UInt8(AF_INET) {
        let name = String(cString: interface.ifa_name)
        if name == networkInterface {
          var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
          getnameinfo(interface.ifa_addr,
                      socklen_t(interface.ifa_addr.pointee.sa_len),
                      &hostname,
                      socklen_t(hostname.count),
                      nil, socklen_t(0),
                      NI_NUMERICHOST)
          ipAddressRawValue = .init(cString: hostname)
        }
      }
    }
    freeifaddrs(ifaddr)
    
    guard let ipAddress = IPv4Address(ipAddressRawValue),
          let port = listener?.port
    else { return .failure(CocoaError(.executableRuntimeMismatch)) }
    
    return .success((ipAddress, port))
  }
}
