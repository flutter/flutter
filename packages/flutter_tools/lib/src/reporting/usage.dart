// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of reporting;

const String _kFlutterUA = 'UA-67589403-6';

/// The collection of custom dimensions understood by the analytics backend.
/// When adding to this list, first ensure that the custom dimension is
/// defined in the backend, or will be defined shortly after the relevant PR
/// lands.
class CustomDimensions {
  final String? sessionHostOsDetails;
  final String? sessionChannelName;
  final bool? commandRunIsEmulator;
  final String? commandRunTargetName;
  final String? hotEventReason;
  final int? hotEventFinalLibraryCount;
  final int? hotEventSyncedLibraryCount;
  final int? hotEventSyncedClassesCount;
  final int? hotEventSyncedProceduresCount;
  final int? hotEventSyncedBytes;
  final int? hotEventInvalidatedSourcesCount;
  final int? hotEventTransferTimeInMs;
  final int? hotEventOverallTimeInMs;
  final String? commandRunProjectType; // unused
  final String? commandRunProjectHostLanguage;
  final String? commandCreateAndroidLanguage;
  final String? commandCreateIosLanguage;
  final bool? commandRunProjectModule;
  final String? commandCreateProjectType;
  final int? commandPackagesNumberPlugins;
  final bool? commandPackagesProjectModule;
  final String? commandRunTargetOsVersion;
  final String? commandRunModeName;
  final String? commandBuildBundleTargetPlatform;
  final bool? commandBuildBundleIsModule;
  final String? commandResult; // unused
  final String? hotEventTargetPlatform;
  final String? hotEventSdkName;
  final bool? hotEventEmulator;
  final bool? hotEventFullRestart;
  final bool? commandHasTerminal;
  final String? enabledFlutterFeatures;
  final String? localTime;
  final String? commandBuildAarTargetPlatform;
  final String? commandBuildAarProjectType;
  final String? buildEventCommand;
  final String? buildEventSettings;
  final String? commandBuildApkTargetPlatform;
  final String? commandBuildApkBuildMode;
  final bool? commandBuildApkSplitPerAbi;
  final String? commandBuildAppBundleTargetPlatform;
  final String? commandBuildAppBundleBuildMode;
  final String? buildEventError;
  final String? commandResultEventMaxRss; // unused
  final String? commandRunAndroidEmbeddingVersion;
  final String? commandPackagesAndroidEmbeddingVersion;
  final bool? nullSafety; // unused?
  final bool? fastReassemble;
  final int? nullSafeMigratedLibraries;
  final int? nullSafeTotalLibraries;

  const CustomDimensions({
    this.sessionHostOsDetails = null,
    this.sessionChannelName = null,
    this.commandRunIsEmulator = null,
    this.commandRunTargetName = null,
    this.hotEventReason = null,
    this.hotEventFinalLibraryCount = null,
    this.hotEventSyncedLibraryCount = null,
    this.hotEventSyncedClassesCount = null,
    this.hotEventSyncedProceduresCount = null,
    this.hotEventSyncedBytes = null,
    this.hotEventInvalidatedSourcesCount = null,
    this.hotEventTransferTimeInMs = null,
    this.hotEventOverallTimeInMs = null,
    this.commandRunProjectType = null,
    this.commandRunProjectHostLanguage = null,
    this.commandCreateAndroidLanguage = null,
    this.commandCreateIosLanguage = null,
    this.commandRunProjectModule = null,
    this.commandCreateProjectType = null,
    this.commandPackagesNumberPlugins = null,
    this.commandPackagesProjectModule = null,
    this.commandRunTargetOsVersion = null,
    this.commandRunModeName = null,
    this.commandBuildBundleTargetPlatform = null,
    this.commandBuildBundleIsModule = null,
    this.commandResult = null,
    this.hotEventTargetPlatform = null,
    this.hotEventSdkName = null,
    this.hotEventEmulator = null,
    this.hotEventFullRestart = null,
    this.commandHasTerminal = null,
    this.enabledFlutterFeatures = null,
    this.localTime = null,
    this.commandBuildAarTargetPlatform = null,
    this.commandBuildAarProjectType = null,
    this.buildEventCommand = null,
    this.buildEventSettings = null,
    this.commandBuildApkTargetPlatform = null,
    this.commandBuildApkBuildMode = null,
    this.commandBuildApkSplitPerAbi = null,
    this.commandBuildAppBundleTargetPlatform = null,
    this.commandBuildAppBundleBuildMode = null,
    this.buildEventError = null,
    this.commandResultEventMaxRss = null,
    this.commandRunAndroidEmbeddingVersion = null,
    this.commandPackagesAndroidEmbeddingVersion = null,
    this.nullSafety = null,
    this.fastReassemble = null,
    this.nullSafeMigratedLibraries = null,
    this.nullSafeTotalLibraries = null,
  });

  /// Convert to a map that will be used to upload to the analytics backend.
  Map<String, String> toMap() {
    return {
      if (sessionHostOsDetails != null) cdKey(CustomDimensionsEnum.sessionHostOsDetails): sessionHostOsDetails.toString(),
      if (sessionChannelName != null) cdKey(CustomDimensionsEnum.sessionChannelName): sessionChannelName.toString(),
      if (commandRunIsEmulator != null) cdKey(CustomDimensionsEnum.commandRunIsEmulator): commandRunIsEmulator.toString(),
      if (commandRunTargetName != null) cdKey(CustomDimensionsEnum.commandRunTargetName): commandRunTargetName.toString(),
      if (hotEventReason != null) cdKey(CustomDimensionsEnum.hotEventReason): hotEventReason.toString(),
      if (hotEventFinalLibraryCount != null) cdKey(CustomDimensionsEnum.hotEventFinalLibraryCount): hotEventFinalLibraryCount.toString(),
      if (hotEventSyncedLibraryCount != null) cdKey(CustomDimensionsEnum.hotEventSyncedLibraryCount): hotEventSyncedLibraryCount.toString(),
      if (hotEventSyncedClassesCount != null) cdKey(CustomDimensionsEnum.hotEventSyncedClassesCount): hotEventSyncedClassesCount.toString(),
      if (hotEventSyncedProceduresCount != null) cdKey(CustomDimensionsEnum.hotEventSyncedProceduresCount): hotEventSyncedProceduresCount.toString(),
      if (hotEventSyncedBytes != null) cdKey(CustomDimensionsEnum.hotEventSyncedBytes): hotEventSyncedBytes.toString(),
      if (hotEventInvalidatedSourcesCount != null) cdKey(CustomDimensionsEnum.hotEventInvalidatedSourcesCount): hotEventInvalidatedSourcesCount.toString(),
      if (hotEventTransferTimeInMs != null) cdKey(CustomDimensionsEnum.hotEventTransferTimeInMs): hotEventTransferTimeInMs.toString(),
      if (hotEventOverallTimeInMs != null) cdKey(CustomDimensionsEnum.hotEventOverallTimeInMs): hotEventOverallTimeInMs.toString(),
      if (commandRunProjectType != null) cdKey(CustomDimensionsEnum.commandRunProjectType): commandRunProjectType.toString(),
      if (commandRunProjectHostLanguage != null) cdKey(CustomDimensionsEnum.commandRunProjectHostLanguage): commandRunProjectHostLanguage.toString(),
      if (commandCreateAndroidLanguage != null) cdKey(CustomDimensionsEnum.commandCreateAndroidLanguage): commandCreateAndroidLanguage.toString(),
      if (commandCreateIosLanguage != null) cdKey(CustomDimensionsEnum.commandCreateIosLanguage): commandCreateIosLanguage.toString(),
      if (commandRunProjectModule != null) cdKey(CustomDimensionsEnum.commandRunProjectModule): commandRunProjectModule.toString(),
      if (commandCreateProjectType != null) cdKey(CustomDimensionsEnum.commandCreateProjectType): commandCreateProjectType.toString(),
      if (commandPackagesNumberPlugins != null) cdKey(CustomDimensionsEnum.commandPackagesNumberPlugins): commandPackagesNumberPlugins.toString(),
      if (commandPackagesProjectModule != null) cdKey(CustomDimensionsEnum.commandPackagesProjectModule): commandPackagesProjectModule.toString(),
      if (commandRunTargetOsVersion != null) cdKey(CustomDimensionsEnum.commandRunTargetOsVersion): commandRunTargetOsVersion.toString(),
      if (commandRunModeName != null) cdKey(CustomDimensionsEnum.commandRunModeName): commandRunModeName.toString(),
      if (commandBuildBundleTargetPlatform != null) cdKey(CustomDimensionsEnum.commandBuildBundleTargetPlatform): commandBuildBundleTargetPlatform.toString(),
      if (commandBuildBundleIsModule != null) cdKey(CustomDimensionsEnum.commandBuildBundleIsModule): commandBuildBundleIsModule.toString(),
      if (commandResult != null) cdKey(CustomDimensionsEnum.commandResult): commandResult.toString(),
      if (hotEventTargetPlatform != null) cdKey(CustomDimensionsEnum.hotEventTargetPlatform): hotEventTargetPlatform.toString(),
      if (hotEventSdkName != null) cdKey(CustomDimensionsEnum.hotEventSdkName): hotEventSdkName.toString(),
      if (hotEventEmulator != null) cdKey(CustomDimensionsEnum.hotEventEmulator): hotEventEmulator.toString(),
      if (hotEventFullRestart != null) cdKey(CustomDimensionsEnum.hotEventFullRestart): hotEventFullRestart.toString(),
      if (commandHasTerminal != null) cdKey(CustomDimensionsEnum.commandHasTerminal): commandHasTerminal.toString(),
      if (enabledFlutterFeatures != null) cdKey(CustomDimensionsEnum.enabledFlutterFeatures): enabledFlutterFeatures.toString(),
      if (localTime != null) cdKey(CustomDimensionsEnum.localTime): localTime.toString(),
      if (commandBuildAarTargetPlatform != null) cdKey(CustomDimensionsEnum.commandBuildAarTargetPlatform): commandBuildAarTargetPlatform.toString(),
      if (commandBuildAarProjectType != null) cdKey(CustomDimensionsEnum.commandBuildAarProjectType): commandBuildAarProjectType.toString(),
      if (buildEventCommand != null) cdKey(CustomDimensionsEnum.buildEventCommand): buildEventCommand.toString(),
      if (buildEventSettings != null) cdKey(CustomDimensionsEnum.buildEventSettings): buildEventSettings.toString(),
      if (commandBuildApkTargetPlatform != null) cdKey(CustomDimensionsEnum.commandBuildApkTargetPlatform): commandBuildApkTargetPlatform.toString(),
      if (commandBuildApkBuildMode != null) cdKey(CustomDimensionsEnum.commandBuildApkBuildMode): commandBuildApkBuildMode.toString(),
      if (commandBuildApkSplitPerAbi != null) cdKey(CustomDimensionsEnum.commandBuildApkSplitPerAbi): commandBuildApkSplitPerAbi.toString(),
      if (commandBuildAppBundleTargetPlatform != null) cdKey(CustomDimensionsEnum.commandBuildAppBundleTargetPlatform): commandBuildAppBundleTargetPlatform.toString(),
      if (commandBuildAppBundleBuildMode != null) cdKey(CustomDimensionsEnum.commandBuildAppBundleBuildMode): commandBuildAppBundleBuildMode.toString(),
      if (buildEventError != null) cdKey(CustomDimensionsEnum.buildEventError): buildEventError.toString(),
      if (commandResultEventMaxRss != null) cdKey(CustomDimensionsEnum.commandResultEventMaxRss): commandResultEventMaxRss.toString(),
      if (commandRunAndroidEmbeddingVersion != null) cdKey(CustomDimensionsEnum.commandRunAndroidEmbeddingVersion): commandRunAndroidEmbeddingVersion.toString(),
      if (commandPackagesAndroidEmbeddingVersion != null) cdKey(CustomDimensionsEnum.commandPackagesAndroidEmbeddingVersion): commandPackagesAndroidEmbeddingVersion.toString(),
      if (nullSafety != null) cdKey(CustomDimensionsEnum.nullSafety): nullSafety.toString(),
      if (fastReassemble != null) cdKey(CustomDimensionsEnum.fastReassemble): fastReassemble.toString(),
      if (nullSafeMigratedLibraries != null) cdKey(CustomDimensionsEnum.nullSafeMigratedLibraries): nullSafeMigratedLibraries.toString(),
      if (nullSafeTotalLibraries != null) cdKey(CustomDimensionsEnum.nullSafeTotalLibraries): nullSafeTotalLibraries.toString(),
    };
  }

  /// Merge the values of two [CustomDimensions] into one. If a value is defined
  /// in both instances, the value in [other] will override the value in this.
  CustomDimensions merge(CustomDimensions? other) {
    if (other == null) {
      return this;
    }

    return CustomDimensions(
      sessionHostOsDetails: other.sessionHostOsDetails ?? sessionHostOsDetails,
      sessionChannelName: other.sessionChannelName ?? sessionChannelName,
      commandRunIsEmulator: other.commandRunIsEmulator ?? commandRunIsEmulator,
      commandRunTargetName: other.commandRunTargetName ?? commandRunTargetName,
      hotEventReason: other.hotEventReason ?? hotEventReason,
      hotEventFinalLibraryCount: other.hotEventFinalLibraryCount ?? hotEventFinalLibraryCount,
      hotEventSyncedLibraryCount: other.hotEventSyncedLibraryCount ?? hotEventSyncedLibraryCount,
      hotEventSyncedClassesCount: other.hotEventSyncedClassesCount ?? hotEventSyncedClassesCount,
      hotEventSyncedProceduresCount: other.hotEventSyncedProceduresCount ?? hotEventSyncedProceduresCount,
      hotEventSyncedBytes: other.hotEventSyncedBytes ?? hotEventSyncedBytes,
      hotEventInvalidatedSourcesCount: other.hotEventInvalidatedSourcesCount ?? hotEventInvalidatedSourcesCount,
      hotEventTransferTimeInMs: other.hotEventTransferTimeInMs ?? hotEventTransferTimeInMs,
      hotEventOverallTimeInMs: other.hotEventOverallTimeInMs ?? hotEventOverallTimeInMs,
      commandRunProjectType: other.commandRunProjectType ?? commandRunProjectType,
      commandRunProjectHostLanguage: other.commandRunProjectHostLanguage ?? commandRunProjectHostLanguage,
      commandCreateAndroidLanguage: other.commandCreateAndroidLanguage ?? commandCreateAndroidLanguage,
      commandCreateIosLanguage: other.commandCreateIosLanguage ?? commandCreateIosLanguage,
      commandRunProjectModule: other.commandRunProjectModule ?? commandRunProjectModule,
      commandCreateProjectType: other.commandCreateProjectType ?? commandCreateProjectType,
      commandPackagesNumberPlugins: other.commandPackagesNumberPlugins ?? commandPackagesNumberPlugins,
      commandPackagesProjectModule: other.commandPackagesProjectModule ?? commandPackagesProjectModule,
      commandRunTargetOsVersion: other.commandRunTargetOsVersion ?? commandRunTargetOsVersion,
      commandRunModeName: other.commandRunModeName ?? commandRunModeName,
      commandBuildBundleTargetPlatform: other.commandBuildBundleTargetPlatform ?? commandBuildBundleTargetPlatform,
      commandBuildBundleIsModule: other.commandBuildBundleIsModule ?? commandBuildBundleIsModule,
      commandResult: other.commandResult ?? commandResult,
      hotEventTargetPlatform: other.hotEventTargetPlatform ?? hotEventTargetPlatform,
      hotEventSdkName: other.hotEventSdkName ?? hotEventSdkName,
      hotEventEmulator: other.hotEventEmulator ?? hotEventEmulator,
      hotEventFullRestart: other.hotEventFullRestart ?? hotEventFullRestart,
      commandHasTerminal: other.commandHasTerminal ?? commandHasTerminal,
      enabledFlutterFeatures: other.enabledFlutterFeatures ?? enabledFlutterFeatures,
      localTime: other.localTime ?? localTime,
      commandBuildAarTargetPlatform: other.commandBuildAarTargetPlatform ?? commandBuildAarTargetPlatform,
      commandBuildAarProjectType: other.commandBuildAarProjectType ?? commandBuildAarProjectType,
      buildEventCommand: other.buildEventCommand ?? buildEventCommand,
      buildEventSettings: other.buildEventSettings ?? buildEventSettings,
      commandBuildApkTargetPlatform: other.commandBuildApkTargetPlatform ?? commandBuildApkTargetPlatform,
      commandBuildApkBuildMode: other.commandBuildApkBuildMode ?? commandBuildApkBuildMode,
      commandBuildApkSplitPerAbi: other.commandBuildApkSplitPerAbi ?? commandBuildApkSplitPerAbi,
      commandBuildAppBundleTargetPlatform: other.commandBuildAppBundleTargetPlatform ?? commandBuildAppBundleTargetPlatform,
      commandBuildAppBundleBuildMode: other.commandBuildAppBundleBuildMode ?? commandBuildAppBundleBuildMode,
      buildEventError: other.buildEventError ?? buildEventError,
      commandResultEventMaxRss: other.commandResultEventMaxRss ?? commandResultEventMaxRss,
      commandRunAndroidEmbeddingVersion: other.commandRunAndroidEmbeddingVersion ?? commandRunAndroidEmbeddingVersion,
      commandPackagesAndroidEmbeddingVersion: other.commandPackagesAndroidEmbeddingVersion ?? commandPackagesAndroidEmbeddingVersion,
      nullSafety: other.nullSafety ?? nullSafety,
      fastReassemble: other.fastReassemble ?? fastReassemble,
      nullSafeMigratedLibraries: other.nullSafeMigratedLibraries ?? nullSafeMigratedLibraries,
      nullSafeTotalLibraries: other.nullSafeTotalLibraries ?? nullSafeTotalLibraries,
    );
  }

  factory CustomDimensions.fromMap(Map<String, String> map) => CustomDimensions(
      sessionHostOsDetails: (map.containsKey(cdKey(CustomDimensionsEnum.sessionHostOsDetails)))? map[cdKey(CustomDimensionsEnum.sessionHostOsDetails)] : null,
      sessionChannelName: (map.containsKey(cdKey(CustomDimensionsEnum.sessionChannelName)))? map[cdKey(CustomDimensionsEnum.sessionChannelName)] : null,
      commandRunIsEmulator: (map.containsKey(cdKey(CustomDimensionsEnum.commandRunIsEmulator)))? map[cdKey(CustomDimensionsEnum.commandRunIsEmulator)] == 'true' : null,
      commandRunTargetName: (map.containsKey(cdKey(CustomDimensionsEnum.commandRunTargetName)))? map[cdKey(CustomDimensionsEnum.commandRunTargetName)] : null,
      hotEventReason: (map.containsKey(cdKey(CustomDimensionsEnum.hotEventReason)))? map[cdKey(CustomDimensionsEnum.hotEventReason)] : null,
      hotEventFinalLibraryCount: (map.containsKey(cdKey(CustomDimensionsEnum.hotEventFinalLibraryCount)))? int.parse(map[cdKey(CustomDimensionsEnum.hotEventFinalLibraryCount)]!) : null,
      hotEventSyncedLibraryCount: (map.containsKey(cdKey(CustomDimensionsEnum.hotEventSyncedLibraryCount)))? int.parse(map[cdKey(CustomDimensionsEnum.hotEventSyncedLibraryCount)]!) : null,
      hotEventSyncedClassesCount: (map.containsKey(cdKey(CustomDimensionsEnum.hotEventSyncedClassesCount)))? int.parse(map[cdKey(CustomDimensionsEnum.hotEventSyncedClassesCount)]!) : null,
      hotEventSyncedProceduresCount: (map.containsKey(cdKey(CustomDimensionsEnum.hotEventSyncedProceduresCount)))? int.parse(map[cdKey(CustomDimensionsEnum.hotEventSyncedProceduresCount)]!) : null,
      hotEventSyncedBytes: (map.containsKey(cdKey(CustomDimensionsEnum.hotEventSyncedBytes)))? int.parse(map[cdKey(CustomDimensionsEnum.hotEventSyncedBytes)]!) : null,
      hotEventInvalidatedSourcesCount: (map.containsKey(cdKey(CustomDimensionsEnum.hotEventInvalidatedSourcesCount)))? int.parse(map[cdKey(CustomDimensionsEnum.hotEventInvalidatedSourcesCount)]!) : null,
      hotEventTransferTimeInMs: (map.containsKey(cdKey(CustomDimensionsEnum.hotEventTransferTimeInMs)))? int.parse(map[cdKey(CustomDimensionsEnum.hotEventTransferTimeInMs)]!) : null,
      hotEventOverallTimeInMs: (map.containsKey(cdKey(CustomDimensionsEnum.hotEventOverallTimeInMs)))? int.parse(map[cdKey(CustomDimensionsEnum.hotEventOverallTimeInMs)]!) : null,
      commandRunProjectType: (map.containsKey(cdKey(CustomDimensionsEnum.commandRunProjectType)))? map[cdKey(CustomDimensionsEnum.commandRunProjectType)] : null,
      commandRunProjectHostLanguage: (map.containsKey(cdKey(CustomDimensionsEnum.commandRunProjectHostLanguage)))? map[cdKey(CustomDimensionsEnum.commandRunProjectHostLanguage)] : null,
      commandCreateAndroidLanguage: (map.containsKey(cdKey(CustomDimensionsEnum.commandCreateAndroidLanguage)))? map[cdKey(CustomDimensionsEnum.commandCreateAndroidLanguage)] : null,
      commandCreateIosLanguage: (map.containsKey(cdKey(CustomDimensionsEnum.commandCreateIosLanguage)))? map[cdKey(CustomDimensionsEnum.commandCreateIosLanguage)] : null,
      commandRunProjectModule: (map.containsKey(cdKey(CustomDimensionsEnum.commandRunProjectModule)))? map[cdKey(CustomDimensionsEnum.commandRunProjectModule)] == 'true' : null,
      commandCreateProjectType: (map.containsKey(cdKey(CustomDimensionsEnum.commandCreateProjectType)))? map[cdKey(CustomDimensionsEnum.commandCreateProjectType)] : null,
      commandPackagesNumberPlugins: (map.containsKey(cdKey(CustomDimensionsEnum.commandPackagesNumberPlugins)))? int.parse(map[cdKey(CustomDimensionsEnum.commandPackagesNumberPlugins)]!) : null,
      commandPackagesProjectModule: (map.containsKey(cdKey(CustomDimensionsEnum.commandPackagesProjectModule)))? map[cdKey(CustomDimensionsEnum.commandPackagesProjectModule)] == 'true' : null,
      commandRunTargetOsVersion: (map.containsKey(cdKey(CustomDimensionsEnum.commandRunTargetOsVersion)))? map[cdKey(CustomDimensionsEnum.commandRunTargetOsVersion)] : null,
      commandRunModeName: (map.containsKey(cdKey(CustomDimensionsEnum.commandRunModeName)))? map[cdKey(CustomDimensionsEnum.commandRunModeName)] : null,
      commandBuildBundleTargetPlatform: (map.containsKey(cdKey(CustomDimensionsEnum.commandBuildBundleTargetPlatform)))? map[cdKey(CustomDimensionsEnum.commandBuildBundleTargetPlatform)] : null,
      commandBuildBundleIsModule: (map.containsKey(cdKey(CustomDimensionsEnum.commandBuildBundleIsModule)))? map[cdKey(CustomDimensionsEnum.commandBuildBundleIsModule)] == 'true' : null,
      commandResult: (map.containsKey(cdKey(CustomDimensionsEnum.commandResult)))? map[cdKey(CustomDimensionsEnum.commandResult)] : null,
      hotEventTargetPlatform: (map.containsKey(cdKey(CustomDimensionsEnum.hotEventTargetPlatform)))? map[cdKey(CustomDimensionsEnum.hotEventTargetPlatform)] : null,
      hotEventSdkName: (map.containsKey(cdKey(CustomDimensionsEnum.hotEventSdkName)))? map[cdKey(CustomDimensionsEnum.hotEventSdkName)] : null,
      hotEventEmulator: (map.containsKey(cdKey(CustomDimensionsEnum.hotEventEmulator)))? map[cdKey(CustomDimensionsEnum.hotEventEmulator)] == 'true' : null,
      hotEventFullRestart: (map.containsKey(cdKey(CustomDimensionsEnum.hotEventFullRestart)))? map[cdKey(CustomDimensionsEnum.hotEventFullRestart)] == 'true' : null,
      commandHasTerminal: (map.containsKey(cdKey(CustomDimensionsEnum.commandHasTerminal)))? map[cdKey(CustomDimensionsEnum.commandHasTerminal)] == 'true' : null,
      enabledFlutterFeatures: (map.containsKey(cdKey(CustomDimensionsEnum.enabledFlutterFeatures)))? map[cdKey(CustomDimensionsEnum.enabledFlutterFeatures)] : null,
      localTime: (map.containsKey(cdKey(CustomDimensionsEnum.localTime)))? map[cdKey(CustomDimensionsEnum.localTime)] : null,
      commandBuildAarTargetPlatform: (map.containsKey(cdKey(CustomDimensionsEnum.commandBuildAarTargetPlatform)))? map[cdKey(CustomDimensionsEnum.commandBuildAarTargetPlatform)] : null,
      commandBuildAarProjectType: (map.containsKey(cdKey(CustomDimensionsEnum.commandBuildAarProjectType)))? map[cdKey(CustomDimensionsEnum.commandBuildAarProjectType)] : null,
      buildEventCommand: (map.containsKey(cdKey(CustomDimensionsEnum.buildEventCommand)))? map[cdKey(CustomDimensionsEnum.buildEventCommand)] : null,
      buildEventSettings: (map.containsKey(cdKey(CustomDimensionsEnum.buildEventSettings)))? map[cdKey(CustomDimensionsEnum.buildEventSettings)] : null,
      commandBuildApkTargetPlatform: (map.containsKey(cdKey(CustomDimensionsEnum.commandBuildApkTargetPlatform)))? map[cdKey(CustomDimensionsEnum.commandBuildApkTargetPlatform)] : null,
      commandBuildApkBuildMode: (map.containsKey(cdKey(CustomDimensionsEnum.commandBuildApkBuildMode)))? map[cdKey(CustomDimensionsEnum.commandBuildApkBuildMode)] : null,
      commandBuildApkSplitPerAbi: (map.containsKey(cdKey(CustomDimensionsEnum.commandBuildApkSplitPerAbi)))? map[cdKey(CustomDimensionsEnum.commandBuildApkSplitPerAbi)] == 'true' : null,
      commandBuildAppBundleTargetPlatform: (map.containsKey(cdKey(CustomDimensionsEnum.commandBuildAppBundleTargetPlatform)))? map[cdKey(CustomDimensionsEnum.commandBuildAppBundleTargetPlatform)] : null,
      commandBuildAppBundleBuildMode: (map.containsKey(cdKey(CustomDimensionsEnum.commandBuildAppBundleBuildMode)))? map[cdKey(CustomDimensionsEnum.commandBuildAppBundleBuildMode)] : null,
      buildEventError: (map.containsKey(cdKey(CustomDimensionsEnum.buildEventError)))? map[cdKey(CustomDimensionsEnum.buildEventError)] : null,
      commandResultEventMaxRss: (map.containsKey(cdKey(CustomDimensionsEnum.commandResultEventMaxRss)))? map[cdKey(CustomDimensionsEnum.commandResultEventMaxRss)] : null,
      commandRunAndroidEmbeddingVersion: (map.containsKey(cdKey(CustomDimensionsEnum.commandRunAndroidEmbeddingVersion)))? map[cdKey(CustomDimensionsEnum.commandRunAndroidEmbeddingVersion)] : null,
      commandPackagesAndroidEmbeddingVersion: (map.containsKey(cdKey(CustomDimensionsEnum.commandPackagesAndroidEmbeddingVersion)))? map[cdKey(CustomDimensionsEnum.commandPackagesAndroidEmbeddingVersion)] : null,
      nullSafety: (map.containsKey(cdKey(CustomDimensionsEnum.nullSafety)))? map[cdKey(CustomDimensionsEnum.nullSafety)] == 'true' : null,
      fastReassemble: (map.containsKey(cdKey(CustomDimensionsEnum.fastReassemble)))? map[cdKey(CustomDimensionsEnum.fastReassemble)] == 'true' : null,
      nullSafeMigratedLibraries: (map.containsKey(cdKey(CustomDimensionsEnum.nullSafeMigratedLibraries)))? int.parse(map[cdKey(CustomDimensionsEnum.nullSafeMigratedLibraries)]!) : null,
      nullSafeTotalLibraries: (map.containsKey(cdKey(CustomDimensionsEnum.nullSafeTotalLibraries)))? int.parse(map[cdKey(CustomDimensionsEnum.nullSafeTotalLibraries)]!) : null,
    );

  @override
  String toString() => toMap().toString();

  @override
  bool operator ==(Object other) {
    return other is CustomDimensions &&
      _mapsEqual(other.toMap(), toMap());
  }
}

/// The collection of custom dimensions understood by the analytics backend.
/// When adding to this list, first ensure that the custom dimension is
/// defined in the backend, or will be defined shortly after the relevant PR
/// lands.
enum CustomDimensionsEnum {
  sessionHostOsDetails,  // cd1
  sessionChannelName,  // cd2
  commandRunIsEmulator, // cd3
  commandRunTargetName, // cd4
  hotEventReason,  // cd5
  hotEventFinalLibraryCount,  // cd6
  hotEventSyncedLibraryCount,  // cd7
  hotEventSyncedClassesCount,  // cd8
  hotEventSyncedProceduresCount,  // cd9
  hotEventSyncedBytes,  // cd10
  hotEventInvalidatedSourcesCount,  // cd11
  hotEventTransferTimeInMs,  // cd12
  hotEventOverallTimeInMs,  // cd13
  commandRunProjectType,  // cd14
  commandRunProjectHostLanguage,  // cd15
  commandCreateAndroidLanguage,  // cd16
  commandCreateIosLanguage,  // cd17
  commandRunProjectModule,  // cd18
  commandCreateProjectType,  // cd19
  commandPackagesNumberPlugins,  // cd20
  commandPackagesProjectModule,  // cd21
  commandRunTargetOsVersion,  // cd22
  commandRunModeName,  // cd23
  commandBuildBundleTargetPlatform,  // cd24
  commandBuildBundleIsModule,  // cd25
  commandResult,  // cd26
  hotEventTargetPlatform,  // cd27
  hotEventSdkName,  // cd28
  hotEventEmulator,  // cd29
  hotEventFullRestart,  // cd30
  commandHasTerminal,  // cd31
  enabledFlutterFeatures,  // cd32
  localTime,  // cd33
  commandBuildAarTargetPlatform,  // cd34
  commandBuildAarProjectType,  // cd35
  buildEventCommand,  // cd36
  buildEventSettings,  // cd37
  commandBuildApkTargetPlatform, // cd38
  commandBuildApkBuildMode, // cd39
  commandBuildApkSplitPerAbi, // cd40
  commandBuildAppBundleTargetPlatform, // cd41
  commandBuildAppBundleBuildMode, // cd42
  buildEventError,  // cd43
  commandResultEventMaxRss,  // cd44
  commandRunAndroidEmbeddingVersion, // cd45
  commandPackagesAndroidEmbeddingVersion, // cd46
  nullSafety, // cd47
  fastReassemble, // cd48
  nullSafeMigratedLibraries, // cd49
  nullSafeTotalLibraries, // cd 50
}

String cdKey(CustomDimensionsEnum cd) => 'cd${cd.index + 1}';

abstract class Usage {
  /// Create a new Usage instance; [versionOverride], [configDirOverride], and
  /// [logFile] are used for testing.
  factory Usage({
    String settingsName = 'flutter',
    String? versionOverride,
    String? configDirOverride,
    String? logFile,
    AnalyticsFactory? analyticsIOFactory,
    FirstRunMessenger? firstRunMessenger,
    required bool runningOnBot,
  }) =>
      _DefaultUsage.initialize(
        settingsName: settingsName,
        versionOverride: versionOverride,
        configDirOverride: configDirOverride,
        logFile: logFile,
        analyticsIOFactory: analyticsIOFactory,
        runningOnBot: runningOnBot,
        firstRunMessenger: firstRunMessenger,
      );

  /// Uses the global [Usage] instance to send a 'command' to analytics.
  static void command(String command, {
    CustomDimensions? parameters,
  }) => globals.flutterUsage.sendCommand(command, parameters: parameters);

  /// Whether analytics reporting should be suppressed.
  bool get suppressAnalytics;

  /// Suppress analytics for this session.
  set suppressAnalytics(bool value);

  /// Whether analytics reporting is enabled.
  bool get enabled;

  /// Enable or disable reporting analytics.
  set enabled(bool value);

  /// A stable randomly generated UUID used to deduplicate multiple identical
  /// reports coming from the same computer.
  String get clientId;

  /// Sends a 'command' to the underlying analytics implementation.
  ///
  /// Note that using [command] above is preferred to ensure that the parameter
  /// keys are well-defined in [CustomDimensions] above.
  void sendCommand(
    String command, {
    CustomDimensions? parameters,
  });

  /// Sends an 'event' to the underlying analytics implementation.
  ///
  /// Note that this method should not be used directly, instead see the
  /// event types defined in this directory in events.dart.
  @visibleForOverriding
  @visibleForTesting
  void sendEvent(
    String category,
    String parameter, {
    String? label,
    int? value,
    CustomDimensions? parameters,
  });

  /// Sends timing information to the underlying analytics implementation.
  void sendTiming(
    String category,
    String variableName,
    Duration duration, {
    String? label,
  });

  /// Sends an exception to the underlying analytics implementation.
  void sendException(dynamic exception);

  /// Fires whenever analytics data is sent over the network.
  @visibleForTesting
  Stream<Map<String, dynamic>> get onSend;

  /// Returns when the last analytics event has been sent, or after a fixed
  /// (short) delay, whichever is less.
  Future<void> ensureAnalyticsSent();

  /// Prints a welcome message that informs the tool user about the collection
  /// of anonymous usage information.
  void printWelcome();
}

typedef AnalyticsFactory = Analytics Function(
  String trackingId,
  String applicationName,
  String applicationVersion, {
  String analyticsUrl,
  Directory? documentDirectory,
});

Analytics _defaultAnalyticsIOFactory(
  String trackingId,
  String applicationName,
  String applicationVersion, {
  String? analyticsUrl,
  Directory? documentDirectory,
}) {
  return AnalyticsIO(
    trackingId,
    applicationName,
    applicationVersion,
    analyticsUrl: analyticsUrl,
    documentDirectory: documentDirectory,
  );
}

class _DefaultUsage implements Usage {
  _DefaultUsage._({
    required bool suppressAnalytics,
    required Analytics analytics,
    required this.firstRunMessenger,
    required SystemClock clock,
  })  : _suppressAnalytics = suppressAnalytics,
        _analytics = analytics,
        _clock = clock;

  static _DefaultUsage initialize({
    String settingsName = 'flutter',
    String? versionOverride,
    String? configDirOverride,
    String? logFile,
    AnalyticsFactory? analyticsIOFactory,
    required FirstRunMessenger? firstRunMessenger,
    required bool runningOnBot,
  }) {
    final FlutterVersion flutterVersion = globals.flutterVersion;
    final String version = versionOverride ?? flutterVersion.getVersionString(redactUnknownBranches: true);
    final bool suppressEnvFlag = globals.platform.environment['FLUTTER_SUPPRESS_ANALYTICS'] == 'true';
    final String? logFilePath = logFile ?? globals.platform.environment['FLUTTER_ANALYTICS_LOG_FILE'];
    final bool usingLogFile = logFilePath != null && logFilePath.isNotEmpty;

    final AnalyticsFactory analyticsFactory = analyticsIOFactory ?? _defaultAnalyticsIOFactory;
    bool suppressAnalytics = false;
    bool skipAnalyticsSessionSetup = false;
    Analytics? setupAnalytics;
    if (// To support testing, only allow other signals to suppress analytics
        // when analytics are not being shunted to a file.
        !usingLogFile && (
        // Ignore local user branches.
        version.startsWith('[user-branch]') ||
        // Many CI systems don't do a full git checkout.
        version.endsWith('/unknown') ||
        // Ignore bots.
        runningOnBot ||
        // Ignore when suppressed by FLUTTER_SUPPRESS_ANALYTICS.
        suppressEnvFlag
    )) {
      // If we think we're running on a CI system, suppress sending analytics.
      suppressAnalytics = true;
      setupAnalytics = AnalyticsMock();
      skipAnalyticsSessionSetup = true;
    }
    if (usingLogFile) {
      setupAnalytics ??= LogToFileAnalytics(logFilePath);
    } else {
      try {
        ErrorHandlingFileSystem.noExitOnFailure(() {
          setupAnalytics = analyticsFactory(
            _kFlutterUA,
            settingsName,
            version,
            documentDirectory: configDirOverride != null
                ? globals.fs.directory(configDirOverride)
                : null,
          );
        });
      } on Exception catch (e) {
        globals.printTrace('Failed to initialize analytics reporting: $e');
        suppressAnalytics = true;
        setupAnalytics ??= AnalyticsMock();
        skipAnalyticsSessionSetup = true;
      }
    }

    final Analytics analytics = setupAnalytics!;
    if (!skipAnalyticsSessionSetup) {
      // Report a more detailed OS version string than package:usage does by default.
      analytics.setSessionValue(
        cdKey(CustomDimensionsEnum.sessionHostOsDetails),
        globals.os.name,
      );
      // Send the branch name as the "channel".
      analytics.setSessionValue(
        cdKey(CustomDimensionsEnum.sessionChannelName),
        flutterVersion.getBranchName(redactUnknownBranches: true),
      );
      // For each flutter experimental feature, record a session value in a comma
      // separated list.
      final String enabledFeatures = allFeatures
          .where((Feature feature) {
        final String? configSetting = feature.configSetting;
        return configSetting != null && globals.config.getValue(configSetting) == true;
      })
          .map((Feature feature) => feature.configSetting)
          .join(',');
      analytics.setSessionValue(
        cdKey(CustomDimensionsEnum.enabledFlutterFeatures),
        enabledFeatures,
      );

      // Record the host as the application installer ID - the context that flutter_tools is running in.
      if (globals.platform.environment.containsKey('FLUTTER_HOST')) {
        analytics.setSessionValue('aiid', globals.platform.environment['FLUTTER_HOST']);
      }
      analytics.analyticsOpt = AnalyticsOpt.optOut;
    }

    return _DefaultUsage._(
      suppressAnalytics: suppressAnalytics,
      analytics: analytics,
      firstRunMessenger: firstRunMessenger,
      clock: globals.systemClock,
    );
  }

  final Analytics _analytics;
  final FirstRunMessenger? firstRunMessenger;

  bool _printedWelcome = false;
  bool _suppressAnalytics = false;
  final SystemClock _clock;

  @override
  bool get suppressAnalytics => _suppressAnalytics || _analytics.firstRun;

  @override
  set suppressAnalytics(bool value) {
    _suppressAnalytics = value;
  }

  @override
  bool get enabled => _analytics.enabled;

  @override
  set enabled(bool value) {
    _analytics.enabled = value;
  }

  @override
  String get clientId => _analytics.clientId;

  @override
  void sendCommand(String command, { CustomDimensions? parameters }) {
    if (suppressAnalytics) {
      return;
    }

    _analytics.sendScreenView(
      command,
      parameters: CustomDimensions(localTime: formatDateTime(_clock.now()))
          .merge(parameters)
          .toMap(),
    );
  }

  @override
  void sendEvent(
    String category,
    String parameter, {
    String? label,
    int? value,
    CustomDimensions? parameters,
  }) {
    if (suppressAnalytics) {
      return;
    }

    _analytics.sendEvent(
      category,
      parameter,
      label: label,
      value: value,
      parameters: CustomDimensions(localTime: formatDateTime(_clock.now()))
          .merge(parameters)
          .toMap(),
    );
  }

  @override
  void sendTiming(
    String category,
    String variableName,
    Duration duration, {
    String? label,
  }) {
    if (suppressAnalytics) {
      return;
    }
    _analytics.sendTiming(
      variableName,
      duration.inMilliseconds,
      category: category,
      label: label,
    );
  }

  @override
  void sendException(dynamic exception) {
    if (suppressAnalytics) {
      return;
    }
    _analytics.sendException(exception.runtimeType.toString());
  }

  @override
  Stream<Map<String, dynamic>> get onSend => _analytics.onSend;

  @override
  Future<void> ensureAnalyticsSent() async {
    // TODO(devoncarew): This may delay tool exit and could cause some analytics
    // events to not be reported. Perhaps we could send the analytics pings
    // out-of-process from flutter_tools?
    await _analytics.waitForLastPing(timeout: const Duration(milliseconds: 250));
  }

  @override
  void printWelcome() {
    // Only print once per run.
    if (_printedWelcome) {
      return;
    }
    // Display the welcome message if this is the first run of the tool or if
    // the license terms have changed since it was last displayed.
    final FirstRunMessenger? messenger = firstRunMessenger;
    if (messenger != null && messenger.shouldDisplayLicenseTerms()) {
      globals.printStatus('');
      globals.printStatus(messenger.licenseTerms, emphasis: true);
      _printedWelcome = true;
      messenger.confirmLicenseTermsDisplayed();
    }
  }
}

// An Analytics mock that logs to file. Unimplemented methods goes to stdout.
// But stdout can't be used for testing since wrapper scripts like
// xcode_backend.sh etc manipulates them.
class LogToFileAnalytics extends AnalyticsMock {
  LogToFileAnalytics(String logFilePath) :
    logFile = globals.fs.file(logFilePath)..createSync(recursive: true),
    super(true);

  final File logFile;
  final Map<String, String> _sessionValues = <String, String>{};

  final StreamController<Map<String, dynamic>> _sendController =
        StreamController<Map<String, dynamic>>.broadcast(sync: true);

  @override
  Stream<Map<String, dynamic>> get onSend => _sendController.stream;

  @override
  Future<void> sendScreenView(String viewName, {
    Map<String, String>? parameters,
  }) {
    if (!enabled) {
      return Future<void>.value(null);
    }
    parameters ??= <String, String>{};
    parameters['viewName'] = viewName;
    parameters.addAll(_sessionValues);
    _sendController.add(parameters);
    logFile.writeAsStringSync('screenView $parameters\n', mode: FileMode.append);
    return Future<void>.value(null);
  }

  @override
  Future<void> sendEvent(String category, String action,
      {String? label, int? value, Map<String, String>? parameters}) {
    if (!enabled) {
      return Future<void>.value(null);
    }
    parameters ??= <String, String>{};
    parameters['category'] = category;
    parameters['action'] = action;
    _sendController.add(parameters);
    logFile.writeAsStringSync('event $parameters\n', mode: FileMode.append);
    return Future<void>.value(null);
  }

  @override
  Future<void> sendTiming(String variableName, int time,
      {String? category, String? label}) {
    if (!enabled) {
      return Future<void>.value(null);
    }
    final Map<String, String> parameters = <String, String>{
      'variableName': variableName,
      'time': '$time',
      if (category != null) 'category': category,
      if (label != null) 'label': label,
    };
    _sendController.add(parameters);
    logFile.writeAsStringSync('timing $parameters\n', mode: FileMode.append);
    return Future<void>.value(null);
  }

  @override
  void setSessionValue(String param, dynamic value) {
    _sessionValues[param] = value.toString();
  }
}


/// Create a testing Usage instance.
///
/// All sent events, exceptions, timings, and pages are
/// buffered on the object and can be inspected later.
@visibleForTesting
class TestUsage implements Usage {
  final List<TestUsageCommand> commands = <TestUsageCommand>[];
  final List<TestUsageEvent> events = <TestUsageEvent>[];
  final List<dynamic> exceptions = <dynamic>[];
  final List<TestTimingEvent> timings = <TestTimingEvent>[];
  int ensureAnalyticsSentCalls = 0;

  @override
  bool enabled = true;

  @override
  bool suppressAnalytics = false;

  @override
  String get clientId => 'test-client';

  @override
  Future<void> ensureAnalyticsSent() async {
    ensureAnalyticsSentCalls++;
  }

  @override
  Stream<Map<String, dynamic>> get onSend => throw UnimplementedError();

  @override
  void printWelcome() { }

  @override
  void sendCommand(String command, {CustomDimensions? parameters}) {
    commands.add(TestUsageCommand(command, parameters: parameters));
  }

  @override
  void sendEvent(String category, String parameter, {String? label, int? value, CustomDimensions? parameters}) {
    events.add(TestUsageEvent(category, parameter, label: label, value: value, parameters: parameters));
  }

  @override
  void sendException(dynamic exception) {
    exceptions.add(exception);
  }

  @override
  void sendTiming(String category, String variableName, Duration duration, {String? label}) {
    timings.add(TestTimingEvent(category, variableName, duration, label: label));
  }
}

@visibleForTesting
@immutable
class TestUsageCommand {
  const TestUsageCommand(this.command, {this.parameters});

  final String command;
  final CustomDimensions? parameters;

  @override
  bool operator ==(Object other) {
    return other is TestUsageCommand &&
      other.command == command &&
      other.parameters == parameters;
  }

  @override
  int get hashCode => command.hashCode ^ parameters.hashCode;

  @override
  String toString() => 'TestUsageCommand($command, parameters:$parameters)';
}

@visibleForTesting
@immutable
class TestUsageEvent {
  const TestUsageEvent(this.category, this.parameter, {this.label, this.value, this.parameters});

  final String category;
  final String parameter;
  final String? label;
  final int? value;
  final CustomDimensions? parameters;

  @override
  bool operator ==(Object other) {
    return other is TestUsageEvent &&
      other.category == category &&
      other.parameter == parameter &&
      other.label == label &&
      other.value == value &&
      other.parameters == parameters;
  }

  @override
  int get hashCode => category.hashCode ^
    parameter.hashCode ^
    label.hashCode ^
    value.hashCode ^
    parameters.hashCode;

  @override
  String toString() => 'TestUsageEvent($category, $parameter, label:$label, value:$value, parameters:$parameters)';
}

@visibleForTesting
@immutable
class TestTimingEvent {
  const TestTimingEvent(this.category, this.variableName, this.duration, {this.label});

  final String category;
  final String variableName;
  final Duration duration;
  final String? label;

  @override
  bool operator ==(Object other) {
    return other is TestTimingEvent &&
      other.category == category &&
      other.variableName == variableName &&
      other.duration == duration &&
      other.label == label;
  }

  @override
  int get hashCode => category.hashCode ^
    variableName.hashCode ^
    duration.hashCode ^
    label.hashCode;

  @override
  String toString() => 'TestTimingEvent($category, $variableName, $duration, label:$label)';
}

bool _mapsEqual(Map<dynamic, dynamic>? a, Map<dynamic, dynamic>? b) {
  if (a == b) {
    return true;
  }
  if (a == null || b == null) {
    return false;
  }
  if (a.length != b.length) {
    return false;
  }

  for (final dynamic k in a.keys) {
    final dynamic bValue = b[k];
    if (bValue == null && !b.containsKey(k)) {
      return false;
    }
    if (bValue != a[k]) {
      return false;
    }
  }

  return true;
}
