import Flutter
import UIKit

public final class FlutterCodePushPlugin: NSObject, FlutterPlugin {
  private let storage = CodePushStorage()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "dev.flutter.codepush/updater",
      binaryMessenger: registrar.messenger()
    )
    let instance = FlutterCodePushPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    do {
      switch call.method {
      case "readCurrentPatchNumber":
        result(try storage.readCurrentPatchNumber())
      case "stagePatchFromUrls":
        try stagePatchFromUrls(call)
        result(nil)
      case "applyStagedPatch":
        try storage.applyStagedPatch()
        result(nil)
      case "clearActivePatch":
        try storage.clearActivePatch()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    } catch {
      result(
        FlutterError(
          code: "code_push_error",
          message: error.localizedDescription,
          details: nil
        )
      )
    }
  }

  private func stagePatchFromUrls(_ call: FlutterMethodCall) throws {
    guard let arguments = call.arguments as? [String: Any],
      let patchNumber = arguments["patch_number"] as? Int,
      let releaseVersion = arguments["release_version"] as? String,
      let dataDownloadURL = arguments["data_download_url"] as? String,
      let instrDownloadURL = arguments["instr_download_url"] as? String,
      let dataSha256 = arguments["isolate_data_sha256"] as? String,
      let instrSha256 = arguments["isolate_instr_sha256"] as? String
    else {
      throw NSError(
        domain: "FlutterCodePushPlugin",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Missing required patch fields."]
      )
    }

    try storage.stagePatchFromUrls(
      patchNumber: patchNumber,
      releaseVersion: releaseVersion,
      dataDownloadURL: dataDownloadURL,
      instrDownloadURL: instrDownloadURL,
      dataSha256: dataSha256,
      instrSha256: instrSha256,
      dataLengthBytes: arguments["isolate_data_length_bytes"] as? Int,
      instrLengthBytes: arguments["isolate_instr_length_bytes"] as? Int,
      enabled: arguments["enabled"] as? Bool ?? true
    )
  }
}
