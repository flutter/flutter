// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'android/android_studio_validator.dart';
import 'android/android_workflow.dart';
import 'artifacts.dart';
import 'base/async_guard.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/process.dart';
import 'base/terminal.dart';
import 'base/user_messages.dart';
import 'base/utils.dart';
import 'base/version.dart';
import 'cache.dart';
import 'device.dart';
import 'features.dart';
import 'fuchsia/fuchsia_workflow.dart';
import 'globals.dart' as globals;
import 'intellij/intellij.dart';
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
import 'web/chrome.dart';
import 'web/web_validator.dart';
import 'web/workflow.dart';
import 'windows/visual_studio_validator.dart';
import 'windows/windows_workflow.dart';

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

  final LinuxWorkflow linuxWorkflow = LinuxWorkflow(
    platform: globals.platform,
    featureFlags: featureFlags,
  );

  final WebWorkflow webWorkflow = WebWorkflow(
    platform: globals.platform,
    featureFlags: featureFlags,
  );

  final MacOSWorkflow macOSWorkflow = MacOSWorkflow(
    platform: globals.platform,
    featureFlags: featureFlags,
  );

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
    final ProxyValidator proxyValidator = ProxyValidator(platform: globals.platform);
    _validators = <DoctorValidator>[
      FlutterValidator(),
      if (androidWorkflow.appliesToHostPlatform)
        GroupedValidator(<DoctorValidator>[androidValidator, androidLicenseValidator]),
      if (globals.iosWorkflow.appliesToHostPlatform || macOSWorkflow.appliesToHostPlatform)
        GroupedValidator(<DoctorValidator>[XcodeValidator(xcode: globals.xcode, userMessages: userMessages), cocoapodsValidator]),
      if (webWorkflow.appliesToHostPlatform)
        ChromeValidator(
          chromiumLauncher: ChromiumLauncher(
            browserFinder: findChromeExecutable,
            fileSystem: globals.fs,
            operatingSystemUtils: globals.os,
            platform:  globals.platform,
            processManager: globals.processManager,
            logger: globals.logger,
          ),
          platform: globals.platform,
        ),
      if (linuxWorkflow.appliesToHostPlatform)
        LinuxDoctorValidator(
          processManager: globals.processManager,
          userMessages: userMessages,
        ),
      if (windowsWorkflow.appliesToHostPlatform)
        visualStudioValidator,
      if (ideValidators.isNotEmpty)
        ...ideValidators
      else
        NoIdeValidator(),
      if (proxyValidator.shouldShow)
        proxyValidator,
      if (globals.deviceManager.canListAnything)
        DeviceValidator(
          deviceManager: globals.deviceManager,
          userMessages: globals.userMessages,
        ),
    ];
    return _validators;
  }

  @override
  List<Workflow> get workflows {
    if (_workflows == null) {
      _workflows = <Workflow>[];

      if (globals.iosWorkflow.appliesToHostPlatform) {
        _workflows.add(globals.iosWorkflow);
      }

      if (androidWorkflow.appliesToHostPlatform) {
        _workflows.add(androidWorkflow);
      }

      if (fuchsiaWorkflow.appliesToHostPlatform) {
        _workflows.add(fuchsiaWorkflow);
      }

      if (linuxWorkflow.appliesToHostPlatform) {
        _workflows.add(linuxWorkflow);
      }

      if (macOSWorkflow.appliesToHostPlatform) {
        _workflows.add(macOSWorkflow);
      }

      if (windowsWorkflow.appliesToHostPlatform) {
        _workflows.add(windowsWorkflow);
      }

      if (webWorkflow.appliesToHostPlatform) {
        _workflows.add(webWorkflow);
      }

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
  Doctor({
    @required Logger logger,
  }) : _logger = logger;

  final Logger _logger;

  List<DoctorValidator> get validators {
    return DoctorValidatorsProvider.instance.validators;
  }

  /// Return a list of [ValidatorTask] objects and starts validation on all
  /// objects in [validators].
  List<ValidatorTask> startValidatorTasks() => <ValidatorTask>[
    for (final DoctorValidator validator in validators)
      ValidatorTask(
        validator,
        // We use an asyncGuard() here to be absolutely certain that
        // DoctorValidators do not result in an uncaught exception. Since the
        // Future returned by the asyncGuard() is not awaited, we pass an
        // onError callback to it and translate errors into ValidationResults.
        asyncGuard<ValidationResult>(
          validator.validate,
          onError: (Object exception, StackTrace stackTrace) {
            return ValidationResult.crash(exception, stackTrace);
          },
        ),
      ),
  ];

  List<Workflow> get workflows {
    return DoctorValidatorsProvider.instance.workflows;
  }

  /// Print a summary of the state of the tooling, as well as how to get more info.
  Future<void> summary() async {
    _logger.printStatus(await _summaryText());
  }

  Future<String> _summaryText() async {
    final StringBuffer buffer = StringBuffer();

    bool missingComponent = false;
    bool sawACrash = false;

    for (final DoctorValidator validator in validators) {
      final StringBuffer lineBuffer = StringBuffer();
      ValidationResult result;
      try {
        result = await asyncGuard<ValidationResult>(() => validator.validate());
      } on Exception catch (exception) {
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

      buffer.write(wrapText(
        lineBuffer.toString(),
        hangingIndent: result.leadingBox.length + 1,
        columnWidth: globals.outputPreferences.wrapColumn,
        shouldWrap: globals.outputPreferences.wrapText,
      ));
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
    return globals.cache.areRemoteArtifactsAvailable(engineVersion: engineRevision);
  }

  /// Print information about the state of installed tooling.
  Future<bool> diagnose({ bool androidLicenses = false, bool verbose = true, bool showColor = true }) async {
    if (androidLicenses) {
      return AndroidLicenseValidator.runLicenseManager();
    }

    if (!verbose) {
      _logger.printStatus('Doctor summary (to see all details, run flutter doctor -v):');
    }
    bool doctorResult = true;
    int issues = 0;

    for (final ValidatorTask validatorTask in startValidatorTasks()) {
      final DoctorValidator validator = validatorTask.validator;
      final Status status = Status.withSpinner(
        timeout: timeoutConfiguration.fastOperation,
        slowWarningCallback: () => validator.slowWarning,
        timeoutConfiguration: timeoutConfiguration,
        stopwatch: Stopwatch(),
        terminal: globals.terminal,
      );
      ValidationResult result;
      try {
        result = await validatorTask.result;
        status.stop();
      } on Exception catch (exception, stackTrace) {
        result = ValidationResult.crash(exception, stackTrace);
        status.cancel();
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

      final String leadingBox = showColor ? result.coloredLeadingBox : result.leadingBox;
      if (result.statusInfo != null) {
        _logger.printStatus('$leadingBox ${validator.title} (${result.statusInfo})',
            hangingIndent: result.leadingBox.length + 1);
      } else {
        _logger.printStatus('$leadingBox ${validator.title}',
            hangingIndent: result.leadingBox.length + 1);
      }

      for (final ValidationMessage message in result.messages) {
        if (message.type != ValidationMessageType.information || verbose == true) {
          int hangingIndent = 2;
          int indent = 4;
          final String indicator = showColor ? message.coloredIndicator : message.indicator;
          for (final String line in '$indicator ${message.message}'.split('\n')) {
            _logger.printStatus(line, hangingIndent: hangingIndent, indent: indent, emphasis: true);
            // Only do hanging indent for the first line.
            hangingIndent = 0;
            indent = 6;
          }
        }
      }
      if (verbose) {
        _logger.printStatus('');
      }
    }

    // Make sure there's always one line before the summary even when not verbose.
    if (!verbose) {
      _logger.printStatus('');
    }

    if (issues > 0) {
      _logger.printStatus('${showColor ? globals.terminal.color('!', TerminalColor.yellow) : '!'}'
        ' Doctor found issues in $issues categor${issues > 1 ? "ies" : "y"}.', hangingIndent: 2);
    } else {
      _logger.printStatus('${showColor ? globals.terminal.color('•', TerminalColor.green) : '•'}'
        ' No issues found!', hangingIndent: 2);
    }

    return doctorResult;
  }

  bool get canListAnything => workflows.any((Workflow workflow) => workflow.canListDevices);

  bool get canLaunchAnything {
    if (FlutterTesterDevices.showFlutterTesterDevice) {
      return true;
    }
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
    String statusInfo;

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
          throw 'Unrecognized validation type: ' + result.type.toString();
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

  factory ValidationResult.crash(Object error, [StackTrace stackTrace]) {
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
        return globals.terminal.color(leadingBox, TerminalColor.red);
      case ValidationType.missing:
        return globals.terminal.color(leadingBox, TerminalColor.red);
      case ValidationType.installed:
        return globals.terminal.color(leadingBox, TerminalColor.green);
      case ValidationType.notAvailable:
      case ValidationType.partial:
        return globals.terminal.color(leadingBox, TerminalColor.yellow);
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

@immutable
class ValidationMessage {
  const ValidationMessage(this.message) : type = ValidationMessageType.information;
  const ValidationMessage.error(this.message) : type = ValidationMessageType.error;
  const ValidationMessage.hint(this.message) : type = ValidationMessageType.hint;

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
        return globals.terminal.color(indicator, TerminalColor.red);
      case ValidationMessageType.hint:
        return globals.terminal.color(indicator, TerminalColor.yellow);
      case ValidationMessageType.information:
        return globals.terminal.color(indicator, TerminalColor.green);
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
    return other is ValidationMessage
        && other.message == message
        && other.type == type;
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
    String versionChannel;
    String frameworkVersion;

    try {
      final FlutterVersion version = globals.flutterVersion;
      versionChannel = version.channel;
      frameworkVersion = version.frameworkVersion;
      messages.add(ValidationMessage(userMessages.flutterVersion(
        frameworkVersion,
        Cache.flutterRoot,
      )));
      messages.add(ValidationMessage(userMessages.flutterRevision(
        version.frameworkRevisionShort,
        version.frameworkAge,
        version.frameworkDate,
      )));
      messages.add(ValidationMessage(userMessages.engineRevision(version.engineRevisionShort)));
      messages.add(ValidationMessage(userMessages.dartRevision(version.dartSdkVersion)));
      if (globals.platform.environment.containsKey('PUB_HOSTED_URL')) {
        messages.add(ValidationMessage(userMessages.pubMirrorURL(globals.platform.environment['PUB_HOSTED_URL'])));
      }
      if (globals.platform.environment.containsKey('FLUTTER_STORAGE_BASE_URL')) {
        messages.add(ValidationMessage(userMessages.flutterMirrorURL(globals.platform.environment['FLUTTER_STORAGE_BASE_URL'])));
      }
    } on VersionCheckError catch (e) {
      messages.add(ValidationMessage.error(e.message));
      valid = ValidationType.partial;
    }

    final String genSnapshotPath =
      globals.artifacts.getArtifactPath(Artifact.genSnapshot);

    // Check that the binaries we downloaded for this platform actually run on it.
    if (globals.fs.file(genSnapshotPath).existsSync()
        && !_genSnapshotRuns(genSnapshotPath)) {
      final StringBuffer buf = StringBuffer();
      buf.writeln(userMessages.flutterBinariesDoNotRun);
      if (globals.platform.isLinux) {
        buf.writeln(userMessages.flutterBinariesLinuxRepairCommands);
      }
      messages.add(ValidationMessage.error(buf.toString()));
      valid = ValidationType.partial;
    }

    return ValidationResult(
      valid,
      messages,
      statusInfo: userMessages.flutterStatusInfo(
        versionChannel,
        frameworkVersion,
        globals.os.name,
        globals.platform.localeName,
      ),
    );
  }
}

bool _genSnapshotRuns(String genSnapshotPath) {
  const int kExpectedExitCode = 255;
  try {
    return processUtils.runSync(<String>[genSnapshotPath]).exitCode == kExpectedExitCode;
  } on Exception {
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
    if (globals.platform.isLinux || globals.platform.isWindows) {
      return IntelliJValidatorOnLinuxAndWindows.installed;
    }
    if (globals.platform.isMacOS) {
      return IntelliJValidatorOnMac.installed;
    }
    return <DoctorValidator>[];
  }

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];

    if (pluginsPath == null) {
      messages.add(const ValidationMessage.error('Invalid IntelliJ version number.'));
    } else {
      messages.add(ValidationMessage(userMessages.intellijLocation(installPath)));

      final IntelliJPlugins plugins = IntelliJPlugins(pluginsPath);
      plugins.validatePackage(messages, <String>['flutter-intellij', 'flutter-intellij.jar'],
          'Flutter', minVersion: IntelliJPlugins.kMinFlutterPluginVersion);
      plugins.validatePackage(messages, <String>['Dart'], 'Dart');

      if (_hasIssues(messages)) {
        messages.add(ValidationMessage(userMessages.intellijPluginInfo));
      }

      _validateIntelliJVersion(messages, kMinIdeaVersion);
    }

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
    if (minVersion == Version.unknown) {
      return;
    }

    final Version installedVersion = Version.parse(version);
    if (installedVersion == null) {
      return;
    }

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
    if (globals.fsUtils.homeDirPath == null) {
      return validators;
    }

    void addValidator(String title, String version, String installPath, String pluginsPath) {
      final IntelliJValidatorOnLinuxAndWindows validator =
        IntelliJValidatorOnLinuxAndWindows(title, version, installPath, pluginsPath);
      for (int index = 0; index < validators.length; ++index) {
        final DoctorValidator other = validators[index];
        if (other is IntelliJValidatorOnLinuxAndWindows && validator.installPath == other.installPath) {
          if (validator.version.compareTo(other.version) > 0) {
            validators[index] = validator;
          }
          return;
        }
      }
      validators.add(validator);
    }

    final Directory homeDir = globals.fs.directory(globals.fsUtils.homeDirPath);
    for (final Directory dir in homeDir.listSync().whereType<Directory>()) {
      final String name = globals.fs.path.basename(dir.path);
      IntelliJValidator._idToTitle.forEach((String id, String title) {
        if (name.startsWith('.$id')) {
          final String version = name.substring(id.length + 1);
          String installPath;
          try {
            installPath = globals.fs.file(globals.fs.path.join(dir.path, 'system', '.home')).readAsStringSync();
          } on Exception {
            // ignored
          }
          if (installPath != null && globals.fs.isDirectorySync(installPath)) {
            final String pluginsPath = globals.fs.path.join(dir.path, 'config', 'plugins');
            addValidator(title, version, installPath, pluginsPath);
          }
        }
      });
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
    final List<String> installPaths = <String>[
      '/Applications',
      globals.fs.path.join(globals.fsUtils.homeDirPath, 'Applications'),
    ];

    void checkForIntelliJ(Directory dir) {
      final String name = globals.fs.path.basename(dir.path);
      _dirNameToId.forEach((String dirName, String id) {
        if (name == dirName) {
          final String title = IntelliJValidator._idToTitle[id];
          validators.add(IntelliJValidatorOnMac(title, id, dir.path));
        }
      });
    }

    try {
      final Iterable<Directory> installDirs = installPaths
              .map<Directory>((String installPath) => globals.fs.directory(installPath))
              .map<List<FileSystemEntity>>((Directory dir) => dir.existsSync() ? dir.listSync() : <FileSystemEntity>[])
              .expand<FileSystemEntity>((List<FileSystemEntity> mappedDirs) => mappedDirs)
              .whereType<Directory>();
      for (final Directory dir in installDirs) {
        checkForIntelliJ(dir);
        if (!dir.path.endsWith('.app')) {
          for (final FileSystemEntity subdir in dir.listSync()) {
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

  @visibleForTesting
  String get plistFile {
    _plistFile ??= globals.fs.path.join(installPath, 'Contents', 'Info.plist');
    return _plistFile;
  }
  String _plistFile;

  @override
  String get version {
    _version ??= globals.plistParser.getValueFromFile(
        plistFile,
        PlistParser.kCFBundleShortVersionStringKey,
      ) ?? 'unknown';
    return _version;
  }
  String _version;

  @override
  String get pluginsPath {
    if (_pluginsPath != null) {
      return _pluginsPath;
    }

    final String altLocation = globals.plistParser
      .getValueFromFile(plistFile, 'JetBrainsToolboxApp');

    if (altLocation != null) {
      _pluginsPath = altLocation + '.plugins';
      return _pluginsPath;
    }

    final List<String> split = version.split('.');
    if (split.length < 2) {
      return null;
    }
    final String major = split[0];
    final String minor = split[1];

    final String homeDirPath = globals.fsUtils.homeDirPath;
    String pluginsPath = globals.fs.path.join(
      homeDirPath,
      'Library',
      'Application Support',
      'JetBrains',
      '$id$major.$minor',
      'plugins',
    );
    // Fallback to legacy location from < 2020.
    if (!globals.fs.isDirectorySync(pluginsPath)) {
      pluginsPath = globals.fs.path.join(
        homeDirPath,
        'Library',
        'Application Support',
        '$id$major.$minor',
      );
    }
    _pluginsPath = pluginsPath;

    return _pluginsPath;
  }
  String _pluginsPath;
}

class DeviceValidator extends DoctorValidator {
  // TODO(jmagman): Make required once g3 rolls and is updated.
  DeviceValidator({
    DeviceManager deviceManager,
    UserMessages userMessages,
  }) : _deviceManager = deviceManager ?? globals.deviceManager,
       _userMessages = userMessages ?? globals.userMessages,
       super('Connected device');

  final DeviceManager _deviceManager;
  final UserMessages _userMessages;

  @override
  String get slowWarning => 'Scanning for devices is taking a long time...';

  @override
  Future<ValidationResult> validate() async {
    final List<Device> devices = await _deviceManager.getAllConnectedDevices();
    List<ValidationMessage> installedMessages = <ValidationMessage>[];
    if (devices.isNotEmpty) {
      installedMessages = await Device.descriptions(devices)
          .map<ValidationMessage>((String msg) => ValidationMessage(msg)).toList();
    }

    List<ValidationMessage> diagnosticMessages = <ValidationMessage>[];
    final List<String> diagnostics = await _deviceManager.getDeviceDiagnostics();
    if (diagnostics.isNotEmpty) {
      diagnosticMessages = diagnostics.map<ValidationMessage>((String message) => ValidationMessage.hint(message)).toList();
    } else if (devices.isEmpty) {
      diagnosticMessages = <ValidationMessage>[ValidationMessage.hint(_userMessages.devicesMissing)];
    }

    if (devices.isEmpty) {
      return ValidationResult(ValidationType.notAvailable, diagnosticMessages);
    } else if (diagnostics.isNotEmpty) {
      installedMessages.addAll(diagnosticMessages);
      return ValidationResult(
        ValidationType.installed,
        installedMessages,
        statusInfo: _userMessages.devicesAvailable(devices.length)
      );
    } else {
      return ValidationResult(
        ValidationType.installed,
        installedMessages,
        statusInfo: _userMessages.devicesAvailable(devices.length)
      );
    }
  }
}

class ValidatorWithResult extends DoctorValidator {
  ValidatorWithResult(String title, this.result) : super(title);

  final ValidationResult result;

  @override
  Future<ValidationResult> validate() async => result;
}
