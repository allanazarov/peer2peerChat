//
//  MainTableView.swift
//  peer2peerChat
//
//  Created by Ibrokhimbek Allanazarov on 09.01.2022.
//

import UIKit

// MARK: -
final class MainTableView: UITableView {
  
  init(frame: CGRect) {
    super.init(frame: frame, style: .insetGrouped)
    register()
    setupAppearance()
  }
  required init?(coder: NSCoder) {
    fatalError()
  }
}

extension MainTableView {
  private func register() {
    register(ButtonTableViewCell.self, forCellReuseIdentifier: "buttonCell")
    register(NamelessHostTableViewCell.self, forCellReuseIdentifier: "namelessHostCell")
    register(HostTableViewCell.self, forCellReuseIdentifier: "hostCell")
  }
}

extension MainTableView {
  private func setupAppearance() {
    showsVerticalScrollIndicator = false
    delaysContentTouches = false
  }
}

// MARK: -
final class ButtonTableViewCell: UITableViewCell {
  func configure(title: String, isDestructive: Bool = false) {
    textLabel?.textColor = isDestructive ? .systemRed : .systemBlue
    textLabel?.text = title
    selectionStyle = .default
  }
  func nonActiveConfigure(title: String) {
    textLabel?.textColor = .secondaryLabel
    textLabel?.text = title
    selectionStyle = .none
  }
  override func prepareForReuse() {
    super.prepareForReuse()
    selectionStyle = .default
  }
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: .default, reuseIdentifier: reuseIdentifier)
  }
  required init?(coder: NSCoder) {
    fatalError()
  }
}

// MARK: -
final class NamelessHostTableViewCell: UITableViewCell {
  func configure(ipAddress: String, port: String) {
    textLabel?.text = "\(ipAddress):\(port)"
    detailTextLabel?.text = "Tap to copy"
  }
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
  }
  required init?(coder: NSCoder) {
    fatalError()
  }
}

// MARK: -
final class HostTableViewCell: UITableViewCell {
  func configure(name: String, ipAddress: String, port: String) {
    textLabel?.numberOfLines = 2
    textLabel?.text = "\(name)\n\(ipAddress):\(port)"
    detailTextLabel?.text = "Tap to connect"
  }
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
  }
  required init?(coder: NSCoder) {
    fatalError()
  }
}
