//
//  MainTableViewController.swift
//  peer2peerChat
//
//  Created by Ibrokhimbek Allanazarov on 09.01.2022.
//

import UIKit
import Drops
import Network
import LocalPeer
import Resolvers

// MARK: -
final class MainTableViewController: UIViewController {
  private var activeHost: Host?
  
  private var hosts: [Host] = []
  private var selectedHost: Host?
  
  private var dataSource: Datasource!
  
  private(set) lazy var tableView: MainTableView = view as! MainTableView
  
  override func loadView() {
    view = MainTableView(frame: .zero)
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    
    dataSource = .init(tableView: tableView) { [unowned self] (tableView, indexPath, itemIdentifier) in cell(tableView: tableView, indexPath: indexPath, itemIdentifier: itemIdentifier) }
    tableView.delegate = self
  }
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
      if  Application.shared.activeConnection?.initiatedConnection == false {
          Application.shared.sharedListener?.stop()
      }
    
    navigationController?.navigationBar.prefersLargeTitles = true
    navigationItem.title = "peer2peerChat"
    
    var snapshot = Snapshot()
    snapshot.appendSections([.host, .join])
    snapshot.appendItems([.buttonCreateHost(isActive: true)], toSection: .host)
    snapshot.appendItems([.buttonFindingHosts(isActive: true)], toSection: .join)
    dataSource.apply(snapshot, animatingDifferences: animated)
    
//    Application.shared.sharedListener = .init()
  }
}

extension MainTableViewController {
  private func cell(tableView: UITableView, indexPath: IndexPath, itemIdentifier: Item) -> UITableViewCell? {
    switch itemIdentifier {
    case .buttonCreateHost(let isActive):
      let cell = tableView.dequeueReusableCell(withIdentifier: "buttonCell", for: indexPath) as! ButtonTableViewCell
      if isActive {
        cell.configure(title: "Create Chat")
      } else {
        cell.nonActiveConfigure(title: "Create Chat")
      }
      return cell
      
    case .buttonFindingHosts(let isActive):
      let cell = tableView.dequeueReusableCell(withIdentifier: "buttonCell", for: indexPath) as! ButtonTableViewCell
      if isActive {
        cell.configure(title: "Find Chats")
      } else {
        cell.nonActiveConfigure(title: "Find Chats")
      }
      return cell
      
    case .buttonCancelHost, .buttonCancelFindingHosts:
      let cell = tableView.dequeueReusableCell(withIdentifier: "buttonCell", for: indexPath) as! ButtonTableViewCell
      cell.configure(title: "Cancel", isDestructive: true)
      return cell
      
    case .buttonInputHost:
      let cell = tableView.dequeueReusableCell(withIdentifier: "buttonCell", for: indexPath) as! ButtonTableViewCell
      cell.configure(title: "Input Host Address Directly")
      return cell
      
    case .host(let value):
      let sectionIdentifier = dataSource.snapshot().sectionIdentifiers[indexPath.section]
      
      if sectionIdentifier == .hostAddress {
        let cell = tableView.dequeueReusableCell(withIdentifier: "namelessHostCell", for: indexPath) as! NamelessHostTableViewCell
        cell.configure(ipAddress: value.ipAddress.debugDescription, port: value.port.debugDescription )
        return cell
      } else if sectionIdentifier == .joinHosts {
        let cell = tableView.dequeueReusableCell(withIdentifier: "hostCell", for: indexPath) as! HostTableViewCell
        cell.configure(name: value.name, ipAddress: value.ipAddress.debugDescription, port: value.port.debugDescription)
        return cell
      }
      else {
        preconditionFailure()
      }
    }
  }
}



extension MainTableViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    UITableView.automaticDimension
  }
  func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    UITableView.automaticDimension
  }
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch dataSource.itemIdentifier(for: indexPath) {
    case .buttonCreateHost(let isActive):
      guard isActive else { break }
      var snapshot = Snapshot()
      snapshot.appendSections([.hostActive, .join])
      snapshot.appendItems([.buttonCancelHost], toSection: .hostActive)
      snapshot.appendItems([.buttonFindingHosts(isActive: false)], toSection: .join)
      dataSource.apply(snapshot, animatingDifferences: true) { [unowned self] in
        
        Application.shared.sharedListener = .init()
        Application.shared.sharedListener!.delegate = self
        Application.shared.sharedListener!.start()
      }
      
    case .buttonFindingHosts(let isActive):
      guard isActive else { break }
      var snapshot = Snapshot()
      snapshot.appendSections([.host, .joinActive, .joinInput])
      snapshot.appendItems([.buttonCreateHost(isActive: false)], toSection: .host)
      snapshot.appendItems([.buttonCancelFindingHosts], toSection: .joinActive)
      snapshot.appendItems([.buttonInputHost], toSection: .joinInput)
      dataSource.apply(snapshot, animatingDifferences: true) { [unowned self] in
          
        Application.shared.sharedDiscover = .init()
        Application.shared.sharedDiscover!.delegate = self
        Application.shared.sharedDiscover!.start()
      }
      
    case .buttonCancelHost:
      var snapshot = Snapshot()
      snapshot.appendSections([.host, .join])
      snapshot.appendItems([.buttonCreateHost(isActive: true)], toSection: .host)
      snapshot.appendItems([.buttonFindingHosts(isActive: true)], toSection: .join)
      dataSource.apply(snapshot, animatingDifferences: true) { [unowned self] in
        activeHost = nil
        Application.shared.sharedListener!.stop()
      }
      
    case .buttonCancelFindingHosts:
      var snapshot = Snapshot()
      snapshot.appendSections([.host, .join])
      snapshot.appendItems([.buttonCreateHost(isActive: true)], toSection: .host)
      snapshot.appendItems([.buttonFindingHosts(isActive: true)], toSection: .join)
      dataSource.apply(snapshot, animatingDifferences: true) { [unowned self] in
        hosts.removeAll()
        Application.shared.sharedDiscover!.stop()
      }
      
    case .buttonInputHost:
      let alertController = UIAlertController(title: "Input Host Address", message: nil, preferredStyle: .alert)
      alertController.addTextField {
        $0.placeholder = "IP:PORT"
        $0.keyboardType = .numbersAndPunctuation
      }
      alertController.addAction(.init(title: "Join", style: .default, handler: { [self] _ in
          let text = alertController.textFields?[0].text ?? ""
          var ipString = ""
          var portString = ""
          if let colonIndex = text.firstIndex(of: ":") {
              ipString = String(text[text.startIndex ..< colonIndex])
              portString = String(text[text.index(after: colonIndex)...])
          }
          guard let ipAddress = IPv4Address.init(ipString), let port = NWEndpoint.Port(portString) else {
              return
          }
          
          Application.shared.sharedDiscover?.stop()
          selectedHost = .init(name: ipString, ipAddress: ipAddress, port:port)
          Application.shared.activeConnection = .init(endpoint: selectedHost!.endpoint)
          Application.shared.activeConnection!.delegate = self
          Application.shared.activeConnection!.start()
      }))
      alertController.addAction(.init(title: "Cancel", style: .cancel, handler: { _ in
        alertController.dismiss(animated: true) {
         
        }
      }))
      tableView.deselectRow(at: indexPath, animated: true)
      present(alertController, animated: true, completion: nil)
      
    case .host(let value):
      let sectionIdentifier = dataSource.snapshot().sectionIdentifiers[indexPath.section]
      
      if sectionIdentifier == .hostAddress {
        Drops.hideAll()
        let drop = Drop(title: "Host address copied", action: .init {
          Drops.hideCurrent()
        })
        Drops.show(drop)
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        #if targetEnvironment(simulator)
        // FIXME: ???
        #else
        UIPasteboard.general.string = "\(value.ipAddress):\(value.port)"
        #endif
      } else {
        tableView.deselectRow(at: indexPath, animated: true)
        
        selectedHost = value
        Application.shared.sharedDiscover?.stop()
        Application.shared.activeConnection = .init(endpoint: value.endpoint)
        Application.shared.activeConnection!.delegate = self
        Application.shared.activeConnection!.start()
      }
      
    default:
      break
    }
  }
}

extension MainTableViewController: LocalPeerListenerDelegate {
  func localPeerListenerIsReady(_ listener: LocalPeerListener) {
    ListenerResolver.resolve(listener: Application.shared.sharedListener!) { [unowned self] (result) in
      switch result {
      case .success(let value):
        activeHost = .init(name: UIDevice.current.name, ipAddress: value.ipAddress, port: value.port)
        
        var snapshot = Snapshot()
        snapshot.appendSections([.hostActive, .hostAddress, .join])
        snapshot.appendItems([.buttonCancelHost], toSection: .hostActive)
        snapshot.appendItems([.host(activeHost!)], toSection: .hostAddress)
        snapshot.appendItems([.buttonFindingHosts(isActive: false)], toSection: .join)
        dataSource.apply(snapshot, animatingDifferences: true)
        
      case .failure(let error):
        print(error)
      }
    }
  }
  func localPeerListener(_ listener: LocalPeerListener, didRecieveNew connection: NWConnection) {
    Application.shared.activeConnection = .init(connection: connection)
    Application.shared.activeConnection!.delegate = self
    Application.shared.activeConnection!.start()
  }
  func localPeerListener(_ listener: LocalPeerListener, didFailedWith error: NWError) {
    print(error)
  }
  func localPeerListenerDidCancelled(_ listener: LocalPeerListener, isRestarting: Bool) {
      Application.shared.activeConnection?.stop()
  }
}

extension MainTableViewController: LocalPeerDiscoverDelegate {
  func localPeerDiscoverIsReady(_ discover: LocalPeerDiscover) {
    
  }
  func localPeerDiscover(_ discover: LocalPeerDiscover, didRecieveNew results: Set<NWBrowser.Result>) {
    hosts.removeAll()

    if !results.isEmpty {
      let group = DispatchGroup()
      
      for result in results {
        guard case let .service(name, type, domain, _) = result.endpoint else { return }
        group.enter()
        BonjourResolver.resolve(service: .init(domain: domain, type: type, name: name)) { [unowned self] (result) in
          switch result {
          case .success(let value):
            guard !hosts.contains(where: { $0.ipAddress == value.ipAddress }) else { break }
            hosts.append(.init(name: name, ipAddress: value.ipAddress, port: value.port))
            
          case .failure(let error):
            print(error)
          }
          
          group.leave()
        }
      }

      
      group.notify(queue: .main) { [self] in
        var snapshot = Snapshot()
        snapshot.appendSections([.host, .joinActive, .joinInput, .joinHosts])
        snapshot.appendItems([.buttonCreateHost(isActive: false)], toSection: .host)
        snapshot.appendItems([.buttonCancelFindingHosts], toSection: .joinActive)
        snapshot.appendItems([.buttonInputHost], toSection: .joinInput)
        snapshot.appendItems(hosts.map { .host($0) }, toSection: .joinHosts)
        dataSource.apply(snapshot, animatingDifferences: true)
      }
    } else {
      var snapshot = Snapshot()
      snapshot.appendSections([.host, .joinActive, .joinInput])
      snapshot.appendItems([.buttonCreateHost(isActive: false)], toSection: .host)
      snapshot.appendItems([.buttonCancelFindingHosts], toSection: .joinActive)
      snapshot.appendItems([.buttonInputHost], toSection: .joinInput)
      dataSource.apply(snapshot, animatingDifferences: true)
    }
  }
  func localPeerDiscover(_ discover: LocalPeerDiscover, didFailedWith error: NWError) {
    print(error)
  }
  func localPeerDiscoverDidCancelled(_ discover: LocalPeerDiscover, isRestarting: Bool) {
    
  }
}

extension MainTableViewController: LocalPeerConnectionDelegate {
  func localPeerConnectionDidConnected(_ connection: LocalPeerConnection) {
    if connection.initiatedConnection {
      connection.send(message: UIDevice.current.name)
      
      Drops.hideAll()
      let drop = Drop(title: "Successfully joined to host", subtitle: "Tap to Go", action: .init { [self] in
        Drops.hideCurrent()
        navigationController?.pushViewController(ChatCollectionViewController(name: selectedHost!.name), animated: true)
      }, duration: .seconds(.infinity))
      
      Drops.show(drop)
    }
  }
  func localPeerConnectiondDidDisconnected(_ connection: LocalPeerConnection) {
    
  }
  func localPeerConnection(_ connection: LocalPeerConnection, didReceivedMessage message: String) {
    if !connection.initiatedConnection && navigationController?.topViewController === self {
      Drops.hideAll()
      let drop = Drop(title: "Someone successfully joined", subtitle: "Tap to Go", action: .init { [self] in
        Drops.hideCurrent()
        navigationController?.pushViewController(ChatCollectionViewController(name: message), animated: true)
      }, duration: .seconds(.infinity))

      Drops.show(drop)
    }
  }
  func localPeerConnection(_ connection: LocalPeerConnection, didFailedWith error: NWError) {
    print(error)
  }
}


// MARK: -
typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

// MARK: -
enum Section: Hashable {
  case host
  case hostActive
  case hostAddress
  
  case join
  case joinActive
  case joinInput
  case joinHosts
}

// MARK: -
enum Item: Hashable {
  case buttonCreateHost(isActive: Bool)
  case buttonCancelHost
  
  case buttonFindingHosts(isActive: Bool)
  case buttonCancelFindingHosts
  case buttonInputHost
  
  case host(Host)
}

// MARK: -
struct Host: Identifiable, Hashable {
  var id: Int { ipAddress.hashValue }
  let name: String
  let ipAddress: IPv4Address
  let port: NWEndpoint.Port
  var endpoint: NWEndpoint { .url(.init(string: "ws://\(ipAddress.debugDescription):\(port.debugDescription)")!) }
}

// MARK: -
final class Datasource: UITableViewDiffableDataSource<Section, Item> {
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    switch snapshot().sectionIdentifiers[section] {
    case .host:
      return "HOST CHAT"
      
    case .hostActive:
      return "HOST CHAT - Waiting for connection..."
      
      
    case .join:
      return "JOIN CHAT"
      
      
    case .joinActive:
      return "JOIN CHAT - Finding active hosts..."
      
    default:
      return nil
    }
  }
  override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    switch snapshot().sectionIdentifiers[section] {
    case .hostAddress:
      return "Although current host address appears in the lists of available host addresses, you can still transfer and enter it manually on another device."
      
    case .joinInput:
      return "You can directly enter the address if, for some reason, device you are interested in is not in the list of those found below."
      
    default:
      return nil
    }
  }
  override init(tableView: UITableView, cellProvider: @escaping UITableViewDiffableDataSource<Section, Item>.CellProvider) {
    super.init(tableView: tableView, cellProvider: cellProvider)
    defaultRowAnimation = .fade
  }
}
