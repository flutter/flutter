// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/context_runner.dart';
import 'package:flutter_tools/src/usage.dart';
import 'package:flutter_tools/src/version.dart';

import 'context.dart';

export 'package:flutter_tools/src/base/context.dart' show Generator;

// A default value should be provided if one of the following criteria is met:
//    - The vast majority of tests should use this provider. For example,
//      [BufferLogger], [MemoryFileSystem].
//    - More TBD.
final Map<Type, Generator> _testbedDefaults = <Type, Generator>{
  // Keeps tests fast by avoid actual file system.
  FileSystem: () => MemoryFileSystem(style: platform.isWindows
      ? FileSystemStyle.windows
      : FileSystemStyle.posix),
  Logger: () => BufferLogger(), // Allows reading logs and prevents stdout.
  OutputPreferences: () => OutputPreferences(showColor: false), // configures BufferLogger to avoid color codes.
  Usage: () => NoOpUsage(), // prevent addition of analytics from burdening test mocks
  FlutterVersion: () => FakeFlutterVersion() // prevent requirement to mock git for test runner.
};

/// Manages interaction with the tool injection and runner system.
///
/// The Testbed automatically injects reasonable defaults through the context
/// DI system such as a [BufferLogger] and a [MemoryFileSytem].
///
/// Example:
///
/// Testing that a filesystem operation works as expected
///
///     void main() {
///       group('Example', () {
///         Testbed testbed;
///
///         setUp(() {
///           testbed = Testbed(setUp: () {
///             fs.file('foo').createSync()
///           });
///         })
///
///         test('Can delete a file', () => testBed.run(() {
///           expect(fs.file('foo').existsSync(), true);
///           fs.file('foo').deleteSync();
///           expect(fs.file('foo').existsSync(), false);
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

  final Future<void> Function() _setup;
  final Map<Type, Generator> _overrides;

  /// Runs `test` within a tool zone.
  ///
  /// `overrides` may be used to provide new context values for the single test
  /// case or override any context values from the setup.
  FutureOr<T> run<T>(FutureOr<T> Function() test, {Map<Type, Generator> overrides}) {
    final Map<Type, Generator> testOverrides = <Type, Generator>{
      ..._testbedDefaults,
      // Add the initial setUp overrides
      ...?_overrides,
      // Add the test-specific overrides
      ...?overrides,
    };
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
            }
          ),
          body: () async {
            Cache.flutterRoot = '';
            if (_setup != null) {
              await _setup();
            }
            await test();
            Cache.flutterRoot = originalFlutterRoot;
            for (MapEntry<Timer, StackTrace> entry in timers.entries) {
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
  Stream<Map<String, Object>> get onSend => const Stream<Object>.empty();

  @override
  void printWelcome() {}

  @override
  void sendCommand(String command, {Map<String, String> parameters}) {}

  @override
  void sendEvent(String category, String parameter,{ Map<String, String> parameters }) {}

  @override
  void sendException(dynamic exception, StackTrace trace) {}

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
  void addCredentials(
      Uri url, String realm, HttpClientCredentials credentials) {}

  @override
  void addProxyCredentials(
      String host, int port, String realm, HttpClientCredentials credentials) {}

  @override
  set authenticate(
      Future<bool> Function(Uri url, String scheme, String realm) f) {}

  @override
  set authenticateProxy(
      Future<bool> Function(String host, int port, String scheme, String realm)
          f) {}

  @override
  set badCertificateCallback(
      bool Function(X509Certificate cert, String host, int port) callback) {}

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
  HttpHeaders get headers => null;

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
}

class FakeHttpClientResponse extends Stream<Uint8List>
    implements HttpClientResponse {

  final Stream<List<int>> _content = const Stream<List<int>>.empty();

  @override
  X509Certificate get certificate => null;

  @override
  HttpClientResponseCompressionState get compressionState => null;

  @override
  HttpConnectionInfo get connectionInfo => null;

  @override
  int get contentLength => 0;

  @override
  List<Cookie> get cookies => <Cookie>[];

  @override
  Future<Socket> detachSocket() async {
    return null;
  }

  @override
  HttpHeaders get headers => null;

  @override
  bool get isRedirect => null;

  @override
  StreamSubscription<Uint8List> listen(void Function(Uint8List event) onData,
      {Function onError, void Function() onDone, bool cancelOnError}) {
    return _content.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError
    );
  }

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => null;

  @override
  Future<HttpClientResponse> redirect(
      [String method, Uri url, bool followLoops]) {
    return null;
  }

  @override
  List<RedirectInfo> get redirects => const <RedirectInfo>[];

  @override
  int get statusCode => HttpStatus.badRequest;
  void sendTiming(String category, String variableName, Duration duration, {String label}) {}
}

class FakeFlutterVersion implements FlutterVersion {
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
