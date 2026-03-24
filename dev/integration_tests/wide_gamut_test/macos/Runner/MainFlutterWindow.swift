import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    // 1. Swizzle NSScreen.canRepresent(_:) to force FALSE for P3
    let screenMethod = class_getInstanceMethod(NSScreen.self, #selector(NSScreen.canRepresent(_:)))
    let swizzledMethod = class_getInstanceMethod(NSScreen.self, #selector(NSScreen.swizzled_canRepresent(_:)))
    if let screenMethod = screenMethod, let swizzledMethod = swizzledMethod {
        method_exchangeImplementations(screenMethod, swizzledMethod)
    }

    // 2. Swizzle NSScreen.colorSpace to force standard sRGB
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

    // 3. Force the FlutterView to disable wide gamut (force normal sRGB)
    if let flutterView = flutterViewController.value(forKey: "flutterView") as? NSView {
        let selector = Selector(("setEnableWideGamut:"))
        if flutterView.responds(to: selector) {
            // Passing 'false' here forces the engine to use standard 8-bit sRGB IOSurfaces
            flutterView.perform(selector, with: false)
        }
    }

    super.awakeFromNib()
  }
}

extension NSScreen {
    @objc func swizzled_canRepresent(_ gamut: NSDisplayGamut) -> Bool {
        if gamut == .p3 {
            return false // Specifically deny P3 support
        }
        // Use the original implementation for other checks
        return self.swizzled_canRepresent(gamut)
    }

    @objc var swizzled_colorSpace: NSColorSpace? {
        return NSColorSpace.sRGB // Return standard sRGB instead of P3 or DeviceRGB
    }
}
