// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import '../integration.shard/test_data/basic_project.dart';
import '../integration.shard/test_driver.dart';
import '../integration.shard/test_utils.dart';
import '../src/common.dart';

void main() {
  late Directory tempDir;
  final BasicProjectWithUnaryMain project = BasicProjectWithUnaryMain();
  late FlutterRunTestDriver flutter;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('run_test.');
    await project.setUpIn(tempDir);
    flutter = FlutterRunTestDriver(tempDir);
  });

  tearDown(() async {
    await flutter.stop();
    tryToDelete(tempDir);
  });

  Future<void> start({bool verbose = false}) async {
      // The non-test project has a loop around its breakpoints.
      // No need to start paused as all breakpoint would be eventually reached.
      await flutter.run(
        withDebugger: true,
        chrome: true,
        additionalCommandArgs: <String>[
          if (verbose) '--verbose',
          '--web-renderer=html',
        ]);
  }

  Future<void> evaluate() async {
    final ObjRef res =
      await flutter.evaluate('package:characters/characters.dart', 'true');
    expect(res, isA<InstanceRef>()
      .having((InstanceRef o) => o.kind, 'kind', 'Bool'));
  }

  Future<void> sendEvent(Map<String, Object> event) async {
    final VmService client = await vmServiceConnectUri(
      '${flutter.vmServiceWsUri}');
    final Response result = await client.callServiceExtension(
      'ext.dwds.sendEvent',
      args: event,
    );
    expect(result, isA<Success>());
    await client.dispose();
  }

  testWithoutContext('flutter run outputs info messages from dwds in verbose mode', () async {
    final Future<dynamic> info = expectLater(
      flutter.stdout, emitsThrough(contains('Loaded debug metadata')));
    await start(verbose: true);
    await evaluate();
    await flutter.stop();
    await info;
  });

  testWithoutContext('flutter run outputs warning messages from dwds in non-verbose mode', () async {
    final Future<dynamic> warning = expectLater(
      flutter.stderr, emitsThrough(contains('Ignoring unknown event')));
    await start();
    await sendEvent(<String, Object>{'type': 'DevtoolsEvent'});
    await warning;
  }, skip: true); // Skipping for 'https://github.com/dart-lang/webdev/issues/1562'

  testWithoutContext(
      'flutter run output skips DartUri warning messages from dwds', () async {
    bool containsDartUriWarning = false;
    flutter.stderr.listen((String msg) {
      if (msg.contains('DartUri')) {
        containsDartUriWarning = true;
      }
    });
    await start();
    await flutter.stop();
    expect(containsDartUriWarning, isFalse);
  }, skip: true); // Skipping for 'https://github.com/flutter/flutter/issues/124214'
}
