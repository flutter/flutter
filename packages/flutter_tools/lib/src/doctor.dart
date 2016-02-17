// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'android/android_workflow.dart';
import 'base/context.dart';
import 'globals.dart';
import 'ios/ios_workflow.dart';

class Doctor {
  Doctor() {
    _iosWorkflow = new IOSWorkflow();
    if (_iosWorkflow.appliesToHostPlatform)
      _workflows.add(_iosWorkflow);

    _androidWorkflow = new AndroidWorkflow();
    if (_androidWorkflow.appliesToHostPlatform)
      _workflows.add(_androidWorkflow);
  }

  static void initGlobal() {
    context[Doctor] = new Doctor();
  }

  IOSWorkflow _iosWorkflow;
  AndroidWorkflow _androidWorkflow;

  /// This can return null for platforms that don't support developing for iOS.
  IOSWorkflow get iosWorkflow => _iosWorkflow;

  AndroidWorkflow get androidWorkflow => _androidWorkflow;

  List<Workflow> _workflows = <Workflow>[];

  List<Workflow> get workflows => _workflows;

  /// Print a summary of the state of the tooling, as well as how to get more info.
  void summary() => printStatus(summaryText);

  String get summaryText {
    StringBuffer buffer = new StringBuffer();

    bool allGood = true;

    for (Workflow workflow in workflows) {
      ValidationResult result = workflow.validate();
      buffer.write('${result.leadingBox} The ${workflow.name} toolchain is ');
      if (result.type == ValidationType.missing)
        buffer.writeln('not installed.');
      else if (result.type == ValidationType.partial)
        buffer.writeln('partially installed; more components are available.');
      else
        buffer.writeln('fully installed.');
      if (result.type != ValidationType.installed)
        allGood = false;
    }

    if (!allGood) {
      buffer.writeln();
      buffer.write('Run "flutter doctor" for information about installing additional components.');
    }

    return buffer.toString();
  }

  /// Print verbose information about the state of installed tooling.
  void diagnose() {
    for (int i = 0; i < workflows.length; i++) {
      if (i > 0)
        printStatus('');
      workflows[i].diagnose();
    }
  }

  bool get canListAnything => workflows.any((Workflow workflow) => workflow.canListDevices);

  bool get canLaunchAnything => workflows.any((Workflow workflow) => workflow.canLaunchDevices);
}

/// A series of tools and required install steps for a target platform (iOS or Android).
abstract class Workflow {
  Workflow(this.name);

  final String name;

  /// Whether the workflow applies to this platform (as in, should we ever try and use it).
  bool get appliesToHostPlatform;

  /// Are we functional enough to list devices?
  bool get canListDevices;

  /// Could this thing launch *something*? It may still have minor issues.
  bool get canLaunchDevices;

  ValidationResult validate();

  /// Print verbose information about the state of the workflow.
  void diagnose();

  String toString() => name;
}

enum ValidationType {
  missing,
  partial,
  installed
}

typedef ValidationType ValidationFunction();

class Validator {
  Validator(this.name, { this.description, this.resolution, this.validatorFunction });

  final String name;
  final String description;
  final String resolution;
  final ValidationFunction validatorFunction;

  List<Validator> _children = <Validator>[];

  ValidationResult validate() {
    List<ValidationResult> childResults;
    ValidationType type;

    if (validatorFunction != null)
      type = validatorFunction();

    childResults = _children.map((Validator child) => child.validate()).toList();

    // If there's no immediate validator, the result we return is synthesized
    // from the sub-tree of children. This is so we can show that the branch is
    // not fully installed.
    if (type == null) {
      type = _combine(childResults
        .expand((ValidationResult child) => child._allResults)
        .map((ValidationResult result) => result.type)
      );
    }

    return new ValidationResult(type, this, childResults);
  }

  ValidationType _combine(Iterable<ValidationType> types) {
    if (types.contains(ValidationType.missing) && types.contains(ValidationType.installed))
      return ValidationType.partial;
    if (types.contains(ValidationType.missing))
      return ValidationType.missing;
    return ValidationType.installed;
  }

  void addValidator(Validator validator) => _children.add(validator);
}

class ValidationResult {
  ValidationResult(this.type, this.validator, [this.childResults = const <ValidationResult>[]]);

  final ValidationType type;
  final Validator validator;
  final List<ValidationResult> childResults;

  String get leadingBox {
    if (type == ValidationType.missing)
      return '[ ]';
    else if (type == ValidationType.installed)
      return '[✓]';
    else
      return '[-]';
  }

  void print([String indent = '']) {
    printSelf(indent);

    for (ValidationResult child in childResults)
      child.print(indent + '  ');
  }

  void printSelf([String indent = '']) {
    String result = indent;

    if (type == ValidationType.missing)
      result += '$leadingBox ';
    else if (type == ValidationType.installed)
      result += '$leadingBox ';
    else
      result += '$leadingBox ';

    result += '${validator.name} ';

    if (validator.description != null)
      result += '- ${validator.description} ';

    if (type == ValidationType.missing)
      result += '(missing)';
    else if (type == ValidationType.installed)
      result += '(installed)';

    printStatus(result);

    if (type == ValidationType.missing && validator.resolution != null)
      printStatus('$indent    ${validator.resolution}');
  }

  List<ValidationResult> get _allResults {
    List<ValidationResult> results = <ValidationResult>[this];
    results.addAll(childResults);
    return results;
  }
}
