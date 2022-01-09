import Foundation
import Network

// MARK: -
public final class LocalPeerDiscover {
  private var browser: NWBrowser?
  private let queue: DispatchQueue
  private var isRestarting = false
  
  public weak var delegate: LocalPeerDiscoverDelegate?
  
  public func start() {
    precondition(browser == nil)
    
    let parameters = NWParameters()
    parameters.includePeerToPeer = true
    
    let browser = NWBrowser(for: .bonjour(type: "_ibrosTest._tcp", domain: nil), using: parameters)
    browser.stateUpdateHandler = { [unowned self] (newState) in stateUpdate(with: newState) }
    browser.browseResultsChangedHandler = { [unowned self] (newResults, changes) in browseResultsChanged(results: newResults, changes: changes) }
    browser.start(queue: queue)
    
    self.browser = browser
  }
  public func stop() {
    browser?.cancel()
  }
  
  public init(queue: DispatchQueue = .main) {
    self.queue = queue
  }
  
  deinit {
    stop()
  }
}

extension LocalPeerDiscover {
  private func stateUpdate(with state: NWBrowser.State) {
    switch state {
    case .ready:
      delegate?.localPeerDiscoverIsReady(self)
      
    case .failed(let error):
      if error == NWError.dns(.init(kDNSServiceErr_DefunctConnection)) {
        isRestarting = true
        stop()
      } else {
        delegate?.localPeerDiscover(self, didFailedWith: error)
        stop()
      }
      
    case .cancelled:
      delegate?.localPeerDiscoverDidCancelled(self, isRestarting: isRestarting)
      if isRestarting {
        browser = nil
        start()
      }
      
    default:
      break
    }
  }
  private func browseResultsChanged(results: Set<NWBrowser.Result>, changes: Set<NWBrowser.Result.Change>) {
    delegate?.localPeerDiscover(self, didRecieveNew: results)
  }
}

// MARK: -
public protocol LocalPeerDiscoverDelegate: AnyObject {
  func localPeerDiscoverIsReady(_ discover: LocalPeerDiscover)
  func localPeerDiscover(_ discover: LocalPeerDiscover, didRecieveNew results: Set<NWBrowser.Result>)
  func localPeerDiscover(_ discover: LocalPeerDiscover, didFailedWith error: NWError)
  func localPeerDiscoverDidCancelled(_ discover: LocalPeerDiscover, isRestarting: Bool)
}
