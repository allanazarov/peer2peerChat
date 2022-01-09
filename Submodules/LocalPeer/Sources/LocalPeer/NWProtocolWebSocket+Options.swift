import Network

// MARK: -
extension NWProtocolWebSocket.Options {
  public static var `default`: NWProtocolWebSocket.Options = {
    $0.autoReplyPing = true
    return  $0
  }(NWProtocolWebSocket.Options())
}
