// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/context.dart';
import '../base/user_messages.dart';
import '../doctor.dart';
import 'visual_studio.dart';

VisualStudioValidator get visualStudioValidator => context.get<VisualStudioValidator>();

class VisualStudioValidator extends DoctorValidator {
  const VisualStudioValidator() : super('Visual Studio - develop for Windows');

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    ValidationType status = ValidationType.missing;
    String versionInfo;

    if (visualStudio.isInstalled) {
      status = ValidationType.installed;

      messages.add(ValidationMessage(
          userMessages.visualStudioLocation(visualStudio.installLocation)
      ));

      messages.add(ValidationMessage(userMessages.visualStudioVersion(
          visualStudio.displayName,
          visualStudio.fullVersion,
      )));

      if (visualStudio.isPrerelease) {
        messages.add(ValidationMessage(userMessages.visualStudioIsPrerelease));
      }

      // Messages for faulty installations.
      if (visualStudio.isRebootRequired) {
        status = ValidationType.partial;
        messages.add(ValidationMessage.error(userMessages.visualStudioRebootRequired));
      } else if (!visualStudio.isComplete) {
        status = ValidationType.partial;
        messages.add(ValidationMessage.error(userMessages.visualStudioIsIncomplete));
      } else if (!visualStudio.isLaunchable) {
        status = ValidationType.partial;
        messages.add(ValidationMessage.error(userMessages.visualStudioNotLaunchable));
      } else  if (!visualStudio.hasNecessaryComponents) {
        status = ValidationType.partial;
        final int majorVersion = int.tryParse(visualStudio.fullVersion.split('.')[0]);
        messages.add(ValidationMessage.error(
            userMessages.visualStudioMissingComponents(
                visualStudio.workloadDescription,
                visualStudio.necessaryComponentDescriptions(majorVersion)
            )
        ));
      }
      versionInfo = '${visualStudio.displayName} ${visualStudio.displayVersion}';
    } else {
      status = ValidationType.missing;
      messages.add(ValidationMessage.error(userMessages.visualStudioMissing));
    }

    return ValidationResult(status, messages, statusInfo: versionInfo);
  }
}
