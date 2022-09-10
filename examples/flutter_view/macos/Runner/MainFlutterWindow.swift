import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let windowFrame = self.frame
    let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: Bundle.main)
    self.contentViewController = storyboard.instantiateController(withIdentifier: "MainViewController") as! NSViewController
    self.setFrame(windowFrame, display: true)

    super.awakeFromNib()
  }
}
