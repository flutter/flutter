// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

@TestOn('vm')
import 'dart:async';

import 'package:dwds/dwds.dart';
import 'package:dwds/src/debugging/debugger.dart';
import 'package:dwds/src/debugging/frame_computer.dart';
import 'package:dwds/src/debugging/inspector.dart';
import 'package:dwds/src/debugging/location.dart';
import 'package:dwds/src/debugging/skip_list.dart';
import 'package:dwds/src/loaders/strategy.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart'
    show CallFrame, DebuggerPausedEvent, StackTrace, WipCallFrame, WipScript;

import 'fixtures/context.dart';
import 'fixtures/debugger_data.dart';
import 'fixtures/fakes.dart';

final context = TestContext();
AppInspector inspector;
Debugger debugger;
FakeWebkitDebugger webkitDebugger;
StreamController<DebuggerPausedEvent> pausedController;
Locations locations;
SkipLists skipLists;

class TestStrategy extends FakeStrategy {
  @override
  Future<String> moduleForServerPath(String entrypoint, String appUri) async =>
      'foo.ddc.js';

  @override
  Future<String> serverPathForModule(String entrypoint, String module) async =>
      'foo/ddc';
}

class FakeAssetReader implements AssetReader {
  @override
  Future<String> dartSourceContents(String serverPath) =>
      throw UnimplementedError();

  @override
  Future<String> metadataContents(String serverPath) =>
      throw UnimplementedError();

  @override
  Future<String> sourceMapContents(String serverPath) async =>
      '{"version":3,"sourceRoot":"","sources":["main.dart"],"names":[],'
      '"mappings":";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;AAUwB,IAAtB,WAAM;AAKJ,'
      'IAHF,4BAAkB,aAAa,SAAC,GAAG;AACb,MAApB,WAAM;AACN,YAAgC,+CAAO,AAAK,oBAAO,'
      'yCAAC,WAAW;IAChE;AAC0D,IAA3D,AAAS,AAAK,0DAAO;AAAe,kBAAO;;;AAEvC,gBAAQ;'
      'AAGV,IAFI,kCAAqC,QAAC;AACX,MAA/B,WAAM,AAAwB,0BAAP,QAAF,AAAE,KAAK,GAAP;'
      ';EAEzB","file":"main.ddc.js"}';

  @override
  Future<void> close() async {}
}

final sampleSyncFrame = WipCallFrame({
  'callFrameId': '{"ordinal":0,"injectedScriptId":2}',
  'functionName': '',
  'functionLocation': {
    'scriptId': '69',
    'lineNumber': 88,
    'columnNumber': 72,
  },
  'location': {'scriptId': '69', 'lineNumber': 37, 'columnNumber': 0},
  'url': '',
  'scopeChain': [],
  'this': {'type': 'undefined'},
});

final sampleAsyncFrame = CallFrame({
  'functionName': 'myFunc',
  'url': '',
  'scriptId': '71',
  'lineNumber': 40,
  'columnNumber': 1,
});

final Map<String, WipScript> scripts = {
  '69': WipScript(<String, dynamic>{
    'url': 'http://127.0.0.1:8081/foo.ddc.js',
  }),
  '71': WipScript(<String, dynamic>{
    'url': 'http://127.0.0.1:8081/bar.ddc.js',
  }),
};

void main() async {
  setUpAll(() async {
    webkitDebugger = FakeWebkitDebugger(scripts: scripts);
    pausedController = StreamController<DebuggerPausedEvent>();
    webkitDebugger.onPaused = pausedController.stream;
    globalLoadStrategy = TestStrategy();
    final root = 'fakeRoot';
    locations = Locations(FakeAssetReader(), FakeModules(), root);
    locations.initialize('fake_entrypoint');
    skipLists = SkipLists();
    debugger = await Debugger.create(
      webkitDebugger,
      null,
      () => inspector,
      locations,
      skipLists,
      root,
    );
    inspector = FakeInspector();
  });

  /// Test that we get expected variable values from a hard-coded
  /// stack frame.
  test('frames 1', () async {
    final stackComputer = FrameComputer(debugger, frames1);
    final frames = await stackComputer.calculateFrames();
    expect(frames, isNotNull);

    final firstFrame = frames[0];
    final frame1Variables = firstFrame.vars.map((each) => each.name).toList();
    expect(frame1Variables, ['a', 'b']);
  });

  test('creates async frames', () async {
    final stackComputer = FrameComputer(
      debugger,
      [sampleSyncFrame],
      asyncStackTrace: StackTrace({
        'callFrames': [sampleAsyncFrame.json],
        'parent': StackTrace({
          'callFrames': [sampleAsyncFrame.json],
        }).json,
      }),
    );

    final frames = await stackComputer.calculateFrames();
    expect(frames, hasLength(5));

    expect(frames[0].kind, FrameKind.kRegular);
    expect(frames[1].kind, FrameKind.kAsyncSuspensionMarker);
    expect(frames[2].kind, FrameKind.kAsyncCausal);
    expect(frames[3].kind, FrameKind.kAsyncSuspensionMarker);
    expect(frames[4].kind, FrameKind.kAsyncCausal);
  });

  test('elides multiple async frames', () async {
    final stackComputer = FrameComputer(
      debugger,
      [sampleSyncFrame],
      asyncStackTrace: StackTrace({
        'callFrames': [sampleAsyncFrame.json],
        'parent': StackTrace({
          'callFrames': [],
          'parent': StackTrace({
            'callFrames': [sampleAsyncFrame.json],
            'parent': StackTrace({
              'callFrames': [],
            }).json,
          }).json,
        }).json,
      }),
    );

    final frames = await stackComputer.calculateFrames();
    expect(frames, hasLength(5));

    expect(frames[0].kind, FrameKind.kRegular);
    expect(frames[1].kind, FrameKind.kAsyncSuspensionMarker);
    expect(frames[2].kind, FrameKind.kAsyncCausal);
    expect(frames[3].kind, FrameKind.kAsyncSuspensionMarker);
    expect(frames[4].kind, FrameKind.kAsyncCausal);
  });

  group('errors', () {
    setUp(() {
      // We need to provide an Isolate so that the code doesn't bail out on a null
      // check before it has a chance to throw.
      inspector = FakeInspector(fakeIsolate: simpleIsolate);
    });

    test('errors in the zone are caught and logged', () async {
      // Add a DebuggerPausedEvent with a null parameter to provoke an error.
      pausedController.sink.add(DebuggerPausedEvent({
        'params': {
          'reason': 'other',
          'callFrames': [
            null,
          ],
        }
      }));
      expect(
          Debugger.logger.onRecord,
          emitsThrough(predicate(
              (log) => log.message == 'Error calculating Dart frames')));
    });
  });
}
