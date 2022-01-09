//
//  ChatCollectionViewController.swift
//  peer2peerChat
//
//  Created by Ibrokhimbek Allanazarov on 09.01.2022.
//

import UIKit
import Drops
import Network
import LocalPeer

// MARK: -
final class ChatCollectionViewController: UIViewController {
  private var isViewDidLayoutSubviewsVisitedOnce = false
  private var textViewBoundsObserver: NSKeyValueObservation!
  
  let name: String
  let collectionView: ChatCollectionView = {
    let collectionViewLayout = $0.collectionViewLayout as! UICollectionViewFlowLayout
    collectionViewLayout.estimatedItemSize = .init(width: 1.0, height: 1.0)
    return $0
  }(ChatCollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout()))
  let titleView = TitleView(frame: .zero)
  
  private(set) var dataSource: ChatDataSource!
  private lazy var cachedCell = IncomingMessageBubbleCollectionViewCell(frame: .zero)
  
  override func loadView() {
    view = collectionView
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    
    dataSource = .init(collectionView: collectionView) { [unowned self] (collectionView, indexPath, itemIdentifier) in cell(collectionView: collectionView, indexPath: indexPath, itemIdentifier: itemIdentifier) }
    collectionView.delegate = self
    Application.shared.activeConnection?.delegate = self
  }
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    if !isViewDidLayoutSubviewsVisitedOnce {
      defer { isViewDidLayoutSubviewsVisitedOnce = true }
      
      collectionView.messageInputBottomConstraint.constant = view.safeAreaInsets.bottom
      collectionView.layoutIfNeeded()
      additionalSafeAreaInsets.bottom = collectionView.messageInputView.bounds.height
      collectionView.contentInset = .init(top: view.safeAreaInsets.top + 10.0, left: 0.0, bottom: view.safeAreaInsets.bottom + 10.0, right: 0.0)
      collectionView.scrollIndicatorInsets = view.safeAreaInsets
    }
  }
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
  
    //
    let navigationBarAppearance = UINavigationBarAppearance()
    navigationBarAppearance.configureWithDefaultBackground()
    navigationItem.scrollEdgeAppearance = navigationBarAppearance
    
    titleView.titleLabel.text = name
    titleView.subtitleLabel.text = "online"
    titleView.sizeToFit()
    navigationItem.titleView = titleView
    
    let backButton = UIBarButtonItem(title: "Back")
    navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
    
    navigationController?.navigationBar.prefersLargeTitles = false
    navigationController?.setNeedsStatusBarAppearanceUpdate()
    //
    NotificationCenter.default
      .addObserver(self, selector: #selector(keyboardWillChangeFrameNotification(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    
    //
    textViewBoundsObserver = collectionView.messageInputView.textView.observe(\.bounds, options: [.old, .new]) { [unowned self] (textView, change) in
      messageInputTexView(textView, boundsDidChange: change)
    }
    
    //
    collectionView.messageInputView.sendButton.addTarget(self, action: #selector(sendButtonDidTapped), for: .touchUpInside)
    
    //
    var snapshot = ChatSnapshot()
    snapshot.appendSections([.main])
    snapshot.appendItems([], toSection: .main)
    dataSource.apply(snapshot, animatingDifferences: animated)
  }
  
  init(name: String) {
    self.name = name
    super.init(nibName: nil, bundle: nil)
  }
  required init?(coder: NSCoder) {
    fatalError()
  }
}

extension ChatCollectionViewController {
  private func cell(collectionView: UICollectionView, indexPath: IndexPath, itemIdentifier: ChatItem) -> UICollectionViewCell {
    switch itemIdentifier {
    case .inComingMessage(let text):
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "incomingMessageCell", for: indexPath) as! IncomingMessageBubbleCollectionViewCell
      cell.messageTextView.text = text
      return cell
      
    case .outComingMessage(let text):
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "outcomingMessageCell", for: indexPath) as! OutcomingMessageBubbleCollectionViewCell
      cell.messageTextView.text = text
      return cell
    }
  }
}

extension ChatCollectionViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    switch dataSource.itemIdentifier(for: indexPath) {
    case .inComingMessage(let text):
      cachedCell.messageTextView.text = text
      
    case .outComingMessage(let text):
      cachedCell.messageTextView.text = text
      
    default:
      break
    }
    
    let width = collectionView.bounds.width - (collectionView.directionalLayoutMargins.leading + collectionView.directionalLayoutMargins.trailing)
    
    let height = cachedCell
      .systemLayoutSizeFitting(.init(width: width, height: UIView.layoutFittingCompressedSize.height), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
      .height
    
    return .init(width: width, height: height)
  }
}

extension ChatCollectionViewController {
  @objc private func keyboardWillChangeFrameNotification(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
          let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
          let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int,
          let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
    else { return }
    
    if frame.minY == view.frame.maxY {
      collectionView.messageInputBackdropBottomConstraint.constant = 0.0
      collectionView.messageInputBottomConstraint.constant = view.window!.safeAreaInsets.bottom
      additionalSafeAreaInsets.bottom = collectionView.messageInputView.bounds.height
      collectionView.contentInset = .init(top: view.safeAreaInsets.top + 10.0, left: 0.0, bottom: view.safeAreaInsets.bottom + 10.0, right: 0.0)
      collectionView.scrollIndicatorInsets = view.safeAreaInsets
    } else {
      collectionView.messageInputBackdropBottomConstraint.constant = frame.height
      collectionView.messageInputBottomConstraint.constant = 0.0
      additionalSafeAreaInsets.bottom = frame.height + collectionView.messageInputView.bounds.height - view.window!.safeAreaInsets.bottom
      collectionView.contentInset = .init(top: view.safeAreaInsets.top + 10.0,
                                          left: 0.0,
                                          bottom: view.safeAreaInsets.bottom + 2.0 * 16.0 + collectionView.hideKeyboardButton.bounds.height,
                                          right: 0.0)
      collectionView.scrollIndicatorInsets = view.safeAreaInsets
    }
    
    let animator = UIViewPropertyAnimator(duration: duration, curve: .init(rawValue: curve)!) { [self] in
      if frame.minY == view.frame.maxY {
        collectionView.messageInputWithKeyboardBackdropView.alpha = 0.0
        collectionView.messageInputWithoutKeyboardBackdropView.alpha = 1.0
        collectionView.hideKeyboardButton.alpha = 0.0
      } else {
        collectionView.messageInputWithKeyboardBackdropView.alpha = 1.0
        collectionView.messageInputWithoutKeyboardBackdropView.alpha = 0.0
        collectionView.hideKeyboardButton.alpha = 1.0
      }
      
      collectionView.contentOffset.y = collectionView.contentSize.height - collectionView.bounds.height + collectionView.adjustedContentInset.bottom
      collectionView.layoutIfNeeded()
    }
    animator.isUserInteractionEnabled = false
    animator.startAnimation()
  }
  private func messageInputTexView(_ textView: UITextView, boundsDidChange boundsChange: NSKeyValueObservedChange<CGRect>) {
    guard textView.isFirstResponder else { return }
    guard let newHeight = boundsChange.newValue?.height, let oldHeight = boundsChange.oldValue?.height else { return }
    let heightDiff = newHeight - oldHeight
    additionalSafeAreaInsets.bottom += heightDiff
    collectionView.contentInset.bottom += heightDiff
    collectionView.scrollIndicatorInsets = view.safeAreaInsets
  }
}

extension ChatCollectionViewController {
  @objc private func sendButtonDidTapped() {
    guard let message = collectionView.messageInputView.textView.text else { return }
    collectionView.messageInputView.textView.text = ""
    
    Application.shared.activeConnection?.send(message: message)
    
    var snapshot = dataSource.snapshot()
    snapshot.appendItems([.outComingMessage(message)], toSection: .main)
    dataSource.apply(snapshot, animatingDifferences: true)
  }
}



extension ChatCollectionViewController: LocalPeerConnectionDelegate {
  func localPeerConnectionDidConnected(_ connection: LocalPeerConnection) {
    
  }
  func localPeerConnectiondDidDisconnected(_ connection: LocalPeerConnection) {
      if connection.initiatedConnection {
          
      }
      
  }
  func localPeerConnection(_ connection: LocalPeerConnection, didReceivedMessage message: String) {
    var snapshot = dataSource.snapshot()
    snapshot.appendItems([.inComingMessage(message)], toSection: .main)
    dataSource.apply(snapshot, animatingDifferences: true)
  }
  func localPeerConnection(_ connection: LocalPeerConnection, didFailedWith error: NWError) {
      switch error {
      case .posix(let darwin) where darwin == POSIXError.ENODATA:
          Drops.hideAll()
          let drop = Drop(title: "Host is disconnected", action: .init {
            Drops.hideCurrent()
          }, duration: .recommended)
          
          Drops.show(drop)
          
          titleView.subtitleLabel.textColor = .systemRed
          titleView.subtitleLabel.text = "offline"
          
      default:
          print(error)
      }

  }
}


// MARK: -
final class TitleView: UIView {
  let titleLabel: UILabel = {
    $0.font = .systemFont(ofSize: 17.0, weight: .semibold)
    $0.textColor = .label
    $0.translatesAutoresizingMaskIntoConstraints = false
    return $0
  }(UILabel(frame: .zero))
  let subtitleLabel: UILabel = {
    $0.font = .systemFont(ofSize: 13.0)
    $0.textColor = .label
    $0.textColor = .systemBlue
    $0.translatesAutoresizingMaskIntoConstraints = false
    return $0
  }(UILabel(frame: .zero))
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    addSubview(titleLabel)
    addSubview(subtitleLabel)
    
    titleLabel.setContentHuggingPriority(.required, for: .horizontal)
    titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    subtitleLabel.setContentHuggingPriority(.required, for: .horizontal)
    subtitleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    
    titleLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
    titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor).isActive = true
    trailingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor).isActive = true
    
    subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
    subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    subtitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor).isActive = true
    trailingAnchor.constraint(greaterThanOrEqualTo: subtitleLabel.trailingAnchor).isActive = true
    bottomAnchor.constraint(equalTo: subtitleLabel.bottomAnchor).isActive = true
  }
  required init?(coder: NSCoder) {
    fatalError()
  }
}

// MARK: -
typealias ChatSnapshot = NSDiffableDataSourceSnapshot<ChatSection, ChatItem>

// MARK: -
typealias ChatDataSource = UICollectionViewDiffableDataSource<ChatSection, ChatItem>

// MARK: -
enum ChatSection: Hashable {
  case main
}

// MARK: -
enum ChatItem: Hashable {
  case inComingMessage(String)
  case outComingMessage(String)
}
