#if canImport(FlutterMacOS)
    import Cocoa
    import FlutterMacOS
#endif

public class AssetsAudioPlayer: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let music = Music(messenger: registrar.messenger, registrar: registrar)
    music.start()
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

  }
}
