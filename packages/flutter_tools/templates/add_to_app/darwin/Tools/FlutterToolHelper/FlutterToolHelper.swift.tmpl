//  Generated file. Do not edit.

import Foundation

/// A helper class for Flutter tools and plugins.
public class FlutterToolHelper {
  /// Parses the Flutter build mode from the environment variables.
  ///
  /// - Parameter env: A dictionary of environment variables.
  /// - Returns: The parsed build mode as a `String` (e.g., "Debug", "Profile", "Release").
  /// - Throws: `XcodeErrorAndExit.error` if the build mode cannot be determined.
  public static func parseFlutterBuildMode(env: [String: String]) throws -> String {
    // Get FLUTTER_BUILD_MODE or fallback to CONFIGURATION, then lowercase it
    let rawMode = (env["FLUTTER_BUILD_MODE"] ?? env["CONFIGURATION"] ?? "")
      .lowercased()

    let buildMode: String

    if rawMode.contains("release") {
      buildMode = "Release"
    } else if rawMode.contains("profile") {
      buildMode = "Profile"
    } else if rawMode.contains("debug") {
      buildMode = "Debug"
    } else {
      throw XcodeErrorAndExit.error([
        "Unknown FLUTTER_BUILD_MODE: \(rawMode)",
        "Valid values are 'Debug', 'Profile', or 'Release' (case insensitive).'",
        "This is controlled by the FLUTTER_BUILD_MODE environment variable.",
        "If that is not set, the CONFIGURATION environment variable is used.",
        "To fix this, please rename the \(rawMode) configuration to include an appropriate value or set FLUTTER_BUILD_MODE",
      ])
    }

    return buildMode
  }

  /// Determines the target platform (iOS or macOS) based on the environment variables.
  ///
  /// - Parameter env: A dictionary of environment variables.
  /// - Returns: The target `FlutterPlatform`.
  /// - Throws: `XcodeErrorAndExit.error` if the platform is unknown or unsupported.
  public static func targetPlatform(env: [String: String]) throws -> FlutterPlatform {
    let platformName = try findOrExit(env: env, key: "PLATFORM_NAME")
    if platformName.contains("macosx") {
      return .macos
    } else if platformName.contains("iphoneos")
      || platformName.contains("iphonesimulator") {
      return .ios
    } else {
      throw XcodeErrorAndExit.error([
        "Unknown PLATFORM_NAME: \(platformName). Flutter only supports iOS and macOS."
      ])
    }
  }

  /// Determines if the SDK being used during the build is for simulators by checking `SDKROOT`.
  ///
  /// - Parameter env: A dictionary of environment variables.
  /// - Returns: `true` if targeting a simulator, `false` otherwise.
  /// - Throws: `XcodeErrorAndExit.error` if `SDKROOT` is not found or does not match expected values for iOS and macOS.
  public static func usingSimulatorSDK(env: [String: String]) throws -> Bool {
    let sdkRoot = try findOrExit(env: env, key: "SDKROOT")
    let url = URL(fileURLWithPath: sdkRoot)
    let filenameWithExtension = url.lastPathComponent.lowercased()
    if !filenameWithExtension.contains("iphone")
      && !filenameWithExtension.contains("macosx") {
      throw XcodeErrorAndExit.error([
        "Unrecognized SDKROOT: \(sdkRoot). Flutter only supports iOS and macOS.",
      ])
    }
    return filenameWithExtension.contains("simulator")
  }

  /// Updates the `FlutterPluginRegistrant` symbolic link within the `FlutterNativeIntegration`
  /// package.
  ///
  /// - Parameters:
  ///   - targetBuildMode: The build mode the app is being built for and the destination the link
  ///     should point to.
  ///   - integrationPackagePath: The path to the FlutterNativeIntegration.
  ///   - fileManager: The file manager to use for file operations.
  /// - Throws: `XcodeErrorAndExit.error` if the update fails.
  public static func updateSymlink(
    targetBuildMode: String,
    integrationPackagePath: String,
    fileManager: FlutterToolsFileManager
  ) throws {
    let currentLinkName = "FlutterPluginRegistrant"
    let newLinkTarget = "./\(targetBuildMode)"

    // Check if current link exists and exit if it already matches
    let currentLinkPath = "\(integrationPackagePath)/\(currentLinkName)"
    let currentLinkTarget = try? fileManager.destinationOfSymbolicLink(
      atPath: currentLinkPath
    )
    if currentLinkTarget == newLinkTarget {
      FlutterToolHelper.xcodeNote(
        message: "\(currentLinkName) symlink is up-to-date."
      )
      return
    }

    // Verify new target exists
    let newTargetPath = "\(integrationPackagePath)/\(newLinkTarget)"
    if !fileManager.fileExists(atPath: newTargetPath) {
      let lowerBuildMode = targetBuildMode.lowercased()
      throw XcodeErrorAndExit.error([
        "\(currentLinkName) does not exist for build mode \(targetBuildMode). "
          + "You may need to run \"flutter build swift-package --build-mode \(lowerBuildMode)\" "
          + "in your Flutter app."
      ])
    }

    // Remove existing item if it exists so we can recreate the link
    if fileManager.fileExists(atPath: currentLinkPath) {
      try fileManager.removeItem(atPath: currentLinkPath)
    }

    do {
      // Create the symlink pointing to the new destination
      try fileManager.createSymbolicLink(
        atPath: currentLinkPath,
        withDestinationPath: newLinkTarget
      )
      FlutterToolHelper.xcodeNote(
        message:
          "\(currentLinkName) symlink updated to \(newLinkTarget)."
      )
    } catch {
      // If creating the symlink fails, recreate the previous one
      if let currentLinkTarget {
        try fileManager.createSymbolicLink(
          atPath: currentLinkPath,
          withDestinationPath: currentLinkTarget
        )
      }
      throw XcodeErrorAndExit.error([
        "Failed to update symlink: \(error.localizedDescription)"
      ])
    }
  }

  /// Finds a value for a key in the environment variables or throws an error.
  ///
  /// - Parameters:
  ///   - env: A dictionary of environment variables.
  ///   - key: The key to look up.
  /// - Returns: The value associated with the key.
  /// - Throws: `XcodeErrorAndExit.error` if the key is not found or the value is empty.
  public static func findOrExit(env: [String: String], key: String) throws -> String {
    guard let value = env[key] else {
      throw XcodeErrorAndExit.error(["\(key) not found in build settings."])
    }
    if value.isEmpty {
      throw XcodeErrorAndExit.error([
        "\(key) found in build settings but has no value."
      ])
    }
    return value
  }

  /// Prints an error message to `stdout` to be reported to the Xcode build system.
  ///
  ///  https://developer.apple.com/documentation/xcode/running-custom-scripts-during-a-build#Log-errors-and-warnings-from-your-script
  ///
  /// - Parameter message: The message to print.
  public static func xcodeError(message: String) {
    fputs("error: \(message)\n", stdout)
  }

  /// Prints an warning message to `stdout` to be reported to the Xcode build system.
  ///
  ///  https://developer.apple.com/documentation/xcode/running-custom-scripts-during-a-build#Log-errors-and-warnings-from-your-script
  ///
  /// - Parameter message: The message to print.
  public static func xcodeWarning(message: String) {
    fputs("warning: \(message)\n", stdout)
  }

  /// Prints an note message to `stdout` to be reported to the Xcode build system.
  ///
  ///  https://developer.apple.com/documentation/xcode/running-custom-scripts-during-a-build#Log-errors-and-warnings-from-your-script
  ///
  /// - Parameter message: The message to print.
  public static func xcodeNote(message: String) {
    fputs("note: \(message)\n", stdout)
  }

}

/// Supported target platforms for Flutter.
public enum FlutterPlatform: String, Sendable {
  case ios
  case macos
}

/// Represents an error that should be reported to Xcode before exiting.
public enum XcodeErrorAndExit: Error, Equatable {
  case error([String])
}

/// A protocol defining file operations required for Flutter tools.
public protocol FlutterToolsFileManager {
  func destinationOfSymbolicLink(atPath path: String) throws -> String

  func fileExists(atPath path: String) -> Bool

  func contents(atPath path: String) -> Data?

  func removeItem(at URL: URL) throws

  func removeItem(atPath path: String) throws

  func createSymbolicLink(
    atPath path: String,
    withDestinationPath destPath: String
  ) throws

  func contentsOfDirectory(
    at url: URL,
    includingPropertiesForKeys keys: [URLResourceKey]?,
    options mask: FileManager.DirectoryEnumerationOptions
  ) throws -> [URL]
}

/// A protocol for running external processes.
public protocol FlutterProcessRunner {
  /// Runs a process with the specified executable URL, arguments, and environment.
  ///
  /// - Parameters:
  ///   - executableURL: The URL of the executable to run.
  ///   - arguments: The arguments to pass to the executable.
  ///   - env: An optional dictionary of environment variables.
  ///   - failOnError: Whether to throw an error if the process fails.
  func run(
    executableURL: URL,
    arguments: [String],
    env: [String: String]?,
    failOnError: Bool
  ) throws
}

/// A concrete implementation of `FlutterProcessRunner` using `Process`.
public class FlutterProcessManager: FlutterProcessRunner {
  public init() {}

  public func run(
    executableURL: URL,
    arguments: [String],
    env: [String: String]? = nil,
    failOnError: Bool
  ) throws {
    #if os(macOS)
      do {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        if env != nil {
          process.environment = env
        }
        let stdPipe = Pipe()
        process.standardOutput = stdPipe
        process.standardError = stdPipe
        try process.run()
        process.waitUntilExit()

        let stdoutData = stdPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: stdoutData, as: UTF8.self)
        FlutterToolHelper.xcodeNote(message: output)
        if process.terminationStatus != 0 && failOnError {
          throw XcodeErrorAndExit.error([
            "\(executableURL) returned non-zero exit code: \(process.terminationStatus)"
          ])
        }
      } catch let error as XcodeErrorAndExit {
        throw error
      } catch {
        throw XcodeErrorAndExit.error([
          "Failed to run \(executableURL): \(error.localizedDescription)"
        ])
      }
    #endif
  }
}
