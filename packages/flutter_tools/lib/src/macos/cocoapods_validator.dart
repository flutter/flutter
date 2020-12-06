// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/context.dart';
import '../base/user_messages.dart';
import '../doctor.dart';
import 'cocoapods.dart';

CocoaPodsValidator get cocoapodsValidator => context.get<CocoaPodsValidator>();

class CocoaPodsValidator extends DoctorValidator {
  CocoaPodsValidator(
    CocoaPods cocoaPods,
    UserMessages userMessages,
  ) : _cocoaPods = cocoaPods,
      _userMessages = userMessages,
      super('CocoaPods subvalidator');

  final CocoaPods _cocoaPods;
  final UserMessages _userMessages;

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];

    final CocoaPodsStatus cocoaPodsStatus = await _cocoaPods
      .evaluateCocoaPodsInstallation;

    ValidationType status = ValidationType.installed;
    if (cocoaPodsStatus == CocoaPodsStatus.recommended) {
      if (await _cocoaPods.isCocoaPodsInitialized) {
        messages.add(ValidationMessage(_userMessages.cocoaPodsVersion(await _cocoaPods.cocoaPodsVersionText)));
      } else {
        status = ValidationType.partial;
        messages.add(ValidationMessage.error(_userMessages.cocoaPodsUninitialized(noCocoaPodsConsequence)));
      }
    } else {
      if (cocoaPodsStatus == CocoaPodsStatus.notInstalled) {
        status = ValidationType.missing;
        messages.add(ValidationMessage.error(
          _userMessages.cocoaPodsMissing(noCocoaPodsConsequence, cocoaPodsInstallInstructions)));

      } else if (cocoaPodsStatus == CocoaPodsStatus.brokenInstall) {
        status = ValidationType.missing;
        messages.add(ValidationMessage.error(
          _userMessages.cocoaPodsBrokenInstall(brokenCocoaPodsConsequence, cocoaPodsInstallInstructions)));

      } else if (cocoaPodsStatus == CocoaPodsStatus.unknownVersion) {
        status = ValidationType.partial;
        messages.add(ValidationMessage.hint(
          _userMessages.cocoaPodsUnknownVersion(unknownCocoaPodsConsequence, cocoaPodsUpgradeInstructions)));
      } else {
        status = ValidationType.partial;
        final String currentVersionText = await _cocoaPods.cocoaPodsVersionText;
        messages.add(ValidationMessage.hint(
          _userMessages.cocoaPodsOutdated(currentVersionText, _cocoaPods.cocoaPodsRecommendedVersion, noCocoaPodsConsequence, cocoaPodsUpgradeInstructions)));
      }
    }

    return ValidationResult(status, messages);
  }
}
