// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

part of reporting;

const String _kFlutterUA = 'UA-67589403-6';

/// The collection of custom dimensions understood by the analytics backend.
/// When adding to this list, first ensure that the custom dimension is
/// defined in the backend, or will be defined shortly after the relevant PR
/// lands.
enum CustomDimensions {
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

String cdKey(CustomDimensions cd) => 'cd${cd.index + 1}';

Map<String, String> _useCdKeys(Map<CustomDimensions, Object> parameters) {
  return parameters.map((CustomDimensions k, Object v) =>
      MapEntry<String, String>(cdKey(k), v.toString()));
}

abstract class Usage {
  /// Create a new Usage instance; [versionOverride], [configDirOverride], and
  /// [logFile] are used for testing.
  factory Usage({
    String settingsName = 'flutter',
    String versionOverride,
    String configDirOverride,
    String logFile,
    AnalyticsFactory analyticsIOFactory,
    FirstRunMessenger firstRunMessenger,
    @required bool runningOnBot,
  }) => _DefaultUsage(settingsName: settingsName,
                      versionOverride: versionOverride,
                      configDirOverride: configDirOverride,
                      logFile: logFile,
                      analyticsIOFactory: analyticsIOFactory,
                      runningOnBot: runningOnBot,
                      firstRunMessenger: firstRunMessenger);

  /// Uses the global [Usage] instance to send a 'command' to analytics.
  static void command(String command, {
    Map<CustomDimensions, Object> parameters,
  }) => globals.flutterUsage.sendCommand(command, parameters: _useCdKeys(parameters));

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
    Map<String, String> parameters,
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
    String label,
    int value,
    Map<String, String> parameters,
  });

  /// Sends timing information to the underlying analytics implementation.
  void sendTiming(
    String category,
    String variableName,
    Duration duration, {
    String label,
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
  Directory documentDirectory,
});

Analytics _defaultAnalyticsIOFactory(
  String trackingId,
  String applicationName,
  String applicationVersion, {
  String analyticsUrl,
  Directory documentDirectory,
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
  _DefaultUsage({
    String settingsName = 'flutter',
    String versionOverride,
    String configDirOverride,
    String logFile,
    AnalyticsFactory analyticsIOFactory,
    @required this.firstRunMessenger,
    @required bool runningOnBot,
  }) {
    final FlutterVersion flutterVersion = globals.flutterVersion;
    final String version = versionOverride ?? flutterVersion.getVersionString(redactUnknownBranches: true);
    final bool suppressEnvFlag = globals.platform.environment['FLUTTER_SUPPRESS_ANALYTICS'] == 'true';
    final String logFilePath = logFile ?? globals.platform.environment['FLUTTER_ANALYTICS_LOG_FILE'];
    final bool usingLogFile = logFilePath != null && logFilePath.isNotEmpty;

    analyticsIOFactory ??= _defaultAnalyticsIOFactory;
    _clock = globals.systemClock;

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
      _analytics = AnalyticsMock();
      return;
    }

    if (usingLogFile) {
      _analytics = LogToFileAnalytics(logFilePath);
    } else {
      try {
        ErrorHandlingFileSystem.noExitOnFailure(() {
          _analytics = analyticsIOFactory(
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
        _analytics = AnalyticsMock();
        return;
      }
    }
    assert(_analytics != null);

    // Report a more detailed OS version string than package:usage does by default.
    _analytics.setSessionValue(
      cdKey(CustomDimensions.sessionHostOsDetails),
      globals.os.name,
    );
    // Send the branch name as the "channel".
    _analytics.setSessionValue(
      cdKey(CustomDimensions.sessionChannelName),
      flutterVersion.getBranchName(redactUnknownBranches: true),
    );
    // For each flutter experimental feature, record a session value in a comma
    // separated list.
    final String enabledFeatures = allFeatures
      .where((Feature feature) {
        return feature.configSetting != null &&
               globals.config.getValue(feature.configSetting) == true;
      })
      .map((Feature feature) => feature.configSetting)
      .join(',');
    _analytics.setSessionValue(
      cdKey(CustomDimensions.enabledFlutterFeatures),
      enabledFeatures,
    );

    // Record the host as the application installer ID - the context that flutter_tools is running in.
    if (globals.platform.environment.containsKey('FLUTTER_HOST')) {
      _analytics.setSessionValue('aiid', globals.platform.environment['FLUTTER_HOST']);
    }
    _analytics.analyticsOpt = AnalyticsOpt.optOut;
  }

  Analytics _analytics;
  final FirstRunMessenger firstRunMessenger;

  bool _printedWelcome = false;
  bool _suppressAnalytics = false;
  SystemClock _clock;

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
  void sendCommand(String command, { Map<String, String> parameters }) {
    if (suppressAnalytics) {
      return;
    }

    final Map<String, String> paramsWithLocalTime = <String, String>{
      ...?parameters,
      cdKey(CustomDimensions.localTime): formatDateTime(_clock.now()),
    };
    _analytics.sendScreenView(command, parameters: paramsWithLocalTime);
  }

  @override
  void sendEvent(
    String category,
    String parameter, {
    String label,
    int value,
    Map<String, String> parameters,
  }) {
    if (suppressAnalytics) {
      return;
    }

    final Map<String, String> paramsWithLocalTime = <String, String>{
      ...?parameters,
      cdKey(CustomDimensions.localTime): formatDateTime(_clock.now()),
    };

    _analytics.sendEvent(
      category,
      parameter,
      label: label,
      value: value,
      parameters: paramsWithLocalTime,
    );
  }

  @override
  void sendTiming(
    String category,
    String variableName,
    Duration duration, {
    String label,
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
    if (firstRunMessenger != null && firstRunMessenger.shouldDisplayLicenseTerms() ?? true) {
      globals.printStatus('');
      globals.printStatus(firstRunMessenger.licenseTerms, emphasis: true);
      _printedWelcome = true;
      firstRunMessenger.confirmLicenseTermsDisplayed();
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
    Map<String, String> parameters,
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
      {String label, int value, Map<String, String> parameters}) {
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
      {String category, String label}) {
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
  void sendCommand(String command, {Map<String, String> parameters}) {
    commands.add(TestUsageCommand(command, parameters: parameters));
  }

  @override
  void sendEvent(String category, String parameter, {String label, int value, Map<String, String> parameters}) {
    events.add(TestUsageEvent(category, parameter, label: label, value: value, parameters: parameters));
  }

  @override
  void sendException(dynamic exception) {
    exceptions.add(exception);
  }

  @override
  void sendTiming(String category, String variableName, Duration duration, {String label}) {
    timings.add(TestTimingEvent(category, variableName, duration, label: label));
  }
}

@visibleForTesting
@immutable
class TestUsageCommand {
  const TestUsageCommand(this.command, {this.parameters});

  final String command;
  final Map<String, String> parameters;

  @override
  bool operator ==(Object other) {
    return other is TestUsageCommand &&
      other.command == command &&
      _mapsEqual(other.parameters, parameters);
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
  final String label;
  final int value;
  final Map<String, String> parameters;

  @override
  bool operator ==(Object other) {
    return other is TestUsageEvent &&
      other.category == category &&
      other.parameter == parameter &&
      other.label == label &&
      other.value == value &&
      _mapsEqual(other.parameters, parameters);
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
  final String label;

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

bool _mapsEqual(Map<dynamic, dynamic> a, Map<dynamic, dynamic> b) {
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
