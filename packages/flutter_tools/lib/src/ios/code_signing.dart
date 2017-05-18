// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:async';
import 'dart:convert' show UTF8;

import 'package:quiver/iterables.dart';
import 'package:quiver/strings.dart';

import '../application_package.dart';
import '../base/common.dart';
import '../base/io.dart';
import '../base/process.dart';
import '../base/terminal.dart';
import '../globals.dart';

const String noCertificatesInstruction = '''
═══════════════════════════════════════════════════════════════════════════════════
No valid code signing certificates were found
Please ensure that you have a valid Development Team with valid iOS Development Certificates
associated with your Apple ID by:
  1- Opening the Xcode application
  2- Go to Xcode->Preferences->Accounts
  3- Make sure that you're signed in with your Apple ID via the '+' button on the bottom left
  4- Make sure that you have development certificates available by signing up to Apple
     Developer Program and/or downloading available profiles as needed.
For more information, please visit:
  https://developer.apple.com/library/content/documentation/IDEs/Conceptual/AppDistributionGuide/MaintainingCertificates/MaintainingCertificates.html

Or run on an iOS simulator without code signing
═══════════════════════════════════════════════════════════════════════════════════''';
const String noDevelopmentTeamInstruction = '''
═══════════════════════════════════════════════════════════════════════════════════
Building a deployable iOS app requires a selected Development Team with a Provisioning Profile
Please ensure that a Development Team is selected by:
  1- Opening the Flutter project's Xcode target with
       open ios/Runner.xcworkspace
  2- Select the 'Runner' project in the navigator then the 'Runner' target
     in the project settings
  3- In the 'General' tab, make sure a 'Development Team' is selected\n
For more information, please visit:
  https://flutter.io/setup/#deploy-to-ios-devices\n
Or run on an iOS simulator
═══════════════════════════════════════════════════════════════════════════════════''';

final RegExp _securityFindIdentityDeveloperIdentityExtractionPattern =
    new RegExp(r'^\s*\d+\).+"(.+Developer.+)"$');
final RegExp _securityFindIdentityCertificateCnExtractionPattern = new RegExp(r'.*\(([a-zA-Z0-9]+)\)');
final RegExp _certificateOrganizationalUnitExtractionPattern = new RegExp(r'OU=([a-zA-Z0-9]+)');

/// Given a [BuildableIOSApp], this will try to find valid development code
/// signing identities in the user's keychain prompting a choice if multiple
/// are found.
///
/// Will return null if none are found, if the user cancels or if the Xcode
/// project has a development team set in the project's build settings.
Future<String> getCodeSigningIdentityDevelopmentTeam(BuildableIOSApp iosApp) async{
  if (iosApp.buildSettings == null)
    return null;

  // If the user already has it set in the project build settings itself,
  // continue with that.
  if (isNotEmpty(iosApp.buildSettings['DEVELOPMENT_TEAM'])) {
    printStatus(
      'Automatically signing iOS for device deployment using specified development '
      'team in Xcode project: ${iosApp.buildSettings['DEVELOPMENT_TEAM']}'
    );
    return null;
  }

  if (isNotEmpty(iosApp.buildSettings['PROVISIONING_PROFILE']))
    return null;

  // If the user's environment is missing the tools needed to find and read
  // certificates, abandon. Tools should be pre-equipped on macOS.
  if (!exitsHappy(const <String>['which', 'security']) || !exitsHappy(const <String>['which', 'openssl']))
    return null;

  final List<String> findIdentityCommand =
      const <String>['security', 'find-identity', '-p', 'codesigning', '-v'];
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

  final String signingIdentity = await _chooseSigningIdentity(validCodeSigningIdentities);

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
  opensslProcess.stdin
      ..write(signingCertificate)
      ..close();

  final String opensslOutput = await UTF8.decodeStream(opensslProcess.stdout);
  opensslProcess.stderr.drain<String>();

  if (await opensslProcess.exitCode != 0) {
    return null;
  }

  return _certificateOrganizationalUnitExtractionPattern
      .firstMatch(opensslOutput)
      ?.group(1);
}

Future<String> _chooseSigningIdentity(List<String> validCodeSigningIdentities) async {
  // The user has no valid code signing identities.
  if (validCodeSigningIdentities.isEmpty) {
    printError(noCertificatesInstruction, emphasis: true);
    throwToolExit('No development certificates available to code sign app for device deployment');
  }

  if (validCodeSigningIdentities.length == 1)
    return validCodeSigningIdentities.first;

  if (validCodeSigningIdentities.length > 1) {
    final int count = validCodeSigningIdentities.length;
    printStatus(
      'Multiple valid development certificates available:',
      emphasis: true,
    );
    for (int i=0; i<count; i++) {
      printStatus('  ${i+1}) ${validCodeSigningIdentities[i]}', emphasis: true);
    }
    printStatus('  a) Abort', emphasis: true);

    final String choice = await terminal.promptForCharInput(
      range(1, count + 1).map((num number) => '$number').toList()
          ..add('a'),
      prompt: 'Please select a certificate for code signing',
      displayAcceptedCharacters: true,
    );

    if (choice == 'a')
      throwToolExit('Aborted. Code signing is required to build a deployable iOS app.');
    else
      return validCodeSigningIdentities[int.parse(choice) - 1];
  }

  return null;
}
