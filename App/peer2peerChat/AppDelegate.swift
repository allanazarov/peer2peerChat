//
//  AppDelegate.swift
//  peer2peerChat
//
//  Created by Ibrokhimbek Allanazarov on 09.01.2022.
//

import UIKit
import CoreData
import LocalPeer

// MARK: -
final class Application: UIApplication {
  override static var shared: Application {  unsafeDowncast(super.shared, to: Application.self) }
  
  var sharedListener: LocalPeerListener?
  var sharedDiscover: LocalPeerDiscover?
  var activeConnection: LocalPeerConnection?
}

// MARK: -
final class ApplicationDelegate: UIResponder, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    true
  }
  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    let sceneConfiguration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
    sceneConfiguration.delegateClass = SceneDelegate.self
    return sceneConfiguration
  }
}
