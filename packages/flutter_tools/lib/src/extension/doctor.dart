// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Tool extensions for interfacing with flutter doctor.
library doctor;

import 'package:meta/meta.dart';

import 'extension.dart';

/// How does the environment match the validation requirements.
class ValidationType implements Serializable {
  const ValidationType._(this._value);

  /// Create a [ValidationType] object from its json encoded equivalent.
  ///
  /// Throws an [ArgumentError] if an invalid value is provided.
  factory ValidationType.fromJson(int value) {
    switch (value) {
      case 0:
        return missing;
      case 1:
        return partial;
      case 2:
        return notAvailable;
      case 3:
        return installed;
    }
    throw ArgumentError.value(value);
  }

  /// Requirements are not met or are otherwise missing.
  static const ValidationType missing = ValidationType._(0);

  /// Some requirements are met.
  static const ValidationType partial = ValidationType._(1);

  /// Some requirements are met.
  // TODO(jonahwilliams): deprecate this enum.
  static const ValidationType notAvailable = ValidationType._(2);

  /// All requirements are met.
  static const ValidationType installed = ValidationType._(3);

  final int _value;

  @override
  Object toJson() => _value;
}

/// The kind of validation message to be shown in the doctor UI.
class ValidationMessageType implements Serializable {
  const ValidationMessageType._(this._value);

  /// Create a [ValidationMessageType] from its json encoded equivalent.
  factory ValidationMessageType.fromJson(int value) {
    switch (value) {
      case 0:
        return error;
      case 1:
        return hint;
      case 2:
        return information;
    }
    throw ArgumentError.value(value);
  }

  /// Something is wrong with this validator.
  static const ValidationMessageType error = ValidationMessageType._(0);

  /// Nothing is broken, but something might not be right.
  static const ValidationMessageType hint = ValidationMessageType._(1);

  /// Nothing is broken, purely informative.
  static const ValidationMessageType information = ValidationMessageType._(2);

  final int _value;

  @override
  Object toJson() => _value;
}

/// An individual validation message from a doctor diagnose.
class ValidationMessage implements Serializable {
  /// Create a new [ValidationMessage].
  ///
  /// [message] and [type] must not be null.
  /// [type] defaults to [ValidationMessage.information] if not provided.
  const ValidationMessage(this.message, { this.type = ValidationMessageType.information })
    : assert(message != null),
      assert(type != null);

  /// Create a new [ValidationMessage] from a json object.
  factory ValidationMessage.fromJson(Map<String, Object> json) {
    final String message = json['message'];
    final ValidationMessageType type = ValidationMessageType.fromJson(json['type']);
    return ValidationMessage(message, type: type);
  }

  /// The type of validation message.
  ///
  /// If not provided, defaults to [ValidationTypeMessage.information].
  final ValidationMessageType type;

  /// The human-readable message.
  ///
  /// If the provided [type] is [ValidationTypeMessage.error] or
  /// [ValidationTypeMessage.hint] the message should contain actionable
  /// advice to the user to remedy the situation.
  final String message;

  @override
  bool operator ==(Object other) => other is ValidationMessage
      && other.type == type
      && other.message == message;

  @override
  int get hashCode => type.hashCode ^ message.hashCode;

  @override
  Map<String, Object> toJson() {
    return <String, Object>{
      'message': message,
      'type': type.toJson(),
    };
  }
}

/// An expected response from [DoctorDomain.diagnose].
class ValidationResult implements Serializable {
  /// Create a new [ValidationResponse].
  ///
  /// [messages], [type], and [name] must not be null.
  /// If [messages] is not provided, it defaults to an empty list.
  /// if [type] is not provided, it defaults to [ValidationType.installed].
  const ValidationResult({
    this.messages = const <ValidationMessage>[],
    this.type = ValidationType.installed,
    this.statusText,
    this.appliesToPlatform = true,
    @required this.name,
  }) : assert(name != null),
       assert(type != null),
       assert(messages != null);

  /// Create a new [ValidationResponse] from a json encoded object.
  factory ValidationResult.fromJson(Map<String, Object> json) {
    final String name = json['name'];
    final List<ValidationMessage> messages = <ValidationMessage>[
      for (Object value in json['messages'])
        ValidationMessage.fromJson(value)
    ];
    final ValidationType type = ValidationType.fromJson(json['type']);
    final String statusText = json['statusText'];
    return ValidationResult(
      name: name,
      messages: messages,
      type: type,
      statusText: statusText,
    );
  }

  /// The messages associated with this doctor diagnose.
  ///
  /// If not explicitly provided in the constructor this defaults to an empty
  /// list. This is equivalent to claiming that there is nothing to diagnose in
  /// the current environment.
  final List<ValidationMessage> messages;

  /// The overal validation summary.
  ///
  /// If not explicitly provided in the constructor this defaults tp
  /// [ValidationType.installed]. This is eqivalent to claiming that there
  /// is nothing wrong with the current environment.
  ///
  /// If there are no associated [messages] this instead means that there are
  /// no applicable checks.
  final ValidationType type;

  /// The human readable name of the validator.
  ///
  /// Some interfaces, including the command line , will display the human
  /// readable name next to the doctor results.
  ///
  /// Example: 'Android Studio', for validation of Android Studio installation.
  final String name;

  /// An optional high level summary.
  ///
  /// This should generally only be provided if a validation message came back
  /// negative.
  final String statusText;

  /// Whether this check applies to the current platform or project.
  ///
  /// Defaults to true. If false, the remaining fields are ignored and this
  /// message is discarded. For example, a validator for Xcode might set
  /// `appliesToPlatform: false` on a Windows platform.
  final bool appliesToPlatform;

  @override
  Map<String, Object> toJson() {
    return <String, Object>{
      'messages': <Object>[
        for (ValidationMessage message in messages)
          message.toJson()
      ],
      'type': type.toJson(),
      'name': name,
      'statusText': statusText,
    };
  }
}

/// Functionality related to diagnosing problems with an environment.
abstract class DoctorDomain extends Domain {

  /// Diagnose problems with the user's environment.
  Future<ValidationResult> diagnose();
}
