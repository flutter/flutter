// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../doctor.dart';
import '../runner/flutter_command.dart';
import '../usage.dart';

class DoctorCommand extends FlutterCommand {
  DoctorCommand({this.verbose = false}) {
    argParser.addFlag('android-licenses',
      defaultsTo: false,
      negatable: false,
      help: 'Run the Android SDK manager tool to accept the SDK\'s licenses.',
    );
    argParser.addOption('check-for-remote-artifacts',
      hide: !verbose,
      help: 'Used to determine if Flutter engine artifacts for all platforms '
            'are available for download.',
      valueHelp: 'engine revision git hash',);
  }

  final bool verbose;

  @override
  final String name = 'doctor';

  @override
  final String description = 'Show information about the installed tooling.';

  List<ValidationResult> _validations;

  @override
  Future<Map<String, String>> get usageValues async {
    assert(_validations != null);
    return Map<String, String>.fromIterable(_validations,
      key: (dynamic v) {
        switch (v.name) {
          case 'device':
            return kCommandDoctorDeviceValidator;
          case 'intelliJ':
            return kCommandDoctorIntelliJValidator;
          case 'noIde':
            return kCommandDoctorNoIdeValidator;
          case 'flutter':
            return kCommandDoctorFlutterValidator;
          case 'androidLicense':
            return kCommandDoctorAndroidLicenseValidator;
          case 'android':
            return kCommandDoctorAndroidValidator;
          case 'xcode':
            return kCommandDoctorXcodeValidator;
          case 'cocoaPods':
            return kCommandDoctorCocoaPodsValidator;
          case 'ios':
            return kCommandDoctorIOSValidator;
          case 'visualStudio':
            return kCommandDoctorVisualStudioValidator;
          case 'web':
            return kCommandDoctorWebValidator;
          case 'androidStudio':
            return kCommandDoctorAndroidStudioValidator;
          case 'noAndroidStudio':
            return kCommandDoctorNoAndroidStudioValidator;
          case 'proxy':
            return kCommandDoctorProxyValidator;
          case 'vsCode':
            return kCommandDoctorVsCodeValidator;
        }
        return '';
      },
      value: (dynamic v) => v.typeStr,
    );
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (argResults.wasParsed('check-for-remote-artifacts')) {
      final String engineRevision = argResults['check-for-remote-artifacts'];
      if (engineRevision.startsWith(RegExp(r'[a-f0-9]{1,40}'))) {
        final bool success = await doctor.checkRemoteArtifacts(engineRevision);
        if (!success) {
          throwToolExit('Artifacts for engine $engineRevision are missing or are '
              'not yet available.', exitCode: 1);
        }
      } else {
        throwToolExit('Remote artifact revision $engineRevision is not a valid '
            'git hash.');
      }
    }
    final DiagnoseResult result = await doctor.diagnose(
      androidLicenses: argResults['android-licenses'],
      verbose: verbose,
    );
    _validations = result.validations;
    return FlutterCommandResult(result.success ? ExitStatus.success : ExitStatus.warning);
  }
}
