import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    // 1. Swizzle NSScreen.canRepresent(_:)
    let screenMethod = class_getInstanceMethod(NSScreen.self, #selector(NSScreen.canRepresent(_:)))
    let swizzledMethod = class_getInstanceMethod(NSScreen.self, #selector(NSScreen.swizzled_canRepresent(_:)))
    if let screenMethod = screenMethod, let swizzledMethod = swizzledMethod {
        method_exchangeImplementations(screenMethod, swizzledMethod)
    }

    // 2. Swizzle NSScreen.colorSpace
    let colorSpaceMethod = class_getInstanceMethod(NSScreen.self, #selector(getter: NSScreen.colorSpace))
    let swizzledColorSpaceMethod = class_getInstanceMethod(NSScreen.self, #selector(getter: NSScreen.swizzled_colorSpace))
    if let colorSpaceMethod = colorSpaceMethod, let swizzledColorSpaceMethod = swizzledColorSpaceMethod {
        method_exchangeImplementations(colorSpaceMethod, swizzledColorSpaceMethod)
    }

    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Force the FlutterView to enable wide gamut immediately.
    if let flutterView = flutterViewController.value(forKey: "flutterView") as? NSView {
        let selector = Selector(("setEnableWideGamut:"))
        if flutterView.responds(to: selector) {
            flutterView.perform(selector, with: true)
        }
    }

    super.awakeFromNib()
  }
}

extension NSScreen {
    @objc func swizzled_canRepresent(_ gamut: NSDisplayGamut) -> Bool {
        if gamut == .p3 {
            return true
        }
        return self.swizzled_canRepresent(gamut)
    }

    @objc var swizzled_colorSpace: NSColorSpace? {
        return NSColorSpace.displayP3
    }
}
