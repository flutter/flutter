// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../build_info.dart';
import '../convert.dart';
import '../darwin/darwin.dart';
import '../ios/code_signing.dart';
import '../runner/flutter_command.dart' show FlutterOptions;
import '../xcode_project.dart';

/// Helper class to handle codesigning of XCFrameworks for iOS and macOS add-to-app.
///
/// This class provides methods to find the codesigning identity [getCodesignIdentity] and
/// codesign files/directories [codesign]. It also has special logic for codesigning
/// Flutter XCFrameworks [codesignFlutterXCFramework].
class DarwinAddToAppCodesigning {
  DarwinAddToAppCodesigning({
    required XcodeCodeSigningSettings xcodeCodeSigningSettings,
    required Logger logger,
  }) : _logger = logger,
       _xcodeCodeSigningSettings = xcodeCodeSigningSettings;

  final XcodeCodeSigningSettings _xcodeCodeSigningSettings;
  final Logger _logger;

  /// Find the codesigning identity to use to codesign XCFrameworks.
  ///
  /// If [codesignEnabled] is false, return null and print a status that code-signing is being
  /// skipped.
  ///
  /// If [codesignIdentityOption] is provided, use it as the code-signing identity. Otherwise,
  /// first attempt to find the code-signing identity from the Flutter project build settings.
  /// If that fails, attempt to find the code-signing identity in the Flutter config. If no
  /// code-signing identity is found, throw an error.
  Future<String?> getCodesignIdentity({
    required BuildInfo buildInfo,
    required bool codesignEnabled,
    required String? codesignIdentityOption,
    required File identityFile,
    required XcodeBasedProject xcodeProject,
  }) async {
    if (!codesignEnabled) {
      _skipCodesigning(identityFile: identityFile);
      return null;
    }
    // Use identity from command line argument if provided.
    if (codesignIdentityOption != null) {
      _logger.printStatus('Using code-signing identity: $codesignIdentityOption');
      _warnIfChangedAndSaveIdentity(
        identity: codesignIdentityOption,
        identityFile: identityFile,
        subMessage: false,
      );
      return codesignIdentityOption;
    }
    final Status status = _logger.startProgress('Finding code-signing identities...');
    final bool toolsAvailable = await _xcodeCodeSigningSettings.validateCodeSignSearchTools();
    if (!toolsAvailable) {
      throwToolExit(
        'Unable to find code-signing tools `security` and/or `openssl`. Ensure Xcode is installed '
        'and up to date.',
      );
    }
    final List<String> identities = await _xcodeCodeSigningSettings.getSigningIdentities();
    if (identities.isEmpty) {
      throwToolExit(
        noCertificatesInstruction(includeTrustStep: false, includeSimulatorAlternative: false),
      );
    }

    // Attempt to get codesigning info from Flutter project
    String? identity = await _getCodesignIdentityFromFlutterProject(
      buildInfo: buildInfo,
      identities: identities,
      xcodeProject: xcodeProject,
    );
    if (identity != null) {
      status.stop();
      _logger.printStatus('   └── Using code-signing identity from Flutter project: $identity');
      _warnIfChangedAndSaveIdentity(identity: identity, identityFile: identityFile);
      return identity;
    }

    // Next, attempt to get codesigning from Flutter config
    identity = await _getCodesignIdentityFromConfig(identities);
    if (identity != null) {
      status.stop();
      _logger.printStatus('   └── Using code-signing identity from Flutter config: $identity');
      _warnIfChangedAndSaveIdentity(identity: identity, identityFile: identityFile);
      return identity;
    }

    status.stop();
    throwToolExit(
      'No valid code-signing identity found. Please specify which identity to use with '
      '--${FlutterOptions.kCodesignIdentity} or use --no-codesign.',
    );
  }

  /// Print a message to the user that code-signing is being skipped and save an empty string to
  /// the [identityFile].
  void _skipCodesigning({required File identityFile}) {
    _logger.printStatus('Skipping code-signing...');
    _warnIfChangedAndSaveIdentity(identity: '', identityFile: identityFile, subMessage: false);
  }

  /// Print a warning if the codesigning identity has changed since the last run and save the new
  /// identity to the [identityFile].
  ///
  /// See https://developer.apple.com/documentation/xcode/verifying-the-origin-of-your-xcframeworks#Diagnose-build-failures-caused-by-code-signature-changes
  void _warnIfChangedAndSaveIdentity({
    required String identity,
    required File identityFile,
    bool subMessage = true,
  }) {
    var indent = '   ';
    if (subMessage) {
      indent = '       ';
    }
    if (identityFile.existsSync()) {
      String previousIdentity = identityFile.readAsStringSync();
      if (previousIdentity == identity) {
        return;
      }
      if (previousIdentity.isEmpty) {
        previousIdentity = '<none>';
      }
      _logger.printWarning(
        '$indent└── Identity has changed since last run. Previous identity: $previousIdentity\n'
        '$indent    If this triggers a notice in Xcode, select "Accept Change" to accept the new identity.',
      );
    } else {
      _logger.printWarning(
        '$indent└── Unable to verify if code-signing identity has changed. If this triggers a notice in Xcode,\n'
        '$indent    select "Accept Change" to accept the new identity.',
      );
    }
    identityFile.createSync(recursive: true);
    identityFile.writeAsStringSync(identity);
  }

  /// Find the codesigning identity in the Flutter project build settings.
  ///
  /// If the project uses manual codesigning, find the provisioning profile that matches the
  /// `PROVISIONING_PROFILE_SPECIFIER` and `DEVELOPMENT_TEAM` build settings. A provisioning
  /// profile contains a list of certificates in it. Get the Common Name from the certificate to
  /// find the matching codesigning identity. Multiple identities could match the provisioning
  /// profile and development team.
  ///
  /// If the project uses automatic codesigning, search for any identity that matches the
  /// development team. Multiple identities could match the development team.
  ///
  /// If there are multiple identities that match, throw an error and ask the user to
  /// specify the codesigning identity.
  Future<String?> _getCodesignIdentityFromFlutterProject({
    required BuildInfo buildInfo,
    required List<String> identities,
    required XcodeBasedProject xcodeProject,
  }) async {
    final Map<String, String>? buildSettings = await xcodeProject.buildSettingsForBuildInfo(
      buildInfo,
    );
    final String? codesignStyle = buildSettings?['CODE_SIGN_STYLE'];
    final String? developmentTeam = buildSettings?['DEVELOPMENT_TEAM'];
    if (developmentTeam == null) {
      return null;
    }
    final matchingIdentities = <String>{};
    if (codesignStyle == 'Manual') {
      // When manual codesigning is used, we need to find the provisioning profile and
      // the certificate to find the matching identity.
      final String? provisioningProfileSpecifier = buildSettings?['PROVISIONING_PROFILE_SPECIFIER'];
      final List<ProvisioningProfile> profiles = await _xcodeCodeSigningSettings
          .getProvisioningProfiles(validIdentities: identities);
      for (final profile in profiles) {
        if (profile.name == provisioningProfileSpecifier &&
            profile.teamIdentifier == developmentTeam) {
          for (final File cert in profile.developerCertificates) {
            final String? commonName = await _xcodeCodeSigningSettings.commonNameForCertificate(
              cert,
            );
            if (commonName != null) {
              matchingIdentities.addAll(identities.where((String id) => id.contains(commonName)));
            }
          }
        }
      }
    } else {
      for (final id in identities) {
        final String? developmentTeamForIdentity = await _xcodeCodeSigningSettings
            .getDevelopmentTeamFromIdentity(id);
        if (developmentTeamForIdentity == developmentTeam) {
          matchingIdentities.add(id);
        }
      }
    }
    if (matchingIdentities.length > 1) {
      throwToolExit(
        'Multiple identities found for development team $developmentTeam. Please specify which '
        'identity to use with --${FlutterOptions.kCodesignIdentity}.\n'
        'Available identities:\n'
        '  ${matchingIdentities.join('\n  ')}',
      );
    }
    return matchingIdentities.singleOrNull;
  }

  /// Find the codesigning identity in the Flutter config.
  ///
  /// If a provisioning profile is saved to the Flutter config, use that to find matching
  /// identities. A provisioning profile contains a list of certificates in it. Get the Common
  /// Name from the certificate to find the matching codesigning identity. Multiple identities
  /// could match the provisioning profile.
  ///
  /// If an identity is saved to the Flutter config, use that directly.
  ///
  /// If there are multiple identities that match, throw an error and ask the user to
  /// specify the codesigning identity.
  Future<String?> _getCodesignIdentityFromConfig(List<String> identities) async {
    final matchingIdentities = <String>{};
    final ProvisioningProfile? savedProfile = await _xcodeCodeSigningSettings
        .getProvisioningProfileFromConfig(identities);
    if (savedProfile != null) {
      for (final File cert in savedProfile.developerCertificates) {
        final String? commonName = await _xcodeCodeSigningSettings.commonNameForCertificate(cert);
        if (commonName != null) {
          matchingIdentities.addAll(identities.where((String id) => id.contains(commonName)));
        }
      }
      if (matchingIdentities.length > 1) {
        throwToolExit(
          'Multiple identities found for provisioning profile ${savedProfile.name}. Please specify which '
          'identity to use with --${FlutterOptions.kCodesignIdentity}.\n'
          'Available identities:\n'
          '  ${matchingIdentities.join('\n  ')}',
        );
      }
      return matchingIdentities.singleOrNull;
    }
    return _xcodeCodeSigningSettings.getIdentityFromCertFromConfig(identities);
  }

  /// Codesigns a file or directory. Throws [ToolExit] if the codesigning fails.
  static Future<void> codesign({
    required FileSystemEntity artifact,
    required ProcessManager processManager,
    required String codesignIdentity,
    required BuildMode buildMode,
  }) async {
    final ProcessResult codesignResult = await processManager.run(<String>[
      'codesign',
      '--force',
      '--sign',
      codesignIdentity,
      // Mimic Xcode's timestamp codesigning behavior on non-release binaries.
      if (buildMode != BuildMode.release) '--timestamp=none',
      artifact.path,
    ]);
    if (codesignResult.exitCode != 0) {
      throwToolExit('Unable to codesign ${artifact.basename}: ${codesignResult.stderr}');
    }
  }

  /// Codesigns a Flutter/FlutterMacOS XCFramework if it's not already codesigned.
  ///
  /// On the stable and beta channels, the Flutter XCFramework is already codesigned with Flutter's
  /// cert, so this method will skip codesigning it.
  ///
  /// Apple requires that the Flutter.xcframework is code-signed and to avoid build failures due to
  /// code-signing identity changing, we only use the app developer's identity to code-sign it when
  /// necessary. In addition, Flutter code-signs both the XCFramework and it's inner frameworks.
  /// Re-codesigning it would require code-signing the inner frameworks as well as the XCFramework.
  /// See go/flutter-ios-privacy-impacting-sdks-codesign-requirement and
  /// https://developer.apple.com/documentation/xcode/verifying-the-origin-of-your-xcframeworks#Diagnose-build-failures-caused-by-code-signature-changes
  static Future<void> codesignFlutterXCFramework({
    required Directory xcframework,
    required String codesignIdentity,
    required BuildMode buildMode,
    required ProcessManager processManager,
  }) async {
    // Check if the XCFramework is already codesigned.
    final ProcessResult codesignResult = await processManager.run(<String>[
      'codesign',
      '-d',
      xcframework.path,
    ]);
    if (!codesignResult.stderr.toString().contains('not signed at all')) {
      // If the Flutter XCFramework is already codesigned, skip codesigning it. It should already
      // be codesigned with Flutter's cert on stable and beta channels.
      return;
    }
    await DarwinAddToAppCodesigning.codesign(
      codesignIdentity: codesignIdentity,
      artifact: xcframework,
      processManager: processManager,
      buildMode: buildMode,
    );
  }
}

/// Helper class with common logic for native assets for iOS and macOS add-to-app.
class DarwinAddToAppNativeAssets {
  /// Parses the NativeAssetsManifest.json in [outputDirectory] and returns a
  /// mapping from asset ID to the path of the code asset within the bundle
  /// (e.g., "MyFramework.framework/MyFramework").
  static Map<String, String> parseNativeAssetsManifest(
    Directory outputDirectory,
    FlutterDarwinPlatform platform,
  ) {
    File manifestFile;
    switch (platform) {
      case FlutterDarwinPlatform.ios:
        manifestFile = outputDirectory
            .childDirectory('App.framework')
            .childDirectory('flutter_assets')
            .childFile('NativeAssetsManifest.json');
      case FlutterDarwinPlatform.macos:
        manifestFile = outputDirectory
            .childDirectory('App.framework')
            .childDirectory('Resources')
            .childDirectory('flutter_assets')
            .childFile('NativeAssetsManifest.json');
    }
    if (!manifestFile.existsSync()) {
      return const <String, String>{};
    }
    final manifest = json.decode(manifestFile.readAsStringSync()) as Map<String, Object?>;
    final nativeAssets = manifest['native-assets'] as Map<String, Object?>?;
    if (nativeAssets == null) {
      return const <String, String>{};
    }
    final result = <String, String>{};
    for (final Object? targetAssets in nativeAssets.values) {
      if (targetAssets is! Map<String, Object?>) {
        continue;
      }
      for (final MapEntry<String, Object?> entry in targetAssets.entries) {
        final String assetId = entry.key;
        final Object? pathInfo = entry.value;
        // The path info is a list of strings, where the first string is the type of path (see
        // [KernelAssetAbsolutePath]), and the second string is the actual path.
        if (pathInfo is List<Object?> && pathInfo.length >= 2) {
          final path = pathInfo[1]! as String;
          result[assetId] = path;
        }
      }
    }
    return result;
  }
}
