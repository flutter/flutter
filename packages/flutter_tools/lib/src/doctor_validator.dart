// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart';

import 'base/async_guard.dart';
import 'base/terminal.dart';
import 'globals.dart' as globals;

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

abstract class DoctorValidator {
  DoctorValidator(this.title);

  /// This is displayed in the CLI.
  final String title;

  String get slowWarning => 'This is taking an unexpectedly long time...';

  static const _slowWarningDuration = Duration(seconds: 10);

  /// Duration before the spinner should display [slowWarning].
  Duration get slowWarningDuration => _slowWarningDuration;

  /// Performs validation by invoking [validateImpl].
  ///
  /// Tracks time taken to execute the validation step.
  Future<ValidationResult> validate() async {
    final stopwatch = Stopwatch()..start();
    final ValidationResult result = await validateImpl();
    stopwatch.stop();
    result.executionTime = stopwatch.elapsed;
    return result;
  }

  /// Validation implementation.
  Future<ValidationResult> validateImpl();
}

/// A validator that runs other [DoctorValidator]s and combines their output
/// into a single [ValidationResult]. It uses the title of the first validator
/// passed to the constructor and reports the statusInfo of the first validator
/// that provides one. Other titles and statusInfo strings are discarded.
class GroupedValidator extends DoctorValidator {
  GroupedValidator(this.subValidators) : super(subValidators[0].title);

  final List<DoctorValidator> subValidators;

  var _subResults = <ValidationResult>[];

  /// Sub-validator results.
  ///
  /// To avoid losing information when results are merged, the sub-results are
  /// cached on this field when they are available. The results are in the same
  /// order as the sub-validator list.
  List<ValidationResult> get subResults => _subResults;

  @override
  String get slowWarning => _currentSlowWarning;
  var _currentSlowWarning = 'Initializing...';

  @override
  Future<ValidationResult> validateImpl() async {
    final tasks = <ValidatorTask>[
      for (final DoctorValidator validator in subValidators)
        ValidatorTask(validator, asyncGuard<ValidationResult>(() => validator.validate())),
    ];

    final results = <ValidationResult>[];
    for (final subValidator in tasks) {
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
    final mergedMessages = <ValidationMessage>[];
    String? statusInfo;

    for (final result in results) {
      statusInfo ??= result.statusInfo;
      switch (result.type) {
        case ValidationType.success:
          if (mergedType == ValidationType.missing) {
            mergedType = ValidationType.partial;
          }
        case ValidationType.notAvailable:
        case ValidationType.partial:
          mergedType = ValidationType.partial;
        case ValidationType.crash:
        case ValidationType.missing:
          if (mergedType == ValidationType.success) {
            mergedType = ValidationType.partial;
          }
      }
      mergedMessages.addAll(result.messages);
    }

    return ValidationResult(mergedType, mergedMessages, statusInfo: statusInfo);
  }
}

/// Host UI formatting extensions for [ValidationResult].
extension ValidationResultFormatting on ValidationResult {
  /// Leading box indicator for CLI status display.
  String get leadingBox => switch (type) {
    ValidationType.crash => '[☠]',
    ValidationType.missing => '[✗]',
    ValidationType.success => '[✓]',
    ValidationType.notAvailable || ValidationType.partial => '[!]',
  };

  /// String representation of the status type.
  String get typeStr => switch (type) {
    ValidationType.success => 'installed',
    _ => type.name,
  };

  String get coloredLeadingBox {
    return globals.terminal.color(leadingBox, switch (type) {
      ValidationType.success => TerminalColor.green,
      ValidationType.crash || ValidationType.missing => TerminalColor.red,
      ValidationType.notAvailable || ValidationType.partial => TerminalColor.yellow,
    });
  }
}

/// Host UI formatting extensions for [ValidationMessage].
extension ValidationMessageFormatting on ValidationMessage {
  /// Icon indicator character for CLI display.
  String get indicator => switch (type) {
    ValidationMessageType.error => '✗',
    ValidationMessageType.hint => '!',
    ValidationMessageType.information => '•',
  };

  String get coloredIndicator {
    return globals.terminal.color(indicator, switch (type) {
      ValidationMessageType.error => TerminalColor.red,
      ValidationMessageType.hint => TerminalColor.yellow,
      ValidationMessageType.information => TerminalColor.green,
    });
  }
}

class NoIdeValidator extends DoctorValidator {
  NoIdeValidator() : super('Flutter IDE Support');

  static const List<String> noIdeInstallationInfo = <String>[
    'IntelliJ - https://www.jetbrains.com/idea/',
    'Android Studio - https://developer.android.com/studio/',
    'VS Code - https://code.visualstudio.com/',
  ];

  String get noIdeStatusInfo => 'No supported IDEs installed';

  @override
  Future<ValidationResult> validateImpl() async {
    return ValidationResult(
      // Info hint to user they do not have a supported IDE installed
      ValidationType.notAvailable,
      noIdeInstallationInfo.map((String ideInfo) => ValidationMessage(ideInfo)).toList(),
      statusInfo: noIdeStatusInfo,
    );
  }
}

class ValidatorWithResult extends DoctorValidator {
  ValidatorWithResult(super.title, this.result);

  final ValidationResult result;

  @override
  Future<ValidationResult> validateImpl() async => result;
}
