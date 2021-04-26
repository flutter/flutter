import Flutter
import UIKit

public class SwiftEchoPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let basicStandard = FlutterBasicMessageChannel(
      name: "dev.flutter.echo.basic.standard", binaryMessenger: registrar.messenger(),
      codec: FlutterStandardMessageCodec.sharedInstance())
    basicStandard.setMessageHandler { (input, reply) in
      reply(input)
    }
  }
}
