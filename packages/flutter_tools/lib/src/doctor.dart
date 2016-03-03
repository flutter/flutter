// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

import 'android/android_workflow.dart';
import 'base/context.dart';
import 'base/os.dart';
import 'globals.dart';
import 'ios/ios_workflow.dart';

// TODO(devoncarew): Make it easy to add version information to the `doctor` printout.

class Doctor {
  Doctor() {
    _iosWorkflow = new IOSWorkflow();
    if (_iosWorkflow.appliesToHostPlatform)
      _validators.add(_iosWorkflow);

    _androidWorkflow = new AndroidWorkflow();
    if (_androidWorkflow.appliesToHostPlatform)
      _validators.add(_androidWorkflow);

    _validators.add(new _AtomValidator());
  }

  static void initGlobal() {
    context[Doctor] = new Doctor();
  }

  IOSWorkflow _iosWorkflow;
  AndroidWorkflow _androidWorkflow;

  /// This can return null for platforms that don't support developing for iOS.
  IOSWorkflow get iosWorkflow => _iosWorkflow;

  AndroidWorkflow get androidWorkflow => _androidWorkflow;

  List<DoctorValidator> _validators = <DoctorValidator>[];

  List<Workflow> get workflows {
    return new List<Workflow>.from(_validators.where((DoctorValidator validator) => validator is Workflow));
  }

  /// Print a summary of the state of the tooling, as well as how to get more info.
  void summary() => printStatus(summaryText);

  String get summaryText {
    StringBuffer buffer = new StringBuffer();

    bool allGood = true;

    for (DoctorValidator validator in _validators) {
      ValidationResult result = validator.validate();
      buffer.write('${result.leadingBox} The ${validator.label} is ');
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
    bool firstLine = true;
    for (DoctorValidator validator in _validators) {
      if (!firstLine)
        printStatus('');
      firstLine = false;
      validator.diagnose();
    }
  }

  bool get canListAnything => workflows.any((Workflow workflow) => workflow.canListDevices);

  bool get canLaunchAnything => workflows.any((Workflow workflow) => workflow.canLaunchDevices);
}

abstract class DoctorValidator {
  String get label;

  ValidationResult validate();

  /// Print verbose information about the state of the workflow.
  void diagnose();
}

/// A series of tools and required install steps for a target platform (iOS or Android).
abstract class Workflow extends DoctorValidator {
  /// Whether the workflow applies to this platform (as in, should we ever try and use it).
  bool get appliesToHostPlatform;

  /// Are we functional enough to list devices?
  bool get canListDevices;

  /// Could this thing launch *something*? It may still have minor issues.
  bool get canLaunchDevices;
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

class _AtomValidator extends DoctorValidator {
  static String getAtomHomePath() {
    final Map<String, String> env = Platform.environment;
    if (env['ATOM_HOME'] != null)
      return env['ATOM_HOME'];
    return os.isWindows
      ? path.join(env['USERPROFILE'], '.atom')
      : path.join(env['HOME'], '.atom');
  }

  String get label => 'Atom development environment';

  ValidationResult validate() {
    Validator atomValidator = new Validator(
      label,
      description: 'a lightweight development environment for Flutter'
    );

    ValidationType atomExists() {
      bool atomDirExists = FileSystemEntity.isDirectorySync(getAtomHomePath());
      return atomDirExists ? ValidationType.installed : ValidationType.missing;
    };

    ValidationType flutterPluginExists() {
      String flutterPluginPath = path.join(getAtomHomePath(), 'packages', 'flutter');
      bool flutterPluginExists = FileSystemEntity.isDirectorySync(flutterPluginPath);
      return flutterPluginExists ? ValidationType.installed : ValidationType.missing;
    };

    atomValidator.addValidator(new Validator(
      'Atom editor',
      resolution: 'Download at https://atom.io',
      validatorFunction: atomExists
    ));

    atomValidator.addValidator(new Validator(
      'Flutter plugin',
      description: 'adds Flutter specific functionality to Atom',
      resolution: "Install the 'flutter' plugin in Atom or run 'apm install flutter'",
      validatorFunction: flutterPluginExists
    ));

    return atomValidator.validate();
  }

  void diagnose() => validate().print();
}
