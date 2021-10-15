// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/user_messages.dart';
import '../doctor_validator.dart';
import 'cocoapods.dart';

/// A validator that confirms cocoapods is in a valid state.
///
/// See also:
///   * [CocoaPods], for the interface to the cocoapods command line tool.
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
      messages.add(ValidationMessage(_userMessages.cocoaPodsVersion((await _cocoaPods.cocoaPodsVersionText).toString())));
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
          _userMessages.cocoaPodsUnknownVersion(unknownCocoaPodsConsequence, cocoaPodsInstallInstructions)));
      } else {
        status = ValidationType.partial;
        final String currentVersionText = (await _cocoaPods.cocoaPodsVersionText).toString();
        messages.add(ValidationMessage.hint(
          _userMessages.cocoaPodsOutdated(currentVersionText, cocoaPodsRecommendedVersion.toString(), noCocoaPodsConsequence, cocoaPodsInstallInstructions)));
      }
    }

    return ValidationResult(status, messages);
  }
}
