import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
    
  override func applicationDidFinishLaunching(_ notification: Notification) {
    let engine = FlutterEngine(name: "project", project: nil);
    engine.run(withEntrypoint:nil);
  }
}
