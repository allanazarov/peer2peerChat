//
//  ChatCollectionView.swift
//  peer2peerChat
//
//  Created by Ibrokhimbek Allanazarov on 09.01.2022.
//

import UIKit
import SwiftUI

// MARK: -
final class ChatCollectionView: UICollectionView {
  let messageInputWithKeyboardBackdropView: UIView = {
    let InputBackdropViewType = NSClassFromString("UIKBInputBackdropView")! as! UIView.Type
    let _$0 = InputBackdropViewType.init(frame: .zero)
    _$0.isUserInteractionEnabled = true
    _$0.translatesAutoresizingMaskIntoConstraints = false
    _$0.alpha = 0.0
    return _$0
  }()
  let messageInputWithoutKeyboardBackdropView: UIView = {
    let _$0 = UIVisualEffectView(frame: .zero)
    _$0.effect = UIBlurEffect(style: .systemChromeMaterial)
    _$0.isUserInteractionEnabled = true
    _$0.translatesAutoresizingMaskIntoConstraints = false
    return _$0
  }()
  let messageInputView: InputView = {
    $0.translatesAutoresizingMaskIntoConstraints = false
    return $0
  }(InputView(frame: .zero))
  let messageBackdropSeparatorImageView: UIImageView = {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.backgroundColor = .separator
    return $0
  }(UIImageView(frame: .zero))
  private(set) lazy var hideKeyboardButton: UIButton = {
    $0.layer.cornerCurve = .circular
    $0.setImage(.init(systemName: "chevron.down.circle.fill"), for: .normal)
    $0.setPreferredSymbolConfiguration(.init(font: .preferredFont(forTextStyle: .title1), scale: .large), forImageIn: .normal)
    $0.tintColor = .label
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.alpha = 0.0
    $0.addTarget(self, action: #selector(hideKeyboardButtonDidTapped), for: .touchUpInside)
    return $0
  }(UIButton(type: .system))
  
  var messageInputBackdropBottomConstraint: NSLayoutConstraint!
  var messageInputBottomConstraint: NSLayoutConstraint!

  override func scrollRectToVisible(_ rect: CGRect, animated: Bool) {
  }
  
  override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
    super.init(frame: frame, collectionViewLayout: layout)
    register()
    setupConstraints()
    setupAppearance()
  }
  required init?(coder: NSCoder) {
    fatalError()
  }
}

extension ChatCollectionView {
  private func register() {
    register(IncomingMessageBubbleCollectionViewCell.self, forCellWithReuseIdentifier: "incomingMessageCell")
    register(OutcomingMessageBubbleCollectionViewCell.self, forCellWithReuseIdentifier: "outcomingMessageCell")
  }
}

extension ChatCollectionView {
  private func setupAppearance() {
    alwaysBounceVertical = true
    automaticallyAdjustsScrollIndicatorInsets = false
    backgroundColor = .systemBackground
    contentInsetAdjustmentBehavior = .never
    delaysContentTouches = false
    showsHorizontalScrollIndicator = false
  }
}

extension ChatCollectionView {
  private func setupConstraints() {
    addSubview(messageInputWithKeyboardBackdropView)
    addSubview(messageInputWithoutKeyboardBackdropView)
    addSubview(messageInputView)
    addSubview(hideKeyboardButton)
    addSubview(messageBackdropSeparatorImageView)
    
    messageInputWithKeyboardBackdropView.leadingAnchor.constraint(equalTo: frameLayoutGuide.leadingAnchor).isActive = true
    frameLayoutGuide.trailingAnchor.constraint(equalTo: messageInputWithKeyboardBackdropView.trailingAnchor).isActive = true
    messageInputBackdropBottomConstraint = frameLayoutGuide.bottomAnchor.constraint(equalTo: messageInputWithKeyboardBackdropView.bottomAnchor, constant: 0.0); messageInputBackdropBottomConstraint.isActive = true
    
    messageInputWithoutKeyboardBackdropView.centerXAnchor.constraint(equalTo: messageInputWithKeyboardBackdropView.centerXAnchor).isActive = true
    messageInputWithoutKeyboardBackdropView.centerYAnchor.constraint(equalTo: messageInputWithKeyboardBackdropView.centerYAnchor).isActive = true
    messageInputWithoutKeyboardBackdropView.widthAnchor.constraint(equalTo: messageInputWithKeyboardBackdropView.widthAnchor).isActive = true
    messageInputWithoutKeyboardBackdropView.heightAnchor.constraint(equalTo: messageInputWithKeyboardBackdropView.heightAnchor).isActive = true
    
    messageBackdropSeparatorImageView.topAnchor.constraint(equalTo: messageInputWithKeyboardBackdropView.topAnchor).isActive = true
    messageBackdropSeparatorImageView.leadingAnchor.constraint(equalTo: messageInputWithKeyboardBackdropView.leadingAnchor).isActive = true
    messageInputWithKeyboardBackdropView.trailingAnchor.constraint(equalTo: messageBackdropSeparatorImageView.trailingAnchor).isActive = true
    messageBackdropSeparatorImageView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale).isActive = true
     
    messageInputView.topAnchor.constraint(equalTo: messageInputWithKeyboardBackdropView.topAnchor).isActive = true
    messageInputView.leadingAnchor.constraint(equalTo: messageInputWithKeyboardBackdropView.leadingAnchor).isActive = true
    messageInputWithKeyboardBackdropView.trailingAnchor.constraint(equalTo: messageInputView.trailingAnchor).isActive = true
    messageInputBottomConstraint = messageInputWithKeyboardBackdropView.bottomAnchor.constraint(equalTo: messageInputView.bottomAnchor); messageInputBottomConstraint.isActive = true
    
    frameLayoutGuide.trailingAnchor.constraint(equalTo: hideKeyboardButton.trailingAnchor, constant: 12.0).isActive = true
    messageInputWithKeyboardBackdropView.topAnchor.constraint(equalTo: hideKeyboardButton.bottomAnchor, constant: 16.0).isActive = true
  }
}

extension ChatCollectionView {
  @objc private func hideKeyboardButtonDidTapped() {
    endEditing(true)
  }
}

// MARK: -
final class InputView: UIView {
  private var isLayoutSubviewsVisitedOnce = false
  private var sendButtonBottomAnchor: NSLayoutConstraint!
  private var textHeightAnchor: NSLayoutConstraint!
  
  private(set) lazy var textView: UITextView = {
    $0.backgroundColor = .init(dynamicProvider: {
      switch $0.userInterfaceStyle {
      case .dark:
        return .secondarySystemFill
      case .light:
        return .white
      default:
        preconditionFailure()
      }
    })
    $0.delegate = self
    $0.font = .preferredFont(forTextStyle: .body)
    $0.isScrollEnabled = false
    $0.layer.cornerCurve = .continuous
    $0.layer.cornerRadius = 8.0
    $0.layer.shadowColor = UIColor.black.cgColor
    $0.layer.shadowOffset = .zero
    $0.layer.shadowOpacity = 0.1
    $0.layer.shadowRadius = 5.0
    $0.automaticallyAdjustsScrollIndicatorInsets = false
    $0.contentInsetAdjustmentBehavior = .never
    $0.translatesAutoresizingMaskIntoConstraints = false
    return $0
  }(VerticallyCenteredTextView(frame: .zero))
  let textPlaceholderLabel: UILabel = {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.font = .preferredFont(forTextStyle: .body)
    $0.text = "Message"
    $0.textColor = .placeholderText
    return $0
  }(UILabel(frame: .zero))
  let sendButton: UIButton = {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.setImage(.init(systemName: "arrow.up.circle.fill"), for: .normal)
    $0.setPreferredSymbolConfiguration(.init(font: .preferredFont(forTextStyle: .title1), scale: .large), forImageIn: .normal)
    $0.tintColor = .systemBlue
    $0.isEnabled = false
    return $0
  }(UIButton(type: .system))
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    if !isLayoutSubviewsVisitedOnce {
      defer { isLayoutSubviewsVisitedOnce = true }
      sendButtonBottomAnchor.constant += (textView.bounds.height - sendButton.bounds.height) / 2.0
      textView.layer.shadowPath = UIBezierPath(roundedRect: textView.bounds, cornerRadius: textView.layer.cornerRadius).cgPath
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    addSubview(textView)
    addSubview(textPlaceholderLabel)
    addSubview(sendButton)

    textView.setContentHuggingPriority(.required, for: .vertical)
    textView.setContentCompressionResistancePriority(.required, for: .vertical)
    sendButton.setContentHuggingPriority(.required, for: .horizontal)
    sendButton.setContentCompressionResistancePriority(.required, for: .horizontal)
    
    textPlaceholderLabel.centerYAnchor.constraint(equalTo: textView.centerYAnchor).isActive = true
    textPlaceholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 5.0).isActive = true
    
    textView.topAnchor.constraint(equalTo: topAnchor, constant: 8.0).isActive = true
    textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16.0).isActive = true
    sendButton.leadingAnchor.constraint(equalTo: textView.trailingAnchor, constant: 8.0).isActive = true
    textHeightAnchor = textView.heightAnchor.constraint(equalToConstant: 44.0); textHeightAnchor.isActive = true
    bottomAnchor.constraint(equalTo: textView.bottomAnchor, constant: 8.0).isActive = true

    trailingAnchor.constraint(equalTo: sendButton.trailingAnchor, constant: 12.0).isActive = true
    sendButtonBottomAnchor = bottomAnchor.constraint(equalTo: sendButton.bottomAnchor, constant: 8.0); sendButtonBottomAnchor.isActive = true
  }
  required init?(coder: NSCoder) {
    fatalError()
  }
}

extension InputView: UITextViewDelegate {
  func textViewDidChange(_ textView: UITextView) {
    textPlaceholderLabel.alpha = textView.text.isEmpty ? 1.0 : 0.0
    sendButton.isEnabled = textView.text.isEmpty ? false : true
    
    let numberOfLines = Int((textView.sizeThatFits(.init(width: textView.bounds.width, height: UIView.layoutFittingCompressedSize.height)).height) / ( textView.font!.lineHeight.rounded(.up) + 1.0))

    if numberOfLines > 5 {
      textView.isScrollEnabled = true
    } else {
      textView.isScrollEnabled = false
      
      let height: CGFloat
      if numberOfLines == 1 {
        height = 44.0
        textView.contentOffset.y = -textView.adjustedContentInset.top
      } else {
        height = textView.sizeThatFits(.init(width: textView.bounds.width, height: UIView.layoutFittingCompressedSize.height)).height
      }
      
      guard textHeightAnchor.constant != height else { return }
      textHeightAnchor.constant = height
     }
  }
}

// MARK: -
final class VerticallyCenteredTextView: UITextView {
  private var isLayoutSubviewsVisitedOnce = false

  override func layoutSubviews() {
    super.layoutSubviews()
    
    if !isLayoutSubviewsVisitedOnce {
      defer { isLayoutSubviewsVisitedOnce = true }
      let offset = (bounds.height - intrinsicContentSize.height) / 2.0
      contentInset.top = offset
      contentInset.bottom = offset
      verticalScrollIndicatorInsets = contentInset
      contentOffset.y = -contentInset.top
    }
  }
}

// MARK: -
final class IncomingMessageBubbleCollectionViewCell: UICollectionViewCell {
  let messageTextView: UITextView = {
    $0.backgroundColor = .secondarySystemFill
    $0.contentInset = .zero
    $0.font = .preferredFont(forTextStyle: .body)
    $0.isEditable = false
    $0.isScrollEnabled = false
    $0.layer.cornerCurve = .continuous
    $0.layer.cornerRadius = 16.0
    $0.showsHorizontalScrollIndicator = false
    $0.showsVerticalScrollIndicator = false
    $0.textColor = .label
    $0.textContainerInset = .init(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
    $0.tintColor = .label
    $0.translatesAutoresizingMaskIntoConstraints = false
    return $0
  }(UITextView(frame: .zero))
  
  override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
    contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    contentView.addSubview(messageTextView)
    
    messageTextView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
    messageTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
    contentView.trailingAnchor.constraint(greaterThanOrEqualTo: messageTextView.trailingAnchor).isActive = true
    contentView.bottomAnchor.constraint(equalTo: messageTextView.bottomAnchor).isActive = true
  }
  required init?(coder: NSCoder) {
    fatalError()
  }
}

// MARK: -
final class OutcomingMessageBubbleCollectionViewCell: UICollectionViewCell {
  let messageTextView: UITextView = {
    $0.backgroundColor = .systemBlue
    $0.contentInset = .zero
    $0.font = .preferredFont(forTextStyle: .body)
    $0.isEditable = false
    $0.isScrollEnabled = false
    $0.layer.cornerCurve = .continuous
    $0.layer.cornerRadius = 16.0
    $0.showsHorizontalScrollIndicator = false
    $0.showsVerticalScrollIndicator = false
    $0.textColor = .white
    $0.textContainerInset = .init(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
    $0.tintColor = .label
    $0.translatesAutoresizingMaskIntoConstraints = false
    return $0
  }(UITextView(frame: .zero))
  
  override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
    contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    contentView.addSubview(messageTextView)
    
    messageTextView.setContentHuggingPriority(.required, for: .horizontal)
    messageTextView.setContentCompressionResistancePriority(.required, for: .horizontal)
    
    messageTextView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
    messageTextView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor).isActive = true
    contentView.trailingAnchor.constraint(equalTo: messageTextView.trailingAnchor).isActive = true
    contentView.bottomAnchor.constraint(equalTo: messageTextView.bottomAnchor).isActive = true
  }
  required init?(coder: NSCoder) {
    fatalError()
  }
}
