// Generated file. Do not edit.

import Foundation

/// A helper class for the `FlutterAssembleTool`.
public class FlutterAssembleToolHelper {
  /// Ensures the correct build mode is being used for Flutter artifacts and re-builds the
  /// Flutter application if possible.
  ///
  /// If a Flutter application path is set, this will call `flutter assemble` to re-build,
  /// codesign, and embed the Flutter.framework and App.framework. Otherwise, this will copy and
  /// codesign the correct build mode version of the Flutter.framework and App.framework into the
  /// app bundle if needed.
  ///
  /// `flutter assemble` is not compatible with and will be skipped when User Script Sandboxing
  /// is enabled. Also, copying into the app bundle is not allowed. This will throw and error with
  /// guidance on how to switch build modes.
  ///
  /// - Parameters:
  ///   - targetBuildMode: The build mode the app is being built for.
  ///   - targetPlatform: The platform (iOS or macOS) the app is being built for.
  ///   - env: A dictionary of environment variables.
  ///   - fileManager: The file manager to use for file operations.
  ///   - processManager: The process runner to use.
  /// - Throws: `XcodeErrorAndExit.error` on failure.
  public static func run(
    targetBuildMode: String,
    targetPlatform: FlutterPlatform,
    env: [String: String],
    fileManager: FlutterToolsFileManager,
    processManager: FlutterProcessRunner
  ) throws {
    let sandboxing = try FlutterToolHelper.findOrExit(
      env: env,
      key: "ENABLE_USER_SCRIPT_SANDBOXING"
    )
    let appPath = try flutterApplicationPath(env: env, fileManager: fileManager)
    let packagePath = try FlutterToolHelper.findOrExit(
      env: env,
      key: "FLUTTER_NATIVE_INTEGRATION_PACKAGE_PATH"
    )

    if sandboxing == "YES" {
      try runInSandbox(
        appPath: appPath,
        packagePath: packagePath,
        targetBuildMode: targetBuildMode,
        targetPlatform: targetPlatform,
        env: env,
        fileManager: fileManager
      )
      return
    }

    if let appPath {
      try FlutterToolHelper.updateSymlink(
        targetBuildMode: targetBuildMode,
        integrationPackagePath: packagePath,
        fileManager: fileManager
      )
      try assemble(
        appPath: appPath,
        targetPlatform: targetPlatform,
        env: env,
        fileManager: fileManager,
        processManager: processManager
      )
      return
    }

    try verifyBuildModeAndUpdateIfNeeded(
      packagePath: packagePath,
      targetBuildMode: targetBuildMode,
      targetPlatform: targetPlatform,
      env: env,
      fileManager: fileManager,
      processManager: processManager
    )
  }

  /// Verify the Flutter framework build mode, throwing guided error if the build mode is incorrect.
  ///
  /// If sandboxing is enabled, `flutter assemble` cannot be run. This method
  /// verifies the Flutter framework and updates the symlink if necessary.
  ///
  /// - Parameters:
  ///   - appPath: The path to the Flutter application.
  ///   - packagePath: The path to the native integration package.
  ///   - targetBuildMode: The build mode the app is being built for.
  ///   - targetPlatform: The platform (iOS or macOS) the app is being built for.
  ///   - env: A dictionary of environment variables.
  ///   - fileManager: The file manager to use for file operations.
  /// - Throws: `XcodeErrorAndExit.error` if build mode is incorrect.
  static func runInSandbox(
    appPath: String?,
    packagePath: String,
    targetBuildMode: String,
    targetPlatform: FlutterPlatform,
    env: [String: String],
    fileManager: FlutterToolsFileManager
  ) throws {
    if appPath != nil {
      let messages = [
        "ENABLE_USER_SCRIPT_SANDBOXING is enabled. Flutter is unable to rebuild the Flutter app when sandboxing is enabled.",
        "To rebuild the Flutter app as part of the Xcode build, please set ENABLE_USER_SCRIPT_SANDBOXING=NO in your build settings.",
        "Otherwise, to build any changes to your Flutter app, you will need to re-run \"flutter build swift-package\" from within your Flutter application.",
        "Alternatively, you can remove FLUTTER_APPLICATION_PATH from your build settings to dismiss this warning."
      ]
      for message in messages {
        FlutterToolHelper.xcodeWarning(message: message)
      }
    }
    do {
      try verifyFlutterFrameworkBuildMode(
        packagePath: packagePath,
        targetBuildMode: targetBuildMode,
        targetPlatform: targetPlatform,
        env: env,
        fileManager: fileManager
      )
    } catch XcodeErrorAndExit.error(let errorMessages) {
      let mismatchError = errorMessages.contains(where: {
        $0.range(of: "build mode does not match", options: .caseInsensitive)
          != nil
      })
      if !mismatchError {
        throw XcodeErrorAndExit.error(errorMessages)
      }
      FlutterToolHelper.xcodeError(
        message:
          "Flutter build mode has changed. ENABLE_USER_SCRIPT_SANDBOXING is enabled."
      )
      FlutterToolHelper.xcodeError(
        message:
          "Unable to change already built artifacts. Updating build mode for next build..."
      )
      try FlutterToolHelper.updateSymlink(
        targetBuildMode: targetBuildMode,
        integrationPackagePath: packagePath,
        fileManager: fileManager
      )
      throw XcodeErrorAndExit.error(
        [
          "Please re-run.",
          "To avoid this error when switching build modes, you can set ENABLE_USER_SCRIPT_SANDBOXING=NO.",
          "Or you can complete one of the following actions before building:",
        ]
          + pluginInstructions(
            targetBuildMode: targetBuildMode,
            packagePath: packagePath
          )
      )
    }
  }

  /// Verifies that the Flutter framework has the correct build mode.
  ///
  /// - Parameters:
  ///   - packagePath: The path to the native integration package.
  ///   - targetBuildMode: The build mode the app is being built for.
  ///   - targetPlatform: The platform (iOS or macOS) the app is being built for.
  ///   - verifyBuiltProducts: Whether to verify `BUILT_PRODUCTS_DIR`.
  ///   - env: A dictionary of environment variables.
  ///   - fileManager: The file manager to use for file operations.
  /// - Throws: `XcodeErrorAndExit.error` if the framework build mode is incorrect.
  static func verifyFlutterFrameworkBuildMode(
    packagePath: String,
    targetBuildMode: String,
    targetPlatform: FlutterPlatform,
    verifyBuiltProducts: Bool = true,
    env: [String: String],
    fileManager: FlutterToolsFileManager
  ) throws {
    let expectedBuildMode = try expectedBuildModeForSDK(
      targetBuildMode: targetBuildMode,
      targetPlatform: targetPlatform,
      env: env
    )

    // Verify build mode of framework in BUILT_PRODUCTS_DIR
    if verifyBuiltProducts {
      let builtProductsDir = try FlutterToolHelper.findOrExit(
        env: env,
        key: "BUILT_PRODUCTS_DIR"
      )
      try verifyFrameworkBuildMode(
        buildDirectory: builtProductsDir,
        expectedBuildMode: expectedBuildMode,
        packagePath: packagePath,
        targetBuildMode: targetBuildMode,
        targetPlatform: targetPlatform,
        env: env,
        fileManager: fileManager
      )
    }

    // Verify build mode of framework in TARGET_BUILD_DIR/FRAMEWORKS_FOLDER_PATH
    let targetBuildDir = try FlutterToolHelper.findOrExit(
      env: env,
      key: "TARGET_BUILD_DIR"
    )
    let frameworksFolderPath = try FlutterToolHelper.findOrExit(
      env: env,
      key: "FRAMEWORKS_FOLDER_PATH"
    )
    let embeddedFrameworks = "\(targetBuildDir)/\(frameworksFolderPath)"
    try verifyFrameworkBuildMode(
      buildDirectory: embeddedFrameworks,
      expectedBuildMode: expectedBuildMode,
      packagePath: packagePath,
      targetBuildMode: targetBuildMode,
      targetPlatform: targetPlatform,
      env: env,
      fileManager: fileManager
    )

    FlutterToolHelper.xcodeNote(
      message: "Verification complete."
    )
  }

  /// Verifies the Flutter framework's build mode.
  ///
  /// Parses the framework's Info.plist for the `BuildMode` key and compares it to the expected
  /// build mode.
  ///
  /// - Parameters:
  ///   - buildDirectory: The directory containing the framework.
  ///   - expectedBuildMode: The expected build mode.
  ///   - packagePath: The path to the native integration package.
  ///   - targetBuildMode: The build mode the app is being built for.
  ///   - targetPlatform: The platform (iOS or macOS) the app is being built for.
  ///   - env: A dictionary of environment variables.
  ///   - fileManager: The file manager to use for file operations.
  /// - Throws: `XcodeErrorAndExit.error` if the build mode does not match.
  private static func verifyFrameworkBuildMode(
    buildDirectory: String,
    expectedBuildMode: String,
    packagePath: String,
    targetBuildMode: String,
    targetPlatform: FlutterPlatform,
    env: [String: String],
    fileManager: FlutterToolsFileManager
  ) throws {
    let frameworkInfoPlistURL = flutterFrameworkInfoPlist(
      buildDirectory: buildDirectory,
      targetPlatform: targetPlatform
    )

    let actualBuildMode = try buildModeFromInfoPlist(
      frameworkInfoPlistURL: frameworkInfoPlistURL,
      fileManager: fileManager
    )

    // Verify expected and actual build mode matches
    if actualBuildMode.lowercased() != expectedBuildMode.lowercased() {
      throw XcodeErrorAndExit.error(
        [
          "The Flutter framework's build mode does not match the currently targeted build mode.",
          "Expected \(targetBuildMode) but found \(actualBuildMode) for \(frameworkInfoPlistURL.path).",
          "Please complete one of the following:",
        ]
          + pluginInstructions(
            targetBuildMode: targetBuildMode,
            packagePath: packagePath
          )
      )
    }
  }

  private static func pluginInstructions(targetBuildMode: String, packagePath: String) -> [String] {
    return [
      "   1) Right click on FlutterNativeIntegration in Xcode's Project Navigator and select "
        + "\"Switch to \(targetBuildMode) Mode\".",
      "   or",
      "   2) Run the following in a terminal:",
      "       cd \(packagePath)",
      "       swift package plugin --allow-writing-to-package-directory switch-to-\(targetBuildMode.lowercased())",
    ]
  }

  /// Determines the path to the framework's Info.plist.
  ///
  /// This path varies between iOS and macOS.
  ///
  /// - Parameters:
  ///   - buildDirectory: The directory containing the framework.
  ///   - targetPlatform: The platform (iOS or macOS) the app is being built for.
  /// - Returns: The URL to the Info.plist.
  private static func flutterFrameworkInfoPlist(
    buildDirectory: String,
    targetPlatform: FlutterPlatform
  ) -> URL {
    let infoPlistRelativePath =
      (targetPlatform == .macos)
      ? "FlutterMacOS.framework/Resources/Info.plist"
      : "Flutter.framework/Info.plist"

    return URL(fileURLWithPath: buildDirectory).appendingPathComponent(
      infoPlistRelativePath
    )
  }

  /// Determines the expected build mode for the given SDK.
  ///
  /// Simulator framework are always expected to have "debug" build mode.
  ///
  /// - Parameters:
  ///   - targetBuildMode: The build mode the app is being built for.
  ///   - targetPlatform: The platform (iOS or macOS) the app is being built for.
  ///   - env: A dictionary of environment variables.
  /// - Returns: The expected build mode.
  /// - Throws: `XcodeErrorAndExit.error` if unable to determine the SDK.
  private static func expectedBuildModeForSDK(
    targetBuildMode: String,
    targetPlatform: FlutterPlatform,
    env: [String: String]
  ) throws -> String {
    if targetPlatform == .ios {
      let isSimulatorBuild = try FlutterToolHelper.usingSimulatorSDK(env: env)
      if isSimulatorBuild {
        return "debug"
      }
    }
    return targetBuildMode
  }

  /// Parses the build mode from an Info.plist file.
  ///
  /// - Parameters:
  ///   - frameworkInfoPlistURL: The URL to the Info.plist file.
  ///   - fileManager: The file manager to use for file operations.
  /// - Returns: The parsed build mode.
  /// - Throws: `XcodeErrorAndExit.error` if unable to parse the build mode.
  private static func buildModeFromInfoPlist(
    frameworkInfoPlistURL: URL,
    fileManager: FlutterToolsFileManager
  ) throws -> String {
    do {
      guard let data = fileManager.contents(atPath: frameworkInfoPlistURL.path)
      else {
        throw XcodeErrorAndExit.error([
          "Failed to read \(frameworkInfoPlistURL)"
        ])
      }
      guard
        let plist = try PropertyListSerialization.propertyList(
          from: data,
          options: [],
          format: nil
        ) as? [String: Any]
      else {
        throw XcodeErrorAndExit.error([
          "Failed to parse \(frameworkInfoPlistURL)"
        ])
      }
      guard let parsedBuildMode = plist["BuildMode"] as? String else {
        throw XcodeErrorAndExit.error([
          "Failed to read BuildMode from \(frameworkInfoPlistURL)"
        ])
      }
      return parsedBuildMode
    } catch let error as XcodeErrorAndExit {
      throw error
    } catch {
      throw XcodeErrorAndExit.error([
        "Failed to read contents of \(frameworkInfoPlistURL): \(error.localizedDescription)"
      ])
    }
  }

  /// Verifies the build mode and updates the Flutter and App framework symlink if needed.
  ///
  /// This method is called when `FLUTTER_APPLICATION_PATH` is not set. It ensures
  /// that the Flutter and App frameworks match the target build mode.
  ///
  /// - Parameters:
  ///   - packagePath: The path to the native integration package.
  ///   - targetBuildMode: The build mode the app is being built for.
  ///   - targetPlatform: The platform (iOS or macOS) the app is being built for.
  ///   - env: A dictionary of environment variables.
  ///   - fileManager: The file manager to use for file operations.
  ///   - processManager: The process runner to use.
  /// - Throws: `XcodeErrorAndExit.error` if the verification or update fails.
  private static func verifyBuildModeAndUpdateIfNeeded(
    packagePath: String,
    targetBuildMode: String,
    targetPlatform: FlutterPlatform,
    env: [String: String],
    fileManager: FlutterToolsFileManager,
    processManager: FlutterProcessRunner
  ) throws {
    var updated = false
    do {
      try verifyFlutterFrameworkBuildMode(
        packagePath: packagePath,
        targetBuildMode: targetBuildMode,
        targetPlatform: targetPlatform,
        env: env,
        fileManager: fileManager
      )
    } catch {
      // If it fails to verify, update the build mode
      try FlutterToolHelper.updateSymlink(
        targetBuildMode: targetBuildMode,
        integrationPackagePath: packagePath,
        fileManager: fileManager
      )
      // Copy and codesign
      try copyAndCodesignFramework(
        frameworkName: targetPlatform == .ios ? "Flutter" : "FlutterMacOS",
        packagePath: packagePath,
        targetBuildMode: targetBuildMode,
        targetPlatform: targetPlatform,
        env: env,
        fileManager: fileManager,
        processManager: processManager
      )
      try copyAndCodesignFramework(
        frameworkName: "App",
        packagePath: packagePath,
        targetBuildMode: targetBuildMode,
        targetPlatform: targetPlatform,
        env: env,
        fileManager: fileManager,
        processManager: processManager
      )
      updated = true
    }
    if updated {
      // This only verified the Flutter framework. The App.framework is assumed to be correct if
      // the Flutter framework is since they come from the same source.
      try verifyFlutterFrameworkBuildMode(
        packagePath: packagePath,
        targetBuildMode: targetBuildMode,
        targetPlatform: targetPlatform,
        // The tool only copies and codesigns into the app bundle, so we should not verify
        // `BUILT_PRODUCTS_DIR`.
        verifyBuiltProducts: false,
        env: env,
        fileManager: fileManager
      )
    }
  }

  /// Calls the Flutter tool to assemble the App framework.
  ///
  /// - Parameters:
  ///   - appPath: The path to the Flutter application.
  ///   - targetPlatform: The platform (iOS or macOS) the app is being built for.
  ///   - env: A dictionary of environment variables.
  ///   - fileManager: The file manager to use for file operations.
  ///   - processManager: The process runner to use.
  /// - Throws: `XcodeErrorAndExit.error` if the assembly fails.
  static func assemble(
    appPath: String,
    targetPlatform: FlutterPlatform,
    env: [String: String],
    fileManager: FlutterToolsFileManager,
    processManager: FlutterProcessRunner
  ) throws {
    // Get the environment by parsing flutter_native_integration.env and merging the exported
    // variables with the Xcode environment.
    let exportedEnvPath = try exportedEnvPath(
      appPath: appPath,
      platform: targetPlatform,
      fileManager: fileManager
    )
    let exportedEnv = try environmentFromBashExports(
      exportedEnvPath: exportedEnvPath,
      fileManager: fileManager
    )
    let mergedEnvironment = mergeEnvironment(
      xcodeEnv: env,
      flutterExportedEnv: exportedEnv
    )

    // Verify Flutter root exists
    let flutterRoot = try FlutterToolHelper.findOrExit(
      env: mergedEnvironment,
      key: "FLUTTER_ROOT"
    )
    if !fileManager.fileExists(atPath: flutterRoot) {
      throw XcodeErrorAndExit.error([
        "FLUTTER_ROOT is set to \(flutterRoot), but could not be located."
      ])
    }

    // Call xcode_backend.dart from within the Flutter root
    let dartExecutable = "\(flutterRoot)/bin/dart"
    let xcodeBackendScript =
      "\(flutterRoot)/packages/flutter_tools/bin/xcode_backend.dart"
    let command = "build-add-to-app"
    try processManager.run(
      executableURL: URL(fileURLWithPath: dartExecutable),
      arguments: [xcodeBackendScript, command, targetPlatform.rawValue],
      env: mergedEnvironment,
      failOnError: true
    )
  }

  /// Finds the path to the Flutter application.
  ///
  /// - Parameters:
  ///   - env: A dictionary of environment variables.
  ///   - fileManager: The file manager to use for file operations.
  /// - Returns: The path to the Flutter application, or `nil` if not set.
  /// - Throws: `XcodeErrorAndExit.error` if the path is set but does not exist.
  private static func flutterApplicationPath(
    env: [String: String],
    fileManager: FlutterToolsFileManager
  ) throws -> String? {
    guard let flutterAppPath = env["FLUTTER_APPLICATION_PATH"],
      !flutterAppPath.isEmpty
    else {
      return nil
    }
    var resolvedPath = flutterAppPath
    if !flutterAppPath.hasPrefix("/") {
      let srcRoot = try FlutterToolHelper.findOrExit(env: env, key: "SRCROOT")
      resolvedPath = "\(srcRoot)/\(flutterAppPath)"
    }

    // Verify the Flutter app exists
    if !fileManager.fileExists(atPath: resolvedPath) {
      throw XcodeErrorAndExit.error([
        "FLUTTER_APPLICATION_PATH is set to \(resolvedPath), but could not be located."
      ])
    }
    return resolvedPath
  }

  /// Finds the path to the `flutter_native_integration.env` file.
  ///
  /// - Parameters:
  ///   - appPath: The path to the Flutter application.
  ///   - platform: The platform (iOS or macOS) the app is being built for.
  ///   - fileManager: The file manager to use for file operations.
  /// - Returns: The path to the `flutter_native_integration.env` file.
  /// - Throws: `XcodeErrorAndExit.error` if the file cannot be located.
  private static func exportedEnvPath(
    appPath: String,
    platform: FlutterPlatform,
    fileManager: FlutterToolsFileManager
  ) throws -> String {
    let path = "\(appPath)/\(platform)/Flutter/ephemeral/flutter_native_integration.env"
    if fileManager.fileExists(atPath: path) {
      return path
    }
    if platform == FlutterPlatform.ios {
      let modulePath = "\(appPath)/.ios/Flutter/ephemeral/flutter_native_integration.env"
      if fileManager.fileExists(atPath: modulePath) {
        return modulePath
      }
    }
    throw XcodeErrorAndExit.error([
      "Unable to rebuild Flutter app. Failed to find \(path)"
    ])
  }

  /// Parses environment variables from a bash script.
  ///
  /// The `flutter_native_integration.env` is a bash file that exports the variables.
  /// ```
  /// FLUTTER_TARGET=lib/main.dart
  /// FLUTTER_BUILD_DIR=build
  /// ```
  ///
  /// - Parameters:
  ///   - exportedEnvPath: The path to the bash script.
  ///   - fileManager: The file manager to use for file operations.
  /// - Returns: A dictionary of environment variables.
  /// - Throws: `XcodeErrorAndExit.error` if unable to read or parse the script.
  private static func environmentFromBashExports(
    exportedEnvPath: String,
    fileManager: FlutterToolsFileManager
  ) throws -> [String: String] {
    guard let data = fileManager.contents(atPath: exportedEnvPath) else {
      throw XcodeErrorAndExit.error([
        "Unable to rebuild Flutter app. Failed to read contents of \(exportedEnvPath)"
      ])
    }
    guard let contents = String(data: data, encoding: .utf8) else {
      throw XcodeErrorAndExit.error([
        "Unable to rebuild Flutter app. Failed to encode contents of \(exportedEnvPath)"
      ])
    }

    var exportedEnv: [String: String] = [:]
    contents.enumerateLines { line, _ in
      guard let equalIndex = line.firstIndex(of: "=") else {
        return
      }
      let key = String(line[..<equalIndex]).trimmingCharacters(in: .whitespaces)
      let value = String(line[line.index(after: equalIndex)...])
      exportedEnv[key] = value
    }
    return exportedEnv
  }

  /// Merges two environment dictionaries with the `xcodeEnv` taking precedence.
  ///
  /// - Parameters:
  ///   - xcodeEnv: The primary environment dictionary.
  ///   - flutterExportedEnv: The secondary environment dictionary.
  /// - Returns: The merged environment dictionary.
  private static func mergeEnvironment(
    xcodeEnv: [String: String],
    flutterExportedEnv: [String: String]
  ) -> [String: String] {
    return xcodeEnv.merging(flutterExportedEnv) { (current, _) in current }
  }

  /// Copies the Flutter framework to `BUILT_PRODUCTS_DIR`.
  ///
  /// - Parameters:
  ///   - frameworkName: The name of the framework to copy.
  ///   - packagePath: The path to the native integration package.
  ///   - targetBuildMode: The build mode the app is being built for.
  ///   - targetPlatform: The platform (iOS or macOS) the app is being built for.
  ///   - env: A dictionary of environment variables.
  ///   - fileManager: The file manager to use for file operations.
  ///   - processManager: The process runner to use.
  /// - Throws: `XcodeErrorAndExit.error` if the copy fails.
  static func copyAndCodesignFramework(
    frameworkName: String,
    packagePath: String,
    targetBuildMode: String,
    targetPlatform: FlutterPlatform,
    env: [String: String],
    fileManager: FlutterToolsFileManager,
    processManager: FlutterProcessRunner
  ) throws {
    // Verify XCFramework for the build mode exists
    let xcframeworkURL = URL(
      fileURLWithPath:
        "\(packagePath)/\(targetBuildMode)/Frameworks/\(frameworkName).xcframework"
    )
    if !fileManager.fileExists(atPath: xcframeworkURL.path) {
      throw XcodeErrorAndExit.error([
        "FlutterPluginRegistrant does not exist for build mode \(targetBuildMode). "
          + "You may need to run \"flutter build swift-package --build-mode "
          + "\(targetBuildMode.lowercased())\" in your Flutter app."
      ])
    }

    let targetBuildDir = try FlutterToolHelper.findOrExit(
      env: env,
      key: "TARGET_BUILD_DIR"
    )
    let frameworksFolderPath = try FlutterToolHelper.findOrExit(
      env: env,
      key: "FRAMEWORKS_FOLDER_PATH"
    )
    let embeddedFrameworks = "\(targetBuildDir)/\(frameworksFolderPath)"
    do {
      // Find the framework for the platform
      let frameworkPath = try findPlatformFramework(
        frameworkName: frameworkName,
        xcframeworkURL: xcframeworkURL,
        targetPlatform: targetPlatform,
        env: env,
        fileManager: fileManager
      )
      // Copy the platform framework to the FRAMEWORKS_FOLDER_PATH
      try rsyncFramework(
        source: frameworkPath,
        destination: URL(fileURLWithPath: embeddedFrameworks),
        processManager: processManager
      )

      if let codesignIdentity = env["EXPANDED_CODE_SIGN_IDENTITY"] {
        if env["CODE_SIGNING_REQUIRED"] != "NO" {
          try processManager.run(
            executableURL: URL(fileURLWithPath: "/usr/bin/codesign"),
            arguments: [
              "--force", "--verbose", "--sign", codesignIdentity, "--",
              "\(embeddedFrameworks)/\(frameworkPath.lastPathComponent)/\(frameworkName)",
            ],
            env: nil,
            failOnError: true
          )
        }
      }
    } catch let error as XcodeErrorAndExit {
      throw error
    } catch {
      throw XcodeErrorAndExit.error([
        "Unable to copy \(xcframeworkURL): \(error.localizedDescription)"
      ])
    }
  }

  /// Finds the framework for the target platform within an XCFramework.
  ///
  /// - Parameters:
  ///   - frameworkName: The name of the framework.
  ///   - xcframeworkURL: The URL to the XCFramework.
  ///   - targetPlatform: The platform (iOS or macOS) the app is being built for.
  ///   - env: A dictionary of environment variables.
  ///   - fileManager: The file manager to use for file operations.
  /// - Returns: The URL to the platform-specific framework.
  /// - Throws: `XcodeErrorAndExit.error` if the framework cannot be found.
  static func findPlatformFramework(
    frameworkName: String,
    xcframeworkURL: URL,
    targetPlatform: FlutterPlatform,
    env: [String: String],
    fileManager: FlutterToolsFileManager
  ) throws -> URL {
    var isSimulatorBuild = false
    if targetPlatform == .ios {
      isSimulatorBuild = try FlutterToolHelper.usingSimulatorSDK(env: env)
    }
    for file in try fileManager.contentsOfDirectory(
      at: xcframeworkURL,
      includingPropertiesForKeys: nil,
      options: []
    ) {
      let platformDirectory = file.lastPathComponent
      if !platformDirectory.starts(with: "\(targetPlatform)-") {
        continue
      }
      let simulatorDirectory = platformDirectory.hasSuffix("-simulator")
      if isSimulatorBuild == simulatorDirectory {
        return file.appendingPathComponent("\(frameworkName).framework")
      }
    }
    throw XcodeErrorAndExit.error([
      "Unable to find \(frameworkName) framework within \(xcframeworkURL.path)"
    ])
  }

  /// Synchronizes a framework from source to destination using `rsync`.
  ///
  /// - Parameters:
  ///   - source: The source URL of the framework.
  ///   - destination: The destination URL of the framework.
  ///   - processManager: The process runner to use.
  /// - Throws: `XcodeErrorAndExit.error` if the synchronization fails.
  private static func rsyncFramework(
    source: URL,
    destination: URL,
    processManager: FlutterProcessRunner
  ) throws {
    var additionalFilters: [String] = []
    if source.lastPathComponent == "FlutterMacOS.framework" {
      additionalFilters = ["--filter", "- Headers", "--filter", "- Modules"]
    }
    try processManager.run(
      executableURL: URL(fileURLWithPath: "/usr/bin/rsync"),
      arguments: ["-av", "--delete", "--filter", "- .DS_Store/"]
        + additionalFilters + [
          "--chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r", source.path, destination.path,
        ],

      env: nil,
      failOnError: true
    )
  }
}
