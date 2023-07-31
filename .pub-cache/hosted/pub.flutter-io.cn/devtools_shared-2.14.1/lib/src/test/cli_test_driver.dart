// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:vm_service/utils.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import 'test_utils.dart';

class AppFixture {
  AppFixture._(
    this.process,
    this.lines,
    this.serviceUri,
    this.serviceConnection,
    this.isolates,
    this.onTeardown,
  ) {
    // "starting app"
    _onAppStarted = lines.first;

    serviceConnection.streamListen(EventStreams.kIsolate);
    _isolateEventStreamSubscription =
        serviceConnection.onIsolateEvent.listen((Event event) {
      if (event.kind == EventKind.kIsolateExit) {
        isolates.remove(event.isolate);
      } else {
        if (!isolates.contains(event.isolate)) {
          isolates.add(event.isolate);
        }
      }
    });
  }

  final Process process;
  final Stream<String> lines;
  final Uri serviceUri;
  final VmService serviceConnection;
  final List<IsolateRef?> isolates;
  late final StreamSubscription<Event> _isolateEventStreamSubscription;
  final Future<void> Function()? onTeardown;
  late Future<void> _onAppStarted;

  Future<void> get onAppStarted => _onAppStarted;

  IsolateRef? get mainIsolate => isolates.isEmpty ? null : isolates.first;

  Future<dynamic> invoke(String expression) async {
    final IsolateRef isolateRef = mainIsolate!;
    final String isolateId = isolateRef.id!;
    final Isolate isolate = await serviceConnection.getIsolate(isolateId);

    return await serviceConnection.evaluate(
      isolateId,
      isolate.rootLib!.id!,
      expression,
    );
  }

  Future<void> teardown() async {
    if (onTeardown != null) {
      await onTeardown!();
    }
    await _isolateEventStreamSubscription.cancel();
    await serviceConnection.dispose();
    process.kill();
  }
}

// This is the fixture for Dart CLI applications.
class CliAppFixture extends AppFixture {
  CliAppFixture._(
    this.appScriptPath,
    Process process,
    Stream<String> lines,
    Uri serviceUri,
    VmService serviceConnection,
    List<IsolateRef> isolates,
    Future<void> Function()? onTeardown,
  ) : super._(
          process,
          lines,
          serviceUri,
          serviceConnection,
          isolates,
          onTeardown,
        );

  final String appScriptPath;

  static Future<CliAppFixture> create(String appScriptPath) async {
    final dartVmServicePrefix =
        RegExp('(Observatory|The Dart VM service is) listening on ');

    final Process process = await Process.start(
      Platform.resolvedExecutable,
      <String>['--observe=0', '--pause-isolates-on-start', appScriptPath],
    );

    final Stream<String> lines =
        process.stdout.transform(utf8.decoder).transform(const LineSplitter());
    final StreamController<String> lineController =
        StreamController<String>.broadcast();
    final Completer<String> completer = Completer<String>();

    final linesSubscription = lines.listen((String line) {
      if (completer.isCompleted) {
        lineController.add(line);
      } else if (line.contains(dartVmServicePrefix)) {
        completer.complete(line);
      } else {
        // Often something like:
        // "Waiting for another flutter command to release the startup lock...".
        print(line);
      }
    });

    // Observatory listening on http://127.0.0.1:9595/(token)
    final String observatoryText = await completer.future;
    final String observatoryUri =
        observatoryText.replaceAll(dartVmServicePrefix, '');
    var uri = Uri.parse(observatoryUri);

    if (!uri.isAbsolute) {
      throw 'Could not parse VM Service URI: "$observatoryText"';
    }

    // Map to WS URI.
    uri = convertToWebSocketUrl(serviceProtocolUrl: uri);

    final VmService serviceConnection =
        await vmServiceConnectUri(uri.toString());

    final VM vm = await serviceConnection.getVM();

    final Isolate isolate =
        await _waitForIsolate(serviceConnection, 'PauseStart');
    await serviceConnection.resume(isolate.id!);

    Future<void> _onTeardown() async {
      await linesSubscription.cancel();
      await lineController.close();
    }

    return CliAppFixture._(
      appScriptPath,
      process,
      lineController.stream,
      uri,
      serviceConnection,
      vm.isolates!,
      _onTeardown,
    );
  }

  static Future<Isolate> _waitForIsolate(
    VmService serviceConnection,
    String pauseEventKind,
  ) async {
    Isolate? foundIsolate;
    await waitFor(() async {
      final vm = await serviceConnection.getVM();
      final List<Isolate?> isolates = await Future.wait(
        vm.isolates!.map(
          (ref) => serviceConnection.getIsolate(ref.id!)
              // Calling getIsolate() can sometimes return a collected sentinel
              // for an isolate that hasn't started yet. We can just ignore these
              // as on the next trip around the Isolate will be returned.
              // https://github.com/dart-lang/sdk/issues/33747
              .catchError((error) {
            print('getIsolate(${ref.id}) failed, skipping\n$error');
          }),
        ),
      );
      foundIsolate = isolates.firstWhere(
        (isolate) => isolate!.pauseEvent?.kind == pauseEventKind,
        orElse: () => null,
      );
      return foundIsolate != null;
    });
    return foundIsolate!;
  }

  String get scriptSource {
    return File(appScriptPath).readAsStringSync();
  }

  static List<int> parseBreakpointLines(String source) {
    return _parseLines(source, 'breakpoint');
  }

  static List<int> parseSteppingLines(String source) {
    return _parseLines(source, 'step');
  }

  static List<int> parseExceptionLines(String source) {
    return _parseLines(source, 'exception');
  }

  static List<int> _parseLines(String source, String keyword) {
    final List<String> lines = source.replaceAll('\r', '').split('\n');
    final List<int> matches = [];

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].endsWith('// $keyword')) {
        matches.add(i);
      }
    }

    return matches;
  }
}
