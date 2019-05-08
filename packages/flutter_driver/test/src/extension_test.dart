// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_driver/src/common/find.dart';
import 'package:flutter_driver/src/common/geometry.dart';
import 'package:flutter_driver/src/common/request_data.dart';
import 'package:flutter_driver/src/extension/extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('waitUntilNoTransientCallbacks', () {
    FlutterDriverExtension extension;
    Map<String, dynamic> result;
    int messageId = 0;
    final List<String> log = <String>[];

    setUp(() {
      result = null;
      extension = FlutterDriverExtension((String message) async { log.add(message); return (messageId += 1).toString(); }, false);
    });

    testWidgets('returns immediately when transient callback queue is empty', (WidgetTester tester) async {
      extension.call(WaitUntilNoTransientCallbacks().serialize())
        .then<void>(expectAsync1((Map<String, dynamic> r) {
          result = r;
        }));

      await tester.idle();
      expect(
          result,
          <String, dynamic>{
            'isError': false,
            'response': null,
          },
      );
    });

    testWidgets('waits until no transient callbacks', (WidgetTester tester) async {
      SchedulerBinding.instance.scheduleFrameCallback((_) {
        // Intentionally blank. We only care about existence of a callback.
      });

      extension.call(WaitUntilNoTransientCallbacks().serialize())
        .then<void>(expectAsync1((Map<String, dynamic> r) {
          result = r;
        }));

      // Nothing should happen until the next frame.
      await tester.idle();
      expect(result, isNull);

      // NOW we should receive the result.
      await tester.pump();
      expect(
          result,
          <String, dynamic>{
            'isError': false,
            'response': null,
          },
      );
    });

    testWidgets('handler', (WidgetTester tester) async {
      expect(log, isEmpty);
      final dynamic result = RequestDataResult.fromJson((await extension.call(RequestData('hello').serialize()))['response']);
      expect(log, <String>['hello']);
      expect(result.message, '1');
    });
  });

  group('getSemanticsId', () {
    FlutterDriverExtension extension;
    setUp(() {
      extension = FlutterDriverExtension((String arg) async => '', true);
    });

    testWidgets('works when semantics are enabled', (WidgetTester tester) async {
      final SemanticsHandle semantics = RendererBinding.instance.pipelineOwner.ensureSemantics();
      await tester.pumpWidget(
        const Text('hello', textDirection: TextDirection.ltr));

      final Map<String, Object> arguments = GetSemanticsId(ByText('hello')).serialize();
      final GetSemanticsIdResult result = GetSemanticsIdResult.fromJson((await extension.call(arguments))['response']);

      expect(result.id, 1);
      semantics.dispose();
    });

    testWidgets('throws state error if no data is found', (WidgetTester tester) async {
      await tester.pumpWidget(
        const Text('hello', textDirection: TextDirection.ltr));

      final Map<String, Object> arguments = GetSemanticsId(ByText('hello')).serialize();
      final Map<String, Object> response = await extension.call(arguments);

      expect(response['isError'], true);
      expect(response['response'], contains('Bad state: No semantics data found'));
    });

    testWidgets('throws state error multiple matches are found', (WidgetTester tester) async {
      final SemanticsHandle semantics = RendererBinding.instance.pipelineOwner.ensureSemantics();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ListView(children: const <Widget>[
            SizedBox(width: 100.0, height: 100.0, child: Text('hello')),
            SizedBox(width: 100.0, height: 100.0, child: Text('hello')),
          ]),
        ),
      );

      final Map<String, Object> arguments = GetSemanticsId(ByText('hello')).serialize();
      final Map<String, Object> response = await extension.call(arguments);

      expect(response['isError'], true);
      expect(response['response'], contains('Bad state: Too many elements'));
      semantics.dispose();
    });
  });

  testWidgets('getOffset', (WidgetTester tester) async {
    final FlutterDriverExtension extension = FlutterDriverExtension((String arg) async => '', true);

    Future<Offset> getOffset(OffsetType offset) async {
      final Map<String, Object> arguments = GetOffset(ByValueKey(1), offset).serialize();
      final GetOffsetResult result = GetOffsetResult.fromJson((await extension.call(arguments))['response']);
      return Offset(result.dx, result.dy);
    }

    await tester.pumpWidget(
      Align(
        alignment: Alignment.topLeft,
        child: Transform.translate(
          offset: const Offset(40, 30),
          child: Container(
            key: const ValueKey<int>(1),
            width: 100,
            height: 120,
          ),
        ),
      ),
    );

    expect(await getOffset(OffsetType.topLeft), const Offset(40, 30));
    expect(await getOffset(OffsetType.topRight), const Offset(40 + 100.0, 30));
    expect(await getOffset(OffsetType.bottomLeft), const Offset(40, 30 + 120.0));
    expect(await getOffset(OffsetType.bottomRight), const Offset(40 + 100.0, 30 + 120.0));
    expect(await getOffset(OffsetType.center), const Offset(40 + (100 / 2), 30 + (120 / 2)));
  });
}
