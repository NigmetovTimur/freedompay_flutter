import Flutter
import UIKit
import XCTest


@testable import freedompay

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {

  func testGooglePayIsReportedAsUnsupportedOnIOS() {
    let plugin = FreedompayPlugin()

    let call = FlutterMethodCall(methodName: "createGooglePayment", arguments: [:])

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      let payload = result as? [String: Any]
      let error = payload?["error"] as? [String: Any]
      XCTAssertEqual(error?["description"] as? String, "Google Pay is not supported on iOS")
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

}
