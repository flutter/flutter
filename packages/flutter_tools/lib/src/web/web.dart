// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tool_api/doctor.dart';
import 'package:flutter_tool_api/extension.dart';

import 'chrome.dart';

class WebExtension extends ToolExtension {
  @override
  String get name => 'Flutter Web';

  @override
  final WebDoctorDomain doctorDomain = WebDoctorDomain();
}

class WebDoctorDomain extends DoctorDomain {
  static const String kValidatorName = 'Flutter Web - develop for the web';

  @override
  Future<ValidationResult> diagnose(Map<String, Object> arguments) async {
    final String chrome = _findChromeExecutable();
    bool canRunChrome;
    try {
      canRunChrome = processManager.canRun(chrome);
    } on ArgumentError {
      canRunChrome = false;
    }
    final List<ValidationMessage> messages = <ValidationMessage>[];
    if (platform.environment.containsKey(kChromeEnvironment)) {
      if (!canRunChrome) {
        messages.add(ValidationMessage(
          '$chrome is not executable.',
          type: ValidationMessageType.hint,
        ));
      } else {
        messages.add(ValidationMessage('$kChromeEnvironment = $chrome'));
      }
    } else {
      if (!canRunChrome) {
        messages.add(const ValidationMessage(
          '$kChromeEnvironment not set',
          type: ValidationMessageType.hint,
        ));
      } else {
        messages.add(ValidationMessage('Chrome at $chrome'));
      }
    }
    if (!canRunChrome) {
      return ValidationResult(
        messages: messages,
        type: ValidationType.missing,
        statusText: 'Cannot find chrome executable at $chrome',
        name: kValidatorName,
      );
    }
    return ValidationResult(
      messages: messages,
      type: ValidationType.installed,
      name: kValidatorName
    );
  }

  // TODO(jonahwilliams): unfork this method.
  String _findChromeExecutable() {
    if (platform.environment.containsKey(kChromeEnvironment)) {
      return platform.environment[kChromeEnvironment];
    }
    if (platform.isLinux) {
      return kLinuxExecutable;
    }
    if (platform.isMacOS) {
      return kMacOSExecutable;
    }
    if (platform.isWindows) {
      final String windowsPrefix = kWindowsPrefixes.firstWhere((String prefix) {
        if (prefix == null) {
          return false;
        }
        final String path = fileSystem.path.join(prefix, kWindowsExecutable);
        return fileSystem.file(path).existsSync();
      }, orElse: () => '.');
      return fileSystem.path.join(windowsPrefix, kWindowsExecutable);
    }
    throw Exception('Platform ${platform.operatingSystem} is not supported.');
  }
}
