// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

part of reporting;

/// A generic usage even that does not involve custom dimensions.
///
/// If sending values for custom dimensions is required, extend this class as
/// below.
class UsageEvent {
  UsageEvent(this.category, this.parameter, {
    this.label,
    this.value,
    @required this.flutterUsage,
  });

  final String category;
  final String parameter;
  final String label;
  final int value;
  final Usage flutterUsage;

  void send() {
    flutterUsage.sendEvent(category, parameter, label: label, value: value);
  }
}

/// A usage event related to hot reload/restart.
///
/// On a successful hot reload, we collect stats that help understand scale of
/// the update. For example, [syncedLibraryCount]/[finalLibraryCount] indicates
/// how many libraries were affected by the hot reload request. Relation of
/// [invalidatedSourcesCount] to [syncedLibraryCount] should help understand
/// sync/transfer "overhead" of updating this number of source files.
class HotEvent extends UsageEvent {
  HotEvent(String parameter, {
    @required this.targetPlatform,
    @required this.sdkName,
    @required this.emulator,
    @required this.fullRestart,
    @required this.fastReassemble,
    this.reason,
    this.finalLibraryCount,
    this.syncedLibraryCount,
    this.syncedClassesCount,
    this.syncedProceduresCount,
    this.syncedBytes,
    this.invalidatedSourcesCount,
    this.transferTimeInMs,
    this.overallTimeInMs,
  }) : super('hot', parameter, flutterUsage: globals.flutterUsage);

  final String reason;
  final String targetPlatform;
  final String sdkName;
  final bool emulator;
  final bool fullRestart;
  final bool fastReassemble;
  final int finalLibraryCount;
  final int syncedLibraryCount;
  final int syncedClassesCount;
  final int syncedProceduresCount;
  final int syncedBytes;
  final int invalidatedSourcesCount;
  final int transferTimeInMs;
  final int overallTimeInMs;

  @override
  void send() {
    final Map<String, String> parameters = _useCdKeys(<CustomDimensions, String>{
      CustomDimensions.hotEventTargetPlatform: targetPlatform,
      CustomDimensions.hotEventSdkName: sdkName,
      CustomDimensions.hotEventEmulator: emulator.toString(),
      CustomDimensions.hotEventFullRestart: fullRestart.toString(),
      if (reason != null)
        CustomDimensions.hotEventReason: reason,
      if (finalLibraryCount != null)
        CustomDimensions.hotEventFinalLibraryCount: finalLibraryCount.toString(),
      if (syncedLibraryCount != null)
        CustomDimensions.hotEventSyncedLibraryCount: syncedLibraryCount.toString(),
      if (syncedClassesCount != null)
        CustomDimensions.hotEventSyncedClassesCount: syncedClassesCount.toString(),
      if (syncedProceduresCount != null)
        CustomDimensions.hotEventSyncedProceduresCount: syncedProceduresCount.toString(),
      if (syncedBytes != null)
        CustomDimensions.hotEventSyncedBytes: syncedBytes.toString(),
      if (invalidatedSourcesCount != null)
        CustomDimensions.hotEventInvalidatedSourcesCount: invalidatedSourcesCount.toString(),
      if (transferTimeInMs != null)
        CustomDimensions.hotEventTransferTimeInMs: transferTimeInMs.toString(),
      if (overallTimeInMs != null)
        CustomDimensions.hotEventOverallTimeInMs: overallTimeInMs.toString(),
      if (fastReassemble != null)
        CustomDimensions.fastReassemble: fastReassemble.toString(),
    });
    flutterUsage.sendEvent(category, parameter, parameters: parameters);
  }
}

/// An event that reports the result of a [DoctorValidator]
class DoctorResultEvent extends UsageEvent {
  DoctorResultEvent({
    @required this.validator,
    @required this.result,
    Usage flutterUsage,
  }) : super(
    'doctor-result',
    '${validator.runtimeType}',
    label: result.typeStr,
    flutterUsage: flutterUsage ?? globals.flutterUsage,
  );

  final DoctorValidator validator;
  final ValidationResult result;

  @override
  void send() {
    if (validator is! GroupedValidator) {
      flutterUsage.sendEvent(category, parameter, label: label);
      return;
    }
    final GroupedValidator group = validator as GroupedValidator;
    // The validator crashed.
    if (group.subResults.isEmpty) {
      flutterUsage.sendEvent(category, parameter, label: label);
      return;
    }
    for (int i = 0; i < group.subValidators.length; i++) {
      final DoctorValidator v = group.subValidators[i];
      final ValidationResult r = group.subResults[i];
      DoctorResultEvent(validator: v, result: r, flutterUsage: flutterUsage).send();
    }
  }
}

/// An event that reports on the result of a pub invocation.
class PubResultEvent extends UsageEvent {
  PubResultEvent({
    @required String context,
    @required String result,
    @required Usage usage,
  }) : super('pub-result', context, label: result, flutterUsage: usage);
}

/// An event that reports something about a build.
class BuildEvent extends UsageEvent {
  BuildEvent(String label, {
    String command,
    String settings,
    String eventError,
    @required Usage flutterUsage,
  }) : _command = command,
  _settings = settings,
  _eventError = eventError,
      super(
    // category
    'build',
    // parameter
    FlutterCommand.current == null
      ? 'unspecified'
      : FlutterCommand.current.name,
    label: label,
    flutterUsage: flutterUsage,
  );

  final String _command;
  final String _settings;
  final String _eventError;

  @override
  void send() {
    final Map<String, String> parameters = _useCdKeys(<CustomDimensions, String>{
      if (_command != null)
        CustomDimensions.buildEventCommand: _command,
      if (_settings != null)
        CustomDimensions.buildEventSettings: _settings,
      if (_eventError != null)
        CustomDimensions.buildEventError: _eventError,
    });
    flutterUsage.sendEvent(
      category,
      parameter,
      label: label,
      parameters: parameters,
    );
  }
}

/// An event that reports the result of a top-level command.
class CommandResultEvent extends UsageEvent {
  CommandResultEvent(String commandPath, FlutterCommandResult result)
      : assert(commandPath != null),
        assert(result != null),
        super(commandPath, result.toString(), flutterUsage: globals.flutterUsage);

  @override
  void send() {
    // An event for the command result.
    flutterUsage.sendEvent(
      'tool-command-result',
      category,
      label: parameter,
    );

    // A separate event for the memory highwater mark. This is a separate event
    // so that we can get the command result even if trying to grab maxRss
    // throws an exception.
    try {
      final int maxRss = globals.processInfo.maxRss;
      flutterUsage.sendEvent(
        'tool-command-max-rss',
        category,
        label: parameter,
        value: maxRss,
      );
    } on Exception catch (error) {
      // If grabbing the maxRss fails for some reason, just don't send an event.
      globals.printTrace('Querying maxRss failed with error: $error');
    }
  }
}

/// An event that reports on changes in the configuration of analytics.
class AnalyticsConfigEvent extends UsageEvent {
  AnalyticsConfigEvent({
    /// Whether analytics reporting is being enabled (true) or disabled (false).
    @required bool enabled,
  }) : super(
    'analytics',
    'enabled',
    label: enabled ? 'true' : 'false',
    flutterUsage: globals.flutterUsage,
  );
}

/// An event that reports when the code size measurement is run via `--analyze-size`.
class CodeSizeEvent extends UsageEvent {
  CodeSizeEvent(String platform, {
    @required Usage flutterUsage,
  }) : super(
    'code-size-analysis',
    platform,
    flutterUsage: flutterUsage ?? globals.flutterUsage,
  );
}

/// An event for tracking the usage of specific error handling fallbacks.
class ErrorHandlingEvent extends UsageEvent {
  ErrorHandlingEvent(String parameter) : super('error-handling', parameter, flutterUsage: globals.flutterUsage);
}

/// Emit various null safety analytic events.
///
/// 1. The current null safety runtime mode.
/// 2. The number of packages that are migrated, along with the total number of packages
/// 3. The main packages language version.
class NullSafetyAnalysisEvent implements UsageEvent {
  NullSafetyAnalysisEvent(
    this.packageConfig,
    this.nullSafetyMode,
    this.currentPackage,
    this.flutterUsage,
  );

  /// The category for analytics events related to null safety.
  static const String kNullSafetyCategory = 'null-safety';

  final PackageConfig packageConfig;
  final NullSafetyMode nullSafetyMode;
  final String currentPackage;
  @override
  final Usage flutterUsage;

  @override
  void send() {
    if (packageConfig.packages.isEmpty) {
      return;
    }
    int migrated = 0;
    LanguageVersion languageVersion;
    for (final Package package in packageConfig.packages) {
      if (package.name == currentPackage) {
        languageVersion = package.languageVersion;
      }
      if (package.languageVersion != null &&
          package.languageVersion.major >= nullSafeVersion.major &&
          package.languageVersion.minor >= nullSafeVersion.minor) {
        migrated += 1;
      }
    }
    flutterUsage.sendEvent(kNullSafetyCategory, 'runtime-mode', label: nullSafetyMode.toString());
    flutterUsage.sendEvent(kNullSafetyCategory, 'stats', parameters: <String, String>{
      cdKey(CustomDimensions.nullSafeMigratedLibraries): migrated.toString(),
      cdKey(CustomDimensions.nullSafeTotalLibraries): packageConfig.packages.length.toString(),
    });
    if (languageVersion != null) {
      final String formattedVersion = '${languageVersion.major}.${languageVersion.minor}';
      flutterUsage.sendEvent(kNullSafetyCategory, 'language-version', label: formattedVersion);
    }
  }

  @override
  String get category => kNullSafetyCategory;

  @override
  String get label => throw UnsupportedError('');

  @override
  String get parameter => throw UnsupportedError('');

  @override
  int get value => throw UnsupportedError('');
}
