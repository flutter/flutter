// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/context.dart';
import '../base/user_messages.dart';
import '../doctor.dart';
import 'xcode.dart';

XcodeValidator get xcodeValidator => context.get<XcodeValidator>();

class XcodeValidator extends DoctorValidator {
  const XcodeValidator() : super('Xcode - develop for iOS and macOS');

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    ValidationType xcodeStatus = ValidationType.missing;
    String xcodeVersionInfo;

    if (xcode.isInstalled) {
      xcodeStatus = ValidationType.installed;

      messages.add(ValidationMessage(userMessages.xcodeLocation(xcode.xcodeSelectPath)));

      xcodeVersionInfo = xcode.versionText;
      if (xcodeVersionInfo.contains(',')) {
        xcodeVersionInfo = xcodeVersionInfo.substring(0, xcodeVersionInfo.indexOf(','));
      }
      messages.add(ValidationMessage(xcode.versionText));

      if (!xcode.isInstalledAndMeetsVersionCheck) {
        xcodeStatus = ValidationType.partial;
        messages.add(ValidationMessage.error(
            userMessages.xcodeOutdated(kXcodeRequiredVersionMajor, kXcodeRequiredVersionMinor)
        ));
      }

      if (!xcode.eulaSigned) {
        xcodeStatus = ValidationType.partial;
        messages.add(ValidationMessage.error(userMessages.xcodeEula));
      }
      if (!xcode.isSimctlInstalled) {
        xcodeStatus = ValidationType.partial;
        messages.add(ValidationMessage.error(userMessages.xcodeMissingSimct));
      }

    } else {
      xcodeStatus = ValidationType.missing;
      if (xcode.xcodeSelectPath == null || xcode.xcodeSelectPath.isEmpty) {
        messages.add(ValidationMessage.error(userMessages.xcodeMissing));
      } else {
        messages.add(ValidationMessage.error(userMessages.xcodeIncomplete));
      }
    }

    return ValidationResult(xcodeStatus, messages, statusInfo: xcodeVersionInfo);
  }
}
