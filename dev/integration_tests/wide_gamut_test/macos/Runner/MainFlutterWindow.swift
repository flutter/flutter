import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Move window to the first screen that supports P3 (if available).
    for screen in NSScreen.screens {
      if screen.canRepresent(.p3) {
        let visibleFrame = screen.visibleFrame
        self.setFrame(
          NSRect(
            x: visibleFrame.midX - windowFrame.width / 2,
            y: visibleFrame.midY - windowFrame.height / 2,
            width: windowFrame.width,
            height: windowFrame.height
          ),
          display: true
        )
        break
      }
    }

    super.awakeFromNib()
  }
}
