// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Linux prototype extension configuration service.
///
/// This library implements the configuration service for the Linux platform
/// prototype extension, defining custom configuration options.
library linux_extension.configuration;

import '../../../flutter_tools_extension.dart';

/// The configuration service for the Linux prototype extension.
///
/// This service exposes configuration options specific to the Linux extension,
/// such as [LinuxCustomFeatureOption].
final class LinuxConfigurationService extends ConfigurationService {
  @override
  final List<ConfigurationOption> options = <ConfigurationOption>[const LinuxCustomFeatureOption()];
}

/// The custom experimental feature option for the Linux extension.
///
/// This option is exposed as a command-line flag (`--enable-custom-linux-feature`)
/// when the tool extension prototype is enabled.
final class LinuxCustomFeatureOption extends ConfigurationOption {
  const LinuxCustomFeatureOption();

  @override
  String get name => 'enable-custom-linux-feature';

  @override
  String get description =>
      'Enables a custom experimental feature for the Linux prototype extension.';

  /// Validates that the value passed to the option is a boolean.
  @override
  OptionValidationResult validate(String option, Object? value) {
    if (value is! bool) {
      return OptionValidationResult.failed(
        'Value for option "$option" must be a boolean (true/false), but got: $value',
      );
    }
    return OptionValidationResult.success();
  }
}
