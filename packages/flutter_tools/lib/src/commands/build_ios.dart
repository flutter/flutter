// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../base/analyze_size.dart';
import '../base/common.dart';
import '../base/error_handling_io.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../base/terminal.dart';
import '../base/utils.dart';
import '../base/version.dart';
import '../build_info.dart';
import '../convert.dart';
import '../darwin/darwin.dart';
import '../doctor_validator.dart';
import '../globals.dart' as globals;
import '../ios/application_package.dart';
import '../ios/code_signing.dart';
import '../ios/mac.dart';
import '../ios/plist_parser.dart';
import '../runner/flutter_command.dart';
import 'build.dart';

/// Builds an .app for an iOS app to be used for local testing on an iOS device
/// or simulator. Can only be run on a macOS host.
class BuildIOSCommand extends _BuildIOSSubCommand {
  BuildIOSCommand({required super.logger, required bool verboseHelp})
    : super(verboseHelp: verboseHelp) {
    addPublishPort(verboseHelp: verboseHelp);
    argParser
      ..addFlag(
        'config-only',
        help:
            'Update the project configuration without performing a build. '
            'This can be used in CI/CD process that create an archive to avoid '
            'performing duplicate work.',
      )
      ..addFlag(
        'simulator',
        help:
            'Build for the iOS simulator instead of the device. This changes '
            'the default build mode to debug if otherwise unspecified.',
      );
  }

  @override
  final name = 'ios';

  @override
  final description = 'Build an iOS application bundle.';

  @override
  final XcodeBuildAction xcodeBuildAction = XcodeBuildAction.build;

  @override
  EnvironmentType get environmentType =>
      boolArg('simulator') ? EnvironmentType.simulator : EnvironmentType.physical;

  @override
  bool get configOnly => boolArg('config-only');

  @override
  Directory _outputAppDirectory(String xcodeResultOutput) =>
      globals.fs.directory(xcodeResultOutput).parent;
}

/// The key that uniquely identifies an image file in an image asset.
/// It consists of (idiom, scale, size?), where size is present for app icon
/// asset, and null for launch image asset.
@immutable
class _ImageAssetFileKey {
  const _ImageAssetFileKey(this.idiom, this.scale, this.size);

  /// The idiom (iphone or ipad).
  final String idiom;

  /// The scale factor (e.g. 2).
  final int scale;

  /// The logical size in point (e.g. 83.5).
  /// Size is present for app icon, and null for launch image.
  final double? size;

  @override
  int get hashCode => Object.hash(idiom, scale, size);

  @override
  bool operator ==(Object other) =>
      other is _ImageAssetFileKey &&
      other.idiom == idiom &&
      other.scale == scale &&
      other.size == size;

  /// The pixel size based on logical size and scale.
  int? get pixelSize => size == null ? null : (size! * scale).toInt(); // pixel size must be an int.
}

/// Builds an .xcarchive and optionally .ipa for an iOS app to be generated for
/// App Store submission.
///
/// Can only be run on a macOS host.
class BuildIOSArchiveCommand extends _BuildIOSSubCommand {
  BuildIOSArchiveCommand({required super.logger, required super.verboseHelp}) {
    argParser.addOption(
      'export-method',
      defaultsTo: 'app-store',
      allowed: <String>['app-store', 'ad-hoc', 'development', 'enterprise'],
      help: 'Specify how the IPA will be distributed.',
      allowedHelp: <String, String>{
        'app-store': 'Upload to the App Store.',
        'ad-hoc':
            'Test on designated devices that do not need to be registered with the Apple developer account. '
            'Requires a distribution certificate.',
        'development':
            'Test only on development devices registered with the Apple developer account.',
        'enterprise': 'Distribute an app registered with the Apple Developer Enterprise Program.',
      },
    );
    argParser.addOption(
      'export-options-plist',
      valueHelp: 'ExportOptions.plist',
      help:
          'Export an IPA with these options. See "xcodebuild -h" for available exportOptionsPlist keys.',
    );
  }

  @override
  final name = 'ipa';

  @override
  final aliases = <String>['xcarchive'];

  @override
  final description = 'Build an iOS archive bundle and IPA for distribution.';

  @override
  final XcodeBuildAction xcodeBuildAction = XcodeBuildAction.archive;

  @override
  final EnvironmentType environmentType = EnvironmentType.physical;

  @override
  final configOnly = false;

  String? get exportOptionsPlist => stringArg('export-options-plist');

  @override
  Directory _outputAppDirectory(String xcodeResultOutput) => globals.fs
      .directory(xcodeResultOutput)
      .childDirectory('Products')
      .childDirectory('Applications');

  @override
  Future<void> validateCommand() async {
    final String? exportOptions = exportOptionsPlist;
    if (exportOptions != null) {
      if (argResults?.wasParsed('export-method') ?? false) {
        throwToolExit(
          '"--export-options-plist" is not compatible with "--export-method". Either use "--export-options-plist" and '
          'a plist describing how the IPA should be exported by Xcode, or use "--export-method" to create a new plist.\n'
          'See "xcodebuild -h" for available exportOptionsPlist keys.',
        );
      }
      final FileSystemEntityType type = globals.fs.typeSync(exportOptions);
      if (type == FileSystemEntityType.notFound) {
        throwToolExit('"$exportOptions" property list does not exist.');
      } else if (type != FileSystemEntityType.file) {
        throwToolExit('"$exportOptions" is not a file. See "xcodebuild -h" for available keys.');
      }
    }
    return super.validateCommand();
  }

  // A helper function to parse Contents.json of an image asset into a map,
  // with the key to be _ImageAssetFileKey, and value to be the image file name.
  // Some assets have size (e.g. app icon) and others do not (e.g. launch image).
  Map<_ImageAssetFileKey, String> _parseImageAssetContentsJson(
    String contentsJsonDirName, {
    required bool requiresSize,
  }) {
    final Directory contentsJsonDirectory = globals.fs.directory(contentsJsonDirName);
    if (!contentsJsonDirectory.existsSync()) {
      return <_ImageAssetFileKey, String>{};
    }
    final File contentsJsonFile = contentsJsonDirectory.childFile('Contents.json');
    final Map<String, dynamic> contents =
        json.decode(contentsJsonFile.readAsStringSync()) as Map<String, dynamic>? ??
        <String, dynamic>{};
    final List<dynamic> images = contents['images'] as List<dynamic>? ?? <dynamic>[];
    final Map<String, dynamic> info =
        contents['info'] as Map<String, dynamic>? ?? <String, dynamic>{};
    if ((info['version'] as int?) != 1) {
      // Skips validation for unknown format.
      return <_ImageAssetFileKey, String>{};
    }

    final iconInfo = <_ImageAssetFileKey, String>{};
    for (final dynamic image in images) {
      final imageMap = image as Map<String, dynamic>;
      final idiom = imageMap['idiom'] as String?;
      final size = imageMap['size'] as String?;
      final scale = imageMap['scale'] as String?;
      final fileName = imageMap['filename'] as String?;

      // requiresSize must match the actual presence of size in json.
      if (requiresSize != (size != null) || idiom == null || scale == null || fileName == null) {
        continue;
      }

      final double? parsedSize;
      if (size != null) {
        // for example, "64x64". Parse the width since it is a square.
        final Iterable<double> parsedSizes = size
            .split('x')
            .map((String element) => double.tryParse(element))
            .whereType<double>();
        if (parsedSizes.isEmpty) {
          continue;
        }
        parsedSize = parsedSizes.first;
      } else {
        parsedSize = null;
      }

      // for example, "3x".
      final Iterable<int> parsedScales = scale
          .split('x')
          .map((String element) => int.tryParse(element))
          .whereType<int>();
      if (parsedScales.isEmpty) {
        continue;
      }
      final int parsedScale = parsedScales.first;
      iconInfo[_ImageAssetFileKey(idiom, parsedScale, parsedSize)] = fileName;
    }
    return iconInfo;
  }

  // A helper function to check if an image asset is still using template files.
  bool _isAssetStillUsingTemplateFiles({
    required Map<_ImageAssetFileKey, String> templateImageInfoMap,
    required Map<_ImageAssetFileKey, String> projectImageInfoMap,
    required String templateImageDirName,
    required String projectImageDirName,
  }) {
    return projectImageInfoMap.entries.any((MapEntry<_ImageAssetFileKey, String> entry) {
      final String projectFileName = entry.value;
      final String? templateFileName = templateImageInfoMap[entry.key];
      if (templateFileName == null) {
        return false;
      }
      final File projectFile = globals.fs.file(
        globals.fs.path.join(projectImageDirName, projectFileName),
      );
      final File templateFile = globals.fs.file(
        globals.fs.path.join(templateImageDirName, templateFileName),
      );

      return projectFile.existsSync() &&
          templateFile.existsSync() &&
          md5.convert(projectFile.readAsBytesSync()) == md5.convert(templateFile.readAsBytesSync());
    });
  }

  // A helper function to return a list of image files in an image asset with
  // wrong sizes (as specified in its Contents.json file).
  List<String> _imageFilesWithWrongSize({
    required Map<_ImageAssetFileKey, String> imageInfoMap,
    required String imageDirName,
  }) {
    return imageInfoMap.entries
        .where((MapEntry<_ImageAssetFileKey, String> entry) {
          final String fileName = entry.value;
          final File imageFile = globals.fs.file(globals.fs.path.join(imageDirName, fileName));
          if (!imageFile.existsSync()) {
            return false;
          }
          // validate image size is correct.
          // PNG file's width is at byte [16, 20), and height is at byte [20, 24), in big endian format.
          // Based on https://en.wikipedia.org/wiki/Portable_Network_Graphics#File_format
          final ByteData imageData = imageFile.readAsBytesSync().buffer.asByteData();
          if (imageData.lengthInBytes < 24) {
            return false;
          }
          final int width = imageData.getInt32(16);
          final int height = imageData.getInt32(20);
          // The size must not be null.
          final int expectedSize = entry.key.pixelSize!;
          return width != expectedSize || height != expectedSize;
        })
        .map((MapEntry<_ImageAssetFileKey, String> entry) => entry.value)
        .toList();
  }

  ValidationResult? _createValidationResult(String title, List<ValidationMessage> messages) {
    if (messages.isEmpty) {
      return null;
    }
    final bool anyInvalid = messages.any(
      (ValidationMessage message) => message.type != ValidationMessageType.information,
    );
    return ValidationResult(
      anyInvalid ? ValidationType.partial : ValidationType.success,
      messages,
      statusInfo: title,
    );
  }

  ValidationMessage _createValidationMessage({required bool isValid, required String message}) {
    // Use "information" type for valid message, and "hint" type for invalid message.
    return isValid ? ValidationMessage(message) : ValidationMessage.hint(message);
  }

  Future<List<ValidationMessage>> _validateIconAssetsAfterArchive() async {
    final BuildableIOSApp app = await buildableIOSApp;

    final Map<_ImageAssetFileKey, String> templateInfoMap = _parseImageAssetContentsJson(
      app.templateAppIconDirNameForContentsJson,
      requiresSize: true,
    );
    final Map<_ImageAssetFileKey, String> projectInfoMap = _parseImageAssetContentsJson(
      app.projectAppIconDirName,
      requiresSize: true,
    );

    final validationMessages = <ValidationMessage>[];

    final bool usesTemplate = _isAssetStillUsingTemplateFiles(
      templateImageInfoMap: templateInfoMap,
      projectImageInfoMap: projectInfoMap,
      templateImageDirName: await app.templateAppIconDirNameForImages,
      projectImageDirName: app.projectAppIconDirName,
    );

    if (usesTemplate) {
      validationMessages.add(
        _createValidationMessage(
          isValid: false,
          message: 'App icon is set to the default placeholder icon. Replace with unique icons.',
        ),
      );
    }

    final List<String> filesWithWrongSize = _imageFilesWithWrongSize(
      imageInfoMap: projectInfoMap,
      imageDirName: app.projectAppIconDirName,
    );

    if (filesWithWrongSize.isNotEmpty) {
      validationMessages.add(
        _createValidationMessage(
          isValid: false,
          message: 'App icon is using the incorrect size (e.g. ${filesWithWrongSize.first}).',
        ),
      );
    }
    return validationMessages;
  }

  Future<List<ValidationMessage>> _validateLaunchImageAssetsAfterArchive() async {
    final BuildableIOSApp app = await buildableIOSApp;

    final Map<_ImageAssetFileKey, String> templateInfoMap = _parseImageAssetContentsJson(
      app.templateLaunchImageDirNameForContentsJson,
      requiresSize: false,
    );
    final Map<_ImageAssetFileKey, String> projectInfoMap = _parseImageAssetContentsJson(
      app.projectLaunchImageDirName,
      requiresSize: false,
    );

    final validationMessages = <ValidationMessage>[];

    final bool usesTemplate = _isAssetStillUsingTemplateFiles(
      templateImageInfoMap: templateInfoMap,
      projectImageInfoMap: projectInfoMap,
      templateImageDirName: await app.templateLaunchImageDirNameForImages,
      projectImageDirName: app.projectLaunchImageDirName,
    );

    if (usesTemplate) {
      validationMessages.add(
        _createValidationMessage(
          isValid: false,
          message:
              'Launch image is set to the default placeholder icon. Replace with unique launch image.',
        ),
      );
    }

    return validationMessages;
  }

  Future<List<ValidationMessage>> _validateXcodeBuildSettingsAfterArchive() async {
    final BuildableIOSApp app = await buildableIOSApp;

    final String plistPath = app.builtInfoPlistPathAfterArchive;

    if (!globals.fs.file(plistPath).existsSync()) {
      globals.printError('Invalid iOS archive. Does not contain Info.plist.');
      return <ValidationMessage>[];
    }

    final xcodeProjectSettingsMap = <String, String?>{};

    xcodeProjectSettingsMap['Version Number'] = globals.plistParser.getValueFromFile<String>(
      plistPath,
      PlistParser.kCFBundleShortVersionStringKey,
    );
    xcodeProjectSettingsMap['Build Number'] = globals.plistParser.getValueFromFile<String>(
      plistPath,
      PlistParser.kCFBundleVersionKey,
    );
    xcodeProjectSettingsMap['Display Name'] =
        globals.plistParser.getValueFromFile<String>(
          plistPath,
          PlistParser.kCFBundleDisplayNameKey,
        ) ??
        globals.plistParser.getValueFromFile<String>(plistPath, PlistParser.kCFBundleNameKey);
    xcodeProjectSettingsMap['Deployment Target'] = globals.plistParser.getValueFromFile<String>(
      plistPath,
      PlistParser.kMinimumOSVersionKey,
    );
    xcodeProjectSettingsMap['Bundle Identifier'] = globals.plistParser.getValueFromFile<String>(
      plistPath,
      PlistParser.kCFBundleIdentifierKey,
    );

    final List<ValidationMessage> validationMessages = xcodeProjectSettingsMap.entries.map((
      MapEntry<String, String?> entry,
    ) {
      final String title = entry.key;
      final String? info = entry.value;
      return _createValidationMessage(
        isValid: info != null,
        message: '$title: ${info ?? "Missing"}',
      );
    }).toList();

    final bool hasMissingSettings = xcodeProjectSettingsMap.values.any(
      (String? element) => element == null,
    );
    if (hasMissingSettings) {
      validationMessages.add(
        _createValidationMessage(
          isValid: false,
          message: 'You must set up the missing app settings.',
        ),
      );
    }

    final bool usesDefaultBundleIdentifier =
        xcodeProjectSettingsMap['Bundle Identifier']?.startsWith('com.example') ?? false;
    if (usesDefaultBundleIdentifier) {
      validationMessages.add(
        _createValidationMessage(
          isValid: false,
          message: 'Your application still contains the default "com.example" bundle identifier.',
        ),
      );
    }

    return validationMessages;
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final BuildInfo buildInfo = await cachedBuildInfo;
    final FlutterCommandResult xcarchiveResult = await super.runCommand();

    final validationResults = <ValidationResult?>[];
    validationResults.add(
      _createValidationResult(
        'App Settings Validation',
        await _validateXcodeBuildSettingsAfterArchive(),
      ),
    );
    validationResults.add(
      _createValidationResult(
        'App Icon and Launch Image Assets Validation',
        await _validateIconAssetsAfterArchive() + await _validateLaunchImageAssetsAfterArchive(),
      ),
    );

    for (final ValidationResult result in validationResults.whereType<ValidationResult>()) {
      globals.printStatus('\n${result.coloredLeadingBox} ${result.statusInfo}');
      for (final ValidationMessage message in result.messages) {
        globals.printStatus(
          '${message.coloredIndicator} ${message.message}',
          indent: result.leadingBox.length + 1,
        );
      }
    }
    globals.printStatus(
      '\nTo update the settings, please refer to https://flutter.dev/to/ios-deploy\n',
    );

    // xcarchive failed or not at expected location.
    if (xcarchiveResult.exitStatus != ExitStatus.success) {
      globals.printStatus('Skipping IPA.');
      return xcarchiveResult;
    }

    if (!shouldCodesign) {
      globals.printStatus('Codesigning disabled with --no-codesign, skipping IPA.');
      return xcarchiveResult;
    }

    // Build IPA from generated xcarchive.
    final BuildableIOSApp app = await buildableIOSApp;
    Status? status;
    RunResult? result;
    final String relativeOutputPath = app.ipaOutputPath;
    final String absoluteOutputPath = globals.fs.path.absolute(relativeOutputPath);
    final String absoluteArchivePath = globals.fs.path.absolute(app.archiveBundleOutputPath);
    String? exportOptions = exportOptionsPlist;
    String? exportMethod = exportOptions != null
        ? globals.plistParser.getValueFromFile<String?>(exportOptions, 'method')
        : null;
    exportMethod ??= _getVersionAppropriateExportMethod(stringArg('export-method')!);
    final bool isAppStoreUpload =
        exportMethod == 'app-store' || exportMethod == 'app-store-connect';
    File? generatedExportPlist;
    try {
      final String exportMethodDisplayName = isAppStoreUpload ? 'App Store' : exportMethod;
      status = globals.logger.startProgress('Building $exportMethodDisplayName IPA...');
      if (exportOptions == null) {
        final Map<String, String>? buildSettings = await app.project.buildSettingsForBuildInfo(
          buildInfo,
        );
        // Create XcodeCodeSigningSettings for dependency injection into createExportPlist
        final codeSigningSettings = XcodeCodeSigningSettings(
          config: globals.config,
          logger: logger,
          platform: globals.platform,
          processUtils: globals.processUtils,
          fileSystem: globals.fs,
          fileSystemUtils: globals.fsUtils,
          terminal: globals.terminal,
          plistParser: globals.plistParser,
        );
        generatedExportPlist = await createExportPlist(
          exportMethod: exportMethod,
          app: app,
          buildInfo: buildInfo,
          buildSettings: buildSettings,
          fileSystem: globals.fs,
          codeSigningSettings: codeSigningSettings,
        );
        exportOptions = generatedExportPlist.path;
      }

      result = await globals.processUtils.run(<String>[
        ...globals.xcode!.xcrunCommand(),
        'xcodebuild',
        '-exportArchive',
        if (shouldCodesign) ...<String>[
          '-allowProvisioningDeviceRegistration',
          '-allowProvisioningUpdates',
        ],
        '-archivePath',
        absoluteArchivePath,
        '-exportPath',
        absoluteOutputPath,
        '-exportOptionsPlist',
        globals.fs.path.absolute(exportOptions),
      ]);
    } finally {
      if (generatedExportPlist != null) {
        ErrorHandlingFileSystem.deleteIfExists(generatedExportPlist);
      }
      status?.stop();
    }

    if (result.exitCode != 0) {
      final errorMessage = StringBuffer();

      // "error:" prefixed lines are the nicely formatted error message, the
      // rest is the same message but printed as a IDEFoundationErrorDomain.
      // Example:
      // error: exportArchive: exportOptionsPlist error for key 'method': expected one of {app-store, ad-hoc, enterprise, development, validation}, but found developmentasdasd
      // Error Domain=IDEFoundationErrorDomain Code=1 "exportOptionsPlist error for key 'method': expected one of {app-store, ad-hoc, enterprise, development, validation}, but found developmentasdasd" ...
      LineSplitter.split(
        result.stderr,
      ).where((String line) => line.contains('error: ')).forEach(errorMessage.writeln);

      globals.printError('Encountered error while creating the IPA:');
      globals.printError(errorMessage.toString());

      final FileSystemEntityType type = globals.fs.typeSync(absoluteArchivePath);
      globals.printError('Try distributing the app in Xcode:');
      if (type == FileSystemEntityType.notFound) {
        globals.printError('open ios/Runner.xcworkspace', indent: 2);
      } else {
        globals.printError('open $absoluteArchivePath', indent: 2);
      }

      // Even though the IPA step didn't succeed, the xcarchive did.
      // Still count this as success since the user has been instructed about how to
      // recover in Xcode.
      return FlutterCommandResult.success();
    }

    final Directory outputDirectory = globals.fs.directory(absoluteOutputPath);
    final int? directorySize = globals.os.getDirectorySize(outputDirectory);
    final appSize = (buildInfo.mode == BuildMode.debug || directorySize == null)
        ? '' // Don't display the size when building a debug variant.
        : ' (${getSizeAsPlatformMB(directorySize)})';

    globals.printStatus(
      '${globals.terminal.successMark} '
      'Built IPA to ${globals.fs.path.relative(outputDirectory.path)}$appSize',
      color: TerminalColor.green,
    );

    if (isAppStoreUpload) {
      globals.printStatus('To upload to the App Store either:');
      globals.printStatus(
        '1. Drag and drop the "$relativeOutputPath/*.ipa" bundle into the Apple Transporter macOS app https://apps.apple.com/us/app/transporter/id1450874784',
        indent: 4,
      );
      globals.printStatus(
        '2. Run "xcrun altool --upload-app --type ios -f $relativeOutputPath/*.ipa --apiKey your_api_key --apiIssuer your_issuer_id".',
        indent: 4,
      );
      globals.printStatus(
        'See "man altool" for details about how to authenticate with the App Store Connect API key.',
        indent: 7,
      );
    }

    return FlutterCommandResult.success();
  }

  /// Generates an ExportOptions.plist for use with `xcodebuild -exportArchive`.
  ///
  /// For manual signing configurations, generates an enhanced plist with complete signing
  /// configuration. Otherwise, generates a simple plist with just the export method.
  ///
  /// **Enhancement conditions:**
  /// - `CODE_SIGN_STYLE=Manual` is detected (manual provisioning profile signing)
  /// - Build mode is Release or Profile (production builds only, skips Debug to avoid overhead)
  /// - A provisioning profile can be located and parsed
  ///
  /// **Known limitations:**
  /// - Currently only supports single-target apps (main app bundle ID only)
  /// - TODO: Handle multi-target apps with extensions/widgets (requires multiple bundle IDs
  ///   mapped to their respective provisioning profiles in the provisioningProfiles dict)
  ///
  /// **Fallback behavior:**
  /// - For Automatic signing: Let Xcode handle the export options (simple plist)
  /// - For Debug builds: Skip enhancement (not needed for App Store export)
  /// - If profile lookup fails: Use simple plist and log trace message
  /// - If required build settings missing: Use simple plist
  ///
  /// Returns an enhanced plist with `teamID`, `signingStyle`, and `provisioningProfiles`
  /// mapping when conditions are met, otherwise returns a simple plist with just `method`.
  Future<File> createExportPlist({
    required String exportMethod,
    required BuildableIOSApp app,
    required BuildInfo buildInfo,
    required Map<String, String>? buildSettings,
    required FileSystem fileSystem,
    XcodeCodeSigningSettings? codeSigningSettings,
    FileSystemUtils? fileSystemUtils,
  }) async {
    final String? codeSignStyle = buildSettings?['CODE_SIGN_STYLE'];
    final isManualSigning = codeSignStyle == 'Manual';

    // Only enhance for manual signing in Release/Profile builds
    // (skip for Debug to avoid overhead during development workflow)
    if (isManualSigning &&
        (buildInfo.mode == BuildMode.release || buildInfo.mode == BuildMode.profile)) {
      final String? profileSpecifier = buildSettings?['PROVISIONING_PROFILE_SPECIFIER'];
      final String? teamId = buildSettings?['DEVELOPMENT_TEAM'];
      final String bundleId = buildSettings?['PRODUCT_BUNDLE_IDENTIFIER'] ?? app.id;

      if (profileSpecifier != null && teamId != null) {
        // Try to find and parse the provisioning profile
        final String? profileUuid = await _findProvisioningProfileUuid(
          profileSpecifier,
          codeSigningSettings: codeSigningSettings,
          fileSystem: fileSystem,
          fileSystemUtils: fileSystemUtils ?? globals.fsUtils,
        );

        if (profileUuid != null) {
          // Generate enhanced ExportOptions.plist for manual signing
          logger.printTrace(
            'Detected manual code signing. Generated ExportOptions.plist with '
            'teamID, signingStyle=manual, and provisioningProfiles for $bundleId.',
          );
          return _createManualSigningExportPlist(
            exportMethod: exportMethod,
            teamId: teamId,
            bundleId: bundleId,
            profileUuid: profileUuid,
            fileSystem: fileSystem,
          );
        }
        // Note: If profile lookup fails, we fall back to simple plist.
        // Trace-level logging is already emitted by _findProvisioningProfileUuid.
        logger.printTrace(
          'Manual signing detected but no matching provisioning profile UUID was found '
          'for $bundleId. Falling back to default ExportOptions.plist. '
          'If exportArchive fails with provisioning profile errors, consider supplying '
          '--export-options-plist manually.',
        );
      }
    }

    // Fall back to simple plist (current behavior)
    return _createSimpleExportPlist(exportMethod: exportMethod, fileSystem: fileSystem);
  }

  File _createSimpleExportPlist({required String exportMethod, required FileSystem fileSystem}) {
    final plistContents = StringBuffer('''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>method</key>
        <string>$exportMethod</string>
        <key>uploadBitcode</key>
        <false/>
    </dict>
</plist>
''');

    final File tempPlist = fileSystem.systemTempDirectory
        .createTempSync('flutter_build_ios.')
        .childFile('ExportOptions.plist');
    tempPlist.writeAsStringSync(plistContents.toString());

    return tempPlist;
  }

  File _createManualSigningExportPlist({
    required String exportMethod,
    required String teamId,
    required String bundleId,
    required String profileUuid,
    required FileSystem fileSystem,
  }) {
    // Note: uploadBitcode=false and stripSwiftSymbols=true are conservative defaults
    // that work for most App Store distribution scenarios. These values are not currently
    // configurable, but could be made configurable in a future enhancement if needed.
    final plistContents = StringBuffer('''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>method</key>
        <string>$exportMethod</string>
        <key>teamID</key>
        <string>$teamId</string>
        <key>signingStyle</key>
        <string>manual</string>
        <key>provisioningProfiles</key>
        <dict>
            <key>$bundleId</key>
            <string>$profileUuid</string>
        </dict>
        <key>uploadBitcode</key>
        <false/>
        <key>stripSwiftSymbols</key>
        <true/>
    </dict>
</plist>
''');

    final File tempPlist = fileSystem.systemTempDirectory
        .createTempSync('flutter_build_ios.')
        .childFile('ExportOptions.plist');
    tempPlist.writeAsStringSync(plistContents.toString());

    return tempPlist;
  }

  /// Searches the provisioning profiles directory for a profile matching [profileSpecifier].
  ///
  /// The [profileSpecifier] can be either:
  /// - A provisioning profile UUID (e.g., "12345678-1234-1234-1234-123456789012")
  /// - A provisioning profile name (e.g., "MyApp Distribution")
  ///
  /// **Search strategy:**
  /// - Iterates through all `.mobileprovision` files in the standard Xcode profiles directory
  /// - Decodes each profile once to extract both UUID and name (performance optimization)
  /// - Matches against both UUID and name to handle either specification format
  /// - Returns the UUID of the first matching profile
  ///
  /// **Edge cases handled:**
  /// - Home directory not available (CI/CD environments) - logs trace and returns null
  /// - Provisioning profiles directory doesn't exist - logs trace and returns null
  /// - Profile file parsing fails - logs trace and continues searching other profiles
  /// - Multiple profiles with same name - returns first match (profile parse order dependent)
  /// - Profile not found - logs trace with helpful context and returns null
  ///
  /// Returns the UUID of the matching profile, or null if not found or parsing fails.
  Future<String?> _findProvisioningProfileUuid(
    String profileSpecifier, {
    XcodeCodeSigningSettings? codeSigningSettings,
    required FileSystem fileSystem,
    required FileSystemUtils fileSystemUtils,
  }) async {
    final Directory? profileDirectory = getProvisioningProfileDirectory(
      fileSystemUtils: fileSystemUtils,
      fileSystem: fileSystem,
    );
    if (profileDirectory == null) {
      logger.printTrace(
        'Manual signing: provisioning profile "$profileSpecifier" not found. '
        'Home directory not available. Falling back to basic ExportOptions.plist.',
      );
      return null;
    }

    if (!profileDirectory.existsSync()) {
      logger.printTrace(
        'Manual signing: provisioning profile "$profileSpecifier" not found. '
        'Provisioning Profiles directory does not exist at: ${profileDirectory.path}. '
        'Falling back to basic ExportOptions.plist.',
      );
      return null;
    }

    // Use provided or create new XcodeCodeSigningSettings instance
    final XcodeCodeSigningSettings settings =
        codeSigningSettings ??
        XcodeCodeSigningSettings(
          config: globals.config,
          logger: logger,
          platform: globals.platform,
          processUtils: globals.processUtils,
          fileSystem: globals.fs,
          fileSystemUtils: globals.fsUtils,
          terminal: globals.terminal,
          plistParser: globals.plistParser,
        );

    // Search for profiles matching the specifier (could be name or UUID)
    await for (final FileSystemEntity entity in profileDirectory.list()) {
      if (entity is! File || fileSystem.path.extension(entity.path) != '.mobileprovision') {
        continue;
      }

      // Decode profile once and extract both UUID and name
      final ProvisioningProfile? profile = await settings.parseProvisioningProfile(entity);
      if (profile != null) {
        // Check if this profile matches the specifier (by UUID or name)
        if (profile.uuid == profileSpecifier || profile.name == profileSpecifier) {
          return profile.uuid;
        }
      }
    }

    logger.printTrace(
      'Manual signing: provisioning profile "$profileSpecifier" not found in ${profileDirectory.path}. '
      'Falling back to basic ExportOptions.plist.',
    );
    return null;
  }

  // As of Xcode 15.4, the old export methods 'app-store', 'ad-hoc', and 'development'
  // are now deprecated. The new equivalents are 'app-store-connect', 'release-testing',
  // and 'debugging'.
  String _getVersionAppropriateExportMethod(String method) {
    final Version? currVersion = globals.xcode!.currentVersion;
    if (currVersion != null) {
      if (currVersion >= Version(15, 4, 0)) {
        switch (method) {
          case 'app-store':
            return 'app-store-connect';
          case 'ad-hoc':
            return 'release-testing';
          case 'development':
            return 'debugging';
        }
      }
      return method;
    }
    throwToolExit('Xcode version could not be found.');
  }
}

abstract class _BuildIOSSubCommand extends BuildSubCommand {
  _BuildIOSSubCommand({required super.logger, required bool verboseHelp})
    : super(verboseHelp: verboseHelp) {
    addTreeShakeIconsFlag();
    addSplitDebugInfoOption();
    addBuildModeFlags(verboseHelp: verboseHelp);
    usesTargetOption();
    usesFlavorOption();
    usesPubOption();
    usesBuildNumberOption();
    usesBuildNameOption();
    addDartObfuscationOption();
    usesDartDefineOption();
    usesExtraDartFlagOptions(verboseHelp: verboseHelp);
    addEnableExperimentation(hide: !verboseHelp);
    addBuildPerformanceFile(hide: !verboseHelp);
    usesAnalyzeSizeFlag();
    argParser.addFlag(
      'codesign',
      defaultsTo: true,
      help: 'Codesign the application bundle (only available on device builds).',
    );
  }

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{
    DevelopmentArtifact.iOS,
  };

  XcodeBuildAction get xcodeBuildAction;

  /// The result of the Xcode build command. Null until it finishes.
  @protected
  XcodeBuildResult? xcodeBuildResult;

  EnvironmentType get environmentType;
  bool get configOnly;

  bool get shouldCodesign => boolArg('codesign');

  late final Future<BuildInfo> cachedBuildInfo = getBuildInfo();

  late final Future<BuildableIOSApp> buildableIOSApp = () async {
    final app =
        await applicationPackages?.getPackageForPlatform(
              TargetPlatform.ios,
              buildInfo: await cachedBuildInfo,
            )
            as BuildableIOSApp?;

    if (app == null) {
      throwToolExit('Application not configured for iOS');
    }
    return app;
  }();

  Directory _outputAppDirectory(String xcodeResultOutput);

  @override
  bool get supported => globals.platform.isMacOS;

  @override
  Future<FlutterCommandResult> runCommand() async {
    defaultBuildMode = environmentType == EnvironmentType.simulator
        ? BuildMode.debug
        : BuildMode.release;
    final BuildInfo buildInfo = await cachedBuildInfo;

    if (!supported) {
      throwToolExit('Building for iOS is only supported on macOS.');
    }
    if (environmentType == EnvironmentType.simulator && !buildInfo.supportsSimulator) {
      throwToolExit('${buildInfo.mode.uppercaseName} mode is not supported for simulators.');
    }
    if (configOnly && buildInfo.codeSizeDirectory != null) {
      throwToolExit('Cannot analyze code size without performing a full build.');
    }
    if (environmentType == EnvironmentType.physical && !shouldCodesign) {
      globals.printStatus(
        'Warning: Building for device with codesigning disabled. You will '
        'have to manually codesign before deploying to device.',
      );
    }

    final BuildableIOSApp app = await buildableIOSApp;

    final logTarget = environmentType == EnvironmentType.simulator ? 'simulator' : 'device';
    final String typeName = globals.artifacts!.getEngineType(TargetPlatform.ios, buildInfo.mode);
    globals.printStatus(switch (xcodeBuildAction) {
      XcodeBuildAction.build => 'Building $app for $logTarget ($typeName)...',
      XcodeBuildAction.archive => 'Archiving $app...',
    });
    final XcodeBuildResult result = await buildXcodeProject(
      app: app,
      buildInfo: buildInfo,
      targetOverride: targetFile,
      environmentType: environmentType,
      codesign: shouldCodesign,
      configOnly: configOnly,
      buildAction: xcodeBuildAction,
      deviceID: globals.deviceManager?.specifiedDeviceId,
      disablePortPublication:
          usingCISystem &&
          xcodeBuildAction == XcodeBuildAction.build &&
          await disablePortPublication,
    );
    xcodeBuildResult = result;

    if (!result.success) {
      await diagnoseXcodeBuildFailure(
        result,
        analytics: globals.analytics,
        fileSystem: globals.fs,
        logger: globals.logger,
        platform: FlutterDarwinPlatform.ios,
        project: app.project.parent,
      );
      final presentParticiple = xcodeBuildAction == XcodeBuildAction.build
          ? 'building'
          : 'archiving';
      throwToolExit('Encountered error while $presentParticiple for $logTarget.');
    }

    if (buildInfo.codeSizeDirectory != null) {
      final sizeAnalyzer = SizeAnalyzer(
        fileSystem: globals.fs,
        logger: globals.logger,
        analytics: analytics,
        appFilenamePattern: 'App',
      );
      // Only support 64bit iOS code size analysis.
      final String arch = DarwinArch.arm64.name;
      final File aotSnapshot = globals.fs
          .directory(buildInfo.codeSizeDirectory)
          .childFile('snapshot.$arch.json');
      final File precompilerTrace = globals.fs
          .directory(buildInfo.codeSizeDirectory)
          .childFile('trace.$arch.json');

      final String? resultOutput = result.output;
      if (resultOutput == null) {
        throwToolExit('Could not find app to analyze code size');
      }
      final Directory outputAppDirectoryCandidate = _outputAppDirectory(resultOutput);

      Directory? appDirectory;
      if (outputAppDirectoryCandidate.existsSync()) {
        appDirectory = outputAppDirectoryCandidate.listSync().whereType<Directory>().where((
          Directory directory,
        ) {
          return globals.fs.path.extension(directory.path) == '.app';
        }).first;
      }
      if (appDirectory == null) {
        throwToolExit(
          'Could not find app to analyze code size in ${outputAppDirectoryCandidate.path}',
        );
      }
      final Map<String, Object?> output = await sizeAnalyzer.analyzeAotSnapshot(
        aotSnapshot: aotSnapshot,
        precompilerTrace: precompilerTrace,
        outputDirectory: appDirectory,
        type: 'ios',
      );
      final File outputFile = globals.fsUtils.getUniqueFile(
        globals.fs.directory(globals.fsUtils.homeDirPath).childDirectory('.flutter-devtools'),
        'ios-code-size-analysis',
        'json',
      )..writeAsStringSync(jsonEncode(output));
      // This message is used as a sentinel in analyze_apk_size_test.dart
      globals.printStatus(
        'A summary of your iOS bundle analysis can be found at: ${outputFile.path}',
      );

      globals.printStatus(
        '\nTo analyze your app size in Dart DevTools, run the following command:\n'
        'dart devtools --appSizeBase=${outputFile.path}',
      );
    }

    if (result.output != null) {
      final Directory outputDirectory = globals.fs.directory(result.output);
      final int? directorySize = globals.os.getDirectorySize(outputDirectory);
      final appSize = (buildInfo.mode == BuildMode.debug || directorySize == null)
          ? '' // Don't display the size when building a debug variant.
          : ' (${getSizeAsPlatformMB(directorySize)})';

      globals.printStatus(
        '${globals.terminal.successMark} '
        'Built ${globals.fs.path.relative(outputDirectory.path)}$appSize',
        color: TerminalColor.green,
      );

      // When an app is successfully built, record to analytics whether Impeller
      // is enabled or disabled. Note that we report the _lack_ of an explicit
      // flag set as "enabled" because the default is to enable Impeller on iOS.
      final BuildableIOSApp app = await buildableIOSApp;
      final String plistPath = app.project.infoPlist.path;
      final bool? impellerEnabled = globals.plistParser.getValueFromFile<bool>(
        plistPath,
        PlistParser.kFLTEnableImpellerKey,
      );

      final buildLabel = impellerEnabled == false
          ? 'plist-impeller-disabled'
          : 'plist-impeller-enabled';
      globals.analytics.send(Event.flutterBuildInfo(label: buildLabel, buildType: 'ios'));

      return FlutterCommandResult.success();
    }

    return FlutterCommandResult.fail();
  }
}
