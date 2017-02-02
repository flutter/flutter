// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show UTF8;

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import 'android/android_workflow.dart';
import 'base/common.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/platform.dart';
import 'device.dart';
import 'globals.dart';
import 'ios/ios_workflow.dart';
import 'version.dart';

Doctor get doctor => context[Doctor];

const Map<String, String> _osNames = const <String, String>{
  'macos': 'Mac OS',
  'linux': 'Linux',
  'windows': 'Windows'
};

String osName() {
  String os = platform.operatingSystem;
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

    List<DoctorValidator> ideValidators = <DoctorValidator>[];
    ideValidators.addAll(IntelliJValidator.installedValidators);
    if (ideValidators.isNotEmpty)
      _validators.addAll(ideValidators);
    else
      _validators.add(new NoIdeValidator());

    _validators.add(new DeviceValidator());
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
  Future<Null> summary() async {
    printStatus(await summaryText);
  }

  Future<String> get summaryText async {
    StringBuffer buffer = new StringBuffer();

    bool allGood = true;

    for (DoctorValidator validator in _validators) {
      ValidationResult result = await validator.validate();
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
      buffer.writeln('Run "flutter doctor" for information about installing additional components.');
    }

    return buffer.toString();
  }

  /// Print verbose information about the state of installed tooling.
  Future<bool> diagnose() async {
    bool firstLine = true;
    bool doctorResult = true;

    for (DoctorValidator validator in _validators) {
      if (!firstLine)
        printStatus('');
      firstLine = false;

      ValidationResult result = await validator.validate();

      if (result.type == ValidationType.missing)
        doctorResult = false;

      if (result.statusInfo != null)
        printStatus('${result.leadingBox} ${validator.title} (${result.statusInfo})');
      else
        printStatus('${result.leadingBox} ${validator.title}');

      for (ValidationMessage message in result.messages) {
        String text = message.message.replaceAll('\n', '\n      ');
        if (message.isError) {
          printStatus('    x $text', emphasis: true);
        } else {
          printStatus('    • $text');
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

  Future<ValidationResult> validate();
}

class ValidationResult {
  ValidationResult(this.type, this.messages, { this.statusInfo });

  final ValidationType type;
  // A short message about the status.
  final String statusInfo;
  final List<ValidationMessage> messages;

  String get leadingBox {
    if (type == ValidationType.missing)
      return '[✗]';
    else if (type == ValidationType.installed)
      return '[✓]';
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
  Future<ValidationResult> validate() async {
    List<ValidationMessage> messages = <ValidationMessage>[];
    ValidationType valid = ValidationType.installed;

    FlutterVersion version = FlutterVersion.getVersion();

    messages.add(new ValidationMessage('Flutter at ${version.flutterRoot}'));
    messages.add(new ValidationMessage(
      'Framework revision ${version.frameworkRevisionShort} '
      '(${version.frameworkAge}), ${version.frameworkDate}'
    ));
    messages.add(new ValidationMessage('Engine revision ${version.engineRevisionShort}'));
    messages.add(new ValidationMessage('Tools Dart version ${version.dartSdkVersion}'));

    if (platform.isWindows) {
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

class NoIdeValidator extends DoctorValidator {
  NoIdeValidator() : super('Flutter IDE Support');

  @override
  Future<ValidationResult> validate() async {
    return new ValidationResult(ValidationType.missing, <ValidationMessage>[
      new ValidationMessage('IntelliJ - https://www.jetbrains.com/idea/'),
    ], statusInfo: 'No supported IDEs installed');
  }
}

abstract class IntelliJValidator extends DoctorValidator {
  IntelliJValidator(String title) : super(title);

  String get version;
  String get pluginsPath;

  static final Map<String, String> _idToTitle = <String, String>{
    'IntelliJIdea' : 'IntelliJ IDEA Ultimate Edition',
    'IdeaIC' : 'IntelliJ IDEA Community Edition',
  };

  static Iterable<DoctorValidator> get installedValidators {
    if (platform.isLinux || platform.isWindows)
      return IntelliJValidatorOnLinuxAndWindows.installed;
    if (platform.isMacOS)
      return IntelliJValidatorOnMac.installed;
    return <DoctorValidator>[];
  }

  @override
  Future<ValidationResult> validate() async {
    List<ValidationMessage> messages = <ValidationMessage>[];

    int installCount = 0;

    if (_validateHasPackage(messages, 'Dart', 'Dart'))
      installCount++;

    if (_validateHasPackage(messages, 'flutter-intellij.jar', 'Flutter'))
      installCount++;

    if (installCount < 2) {
      messages.add(new ValidationMessage(
          'For information about managing plugins, see\n'
          'https://www.jetbrains.com/help/idea/2016.2/managing-plugins.html'
      ));
    }

    return new ValidationResult(
        installCount == 2 ? ValidationType.installed : ValidationType.partial,
        messages,
        statusInfo: 'version $version'
    );
  }

  bool _validateHasPackage(List<ValidationMessage> messages, String packageName, String title) {
    if (!hasPackage(packageName)) {
      messages.add(new ValidationMessage(
        '$title plugin not installed; this adds $title specific functionality.'
      ));
      return false;
    }
    String version = _readPackageVersion(packageName);
    messages.add(new ValidationMessage('$title plugin '
        '${version != null ? "version $version" : "installed"}'));
    return true;
  }

  String _readPackageVersion(String packageName) {
    String jarPath = packageName.endsWith('.jar')
        ? path.join(pluginsPath, packageName)
        : path.join(pluginsPath, packageName, 'lib', '$packageName.jar');
    // TODO(danrubel) look for a better way to extract a single 2K file from the zip
    // rather than reading the entire file into memory.
    try {
      Archive archive = new ZipDecoder().decodeBytes(fs.file(jarPath).readAsBytesSync());
      ArchiveFile file = archive.findFile('META-INF/plugin.xml');
      String content = UTF8.decode(file.content);
      String versionStartTag = '<version>';
      int start = content.indexOf(versionStartTag);
      int end = content.indexOf('</version>', start);
      return content.substring(start + versionStartTag.length, end);
    } catch (_) {
      return null;
    }
  }

  bool hasPackage(String packageName) {
    String packagePath = path.join(pluginsPath, packageName);
    if (packageName.endsWith('.jar'))
      return fs.isFileSync(packagePath);
    return fs.isDirectorySync(packagePath);
  }
}

class IntelliJValidatorOnLinuxAndWindows extends IntelliJValidator {
  IntelliJValidatorOnLinuxAndWindows(String title, this.version, this.installPath, this.pluginsPath) : super(title);

  @override
  String version;

  final String installPath;

  @override
  String pluginsPath;

  static Iterable<DoctorValidator> get installed {
    List<DoctorValidator> validators = <DoctorValidator>[];
    if (homeDirPath == null) return validators;

    void addValidator(String title, String version, String installPath, String pluginsPath) {
      IntelliJValidatorOnLinuxAndWindows validator =
        new IntelliJValidatorOnLinuxAndWindows(title, version, installPath, pluginsPath);
      for (int index = 0; index < validators.length; ++index) {
        DoctorValidator other = validators[index];
        if (other is IntelliJValidatorOnLinuxAndWindows && validator.installPath == other.installPath) {
          if (validator.version.compareTo(other.version) > 0)
            validators[index] = validator;
          return;
        }
      }
      validators.add(validator);
    }

    for (FileSystemEntity dir in fs.directory(homeDirPath).listSync()) {
      if (dir is Directory) {
        String name = path.basename(dir.path);
        IntelliJValidator._idToTitle.forEach((String id, String title) {
          if (name.startsWith('.$id')) {
            String version = name.substring(id.length + 1);
            String installPath;
            try {
              installPath = fs.file(path.join(dir.path, 'system', '.home')).readAsStringSync();
            } catch (e) {
              // ignored
            }
            if (installPath != null && fs.isDirectorySync(installPath)) {
              String pluginsPath = path.join(dir.path, 'config', 'plugins');
              addValidator(title, version, installPath, pluginsPath);
            }
          }
        });
      }
    }
    return validators;
  }
}

class IntelliJValidatorOnMac extends IntelliJValidator {
  IntelliJValidatorOnMac(String title, this.id, this.installPath) : super(title);

  final String id;
  final String installPath;

  static final Map<String, String> _dirNameToId = <String, String>{
    'IntelliJ IDEA.app' : 'IntelliJIdea',
    'IntelliJ IDEA Ultimate.app' : 'IntelliJIdea',
    'IntelliJ IDEA CE.app' : 'IdeaIC',
  };

  static Iterable<DoctorValidator> get installed {
    List<DoctorValidator> validators = <DoctorValidator>[];
    List<String> installPaths = <String>['/Applications', path.join(homeDirPath, 'Applications')];

    void checkForIntelliJ(Directory dir) {
      String name = path.basename(dir.path);
      _dirNameToId.forEach((String dirName, String id) {
        if (name == dirName) {
          String title = IntelliJValidator._idToTitle[id];
          validators.add(new IntelliJValidatorOnMac(title, id, dir.path));
        }
      });
    }

    try {
      Iterable<FileSystemEntity> installDirs = installPaths
              .map((String installPath) => fs.directory(installPath).listSync())
              .expand((List<FileSystemEntity> mappedDirs) => mappedDirs)
              .where((FileSystemEntity mappedDir) => mappedDir is Directory);
      for (FileSystemEntity dir in installDirs) {
        if (dir is Directory) {
          checkForIntelliJ(dir);
          if (!dir.path.endsWith('.app')) {
            for (FileSystemEntity subdir in dir.listSync()) {
              if (subdir is Directory) {
                checkForIntelliJ(subdir);
              }
            }
          }
        }
      }
    } on FileSystemException catch (e) {
      validators.add(new ValidatorWithResult(
          'Cannot determine if IntelliJ is installed',
          new ValidationResult(ValidationType.missing, <ValidationMessage>[
             new ValidationMessage.error(e.message),
          ]),
      ));
    }
    return validators;
  }

  @override
  String get version {
    if (_version == null) {
      String plist;
      try {
        plist = fs.file(path.join(installPath, 'Contents', 'Info.plist')).readAsStringSync();
        int index = plist.indexOf('CFBundleShortVersionString');
        if (index > 0) {
          int start = plist.indexOf('<string>', index);
          if (start > 0) {
            int end = plist.indexOf('</string>', start);
            if (end > 0) {
              _version = plist.substring(start + 8, end);
            }
          }
        }
      } on FileSystemException catch (_) {
        // ignored
      }
      _version ??= 'unknown';
    }
    return _version;
  }
  String _version;

  @override
  String get pluginsPath {
    List<String> split = version.split('.');
    String major = split[0];
    String minor = split[1];
    return path.join(homeDirPath, 'Library', 'Application Support', '$id$major.$minor');
  }
}

class DeviceValidator extends DoctorValidator {
  DeviceValidator() : super('Connected devices');

  @override
  Future<ValidationResult> validate() async {
    List<Device> devices = await deviceManager.getAllConnectedDevices();
    List<ValidationMessage> messages;
    if (devices.isEmpty) {
      messages = <ValidationMessage>[new ValidationMessage('None')];
    } else {
      messages = Device.descriptions(devices)
          .map((String msg) => new ValidationMessage(msg)).toList();
    }
    return new ValidationResult(ValidationType.installed, messages);
  }
}

class ValidatorWithResult extends DoctorValidator {
  final ValidationResult result;

  ValidatorWithResult(String title, this.result) : super(title);

  @override
  Future<ValidationResult> validate() async => result;
}
