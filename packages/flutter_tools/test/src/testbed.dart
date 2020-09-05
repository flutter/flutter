// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/process.dart';

import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/context_runner.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:meta/meta.dart';
import 'package:process/process.dart';

import 'common.dart' as tester;
import 'context.dart';
import 'fake_process_manager.dart';
import 'throwing_pub.dart';

export 'package:flutter_tools/src/base/context.dart' show Generator;

// A default value should be provided if the vast majority of tests should use
// this provider. For example, [BufferLogger], [MemoryFileSystem].
final Map<Type, Generator> _testbedDefaults = <Type, Generator>{
  // Keeps tests fast by avoiding the actual file system.
  FileSystem: () => MemoryFileSystem(style: globals.platform.isWindows ? FileSystemStyle.windows : FileSystemStyle.posix),
  ProcessManager: () => FakeProcessManager.any(),
  Logger: () => BufferLogger(
    terminal: AnsiTerminal(stdio: globals.stdio, platform: globals.platform),  // Danger, using real stdio.
    outputPreferences: OutputPreferences.test(),
  ), // Allows reading logs and prevents stdout.
  OperatingSystemUtils: () => FakeOperatingSystemUtils(),
  OutputPreferences: () => OutputPreferences.test(), // configures BufferLogger to avoid color codes.
  Usage: () => NoOpUsage(), // prevent addition of analytics from burdening test mocks
  FlutterVersion: () => FakeFlutterVersion(), // prevent requirement to mock git for test runner.
  Signals: () => FakeSignals(),  // prevent registering actual signal handlers.
  Pub: () => ThrowingPub(), // prevent accidental invocations of pub.
};

/// Manages interaction with the tool injection and runner system.
///
/// The Testbed automatically injects reasonable defaults through the context
/// DI system such as a [BufferLogger] and a [MemoryFileSytem].
///
/// Example:
///
/// Testing that a filesystem operation works as expected:
///
///     void main() {
///       group('Example', () {
///         Testbed testbed;
///
///         setUp(() {
///           testbed = Testbed(setUp: () {
///             globals.fs.file('foo').createSync()
///           });
///         })
///
///         test('Can delete a file', () => testbed.run(() {
///           expect(globals.fs.file('foo').existsSync(), true);
///           globals.fs.file('foo').deleteSync();
///           expect(globals.fs.file('foo').existsSync(), false);
///         }));
///       });
///     }
///
/// For a more detailed example, see the code in test_compiler_test.dart.
class Testbed {
  /// Creates a new [TestBed]
  ///
  /// `overrides` provides more overrides in addition to the test defaults.
  /// `setup` may be provided to apply mocks within the tool managed zone,
  /// including any specified overrides.
  Testbed({FutureOr<void> Function() setup, Map<Type, Generator> overrides})
      : _setup = setup,
        _overrides = overrides;

  final FutureOr<void> Function() _setup;
  final Map<Type, Generator> _overrides;

  /// Runs the `test` within a tool zone.
  ///
  /// Unlike [run], this sets up a test group on its own.
  @isTest
  void test<T>(String name, FutureOr<T> Function() test, {Map<Type, Generator> overrides}) {
    tester.test(name, () {
      return run(test, overrides: overrides);
    });
  }

  /// Runs `test` within a tool zone.
  ///
  /// `overrides` may be used to provide new context values for the single test
  /// case or override any context values from the setup.
  Future<T> run<T>(FutureOr<T> Function() test, {Map<Type, Generator> overrides}) {
    final Map<Type, Generator> testOverrides = <Type, Generator>{
      ..._testbedDefaults,
      // Add the initial setUp overrides
      ...?_overrides,
      // Add the test-specific overrides
      ...?overrides,
    };
    if (testOverrides.containsKey(ProcessUtils)) {
      throw StateError('Do not inject ProcessUtils for testing, use ProcessManager instead.');
    }
    // Cache the original flutter root to restore after the test case.
    final String originalFlutterRoot = Cache.flutterRoot;
    // Track pending timers to verify that they were correctly cleaned up.
    final Map<Timer, StackTrace> timers = <Timer, StackTrace>{};

    return HttpOverrides.runZoned(() {
      return runInContext<T>(() {
        return context.run<T>(
          name: 'testbed',
          overrides: testOverrides,
          zoneSpecification: ZoneSpecification(
            createTimer: (Zone self, ZoneDelegate parent, Zone zone, Duration duration, void Function() timer) {
              final Timer result = parent.createTimer(zone, duration, timer);
              timers[result] = StackTrace.current;
              return result;
            },
            createPeriodicTimer: (Zone self, ZoneDelegate parent, Zone zone, Duration period, void Function(Timer) timer) {
              final Timer result = parent.createPeriodicTimer(zone, period, timer);
              timers[result] = StackTrace.current;
              return result;
            },
          ),
          body: () async {
            Cache.flutterRoot = '';
            if (_setup != null) {
              await _setup();
            }
            await test();
            Cache.flutterRoot = originalFlutterRoot;
            for (final MapEntry<Timer, StackTrace> entry in timers.entries) {
              if (entry.key.isActive) {
                throw StateError('A Timer was active at the end of a test: ${entry.value}');
              }
            }
            return null;
          });
      });
    }, createHttpClient: (SecurityContext c) => FakeHttpClient());
  }
}

/// A no-op implementation of [Usage] for testing.
class NoOpUsage implements Usage {
  @override
  bool enabled = false;

  @override
  bool suppressAnalytics = true;

  @override
  String get clientId => 'test';

  @override
  Future<void> ensureAnalyticsSent() {
    return null;
  }

  @override
  bool get isFirstRun => false;

  @override
  Stream<Map<String, Object>> get onSend => const Stream<Map<String, Object>>.empty();

  @override
  void printWelcome() {}

  @override
  void sendCommand(String command, {Map<String, String> parameters}) {}

  @override
  void sendEvent(String category, String parameter, {
    String label,
    int value,
    Map<String, String> parameters,
  }) {}

  @override
  void sendException(dynamic exception) {}

  @override
  void sendTiming(String category, String variableName, Duration duration, { String label }) {}
}

class FakeHttpClient implements HttpClient {
  @override
  bool autoUncompress;

  @override
  Duration connectionTimeout;

  @override
  Duration idleTimeout;

  @override
  int maxConnectionsPerHost;

  @override
  String userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}

  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) {}

  @override
  set authenticate(Future<bool> Function(Uri url, String scheme, String realm) f) {}

  @override
  set authenticateProxy(Future<bool> Function(String host, int port, String scheme, String realm) f) {}

  @override
  set badCertificateCallback(bool Function(X509Certificate cert, String host, int port) callback) {}

  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) async {
    return FakeHttpClientRequest();
  }

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) async {
    return FakeHttpClientRequest();
  }

  @override
  set findProxy(String Function(Uri url) f) {}

  @override
  Future<HttpClientRequest> get(String host, int port, String path) async {
    return FakeHttpClientRequest();
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return FakeHttpClientRequest();
  }

  @override
  Future<HttpClientRequest> head(String host, int port, String path) async {
    return FakeHttpClientRequest();
  }

  @override
  Future<HttpClientRequest> headUrl(Uri url) async {
    return FakeHttpClientRequest();
  }

  @override
  Future<HttpClientRequest> open(String method, String host, int port, String path) async {
    return FakeHttpClientRequest();
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return FakeHttpClientRequest();
  }

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) async {
    return FakeHttpClientRequest();
  }

  @override
  Future<HttpClientRequest> patchUrl(Uri url) async {
    return FakeHttpClientRequest();
  }

  @override
  Future<HttpClientRequest> post(String host, int port, String path) async {
    return FakeHttpClientRequest();
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    return FakeHttpClientRequest();
  }

  @override
  Future<HttpClientRequest> put(String host, int port, String path) async {
    return FakeHttpClientRequest();
  }

  @override
  Future<HttpClientRequest> putUrl(Uri url) async {
    return FakeHttpClientRequest();
  }
}

class FakeHttpClientRequest implements HttpClientRequest {
  FakeHttpClientRequest();

  @override
  bool bufferOutput;

  @override
  int contentLength;

  @override
  Encoding encoding;

  @override
  bool followRedirects;

  @override
  int maxRedirects;

  @override
  bool persistentConnection;

  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) async {}

  @override
  Future<HttpClientResponse> close() async {
    return FakeHttpClientResponse();
  }

  @override
  HttpConnectionInfo get connectionInfo => null;

  @override
  List<Cookie> get cookies => <Cookie>[];

  @override
  Future<HttpClientResponse> get done => null;

  @override
  Future<void> flush() {
    return Future<void>.value();
  }

  @override
  HttpHeaders get headers => FakeHttpHeaders();

  @override
  String get method => null;

  @override
  Uri get uri => null;

  @override
  void write(Object obj) {}

  @override
  void writeAll(Iterable<Object> objects, [String separator = '']) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object obj = '']) {}

  // TODO(zichangguo): remove the ignore after the change in dart:io lands.
  @override
  // ignore: override_on_non_overriding_member
  void abort([Object exception, StackTrace stackTrace]) {}
}

class FakeHttpClientResponse implements HttpClientResponse {
  final Stream<List<int>> _delegate = Stream<List<int>>.fromIterable(const Iterable<List<int>>.empty());

  @override
  final HttpHeaders headers = FakeHttpHeaders();

  @override
  X509Certificate get certificate => null;

  @override
  HttpConnectionInfo get connectionInfo => null;

  @override
  int get contentLength => 0;

  @override
  HttpClientResponseCompressionState get compressionState {
    return HttpClientResponseCompressionState.decompressed;
  }

  @override
  List<Cookie> get cookies => null;

  @override
  Future<Socket> detachSocket() {
    return Future<Socket>.error(UnsupportedError('Mocked response'));
  }

  @override
  bool get isRedirect => false;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event) onData, { Function onError, void Function() onDone, bool cancelOnError }) {
    return const Stream<List<int>>.empty().listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  bool get persistentConnection => null;

  @override
  String get reasonPhrase => null;

  @override
  Future<HttpClientResponse> redirect([ String method, Uri url, bool followLoops ]) {
    return Future<HttpClientResponse>.error(UnsupportedError('Mocked response'));
  }

  @override
  List<RedirectInfo> get redirects => <RedirectInfo>[];

  @override
  int get statusCode => 400;

  @override
  Future<bool> any(bool Function(List<int> element) test) {
    return _delegate.any(test);
  }

  @override
  Stream<List<int>> asBroadcastStream({
    void Function(StreamSubscription<List<int>> subscription) onListen,
    void Function(StreamSubscription<List<int>> subscription) onCancel,
  }) {
    return _delegate.asBroadcastStream(onListen: onListen, onCancel: onCancel);
  }

  @override
  Stream<E> asyncExpand<E>(Stream<E> Function(List<int> event) convert) {
    return _delegate.asyncExpand<E>(convert);
  }

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(List<int> event) convert) {
    return _delegate.asyncMap<E>(convert);
  }

  @override
  Stream<R> cast<R>() {
    return _delegate.cast<R>();
  }

  @override
  Future<bool> contains(Object needle) {
    return _delegate.contains(needle);
  }

  @override
  Stream<List<int>> distinct([bool Function(List<int> previous, List<int> next) equals]) {
    return _delegate.distinct(equals);
  }

  @override
  Future<E> drain<E>([E futureValue]) {
    return _delegate.drain<E>(futureValue);
  }

  @override
  Future<List<int>> elementAt(int index) {
    return _delegate.elementAt(index);
  }

  @override
  Future<bool> every(bool Function(List<int> element) test) {
    return _delegate.every(test);
  }

  @override
  Stream<S> expand<S>(Iterable<S> Function(List<int> element) convert) {
    return _delegate.expand(convert);
  }

  @override
  Future<List<int>> get first => _delegate.first;

  @override
  Future<List<int>> firstWhere(
    bool Function(List<int> element) test, {
    List<int> Function() orElse,
  }) {
    return _delegate.firstWhere(test, orElse: orElse);
  }

  @override
  Future<S> fold<S>(S initialValue, S Function(S previous, List<int> element) combine) {
    return _delegate.fold<S>(initialValue, combine);
  }

  @override
  Future<dynamic> forEach(void Function(List<int> element) action) {
    return _delegate.forEach(action);
  }

  @override
  Stream<List<int>> handleError(
    Function onError, {
    bool Function(dynamic error) test,
  }) {
    return _delegate.handleError(onError, test: test);
  }

  @override
  bool get isBroadcast => _delegate.isBroadcast;

  @override
  Future<bool> get isEmpty => _delegate.isEmpty;

  @override
  Future<String> join([String separator = '']) {
    return _delegate.join(separator);
  }

  @override
  Future<List<int>> get last => _delegate.last;

  @override
  Future<List<int>> lastWhere(
    bool Function(List<int> element) test, {
    List<int> Function() orElse,
  }) {
    return _delegate.lastWhere(test, orElse: orElse);
  }

  @override
  Future<int> get length => _delegate.length;

  @override
  Stream<S> map<S>(S Function(List<int> event) convert) {
    return _delegate.map<S>(convert);
  }

  @override
  Future<dynamic> pipe(StreamConsumer<List<int>> streamConsumer) {
    return _delegate.pipe(streamConsumer);
  }

  @override
  Future<List<int>> reduce(List<int> Function(List<int> previous, List<int> element) combine) {
    return _delegate.reduce(combine);
  }

  @override
  Future<List<int>> get single => _delegate.single;

  @override
  Future<List<int>> singleWhere(bool Function(List<int> element) test, {List<int> Function() orElse}) {
    return _delegate.singleWhere(test, orElse: orElse);
  }

  @override
  Stream<List<int>> skip(int count) {
    return _delegate.skip(count);
  }

  @override
  Stream<List<int>> skipWhile(bool Function(List<int> element) test) {
    return _delegate.skipWhile(test);
  }

  @override
  Stream<List<int>> take(int count) {
    return _delegate.take(count);
  }

  @override
  Stream<List<int>> takeWhile(bool Function(List<int> element) test) {
    return _delegate.takeWhile(test);
  }

  @override
  Stream<List<int>> timeout(
    Duration timeLimit, {
    void Function(EventSink<List<int>> sink) onTimeout,
  }) {
    return _delegate.timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<List<List<int>>> toList() {
    return _delegate.toList();
  }

  @override
  Future<Set<List<int>>> toSet() {
    return _delegate.toSet();
  }

  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) {
    return _delegate.transform<S>(streamTransformer);
  }

  @override
  Stream<List<int>> where(bool Function(List<int> event) test) {
    return _delegate.where(test);
  }
}

/// A fake [HttpHeaders] that ignores all writes.
class FakeHttpHeaders extends HttpHeaders {
  @override
  List<String> operator [](String name) => <String>[];

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) { }

  @override
  void clear() { }

  @override
  void forEach(void Function(String name, List<String> values) f) { }

  @override
  void noFolding(String name) { }

  @override
  void remove(String name, Object value) { }

  @override
  void removeAll(String name) { }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) { }

  @override
  String value(String name) => null;
}

class FakeFlutterVersion implements FlutterVersion {
  @override
  void fetchTagsAndUpdate() {  }

  @override
  String get channel => 'master';

  @override
  Future<void> checkFlutterVersionFreshness() async { }

  @override
  bool checkRevisionAncestry({String tentativeDescendantRevision, String tentativeAncestorRevision}) {
    throw UnimplementedError();
  }

  @override
  String get dartSdkVersion => '12';

  @override
  String get engineRevision => '42.2';

  @override
  String get engineRevisionShort => '42';

  @override
  Future<void> ensureVersionFile() async { }

  @override
  String get frameworkAge => null;

  @override
  String get frameworkCommitDate => null;

  @override
  String get frameworkDate => null;

  @override
  String get frameworkRevision => null;

  @override
  String get frameworkRevisionShort => null;

  @override
  String get frameworkVersion => null;

  @override
  GitTagVersion get gitTagVersion => null;

  @override
  String getBranchName({bool redactUnknownBranches = false}) {
    return 'master';
  }

  @override
  String getVersionString({bool redactUnknownBranches = false}) {
    return 'v0.0.0';
  }

  @override
  bool get isMaster => true;

  @override
  String get repositoryUrl => null;

  @override
  Map<String, Object> toJson() {
    return null;
  }
}

// A test implementation of [FeatureFlags] that allows enabling without reading
// config. If not otherwise specified, all values default to false.
class TestFeatureFlags implements FeatureFlags {
  TestFeatureFlags({
    this.isLinuxEnabled = false,
    this.isMacOSEnabled = false,
    this.isWebEnabled = false,
    this.isWindowsEnabled = false,
    this.isSingleWidgetReloadEnabled = false,
    this.isAndroidEnabled = true,
    this.isIOSEnabled = true,
    this.isFuchsiaEnabled = false,
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
  final bool isSingleWidgetReloadEnabled;

  @override
  final bool isAndroidEnabled;

  @override
  final bool isIOSEnabled;

  @override
  final bool isFuchsiaEnabled;

  @override
  bool isEnabled(Feature feature) {
    switch (feature) {
      case flutterWebFeature:
        return isWebEnabled;
      case flutterLinuxDesktopFeature:
        return isLinuxEnabled;
      case flutterMacOSDesktopFeature:
        return isMacOSEnabled;
      case flutterWindowsDesktopFeature:
        return isWindowsEnabled;
      case singleWidgetReload:
        return isSingleWidgetReloadEnabled;
      case flutterAndroidFeature:
        return isAndroidEnabled;
      case flutterIOSFeature:
        return isIOSEnabled;
      case flutterFuchsiaFeature:
        return isFuchsiaEnabled;
    }
    return false;
  }
}

class DelegateLogger implements Logger {
  DelegateLogger(this.delegate);

  final Logger delegate;
  Status status;

  @override
  bool get quiet => delegate.quiet;

  @override
  set quiet(bool value) => delegate.quiet;

  @override
  bool get hasTerminal => delegate.hasTerminal;

  @override
  bool get isVerbose => delegate.isVerbose;

  @override
  void printError(String message, {StackTrace stackTrace, bool emphasis, TerminalColor color, int indent, int hangingIndent, bool wrap}) {
    delegate.printError(
      message,
      stackTrace: stackTrace,
      emphasis: emphasis,
      color: color,
      indent: indent,
      hangingIndent: hangingIndent,
      wrap: wrap,
    );
  }

  @override
  void printStatus(String message, {bool emphasis, TerminalColor color, bool newline, int indent, int hangingIndent, bool wrap}) {
    delegate.printStatus(message,
      emphasis: emphasis,
      color: color,
      indent: indent,
      hangingIndent: hangingIndent,
      wrap: wrap,
    );
  }

  @override
  void printTrace(String message) {
    delegate.printTrace(message);
  }

  @override
  void sendEvent(String name, [Map<String, dynamic> args]) {
    delegate.sendEvent(name, args);
  }

  @override
  Status startProgress(String message, {Duration timeout, String progressId, bool multilineOutput = false, int progressIndicatorPadding = kDefaultStatusPadding}) {
    return status;
  }

  @override
  bool get supportsColor => delegate.supportsColor;

  @override
  void clear() => delegate.clear();
}

/// An implementation of the Cache which does not download or require locking.
class FakeCache implements Cache {
  @override
  bool includeAllPlatforms;

  @override
  Set<String> platformOverrideArtifacts;

  @override
  bool useUnsignedMacBinaries;

  @override
  Future<bool> areRemoteArtifactsAvailable({String engineVersion, bool includeAllPlatforms = true}) async {
    return true;
  }

  @override
  String get dartSdkVersion => null;

  @override
  String get storageBaseUrl => null;

  @override
  MapEntry<String, String> get dyLdLibEntry => const MapEntry<String, String>('DYLD_LIBRARY_PATH', '');

  @override
  String get engineRevision => null;

  @override
  Directory getArtifactDirectory(String name) {
    return globals.fs.currentDirectory;
  }

  @override
  Directory getCacheArtifacts() {
    return globals.fs.currentDirectory;
  }

  @override
  Directory getCacheDir(String name) {
    return globals.fs.currentDirectory;
  }

  @override
  Directory getDownloadDir() {
    return globals.fs.currentDirectory;
  }

  @override
  Directory getRoot() {
    return globals.fs.currentDirectory;
  }

  @override
  File getLicenseFile() {
    return globals.fs.currentDirectory.childFile('LICENSE');
  }

  @override
  File getStampFileFor(String artifactName) {
    throw UnsupportedError('Not supported in the fake Cache');
  }

  @override
  String getStampFor(String artifactName) {
    throw UnsupportedError('Not supported in the fake Cache');
  }

  @override
  String getVersionFor(String artifactName) {
    throw UnsupportedError('Not supported in the fake Cache');
  }

  @override
  Directory getWebSdkDirectory() {
    return globals.fs.currentDirectory;
  }

  @override
  bool isOlderThanToolsStamp(FileSystemEntity entity) {
    return false;
  }

  @override
  bool isUpToDate() {
    return true;
  }

  @override
  void setStampFor(String artifactName, String version) {
    throw UnsupportedError('Not supported in the fake Cache');
  }

  @override
  Future<void> updateAll(Set<DevelopmentArtifact> requiredArtifacts) async {
  }

  @override
  Future<bool> doesRemoteExist(String message, Uri url) async {
    return true;
  }

  @override
  void clearStampFiles() {}
}
