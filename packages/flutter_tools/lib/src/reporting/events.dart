// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of reporting;

/// A generic usage even that does not involve custom dimensions.
///
/// If sending values for custom dimensions is required, extend this class as
/// below.
class UsageEvent {
  UsageEvent(this.category, this.parameter, {
    this.label,
  });

  final String category;
  final String parameter;
  final String label;

  void send() {
    flutterUsage.sendEvent(category, parameter, label: label);
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
    this.reason,
    this.finalLibraryCount,
    this.syncedLibraryCount,
    this.syncedClassesCount,
    this.syncedProceduresCount,
    this.syncedBytes,
    this.invalidatedSourcesCount,
    this.transferTimeInMs,
    this.overallTimeInMs,
  }) : super('hot', parameter);

  final String reason;
  final String targetPlatform;
  final String sdkName;
  final bool emulator;
  final bool fullRestart;
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
    });
    flutterUsage.sendEvent(category, parameter, parameters: parameters);
  }
}

/// An event that reports the result of a [DoctorValidator]
class DoctorResultEvent extends UsageEvent {
  DoctorResultEvent({
    @required this.validator,
    @required this.result,
  }) : super('doctorResult.${validator.runtimeType}',
             result.typeStr);

  final DoctorValidator validator;
  final ValidationResult result;

  @override
  void send() {
    if (validator is! GroupedValidator) {
      flutterUsage.sendEvent(category, parameter, label: label);
      return;
    }
    final GroupedValidator group = validator;
    for (int i = 0; i < group.subValidators.length; i++) {
      final DoctorValidator v = group.subValidators[i];
      final ValidationResult r = group.subResults[i];
      DoctorResultEvent(validator: v, result: r).send();
    }
  }
}

/// An event that reports success or failure of a pub get.
class PubResultEvent extends UsageEvent {
  PubResultEvent({
    @required String context,
    @required String result,
  }) : super('pub', context, label: result);
}

/// An event that reports something about a build.
class BuildEvent extends UsageEvent {
  BuildEvent(String parameter, {
    this.command,
    this.settings,
    this.eventError,
  }) : super(
    'build' +
      (FlutterCommand.current == null ? '' : '-${FlutterCommand.current.name}'),
    parameter);

  final String command;
  final String settings;
  final String eventError;

  @override
  void send() {
    final Map<String, String> parameters = _useCdKeys(<CustomDimensions, String>{
      if (command != null)
        CustomDimensions.buildEventCommand: command,
      if (settings != null)
        CustomDimensions.buildEventSettings: settings,
      if (eventError != null)
        CustomDimensions.buildEventError: eventError,
    });
    flutterUsage.sendEvent(category, parameter, parameters: parameters);
  }
}

/// An event that reports the result of a top-level command.
class CommandResultEvent extends UsageEvent {
  CommandResultEvent(String commandPath, FlutterCommandResult result)
      : super(commandPath, result?.toString() ?? 'unspecified');

  @override
  void send() {
    int maxRss;
    try {
      maxRss = processInfo.maxRss;
    } catch (e) {
      // If grabbing the maxRss fails for some reason, just leave it off the
      // event.
    }
    final Map<String, String> parameters = _useCdKeys(<CustomDimensions, String>{
      if (maxRss != null)
        CustomDimensions.commandResultEventMaxRss: maxRss.toString(),
    });
    flutterUsage.sendEvent(category, parameter, parameters: parameters);
  }
}
