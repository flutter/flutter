// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show JSON;
import 'dart:io';

import 'package:path/path.dart' as path;

import 'android/android_workflow.dart';
import 'base/context.dart';
import 'base/os.dart';
import 'globals.dart';
import 'ios/ios_workflow.dart';
import 'version.dart';

const Map<String, String> _osNames = const <String, String>{
  'macos': 'Mac OS',
  'linux': 'Linux',
  'windows': 'Windows'
};

String osName() {
  String os = Platform.operatingSystem;
  return _osNames.containsKey(os) ? _osNames[os] : os;
}

class Doctor {
  Doctor() {
    _validators.add(new _FlutterValidator());

    _androidWorkflow = new AndroidWorkflow();
    if (_androidWorkflow.appliesToHostPlatform)
      _validators.add(_androidWorkflow);

    _iosWorkflow = new IOSWorkflow();
    if (_iosWorkflow.appliesToHostPlatform)
      _validators.add(_iosWorkflow);

    _validators.add(new AtomValidator());
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
      buffer.write('${result.leadingBox} ${validator.title} is ');
      if (result.type == ValidationType.missing)
        buffer.write('not installed.');
      else if (result.type == ValidationType.partial)
        buffer.write('partially installed; more components are available.');
      else
        buffer.write('fully installed.');

      if (result.statusInfo != null)
        buffer.write(' (${result.statusInfo})');

      buffer.writeln();

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
  bool diagnose() {
    bool firstLine = true;
    bool doctorResult = true;

    for (DoctorValidator validator in _validators) {
      if (!firstLine)
        printStatus('');
      firstLine = false;

      ValidationResult result = validator.validate();

      if (result.type == ValidationType.missing)
        doctorResult = false;

      if (result.statusInfo != null)
        printStatus('${result.leadingBox} ${validator.title} (${result.statusInfo})');
      else
        printStatus('${result.leadingBox} ${validator.title}');

      final String separator = Platform.isWindows ? ' ' : '•';

      for (ValidationMessage message in result.messages) {
        if (message.isError) {
          printStatus('    x ${message.message.replaceAll('\n', '\n      ')}', emphasis: true);
        } else {
          printStatus('    $separator ${message.message.replaceAll('\n', '\n      ')}');
        }
      }
    }

    return doctorResult;
  }

  bool get canListAnything => workflows.any((Workflow workflow) => workflow.canListDevices);

  bool get canLaunchAnything => workflows.any((Workflow workflow) => workflow.canLaunchDevices);
}

/// A series of tools and required install steps for a target platform (iOS or Android).
abstract class Workflow {
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

abstract class DoctorValidator {
  DoctorValidator(this.title);

  final String title;

  ValidationResult validate();
}

class ValidationResult {
  ValidationResult(this.type, this.messages, { this.statusInfo });

  final ValidationType type;
  // A short message about the status.
  final String statusInfo;
  final List<ValidationMessage> messages;

  bool get isInstalled => type == ValidationType.installed;

  String get leadingBox {
    if (type == ValidationType.missing)
      return '[x]';
    else if (type == ValidationType.installed)
      return Platform.isWindows ? '[+]' : '[✓]';
    else
      return '[-]';
  }
}

class ValidationMessage {
  ValidationMessage(this.message) : isError = false;
  ValidationMessage.error(this.message) : isError = true;

  final bool isError;
  final String message;

  @override
  String toString() => message;
}

class _FlutterValidator extends DoctorValidator {
  _FlutterValidator() : super('Flutter');

  @override
  ValidationResult validate() {
    List<ValidationMessage> messages = <ValidationMessage>[];
    ValidationType valid = ValidationType.installed;

    FlutterVersion version = FlutterVersion.getVersion();

    messages.add(new ValidationMessage('Flutter at ${version.flutterRoot}'));
    messages.add(new ValidationMessage(
      'Framework revision ${version.frameworkRevisionShort} '
      '(${version.frameworkAge}), '
      'engine revision ${version.engineRevisionShort}'
    ));

    if (Platform.isWindows) {
      valid = ValidationType.missing;

      messages.add(new ValidationMessage.error(
        'Flutter tools are not (yet) supported on Windows: '
        'https://github.com/flutter/flutter/issues/138.'
      ));
    }

    return new ValidationResult(valid, messages,
      statusInfo: 'on ${osName()}, channel ${version.channel}');
  }
}

class AtomValidator extends DoctorValidator {
  AtomValidator() : super('Atom - a lightweight development environment for Flutter');

  static File getConfigFile() {
    // ~/.atom/config.cson
    return new File(path.join(_getAtomHomePath(), 'config.cson'));
  }

  static String _getAtomHomePath() {
    final Map<String, String> env = Platform.environment;
    if (env['ATOM_HOME'] != null)
      return env['ATOM_HOME'];
    return os.isWindows
      ? path.join(env['USERPROFILE'], '.atom')
      : path.join(env['HOME'], '.atom');
  }

  @override
  ValidationResult validate() {
    List<ValidationMessage> messages = <ValidationMessage>[];

    int installCount = 0;

    bool atomDirExists = FileSystemEntity.isDirectorySync(_getAtomHomePath());
    if (!atomDirExists) {
      messages.add(new ValidationMessage.error(
        'Atom not installed; download at https://atom.io.'
      ));
    } else {
      installCount++;
    }

    if (!hasPackage('flutter')) {
      messages.add(new ValidationMessage.error(
        'Flutter plugin not installed; this adds Flutter specific functionality to Atom.\n'
        'Install the \'flutter\' plugin in Atom or run \'apm install flutter\'.'
      ));
    } else {
      installCount++;

      try {
        String flutterPluginPath = path.join(_getAtomHomePath(), 'packages', 'flutter');
        File packageFile = new File(path.join(flutterPluginPath, 'package.json'));
        dynamic packageInfo = JSON.decode(packageFile.readAsStringSync());
        String version = packageInfo['version'];
        messages.add(new ValidationMessage('Atom installed; Flutter plugin version $version'));
      } catch (error) {
        printTrace('Unable to read flutter plugin version: $error');
      }
    }

    return new ValidationResult(
      installCount == 2
        ? ValidationType.installed
        : installCount == 1 ? ValidationType.partial : ValidationType.missing,
      messages
    );
  }

  bool hasPackage(String packageName) {
    String packagePath = path.join(_getAtomHomePath(), 'packages', packageName);
    return FileSystemEntity.isDirectorySync(packagePath);
  }
}
