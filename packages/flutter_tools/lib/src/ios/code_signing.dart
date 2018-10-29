// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:async';
import 'dart:convert' show utf8;

import 'package:quiver/strings.dart';

import '../application_package.dart';
import '../base/common.dart';
import '../base/io.dart';
import '../base/process.dart';
import '../base/terminal.dart';
import '../globals.dart';

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
  https://flutter.io/setup/#deploy-to-ios-devices

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
  https://flutter.io/setup/#deploy-to-ios-devices

Or run on an iOS simulator without code signing
════════════════════════════════════════════════════════════════════════════════''';
const String fixWithDevelopmentTeamInstruction = '''
  1- Open the Flutter project's Xcode target with
       open ios/Runner.xcworkspace
  2- Select the 'Runner' project in the navigator then the 'Runner' target
     in the project settings
  3- In the 'General' tab, make sure a 'Development Team' is selected.\u0020
     You may need to:
         - Log in with your Apple ID in Xcode first
         - Ensure you have a valid unique Bundle ID
         - Register your device with your Apple Developer Account
         - Let Xcode automatically provision a profile for your app
  4- Build or run your project again''';


final RegExp _securityFindIdentityDeveloperIdentityExtractionPattern =
    RegExp(r'^\s*\d+\).+"(.+Developer.+)"$');
final RegExp _securityFindIdentityCertificateCnExtractionPattern = RegExp(r'.*\(([a-zA-Z0-9]+)\)');
final RegExp _certificateOrganizationalUnitExtractionPattern = RegExp(r'OU=([a-zA-Z0-9]+)');

/// Given a [BuildableIOSApp], this will try to find valid development code
/// signing identities in the user's keychain prompting a choice if multiple
/// are found.
///
/// Returns a set of build configuration settings that uses the selected
/// signing identities.
///
/// Will return null if none are found, if the user cancels or if the Xcode
/// project has a development team set in the project's build settings.
Future<Map<String, String>> getCodeSigningIdentityDevelopmentTeam({
  BuildableIOSApp iosApp,
  bool usesTerminalUi = true
}) async{
  final Map<String, String> buildSettings = iosApp.project.buildSettings;
  if (buildSettings == null)
    return null;

  // If the user already has it set in the project build settings itself,
  // continue with that.
  if (isNotEmpty(buildSettings['DEVELOPMENT_TEAM'])) {
    printStatus(
      'Automatically signing iOS for device deployment using specified development '
      'team in Xcode project: ${buildSettings['DEVELOPMENT_TEAM']}'
    );
    return null;
  }

  if (isNotEmpty(buildSettings['PROVISIONING_PROFILE']))
    return null;

  // If the user's environment is missing the tools needed to find and read
  // certificates, abandon. Tools should be pre-equipped on macOS.
  if (!exitsHappy(const <String>['which', 'security']) || !exitsHappy(const <String>['which', 'openssl']))
    return null;

  const List<String> findIdentityCommand =
      <String>['security', 'find-identity', '-p', 'codesigning', '-v'];
  final List<String> validCodeSigningIdentities = runCheckedSync(findIdentityCommand)
      .split('\n')
      .map<String>((String outputLine) {
        return _securityFindIdentityDeveloperIdentityExtractionPattern
            .firstMatch(outputLine)
            ?.group(1);
      })
      .where(isNotEmpty)
      .toSet() // Unique.
      .toList();

  final String signingIdentity = await _chooseSigningIdentity(validCodeSigningIdentities, usesTerminalUi);

  // If none are chosen, return null.
  if (signingIdentity == null)
    return null;

  printStatus('Signing iOS app for device deployment using developer identity: "$signingIdentity"');

  final String signingCertificateId =
      _securityFindIdentityCertificateCnExtractionPattern
          .firstMatch(signingIdentity)
          ?.group(1);

  // If `security`'s output format changes, we'd have to update the above regex.
  if (signingCertificateId == null)
    return null;

  final String signingCertificate = runCheckedSync(
    <String>['security', 'find-certificate', '-c', signingCertificateId, '-p']
  );

  final Process opensslProcess = await runCommand(const <String>['openssl', 'x509', '-subject']);
  await (opensslProcess.stdin..write(signingCertificate)).close();

  final String opensslOutput = await utf8.decodeStream(opensslProcess.stdout);
  // Fire and forget discard of the stderr stream so we don't hold onto resources.
  // Don't care about the result.
  opensslProcess.stderr.drain<String>(); // ignore: unawaited_futures

  if (await opensslProcess.exitCode != 0)
    return null;

  final Map<String, String> signingConfigs = <String, String> {
    'DEVELOPMENT_TEAM': _certificateOrganizationalUnitExtractionPattern
      .firstMatch(opensslOutput)
      ?.group(1),
  };

  if (opensslOutput.contains('iPhone Developer: Google Development')) {
    signingConfigs['PROVISIONING_PROFILE_SPECIFIER'] = 'Google Development';
    signingConfigs['CODE_SIGN_STYLE'] = 'Manual';
    printStatus("Manually selecting Google's mobile provisioning profile (see go/google-flutter-signing).");
  }

  return signingConfigs;
}

Future<String> _chooseSigningIdentity(List<String> validCodeSigningIdentities, bool usesTerminalUi) async {
  // The user has no valid code signing identities.
  if (validCodeSigningIdentities.isEmpty) {
    printError(noCertificatesInstruction, emphasis: true);
    throwToolExit('No development certificates available to code sign app for device deployment');
  }

  if (validCodeSigningIdentities.length == 1)
    return validCodeSigningIdentities.first;

  if (validCodeSigningIdentities.length > 1) {
    final String savedCertChoice = config.getValue('ios-signing-cert');

    if (savedCertChoice != null) {
      if (validCodeSigningIdentities.contains(savedCertChoice)) {
        printStatus('Found saved certificate choice "$savedCertChoice". To clear, use "flutter config".');
        return savedCertChoice;
      }
      else {
        printError('Saved signing certificate "$savedCertChoice" is not a valid development certificate');
      }
    }

    // If terminal UI can't be used, just attempt with the first valid certificate
    // since we can't ask the user.
    if (!usesTerminalUi)
      return validCodeSigningIdentities.first;

    final int count = validCodeSigningIdentities.length;
    printStatus(
      'Multiple valid development certificates available (your choice will be saved):',
      emphasis: true,
    );
    for (int i=0; i<count; i++) {
      printStatus('  ${i+1}) ${validCodeSigningIdentities[i]}', emphasis: true);
    }
    printStatus('  a) Abort', emphasis: true);

    final String choice = await terminal.promptForCharInput(
      List<String>.generate(count, (int number) => '${number + 1}')
          ..add('a'),
      prompt: 'Please select a certificate for code signing',
      displayAcceptedCharacters: true,
      defaultChoiceIndex: 0, // Just pressing enter chooses the first one.
    );

    if (choice == 'a') {
      throwToolExit('Aborted. Code signing is required to build a deployable iOS app.');
    } else {
      final String selectedCert = validCodeSigningIdentities[int.parse(choice) - 1];
      printStatus('Certificate choice "$selectedCert" saved');
      config.setValue('ios-signing-cert', selectedCert);
      return selectedCert;
    }
  }

  return null;
}
