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
  /// First, attempt to find the codesigning identity in the Flutter project build settings.
  /// If that fails, attempt to find the codesigning identity in the Flutter config.
  /// If no codesign identity is found, print a warning and return null.
  Future<String?> getCodesignIdentity(BuildInfo buildInfo, XcodeBasedProject xcodeProject) async {
    final Status status = _logger.startProgress('Finding codesigning identities...');
    final bool toolsAvailable = await _xcodeCodeSigningSettings.validateCodeSignSearchTools();
    if (!toolsAvailable) {
      throwToolExit(
        'Unable to find code-signing tools `security` and/or `openssl`. Ensure Xcode is installed '
        'and up to date.',
      );
    }
    final List<String> identities = await _xcodeCodeSigningSettings.getSigningIdentities();
    if (identities.isEmpty) {
      throwToolExit('$noCertificatesFound\n\n$noCertificatesFoundMoreInfo');
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
      return identity;
    }

    // Next, attempt to get codesigning from Flutter config
    identity = await _getCodesignIdentityFromConfig(identities);
    if (identity != null) {
      status.stop();
      _logger.printStatus('   └── Using code-signing identity from Flutter config: $identity');
      return identity;
    }

    status.stop();
    throwToolExit(
      'No valid code-signing identity found. Please specify which identity to use with '
      '--${FlutterOptions.kCodesignIdentity} or use --no-codesign.',
    );
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
    if (matchingIdentities.length == 1) {
      return matchingIdentities.single;
    }
    return null;
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
      if (matchingIdentities.length == 1) {
        return matchingIdentities.single;
      }
      return null;
    }
    return _xcodeCodeSigningSettings.getIdentityFromCertFromConfig(identities);
  }

  /// Codesigns a file or directory if [codesignIdentity] is not null. Throws [ToolExit] if the
  /// codesigning fails.
  static Future<void> codesign({
    required FileSystemEntity artifact,
    required ProcessManager processManager,
    required String? codesignIdentity,
    required BuildMode buildMode,
  }) async {
    if (codesignIdentity == null) {
      return;
    }
    final ProcessResult codesignResult = await processManager.run(<String>[
      'codesign',
      '--force',
      '--sign',
      codesignIdentity,
      if (buildMode != BuildMode.release) ...<String>[
        // Mimic Xcode's timestamp codesigning behavior on non-release binaries.
        '--timestamp=none',
      ],
      artifact.path,
    ]);
    if (codesignResult.exitCode != 0) {
      throwToolExit('Unable to codesign ${artifact.basename}: ${codesignResult.stderr}');
    }
  }

  /// Codesigns a Flutter/FlutterMacOS XCFramework and it's sub-frameworks if [codesignIdentity]
  /// is not null.
  ///
  /// Codesigning the sub-frameworks is needed for the Flutter/FlutterMacOS XCFramework because on
  /// stable the engine artifacts have both the XCFramework and the frameworks inside codesigned,
  /// so to properly overwrite the signature, the sub-frameworks need to be codesigned as well.
  static Future<void> codesignFlutterXCFramework({
    required Directory xcframework,
    required String? codesignIdentity,
    required BuildMode buildMode,
    required FlutterDarwinPlatform targetPlatform,
    required ProcessManager processManager,
  }) async {
    if (codesignIdentity == null) {
      return;
    }
    for (final FileSystemEntity child in xcframework.listSync()) {
      if (child is Directory && child.basename.contains(targetPlatform.name)) {
        final Directory framework = child.childDirectory('${targetPlatform.binaryName}.framework');
        if (framework.existsSync()) {
          await DarwinAddToAppCodesigning.codesign(
            codesignIdentity: codesignIdentity,
            artifact: framework,
            processManager: processManager,
            buildMode: buildMode,
          );
        }
      }
    }
    // After codesigning the sub-frameworks, codesign the XCFramework. This must be done after so
    // that nothing within the XCFramework changes after code-signing it.
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
        if (pathInfo is List<Object?> && pathInfo.length >= 2) {
          final path = pathInfo[1]! as String;
          result[assetId] = path;
        }
      }
    }
    return result;
  }
}
