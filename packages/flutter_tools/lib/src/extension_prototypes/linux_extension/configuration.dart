// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../../flutter_tools_extension.dart';

/// The configuration service for the Linux prototype extension.
final class LinuxConfigurationService extends ConfigurationService {
  @override
  final List<ConfigurationOption> options = <ConfigurationOption>[const LinuxCustomFeatureOption()];
}

/// The custom experimental feature option.
final class LinuxCustomFeatureOption extends ConfigurationOption {
  /// Create a new instance of [LinuxCustomFeatureOption].
  const LinuxCustomFeatureOption();

  @override
  String get name => 'enable-custom-linux-feature';

  @override
  String get description =>
      'Enables a custom experimental feature for the Linux prototype extension.';

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
