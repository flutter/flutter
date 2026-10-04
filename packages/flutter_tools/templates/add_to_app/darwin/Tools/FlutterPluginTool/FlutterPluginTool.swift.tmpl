// Generated file. Do not edit.

import FlutterToolHelper
import Foundation

/// Executable tool that is expected to be called from a Swift package plugin to change the build
/// mode of the `FlutterPluginRegistrant` swift package.
@main
struct FlutterPluginTool {
  static func main() throws {
    let (buildMode, packagePath) = try extractArguments(arguments: CommandLine.arguments)

    let fileManager = FileManager.default
    try FlutterToolHelper.updateSymlink(
      targetBuildMode: buildMode,
      integrationPackagePath: packagePath,
      fileManager: fileManager
    )
  }

  /// Extracts the build mode and package path from the command line arguments.
  ///
  /// - Parameter arguments: The command line arguments.
  /// - Returns: A tuple containing the build mode and package path.
  /// - Throws: `XcodeErrorAndExit.error` if the arguments are invalid.
  static func extractArguments(arguments: [String]) throws -> (String, String) {
    if arguments.count != 3 {
      throw XcodeErrorAndExit.error([
        "Invalid arguments: [\(arguments.joined(separator: ", "))]",
      ])
    }
    let buildMode = arguments[1]
    let validBuildModes = ["Debug", "Profile", "Release"]
    if !validBuildModes.contains(buildMode) {
      throw XcodeErrorAndExit.error(["Invalid build mode: \(buildMode)"])
    }
    let packagePath = arguments[2]
    if !packagePath.contains("FlutterNativeIntegration") {
      throw XcodeErrorAndExit.error(["Invalid package path: \(packagePath)"])
    }
    return (buildMode, packagePath)
  }
}

extension FileManager: FlutterToolsFileManager {}
