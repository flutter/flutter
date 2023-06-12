import Flutter
import UIKit

public class SwiftAssetsAudioPlayerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let music = Music(messenger: registrar.messenger(), registrar: registrar)
    music.start()
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

  }
}
