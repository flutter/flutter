import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private static var swizzled = false

  override func awakeFromNib() {
    MainFlutterWindow.doSwizzleOnce()

    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Force the FlutterView to enable wide gamut (force Display P3)
    if let flutterView = flutterViewController.value(forKey: "flutterView") as? NSView {
        let selector = Selector(("setEnableWideGamut:"))
        if flutterView.responds(to: selector) {
            // Safely call the private BOOL method using a C-style function pointer
            typealias SetWideGamutFunc = @convention(c) (NSView, Selector, Bool) -> Void
            let imp = flutterView.method(for: selector)
            let fn = unsafeBitCast(imp, to: SetWideGamutFunc.self)
            fn(flutterView, selector, true) // Pass 'true' for wide-gamut P3
        }
    }

    super.awakeFromNib()
  }

  private static func doSwizzleOnce() {
    guard !swizzled else { return }
    swizzled = true

    // Swizzle NSScreen.canRepresentDisplayGamut:
    let canRepresentSelector = Selector(("canRepresentDisplayGamut:"))
    if let original = class_getInstanceMethod(NSScreen.self, canRepresentSelector),
       let swizzled = class_getInstanceMethod(NSScreen.self, #selector(NSScreen.swizzled_canRepresent(_:))) {
        method_exchangeImplementations(original, swizzled)
    }

    // Swizzle NSScreen.colorSpace
    if let original = class_getInstanceMethod(NSScreen.self, #selector(getter: NSScreen.colorSpace)),
       let swizzled = class_getInstanceMethod(NSScreen.self, #selector(getter: NSScreen.swizzled_colorSpace)) {
        method_exchangeImplementations(original, swizzled)
    }
  }
}

extension NSScreen {
    @objc func swizzled_canRepresent(_ gamut: NSDisplayGamut) -> Bool {
        if gamut == .p3 {
            return true // Force P3 support reporting
        }
        // This calls the original implementation due to the exchange
        return self.swizzled_canRepresent(gamut)
    }

    @objc var swizzled_colorSpace: NSColorSpace? {
        return NSColorSpace.displayP3 // Force P3 color space
    }
}
