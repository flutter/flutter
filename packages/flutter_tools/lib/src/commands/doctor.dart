// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/android/android_studio_validator.dart';
import 'package:flutter_tools/src/android/android_workflow.dart';
import 'package:flutter_tools/src/ios/ios_workflow.dart';
import 'package:flutter_tools/src/macos/cocoapods_validator.dart';
import 'package:flutter_tools/src/macos/xcode_validator.dart';
import 'package:flutter_tools/src/proxy_validator.dart';
import 'package:flutter_tools/src/vscode/vscode_validator.dart';
import 'package:flutter_tools/src/web/web_validator.dart';
import 'package:flutter_tools/src/windows/visual_studio_validator.dart';

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

  Map<Type, ValidationResult> _validations;

  @override
  Future<Map<String, String>> get usageValues async {
    assert(_validations != null);
    return _validations
      .map<String, String>((Type validationType, ValidationResult result) {
        String dimension = '';
        switch (validationType) {
          case DeviceValidator:
            dimension = kCommandDoctorDeviceValidator;
            break;
          case IntelliJValidator:
            dimension = kCommandDoctorIntelliJValidator;
            break;
          case NoIdeValidator:
            dimension = kCommandDoctorNoIdeValidator;
            break;
          case FlutterValidator:
            dimension = kCommandDoctorFlutterValidator;
            break;
          case AndroidValidator:
          case AndroidHostPlatformValidator:
          case AndroidLicenseValidator:
            dimension = kCommandDoctorAndroidHostPlatformValidator;
            break;
          case XcodeValidator:
          case IosHostPlatformValidator:
          case CocoaPodsValidator:
            dimension = kCommandDoctorIosHostPlatformValidator;
            break;
          case IOSValidator:
            dimension = kCommandDoctorIOSValidator;
            break;
          case VisualStudioValidator:
            dimension = kCommandDoctorVisualStudioValidator;
            break;
          case WebValidator:
            dimension = kCommandDoctorWebValidator;
            break;
          case AndroidStudioValidator:
            dimension = kCommandDoctorAndroidStudioValidator;
            break;
          case NoAndroidStudioValidator:
            dimension = kCommandDoctorNoAndroidStudioValidator;
            break;
          case ProxyValidator:
            dimension = kCommandDoctorProxyValidator;
            break;
          case VsCodeValidator:
            dimension = kCommandDoctorVsCodeValidator;
            break;
          default:
            print(validationType);
            break;
        }
        return MapEntry<String, String>(dimension, result.typeStr);
      }
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
