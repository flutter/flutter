import Flutter
import UIKit

public class SwiftFlutterUnityWidgetPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let fuwFactory = FLTUnityWidgetFactory(registrar: registrar)
        registrar.register(fuwFactory, withId: "plugin.xraph.com/unity_view", gestureRecognizersBlockingPolicy: FlutterPlatformViewGestureRecognizersBlockingPolicyWaitUntilTouchesEnded)
    }
}
