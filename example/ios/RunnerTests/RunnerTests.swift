import Flutter
import XCTest

@testable import durable_device_id

class RunnerTests: XCTestCase {
  // A bundle identifier of its own, so the tests never touch the identifier of the example app.
  private let store = DeviceIdStore(bundleIdentifier: "com.serdun.durableDeviceIdExample.tests")

  override func setUp() {
    super.setUp()
    store.remove()
  }

  override func tearDown() {
    store.remove()
    super.tearDown()
  }

  func testCreatesAnIdentifierOnTheFirstCall() {
    let id = store.deviceId()

    XCTAssertNotNil(id)
    XCTAssertNotNil(UUID(uuidString: id ?? ""))
    XCTAssertEqual(id, id?.lowercased())
  }

  func testGivesTheSameIdentifierOnEveryLaterCall() {
    let first = store.deviceId()

    XCTAssertEqual(store.deviceId(), first)
    XCTAssertEqual(DeviceIdStore(bundleIdentifier: "com.serdun.durableDeviceIdExample.tests").deviceId(), first)
  }

  func testGivesANewIdentifierOnceTheItemIsRemoved() {
    let first = store.deviceId()
    store.remove()

    XCTAssertNotEqual(store.deviceId(), first)
  }

  func testAnotherAppGetsAnotherIdentifier() {
    let other = DeviceIdStore(bundleIdentifier: "com.serdun.durableDeviceIdExample.tests.other")
    defer { other.remove() }

    XCTAssertNotEqual(store.deviceId(), other.deviceId())
  }

  func testServiceCarriesTheBundleIdentifier() {
    XCTAssertEqual(store.service, "com.serdun.durableDeviceIdExample.tests.durable_device_id")
  }

  func testPluginAnswersReadWithTheIdentifier() {
    let plugin = DurableDeviceIdPlugin()
    let answered = expectation(description: "result block must be called.")

    plugin.handle(FlutterMethodCall(methodName: "read", arguments: nil)) { result in
      XCTAssertNotNil(result as? String)
      answered.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testPluginRefusesAnUnknownMethod() {
    let plugin = DurableDeviceIdPlugin()
    let answered = expectation(description: "result block must be called.")

    plugin.handle(FlutterMethodCall(methodName: "getPlatformVersion", arguments: nil)) { result in
      XCTAssertTrue((result as AnyObject) === FlutterMethodNotImplemented)
      answered.fulfill()
    }
    waitForExpectations(timeout: 1)
  }
}
