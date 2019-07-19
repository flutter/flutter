// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget snapshotText(BuildContext context, AsyncSnapshot<String> snapshot) {
    return Text(snapshot.toString(), textDirection: TextDirection.ltr);
  }
  group('AsyncSnapshot', () {
    test('data succeeds if data is present', () {
      const AsyncSnapshot<String> snapshot = AsyncSnapshot<String>.withData(ConnectionState.done, 'hello');
      expect(snapshot.hasData, isTrue);
      expect(snapshot.data, 'hello');
      expect(snapshot.hasError, isFalse);
      expect(snapshot.error, isNull);
    });
    test('data throws if there is an error', () {
      const AsyncSnapshot<String> snapshot = AsyncSnapshot<String>.withError(ConnectionState.done, 'error');
      expect(snapshot.hasData, isFalse);
      expect(() => snapshot.data, throwsA(equals('error')));
      expect(snapshot.hasError, isTrue);
      expect(snapshot.error, 'error');
    });
    test('data throws if created without data', () {
      const AsyncSnapshot<String> snapshot = AsyncSnapshot<String>.withoutData(ConnectionState.none);
      expect(snapshot.hasData, isFalse);
      expect(() => snapshot.data, throwsStateError);
      expect(snapshot.hasError, isFalse);
      expect(snapshot.error, isNull);
    });
    test('data can be null', () {
      const AsyncSnapshot<int> snapshot = AsyncSnapshot<int>.withData(ConnectionState.none, null);
      expect(snapshot.hasData, isTrue);
      expect(snapshot.data, isNull);
      expect(snapshot.hasError, isFalse);
      expect(snapshot.error, isNull);
    });
  });
  group('Async smoke tests', () {
    testWidgets('FutureBuilder', (WidgetTester tester) async {
      await tester.pumpWidget(FutureBuilder<String>(
        future: Future<String>.value('hello'),
        builder: snapshotText,
      ));
      await eventFiring(tester);
    });
    testWidgets('StreamBuilder', (WidgetTester tester) async {
      await tester.pumpWidget(StreamBuilder<String>(
        stream: Stream<String>.fromIterable(<String>['hello', 'world']),
        builder: snapshotText,
      ));
      await eventFiring(tester);
    });
    testWidgets('StreamFold', (WidgetTester tester) async {
      await tester.pumpWidget(StringCollector(
        stream: Stream<String>.fromIterable(<String>['hello', 'world'])
      ));
      await eventFiring(tester);
    });
  });
  group('FutureBuilder', () {
    testWidgets('gracefully handles transition from null future', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      await tester.pumpWidget(FutureBuilder<String>(
        key: key, future: null, builder: snapshotText,
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.none)'), findsOneWidget);
      final Completer<String> completer = Completer<String>();
      await tester.pumpWidget(FutureBuilder<String>(
        key: key, future: completer.future, builder: snapshotText,
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting)'), findsOneWidget);
    });
    testWidgets('gracefully handles transition to null future', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      final Completer<String> completer = Completer<String>();
      await tester.pumpWidget(FutureBuilder<String>(
        key: key, future: completer.future, builder: snapshotText,
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting)'), findsOneWidget);
      await tester.pumpWidget(FutureBuilder<String>(
        key: key, future: null, builder: snapshotText,
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.none)'), findsOneWidget);
      completer.complete('hello');
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<String>(ConnectionState.none)'), findsOneWidget);
    });
    testWidgets('gracefully handles transition to other future', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      final Completer<String> completerA = Completer<String>();
      final Completer<String> completerB = Completer<String>();
      await tester.pumpWidget(FutureBuilder<String>(
        key: key, future: completerA.future, builder: snapshotText,
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting)'), findsOneWidget);
      await tester.pumpWidget(FutureBuilder<String>(
        key: key, future: completerB.future, builder: snapshotText,
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting)'), findsOneWidget);
      completerB.complete('B');
      completerA.complete('A');
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<String>(ConnectionState.done, data: B)'), findsOneWidget);
    });
    testWidgets('tracks life-cycle of Future to success', (WidgetTester tester) async {
      final Completer<String> completer = Completer<String>();
      await tester.pumpWidget(FutureBuilder<String>(
        future: completer.future, builder: snapshotText,
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting)'), findsOneWidget);
      completer.complete('hello');
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<String>(ConnectionState.done, data: hello)'), findsOneWidget);
    });
    testWidgets('tracks life-cycle of Future to error', (WidgetTester tester) async {
      final Completer<String> completer = Completer<String>();
      await tester.pumpWidget(FutureBuilder<String>(
        future: completer.future, builder: snapshotText,
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting)'), findsOneWidget);
      completer.completeError('bad');
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<String>(ConnectionState.done, error: bad)'), findsOneWidget);
    });
    testWidgets('produces snapshot with null data for null-completing data Future', (WidgetTester tester) async {
      final Completer<String> completer = Completer<String>();
      await tester.pumpWidget(FutureBuilder<String>(
        future: completer.future, builder: snapshotText,
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting)'), findsOneWidget);
      completer.complete(null);
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<String>(ConnectionState.done, data: null)'), findsOneWidget);
    });
    testWidgets('produces snapshot with null data for Future<Null>', (WidgetTester tester) async {
      final Completer<Null> completer = Completer<Null>();  // ignore: prefer_void_to_null
      await tester.pumpWidget(FutureBuilder<Null>(  // ignore: prefer_void_to_null
        future: completer.future, builder: snapshotText,
      ));
      expect(find.text('AsyncSnapshot<Null>(ConnectionState.waiting)'), findsOneWidget);
      completer.complete();
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<Null>(ConnectionState.done, data: null)'), findsOneWidget);
    });
    testWidgets('produces snapshot with no data for Future<void>', (WidgetTester tester) async {
      final Completer<void> completer = Completer<void>();
      await tester.pumpWidget(
        FutureBuilder<void>(
          future: completer.future,
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            return Text(snapshot.toString(), textDirection: TextDirection.ltr);
          },
        ),
      );
      expect(find.text('AsyncSnapshot<void>(ConnectionState.waiting)'), findsOneWidget);
      completer.complete();
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<void>(ConnectionState.done)'), findsOneWidget);
    });
  });
  group('StreamBuilder', () {
    testWidgets('gracefully handles transition from null stream', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      await tester.pumpWidget(StreamBuilder<String>(
        key: key, stream: null, builder: snapshotText,
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.none)'), findsOneWidget);
      final StreamController<String> controller = StreamController<String>();
      await tester.pumpWidget(StreamBuilder<String>(
        key: key, stream: controller.stream, builder: snapshotText,
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting)'), findsOneWidget);
    });
    testWidgets('gracefully handles transition to null stream', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      final StreamController<String> controller = StreamController<String>();
      await tester.pumpWidget(StreamBuilder<String>(
        key: key, stream: controller.stream, builder: snapshotText,
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting)'), findsOneWidget);
      await tester.pumpWidget(StreamBuilder<String>(
        key: key, stream: null, builder: snapshotText,
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.none)'), findsOneWidget);
    });
    testWidgets('gracefully handles transition to other stream', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      final StreamController<String> controllerA = StreamController<String>();
      final StreamController<String> controllerB = StreamController<String>();
      await tester.pumpWidget(StreamBuilder<String>(
        key: key, stream: controllerA.stream, builder: snapshotText,
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting)'), findsOneWidget);
      await tester.pumpWidget(StreamBuilder<String>(
        key: key, stream: controllerB.stream, builder: snapshotText,
      ));
      controllerB.add('B');
      controllerA.add('A');
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<String>(ConnectionState.active, data: B)'), findsOneWidget);
    });
    testWidgets('tracks events and errors of stream until completion', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      final StreamController<String> controller = StreamController<String>();
      await tester.pumpWidget(StreamBuilder<String>(
        key: key, stream: controller.stream, builder: snapshotText,
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting)'), findsOneWidget);
      controller.add('1');
      controller.add('2');
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<String>(ConnectionState.active, data: 2)'), findsOneWidget);
      controller.add('3');
      controller.addError('bad');
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<String>(ConnectionState.active, error: bad)'), findsOneWidget);
      controller.add('4');
      controller.close();
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<String>(ConnectionState.done, data: 4)'), findsOneWidget);
    });
    testWidgets('runs the builder using given initial data', (WidgetTester tester) async {
      final StreamController<String> controller = StreamController<String>();
      await tester.pumpWidget(StreamBuilder<String>.withInitialData(
        stream: controller.stream,
        builder: snapshotText,
        initialData: 'I',
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting, data: I)'), findsOneWidget);
    });
    testWidgets('ignores initialData when reconfiguring', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      await tester.pumpWidget(StreamBuilder<String>.withInitialData(
        key: key,
        stream: null,
        builder: snapshotText,
        initialData: 'I',
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.none, data: I)'), findsOneWidget);
      final StreamController<String> controller = StreamController<String>();
      await tester.pumpWidget(StreamBuilder<String>.withInitialData(
        key: key,
        stream: controller.stream,
        builder: snapshotText,
        initialData: 'Ignored',
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting, data: I)'), findsOneWidget);
    });
    testWidgets('produces snapshots with null data for null-producing stream', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      final StreamController<String> controller = StreamController<String>();
      await tester.pumpWidget(StreamBuilder<String>(
        key: key,
        stream: controller.stream,
        builder: snapshotText,
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting)'), findsOneWidget);
      controller.add(null);
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<String>(ConnectionState.active, data: null)'), findsOneWidget);
      controller.addError('bad');
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<String>(ConnectionState.active, error: bad)'), findsOneWidget);
      controller.add(null);
      controller.close();
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<String>(ConnectionState.done, data: null)'), findsOneWidget);
    });
    testWidgets('produces snapshots with null data for Stream<Null>', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      final StreamController<Null> controller = StreamController<Null>();  // ignore: prefer_void_to_null
      await tester.pumpWidget(StreamBuilder<Null>(  // ignore: prefer_void_to_null
        key: key,
        stream: controller.stream,
        builder: snapshotText,
      ));
      expect(find.text('AsyncSnapshot<Null>(ConnectionState.waiting)'), findsOneWidget);
      controller.add(null);
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<Null>(ConnectionState.active, data: null)'), findsOneWidget);
      controller.addError('bad');
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<Null>(ConnectionState.active, error: bad)'), findsOneWidget);
      controller.add(null);
      controller.close();
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<Null>(ConnectionState.done, data: null)'), findsOneWidget);
    });
    testWidgets('produces snapshots with no data for Stream<void>', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      final StreamController<void> controller = StreamController<void>();
      await tester.pumpWidget(StreamBuilder<void>(
        key: key,
        stream: controller.stream,
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          return Text(snapshot.toString(), textDirection: TextDirection.ltr);
        },
      ));
      expect(find.text('AsyncSnapshot<void>(ConnectionState.waiting)'), findsOneWidget);
      controller.add(null);
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<void>(ConnectionState.active)'), findsOneWidget);
      controller.addError('bad');
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<void>(ConnectionState.active, error: bad)'), findsOneWidget);
      controller.add(null);
      controller.close();
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<void>(ConnectionState.done)'), findsOneWidget);
    });
  });
  group('FutureBuilder and StreamBuilder behave identically on Stream from Future', () {
    testWidgets('when completing with data', (WidgetTester tester) async {
      final Completer<String> completer = Completer<String>();
      await tester.pumpWidget(Column(children: <Widget>[
        FutureBuilder<String>(future: completer.future, builder: snapshotText),
        StreamBuilder<String>(stream: completer.future.asStream(), builder: snapshotText),
      ]));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting)'), findsNWidgets(2));
      completer.complete('hello');
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<String>(ConnectionState.done, data: hello)'), findsNWidgets(2));
    });
    testWidgets('when completing with error', (WidgetTester tester) async {
      final Completer<String> completer = Completer<String>();
      await tester.pumpWidget(Column(children: <Widget>[
        FutureBuilder<String>(future: completer.future, builder: snapshotText),
        StreamBuilder<String>(stream: completer.future.asStream(), builder: snapshotText),
      ]));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting)'), findsNWidgets(2));
      completer.completeError('bad');
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<String>(ConnectionState.done, error: bad)'), findsNWidgets(2));
    });
    testWidgets('when Future is null', (WidgetTester tester) async {
      await tester.pumpWidget(Column(children: <Widget>[
        FutureBuilder<String>(future: null, builder: snapshotText),
        StreamBuilder<String>(stream: null, builder: snapshotText),
      ]));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.none)'), findsNWidgets(2));
    });
  });
  group('StreamBuilderBase', () {
    testWidgets('gracefully handles transition from null stream', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      await tester.pumpWidget(StringCollector(key: key, stream: null));
      expect(find.text(''), findsOneWidget);
      final StreamController<String> controller = StreamController<String>();
      await tester.pumpWidget(StringCollector(key: key, stream: controller.stream));
      expect(find.text('conn'), findsOneWidget);
    });
    testWidgets('gracefully handles transition to null stream', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      final StreamController<String> controller = StreamController<String>();
      await tester.pumpWidget(StringCollector(key: key, stream: controller.stream));
      expect(find.text('conn'), findsOneWidget);
      await tester.pumpWidget(StringCollector(key: key, stream: null));
      expect(find.text('conn, disc'), findsOneWidget);
    });
    testWidgets('gracefully handles transition to other stream', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      final StreamController<String> controllerA = StreamController<String>();
      final StreamController<String> controllerB = StreamController<String>();
      await tester.pumpWidget(StringCollector(key: key, stream: controllerA.stream));
      await tester.pumpWidget(StringCollector(key: key, stream: controllerB.stream));
      controllerA.add('A');
      controllerB.add('B');
      await eventFiring(tester);
      expect(find.text('conn, disc, conn, data:B'), findsOneWidget);
    });
    testWidgets('tracks events and errors until completion', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      final StreamController<String> controller = StreamController<String>();
      await tester.pumpWidget(StringCollector(key: key, stream: controller.stream));
      controller.add('1');
      controller.addError('bad');
      controller.add('2');
      controller.close();
      await eventFiring(tester);
      expect(find.text('conn, data:1, error:bad, data:2, done'), findsOneWidget);
    });
  });
}

Future<void> eventFiring(WidgetTester tester) async {
  await tester.pump(Duration.zero);
}

class StringCollector extends StreamBuilderBase<String, List<String>> {
  const StringCollector({ Key key, Stream<String> stream }) : super(key: key, stream: stream);

  @override
  List<String> initial() => <String>[];

  @override
  List<String> afterConnected(List<String> current) => current..add('conn');

  @override
  List<String> afterData(List<String> current, String data) => current..add('data:$data');

  @override
  List<String> afterError(List<String> current, dynamic error) => current..add('error:$error');

  @override
  List<String> afterDone(List<String> current) => current..add('done');

  @override
  List<String> afterDisconnected(List<String> current) => current..add('disc');

  @override
  Widget build(BuildContext context, List<String> currentSummary) => Text(currentSummary.join(', '), textDirection: TextDirection.ltr);
}
