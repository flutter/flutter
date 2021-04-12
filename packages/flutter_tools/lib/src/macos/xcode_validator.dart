// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:meta/meta.dart';

import '../base/user_messages.dart';
import '../doctor_validator.dart';
import 'xcode.dart';

class XcodeValidator extends DoctorValidator {
  XcodeValidator({
    @required Xcode xcode,
    @required UserMessages userMessages,
  }) : _xcode = xcode,
      _userMessages = userMessages,
      super('Xcode - develop for iOS and macOS');

  final Xcode _xcode;
  final UserMessages _userMessages;

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    ValidationType xcodeStatus = ValidationType.missing;
    String xcodeVersionInfo;

    if (_xcode.isInstalled) {
      xcodeStatus = ValidationType.installed;

      messages.add(ValidationMessage(_userMessages.xcodeLocation(_xcode.xcodeSelectPath)));
      messages.add(ValidationMessage(_xcode.versionText));

      if (!_xcode.isInstalledAndMeetsVersionCheck) {
        xcodeStatus = ValidationType.partial;
        messages.add(ValidationMessage.error(_userMessages.xcodeOutdated(
          _xcode.currentVersion.toString(),
          xcodeRecommendedVersion.toString(),
        )));
      } else if (!_xcode.isRecommendedVersionSatisfactory) {
        xcodeStatus = ValidationType.partial;
        messages.add(ValidationMessage.hint(_userMessages.xcodeOutdated(
          _xcode.currentVersion.toString(),
          xcodeRecommendedVersion.toString(),
        )));
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
      if (_xcode.xcodeSelectPath == null || _xcode.xcodeSelectPath.isEmpty) {
        messages.add(ValidationMessage.error(_userMessages.xcodeMissing));
      } else {
        messages.add(ValidationMessage.error(_userMessages.xcodeIncomplete));
      }
    }

    return ValidationResult(xcodeStatus, messages, statusInfo: xcodeVersionInfo);
  }
}
