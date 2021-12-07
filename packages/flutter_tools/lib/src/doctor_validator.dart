// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'base/async_guard.dart';
import 'base/terminal.dart';
import 'globals_null_migrated.dart' as globals;

class ValidatorTask {
  ValidatorTask(this.validator, this.result);
  final DoctorValidator validator;
  final Future<ValidationResult> result;
}

/// A series of tools and required install steps for a target platform (iOS or Android).
abstract class Workflow {
  const Workflow();

  /// Whether the workflow applies to this platform (as in, should we ever try and use it).
  bool get appliesToHostPlatform;

  /// Are we functional enough to list devices?
  bool get canListDevices;

  /// Could this thing launch *something*? It may still have minor issues.
  bool get canLaunchDevices;

  /// Are we functional enough to list emulators?
  bool get canListEmulators;
}

enum ValidationType {
  crash,
  missing,
  partial,
  notAvailable,
  installed,
}

enum ValidationMessageType {
  error,
  hint,
  information,
}

abstract class DoctorValidator {
  const DoctorValidator(this.title);

  /// This is displayed in the CLI.
  final String title;

  String get slowWarning => 'This is taking an unexpectedly long time...';

  Future<ValidationResult> validate();
}

/// A validator that runs other [DoctorValidator]s and combines their output
/// into a single [ValidationResult]. It uses the title of the first validator
/// passed to the constructor and reports the statusInfo of the first validator
/// that provides one. Other titles and statusInfo strings are discarded.
class GroupedValidator extends DoctorValidator {
  GroupedValidator(this.subValidators) : super(subValidators[0].title);

  final List<DoctorValidator> subValidators;

  List<ValidationResult> _subResults = <ValidationResult>[];

  /// Sub-validator results.
  ///
  /// To avoid losing information when results are merged, the sub-results are
  /// cached on this field when they are available. The results are in the same
  /// order as the sub-validator list.
  List<ValidationResult> get subResults => _subResults;

  @override
  String get slowWarning => _currentSlowWarning;
  String _currentSlowWarning = 'Initializing...';

  @override
  Future<ValidationResult> validate() async {
    final List<ValidatorTask> tasks = <ValidatorTask>[
      for (final DoctorValidator validator in subValidators)
        ValidatorTask(
          validator,
          asyncGuard<ValidationResult>(() => validator.validate()),
        ),
    ];

    final List<ValidationResult> results = <ValidationResult>[];
    for (final ValidatorTask subValidator in tasks) {
      _currentSlowWarning = subValidator.validator.slowWarning;
      try {
        results.add(await subValidator.result);
      } on Exception catch (exception, stackTrace) {
        results.add(ValidationResult.crash(exception, stackTrace));
      }
    }
    _currentSlowWarning = 'Merging results...';
    return _mergeValidationResults(results);
  }

  ValidationResult _mergeValidationResults(List<ValidationResult> results) {
    assert(results.isNotEmpty, 'Validation results should not be empty');
    _subResults = results;
    ValidationType mergedType = results[0].type;
    final List<ValidationMessage> mergedMessages = <ValidationMessage>[];
    String? statusInfo;

    for (final ValidationResult result in results) {
      statusInfo ??= result.statusInfo;
      switch (result.type) {
        case ValidationType.installed:
          if (mergedType == ValidationType.missing) {
            mergedType = ValidationType.partial;
          }
          break;
        case ValidationType.notAvailable:
        case ValidationType.partial:
          mergedType = ValidationType.partial;
          break;
        case ValidationType.crash:
        case ValidationType.missing:
          if (mergedType == ValidationType.installed) {
            mergedType = ValidationType.partial;
          }
          break;
        default:
          throw 'Unrecognized validation type: ${result.type}';
      }
      mergedMessages.addAll(result.messages);
    }

    return ValidationResult(mergedType, mergedMessages,
        statusInfo: statusInfo);
  }
}

@immutable
class ValidationResult {
  /// [ValidationResult.type] should only equal [ValidationResult.installed]
  /// if no [messages] are hints or errors.
  const ValidationResult(this.type, this.messages, { this.statusInfo });

  factory ValidationResult.crash(Object error, [StackTrace? stackTrace]) {
    return ValidationResult(ValidationType.crash, <ValidationMessage>[
      const ValidationMessage.error(
          'Due to an error, the doctor check did not complete. '
          'If the error message below is not helpful, '
          'please let us know about this issue at https://github.com/flutter/flutter/issues.'),
      ValidationMessage.error('$error'),
      if (stackTrace != null)
          // Stacktrace is informational. Printed in verbose mode only.
          ValidationMessage('$stackTrace'),
    ], statusInfo: 'the doctor check crashed');
  }

  final ValidationType type;
  // A short message about the status.
  final String? statusInfo;
  final List<ValidationMessage> messages;

  String get leadingBox {
    assert(type != null);
    switch (type) {
      case ValidationType.crash:
        return '[☠]';
      case ValidationType.missing:
        return '[✗]';
      case ValidationType.installed:
        return '[✓]';
      case ValidationType.notAvailable:
      case ValidationType.partial:
        return '[!]';
    }
  }

  String get coloredLeadingBox {
    assert(type != null);
    switch (type) {
      case ValidationType.crash:
        return globals.terminal.color(leadingBox, TerminalColor.red);
      case ValidationType.missing:
        return globals.terminal.color(leadingBox, TerminalColor.red);
      case ValidationType.installed:
        return globals.terminal.color(leadingBox, TerminalColor.green);
      case ValidationType.notAvailable:
      case ValidationType.partial:
        return globals.terminal.color(leadingBox, TerminalColor.yellow);
    }
  }

  /// The string representation of the type.
  String get typeStr {
    assert(type != null);
    switch (type) {
      case ValidationType.crash:
        return 'crash';
      case ValidationType.missing:
        return 'missing';
      case ValidationType.installed:
        return 'installed';
      case ValidationType.notAvailable:
        return 'notAvailable';
      case ValidationType.partial:
        return 'partial';
    }
  }
}

/// A status line for the flutter doctor validation to display.
///
/// The [message] is required and represents either an informational statement
/// about the particular doctor validation that passed, or more context
/// on the cause and/or solution to the validation failure.
@immutable
class ValidationMessage {
  /// Create a validation message with information for a passing validator.
  ///
  /// By default this is not displayed unless the doctor is run in
  /// verbose mode.
  ///
  /// The [contextUrl] may be supplied to link to external resources. This
  /// is displayed after the informative message in verbose modes.
  const ValidationMessage(this.message, {this.contextUrl}) : type = ValidationMessageType.information;

  /// Create a validation message with information for a failing validator.
  const ValidationMessage.error(this.message)
    : type = ValidationMessageType.error,
      contextUrl = null;

  /// Create a validation message with information for a partially failing
  /// validator.
  const ValidationMessage.hint(this.message)
    : type = ValidationMessageType.hint,
      contextUrl = null;

  final ValidationMessageType type;
  final String? contextUrl;
  final String message;

  bool get isError => type == ValidationMessageType.error;

  bool get isHint => type == ValidationMessageType.hint;

  String get indicator {
    switch (type) {
      case ValidationMessageType.error:
        return '✗';
      case ValidationMessageType.hint:
        return '!';
      case ValidationMessageType.information:
        return '•';
    }
  }

  String get coloredIndicator {
    switch (type) {
      case ValidationMessageType.error:
        return globals.terminal.color(indicator, TerminalColor.red);
      case ValidationMessageType.hint:
        return globals.terminal.color(indicator, TerminalColor.yellow);
      case ValidationMessageType.information:
        return globals.terminal.color(indicator, TerminalColor.green);
    }
  }

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) {
    return other is ValidationMessage
        && other.message == message
        && other.type == type
        && other.contextUrl == contextUrl;
  }

  @override
  int get hashCode => Object.hash(type, message, contextUrl);
}

class NoIdeValidator extends DoctorValidator {
  NoIdeValidator() : super('Flutter IDE Support');

  @override
  Future<ValidationResult> validate() async {
    return ValidationResult(
      ValidationType.missing,
      globals.userMessages.noIdeInstallationInfo.map((String ideInfo) => ValidationMessage(ideInfo)).toList(),
      statusInfo: globals.userMessages.noIdeStatusInfo,
    );
  }
}

class ValidatorWithResult extends DoctorValidator {
  ValidatorWithResult(String title, this.result) : super(title);

  final ValidationResult result;

  @override
  Future<ValidationResult> validate() async => result;
}
