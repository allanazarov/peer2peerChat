//
//  SceneDelegate.swift
//  peer2peerChat
//
//  Created by Ibrokhimbek Allanazarov on 09.01.2022.
//

import UIKit

// MARK: -
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?
  
  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = scene as? UIWindowScene else { return }
    let window = UIWindow(windowScene: windowScene)
    let nv = UINavigationController()
    nv.setViewControllers([MainTableViewController(nibName: nil, bundle: nil)], animated: false)
    window.rootViewController = nv
    window.makeKeyAndVisible()
    self.window = window
  }
}
