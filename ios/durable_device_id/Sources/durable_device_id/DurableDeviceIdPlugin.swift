import Flutter
import Foundation
import Security

public class DurableDeviceIdPlugin: NSObject, FlutterPlugin {
  private static let methodChannelName = "durable_device_id"
  private static let methodRead = "read"

  private let store = DeviceIdStore()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(DurableDeviceIdPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == DurableDeviceIdPlugin.methodRead {
      result(store.deviceId())
    } else {
      result(FlutterMethodNotImplemented)
    }
  }
}

/// The identifier kept in the Keychain, which iOS does not remove with the app.
///
/// Readable after the first unlock, so a launch in the background on a locked device still
/// gets it, and bound to this device, so a backup restored on another phone does not carry
/// the identity of the first one over.
struct DeviceIdStore {
  private static let serviceSuffix = ".durable_device_id"
  private static let account = "device_id"

  /// Carries the bundle identifier: apps that share a Keychain access group search each
  /// other's items, and the identifier of one app must not be the identifier of another.
  let service: String

  init(bundleIdentifier: String? = Bundle.main.bundleIdentifier) {
    service = (bundleIdentifier ?? "") + DeviceIdStore.serviceSuffix
  }

  func deviceId() -> String? {
    switch read() {
    case .found(let id):
      return id
    case .unavailable:
      // Before the first unlock the item cannot be read. Creating one here would hand out
      // a second identity for a device that already has one.
      return nil
    case .missing:
      return create()
    }
  }

  /// Removes the identifier. The app has no use for it; the tests clean up with it.
  @discardableResult
  func remove() -> Bool {
    let status = SecItemDelete(baseQuery as CFDictionary)
    return status == errSecSuccess || status == errSecItemNotFound
  }

  private enum ReadResult {
    case found(String)
    case missing
    case unavailable
  }

  private var baseQuery: [String: Any] {
    return [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: DeviceIdStore.account,
    ]
  }

  private func read() -> ReadResult {
    var query = baseQuery
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)

    switch status {
    case errSecSuccess:
      guard let data = item as? Data, let id = String(data: data, encoding: .utf8), !id.isEmpty else {
        return .unavailable
      }
      return .found(id)
    case errSecItemNotFound:
      return .missing
    default:
      return .unavailable
    }
  }

  private func create() -> String? {
    let id = UUID().uuidString.lowercased()

    var attributes = baseQuery
    attributes[kSecValueData as String] = Data(id.utf8)
    attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

    switch SecItemAdd(attributes as CFDictionary, nil) {
    case errSecSuccess:
      return id
    case errSecDuplicateItem:
      // Another isolate of the app stored one between the read and the add; that one stands.
      if case .found(let existing) = read() { return existing }
      return nil
    default:
      return nil
    }
  }
}
