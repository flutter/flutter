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
    test('requiring data succeeds if data is present', () {
      expect(
        const AsyncSnapshot<String>.withData(ConnectionState.done, 'hello').requireData,
        'hello',
      );
    });
    test('requiring data fails if there is an error', () {
      expect(
        () => const AsyncSnapshot<String>.withError(ConnectionState.done, 'error').requireData,
        throwsA(equals('error')),
      );
    });
    test('requiring data fails if snapshot has neither data nor error', () {
      expect(
        () => const AsyncSnapshot<String>.nothing().requireData,
        throwsStateError,
      );
    });
  });
  group('Async smoke tests', () {
    testWidgets('FutureBuilder', (WidgetTester tester) async {
      await tester.pumpWidget(FutureBuilder<String>(
        future: Future<String>.value('hello'),
        builder: snapshotText
      ));
      await eventFiring(tester);
    });
    testWidgets('StreamBuilder', (WidgetTester tester) async {
      await tester.pumpWidget(StreamBuilder<String>(
        stream: Stream<String>.fromIterable(<String>['hello', 'world']),
        builder: snapshotText
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
        key: key, future: null, builder: snapshotText
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.none, null, null)'), findsOneWidget);
      final Completer<String> completer = Completer<String>();
      await tester.pumpWidget(FutureBuilder<String>(
        key: key, future: completer.future, builder: snapshotText
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting, null, null)'), findsOneWidget);
    });
    testWidgets('gracefully handles transition to null future', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      final Completer<String> completer = Completer<String>();
      await tester.pumpWidget(FutureBuilder<String>(
        key: key, future: completer.future, builder: snapshotText
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting, null, null)'), findsOneWidget);
      await tester.pumpWidget(FutureBuilder<String>(
        key: key, future: null, builder: snapshotText
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.none, null, null)'), findsOneWidget);
      completer.complete('hello');
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<String>(ConnectionState.none, null, null)'), findsOneWidget);
    });
    testWidgets('gracefully handles transition to other future', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      final Completer<String> completerA = Completer<String>();
      final Completer<String> completerB = Completer<String>();
      await tester.pumpWidget(FutureBuilder<String>(
        key: key, future: completerA.future, builder: snapshotText
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting, null, null)'), findsOneWidget);
      await tester.pumpWidget(FutureBuilder<String>(
        key: key, future: completerB.future, builder: snapshotText
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting, null, null)'), findsOneWidget);
      completerB.complete('B');
      completerA.complete('A');
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<String>(ConnectionState.done, B, null)'), findsOneWidget);
    });
    testWidgets('tracks life-cycle of Future to success', (WidgetTester tester) async {
      final Completer<String> completer = Completer<String>();
      await tester.pumpWidget(FutureBuilder<String>(
        future: completer.future, builder: snapshotText
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting, null, null)'), findsOneWidget);
      completer.complete('hello');
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<String>(ConnectionState.done, hello, null)'), findsOneWidget);
    });
    testWidgets('tracks life-cycle of Future to error', (WidgetTester tester) async {
      final Completer<String> completer = Completer<String>();
      await tester.pumpWidget(FutureBuilder<String>(
        future: completer.future, builder: snapshotText
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting, null, null)'), findsOneWidget);
      completer.completeError('bad');
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<String>(ConnectionState.done, null, bad)'), findsOneWidget);
    });
    testWidgets('runs the builder using given initial data', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      await tester.pumpWidget(FutureBuilder<String>(
        key: key,
        future: null,
        builder: snapshotText,
        initialData: 'I',
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.none, I, null)'), findsOneWidget);
    });
    testWidgets('ignores initialData when reconfiguring', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      await tester.pumpWidget(FutureBuilder<String>(
        key: key,
        future: null,
        builder: snapshotText,
        initialData: 'I',
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.none, I, null)'), findsOneWidget);
      final Completer<String> completer = Completer<String>();
      await tester.pumpWidget(FutureBuilder<String>(
        key: key,
        future: completer.future,
        builder: snapshotText,
        initialData: 'Ignored',
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting, I, null)'), findsOneWidget);
    });
  });
  group('StreamBuilder', () {
    testWidgets('gracefully handles transition from null stream', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      await tester.pumpWidget(StreamBuilder<String>(
        key: key, stream: null, builder: snapshotText
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.none, null, null)'), findsOneWidget);
      final StreamController<String> controller = StreamController<String>();
      await tester.pumpWidget(StreamBuilder<String>(
        key: key, stream: controller.stream, builder: snapshotText
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting, null, null)'), findsOneWidget);
    });
    testWidgets('gracefully handles transition to null stream', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      final StreamController<String> controller = StreamController<String>();
      await tester.pumpWidget(StreamBuilder<String>(
        key: key, stream: controller.stream, builder: snapshotText
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting, null, null)'), findsOneWidget);
      await tester.pumpWidget(StreamBuilder<String>(
        key: key, stream: null, builder: snapshotText
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.none, null, null)'), findsOneWidget);
    });
    testWidgets('gracefully handles transition to other stream', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      final StreamController<String> controllerA = StreamController<String>();
      final StreamController<String> controllerB = StreamController<String>();
      await tester.pumpWidget(StreamBuilder<String>(
        key: key, stream: controllerA.stream, builder: snapshotText
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting, null, null)'), findsOneWidget);
      await tester.pumpWidget(StreamBuilder<String>(
        key: key, stream: controllerB.stream, builder: snapshotText
      ));
      controllerB.add('B');
      controllerA.add('A');
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<String>(ConnectionState.active, B, null)'), findsOneWidget);
    });
    testWidgets('tracks events and errors of stream until completion', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      final StreamController<String> controller = StreamController<String>();
      await tester.pumpWidget(StreamBuilder<String>(
        key: key, stream: controller.stream, builder: snapshotText
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting, null, null)'), findsOneWidget);
      controller.add('1');
      controller.add('2');
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<String>(ConnectionState.active, 2, null)'), findsOneWidget);
      controller.add('3');
      controller.addError('bad');
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<String>(ConnectionState.active, null, bad)'), findsOneWidget);
      controller.add('4');
      controller.close();
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<String>(ConnectionState.done, 4, null)'), findsOneWidget);
    });
    testWidgets('runs the builder using given initial data', (WidgetTester tester) async {
      final StreamController<String> controller = StreamController<String>();
      await tester.pumpWidget(StreamBuilder<String>(
        stream: controller.stream,
        builder: snapshotText,
        initialData: 'I',
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting, I, null)'), findsOneWidget);
    });
    testWidgets('ignores initialData when reconfiguring', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      await tester.pumpWidget(StreamBuilder<String>(
        key: key,
        stream: null,
        builder: snapshotText,
        initialData: 'I',
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.none, I, null)'), findsOneWidget);
      final StreamController<String> controller = StreamController<String>();
      await tester.pumpWidget(StreamBuilder<String>(
        key: key,
        stream: controller.stream,
        builder: snapshotText,
        initialData: 'Ignored',
      ));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting, I, null)'), findsOneWidget);
    });
  });
  group('FutureBuilder and StreamBuilder behave identically on Stream from Future', () {
    testWidgets('when completing with data', (WidgetTester tester) async {
      final Completer<String> completer = Completer<String>();
      await tester.pumpWidget(Column(children: <Widget>[
        FutureBuilder<String>(future: completer.future, builder: snapshotText),
        StreamBuilder<String>(stream: completer.future.asStream(), builder: snapshotText),
      ]));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting, null, null)'), findsNWidgets(2));
      completer.complete('hello');
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<String>(ConnectionState.done, hello, null)'), findsNWidgets(2));
    });
    testWidgets('when completing with error', (WidgetTester tester) async {
      final Completer<String> completer = Completer<String>();
      await tester.pumpWidget(Column(children: <Widget>[
        FutureBuilder<String>(future: completer.future, builder: snapshotText),
        StreamBuilder<String>(stream: completer.future.asStream(), builder: snapshotText),
      ]));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting, null, null)'), findsNWidgets(2));
      completer.completeError('bad');
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<String>(ConnectionState.done, null, bad)'), findsNWidgets(2));
    });
    testWidgets('when Future is null', (WidgetTester tester) async {
      await tester.pumpWidget(Column(children: <Widget>[
        FutureBuilder<String>(future: null, builder: snapshotText),
        StreamBuilder<String>(stream: null, builder: snapshotText),
      ]));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.none, null, null)'), findsNWidgets(2));
    });
    testWidgets('when initialData is used with null Future and Stream', (WidgetTester tester) async {
      await tester.pumpWidget(Column(children: <Widget>[
        FutureBuilder<String>(future: null, builder: snapshotText, initialData: 'I'),
        StreamBuilder<String>(stream: null, builder: snapshotText, initialData: 'I'),
      ]));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.none, I, null)'), findsNWidgets(2));
    });
    testWidgets('when using initialData and completing with data', (WidgetTester tester) async {
      final Completer<String> completer = Completer<String>();
      await tester.pumpWidget(Column(children: <Widget>[
        FutureBuilder<String>(future: completer.future, builder: snapshotText, initialData: 'I'),
        StreamBuilder<String>(stream: completer.future.asStream(), builder: snapshotText, initialData: 'I'),
      ]));
      expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting, I, null)'), findsNWidgets(2));
      completer.complete('hello');
      await eventFiring(tester);
      expect(find.text('AsyncSnapshot<String>(ConnectionState.done, hello, null)'), findsNWidgets(2));
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
