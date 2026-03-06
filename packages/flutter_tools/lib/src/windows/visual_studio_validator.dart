// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/context.dart';
import '../doctor_validator.dart';
import 'visual_studio.dart';

VisualStudioValidator? get visualStudioValidator => context.get<VisualStudioValidator>();

class VisualStudioValidator extends DoctorValidator {
  VisualStudioValidator({required VisualStudio visualStudio})
    : _visualStudio = visualStudio,
      super('Visual Studio - develop Windows apps');

  final VisualStudio _visualStudio;

  String get _visualStudioNotLaunchable =>
      'The current Visual Studio installation is not launchable. Please reinstall Visual Studio.';

  String get _visualStudioIsIncomplete =>
      'The current Visual Studio installation is incomplete.\n'
      'Please use Visual Studio Installer to complete the installation or reinstall Visual Studio.';

  String get _visualStudioRebootRequired =>
      'Visual Studio requires a reboot of your system to complete installation.';

  String get _visualStudioIsPrerelease =>
      'The current Visual Studio installation is a pre-release version. It may not be '
      'supported by Flutter yet.';

  String _visualStudioTooOld(String minimumVersion, String workload) =>
      'Visual Studio $minimumVersion or later is required.\n'
      'Download at https://visualstudio.microsoft.com/downloads/.\n'
      'Please install the "$workload" workload, including all of its default components';

  String _visualStudioMissing(String workload) =>
      'Visual Studio not installed; this is necessary to develop Windows apps.\n'
      'Download at https://visualstudio.microsoft.com/downloads/.\n'
      'Please install the "$workload" workload, including all of its default components';

  String get _windows10SdkNotFound =>
      'Unable to locate a Windows 10 SDK. If building fails, install the Windows 10 SDK in Visual Studio.';

  String _visualStudioVersion(String name, String version) => '$name version $version';
  String _visualStudioLocation(String location) => 'Visual Studio at $location';
  String _windows10SdkVersion(String version) => 'Windows 10 SDK version $version';
  String _visualStudioMissingComponents(String workload, List<String> components) =>
      'Visual Studio is missing necessary components. Please re-run the '
      'Visual Studio installer for the "$workload" workload, and include these components:\n'
      '  ${components.join('\n  ')}\n'
      '  Windows 10 SDK';

  @override
  Future<ValidationResult> validateImpl() async {
    final messages = <ValidationMessage>[];
    ValidationType status = ValidationType.missing;
    String? versionInfo;

    if (_visualStudio.isInstalled) {
      status = ValidationType.success;

      messages.add(
        ValidationMessage(_visualStudioLocation(_visualStudio.installLocation ?? 'unknown')),
      );

      messages.add(
        ValidationMessage(
          _visualStudioVersion(
            _visualStudio.displayName ?? 'unknown',
            _visualStudio.fullVersion ?? 'unknown',
          ),
        ),
      );

      if (_visualStudio.isPrerelease) {
        messages.add(ValidationMessage(_visualStudioIsPrerelease));
      }

      final String? windows10SdkVersion = _visualStudio.getWindows10SDKVersion();
      if (windows10SdkVersion != null) {
        messages.add(ValidationMessage(_windows10SdkVersion(windows10SdkVersion)));
      }

      // Messages for faulty installations.
      if (!_visualStudio.isAtLeastMinimumVersion) {
        status = ValidationType.partial;
        messages.add(
          ValidationMessage.error(
            _visualStudioTooOld(
              _visualStudio.minimumVersionDescription,
              _visualStudio.workloadDescription,
            ),
          ),
        );
      } else if (_visualStudio.isRebootRequired) {
        status = ValidationType.partial;
        messages.add(ValidationMessage.error(_visualStudioRebootRequired));
      } else if (!_visualStudio.isComplete) {
        status = ValidationType.partial;
        messages.add(ValidationMessage.error(_visualStudioIsIncomplete));
      } else if (!_visualStudio.isLaunchable) {
        status = ValidationType.partial;
        messages.add(ValidationMessage.error(_visualStudioNotLaunchable));
      } else if (!_visualStudio.hasNecessaryComponents) {
        status = ValidationType.partial;
        messages.add(
          ValidationMessage.error(
            _visualStudioMissingComponents(
              _visualStudio.workloadDescription,
              _visualStudio.necessaryComponentDescriptions(),
            ),
          ),
        );
      } else if (windows10SdkVersion == null) {
        status = ValidationType.partial;
        messages.add(ValidationMessage.hint(_windows10SdkNotFound));
      }
      versionInfo = '${_visualStudio.displayName} ${_visualStudio.displayVersion}';
    } else {
      status = ValidationType.missing;
      messages.add(
        ValidationMessage.error(_visualStudioMissing(_visualStudio.workloadDescription)),
      );
    }

    return ValidationResult(status, messages, statusInfo: versionInfo);
  }
}
