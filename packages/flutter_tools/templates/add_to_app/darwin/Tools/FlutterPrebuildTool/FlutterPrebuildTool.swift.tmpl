// Generated file. Do not edit.

import FlutterToolHelper
import Foundation

/// Executable tool that is expected to be called from a Xcode build phase for an iOS or macOS app.
///
/// This tool is expected to run after the Flutter.framework and App.framework have been embedded
/// in the app.
///
/// This tool verifies the embedded Flutter framework is the correct build mode. Otherwise, it will
/// re-embed and codesign the correct version of the framework when sandboxing is disabled or it
/// will throw if sandboxing is enabled.
///
/// This tool also calls into the Flutter CLI to re-build and embed the App.framework if possible.
@main
struct FlutterPrebuildTool {
  static func main() {
    let env = ProcessInfo.processInfo.environment
    do {
      let fileManager = FileManager.default
      let mode = try FlutterToolHelper.parseFlutterBuildMode(env: env)

      let packagePath = try FlutterToolHelper.findOrExit(
        env: env,
        key: "FLUTTER_NATIVE_INTEGRATION_PACKAGE_PATH"
      )

      try FlutterToolHelper.updateSymlink(
        targetBuildMode: mode,
        integrationPackagePath: packagePath,
        fileManager: fileManager
      )
    } catch XcodeErrorAndExit.error(let errorMessages) {
      for line in errorMessages {
        FlutterToolHelper.xcodeError(message: line)
      }
      exit(EXIT_FAILURE)
    } catch {
      FlutterToolHelper.xcodeError(
        message: "Failed to run FlutterAssembleTool: \(error.localizedDescription)"
      )
      exit(EXIT_FAILURE)
    }
  }
}

extension FileManager: FlutterToolsFileManager {}
