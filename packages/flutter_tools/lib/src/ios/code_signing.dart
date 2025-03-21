// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:process/process.dart';

import '../base/common.dart';
import '../base/config.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/terminal.dart';
import '../convert.dart' show utf8;
import 'plist_parser.dart';

const String _developmentTeamBuildSettingName = 'DEVELOPMENT_TEAM';
const String _codeSignStyleBuildSettingName = 'CODE_SIGN_STYLE';
const String _provisioningProfileSpecifierBuildSettingName = 'PROVISIONING_PROFILE_SPECIFIER';
const String _provisioningProfileBuildSettingName = 'PROVISIONING_PROFILE';

const String _codeSignSelectionCanceled =
    'Code-signing setup canceled. Your changes have not been saved.';

/// User message when no development certificates are found in the keychain.
///
/// The user likely never did any iOS development.
const String noCertificatesInstruction = '''
════════════════════════════════════════════════════════════════════════════════
No valid code signing certificates were found
You can connect to your Apple Developer account by signing in with your Apple ID
in Xcode and create an iOS Development Certificate as well as a Provisioning\u0020
Profile for your project by:
$fixWithDevelopmentTeamInstruction
  5- Trust your newly created Development Certificate on your iOS device
     via Settings > General > Device Management > [your new certificate] > Trust

For more information, please visit:
  https://developer.apple.com/library/content/documentation/IDEs/Conceptual/
  AppDistributionGuide/MaintainingCertificates/MaintainingCertificates.html

Or run on an iOS simulator without code signing
════════════════════════════════════════════════════════════════════════════════''';

/// User message when there are no provisioning profile for the current app bundle identifier.
///
/// The user did iOS development but never on this project and/or device.
const String noProvisioningProfileInstruction = '''
════════════════════════════════════════════════════════════════════════════════
No Provisioning Profile was found for your project's Bundle Identifier or your\u0020
device. You can create a new Provisioning Profile for your project in Xcode for\u0020
your team by:
$fixWithDevelopmentTeamInstruction

It's also possible that a previously installed app with the same Bundle\u0020
Identifier was signed with a different certificate.

For more information, please visit:
  https://flutter.dev/to/ios-app-signing

Or run on an iOS simulator without code signing
════════════════════════════════════════════════════════════════════════════════''';

/// Fallback error message for signing issues.
///
/// Couldn't auto sign the app but can likely solved by retracing the signing flow in Xcode.
const String noDevelopmentTeamInstruction = '''
════════════════════════════════════════════════════════════════════════════════
Building a deployable iOS app requires a selected Development Team with a\u0020
Provisioning Profile. Please ensure that a Development Team is selected by:
$fixWithDevelopmentTeamInstruction

For more information, please visit:
  https://flutter.dev/to/ios-development-team

Or run on an iOS simulator without code signing
════════════════════════════════════════════════════════════════════════════════''';
const String fixWithDevelopmentTeamInstruction = '''
  1- Open the Flutter project's Xcode target with
       open ios/Runner.xcworkspace
  2- Select the 'Runner' project in the navigator then the 'Runner' target
     in the project settings
  3- Make sure a 'Development Team' is selected under Signing & Capabilities > Team.\u0020
     You may need to:
         - Log in with your Apple ID in Xcode first
         - Ensure you have a valid unique Bundle ID
         - Register your device with your Apple Developer Account
         - Let Xcode automatically provision a profile for your app
  4- Build or run your project again''';

/// Pattern to extract identity from list of identities.
///
/// Example:
///
/// `  1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "iPhone Developer: Profile 1 (1111AAAA11)"`
/// extracts `iPhone Developer: Profile 1 (1111AAAA11)`
final RegExp _securityFindIdentityDeveloperIdentityExtractionPattern = RegExp(
  r'^\s*\d+\).+"(.+Develop(ment|er).+)"$',
);

/// Pattern to extract unique identifier from certificate Common Name.
///
/// Example:
///
/// `iPhone Developer: Profile 1 (1111AAAA11)`
/// extracts `1111AAAA11`
final RegExp _securityFindIdentityCertificateCnExtractionPattern = RegExp(r'.*\(([a-zA-Z0-9]+)\)');

/// Pattern to extract OU (Organizational Unit) from certificate subject.
///
/// Example:
///
/// `subject= /UID=A123BC4D5E/CN=Apple Development: Company Development (12ABCD234E)/OU=ABCDE1F2DH/O/O=Company LLC/C=US`
/// extracts `ABCDE1F2DH`
final RegExp _certificateOrganizationalUnitExtractionPattern = RegExp(r'OU=([a-zA-Z0-9]+)');

/// Pattern to extract CN (Common Name) from certificate subject.
///
/// Example:
///
/// `subject= /UID=A123BC4D5E/CN=Apple Development: Company Development (12ABCD234E)/OU=ABCDE1F2DH/O/O=Company LLC/C=US`
/// extracts `Apple Development: Company Development (12ABCD234E)`
final RegExp _certificateCommonNameExtractionPattern = RegExp(r'CN=([a-zA-Z0-9\s:\(\)]+)');

/// Given a [BuildableIOSApp], find build settings for either automatic (identity)
/// or manual (provisioning profile) code-signing.
///
/// If a valid provisioning profile or code-signing identity is saved in the
/// config, it will use that. Otherwise, it will try to find valid development
/// code-signing identities in the user's keychain, prompting a choice if multiple
/// are found.
///
/// Throws an error if the user cancels identity selection or if no identities
/// are found.
///
/// Will return null if the `DEVELOPMENT_TEAM` or `PROVISIONING_PROFILE` are
/// already set in the Xcode project's build settings.
Future<Map<String, String>?> getCodeSigningIdentityDevelopmentTeamBuildSetting({
  required Map<String, String> buildSettings,
  required ProcessManager processManager,
  required Platform platform,
  required Logger logger,
  required Config config,
  required Terminal terminal,
  required FileSystem fileSystem,
  required FileSystemUtils fileSystemUtils,
  required PlistParser plistParser,
}) async {
  // If the user already has it set in the project build settings itself,
  // continue with that.
  if (_isNotEmpty(buildSettings[_developmentTeamBuildSettingName])) {
    logger.printStatus(
      'Automatically signing iOS for device deployment using specified development '
      'team in Xcode project: ${buildSettings[_developmentTeamBuildSettingName]}',
    );
    return null;
  }

  if (_isNotEmpty(buildSettings[_provisioningProfileBuildSettingName])) {
    return null;
  }

  final XcodeCodeSigningSettings settings = XcodeCodeSigningSettings(
    config: config,
    logger: logger,
    platform: platform,
    processUtils: ProcessUtils(processManager: processManager, logger: logger),
    fileSystem: fileSystem,
    fileSystemUtils: fileSystemUtils,
    terminal: terminal,
    plistParser: plistParser,
  );

  return settings._getCodeSigningBuildSettings();
}

/// Returns the `DEVELOPMENT_TEAM` for automatic code-signing.
/// This function should not be used for manual code-signing.
///
/// This finds the `DEVELOPMENT_TEAM` from the saved `ios-signing-cert` or prompt the
/// user to select a code-signing identity for automatic code-signing if
/// `ios-signing-cert` is not saved or invalid.
///
/// If `ios-signing-profile` (manual code-signing with a provisioning profile)
/// is saved instead, returns null.
Future<String?> getCodeSigningIdentityDevelopmentTeam({
  required ProcessManager processManager,
  required Platform platform,
  required Logger logger,
  required Config config,
  required Terminal terminal,
  required FileSystem fileSystem,
  required FileSystemUtils fileSystemUtils,
  required PlistParser plistParser,
}) async {
  final XcodeCodeSigningSettings settings = XcodeCodeSigningSettings(
    config: config,
    logger: logger,
    platform: platform,
    processUtils: ProcessUtils(processManager: processManager, logger: logger),
    fileSystem: fileSystem,
    fileSystemUtils: fileSystemUtils,
    terminal: terminal,
    plistParser: plistParser,
  );

  final Map<String, String>? buildSettings = await settings._getCodeSigningBuildSettings(
    shouldExitOnNoCerts: false,
    automaticCodeSignStyleOnly: true,
  );

  return buildSettings?[_developmentTeamBuildSettingName];
}

class XcodeCodeSigningSettings {
  XcodeCodeSigningSettings({
    required Config config,
    required Logger logger,
    required Platform platform,
    required ProcessUtils processUtils,
    required FileSystem fileSystem,
    required FileSystemUtils fileSystemUtils,
    required Terminal terminal,
    required PlistParser plistParser,
  }) : _config = config,
       _logger = logger,
       _platform = platform,
       _processUtils = processUtils,
       _fileSystem = fileSystem,
       _fileSystemUtils = fileSystemUtils,
       _plistParser = plistParser,
       _terminal = terminal;

  final Config _config;
  final Logger _logger;
  final Platform _platform;
  final ProcessUtils _processUtils;
  final FileSystem _fileSystem;
  final FileSystemUtils _fileSystemUtils;
  final Terminal _terminal;
  final PlistParser _plistParser;

  /// Config key for saved code-signing identity. A code-signing identity is a
  /// combination of a certificate and the private key that matches the public
  /// key in that certificate.
  ///
  /// Example: Apple Development: My Name (ABC1234EFG)
  static const String kConfigCodeSignCertificate = 'ios-signing-cert';

  /// Config key for saved provisioning profile file path. A provisioning profile
  /// sets criteria for who is allowed to sign code, what apps are allowed to be
  /// signed, where and when those apps can be run and how those apps are entitled.
  ///
  /// Example: ~/Library/Developer/Xcode/UserData/Provisioning Profiles/1234567a-bcde-89f0-1234-g56hi567j8kl.mobileprovision
  static const String kConfigCodeSignProvisioningProfile = 'ios-signing-profile';

  /// Reset both [kConfigCodeSignCertificate] and [kConfigCodeSignProvisioningProfile]
  /// config settings.
  static void resetSettings(Config config, Logger logger) {
    config.removeValue(kConfigCodeSignCertificate);
    logger.printStatus('Removing "$kConfigCodeSignCertificate" value.');

    config.removeValue(kConfigCodeSignProvisioningProfile);
    logger.printStatus('Removing "$kConfigCodeSignProvisioningProfile" value.');
  }

  /// Get and validate code-sign settings from the config (provisioning profile
  /// or identity) or prompt the user to select a code-signing identity for
  /// automatic code-signing.
  ///
  /// If a provisioning profile is saved, return settings with `CODE_SIGN_STYLE=Manual`,
  /// `DEVELOPMENT_TEAM`, and `PROVISIONING_PROFILE_SPECIFIER`. If the profile
  /// is no longer valid, return null.
  ///
  /// If a identity is saved, return settings with `DEVELOPMENT_TEAM`. If no
  /// settings are found or if the saved identity is no longer valid, prompt
  /// the user to select a code-signing identity for automatic code-signing.
  ///
  /// If [shouldExitOnNoCerts] is true, throw a toolExit if no code-signing
  /// identities are found.
  ///
  /// If [automaticCodeSignStyleOnly] is true, return null if a provisioning
  /// profile is saved in the config.
  Future<Map<String, String>?> _getCodeSigningBuildSettings({
    bool shouldExitOnNoCerts = true,
    bool automaticCodeSignStyleOnly = false,
  }) async {
    if (!_platform.isMacOS) {
      _logger.printTrace('Unable to get code-sign settings on non-Mac platform.');
      return null;
    }
    final bool toolsValidated = await _validateCodeSignSearchTools();
    if (!toolsValidated) {
      return null;
    }

    final List<String> validCodeSigningIdentities = await _getSigningIdentities();
    if (validCodeSigningIdentities.isEmpty) {
      if (shouldExitOnNoCerts) {
        _logger.printError(noCertificatesInstruction, emphasis: true);
        throwToolExit(
          'No development certificates available to code sign app for device deployment',
        );
      } else {
        _logger.printTrace(
          'No development certificates available to code sign app for device deployment',
        );
        return null;
      }
    }

    final String? savedProfile =
        _config.getValue(XcodeCodeSigningSettings.kConfigCodeSignProvisioningProfile) as String?;

    if (savedProfile != null) {
      // Provisioning profile should be used for manual signing.
      if (automaticCodeSignStyleOnly) {
        return null;
      }
      final _ProvisioningProfile? validatedProfile = await _validateSavedProfile(
        savedProfile,
        validCodeSigningIdentities,
      );
      if (validatedProfile == null) {
        return null;
      }
      _logger.printStatus(
        'Provisioning profile "${validatedProfile.name}" selected for iOS code signing',
      );
      return <String, String>{
        _codeSignStyleBuildSettingName: _CodeSigningStyle.manual.label,
        _developmentTeamBuildSettingName: validatedProfile.teamIdentifier,
        _provisioningProfileSpecifierBuildSettingName: validatedProfile.name,
      };
    }

    final String? savedCertChoice =
        _config.getValue(XcodeCodeSigningSettings.kConfigCodeSignCertificate) as String?;

    String? identity;
    if (savedCertChoice != null) {
      identity = _validateSavedIdentity(savedCertChoice, validCodeSigningIdentities);
      if (identity == null) {
        _logger.printError(
          'Saved signing certificate "$savedCertChoice" is not a valid development '
          'certificate. To clear, use "flutter config --clear-ios-signing-settings"',
        );
      }
    }

    if (identity == null) {
      identity = await _selectSigningIdentity(
        validCodeSigningIdentities,
        autoSelectSingle: true,
        throwOnCancel: true,
      );
      if (identity == null) {
        return null;
      }
    }

    final String? developmentTeam = await _getDevelopmentTeamFromIdentity(identity);
    if (developmentTeam == null) {
      return null;
    }
    _logger.printStatus('Developer identity "$identity" selected for iOS code signing');
    return <String, String>{_developmentTeamBuildSettingName: developmentTeam};
  }

  void _saveCodeSignIdentity(String identity) {
    _logger.printStatus('Certificate choice "$identity" saved.');
    _config.setValue(kConfigCodeSignCertificate, identity);
  }

  void _saveProvisioningProfile(_ProvisioningProfile profile) {
    _logger.printStatus('Provisioning Profile "${profile.name}" saved.');
    _config.setValue(kConfigCodeSignProvisioningProfile, profile.filePath);
  }

  /// Validates that command-line tools `security` and `openssl` are available.
  Future<bool> _validateCodeSignSearchTools({bool printError = false}) async {
    // If the user's environment is missing the tools needed to find and read
    // certificates, abandon. Tools should be pre-equipped on macOS.
    if (!await _processUtils.exitsHappy(const <String>['which', 'security']) ||
        !await _processUtils.exitsHappy(const <String>['which', 'openssl'])) {
      if (printError) {
        _logger.printError('Unable to validate code-signing tools `security` and/or `openssl`.');
      } else {
        _logger.printTrace('Unable to validate code-signing tools `security` and/or `openssl`.');
      }
      return false;
    }
    return true;
  }

  /// Get list of code-signing identities.
  Future<List<String>> _getSigningIdentities() async {
    String findIdentityStdout;
    try {
      findIdentityStdout =
          (await _processUtils.run(<String>[
            'security',
            'find-identity',
            '-p',
            'codesigning',
            '-v',
          ], throwOnError: true)).stdout.trim();
    } on ProcessException catch (error) {
      _logger.printError('Unexpected failure from find-identity: $error.');
      return <String>[];
    }

    return findIdentityStdout
        .split('\n')
        .map<String?>((String outputLine) {
          return _securityFindIdentityDeveloperIdentityExtractionPattern
              .firstMatch(outputLine)
              ?.group(1);
        })
        .where(_isNotEmpty)
        .whereType<String>()
        .toSet() // Unique.
        .toList();
  }

  /// Validates the saved provisioning profile still exists and that there is a
  /// valid identity/certificate for the profile.
  ///
  /// Returns null if profile cannot be found, parsed, or validated.
  Future<_ProvisioningProfile?> _validateSavedProfile(
    String savedProfilePath,
    List<String> validCodeSigningIdentities,
  ) async {
    final File savedProfile = _fileSystem.file(savedProfilePath);
    if (!savedProfile.existsSync()) {
      _logger.printError('Unable to find saved provisioning profile $savedProfilePath');
      return null;
    }
    final _ProvisioningProfile? parsedProfile = await _parseProvisioningProfile(savedProfile);
    if (parsedProfile == null) {
      return null;
    }
    for (final File cert in parsedProfile.developerCertificates) {
      final String? identity = await _validateIdentityFromCert(cert, validCodeSigningIdentities);
      if (identity != null) {
        return parsedProfile;
      }
    }
    _logger.printError(
      'Unable to find a valid certificate matching the provisioning profile $savedProfilePath',
    );
    return null;
  }

  /// Decode and convert a .mobileprovision file to a .plist file and then
  /// parse the .plist into [_ProvisioningProfile].
  Future<_ProvisioningProfile?> _parseProvisioningProfile(File provisioningProfileFile) async {
    final Directory profilesDirectory = _fileSystem.systemTempDirectory.childDirectory(
      'provisioning_profiles',
    );
    profilesDirectory.createSync(recursive: true);
    final File decodedProfile = profilesDirectory.childFile(
      'decoded_profile_${provisioningProfileFile.basename}.plist',
    );
    try {
      await _processUtils.run(<String>[
        'security',
        'cms',
        '-D',
        '-i',
        provisioningProfileFile.path,
        '-o',
        decodedProfile.path,
      ], throwOnError: true);
    } on ProcessException catch (error) {
      _logger.printError('Unexpected failure from security: $error.');
      return null;
    }
    if (!decodedProfile.existsSync()) {
      _logger.printError('Failed to decode ${provisioningProfileFile.basename}');
      return null;
    }
    try {
      final Map<String, Object> contents = _plistParser.parseFile(decodedProfile.path);
      return _ProvisioningProfile.fromPlist(
        provisioningProfileFile.path,
        contents,
        fileSystem: _fileSystem,
      );
    } on Exception catch (e) {
      _logger.printError('Failed to parse provisioning profile: $e');
      return null;
    }
  }

  /// Extract the Common Name from the [certificate] and then search for
  /// matching identities in [validCodeSigningIdentities]. Return the first
  /// matching.
  Future<String?> _validateIdentityFromCert(
    File certificate,
    List<String> validCodeSigningIdentities,
  ) async {
    final String resultsStdOut;
    try {
      final RunResult results = await _processUtils.run(<String>[
        'openssl',
        'x509',
        '-subject',
        '-in',
        certificate.path,
        '-inform',
        'DER',
      ], throwOnError: true);
      resultsStdOut = results.stdout;
    } on ProcessException catch (error) {
      _logger.printError('Unexpected failure from openssl: $error.');
      return null;
    }

    final String? commonName = _certificateCommonNameExtractionPattern
        .firstMatch(resultsStdOut)
        ?.group(1);
    if (commonName == null) {
      _logger.printError('Unable to extract Common Name from certificate.');
      return null;
    }
    return validCodeSigningIdentities.where((String id) => id.contains(commonName)).firstOrNull;
  }

  /// Returns [identity] if it is found within [validCodeSigningIdentities] and
  /// prints a message that it was found.
  String? _validateSavedIdentity(String identity, List<String> validCodeSigningIdentities) {
    if (validCodeSigningIdentities.contains(identity)) {
      _logger.printStatus(
        'Found saved certificate choice "$identity". To clear, use "flutter config '
        '--clear-ios-signing-settings".',
      );
      return identity;
    }
    return null;
  }

  /// Find the certificate for the [identity] and extract the development team /
  /// organizational unit from the certificate.
  Future<String?> _getDevelopmentTeamFromIdentity(String identity) async {
    final String? signingCertificateId = _securityFindIdentityCertificateCnExtractionPattern
        .firstMatch(identity)
        ?.group(1);

    // If `security`'s output format changes, we'd have to update the above regex.
    if (signingCertificateId == null) {
      _logger.printError('Unable to parse common name from code-signing certificate $identity');
      return null;
    }
    String signingCertificateStdout;
    try {
      signingCertificateStdout =
          (await _processUtils.run(<String>[
            'security',
            'find-certificate',
            '-c',
            signingCertificateId,
            '-p',
          ], throwOnError: true)).stdout.trim();
    } on ProcessException catch (error) {
      _logger.printError('Unexpected error from security: $error');
      return null;
    }

    final Process opensslProcess = await _processUtils.start(const <String>[
      'openssl',
      'x509',
      '-subject',
    ]);

    await ProcessUtils.writeToStdinGuarded(
      stdin: opensslProcess.stdin,
      content: signingCertificateStdout,
      onError: (Object? error, _) {
        throw Exception('Unexpected error when writing to openssl: $error');
      },
    );
    await opensslProcess.stdin.close();

    final String opensslOutput = await utf8.decodeStream(opensslProcess.stdout);
    // Fire and forget discard of the stderr stream so we don't hold onto resources.
    // Don't care about the result.
    unawaited(opensslProcess.stderr.drain<String?>());

    if (await opensslProcess.exitCode != 0) {
      _logger.printError('Failed to get subject name for code-signing certificate $identity');
      return null;
    }

    final String? developmentTeam = _certificateOrganizationalUnitExtractionPattern
        .firstMatch(opensslOutput)
        ?.group(1);
    if (developmentTeam == null) {
      _logger.printError(
        'Unable to parse development team from code-signing certificate $identity',
      );
      return null;
    }
    return developmentTeam;
  }

  /// Select code-signinging settings and save to config.
  ///
  /// Available options include automatic signing with a code-signing identity
  /// or manual code-signing with a provisioning profile.
  Future<void> selectSettings() async {
    // If terminal UI can't be used, just attempt with the first valid certificate
    // since we can't ask the user.
    if (!_terminal.stdinHasTerminal) {
      _logger.printError(
        'Unable to detect stdin for the terminal. Code-signing selection requires stdin.',
      );
      return;
    }
    _terminal.usesTerminalUi = true;

    final bool toolsValidated = await _validateCodeSignSearchTools(printError: true);
    if (!toolsValidated) {
      return;
    }

    final String? savedCertChoice =
        _config.getValue(XcodeCodeSigningSettings.kConfigCodeSignCertificate) as String?;
    final String? savedProfile =
        _config.getValue(XcodeCodeSigningSettings.kConfigCodeSignProvisioningProfile) as String?;

    if (savedCertChoice != null || savedProfile != null) {
      _logger.printError(
        'Code-signing settings are already set. To reset them, use "flutter config '
        '--clear-ios-signing-settings"',
      );
      return;
    }

    final _CodeSigningStyle? style = await _selectSigningStyle();
    if (style == null) {
      _logger.printWarning(_codeSignSelectionCanceled);
      return;
    }

    if (style == _CodeSigningStyle.automatic) {
      final List<String> validCodeSigningIdentities = await _getSigningIdentities();
      if (validCodeSigningIdentities.isEmpty) {
        _logger.printError(noCertificatesInstruction, emphasis: true);
        _logger.printWarning(_codeSignSelectionCanceled);
        return;
      }
      final String? identity = await _selectSigningIdentity(validCodeSigningIdentities);
      if (identity == null) {
        _logger.printWarning(_codeSignSelectionCanceled);
        return;
      }
    } else if (style == _CodeSigningStyle.manual) {
      final List<_ProvisioningProfile> validProvisioningProfiles = await _getProvisioningProfiles();
      if (validProvisioningProfiles.isEmpty) {
        _logger.printError(
          'No provisioning profiles were found. To learn how to create or download '
          'a provisioning profile, please see '
          'https://developer.apple.com/help/account/manage-provisioning-profiles/create-a-development-provisioning-profile',
          emphasis: true,
        );
        _logger.printWarning(_codeSignSelectionCanceled);
        return;
      }
      final _ProvisioningProfile? profile = await _selectProvisioningProfile(
        validProvisioningProfiles,
      );
      if (profile == null) {
        _logger.printWarning(_codeSignSelectionCanceled);
        return;
      }
      _saveProvisioningProfile(profile);
    }
  }

  /// Prompt user to select a code-signing style (Automatic or Manual).
  Future<_CodeSigningStyle?> _selectSigningStyle() async {
    _logger.printStatus('Code Signing Styles:', emphasis: true);
    _logger.printStatus(
      '  This setting specifies the method used to acquire and locate signing '
      'assets. Choose Automatic to let Xcode automatically create and update '
      'profiles, app IDs, and certificates. Choose Manual to create and update '
      'these yourself on the developer website.',
    );
    _logger.printStatus('[1]: ${_CodeSigningStyle.automatic.label} (recommended)');
    _logger.printStatus('[2]: ${_CodeSigningStyle.manual.label}');
    final String choice = await _terminal.promptForCharInput(
      <String>['1', '2', 'q'],
      prompt: 'Select a signing style (or "q" to quit)',
      defaultChoiceIndex: 0, // Just pressing enter chooses the first one.
      logger: _logger,
      displayAcceptedCharacters: false,
    );
    return switch (choice) {
      '1' => _CodeSigningStyle.automatic,
      '2' => _CodeSigningStyle.manual,
      _ => null,
    };
  }

  /// Prompts the user to select a code-signing identity from a list of [validCodeSigningIdentities].
  /// Selects the first one found without prompting if there is no stdin or if
  /// [autoSelectSingle] is true and only one identity was found.
  ///
  /// Saves the selected identity to the config. Does not save if auto-selected.
  ///
  /// Throw an error if [throwOnCancel] is true and the user quits while
  /// selecting an identity.
  Future<String?> _selectSigningIdentity(
    List<String> validCodeSigningIdentities, {
    bool autoSelectSingle = false,
    bool throwOnCancel = false,
  }) async {
    if (validCodeSigningIdentities.isEmpty) {
      return null;
    }

    if (autoSelectSingle && validCodeSigningIdentities.length == 1) {
      return validCodeSigningIdentities.first;
    }

    // If terminal UI can't be used, just attempt with the first valid certificate
    // since we can't ask the user.
    if (!_terminal.stdinHasTerminal) {
      return validCodeSigningIdentities.first;
    }
    _terminal.usesTerminalUi = true;

    _logger.printStatus(
      '\nValid development certificates available (your choice will be saved):',
      emphasis: true,
    );
    final int count = validCodeSigningIdentities.length;
    for (int i = 0; i < count; i++) {
      _logger.printStatus('[${i + 1}] ${validCodeSigningIdentities[i]}');
    }
    final String choice = await _terminal.promptForCharInput(
      List<String>.generate(count, (int number) => '${number + 1}')..add('q'),
      prompt: 'Please select a certificate for code signing (or "q" to quit)',
      defaultChoiceIndex: 0, // Just pressing enter chooses the first one.
      logger: _logger,
      displayAcceptedCharacters: false,
    );
    if (choice == 'q') {
      if (throwOnCancel) {
        throwToolExit(
          'No certificate was selected. Code signing is required to build a deployable iOS app.',
        );
      } else {
        return null;
      }
    }
    final String selectedCert = validCodeSigningIdentities[int.parse(choice) - 1];

    _saveCodeSignIdentity(selectedCert);

    return selectedCert;
  }

  /// Get list of provisioning profiles from `~/Library/Developer/Xcode/UserData/Provisioning\ Profiles`.
  ///
  /// Only return non-Xcode-managed profiles with matching valid identities.
  Future<List<_ProvisioningProfile>> _getProvisioningProfiles() async {
    final String? homeDir = _fileSystemUtils.homeDirPath;
    if (homeDir == null) {
      return <_ProvisioningProfile>[];
    }
    final Directory profileDirectory = _fileSystem.directory(
      _fileSystem.path.join(
        homeDir,
        'Library',
        'Developer',
        'Xcode',
        'UserData',
        'Provisioning Profiles',
      ),
    );

    if (!profileDirectory.existsSync()) {
      return <_ProvisioningProfile>[];
    }

    final List<String> validCodeSigningIdentities = await _getSigningIdentities();

    final List<_ProvisioningProfile> profiles = <_ProvisioningProfile>[];
    for (final FileSystemEntity entity in profileDirectory.listSync()) {
      if (entity is! File || _fileSystem.path.extension(entity.path) != '.mobileprovision') {
        continue;
      }
      final _ProvisioningProfile? profile = await _parseProvisioningProfile(entity);

      // Xcode managed profiles can't be used for manual code-signing.
      final bool? isXcodeManaged = profile?.isXcodeManaged;
      if (profile == null || (isXcodeManaged != null && isXcodeManaged)) {
        continue;
      }

      // Only list profiles with valid identities.
      for (final File cert in profile.developerCertificates) {
        if (await _validateIdentityFromCert(cert, validCodeSigningIdentities) != null) {
          profiles.add(profile);
          break;
        }
      }
    }
    return profiles;
  }

  /// Prompt the user to select from list of [validatedProfiles].
  Future<_ProvisioningProfile?> _selectProvisioningProfile(
    List<_ProvisioningProfile> validatedProfiles,
  ) async {
    if (validatedProfiles.isEmpty) {
      return null;
    }

    _logger.printStatus(
      '\nValid provisioning profiles available (your choice will be saved):',
      emphasis: true,
    );
    int count = 1;
    for (final _ProvisioningProfile profile in validatedProfiles) {
      _logger.printStatus(
        '[$count]: ${profile.name} (${profile.teamIdentifier}) | Expires ${profile.expirationDate}',
      );
      count++;
    }

    _logger.printStatus('[$count]: Other (not listed)');
    final String choice = await _terminal.promptForCharInput(
      List<String>.generate(validatedProfiles.length + 1, (int number) => '${number + 1}')
        ..add('q'),
      prompt: 'Select a provisioning profile (or "q" to quit)',
      defaultChoiceIndex: 0, // Just pressing enter chooses the first one.
      logger: _logger,
      displayAcceptedCharacters: false,
    );
    if (choice == 'q') {
      return null;
    } else if (choice == '$count') {
      _logger.printError(
        'If you have already downloaded a provisioning profile, double-click it '
        'in Finder to install it. To learn how to create or download a '
        'provisioning profile, please see '
        'https://developer.apple.com/help/account/manage-provisioning-profiles/create-a-development-provisioning-profile',
      );
      return null;
    }

    return validatedProfiles[int.parse(choice) - 1];
  }
}

enum _CodeSigningStyle {
  automatic('Automatic'),
  manual('Manual');

  const _CodeSigningStyle(this.label);
  final String label;
}

class _ProvisioningProfile {
  _ProvisioningProfile({
    required this.filePath,
    required this.name,
    required this.teamIdentifier,
    required this.expirationDate,
    required this.developerCertificates,
    this.isXcodeManaged,
  });

  factory _ProvisioningProfile.fromPlist(
    String filePath,
    Map<String, Object> data, {
    required FileSystem fileSystem,
  }) {
    final String? name = data['Name']?.toString();
    if (name == null) {
      throw Exception('Unable to parse Name value for provisioning profile.');
    }

    List<String> identifiers = <String>[];
    if (data case {'TeamIdentifier': final List<Object?> values}) {
      try {
        identifiers = List<String>.from(values);
        if (identifiers.isEmpty) {
          throw Exception('Unable to parse TeamIdentifier value for provisioning profile.');
        }
      } on TypeError {
        throw Exception('Error parsing TeamIdentifier value: $values');
      }
    }

    final String? uuid = data['UUID']?.toString();
    if (uuid == null) {
      throw Exception('Unable to parse UUID value for provisioning profile.');
    }

    final List<File> certificateFiles = <File>[];
    if (data case {'DeveloperCertificates': final List<Object?> values}) {
      for (int i = 0; i < values.length; i++) {
        final Object? obj = values[i];
        if (obj != null && obj is List<int>) {
          final File certFile = fileSystem.systemTempDirectory
              .childDirectory('provisioning_profile_certificates')
              .childFile('${uuid}_$i.cer');
          certFile.createSync(recursive: true);
          certFile.writeAsBytesSync(obj);
          certificateFiles.add(certFile);
        }
      }
    }
    if (certificateFiles.isEmpty) {
      throw Exception('Unable to parse DeveloperCertificates value for provisioning profile.');
    }

    final String? expirationDateString = data['ExpirationDate']?.toString();
    if (expirationDateString == null) {
      throw Exception('Unable to parse ExpirationDate value for provisioning profile.');
    }
    final DateTime expirationDate = DateTime.parse(expirationDateString);

    return _ProvisioningProfile(
      filePath: filePath,
      name: name,
      developerCertificates: certificateFiles,
      isXcodeManaged: data['IsXcodeManaged'] is bool? ? data['IsXcodeManaged'] as bool? : null,
      expirationDate: expirationDate,
      teamIdentifier: identifiers.first,
    );
  }

  final String filePath;
  final String name;
  final String teamIdentifier;
  final DateTime expirationDate;
  final List<File> developerCertificates;
  final bool? isXcodeManaged;
}

/// Returns true if s is a not empty string.
bool _isNotEmpty(String? s) => s != null && s.isNotEmpty;
