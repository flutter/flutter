// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/user_messages.dart';
import '../doctor_validator.dart';
import 'xcode.dart';

class XcodeValidator extends DoctorValidator {
  XcodeValidator({
    required Xcode xcode,
    required UserMessages userMessages,
  }) : _xcode = xcode,
      _userMessages = userMessages,
      super('Xcode - develop for iOS and macOS');

  final Xcode _xcode;
  final UserMessages _userMessages;

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    ValidationType xcodeStatus = ValidationType.missing;
    String? xcodeVersionInfo;

    final String? xcodeSelectPath = _xcode.xcodeSelectPath;

    if (_xcode.isInstalled) {
      xcodeStatus = ValidationType.installed;
      if (xcodeSelectPath != null) {
        messages.add(ValidationMessage(_userMessages.xcodeLocation(xcodeSelectPath)));
      }
      final String? versionText = _xcode.versionText;
      if (versionText != null) {
        xcodeVersionInfo = versionText;
        if (xcodeVersionInfo.contains(',')) {
          xcodeVersionInfo = xcodeVersionInfo.substring(0, xcodeVersionInfo.indexOf(','));
        }
      }
      if (_xcode.buildVersion != null) {
        messages.add(ValidationMessage('Build ${_xcode.buildVersion}'));
      }
      if (!_xcode.isInstalledAndMeetsVersionCheck) {
        xcodeStatus = ValidationType.partial;
        messages.add(ValidationMessage.error(_userMessages.xcodeOutdated(xcodeRequiredVersion.toString())));
      } else if (!_xcode.isRecommendedVersionSatisfactory) {
        xcodeStatus = ValidationType.partial;
        messages.add(ValidationMessage.hint(_userMessages.xcodeRecommended(xcodeRecommendedVersion.toString())));
      }

      if (!_xcode.eulaSigned) {
        xcodeStatus = ValidationType.partial;
        messages.add(ValidationMessage.error(_userMessages.xcodeEula));
      }
      if (!_xcode.isSimctlInstalled) {
        xcodeStatus = ValidationType.partial;
        messages.add(ValidationMessage.error(_userMessages.xcodeMissingSimct));
      }

    } else {
      xcodeStatus = ValidationType.missing;
      if (xcodeSelectPath == null || xcodeSelectPath.isEmpty) {
        messages.add(ValidationMessage.error(_userMessages.xcodeMissing));
      } else {
        messages.add(ValidationMessage.error(_userMessages.xcodeIncomplete));
      }
    }

    return ValidationResult(xcodeStatus, messages, statusInfo: xcodeVersionInfo);
  }
}
