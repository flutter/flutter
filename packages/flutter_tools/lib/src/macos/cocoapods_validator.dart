// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../doctor_validator.dart';
import 'cocoapods.dart';

/// A validator that confirms cocoapods is in a valid state.
///
/// See also:
///   * [CocoaPods], for the interface to the cocoapods command line tool.
class CocoaPodsValidator extends DoctorValidator {
  CocoaPodsValidator(CocoaPods cocoaPods) : _cocoaPods = cocoaPods, super('CocoaPods subvalidator');

  final CocoaPods _cocoaPods;

  String _cocoaPodsBrokenInstall(String consequence, String reinstallInstructions) =>
      'CocoaPods installed but not working.\n'
      '$consequence\n'
      'For re-installation instructions, $reinstallInstructions';

  String _cocoaPodsOutdated(
    String currentVersion,
    String recVersion,
    String consequence,
    String upgradeInstructions,
  ) =>
      'CocoaPods $currentVersion out of date ($recVersion is recommended).\n'
      '$consequence\n'
      'To update CocoaPods, $upgradeInstructions';

  String _cocoaPodsVersion(String version) => 'CocoaPods version $version';

  String _cocoaPodsMissing(String consequence, String installInstructions) =>
      'CocoaPods not installed.\n'
      '$consequence\n'
      'For installation instructions, $installInstructions';

  String _cocoaPodsUnknownVersion(String consequence, String upgradeInstructions) =>
      'Unknown CocoaPods version installed.\n'
      '$consequence\n'
      'To update CocoaPods, $upgradeInstructions';

  @override
  Future<ValidationResult> validateImpl() async {
    final messages = <ValidationMessage>[];

    final CocoaPodsStatus cocoaPodsStatus = await _cocoaPods.evaluateCocoaPodsInstallation;

    ValidationType status = ValidationType.success;
    switch (cocoaPodsStatus) {
      case CocoaPodsStatus.recommended:
        messages.add(
          ValidationMessage(_cocoaPodsVersion((await _cocoaPods.cocoaPodsVersionText).toString())),
        );
      case CocoaPodsStatus.notInstalled:
        status = ValidationType.missing;
        messages.add(
          ValidationMessage.error(
            _cocoaPodsMissing(noCocoaPodsConsequence, cocoaPodsInstallInstructions),
          ),
        );
      case CocoaPodsStatus.brokenInstall:
        status = ValidationType.missing;
        messages.add(
          ValidationMessage.error(
            _cocoaPodsBrokenInstall(brokenCocoaPodsConsequence, cocoaPodsInstallInstructions),
          ),
        );
      case CocoaPodsStatus.unknownVersion:
        status = ValidationType.partial;
        messages.add(
          ValidationMessage.hint(
            _cocoaPodsUnknownVersion(unknownCocoaPodsConsequence, cocoaPodsUpdateInstructions),
          ),
        );
      case CocoaPodsStatus.belowMinimumVersion:
      case CocoaPodsStatus.belowRecommendedVersion:
        status = ValidationType.partial;
        final currentVersionText = (await _cocoaPods.cocoaPodsVersionText).toString();
        messages.add(
          ValidationMessage.hint(
            _cocoaPodsOutdated(
              currentVersionText,
              cocoaPodsRecommendedVersion.toString(),
              noCocoaPodsConsequence,
              cocoaPodsUpdateInstructions,
            ),
          ),
        );
    }
    return ValidationResult(status, messages);
  }
}
