// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/context.dart';
import '../base/user_messages.dart' as user_messages;
import '../doctor.dart';
import 'visual_studio.dart';

VisualStudioValidator get visualStudioValidator => context.get<VisualStudioValidator>();

class VisualStudioValidator extends DoctorValidator {
  const VisualStudioValidator({
    @required VisualStudio visualStudio,
  }) : _visualStudio = visualStudio,
       super('Visual Studio - develop for Windows');

  final VisualStudio _visualStudio;

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    ValidationType status = ValidationType.missing;
    String versionInfo;

    if (_visualStudio.isInstalled) {
      status = ValidationType.installed;

      messages.add(ValidationMessage(
          user_messages.visualStudioLocation(_visualStudio.installLocation)
      ));

      messages.add(ValidationMessage(user_messages.visualStudioVersion(
          _visualStudio.displayName,
          _visualStudio.fullVersion,
      )));

      if (_visualStudio.isPrerelease) {
        messages.add(ValidationMessage(user_messages.visualStudioIsPrerelease));
      }

      // Messages for faulty installations.
      if (!_visualStudio.isAtLeastMinimumVersion) {
        status = ValidationType.partial;
        messages.add(ValidationMessage.error(
            user_messages.visualStudioTooOld(
                _visualStudio.minimumVersionDescription,
                _visualStudio.workloadDescription,
                _visualStudio.necessaryComponentDescriptions(),
            ),
        ));
      } else if (_visualStudio.isRebootRequired) {
        status = ValidationType.partial;
        messages.add(ValidationMessage.error(user_messages.visualStudioRebootRequired));
      } else if (!_visualStudio.isComplete) {
        status = ValidationType.partial;
        messages.add(ValidationMessage.error(user_messages.visualStudioIsIncomplete));
      } else if (!_visualStudio.isLaunchable) {
        status = ValidationType.partial;
        messages.add(ValidationMessage.error(user_messages.visualStudioNotLaunchable));
      } else if (!_visualStudio.hasNecessaryComponents) {
        status = ValidationType.partial;
        messages.add(ValidationMessage.error(
            user_messages.visualStudioMissingComponents(
                _visualStudio.workloadDescription,
                _visualStudio.necessaryComponentDescriptions(),
            ),
        ));
      }
      versionInfo = '${_visualStudio.displayName} ${_visualStudio.displayVersion}';
    } else {
      status = ValidationType.missing;
      messages.add(ValidationMessage.error(
        user_messages.visualStudioMissing(
          _visualStudio.workloadDescription,
          _visualStudio.necessaryComponentDescriptions(),
        ),
      ));
    }

    return ValidationResult(status, messages, statusInfo: versionInfo);
  }
}
