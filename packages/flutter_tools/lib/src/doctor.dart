// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'android/android_studio_validator.dart';
import 'android/android_workflow.dart';
import 'artifacts.dart';
import 'base/async_guard.dart';
import 'base/common.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/os.dart';
import 'base/platform.dart';
import 'base/process.dart';
import 'base/terminal.dart';
import 'base/user_messages.dart';
import 'base/utils.dart';
import 'base/version.dart';
import 'cache.dart';
import 'device.dart';
import 'fuchsia/fuchsia_workflow.dart';
import 'globals.dart';
import 'intellij/intellij.dart';
import 'ios/ios_workflow.dart';
import 'ios/plist_parser.dart';
import 'linux/linux_doctor.dart';
import 'linux/linux_workflow.dart';
import 'macos/cocoapods_validator.dart';
import 'macos/macos_workflow.dart';
import 'macos/xcode_validator.dart';
import 'proxy_validator.dart';
import 'reporting/reporting.dart';
import 'tester/flutter_tester.dart';
import 'version.dart';
import 'vscode/vscode_validator.dart';
import 'web/web_validator.dart';
import 'web/workflow.dart';
import 'windows/visual_studio_validator.dart';
import 'windows/windows_workflow.dart';

Doctor get doctor => context.get<Doctor>();

abstract class DoctorValidatorsProvider {
  /// The singleton instance, pulled from the [AppContext].
  static DoctorValidatorsProvider get instance => context.get<DoctorValidatorsProvider>();

  static final DoctorValidatorsProvider defaultInstance = _DefaultDoctorValidatorsProvider();

  List<DoctorValidator> get validators;
  List<Workflow> get workflows;
}

class _DefaultDoctorValidatorsProvider implements DoctorValidatorsProvider {
  List<DoctorValidator> _validators;
  List<Workflow> _workflows;

  @override
  List<DoctorValidator> get validators {
    if (_validators != null) {
      return _validators;
    }

    final List<DoctorValidator> ideValidators = <DoctorValidator>[
      ...AndroidStudioValidator.allValidators,
      ...IntelliJValidator.installedValidators,
      ...VsCodeValidator.installedValidators,
    ];

    _validators = <DoctorValidator>[
      FlutterValidator(),
      if (androidWorkflow.appliesToHostPlatform)
        GroupedValidator(<DoctorValidator>[androidValidator, androidLicenseValidator]),
      if (iosWorkflow.appliesToHostPlatform || macOSWorkflow.appliesToHostPlatform)
        GroupedValidator(<DoctorValidator>[xcodeValidator, cocoapodsValidator]),
      if (webWorkflow.appliesToHostPlatform)
        const WebValidator(),
      if (linuxWorkflow.appliesToHostPlatform)
        LinuxDoctorValidator(),
      if (windowsWorkflow.appliesToHostPlatform)
        visualStudioValidator,
      if (ideValidators.isNotEmpty)
        ...ideValidators
      else
        NoIdeValidator(),
      if (ProxyValidator.shouldShow)
        ProxyValidator(),
      if (deviceManager.canListAnything)
        DeviceValidator(),
    ];
    return _validators;
  }

  @override
  List<Workflow> get workflows {
    if (_workflows == null) {
      _workflows = <Workflow>[];

      if (iosWorkflow.appliesToHostPlatform)
        _workflows.add(iosWorkflow);

      if (androidWorkflow.appliesToHostPlatform)
        _workflows.add(androidWorkflow);

      if (fuchsiaWorkflow.appliesToHostPlatform)
        _workflows.add(fuchsiaWorkflow);

      if (linuxWorkflow.appliesToHostPlatform)
        _workflows.add(linuxWorkflow);

      if (macOSWorkflow.appliesToHostPlatform)
        _workflows.add(macOSWorkflow);

      if (windowsWorkflow.appliesToHostPlatform)
        _workflows.add(windowsWorkflow);

      if (webWorkflow.appliesToHostPlatform)
        _workflows.add(webWorkflow);

    }
    return _workflows;
  }

}

class ValidatorTask {
  ValidatorTask(this.validator, this.result);
  final DoctorValidator validator;
  final Future<ValidationResult> result;
}

class Doctor {
  const Doctor();

  List<DoctorValidator> get validators {
    return DoctorValidatorsProvider.instance.validators;
  }

  /// Return a list of [ValidatorTask] objects and starts validation on all
  /// objects in [validators].
  List<ValidatorTask> startValidatorTasks() {
    final List<ValidatorTask> tasks = <ValidatorTask>[];
    for (DoctorValidator validator in validators) {
      // We use an asyncGuard() here to be absolutely certain that
      // DoctorValidators do not result in an uncaught exception. Since the
      // Future returned by the asyncGuard() is not awaited, we pass an
      // onError callback to it and translate errors into ValidationResults.
      final Future<ValidationResult> result =
          asyncGuard<ValidationResult>(validator.validate,
            onError: (Object exception, StackTrace stackTrace) {
              return ValidationResult.crash(exception, stackTrace);
            });
      tasks.add(ValidatorTask(validator, result));
    }
    return tasks;
  }

  List<Workflow> get workflows {
    return DoctorValidatorsProvider.instance.workflows;
  }

  /// Print a summary of the state of the tooling, as well as how to get more info.
  Future<void> summary() async {
    printStatus(await _summaryText());
  }

  Future<String> _summaryText() async {
    final StringBuffer buffer = StringBuffer();

    bool missingComponent = false;
    bool sawACrash = false;

    for (DoctorValidator validator in validators) {
      final StringBuffer lineBuffer = StringBuffer();
      ValidationResult result;
      try {
        result = await asyncGuard<ValidationResult>(() => validator.validate());
      } catch (exception) {
        // We're generating a summary, so drop the stack trace.
        result = ValidationResult.crash(exception);
      }
      lineBuffer.write('${result.coloredLeadingBox} ${validator.title}: ');
      switch (result.type) {
        case ValidationType.crash:
          lineBuffer.write('the doctor check crashed without a result.');
          sawACrash = true;
          break;
        case ValidationType.missing:
          lineBuffer.write('is not installed.');
          break;
        case ValidationType.partial:
          lineBuffer.write('is partially installed; more components are available.');
          break;
        case ValidationType.notAvailable:
          lineBuffer.write('is not available.');
          break;
        case ValidationType.installed:
          lineBuffer.write('is fully installed.');
          break;
      }

      if (result.statusInfo != null) {
        lineBuffer.write(' (${result.statusInfo})');
      }

      buffer.write(wrapText(lineBuffer.toString(), hangingIndent: result.leadingBox.length + 1));
      buffer.writeln();

      if (result.type != ValidationType.installed) {
        missingComponent = true;
      }
    }

    if (sawACrash) {
      buffer.writeln();
      buffer.writeln('Run "flutter doctor" for information about why a doctor check crashed.');
    }

    if (missingComponent) {
      buffer.writeln();
      buffer.writeln('Run "flutter doctor" for information about installing additional components.');
    }

    return buffer.toString();
  }

  Future<bool> checkRemoteArtifacts(String engineRevision) async {
    return Cache.instance.areRemoteArtifactsAvailable(engineVersion: engineRevision);
  }

  /// Print information about the state of installed tooling.
  Future<bool> diagnose({ bool androidLicenses = false, bool verbose = true }) async {
    if (androidLicenses)
      return AndroidLicenseValidator.runLicenseManager();

    if (!verbose) {
      printStatus('Doctor summary (to see all details, run flutter doctor -v):');
    }
    bool doctorResult = true;
    int issues = 0;

    for (ValidatorTask validatorTask in startValidatorTasks()) {
      final DoctorValidator validator = validatorTask.validator;
      final Status status = Status.withSpinner(
        timeout: timeoutConfiguration.fastOperation,
        slowWarningCallback: () => validator.slowWarning,
      );
      ValidationResult result;
      try {
        result = await validatorTask.result;
      } catch (exception, stackTrace) {
        result = ValidationResult.crash(exception, stackTrace);
      } finally {
        status.stop();
      }

      switch (result.type) {
        case ValidationType.crash:
          doctorResult = false;
          issues += 1;
          break;
        case ValidationType.missing:
          doctorResult = false;
          issues += 1;
          break;
        case ValidationType.partial:
        case ValidationType.notAvailable:
          issues += 1;
          break;
        case ValidationType.installed:
          break;
      }

      DoctorResultEvent(validator: validator, result: result).send();

      if (result.statusInfo != null) {
        printStatus('${result.coloredLeadingBox} ${validator.title} (${result.statusInfo})',
            hangingIndent: result.leadingBox.length + 1);
      } else {
        printStatus('${result.coloredLeadingBox} ${validator.title}',
            hangingIndent: result.leadingBox.length + 1);
      }

      for (ValidationMessage message in result.messages) {
        if (message.type != ValidationMessageType.information || verbose == true) {
          int hangingIndent = 2;
          int indent = 4;
          for (String line in '${message.coloredIndicator} ${message.message}'.split('\n')) {
            printStatus(line, hangingIndent: hangingIndent, indent: indent, emphasis: true);
            // Only do hanging indent for the first line.
            hangingIndent = 0;
            indent = 6;
          }
        }
      }
      if (verbose) {
        printStatus('');
      }
    }

    // Make sure there's always one line before the summary even when not verbose.
    if (!verbose) {
      printStatus('');
    }

    if (issues > 0) {
      printStatus('${terminal.color('!', TerminalColor.yellow)} Doctor found issues in $issues categor${issues > 1 ? "ies" : "y"}.', hangingIndent: 2);
    } else {
      printStatus('${terminal.color('•', TerminalColor.green)} No issues found!', hangingIndent: 2);
    }

    return doctorResult;
  }

  bool get canListAnything => workflows.any((Workflow workflow) => workflow.canListDevices);

  bool get canLaunchAnything {
    if (FlutterTesterDevices.showFlutterTesterDevice)
      return true;
    return workflows.any((Workflow workflow) => workflow.canLaunchDevices);
  }
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

  List<ValidationResult> _subResults;

  /// Subvalidator results.
  ///
  /// To avoid losing information when results are merged, the subresults are
  /// cached on this field when they are available. The results are in the same
  /// order as the subvalidator list.
  List<ValidationResult> get subResults => _subResults;

  @override
  String get slowWarning => _currentSlowWarning;
  String _currentSlowWarning = 'Initializing...';

  @override
  Future<ValidationResult> validate() async {
    final List<ValidatorTask> tasks = <ValidatorTask>[];
    for (DoctorValidator validator in subValidators) {
      final Future<ValidationResult> result =
          asyncGuard<ValidationResult>(() => validator.validate());
      tasks.add(ValidatorTask(validator, result));
    }

    final List<ValidationResult> results = <ValidationResult>[];
    for (ValidatorTask subValidator in tasks) {
      _currentSlowWarning = subValidator.validator.slowWarning;
      try {
        results.add(await subValidator.result);
      } catch (exception, stackTrace) {
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
    String statusInfo;

    for (ValidationResult result in results) {
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
          throw 'Unrecognized validation type: ' + result.type.toString();
      }
      mergedMessages.addAll(result.messages);
    }

    return ValidationResult(mergedType, mergedMessages,
        statusInfo: statusInfo);
  }
}

class ValidationResult {
  /// [ValidationResult.type] should only equal [ValidationResult.installed]
  /// if no [messages] are hints or errors.
  ValidationResult(this.type, this.messages, { this.statusInfo });

  factory ValidationResult.crash(Object error, [StackTrace stackTrace]) {
    return ValidationResult(ValidationType.crash, <ValidationMessage>[
      ValidationMessage.error(
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
  final String statusInfo;
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
    return null;
  }

  String get coloredLeadingBox {
    assert(type != null);
    switch (type) {
      case ValidationType.crash:
        return terminal.color(leadingBox, TerminalColor.red);
      case ValidationType.missing:
        return terminal.color(leadingBox, TerminalColor.red);
      case ValidationType.installed:
        return terminal.color(leadingBox, TerminalColor.green);
      case ValidationType.notAvailable:
      case ValidationType.partial:
       return terminal.color(leadingBox, TerminalColor.yellow);
    }
    return null;
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
    return null;
  }
}

class ValidationMessage {
  ValidationMessage(this.message) : type = ValidationMessageType.information;
  ValidationMessage.error(this.message) : type = ValidationMessageType.error;
  ValidationMessage.hint(this.message) : type = ValidationMessageType.hint;

  final ValidationMessageType type;
  bool get isError => type == ValidationMessageType.error;
  bool get isHint => type == ValidationMessageType.hint;
  final String message;

  String get indicator {
    switch (type) {
      case ValidationMessageType.error:
        return '✗';
      case ValidationMessageType.hint:
        return '!';
      case ValidationMessageType.information:
        return '•';
    }
    return null;
  }

  String get coloredIndicator {
    switch (type) {
      case ValidationMessageType.error:
        return terminal.color(indicator, TerminalColor.red);
      case ValidationMessageType.hint:
        return terminal.color(indicator, TerminalColor.yellow);
      case ValidationMessageType.information:
        return terminal.color(indicator, TerminalColor.green);
    }
    return null;
  }

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final ValidationMessage typedOther = other;
    return typedOther.message == message
      && typedOther.type == type;
  }

  @override
  int get hashCode => type.hashCode ^ message.hashCode;
}

class FlutterValidator extends DoctorValidator {
  FlutterValidator() : super('Flutter');

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    ValidationType valid = ValidationType.installed;

    final FlutterVersion version = FlutterVersion.instance;

    messages.add(ValidationMessage(userMessages.flutterVersion(version.frameworkVersion, Cache.flutterRoot)));
    messages.add(ValidationMessage(userMessages.flutterRevision(version.frameworkRevisionShort, version.frameworkAge, version.frameworkDate)));
    messages.add(ValidationMessage(userMessages.engineRevision(version.engineRevisionShort)));
    messages.add(ValidationMessage(userMessages.dartRevision(version.dartSdkVersion)));
    final String genSnapshotPath =
      artifacts.getArtifactPath(Artifact.genSnapshot);

    // Check that the binaries we downloaded for this platform actually run on it.
    if (!_genSnapshotRuns(genSnapshotPath)) {
      final StringBuffer buf = StringBuffer();
      buf.writeln(userMessages.flutterBinariesDoNotRun);
      if (platform.isLinux) {
        buf.writeln(userMessages.flutterBinariesLinuxRepairCommands);
      }
      messages.add(ValidationMessage.error(buf.toString()));
      valid = ValidationType.partial;
    }

    return ValidationResult(valid, messages,
      statusInfo: userMessages.flutterStatusInfo(version.channel, version.frameworkVersion, os.name, platform.localeName),
    );
  }
}

bool _genSnapshotRuns(String genSnapshotPath) {
  const int kExpectedExitCode = 255;
  try {
    return processUtils.runSync(<String>[genSnapshotPath]).exitCode == kExpectedExitCode;
  } catch (error) {
    return false;
  }
}

class NoIdeValidator extends DoctorValidator {
  NoIdeValidator() : super('Flutter IDE Support');

  @override
  Future<ValidationResult> validate() async {
    return ValidationResult(ValidationType.missing, <ValidationMessage>[
      ValidationMessage(userMessages.noIdeInstallationInfo),
    ], statusInfo: userMessages.noIdeStatusInfo);
  }
}

abstract class IntelliJValidator extends DoctorValidator {
  IntelliJValidator(String title, this.installPath) : super(title);

  final String installPath;

  String get version;
  String get pluginsPath;

  static final Map<String, String> _idToTitle = <String, String>{
    'IntelliJIdea': 'IntelliJ IDEA Ultimate Edition',
    'IdeaIC': 'IntelliJ IDEA Community Edition',
  };

  static final Version kMinIdeaVersion = Version(2017, 1, 0);

  static Iterable<DoctorValidator> get installedValidators {
    if (platform.isLinux || platform.isWindows)
      return IntelliJValidatorOnLinuxAndWindows.installed;
    if (platform.isMacOS)
      return IntelliJValidatorOnMac.installed;
    return <DoctorValidator>[];
  }

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];

    messages.add(ValidationMessage(userMessages.intellijLocation(installPath)));

    final IntelliJPlugins plugins = IntelliJPlugins(pluginsPath);
    plugins.validatePackage(messages, <String>['flutter-intellij', 'flutter-intellij.jar'],
        'Flutter', minVersion: IntelliJPlugins.kMinFlutterPluginVersion);
    plugins.validatePackage(messages, <String>['Dart'], 'Dart');

    if (_hasIssues(messages)) {
      messages.add(ValidationMessage(userMessages.intellijPluginInfo));
    }

    _validateIntelliJVersion(messages, kMinIdeaVersion);

    return ValidationResult(
      _hasIssues(messages) ? ValidationType.partial : ValidationType.installed,
      messages,
      statusInfo: userMessages.intellijStatusInfo(version));
  }

  bool _hasIssues(List<ValidationMessage> messages) {
    return messages.any((ValidationMessage message) => message.isError);
  }

  void _validateIntelliJVersion(List<ValidationMessage> messages, Version minVersion) {
    // Ignore unknown versions.
    if (minVersion == Version.unknown)
      return;

    final Version installedVersion = Version.parse(version);
    if (installedVersion == null)
      return;

    if (installedVersion < minVersion) {
      messages.add(ValidationMessage.error(userMessages.intellijMinimumVersion(minVersion.toString())));
    }
  }
}

class IntelliJValidatorOnLinuxAndWindows extends IntelliJValidator {
  IntelliJValidatorOnLinuxAndWindows(String title, this.version, String installPath, this.pluginsPath) : super(title, installPath);

  @override
  final String version;

  @override
  final String pluginsPath;

  static Iterable<DoctorValidator> get installed {
    final List<DoctorValidator> validators = <DoctorValidator>[];
    if (homeDirPath == null)
      return validators;

    void addValidator(String title, String version, String installPath, String pluginsPath) {
      final IntelliJValidatorOnLinuxAndWindows validator =
        IntelliJValidatorOnLinuxAndWindows(title, version, installPath, pluginsPath);
      for (int index = 0; index < validators.length; ++index) {
        final DoctorValidator other = validators[index];
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
        final String name = fs.path.basename(dir.path);
        IntelliJValidator._idToTitle.forEach((String id, String title) {
          if (name.startsWith('.$id')) {
            final String version = name.substring(id.length + 1);
            String installPath;
            try {
              installPath = fs.file(fs.path.join(dir.path, 'system', '.home')).readAsStringSync();
            } catch (e) {
              // ignored
            }
            if (installPath != null && fs.isDirectorySync(installPath)) {
              final String pluginsPath = fs.path.join(dir.path, 'config', 'plugins');
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
  IntelliJValidatorOnMac(String title, this.id, String installPath) : super(title, installPath);

  final String id;

  static final Map<String, String> _dirNameToId = <String, String>{
    'IntelliJ IDEA.app': 'IntelliJIdea',
    'IntelliJ IDEA Ultimate.app': 'IntelliJIdea',
    'IntelliJ IDEA CE.app': 'IdeaIC',
  };

  static Iterable<DoctorValidator> get installed {
    final List<DoctorValidator> validators = <DoctorValidator>[];
    final List<String> installPaths = <String>['/Applications', fs.path.join(homeDirPath, 'Applications')];

    void checkForIntelliJ(Directory dir) {
      final String name = fs.path.basename(dir.path);
      _dirNameToId.forEach((String dirName, String id) {
        if (name == dirName) {
          final String title = IntelliJValidator._idToTitle[id];
          validators.add(IntelliJValidatorOnMac(title, id, dir.path));
        }
      });
    }

    try {
      final Iterable<Directory> installDirs = installPaths
              .map<Directory>((String installPath) => fs.directory(installPath))
              .map<List<FileSystemEntity>>((Directory dir) => dir.existsSync() ? dir.listSync() : <FileSystemEntity>[])
              .expand<FileSystemEntity>((List<FileSystemEntity> mappedDirs) => mappedDirs)
              .whereType<Directory>();
      for (Directory dir in installDirs) {
        checkForIntelliJ(dir);
        if (!dir.path.endsWith('.app')) {
          for (FileSystemEntity subdir in dir.listSync()) {
            if (subdir is Directory) {
              checkForIntelliJ(subdir);
            }
          }
        }
      }
    } on FileSystemException catch (e) {
      validators.add(ValidatorWithResult(
          userMessages.intellijMacUnknownResult,
          ValidationResult(ValidationType.missing, <ValidationMessage>[
              ValidationMessage.error(e.message),
          ]),
      ));
    }
    return validators;
  }

  @override
  String get version {
    if (_version == null) {
      final String plistFile = fs.path.join(installPath, 'Contents', 'Info.plist');
      _version = PlistParser.instance.getValueFromFile(
        plistFile,
        PlistParser.kCFBundleShortVersionStringKey,
      ) ?? 'unknown';
    }
    return _version;
  }
  String _version;

  @override
  String get pluginsPath {
    final List<String> split = version.split('.');
    final String major = split[0];
    final String minor = split[1];
    return fs.path.join(homeDirPath, 'Library', 'Application Support', '$id$major.$minor');
  }
}

class DeviceValidator extends DoctorValidator {
  DeviceValidator() : super('Connected device');

  @override
  String get slowWarning => 'Scanning for devices is taking a long time...';

  @override
  Future<ValidationResult> validate() async {
    final List<Device> devices = await deviceManager.getAllConnectedDevices().toList();
    List<ValidationMessage> messages;
    if (devices.isEmpty) {
      final List<String> diagnostics = await deviceManager.getDeviceDiagnostics();
      if (diagnostics.isNotEmpty) {
        messages = diagnostics.map<ValidationMessage>((String message) => ValidationMessage(message)).toList();
      } else {
        messages = <ValidationMessage>[ValidationMessage.hint(userMessages.devicesMissing)];
      }
    } else {
      messages = await Device.descriptions(devices)
          .map<ValidationMessage>((String msg) => ValidationMessage(msg)).toList();
    }

    if (devices.isEmpty) {
      return ValidationResult(ValidationType.notAvailable, messages);
    } else {
      return ValidationResult(ValidationType.installed, messages, statusInfo: userMessages.devicesAvailable(devices.length));
    }
  }
}

class ValidatorWithResult extends DoctorValidator {
  ValidatorWithResult(String title, this.result) : super(title);

  final ValidationResult result;

  @override
  Future<ValidationResult> validate() async => result;
}
