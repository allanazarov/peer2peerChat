import Foundation
import Network

// MARK: -
public final class BonjourResolver: NSObject {
  private var shared: BonjourResolver?
  
  private var service: NetService?
  private var completionHandler: ((_ result: Result<(ipAddress: IPv4Address, port: NWEndpoint.Port), Error>) -> Void)?

  @discardableResult
  public static func resolve(service: NetService, completionHandler: @escaping (_ result: Result<(ipAddress: IPv4Address, port: NWEndpoint.Port), Error>) -> Void) -> BonjourResolver {
    precondition(Thread.isMainThread)
    
    let resolver = BonjourResolver(service: service, completionHandler: completionHandler)
    resolver.start()
    return resolver
  }
  
  public func stop() {
    stop(with: .failure(CocoaError(.userCancelled)))
  }
  
  private init(service: NetService, completionHandler: @escaping (_ result: Result<(ipAddress: IPv4Address, port: NWEndpoint.Port), Error>) -> Void) {
    let copy = NetService(domain: service.domain, type: service.type, name: service.name)
    self.service = copy
    self.completionHandler = completionHandler
  }
  
  deinit {
    precondition(service == nil)
    precondition(completionHandler == nil)
    precondition(shared == nil)
  }
}

extension BonjourResolver {
  private func start() {
    precondition(Thread.isMainThread)

    guard let service = self.service else { fatalError() }
    service.delegate = self
    service.resolve(withTimeout: 5.0)

    shared = self
  }
}

extension BonjourResolver {
  private func stop(with result: Result<(ipAddress: IPv4Address, port: NWEndpoint.Port), Error>) {
    precondition(Thread.isMainThread)
    
    service?.delegate = nil
    service?.stop()
    service = nil
    
    let completionHandler = self.completionHandler
    self.completionHandler = nil
    completionHandler?(result)
    
    shared = nil
  }
}

extension BonjourResolver: NetServiceDelegate {
  public func netServiceDidResolveAddress(_ sender: NetService) {
    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
    
    guard let data = sender.addresses?.first else { stop(with: .failure(CocoaError(.executableRuntimeMismatch))); return }
    data.withUnsafeBytes { (pointer) -> Void in
      let sockaddrPtr = pointer.bindMemory(to: sockaddr.self)
      guard let unsafePtr = sockaddrPtr.baseAddress else { stop(with: .failure(CocoaError(.executableRuntimeMismatch))); return }
      guard getnameinfo(unsafePtr,
                        socklen_t(data.count),
                        &hostname,
                        socklen_t(hostname.count),
                        nil,
                        0,
                        NI_NUMERICHOST) == 0
      else { stop(with: .failure(CocoaError(.executableRuntimeMismatch))); return }
    }
    
    guard let ipAddress =  IPv4Address(.init(cString: hostname)) else { stop(with: .failure(CocoaError(.executableRuntimeMismatch))); return }
    let port = NWEndpoint.Port(integerLiteral: .init(sender.port))
    
    stop(with: .success((ipAddress, port)))
  }
  public func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
    let code = (errorDict[NetService.errorCode]?.intValue).flatMap { NetService.ErrorCode(rawValue: $0) } ?? .unknownError
    let error = NSError(domain: NetService.errorDomain, code: code.rawValue, userInfo: nil)
    
    stop(with: .failure(error))
  }
}
