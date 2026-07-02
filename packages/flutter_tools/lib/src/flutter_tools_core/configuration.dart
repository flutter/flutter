// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../generic_extension_protocol.dart';

/// The service responsible for managing custom configuration options for
/// an extension.
abstract base class ConfigurationService extends ToolExtensionService {
  @override
  String get namespace => 'config';

  /// The set of configuration options handled by this extension.
  List<ConfigurationOption> get options;
}

/// The definition of a single option provided by the [ConfigurationService].
abstract base class ConfigurationOption {
  /// The name of the option.
  String get name;

  /// The description of the option.
  String get description;

  /// Checks if [value] is valid for [option].
  OptionValidationResult validate(String option, Object? value);
}

/// Result type that indicates whether or not a value is valid for an option.
final class OptionValidationResult {
  /// Create a successful validation result.
  OptionValidationResult.success() : success = true, failureReason = null;

  /// Create a failed validation result with a reason.
  OptionValidationResult.failed(this.failureReason) : success = false;

  /// Whether validation was successful.
  final bool success;

  /// The reason why validation failed, if applicable.
  final String? failureReason;
}
