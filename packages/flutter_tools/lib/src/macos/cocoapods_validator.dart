// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/context.dart';
import '../base/user_messages.dart' as user_messages;
import '../doctor.dart';
import 'cocoapods.dart';

CocoaPodsValidator get cocoapodsValidator => context.get<CocoaPodsValidator>();

class CocoaPodsValidator extends DoctorValidator {
  const CocoaPodsValidator() : super('CocoaPods subvalidator');

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];

    final CocoaPodsStatus cocoaPodsStatus = await cocoaPods
        .evaluateCocoaPodsInstallation;

    ValidationType status = ValidationType.installed;
    if (cocoaPodsStatus == CocoaPodsStatus.recommended) {
      if (await cocoaPods.isCocoaPodsInitialized) {
        messages.add(ValidationMessage(user_messages.cocoaPodsVersion(await cocoaPods.cocoaPodsVersionText)));
      } else {
        status = ValidationType.partial;
        messages.add(ValidationMessage.error(user_messages.cocoaPodsUninitialized(noCocoaPodsConsequence)));
      }
    } else {
      if (cocoaPodsStatus == CocoaPodsStatus.notInstalled) {
        status = ValidationType.missing;
        messages.add(ValidationMessage.error(
          user_messages.cocoaPodsMissing(noCocoaPodsConsequence, cocoaPodsInstallInstructions)));
      } else if (cocoaPodsStatus == CocoaPodsStatus.brokenInstall) {
        status = ValidationType.missing;
        messages.add(ValidationMessage.error(
          user_messages.cocoaPodsBrokenInstall(brokenCocoaPodsConsequence, cocoaPodsInstallInstructions)));

      } else if (cocoaPodsStatus == CocoaPodsStatus.unknownVersion) {
        status = ValidationType.partial;
        messages.add(ValidationMessage.hint(
          user_messages.cocoaPodsUnknownVersion(unknownCocoaPodsConsequence, cocoaPodsUpgradeInstructions)));
      } else {
        status = ValidationType.partial;
        final String currentVersionText = await cocoaPods.cocoaPodsVersionText;
        messages.add(ValidationMessage.hint(
          user_messages.cocoaPodsOutdated(currentVersionText, cocoaPods.cocoaPodsRecommendedVersion, noCocoaPodsConsequence, cocoaPodsUpgradeInstructions)));
      }
    }

    return ValidationResult(status, messages);
  }
}
