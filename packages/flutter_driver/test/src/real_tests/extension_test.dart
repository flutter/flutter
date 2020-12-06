// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:flutter_driver/src/common/diagnostics_tree.dart';
import 'package:flutter_driver/src/common/find.dart';
import 'package:flutter_driver/src/common/geometry.dart';
import 'package:flutter_driver/src/common/request_data.dart';
import 'package:flutter_driver/src/common/text.dart';
import 'package:flutter_driver/src/common/wait.dart';
import 'package:flutter_driver/src/extension/extension.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> silenceDriverLogger(AsyncCallback callback) async {
  final DriverLogCallback oldLogger = driverLog;
  driverLog = (String source, String message) { };
  try {
    await callback();
  } finally {
    driverLog = oldLogger;
  }
}

void main() {
  group('waitUntilNoTransientCallbacks', () {
    FlutterDriverExtension extension;
    Map<String, dynamic> result;
    int messageId = 0;
    final List<String> log = <String>[];

    setUp(() {
      result = null;
      extension = FlutterDriverExtension((String message) async { log.add(message); return (messageId += 1).toString(); }, false, <FinderExtension>[]);
    });

    testWidgets('returns immediately when transient callback queue is empty', (WidgetTester tester) async {
      extension.call(const WaitUntilNoTransientCallbacks().serialize())
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

      extension.call(const WaitUntilNoTransientCallbacks().serialize())
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
      final Map<String, dynamic> response = await extension.call(const RequestData('hello').serialize());
      final RequestDataResult result = RequestDataResult.fromJson(response['response'] as Map<String, dynamic>);
      expect(log, <String>['hello']);
      expect(result.message, '1');
    });
  });

  group('waitForCondition', () {
    FlutterDriverExtension extension;
    Map<String, dynamic> result;
    int messageId = 0;
    final List<String> log = <String>[];

    setUp(() {
      result = null;
      extension = FlutterDriverExtension((String message) async { log.add(message); return (messageId += 1).toString(); }, false, <FinderExtension>[]);
    });

    testWidgets('waiting for NoTransientCallbacks returns immediately when transient callback queue is empty', (WidgetTester tester) async {
      extension.call(const WaitForCondition(NoTransientCallbacks()).serialize())
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

    testWidgets('waiting for NoTransientCallbacks returns until no transient callbacks', (WidgetTester tester) async {
      SchedulerBinding.instance.scheduleFrameCallback((_) {
        // Intentionally blank. We only care about existence of a callback.
      });

      extension.call(const WaitForCondition(NoTransientCallbacks()).serialize())
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

    testWidgets('waiting for NoPendingFrame returns immediately when frame is synced', (
        WidgetTester tester) async {
      extension.call(const WaitForCondition(NoPendingFrame()).serialize())
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

    testWidgets('waiting for NoPendingFrame returns until no pending scheduled frame', (WidgetTester tester) async {
      SchedulerBinding.instance.scheduleFrame();

      extension.call(const WaitForCondition(NoPendingFrame()).serialize())
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

    testWidgets(
        'waiting for combined conditions returns immediately', (WidgetTester tester) async {
      const SerializableWaitCondition combinedCondition =
          CombinedCondition(<SerializableWaitCondition>[NoTransientCallbacks(), NoPendingFrame()]);
      extension.call(const WaitForCondition(combinedCondition).serialize())
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

    testWidgets(
        'waiting for combined conditions returns until no transient callbacks', (WidgetTester tester) async {
      SchedulerBinding.instance.scheduleFrame();
      SchedulerBinding.instance.scheduleFrameCallback((_) {
        // Intentionally blank. We only care about existence of a callback.
      });

      const SerializableWaitCondition combinedCondition =
          CombinedCondition(<SerializableWaitCondition>[NoTransientCallbacks(), NoPendingFrame()]);
      extension.call(const WaitForCondition(combinedCondition).serialize())
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

    testWidgets(
        'waiting for combined conditions returns until no pending scheduled frame', (WidgetTester tester) async {
      SchedulerBinding.instance.scheduleFrame();
      SchedulerBinding.instance.scheduleFrameCallback((_) {
        // Intentionally blank. We only care about existence of a callback.
      });

      const SerializableWaitCondition combinedCondition =
          CombinedCondition(<SerializableWaitCondition>[NoPendingFrame(), NoTransientCallbacks()]);
      extension.call(const WaitForCondition(combinedCondition).serialize())
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

    testWidgets(
        "waiting for NoPendingPlatformMessages returns immediately when there're no platform messages", (WidgetTester tester) async {
      extension
          .call(const WaitForCondition(NoPendingPlatformMessages()).serialize())
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

    testWidgets(
        'waiting for NoPendingPlatformMessages returns until a single method channel call returns', (WidgetTester tester) async {
      const MethodChannel channel = MethodChannel('helloChannel', JSONMethodCodec());
      const MessageCodec<dynamic> jsonMessage = JSONMessageCodec();
      ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
          'helloChannel', (ByteData message) {
            return Future<ByteData>.delayed(
                const Duration(milliseconds: 10),
                () => jsonMessage.encodeMessage(<dynamic>['hello world']));
          });
      channel.invokeMethod<String>('sayHello', 'hello');

      extension
          .call(const WaitForCondition(NoPendingPlatformMessages()).serialize())
          .then<void>(expectAsync1((Map<String, dynamic> r) {
        result = r;
      }));

      // The channel message are delayed for 10 milliseconds, so nothing happens yet.
      await tester.pump(const Duration(milliseconds: 5));
      expect(result, isNull);

      // Now we receive the result.
      await tester.pump(const Duration(milliseconds: 5));
      expect(
        result,
        <String, dynamic>{
          'isError': false,
          'response': null,
        },
      );
    });

    testWidgets(
        'waiting for NoPendingPlatformMessages returns until both method channel calls return', (WidgetTester tester) async {
      const MessageCodec<dynamic> jsonMessage = JSONMessageCodec();
      // Configures channel 1
      const MethodChannel channel1 = MethodChannel('helloChannel1', JSONMethodCodec());
      ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
          'helloChannel1', (ByteData message) {
            return Future<ByteData>.delayed(
                const Duration(milliseconds: 10),
                () => jsonMessage.encodeMessage(<dynamic>['hello world']));
          });

      // Configures channel 2
      const MethodChannel channel2 = MethodChannel('helloChannel2', JSONMethodCodec());
      ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
          'helloChannel2', (ByteData message) {
            return Future<ByteData>.delayed(
                const Duration(milliseconds: 20),
                () => jsonMessage.encodeMessage(<dynamic>['hello world']));
          });

      channel1.invokeMethod<String>('sayHello', 'hello');
      channel2.invokeMethod<String>('sayHello', 'hello');

      extension
          .call(const WaitForCondition(NoPendingPlatformMessages()).serialize())
          .then<void>(expectAsync1((Map<String, dynamic> r) {
        result = r;
      }));

      // Neither of the channel responses is received, so nothing happens yet.
      await tester.pump(const Duration(milliseconds: 5));
      expect(result, isNull);

      // Result of channel 1 is received, but channel 2 is still pending, so still waiting.
      await tester.pump(const Duration(milliseconds: 10));
      expect(result, isNull);

      // Both of the results are received. Now we receive the result.
      await tester.pump(const Duration(milliseconds: 30));
      expect(
        result,
        <String, dynamic>{
          'isError': false,
          'response': null,
        },
      );
    });

    testWidgets(
        'waiting for NoPendingPlatformMessages returns until new method channel call returns', (WidgetTester tester) async {
      const MessageCodec<dynamic> jsonMessage = JSONMessageCodec();
      // Configures channel 1
      const MethodChannel channel1 = MethodChannel('helloChannel1', JSONMethodCodec());
      ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
          'helloChannel1', (ByteData message) {
            return Future<ByteData>.delayed(
                const Duration(milliseconds: 10),
                () => jsonMessage.encodeMessage(<dynamic>['hello world']));
          });

      // Configures channel 2
      const MethodChannel channel2 = MethodChannel('helloChannel2', JSONMethodCodec());
      ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
          'helloChannel2', (ByteData message) {
            return Future<ByteData>.delayed(
                const Duration(milliseconds: 20),
                () => jsonMessage.encodeMessage(<dynamic>['hello world']));
          });

      channel1.invokeMethod<String>('sayHello', 'hello');

      // Calls the waiting API before the second channel message is sent.
      extension
          .call(const WaitForCondition(NoPendingPlatformMessages()).serialize())
          .then<void>(expectAsync1((Map<String, dynamic> r) {
        result = r;
      }));

      // The first channel message is not received, so nothing happens yet.
      await tester.pump(const Duration(milliseconds: 5));
      expect(result, isNull);

      channel2.invokeMethod<String>('sayHello', 'hello');

      // Result of channel 1 is received, but channel 2 is still pending, so still waiting.
      await tester.pump(const Duration(milliseconds: 15));
      expect(result, isNull);

      // Both of the results are received. Now we receive the result.
      await tester.pump(const Duration(milliseconds: 10));
      expect(
        result,
        <String, dynamic>{
          'isError': false,
          'response': null,
        },
      );
    });

    testWidgets(
        'waiting for NoPendingPlatformMessages returns until both old and new method channel calls return', (WidgetTester tester) async {
      const MessageCodec<dynamic> jsonMessage = JSONMessageCodec();
      // Configures channel 1
      const MethodChannel channel1 = MethodChannel('helloChannel1', JSONMethodCodec());
      ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
          'helloChannel1', (ByteData message) {
            return Future<ByteData>.delayed(
                const Duration(milliseconds: 20),
                () => jsonMessage.encodeMessage(<dynamic>['hello world']));
          });

      // Configures channel 2
      const MethodChannel channel2 = MethodChannel('helloChannel2', JSONMethodCodec());
      ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
          'helloChannel2', (ByteData message) {
            return Future<ByteData>.delayed(
                const Duration(milliseconds: 10),
                () => jsonMessage.encodeMessage(<dynamic>['hello world']));
          });

      channel1.invokeMethod<String>('sayHello', 'hello');

      extension
          .call(const WaitForCondition(NoPendingPlatformMessages()).serialize())
          .then<void>(expectAsync1((Map<String, dynamic> r) {
        result = r;
      }));

      // The first channel message is not received, so nothing happens yet.
      await tester.pump(const Duration(milliseconds: 5));
      expect(result, isNull);

      channel2.invokeMethod<String>('sayHello', 'hello');

      // Result of channel 2 is received, but channel 1 is still pending, so still waiting.
      await tester.pump(const Duration(milliseconds: 10));
      expect(result, isNull);

      // Now we receive the result.
      await tester.pump(const Duration(milliseconds: 5));
      expect(
        result,
        <String, dynamic>{
          'isError': false,
          'response': null,
        },
      );
    });
  });

  group('getSemanticsId', () {
    FlutterDriverExtension extension;
    setUp(() {
      extension = FlutterDriverExtension((String arg) async => '', true, <FinderExtension>[]);
    });

    testWidgets('works when semantics are enabled', (WidgetTester tester) async {
      final SemanticsHandle semantics = RendererBinding.instance.pipelineOwner.ensureSemantics();
      await tester.pumpWidget(
        const Text('hello', textDirection: TextDirection.ltr));

      final Map<String, String> arguments = GetSemanticsId(const ByText('hello')).serialize();
      final Map<String, dynamic> response = await extension.call(arguments);
      final GetSemanticsIdResult result = GetSemanticsIdResult.fromJson(response['response'] as Map<String, dynamic>);

      expect(result.id, 1);
      semantics.dispose();
    });

    testWidgets('throws state error if no data is found', (WidgetTester tester) async {
      await tester.pumpWidget(
        const Text('hello', textDirection: TextDirection.ltr));

      final Map<String, String> arguments = GetSemanticsId(const ByText('hello')).serialize();
      final Map<String, dynamic> response = await extension.call(arguments);

      expect(response['isError'], true);
      expect(response['response'], contains('Bad state: No semantics data found'));
    }, semanticsEnabled: false);

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

      final Map<String, String> arguments = GetSemanticsId(const ByText('hello')).serialize();
      final Map<String, dynamic> response = await extension.call(arguments);

      expect(response['isError'], true);
      expect(response['response'], contains('Bad state: Found more than one element with the same ID'));
      semantics.dispose();
    });
  });

  testWidgets('getOffset', (WidgetTester tester) async {
    final FlutterDriverExtension extension = FlutterDriverExtension((String arg) async => '', true, <FinderExtension>[]);

    Future<Offset> getOffset(OffsetType offset) async {
      final Map<String, String> arguments = GetOffset(ByValueKey(1), offset).serialize();
      final Map<String, dynamic> response = await extension.call(arguments);
      final GetOffsetResult result = GetOffsetResult.fromJson(response['response'] as Map<String, dynamic>);
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

  testWidgets('getText', (WidgetTester tester) async {
    await silenceDriverLogger(() async {
      final FlutterDriverExtension extension = FlutterDriverExtension((String arg) async => '', true, <FinderExtension>[]);

      Future<String> getTextInternal(SerializableFinder search) async {
        final Map<String, String> arguments = GetText(search, timeout: const Duration(seconds: 1)).serialize();
        final Map<String, dynamic> result = await extension.call(arguments);
        if (result['isError'] as bool) {
          return null;
        }
        return GetTextResult.fromJson(result['response'] as Map<String, dynamic>).text;
      }

      await tester.pumpWidget(
          MaterialApp(
              home: Scaffold(body:Column(
                key: const ValueKey<String>('column'),
                children: <Widget>[
                  const Text('Hello1', key: ValueKey<String>('text1')),
                  Container(
                    height: 25.0,
                    child: RichText(
                      key: const ValueKey<String>('text2'),
                      text: const TextSpan(text: 'Hello2'),
                    ),
                  ),
                  Container(
                    height: 25.0,
                    child: EditableText(
                      key: const ValueKey<String>('text3'),
                      controller: TextEditingController(text: 'Hello3'),
                      focusNode: FocusNode(),
                      style: const TextStyle(),
                      cursorColor: Colors.red,
                      backgroundCursorColor: Colors.black,
                    ),
                  ),
                  Container(
                    height: 25.0,
                    child: TextField(
                      key: const ValueKey<String>('text4'),
                      controller: TextEditingController(text: 'Hello4'),
                    ),
                  ),
                  Container(
                    height: 25.0,
                    child: TextFormField(
                      key: const ValueKey<String>('text5'),
                      controller: TextEditingController(text: 'Hello5'),
                    ),
                  ),
                ],
              ))
          )
      );

      expect(await getTextInternal(ByValueKey('text1')), 'Hello1');
      expect(await getTextInternal(ByValueKey('text2')), 'Hello2');
      expect(await getTextInternal(ByValueKey('text3')), 'Hello3');
      expect(await getTextInternal(ByValueKey('text4')), 'Hello4');
      expect(await getTextInternal(ByValueKey('text5')), 'Hello5');

      // Check if error thrown for other types
      final Map<String, String> arguments = GetText(ByValueKey('column'), timeout: const Duration(seconds: 1)).serialize();
      final Map<String, dynamic> response = await extension.call(arguments);
      expect(response['isError'], true);
      expect(response['response'], contains('is currently not supported by getText'));
    });
  });

  testWidgets('descendant finder', (WidgetTester tester) async {
    await silenceDriverLogger(() async {
      final FlutterDriverExtension extension = FlutterDriverExtension((String arg) async => '', true, <FinderExtension>[]);

      Future<String> getDescendantText({ String of, bool matchRoot = false}) async {
        final Map<String, String> arguments = GetText(Descendant(
          of: ByValueKey(of),
          matching: ByValueKey('text2'),
          matchRoot: matchRoot,
        ), timeout: const Duration(seconds: 1)).serialize();
        final Map<String, dynamic> result = await extension.call(arguments);
        if (result['isError'] as bool) {
          return null;
        }
        return GetTextResult.fromJson(result['response'] as Map<String, dynamic>).text;
      }

      await tester.pumpWidget(
          MaterialApp(
              home: Column(
                key: const ValueKey<String>('column'),
                children: const <Widget>[
                  Text('Hello1', key: ValueKey<String>('text1')),
                  Text('Hello2', key: ValueKey<String>('text2')),
                  Text('Hello3', key: ValueKey<String>('text3')),
                ],
              )
          )
      );

      expect(await getDescendantText(of: 'column'), 'Hello2');
      expect(await getDescendantText(of: 'column', matchRoot: true), 'Hello2');
      expect(await getDescendantText(of: 'text2', matchRoot: true), 'Hello2');

      // Find nothing
      Future<String> result = getDescendantText(of: 'text1', matchRoot: true);
      await tester.pump(const Duration(seconds: 2));
      expect(await result, null);

      result = getDescendantText(of: 'text2');
      await tester.pump(const Duration(seconds: 2));
      expect(await result, null);
    });
  });

  testWidgets('descendant finder firstMatchOnly', (WidgetTester tester) async {
    await silenceDriverLogger(() async {
      final FlutterDriverExtension extension = FlutterDriverExtension((String arg) async => '', true, <FinderExtension>[]);

      Future<String> getDescendantText() async {
        final Map<String, String> arguments = GetText(Descendant(
          of: ByValueKey('column'),
          matching: const ByType('Text'),
          firstMatchOnly: true,
        ), timeout: const Duration(seconds: 1)).serialize();
        final Map<String, dynamic> result = await extension.call(arguments);
        if (result['isError'] as bool) {
          return null;
        }
        return GetTextResult.fromJson(result['response'] as Map<String, dynamic>).text;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            key: const ValueKey<String>('column'),
            children: const <Widget>[
              Text('Hello1', key: ValueKey<String>('text1')),
              Text('Hello2', key: ValueKey<String>('text2')),
              Text('Hello3', key: ValueKey<String>('text3')),
            ],
          ),
        ),
      );

      expect(await getDescendantText(), 'Hello1');
    });
  });

  testWidgets('ancestor finder', (WidgetTester tester) async {
    await silenceDriverLogger(() async {
      final FlutterDriverExtension extension = FlutterDriverExtension((String arg) async => '', true, <FinderExtension>[]);

      Future<Offset> getAncestorTopLeft({ String of, String matching, bool matchRoot = false}) async {
        final Map<String, String> arguments = GetOffset(Ancestor(
          of: ByValueKey(of),
          matching: ByValueKey(matching),
          matchRoot: matchRoot,
        ), OffsetType.topLeft, timeout: const Duration(seconds: 1)).serialize();
        final Map<String, dynamic> response = await extension.call(arguments);
        if (response['isError'] as bool) {
          return null;
        }
        final GetOffsetResult result = GetOffsetResult.fromJson(response['response'] as Map<String, dynamic>);
        return Offset(result.dx, result.dy);
      }

      await tester.pumpWidget(
          MaterialApp(
            home: Center(
                child: Container(
                  key: const ValueKey<String>('parent'),
                  height: 100,
                  width: 100,
                  child: Center(
                    child: Row(
                      children: <Widget>[
                        Container(
                          key: const ValueKey<String>('leftchild'),
                          width: 25,
                          height: 25,
                        ),
                        Container(
                          key: const ValueKey<String>('righttchild'),
                          width: 25,
                          height: 25,
                        ),
                      ],
                    ),
                  ),
                )
            ),
          )
      );

      expect(
        await getAncestorTopLeft(of: 'leftchild', matching: 'parent'),
        const Offset((800 - 100) / 2, (600 - 100) / 2),
      );
      expect(
        await getAncestorTopLeft(of: 'leftchild', matching: 'parent', matchRoot: true),
        const Offset((800 - 100) / 2, (600 - 100) / 2),
      );
      expect(
        await getAncestorTopLeft(of: 'parent', matching: 'parent', matchRoot: true),
        const Offset((800 - 100) / 2, (600 - 100) / 2),
      );

      // Find nothing
      Future<Offset> result = getAncestorTopLeft(of: 'leftchild', matching: 'leftchild');
      await tester.pump(const Duration(seconds: 2));
      expect(await result, null);

      result = getAncestorTopLeft(of: 'leftchild', matching: 'righttchild');
      await tester.pump(const Duration(seconds: 2));
      expect(await result, null);
    });
  });

  testWidgets('ancestor finder firstMatchOnly', (WidgetTester tester) async {
    await silenceDriverLogger(() async {
      final FlutterDriverExtension extension = FlutterDriverExtension((String arg) async => '', true, <FinderExtension>[]);

      Future<Offset> getAncestorTopLeft() async {
        final Map<String, String> arguments = GetOffset(Ancestor(
          of: ByValueKey('leaf'),
          matching: const ByType('Container'),
          firstMatchOnly: true,
        ), OffsetType.topLeft, timeout: const Duration(seconds: 1)).serialize();
        final Map<String, dynamic> response = await extension.call(arguments);
        if (response['isError'] as bool) {
          return null;
        }
        final GetOffsetResult result = GetOffsetResult.fromJson(response['response'] as Map<String, dynamic>);
        return Offset(result.dx, result.dy);
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: Container(
              height: 200,
              width: 200,
              child: Center(
                child: Container(
                  height: 100,
                  width: 100,
                  child: Center(
                    child: Container(
                      key: const ValueKey<String>('leaf'),
                      height: 50,
                      width: 50,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        await getAncestorTopLeft(),
        const Offset((800 - 100) / 2, (600 - 100) / 2),
      );
    });
  });

  testWidgets('GetDiagnosticsTree', (WidgetTester tester) async {
    final FlutterDriverExtension extension = FlutterDriverExtension((String arg) async => '', true, <FinderExtension>[]);

    Future<Map<String, Object>> getDiagnosticsTree(DiagnosticsType type, SerializableFinder finder, { int depth = 0, bool properties = true }) async {
      final Map<String, String> arguments = GetDiagnosticsTree(finder, type, subtreeDepth: depth, includeProperties: properties).serialize();
      final Map<String, dynamic> response = await extension.call(arguments);
      final DiagnosticsTreeResult result = DiagnosticsTreeResult(response['response'] as Map<String, dynamic>);
      return result.json;
    }

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
            child: Text('Hello World', key: ValueKey<String>('Text'))
        ),
      ),
    );

    // Widget
    Map<String, Object> result = await getDiagnosticsTree(DiagnosticsType.widget, ByValueKey('Text'), depth: 0);
    expect(result['children'], isNull); // depth: 0
    expect(result['widgetRuntimeType'], 'Text');

    List<Map<String, Object>> properties = (result['properties'] as List<dynamic>).cast<Map<String, Object>>();
    Map<String, Object> stringProperty = properties.singleWhere((Map<String, Object> property) => property['name'] == 'data');
    expect(stringProperty['description'], '"Hello World"');
    expect(stringProperty['propertyType'], 'String');

    result = await getDiagnosticsTree(DiagnosticsType.widget, ByValueKey('Text'), depth: 0, properties: false);
    expect(result['widgetRuntimeType'], 'Text');
    expect(result['properties'], isNull); // properties: false

    result = await getDiagnosticsTree(DiagnosticsType.widget, ByValueKey('Text'), depth: 1);
    List<Map<String, Object>> children = (result['children'] as List<dynamic>).cast<Map<String, Object>>();
    expect(children.single['children'], isNull);

    result = await getDiagnosticsTree(DiagnosticsType.widget, ByValueKey('Text'), depth: 100);
    children = (result['children'] as List<dynamic>).cast<Map<String, Object>>();
    expect(children.single['children'], isEmpty);

    // RenderObject
    result = await getDiagnosticsTree(DiagnosticsType.renderObject, ByValueKey('Text'), depth: 0);
    expect(result['children'], isNull); // depth: 0
    expect(result['properties'], isNotNull);
    expect(result['description'], startsWith('RenderParagraph'));

    result = await getDiagnosticsTree(DiagnosticsType.renderObject, ByValueKey('Text'), depth: 0, properties: false);
    expect(result['properties'], isNull); // properties: false
    expect(result['description'], startsWith('RenderParagraph'));

    result = await getDiagnosticsTree(DiagnosticsType.renderObject, ByValueKey('Text'), depth: 1);
    children = (result['children'] as List<dynamic>).cast<Map<String, Object>>();
    final Map<String, Object> textSpan = children.single;
    expect(textSpan['description'], 'TextSpan');
    properties = (textSpan['properties'] as List<dynamic>).cast<Map<String, Object>>();
    stringProperty = properties.singleWhere((Map<String, Object> property) => property['name'] == 'text');
    expect(stringProperty['description'], '"Hello World"');
    expect(stringProperty['propertyType'], 'String');
    expect(children.single['children'], isNull);

    result = await getDiagnosticsTree(DiagnosticsType.renderObject, ByValueKey('Text'), depth: 100);
    children = (result['children'] as List<dynamic>).cast<Map<String, Object>>();
    expect(children.single['children'], isEmpty);
  });

  group('waitUntilFrameSync', () {
    FlutterDriverExtension extension;
    Map<String, dynamic> result;

    setUp(() {
      extension = FlutterDriverExtension((String arg) async => '', true, <FinderExtension>[]);
      result = null;
    });

    testWidgets('returns immediately when frame is synced', (
        WidgetTester tester) async {
      extension.call(const WaitUntilNoPendingFrame().serialize())
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

    testWidgets(
        'waits until no transient callbacks', (WidgetTester tester) async {
      SchedulerBinding.instance.scheduleFrameCallback((_) {
        // Intentionally blank. We only care about existence of a callback.
      });

      extension.call(const WaitUntilNoPendingFrame().serialize())
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

    testWidgets(
        'waits until no pending scheduled frame', (WidgetTester tester) async {
      SchedulerBinding.instance.scheduleFrame();

      extension.call(const WaitUntilNoPendingFrame().serialize())
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
  });
}
