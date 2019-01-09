import 'package:meta/meta.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../globals.dart';

/// Message logged by the test process to signal that its main method has begun
/// execution.
///
/// The test harness responds by starting the [_kTestStartupTimeout] countdown.
/// The CPU may be throttled, which can cause a long delay in between when the
/// process is spawned and when dart code execution begins; we don't want to
/// hold that against the test.
const String kStartTimeoutTimerMessage = 'sky_shell test process has entered main method';

/// The name of the test configuration file that will be discovered by the
/// test harness if it exists in the project directory hierarchy.
const String _kTestConfigFileName = 'flutter_test_config.dart';

/// The name of the file that signals the root of the project and that will
/// cause the test harness to stop scanning for configuration files.
const String _kProjectRootSentinel = 'pubspec.yaml';

typedef Finalizer = Future<void> Function();

/// Generates the bootstrap entry point script that will be used to launch an
/// individual test file.
///
/// The [testUrl] argument specifies the path to the test file that is being
/// launched.
///
/// The [host] argument specifies the address at which the test harness is
/// running.
///
/// If [testConfigFile] is specified, it must follow the conventions of test
/// configuration files as outlined in the [flutter_test] library. By default,
/// the test file will be launched directly.
///
/// The [updateGoldens] argument will set the [autoUpdateGoldens] global
/// variable in the [flutter_test] package before invoking the test.
String _generateTestBootstrap({
  @required Uri testUrl,
  @required InternetAddress host,
  File testConfigFile,
  bool updateGoldens = false,
}) {
  assert(testUrl != null);
  assert(host != null);
  assert(updateGoldens != null);

  final String websocketUrl = host.type == InternetAddressType.IPv4
      ? 'ws://${host.address}'
      : 'ws://[${host.address}]';
  final String encodedWebsocketUrl = Uri.encodeComponent(websocketUrl);

  final StringBuffer buffer = StringBuffer();
  buffer.write('''
import 'dart:async';
import 'dart:convert';
import 'dart:io';  // ignore: dart_io_import
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:test_api/src/remote_listener.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:stack_trace/stack_trace.dart';

import '$testUrl' as test;
''');
  if (testConfigFile != null) {
    buffer.write('''
import '${Uri.file(testConfigFile.path)}' as test_config;
''');
  }
  buffer.write('''

/// Returns a serialized test suite.
StreamChannel<dynamic> serializeSuite(Function getMain(),
    {bool hidePrints = true, Future<dynamic> beforeLoad()}) {
  return RemoteListener.start(getMain,
      hidePrints: hidePrints, beforeLoad: beforeLoad);
}

/// Capture any top-level errors (mostly lazy syntax errors, since other are
/// caught below) and report them to the parent isolate.
void catchIsolateErrors() {
  final ReceivePort errorPort = ReceivePort();
  // Treat errors non-fatal because otherwise they'll be double-printed.
  Isolate.current.setErrorsFatal(false);
  Isolate.current.addErrorListener(errorPort.sendPort);
  errorPort.listen((dynamic message) {
    // Masquerade as an IsolateSpawnException because that's what this would
    // be if the error had been detected statically.
    final IsolateSpawnException error = IsolateSpawnException(message[0]);
    final Trace stackTrace =
        message[1] == null ? Trace(const <Frame>[]) : Trace.parse(message[1]);
    Zone.current.handleUncaughtError(error, stackTrace);
  });
}


void main() {
  print('$kStartTimeoutTimerMessage');
  String serverPort = Platform.environment['SERVER_PORT'];
  String server = Uri.decodeComponent('$encodedWebsocketUrl:\$serverPort');
  StreamChannel channel = serializeSuite(() {
    catchIsolateErrors();
    goldenFileComparator = new LocalFileComparator(Uri.parse('$testUrl'));
    autoUpdateGoldenFiles = $updateGoldens;
''');
  if (testConfigFile != null) {
    buffer.write('''
    return () => test_config.main(test.main);
''');
  } else {
    buffer.write('''
    return test.main;
''');
  }
  buffer.write('''
  });
  WebSocket.connect(server).then((WebSocket socket) {
    socket.map((dynamic x) {
      assert(x is String);
      return json.decode(x);
    }).pipe(channel.sink);
    socket.addStream(channel.stream.map(json.encode));
  });
}
''');
  return buffer.toString();
}

String createListenerDart(List<Finalizer> finalizers, int ourTestCount,
      String testPath, InternetAddress host, bool updateGoldens) {
    // Prepare a temporary directory to store the Dart file that will talk to us.
    final Directory tempDir = fs.systemTempDirectory.createTempSync('flutter_test_listener.');
    finalizers.add(() async {
      printTrace('test $ourTestCount: deleting temporary directory');
      tempDir.deleteSync(recursive: true);
    });

    // Prepare the Dart file that will talk to us and start the test.
    final File listenerFile = fs.file('${tempDir.path}/listener.dart');
    listenerFile.createSync();
    listenerFile.writeAsStringSync(_generateTestMain(
      testUrl: fs.path.toUri(fs.path.absolute(testPath)),
      host: host,
      updateGoldens: updateGoldens,
    ));
    return listenerFile.path;
  }

  String _generateTestMain({
    Uri testUrl,
    InternetAddress host,
    bool updateGoldens,
  }) {
    assert(testUrl.scheme == 'file');
    File testConfigFile;
    Directory directory = fs.file(testUrl).parent;
    while (directory.path != directory.parent.path) {
      final File configFile = directory.childFile(_kTestConfigFileName);
      if (configFile.existsSync()) {
        printTrace('Discovered $_kTestConfigFileName in ${directory.path}');
        testConfigFile = configFile;
        break;
      }
      if (directory.childFile(_kProjectRootSentinel).existsSync()) {
        printTrace('Stopping scan for $_kTestConfigFileName; '
            'found project root at ${directory.path}');
        break;
      }
      directory = directory.parent;
    }
    return _generateTestBootstrap(
      testUrl: testUrl,
      testConfigFile: testConfigFile,
      host: host,
      updateGoldens: updateGoldens,
    );
  }