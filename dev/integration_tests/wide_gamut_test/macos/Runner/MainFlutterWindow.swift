import Cocoa
import FlutterMacOS
import Foundation

// 1. Define a private protocol to expose the engine's internal method to Swift.
@objc protocol PrivateFlutterView {
    func setEnableWideGamut(_ enabled: Bool)
}

// 2. Subclass to intercept and "lock" the wide-gamut state without global swizzling.
class WideGamutViewController: FlutterViewController {
    
    // This intercepts the private engine method called during window moves/resizes.
    // By overriding it, we stop the engine from checking the screen and disabling wide-gamut.
    @objc(updateWideGamutForScreen)
    func updateWideGamutForScreen() {
        if let flutterView = self.view as AnyObject as? PrivateFlutterView {
            flutterView.setEnableWideGamut(true) // Always force true
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        // Force the surface to 10-bit during the initial view loading sequence.
        self.updateWideGamutForScreen()
    }
}

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    // 3. Instantiate our custom subclass instead of the standard FlutterViewController.
    let flutterViewController = WideGamutViewController()
    
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
