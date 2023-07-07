// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dds/devtools_server.dart';
import 'package:devtools_shared/devtools_test_utils.dart';
import 'package:vm_service/vm_service.dart';

const verbose = true;

class DevToolsServerDriver {
  DevToolsServerDriver._(
    this._process,
    this._stdin,
    Stream<String> _stdout,
    Stream<String> _stderr,
  )   : stdout = _convertToMapStream(_stdout),
        stderr = _stderr.map((line) {
          _trace('<== STDERR $line');
          return line;
        });

  final Process _process;
  final Stream<Map<String, dynamic>?> stdout;
  final Stream<String> stderr;
  final StringSink _stdin;

  void write(Map<String, dynamic> request) {
    final line = jsonEncode(request);
    _trace('==> $line');
    _stdin.writeln(line);
  }

  static Stream<Map<String, dynamic>?> _convertToMapStream(
    Stream<String> stream,
  ) {
    return stream.map((line) {
      _trace('<== $line');
      return line;
    }).map((line) {
      try {
        return jsonDecode(line) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }).where((item) => item != null);
  }

  static void _trace(String message) {
    if (verbose) {
      print(message);
    }
  }

  bool kill() => _process.kill();

  static Future<DevToolsServerDriver> create({
    int port = 0,
    int? tryPorts,
    List<String> additionalArgs = const [],
  }) async {
    final script = Platform.script.resolveUri(
      Uri.parse('utils/serve_devtools.dart'),
    );
    final args = [
      script.toFilePath(),
      '--machine',
      '--port',
      '$port',
      ...additionalArgs,
    ];

    if (tryPorts != null) {
      args.addAll(['--try-ports', '$tryPorts']);
    }

    if (useChromeHeadless && headlessModeIsSupported) {
      args.add('--headless');
    }
    final Process process = await Process.start(
      Platform.resolvedExecutable,
      args,
    );

    return DevToolsServerDriver._(
      process,
      process.stdin,
      process.stdout.transform(utf8.decoder).transform(const LineSplitter()),
      process.stderr.transform(utf8.decoder).transform(const LineSplitter()),
    );
  }
}

class DevToolsServerTestController {
  static const defaultDelay = Duration(milliseconds: 500);

  late CliAppFixture appFixture;

  late DevToolsServerDriver server;

  final completers = <String, Completer<Map<String, dynamic>>>{};

  /// A broadcast stream controller for streaming events from the server.
  late StreamController<Map<String, dynamic>> eventController;

  /// A broadcast stream of events from the server.
  ///
  /// Listening for "server.started" events on this stream may be unreliable
  /// because it may have occurred before the test starts. Use the
  /// [serverStartedEvent] instead.
  Stream<Map<String, dynamic>> get events => eventController.stream;

  /// Completer that signals when the server started event has been received.
  late Completer<Map<String, dynamic>> serverStartedEvent;

  final Map<String, String> registeredServices = {};

  /// A list of PIDs for Chrome instances spawned by tests that should be
  /// cleaned up.
  final List<int> browserPids = [];

  late StreamSubscription<String> stderrSub;

  late StreamSubscription<Map<String, dynamic>?> stdoutSub;

  Future<void> setUp() async {
    serverStartedEvent = Completer<Map<String, dynamic>>();
    eventController = StreamController<Map<String, dynamic>>.broadcast();

    // Start the command-line server.
    server = await DevToolsServerDriver.create();

    // Fail tests on any stderr.
    stderrSub = server.stderr.listen((text) => throw 'STDERR: $text');
    stdoutSub = server.stdout.listen((map) {
      if (map!.containsKey('id')) {
        if (map.containsKey('result')) {
          completers[map['id']]!.complete(map['result']);
        } else {
          completers[map['id']]!.completeError(map['error']);
        }
      } else if (map.containsKey('event')) {
        if (map['event'] == 'server.started') {
          serverStartedEvent.complete(map);
        }
        eventController.add(map);
      }
    });

    await serverStartedEvent.future;
    await startApp();
  }

  Future<void> tearDown() async {
    browserPids
      ..forEach((pid) => Process.killPid(pid, ProcessSignal.sigkill))
      ..clear();
    await stdoutSub.cancel();
    await stderrSub.cancel();
    server.kill();
    await appFixture.teardown();
  }

  Future<Map<String, dynamic>> sendLaunchDevToolsRequest({
    required bool useVmService,
    String? page,
    bool notify = false,
    bool reuseWindows = false,
  }) async {
    final launchEvent =
        events.where((e) => e['event'] == 'client.launch').first;
    if (useVmService) {
      await appFixture.serviceConnection.callMethod(
        registeredServices[DevToolsServer.launchDevToolsService]!,
        args: {
          'reuseWindows': reuseWindows,
          'page': page,
          'notify': notify,
        },
      );
    } else {
      await send(
        'devTools.launch',
        {
          'vmServiceUri': appFixture.serviceUri.toString(),
          'reuseWindows': reuseWindows,
          'page': page,
        },
      );
    }
    final response = await launchEvent;
    final pid = response['params']['pid'];
    if (pid != null) {
      browserPids.add(pid);
    }
    return response['params'];
  }

  Future<void> startApp() async {
    final appUri =
        Platform.script.resolveUri(Uri.parse('fixtures/empty_dart_app.dart'));
    appFixture = await CliAppFixture.create(appUri.toFilePath());

    // Track services method names as they're registered.
    appFixture.serviceConnection
        .onEvent(EventStreams.kService)
        .where((e) => e.kind == EventKind.kServiceRegistered)
        .listen((e) => registeredServices[e.service!] = e.method!);
    await appFixture.serviceConnection.streamListen(EventStreams.kService);
    await appFixture.onAppStarted;
  }

  int nextId = 0;
  Future<Map<String, dynamic>> send(
    String method, [
    Map<String, dynamic>? params,
  ]) {
    final id = (nextId++).toString();
    completers[id] = Completer<Map<String, dynamic>>();
    server.write({'id': id.toString(), 'method': method, 'params': params});
    return completers[id]!.future;
  }

  /// Waits for the server's client list to be updated with the expected state,
  /// and then returns the client list.
  ///
  /// It may take time for the servers client list to be updated as the web app
  /// connects, so this helper just polls and waits for the expected state. If
  /// the expected state is never found, the test will timeout.
  Future<Map<String, dynamic>> waitForClients({
    bool? requiredConnectionState,
    String? requiredPage,
    bool expectNone = false,
    bool useLongTimeout = false,
    Duration delayDuration = defaultDelay,
  }) async {
    late Map<String, dynamic> serverResponse;

    final isOnPage = (client) => client['currentPage'] == requiredPage;
    final hasConnectionState = (client) => requiredConnectionState ?? false
        // If we require a connected client, also require a non-null page. This
        // avoids a race in tests where we may proceed to send messages to a client
        // that is not fully initialised.
        ? (client['hasConnection'] && client['currentPage'] != null)
        : !client['hasConnection'];

    await _waitFor(
      () async {
        // Await a short delay to give the client time to connect.
        await delay();

        serverResponse = await send('client.list');
        final clients = serverResponse['clients'];
        return clients is List &&
            (clients.isEmpty == expectNone) &&
            (requiredPage == null || clients.any(isOnPage)) &&
            (requiredConnectionState == null ||
                clients.any(hasConnectionState));
      },
      delayDuration: delayDuration,
    );

    return serverResponse;
  }

  Future<void> _waitFor(
    Future<bool> condition(), {
    Duration delayDuration = defaultDelay,
  }) async {
    while (true) {
      if (await condition()) {
        return;
      }
      await delay(duration: delayDuration);
    }
  }
}
