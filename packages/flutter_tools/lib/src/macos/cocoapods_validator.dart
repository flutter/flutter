// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/context.dart';
import '../base/user_messages.dart';
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
        messages.add(ValidationMessage(userMessages.cocoaPodsVersion(await cocoaPods.cocoaPodsVersionText)));
      } else {
        status = ValidationType.partial;
        messages.add(ValidationMessage.error(userMessages.cocoaPodsUninitialized(noCocoaPodsConsequence)));
      }
    } else {
      if (cocoaPodsStatus == CocoaPodsStatus.notInstalled) {
        status = ValidationType.missing;
        messages.add(ValidationMessage.error(
            userMessages.cocoaPodsMissing(noCocoaPodsConsequence, cocoaPodsInstallInstructions)));
      } else if (cocoaPodsStatus == CocoaPodsStatus.brokenInstall) {
        status = ValidationType.missing;
        messages.add(ValidationMessage.error(
            userMessages.cocoaPodsBrokenInstall(brokenCocoaPodsConsequence, cocoaPodsInstallInstructions)));

      } else if (cocoaPodsStatus == CocoaPodsStatus.unknownVersion) {
        status = ValidationType.partial;
        messages.add(ValidationMessage.hint(
            userMessages.cocoaPodsUnknownVersion(unknownCocoaPodsConsequence, cocoaPodsUpgradeInstructions)));
      } else {
        status = ValidationType.partial;
        final String currentVersionText = await cocoaPods.cocoaPodsVersionText;
        messages.add(ValidationMessage.hint(
            userMessages.cocoaPodsOutdated(currentVersionText, cocoaPods.cocoaPodsRecommendedVersion, noCocoaPodsConsequence, cocoaPodsUpgradeInstructions)));
      }
    }

    return ValidationResult(status, messages);
  }
}
