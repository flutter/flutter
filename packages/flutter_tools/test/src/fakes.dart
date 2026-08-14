// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io show IOSink, ProcessSignal, Stdout, StdoutException;

import 'package:dds/dds_launcher.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart';
import 'package:flutter_tools/src/android/java.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/base/template.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/build_targets.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/context/android_context.dart';
import 'package:flutter_tools/src/context/apple_context.dart';
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:flutter_tools/src/context/tool_dependencies.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/custom_devices/custom_devices_config.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/git.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/ios/ios_workflow.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/ios/simulators.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/cocoapods.dart';
import 'package:flutter_tools/src/macos/cocoapods_validator.dart';
import 'package:flutter_tools/src/macos/xcdevice.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/native_assets.dart';
import 'package:flutter_tools/src/pre_run_validator.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/crash_reporting.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/runner/local_engine.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import 'context.dart';

class FakeDyldEnvironmentArtifact extends ArtifactSet {
  FakeDyldEnvironmentArtifact() : super(DevelopmentArtifact.iOS);
  @override
  Map<String, String> get environment => <String, String>{
    'DYLD_LIBRARY_PATH': '/path/to/libraries',
  };

  @override
  Future<bool> isUpToDate(FileSystem fileSystem) => Future<bool>.value(true);

  @override
  String get name => 'fake';

  @override
  Future<void> update(
    ArtifactUpdater artifactUpdater,
    Logger logger,
    FileSystem fileSystem,
    OperatingSystemUtils operatingSystemUtils, {
    bool offline = false,
  }) async {}
}

/// A fake process implementation which can be provided all necessary values.
class FakeProcess implements Process {
  FakeProcess({
    this.pid = 1,
    Future<int>? exitCode,
    IOSink? stdin,
    this.stdout = const Stream<List<int>>.empty(),
    this.stderr = const Stream<List<int>>.empty(),
  }) : exitCode = exitCode ?? Future<int>.value(0),
       stdin = stdin ?? MemoryIOSink();

  @override
  final int pid;

  @override
  final Future<int> exitCode;

  @override
  final io.IOSink stdin;

  @override
  final Stream<List<int>> stdout;

  @override
  final Stream<List<int>> stderr;

  @override
  bool kill([io.ProcessSignal signal = io.ProcessSignal.sigterm]) {
    return true;
  }
}

/// A [ShutdownHooks] implementation that does not actually execute any hooks.
class FakeShutdownHooks extends Fake implements ShutdownHooks {
  @override
  bool get isShuttingDown => _isShuttingDown;
  var _isShuttingDown = false;

  @override
  final registeredHooks = <ShutdownHook>[];

  @override
  void addShutdownHook(ShutdownHook shutdownHook) {
    registeredHooks.add(shutdownHook);
  }

  @override
  Future<void> runShutdownHooks(Logger logger) async {
    _isShuttingDown = true;
  }
}

/// An IOSink that completes a future with the first line written to it.
class CompleterIOSink extends MemoryIOSink {
  CompleterIOSink({this.throwOnAdd = false});

  final bool throwOnAdd;

  final _completer = Completer<List<int>>();

  Future<List<int>> get future => _completer.future;

  @override
  void add(List<int> data) {
    if (!_completer.isCompleted) {
      // When throwOnAdd is true, complete with empty so any expected output
      // doesn't appear.
      _completer.complete(throwOnAdd ? <int>[] : data);
    }
    if (throwOnAdd) {
      throw Exception('CompleterIOSink Error');
    }
    super.add(data);
  }
}

/// An IOSink that collects whatever is written to it.
class MemoryIOSink implements IOSink {
  @override
  Encoding encoding = utf8;

  final writes = <List<int>>[];

  @override
  void add(List<int> data) {
    writes.add(data);
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) {
    final completer = Completer<void>();
    late StreamSubscription<List<int>> sub;
    sub = stream.listen(
      (List<int> data) {
        try {
          add(data);
          // Catches all exceptions to propagate them to the completer.
        } catch (err, stack) {
          sub.cancel();
          completer.completeError(err, stack);
        }
      },
      onError: completer.completeError,
      onDone: completer.complete,
      cancelOnError: true,
    );
    return completer.future;
  }

  @override
  void writeCharCode(int charCode) {
    add(<int>[charCode]);
  }

  @override
  void write(Object? obj) {
    add(encoding.encode('$obj'));
  }

  @override
  void writeln([Object? obj = '']) {
    add(encoding.encode('$obj\n'));
  }

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) {
    var addSeparator = false;
    for (final dynamic object in objects) {
      if (addSeparator) {
        write(separator);
      }
      write(object);
      addSeparator = true;
    }
  }

  @override
  void addError(dynamic error, [StackTrace? stackTrace]) {
    throw UnimplementedError();
  }

  @override
  Future<void> get done => close();

  @override
  Future<void> close() async {}

  @override
  Future<void> flush() async {}

  void clear() {
    writes.clear();
  }

  String getAndClear() {
    final String result = utf8.decode(writes.expand((List<int> l) => l).toList());
    clear();
    return result;
  }
}

class MemoryStdout extends MemoryIOSink implements io.Stdout {
  @override
  bool get hasTerminal => _hasTerminal;
  set hasTerminal(bool value) {
    _hasTerminal = value;
  }

  var _hasTerminal = true;

  @override
  String get lineTerminator => '\n';
  @override
  set lineTerminator(String value) {
    throw UnimplementedError('Setting the line terminator is not supported');
  }

  @override
  io.IOSink get nonBlocking => this;

  @override
  bool get supportsAnsiEscapes => _supportsAnsiEscapes;
  set supportsAnsiEscapes(bool value) {
    _supportsAnsiEscapes = value;
  }

  var _supportsAnsiEscapes = true;

  @override
  int get terminalColumns {
    if (_terminalColumns != null) {
      return _terminalColumns!;
    }
    throw const io.StdoutException('unspecified mock value');
  }

  set terminalColumns(int value) => _terminalColumns = value;
  int? _terminalColumns;

  @override
  int get terminalLines {
    if (_terminalLines != null) {
      return _terminalLines!;
    }
    throw const io.StdoutException('unspecified mock value');
  }

  set terminalLines(int value) => _terminalLines = value;
  int? _terminalLines;
}

/// A Stdio that collects stdout and supports simulated stdin.
class FakeStdio extends Stdio {
  final _stdout = MemoryStdout()..terminalColumns = 80;
  final _stderr = MemoryIOSink();
  final _stdin = FakeStdin();

  @override
  MemoryStdout get stdout => _stdout;

  @override
  MemoryIOSink get stderr => _stderr;

  @override
  Stream<List<int>> get stdin => _stdin;

  void simulateStdin(String line) {
    _stdin.controller.add(utf8.encode('$line\n'));
  }

  @override
  bool hasTerminal = false;

  List<String> get writtenToStdout => _stdout.writes.map<String>(_stdout.encoding.decode).toList();
  List<String> get writtenToStderr => _stderr.writes.map<String>(_stderr.encoding.decode).toList();
}

class FakeStdin extends Fake implements Stdin {
  final controller = StreamController<List<int>>();

  void Function(bool mode)? echoModeCallback;

  var _echoMode = true;

  @override
  bool get echoMode => _echoMode;

  @override
  set echoMode(bool mode) {
    _echoMode = mode;
    if (echoModeCallback != null) {
      echoModeCallback!(mode);
    }
  }

  @override
  bool lineMode = true;

  @override
  bool hasTerminal = false;

  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> transformer) {
    return controller.stream.transform(transformer);
  }

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class FakePlistParser implements PlistParser {
  FakePlistParser([Map<String, Object>? underlyingValues])
    : _underlyingValues = underlyingValues ?? <String, Object>{};

  final Map<String, Object> _underlyingValues;

  void setProperty(String key, Object value) {
    _underlyingValues[key] = value;
  }

  @override
  String? plistXmlContent(String plistFilePath) => throw UnimplementedError();

  @override
  String? plistJsonContent(String filePath, {bool sorted = false}) {
    throw UnimplementedError();
  }

  @override
  Map<String, Object> parseFile(String plistFilePath) {
    return _underlyingValues;
  }

  @override
  T? getValueFromFile<T>(String plistFilePath, String key) {
    return _underlyingValues[key] as T?;
  }

  @override
  bool replaceKey(String plistFilePath, {required String key, String? value}) {
    if (value == null) {
      _underlyingValues.remove(key);
      return true;
    }
    setProperty(key, value);
    return true;
  }

  @override
  bool insertKeyWithJson(String plistFilePath, {required String key, required String json}) {
    return false;
  }
}

class FakeBotDetector implements BotDetector {
  const FakeBotDetector(bool isRunningOnBot) : _isRunningOnBot = isRunningOnBot;

  @override
  Future<bool> get isRunningOnBot async => _isRunningOnBot;

  final bool _isRunningOnBot;
}

class FakeFlutterVersion implements FlutterVersion {
  FakeFlutterVersion({
    this.branch = 'master',
    this.dartSdkVersion = '12',
    this.devToolsVersion = '2.8.0',
    this.engineRevision = 'abcdefghijklmnopqrstuvwxyz',
    this.engineRevisionShort = 'abcde',
    this.engineAge = '0 hours ago',
    this.engineCommitDate = '12/01/01',
    this.repositoryUrl = 'https://github.com/flutter/flutter.git',
    this.frameworkVersion = '0.0.0',
    this.frameworkRevision = '11111111111111111111',
    this.frameworkRevisionShort = '11111',
    this.frameworkAge = '0 hours ago',
    this.frameworkCommitDate = '12/01/01',
    this.gitTagVersion = const GitTagVersion.unknown(),
    this.flutterRoot = '/path/to/flutter',
    this.nextFlutterVersion,
    this.engineBuildDate = '12/01/02',
    this.engineContentHash = 'cccccccccccccccccccccccccccccccccccccccc',
  });

  final String branch;

  bool get didFetchTagsAndUpdate => _didFetchTagsAndUpdate;
  var _didFetchTagsAndUpdate = false;

  bool get didEnsureVersionFile => _didEnsureVersionFile;
  var _didEnsureVersionFile = false;

  bool get didDeleteVersionFile => _didDeleteVersionFile;
  var _didDeleteVersionFile = false;

  /// Will be returned by [fetchTagsAndGetVersion] if not null.
  final FlutterVersion? nextFlutterVersion;

  @override
  FlutterVersion fetchTagsAndGetVersion({SystemClock clock = const SystemClock()}) {
    _didFetchTagsAndUpdate = true;
    return nextFlutterVersion ?? this;
  }

  bool get didCheckFlutterVersionFreshness => _didCheckFlutterVersionFreshness;
  var _didCheckFlutterVersionFreshness = false;

  @override
  String get channel {
    if (kOfficialChannels.contains(branch) || kObsoleteBranches.containsKey(branch)) {
      return branch;
    }
    return kUserBranch;
  }

  @override
  final String flutterRoot;

  @override
  final String devToolsVersion;

  @override
  final String dartSdkVersion;

  @override
  final String engineRevision;

  @override
  final String engineRevisionShort;

  @override
  final String? engineCommitDate;

  @override
  final String engineAge;

  @override
  final String? repositoryUrl;

  @override
  final String frameworkVersion;

  @override
  final String frameworkRevision;

  @override
  final String frameworkRevisionShort;

  @override
  final String frameworkAge;

  @override
  final String frameworkCommitDate;

  @override
  final GitTagVersion gitTagVersion;

  @override
  FileSystem get fs => throw UnimplementedError('FakeFlutterVersion.fs is not implemented');

  @override
  Future<void> checkFlutterVersionFreshness() async {
    _didCheckFlutterVersionFreshness = true;
  }

  @override
  Future<void> ensureVersionFile() async {
    _didEnsureVersionFile = true;
  }

  @override
  void deleteVersionFile() {
    _didDeleteVersionFile = true;
  }

  @override
  String getBranchName({bool redactUnknownBranches = false}) {
    if (!redactUnknownBranches ||
        kOfficialChannels.contains(branch) ||
        kObsoleteBranches.containsKey(branch)) {
      return branch;
    }
    return kUserBranch;
  }

  @override
  String getVersionString({bool redactUnknownBranches = false}) {
    return '${getBranchName(redactUnknownBranches: redactUnknownBranches)}/$frameworkRevision';
  }

  @override
  Map<String, Object> toJson() {
    return <String, Object>{};
  }

  @override
  final String? engineBuildDate;

  @override
  final String? engineContentHash;
}

// A test implementation of [FeatureFlags] that allows enabling without reading
// config. If not otherwise specified, all values default to false.
class TestFeatureFlags implements FeatureFlags {
  TestFeatureFlags({
    this.isLinuxEnabled = false,
    this.isMacOSEnabled = false,
    this.isWebEnabled = false,
    this.isWindowsEnabled = false,
    this.isAndroidEnabled = true,
    this.isIOSEnabled = true,
    this.isFuchsiaEnabled = false,
    this.areCustomDevicesEnabled = false,
    this.isCliAnimationEnabled = true,
    this.isNativeAssetsEnabled = false,
    this.isDartDataAssetsEnabled = false,
    this.isRecordUseEnabled = false,
    this.isSwiftPackageManagerEnabled = false,
    this.isOmitLegacyVersionFileEnabled = false,
    this.isWindowingEnabled = false,
    this.isAccessibilityEvaluationsEnabled = false,
    this.isLLDBDebuggingEnabled = false,
    this.isUISceneMigrationEnabled = false,
    this.isRiscv64SupportEnabled = false,
    this.isMacOSArm64OnlyEnabled = false,
  });

  @override
  final bool isLinuxEnabled;

  @override
  final bool isMacOSEnabled;

  @override
  final bool isWebEnabled;

  @override
  final bool isWindowsEnabled;

  @override
  final bool isAndroidEnabled;

  @override
  final bool isIOSEnabled;

  @override
  final bool isFuchsiaEnabled;

  @override
  final bool areCustomDevicesEnabled;

  @override
  final bool isCliAnimationEnabled;

  @override
  final bool isNativeAssetsEnabled;

  @override
  final bool isDartDataAssetsEnabled;

  @override
  final bool isRecordUseEnabled;

  @override
  final bool isSwiftPackageManagerEnabled;

  @override
  final bool isOmitLegacyVersionFileEnabled;

  @override
  final bool isWindowingEnabled;

  @override
  final bool isAccessibilityEvaluationsEnabled;

  @override
  final bool isLLDBDebuggingEnabled;

  @override
  final bool isUISceneMigrationEnabled;

  @override
  final bool isRiscv64SupportEnabled;

  @override
  final bool isMacOSArm64OnlyEnabled;

  @override
  bool isEnabled(Feature feature) {
    return switch (feature) {
      flutterWebFeature => isWebEnabled,
      flutterLinuxDesktopFeature => isLinuxEnabled,
      flutterMacOSDesktopFeature => isMacOSEnabled,
      flutterWindowsDesktopFeature => isWindowsEnabled,
      flutterAndroidFeature => isAndroidEnabled,
      flutterIOSFeature => isIOSEnabled,
      flutterFuchsiaFeature => isFuchsiaEnabled,
      flutterCustomDevicesFeature => areCustomDevicesEnabled,
      cliAnimation => isCliAnimationEnabled,
      nativeAssets => isNativeAssetsEnabled,
      swiftPackageManager => isSwiftPackageManagerEnabled,
      omitLegacyVersionFile => isOmitLegacyVersionFileEnabled,
      windowingFeature => isWindowingEnabled,
      accessibilityEvaluationsFeature => isAccessibilityEvaluationsEnabled,
      lldbDebugging => isLLDBDebuggingEnabled,
      uiSceneMigration => isUISceneMigrationEnabled,
      riscv64 => isRiscv64SupportEnabled,
      macOSArm64Only => isMacOSArm64OnlyEnabled,
      recordUse => isRecordUseEnabled,
      _ => false,
    };
  }

  @override
  List<Feature> get allFeatures => const <Feature>[
    flutterWebFeature,
    flutterLinuxDesktopFeature,
    flutterMacOSDesktopFeature,
    flutterWindowsDesktopFeature,
    flutterAndroidFeature,
    flutterIOSFeature,
    flutterFuchsiaFeature,
    flutterCustomDevicesFeature,
    cliAnimation,
    dartDataAssets,
    nativeAssets,
    recordUse,
    swiftPackageManager,
    omitLegacyVersionFile,
    windowingFeature,
    accessibilityEvaluationsFeature,
    lldbDebugging,
    uiSceneMigration,
    riscv64,
    macOSArm64Only,
  ];

  @override
  Iterable<Feature> get allConfigurableFeatures {
    return allFeatures.where((Feature feature) => feature.configSetting != null);
  }

  @override
  Iterable<Feature> get allEnabledFeatures {
    return allFeatures.where(isEnabled);
  }
}

class FakeOperatingSystemUtils extends Fake implements OperatingSystemUtils {
  FakeOperatingSystemUtils({this.hostPlatform = HostPlatform.linux_x64});

  final chmods = <List<String>>[];

  @override
  void makeExecutable(File file) {}

  @override
  HostPlatform? hostPlatformOverride;

  @override
  HostPlatform hostPlatform = HostPlatform.linux_x64;

  @override
  void chmod(FileSystemEntity entity, String mode) {
    chmods.add(<String>[entity.path, mode]);
  }

  @override
  File? which(String execName) => null;

  @override
  List<File> whichAll(String execName) => <File>[];

  @override
  int? getDirectorySize(Directory directory) => 10000000; // 10 MB / 9.5 MiB

  @override
  void unzip(File file, Directory targetDirectory) {}

  @override
  void unpack(File gzippedTarFile, Directory targetDirectory) {}

  @override
  Stream<List<int>> gzipLevel1Stream(Stream<List<int>> stream) => stream;

  @override
  String get name => 'fake OS name and version';

  @override
  String get pathVarSeparator => ';';

  @override
  Future<int> findFreePort({bool ipv6 = false}) async => 12345;
}

class FakeStopwatch implements Stopwatch {
  @override
  bool get isRunning => _isRunning;
  var _isRunning = false;

  @override
  void start() => _isRunning = true;

  @override
  void stop() => _isRunning = false;

  @override
  Duration elapsed = Duration.zero;

  @override
  int get elapsedMicroseconds => elapsed.inMicroseconds;

  @override
  int get elapsedMilliseconds => elapsed.inMilliseconds;

  @override
  int get elapsedTicks => elapsed.inMilliseconds;

  @override
  int get frequency => 1000;

  @override
  void reset() {
    _isRunning = false;
    elapsed = Duration.zero;
  }

  @override
  String toString() => '$runtimeType $elapsed $isRunning';
}

class FakeStopwatchFactory implements StopwatchFactory {
  FakeStopwatchFactory({Stopwatch? stopwatch, Map<String, Stopwatch>? stopwatches})
    : stopwatches = <String, Stopwatch>{...?stopwatches, '': ?stopwatch};

  Map<String, Stopwatch> stopwatches;

  @override
  Stopwatch createStopwatch([String name = '']) {
    return stopwatches[name] ?? FakeStopwatch();
  }
}

class FakeFlutterProjectFactory implements FlutterProjectFactory {
  @override
  FlutterProject fromDirectory(Directory directory) {
    return FlutterProject.fromDirectoryTest(directory);
  }

  @override
  Map<String, FlutterProject> get projects => throw UnimplementedError();
}

class FakeAndroidSdk extends Fake implements AndroidSdk {
  @override
  late bool platformToolsAvailable;

  @override
  late bool licensesAvailable;

  @override
  AndroidSdkVersion? latestVersion;
}

class FakeAndroidStudio extends Fake implements AndroidStudio {
  @override
  String get javaPath => 'java';
}

class FakeJava extends Fake implements Java {
  FakeJava({
    this.javaHome = '/android-studio/jbr',
    this.javaSource = JavaSource.androidStudio,
    String binary = '/android-studio/jbr/bin/java',
    Version? version,
    bool canRun = true,
  }) : binaryPath = binary,
       version = version ?? const Version.withText(19, 0, 2, 'openjdk 19.0.2 2023-01-17'),
       _environment = <String, String>{
         Java.javaHomeEnvironmentVariable: ?javaHome,
         'PATH': '/android-studio/jbr/bin',
       },
       _canRun = canRun;

  @override
  String? javaHome;

  @override
  String binaryPath;

  @override
  JavaSource javaSource;

  final Map<String, String> _environment;
  final bool _canRun;

  @override
  Map<String, String> get environment => _environment;

  @override
  Version? version;

  @override
  bool canRun() {
    return _canRun;
  }
}

class FakeDartDevelopmentServiceLauncher extends Fake implements DartDevelopmentServiceLauncher {
  FakeDartDevelopmentServiceLauncher({required this.uri, this.devToolsUri, this.dtdUri});

  @override
  final Uri uri;

  @override
  final Uri? devToolsUri;

  @override
  final Uri? dtdUri;

  @override
  Future<void> get done => _completer.future;

  @override
  Future<void> shutdown() async => _completer.complete();

  final _completer = Completer<void>();
}

class FakeDevtoolsLauncher extends Fake implements DevtoolsLauncher {
  FakeDevtoolsLauncher({DevToolsServerAddress? serverAddress}) : _serverAddress = serverAddress;

  @override
  Future<void> get processStart => _processStarted.future;

  final _processStarted = Completer<void>();

  @override
  Future<void> get ready => readyCompleter.future;

  Completer<void> readyCompleter = Completer<void>()..complete();

  @override
  DevToolsServerAddress? activeDevToolsServer;

  @override
  Uri? devToolsUrl;

  @override
  Uri? dtdUri;

  @override
  bool printDtdUri = false;

  final DevToolsServerAddress? _serverAddress;

  @override
  Future<DevToolsServerAddress?> serve() async => _serverAddress;

  @override
  Future<void> launch(Uri vmServiceUri, {List<String>? additionalArguments}) {
    _processStarted.complete();
    return Completer<void>().future;
  }

  bool closed = false;

  @override
  Future<void> close() async {
    closed = true;
  }
}

/// A fake [Logger] that throws the [Invocation] for any method call.
class FakeLogger implements Logger {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw invocation; // ignore: only_throw_errors
}

class ClosedStdinController extends Fake implements StreamSink<List<int>> {
  @override
  Future<Object?> addStream(Stream<List<int>> stream) async =>
      throw const SocketException('Bad pipe');

  @override
  Future<Object?> close() async {
    return null;
  }
}

class FakeConfig extends Fake implements Config {
  FakeConfig([Map<String, Object?>? values, this.configPath = '/.flutter_settings'])
    : _values = values ?? <String, Object?>{};
  final Map<String, Object?> _values;

  @override
  final String configPath;

  @override
  Object? getValue(String key) => _values[key];

  @override
  void setValue(String key, Object value) {
    _values[key] = value;
  }

  @override
  void removeValue(String key) {
    _values.remove(key);
  }

  @override
  bool containsKey(String key) => _values.containsKey(key);

  @override
  Iterable<String> get keys => _values.keys;
}

class FakeFileSystemUtils extends Fake implements FileSystemUtils {}

class FakeTerminal extends Fake implements Terminal {}

class FakeProcessUtils extends Fake implements ProcessUtils {}

class FakeTemplateRenderer extends Fake implements TemplateRenderer {}

class FakeXcode extends Fake implements Xcode {
  FakeXcode({this.currentVersion, this.isDevicectlInstalled = true});

  @override
  Version? currentVersion;

  @override
  bool isDevicectlInstalled;

  @override
  Future<String> sdkLocation(EnvironmentType environmentType) async => '/fake/sdk/path';

  @override
  List<String> xcrunCommand() => <String>['xcrun'];
}

class FakeArtifacts extends Fake implements Artifacts {
  FakeArtifacts({FileSystem? fileSystem, this.sdkPath})
    : _delegate = Artifacts.test(fileSystem: fileSystem);

  final Artifacts _delegate;
  final String? sdkPath;

  @override
  LocalEngineInfo? get localEngineInfo => _delegate.localEngineInfo;

  @override
  bool get usesLocalArtifacts => _delegate.usesLocalArtifacts;

  @override
  FileSystemEntity getHostArtifact(HostArtifact artifact) => _delegate.getHostArtifact(artifact);

  @override
  String getArtifactPath(
    Artifact artifact, {
    TargetPlatform? platform,
    BuildMode? mode,
    EnvironmentType? environmentType,
  }) {
    if (artifact == Artifact.engineDartSdkPath && sdkPath != null) {
      return sdkPath!;
    }
    return _delegate.getArtifactPath(
      artifact,
      platform: platform,
      mode: mode,
      environmentType: environmentType,
    );
  }

  @override
  String getEngineType(TargetPlatform platform, [BuildMode? mode]) =>
      _delegate.getEngineType(platform, mode);
}

class FakeCache extends Fake implements Cache {
  FakeCache({FileSystem? fileSystem}) : _fileSystem = fileSystem ?? MemoryFileSystem.test();

  final FileSystem _fileSystem;

  @override
  Future<void> lock() async {}

  @override
  void releaseLock() {}

  @override
  Future<void> updateAll(
    Set<DevelopmentArtifact> requiredArtifacts, {
    bool offline = false,
  }) async {}

  @override
  Directory getRoot() => _fileSystem.directory('/bin/cache');

  @override
  Directory getCacheDir(String name, {bool shouldCreate = true}) =>
      _fileSystem.directory('/bin/cache/$name');

  @override
  Directory getArtifactDirectory(String name) =>
      _fileSystem.directory('/bin/cache/artifacts/$name');

  @override
  Directory getWebSdkDirectory() => _fileSystem.directory('/bin/cache/flutter_web_sdk');

  @override
  MapEntry<String, String> get dyLdLibEntry =>
      const MapEntry<String, String>('DYLD_LIBRARY_PATH', 'fake_path');
}

class FakeGit extends Fake implements Git {}

class FakeGradleUtils extends Fake implements GradleUtils {}

class FakeCocoaPods extends Fake implements CocoaPods {}

class FakeCocoaPodsValidator extends Fake implements CocoaPodsValidator {}

class FakeIOSSimulatorUtils extends Fake implements IOSSimulatorUtils {}

class FakeIOSWorkflow extends Fake implements IOSWorkflow {}

class FakeXCDevice extends Fake implements XCDevice {}

class FakeBuildSystem extends Fake implements BuildSystem {}

class FakeBuildTargets extends Fake implements BuildTargets {}

class FakeCrashReporter extends Fake implements CrashReporter {}

class FakeToolDependencies extends Fake implements ToolDependencies {
  FakeToolDependencies({
    Analytics? analytics,
    AndroidContext? androidContext,
    AppleContext? appleContext,
    BuildSystem? buildSystem,
    BuildTargets? buildTargets,
    CrashReporter? crashReporter,
    ToolContext? toolContext,
  }) : _analytics = analytics,
       _androidContext = androidContext,
       _appleContext = appleContext,
       _buildSystem = buildSystem,
       _buildTargets = buildTargets,
       _crashReporter = crashReporter,
       _toolContext = toolContext;

  final Analytics? _analytics;
  final AndroidContext? _androidContext;
  final AppleContext? _appleContext;
  final BuildSystem? _buildSystem;
  final BuildTargets? _buildTargets;
  final CrashReporter? _crashReporter;
  final ToolContext? _toolContext;

  @override
  Analytics get analytics => _analytics ?? const NoOpAnalytics();

  @override
  AndroidContext get androidContext => _androidContext ?? FakeAndroidContext();

  @override
  AppleContext get appleContext => _appleContext ?? FakeAppleContext();

  @override
  BuildSystem get buildSystem => _buildSystem ?? FakeBuildSystem();

  @override
  BuildTargets get buildTargets => _buildTargets ?? FakeBuildTargets();

  @override
  CrashReporter get crashReporter => _crashReporter ?? FakeCrashReporter();

  @override
  ToolContext get toolContext => _toolContext ?? FakeToolContext();
}

class FakeToolContext extends Fake implements ToolContext {
  FakeToolContext({
    Artifacts? artifacts,
    BotDetector? botDetector,
    Cache? cache,
    Config? config,
    CustomDevicesConfig? customDevicesConfig,
    FlutterVersion? flutterVersion,
    FileSystem? fs,
    Git? git,
    LocalEngineLocator? localEngineLocator,
    Logger? logger,
    TestCompilerNativeAssetsBuilder? nativeAssetsBuilder,
    OperatingSystemUtils? os,
    OutputPreferences? outputPreferences,
    Platform? platform,
    PreRunValidator? preRunValidator,
    ProcessManager? processManager,
    ProcessUtils? processUtils,
    FlutterProjectFactory? projectFactory,
    ShutdownHooks? shutdownHooks,
    Signals? signals,
    Stdio? stdio,
    SystemClock? systemClock,
    AnsiTerminal? terminal,
    UserMessages? userMessages,
  }) : _artifacts = artifacts,
       _botDetector = botDetector,
       _cache = cache,
       _config = config,
       _customDevicesConfig = customDevicesConfig,
       _flutterVersion = flutterVersion,
       _fs = fs,
       _git = git,
       _localEngineLocator = localEngineLocator,
       _logger = logger,
       _nativeAssetsBuilder = nativeAssetsBuilder,
       _os = os,
       _outputPreferences = outputPreferences,
       _platform = platform,
       _preRunValidator = preRunValidator,
       _processManager = processManager,
       _processUtils = processUtils,
       _projectFactory = projectFactory,
       _shutdownHooks = shutdownHooks,
       _signals = signals,
       _stdio = stdio,
       _systemClock = systemClock,
       _terminal = terminal,
       _userMessages = userMessages;

  final Artifacts? _artifacts;
  final BotDetector? _botDetector;
  final Cache? _cache;
  final Config? _config;
  final CustomDevicesConfig? _customDevicesConfig;
  final FlutterVersion? _flutterVersion;
  final FileSystem? _fs;
  final Git? _git;
  final LocalEngineLocator? _localEngineLocator;
  final Logger? _logger;
  final TestCompilerNativeAssetsBuilder? _nativeAssetsBuilder;
  final OperatingSystemUtils? _os;
  final OutputPreferences? _outputPreferences;
  final Platform? _platform;
  final PreRunValidator? _preRunValidator;
  final ProcessManager? _processManager;
  final ProcessUtils? _processUtils;
  final FlutterProjectFactory? _projectFactory;
  final ShutdownHooks? _shutdownHooks;
  final Signals? _signals;
  final Stdio? _stdio;
  final SystemClock? _systemClock;
  final AnsiTerminal? _terminal;
  final UserMessages? _userMessages;

  @override
  late final Artifacts artifacts = _artifacts ?? FakeArtifacts(fileSystem: fs);

  @override
  late final BotDetector botDetector = _botDetector ?? const FakeBotDetector(false);

  @override
  late final Cache cache = _cache ?? FakeCache(fileSystem: fs);

  @override
  late final Config config = _config ?? FakeConfig();

  @override
  late final CustomDevicesConfig customDevicesConfig =
      _customDevicesConfig ??
      CustomDevicesConfig.test(fileSystem: fs, logger: logger, platform: platform);

  @override
  late final FlutterVersion flutterVersion = _flutterVersion ?? FakeFlutterVersion();

  @override
  late final FileSystem fs = _fs ?? MemoryFileSystem.test();

  @override
  late final Git git = _git ?? Git(currentPlatform: platform, runProcessWith: processUtils);

  @override
  late final LocalEngineLocator localEngineLocator =
      _localEngineLocator ??
      LocalEngineLocator(
        userMessages: userMessages,
        logger: logger,
        platform: platform,
        fileSystem: fs,
        flutterRoot: Cache.flutterRoot ?? '',
      );

  @override
  late final Logger logger = _logger ?? BufferLogger.test();

  @override
  TestCompilerNativeAssetsBuilder? get nativeAssetsBuilder => _nativeAssetsBuilder;

  @override
  late final OperatingSystemUtils os = _os ?? FakeOperatingSystemUtils();

  @override
  late final OutputPreferences outputPreferences = _outputPreferences ?? OutputPreferences.test();

  @override
  late final Platform platform = _platform ?? FakePlatform();

  @override
  late final PreRunValidator preRunValidator = _preRunValidator ?? const NoOpPreRunValidator();

  @override
  late final ProcessManager processManager = _processManager ?? FakeProcessManager.any();

  @override
  late final ProcessUtils processUtils =
      _processUtils ?? ProcessUtils(processManager: processManager, logger: logger);

  @override
  late final FlutterProjectFactory projectFactory =
      _projectFactory ?? FlutterProjectFactory(fileSystem: fs, logger: logger);

  @override
  late final ShutdownHooks shutdownHooks = _shutdownHooks ?? ShutdownHooks();

  @override
  late final Signals signals = _signals ?? Signals.test();

  @override
  late final Stdio stdio = _stdio ?? FakeStdio();

  @override
  late final SystemClock systemClock = _systemClock ?? const SystemClock();

  @override
  late final AnsiTerminal terminal = _terminal ?? AnsiTerminal(stdio: stdio, platform: platform);

  @override
  late final UserMessages userMessages = _userMessages ?? UserMessages();

  @override
  FileSystemUtils get fileSystemUtils => FileSystemUtils(fileSystem: fs, platform: platform);
}

/// A [ToolContext] that dynamically delegates to [globals] for use in [testUsingContext].
class DelegatingToolContext extends Fake implements ToolContext {
  DelegatingToolContext({
    Artifacts? artifacts,
    BotDetector? botDetector,
    Cache? cache,
    Config? config,
    CustomDevicesConfig? customDevicesConfig,
    FlutterVersion? flutterVersion,
    FileSystem? fs,
    Git? git,
    LocalEngineLocator? localEngineLocator,
    Logger? logger,
    OperatingSystemUtils? os,
    OutputPreferences? outputPreferences,
    Platform? platform,
    PreRunValidator? preRunValidator,
    ProcessManager? processManager,
    ProcessUtils? processUtils,
    FlutterProjectFactory? projectFactory,
    ShutdownHooks? shutdownHooks,
    Signals? signals,
    Stdio? stdio,
    SystemClock? systemClock,
    AnsiTerminal? terminal,
    UserMessages? userMessages,
  }) : _artifacts = artifacts,
       _botDetector = botDetector,
       _cache = cache,
       _config = config,
       _customDevicesConfig = customDevicesConfig,
       _flutterVersion = flutterVersion,
       _fs = fs,
       _git = git,
       _localEngineLocator = localEngineLocator,
       _logger = logger,
       _os = os,
       _outputPreferences = outputPreferences,
       _platform = platform,
       _preRunValidator = preRunValidator,
       _processManager = processManager,
       _processUtils = processUtils,
       _projectFactory = projectFactory,
       _shutdownHooks = shutdownHooks,
       _signals = signals,
       _stdio = stdio,
       _systemClock = systemClock,
       _terminal = terminal,
       _userMessages = userMessages;

  final Artifacts? _artifacts;
  final BotDetector? _botDetector;
  final Cache? _cache;
  final Config? _config;
  final CustomDevicesConfig? _customDevicesConfig;
  final FlutterVersion? _flutterVersion;
  final FileSystem? _fs;
  final Git? _git;
  final LocalEngineLocator? _localEngineLocator;
  final Logger? _logger;
  final OperatingSystemUtils? _os;
  final OutputPreferences? _outputPreferences;
  final Platform? _platform;
  final PreRunValidator? _preRunValidator;
  final ProcessManager? _processManager;
  final ProcessUtils? _processUtils;
  final FlutterProjectFactory? _projectFactory;
  final ShutdownHooks? _shutdownHooks;
  final Signals? _signals;
  final Stdio? _stdio;
  final SystemClock? _systemClock;
  final AnsiTerminal? _terminal;
  final UserMessages? _userMessages;

  @override
  Artifacts get artifacts => _artifacts ?? globals.artifacts!;

  @override
  BotDetector get botDetector => _botDetector ?? globals.botDetector;

  @override
  Cache get cache => _cache ?? globals.cache;

  @override
  Config get config => _config ?? globals.config;

  @override
  CustomDevicesConfig get customDevicesConfig =>
      _customDevicesConfig ?? globals.customDevicesConfig;

  @override
  FlutterVersion get flutterVersion => _flutterVersion ?? globals.flutterVersion;

  @override
  FileSystem get fs => _fs ?? globals.fs;

  @override
  Git get git => _git ?? globals.git;

  @override
  LocalEngineLocator get localEngineLocator =>
      _localEngineLocator ??
      globals.localEngineLocator ??
      LocalEngineLocator(
        userMessages: userMessages,
        logger: logger,
        platform: platform,
        fileSystem: fs,
        flutterRoot: Cache.flutterRoot ?? '',
      );

  @override
  Logger get logger => _logger ?? globals.logger;

  @override
  OperatingSystemUtils get os => _os ?? globals.os;

  @override
  OutputPreferences get outputPreferences => _outputPreferences ?? globals.outputPreferences;

  @override
  Platform get platform => _platform ?? globals.platform;

  @override
  PreRunValidator get preRunValidator => _preRunValidator ?? const NoOpPreRunValidator();

  @override
  ProcessManager get processManager => _processManager ?? globals.processManager;

  @override
  ProcessUtils get processUtils => _processUtils ?? globals.processUtils;

  @override
  FlutterProjectFactory get projectFactory => _projectFactory ?? globals.projectFactory;

  @override
  ShutdownHooks get shutdownHooks => _shutdownHooks ?? globals.shutdownHooks;

  @override
  Signals get signals => _signals ?? globals.signals;

  @override
  Stdio get stdio => _stdio ?? globals.stdio;

  @override
  SystemClock get systemClock => _systemClock ?? globals.systemClock;

  @override
  AnsiTerminal get terminal => _terminal ?? globals.terminal;

  @override
  UserMessages get userMessages => _userMessages ?? globals.userMessages;

  @override
  FileSystemUtils get fileSystemUtils => FileSystemUtils(fileSystem: fs, platform: platform);
}

class FakeAndroidContext extends Fake implements AndroidContext {
  FakeAndroidContext({
    AndroidSdk? androidSdk,
    AndroidStudio? androidStudio,
    GradleUtils? gradleUtils,
    Java? java,
  }) : _androidSdk = androidSdk,
       _androidStudio = androidStudio,
       _gradleUtils = gradleUtils,
       _java = java;

  final AndroidSdk? _androidSdk;
  final AndroidStudio? _androidStudio;
  final GradleUtils? _gradleUtils;
  final Java? _java;

  @override
  AndroidSdk? get androidSdk => _androidSdk;

  @override
  AndroidStudio? get androidStudio => _androidStudio;

  @override
  late final GradleUtils gradleUtils = _gradleUtils ?? FakeGradleUtils();

  @override
  Java? get java => _java;
}

class FakeAppleContext extends Fake implements AppleContext {
  FakeAppleContext({
    CocoaPods? cocoaPods,
    CocoaPodsValidator? cocoapodsValidator,
    IOSSimulatorUtils? iosSimulatorUtils,
    IOSWorkflow? iosWorkflow,
    PlistParser? plistParser,
    XCDevice? xcdevice,
    Xcode? xcode,
    XcodeProjectInterpreter? xcodeProjectInterpreter,
  }) : _cocoaPods = cocoaPods,
       _cocoapodsValidator = cocoapodsValidator,
       _iosSimulatorUtils = iosSimulatorUtils,
       _iosWorkflow = iosWorkflow,
       _plistParser = plistParser,
       _xcdevice = xcdevice,
       _xcode = xcode,
       _xcodeProjectInterpreter = xcodeProjectInterpreter;

  final CocoaPods? _cocoaPods;
  final CocoaPodsValidator? _cocoapodsValidator;
  final IOSSimulatorUtils? _iosSimulatorUtils;
  final IOSWorkflow? _iosWorkflow;
  final PlistParser? _plistParser;
  final XCDevice? _xcdevice;
  final Xcode? _xcode;
  final XcodeProjectInterpreter? _xcodeProjectInterpreter;

  @override
  late final CocoaPods cocoaPods = _cocoaPods ?? FakeCocoaPods();

  @override
  late final CocoaPodsValidator cocoapodsValidator =
      _cocoapodsValidator ?? FakeCocoaPodsValidator();

  @override
  late final IOSSimulatorUtils iosSimulatorUtils = _iosSimulatorUtils ?? FakeIOSSimulatorUtils();

  @override
  late final IOSWorkflow iosWorkflow = _iosWorkflow ?? FakeIOSWorkflow();

  @override
  late final PlistParser plistParser = _plistParser ?? FakePlistParser();

  @override
  late final XCDevice xcdevice = _xcdevice ?? FakeXCDevice();

  @override
  late final Xcode xcode = _xcode ?? FakeXcode();

  @override
  late final XcodeProjectInterpreter xcodeProjectInterpreter =
      _xcodeProjectInterpreter ?? FakeXcodeProjectInterpreter();
}
