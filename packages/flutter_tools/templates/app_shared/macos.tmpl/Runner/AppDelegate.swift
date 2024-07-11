import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    // If you are customizing app state serialization and deserialization,
    // ensure that such serialization is compatible with NSSecureCoding, or
    // return false here.
    return true
  }
}
