// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import 'android/android_studio_validator.dart';
import 'android/android_workflow.dart';
import 'artifacts.dart';
import 'base/async_guard.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/os.dart';
import 'base/platform.dart';
import 'base/terminal.dart';
import 'base/user_messages.dart';
import 'base/utils.dart';
import 'cache.dart';
import 'device.dart';
import 'features.dart';
import 'fuchsia/fuchsia_workflow.dart';
import 'globals.dart' as globals;
import 'intellij/intellij_validator.dart';
import 'linux/linux_doctor.dart';
import 'linux/linux_workflow.dart';
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
      if (androidWorkflow.appliesToHostPlatform)
        ...AndroidStudioValidator.allValidators(globals.config, globals.platform, globals.fs, globals.userMessages),
      ...IntelliJValidator.installedValidators(
        fileSystem: globals.fs,
        platform: globals.platform,
        userMessages: userMessages,
        plistParser: globals.plistParser,
      ),
      ...VsCodeValidator.installedValidators(globals.fs, globals.platform),
    ];
    final ProxyValidator proxyValidator = ProxyValidator(platform: globals.platform);
    _validators = <DoctorValidator>[
      FlutterValidator(
        fileSystem: globals.fs,
        platform: globals.platform,
        flutterVersion: () => globals.flutterVersion,
        processManager: globals.processManager,
        userMessages: userMessages,
        artifacts: globals.artifacts,
        flutterRoot: () => Cache.flutterRoot,
        operatingSystemUtils: globals.os,
      ),
      if (androidWorkflow.appliesToHostPlatform)
        GroupedValidator(<DoctorValidator>[androidValidator, androidLicenseValidator]),
      if (globals.iosWorkflow.appliesToHostPlatform || macOSWorkflow.appliesToHostPlatform)
        GroupedValidator(<DoctorValidator>[XcodeValidator(xcode: globals.xcode, userMessages: userMessages), globals.cocoapodsValidator]),
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
          if (message.contextUrl != null) {
            _logger.printStatus('🔨 ${message.contextUrl}', hangingIndent: hangingIndent, indent: indent, emphasis: true);
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
  final String contextUrl;
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
    return other is ValidationMessage
        && other.message == message
        && other.type == type
        && other.contextUrl == contextUrl;
  }

  @override
  int get hashCode => type.hashCode ^ message.hashCode ^ contextUrl.hashCode;
}

/// A validator that checks the version of Flutter, as well as some auxiliary information
/// such as the pub or Flutter cache overrides.
///
/// This is primarily useful for diagnosing issues on Github bug reports by displaying
/// specific commit information.
class FlutterValidator extends DoctorValidator {
  FlutterValidator({
    @required Platform platform,
    @required FlutterVersion Function() flutterVersion,
    @required UserMessages userMessages,
    @required FileSystem fileSystem,
    @required Artifacts artifacts,
    @required ProcessManager processManager,
    @required String Function() flutterRoot,
    @required OperatingSystemUtils operatingSystemUtils,
  }) : _flutterVersion = flutterVersion,
       _platform = platform,
       _userMessages = userMessages,
       _fileSystem = fileSystem,
       _artifacts = artifacts,
       _processManager = processManager,
       _flutterRoot = flutterRoot,
       _operatingSystemUtils = operatingSystemUtils,
       super('Flutter');

  final Platform _platform;
  final FlutterVersion Function() _flutterVersion;
  final String Function() _flutterRoot;
  final UserMessages _userMessages;
  final FileSystem _fileSystem;
  final Artifacts _artifacts;
  final ProcessManager _processManager;
  final OperatingSystemUtils _operatingSystemUtils;

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    ValidationType valid = ValidationType.installed;
    String versionChannel;
    String frameworkVersion;

    try {
      final FlutterVersion version = _flutterVersion();
      versionChannel = version.channel;
      frameworkVersion = version.frameworkVersion;
      messages.add(ValidationMessage(_userMessages.flutterVersion(
        frameworkVersion,
        _flutterRoot(),
      )));
      messages.add(ValidationMessage(_userMessages.flutterRevision(
        version.frameworkRevisionShort,
        version.frameworkAge,
        version.frameworkDate,
      )));
      messages.add(ValidationMessage(_userMessages.engineRevision(version.engineRevisionShort)));
      messages.add(ValidationMessage(_userMessages.dartRevision(version.dartSdkVersion)));
      if (_platform.environment.containsKey('PUB_HOSTED_URL')) {
        messages.add(ValidationMessage(_userMessages.pubMirrorURL(_platform.environment['PUB_HOSTED_URL'])));
      }
      if (_platform.environment.containsKey('FLUTTER_STORAGE_BASE_URL')) {
        messages.add(ValidationMessage(_userMessages.flutterMirrorURL(_platform.environment['FLUTTER_STORAGE_BASE_URL'])));
      }
    } on VersionCheckError catch (e) {
      messages.add(ValidationMessage.error(e.message));
      valid = ValidationType.partial;
    }

    // Check that the binaries we downloaded for this platform actually run on it.
    // If the binaries are not downloaded (because android is not enabled), then do
    // not run this check.
    final String genSnapshotPath = _artifacts.getArtifactPath(Artifact.genSnapshot);
    if (_fileSystem.file(genSnapshotPath).existsSync() && !_genSnapshotRuns(genSnapshotPath)) {
      final StringBuffer buffer = StringBuffer();
      buffer.writeln(_userMessages.flutterBinariesDoNotRun);
      if (_platform.isLinux) {
        buffer.writeln(_userMessages.flutterBinariesLinuxRepairCommands);
      }
      messages.add(ValidationMessage.error(buffer.toString()));
      valid = ValidationType.partial;
    }

    return ValidationResult(
      valid,
      messages,
      statusInfo: _userMessages.flutterStatusInfo(
        versionChannel,
        frameworkVersion,
        _operatingSystemUtils.name,
        _platform.localeName,
      ),
    );
  }

  bool _genSnapshotRuns(String genSnapshotPath) {
    const int kExpectedExitCode = 255;
    try {
      return _processManager.runSync(<String>[genSnapshotPath]).exitCode == kExpectedExitCode;
    } on Exception {
      return false;
    }
  }
}

class NoIdeValidator extends DoctorValidator {
  NoIdeValidator() : super('Flutter IDE Support');

  @override
  Future<ValidationResult> validate() async {
    return ValidationResult(
      ValidationType.missing,
      userMessages.noIdeInstallationInfo.map((String ideInfo) => ValidationMessage(ideInfo)).toList(),
      statusInfo: userMessages.noIdeStatusInfo,
    );
  }
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
