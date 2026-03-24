import Cocoa
import FlutterMacOS
import Foundation

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
    let flutterView = flutterViewController.view
    // Use NSSelectorFromString to avoid "no method declared" compiler warnings for private selectors
    let wideGamutSelector = NSSelectorFromString("setEnableWideGamut:")
    if flutterView.responds(to: wideGamutSelector) {
        typealias SetWideGamutFunc = @convention(c) (NSView, Selector, Bool) -> Void
        let imp = flutterView.method(for: wideGamutSelector)
        let fn = unsafeBitCast(imp, to: SetWideGamutFunc.self)
        fn(flutterView, wideGamutSelector, true)
    }

    super.awakeFromNib()
  }

  private static func doSwizzleOnce() {
    guard !swizzled else { return }
    swizzled = true

    // Swizzle NSScreen.canRepresent(_:)
    // #selector resolves to the correct Objective-C "canRepresentDisplayGamut:" selector
    let originalCanRepresent = #selector(NSScreen.canRepresent(_:))
    let swizzledCanRepresent = #selector(NSScreen.swizzled_canRepresentDisplayGamut(_:))
    
    if let original = class_getInstanceMethod(NSScreen.self, originalCanRepresent),
       let swizzled = class_getInstanceMethod(NSScreen.self, swizzledCanRepresent) {
        method_exchangeImplementations(original, swizzled)
    }

    // Swizzle NSScreen.colorSpace
    let originalColorSpace = #selector(getter: NSScreen.colorSpace)
    let swizzledColorSpace = #selector(getter: NSScreen.swizzled_colorSpace)
    
    if let original = class_getInstanceMethod(NSScreen.self, originalColorSpace),
       let swizzled = class_getInstanceMethod(NSScreen.self, swizzledColorSpace) {
        method_exchangeImplementations(original, swizzled)
    }
  }
}

extension NSScreen {
    @objc(swizzled_canRepresentDisplayGamut:)
    func swizzled_canRepresentDisplayGamut(_ gamut: NSDisplayGamut) -> Bool {
        if gamut == .p3 {
            return true
        }
        return self.swizzled_canRepresentDisplayGamut(gamut)
    }

    @objc var swizzled_colorSpace: NSColorSpace? {
        return NSColorSpace.displayP3
    }
}
