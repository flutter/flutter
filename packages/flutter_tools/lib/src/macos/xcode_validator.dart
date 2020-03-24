// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/context.dart';
import '../base/user_messages.dart' as user_messages;
import '../doctor.dart';
import '../globals.dart' as globals;
import 'xcode.dart';

XcodeValidator get xcodeValidator => context.get<XcodeValidator>();

class XcodeValidator extends DoctorValidator {
  const XcodeValidator() : super('Xcode - develop for iOS and macOS');

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    ValidationType xcodeStatus = ValidationType.missing;
    String xcodeVersionInfo;

    if (globals.xcode.isInstalled) {
      xcodeStatus = ValidationType.installed;

      messages.add(ValidationMessage(user_messages.xcodeLocation(globals.xcode.xcodeSelectPath)));

      xcodeVersionInfo = globals.xcode.versionText;
      if (xcodeVersionInfo.contains(',')) {
        xcodeVersionInfo = xcodeVersionInfo.substring(0, xcodeVersionInfo.indexOf(','));
      }
      messages.add(ValidationMessage(globals.xcode.versionText));

      if (!globals.xcode.isInstalledAndMeetsVersionCheck) {
        xcodeStatus = ValidationType.partial;
        messages.add(ValidationMessage.error(
            user_messages.xcodeOutdated(kXcodeRequiredVersionMajor, kXcodeRequiredVersionMinor)
        ));
      }

      if (!globals.xcode.eulaSigned) {
        xcodeStatus = ValidationType.partial;
        messages.add(ValidationMessage.error(user_messages.xcodeEula));
      }
      if (!globals.xcode.isSimctlInstalled) {
        xcodeStatus = ValidationType.partial;
        messages.add(ValidationMessage.error(user_messages.xcodeMissingSimct));
      }

    } else {
      xcodeStatus = ValidationType.missing;
      if (globals.xcode.xcodeSelectPath == null || globals.xcode.xcodeSelectPath.isEmpty) {
        messages.add(ValidationMessage.error(user_messages.xcodeMissing));
      } else {
        messages.add(ValidationMessage.error(user_messages.xcodeIncomplete));
      }
    }

    return ValidationResult(xcodeStatus, messages, statusInfo: xcodeVersionInfo);
  }
}
