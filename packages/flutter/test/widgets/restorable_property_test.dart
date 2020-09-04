// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('value is not accessible when not registered', (WidgetTester tester) async {
    expect(() => RestorableNum<num>(0).value, throwsAssertionError);
    expect(() => RestorableDouble(1.0).value, throwsAssertionError);
    expect(() => RestorableInt(1).value, throwsAssertionError);
    expect(() => RestorableString('hello').value, throwsAssertionError);
    expect(() => RestorableBool(true).value, throwsAssertionError);
    expect(() => RestorableTextEditingController().value, throwsAssertionError);
    expect(() => _TestRestorableValue().value, throwsAssertionError);
  });

  testWidgets('cannot initialize with null', (WidgetTester tester) async {
    expect(() => RestorableNum<num>(null), throwsAssertionError);
    expect(() => RestorableDouble(null), throwsAssertionError);
    expect(() => RestorableInt(null), throwsAssertionError);
    expect(() => RestorableString(null).value, throwsAssertionError);
    expect(() => RestorableBool(null).value, throwsAssertionError);
  });

  testWidgets('work when not in restoration scope', (WidgetTester tester) async {
    await tester.pumpWidget(const _RestorableWidget());

    expect(find.text('hello world'), findsOneWidget);
    final _RestorableWidgetState state = tester.state(find.byType(_RestorableWidget));

    // Initialized to default values.
    expect(state.numValue.value, 99);
    expect(state.doubleValue.value, 123.2);
    expect(state.intValue.value, 42);
    expect(state.stringValue.value, 'hello world');
    expect(state.boolValue.value, false);
    expect(state.controllerValue.value.text, 'FooBar');
    expect(state.objectValue.value, 55);

    // Modify values.
    state.setProperties(() {
      state.numValue.value = 42.2;
      state.doubleValue.value = 441.3;
      state.intValue.value = 10;
      state.stringValue.value = 'guten tag';
      state.boolValue.value = true;
      state.controllerValue.value.text = 'blabla';
      state.objectValue.value = 53;
    });
    await tester.pump();

    expect(state.numValue.value, 42.2);
    expect(state.doubleValue.value, 441.3);
    expect(state.intValue.value, 10);
    expect(state.stringValue.value, 'guten tag');
    expect(state.boolValue.value, true);
    expect(state.controllerValue.value.text, 'blabla');
    expect(state.objectValue.value, 53);
    expect(find.text('guten tag'), findsOneWidget);
  });

  testWidgets('restart and restore', (WidgetTester tester) async {
    await tester.pumpWidget(const RootRestorationScope(
      restorationId: 'root-child',
      child: _RestorableWidget(),
    ));

    expect(find.text('hello world'), findsOneWidget);
    _RestorableWidgetState state = tester.state(find.byType(_RestorableWidget));

    // Initialized to default values.
    expect(state.numValue.value, 99);
    expect(state.doubleValue.value, 123.2);
    expect(state.intValue.value, 42);
    expect(state.stringValue.value, 'hello world');
    expect(state.boolValue.value, false);
    expect(state.controllerValue.value.text, 'FooBar');
    expect(state.objectValue.value, 55);

    // Modify values.
    state.setProperties(() {
      state.numValue.value = 42.2;
      state.doubleValue.value = 441.3;
      state.intValue.value = 10;
      state.stringValue.value = 'guten tag';
      state.boolValue.value = true;
      state.controllerValue.value.text = 'blabla';
      state.objectValue.value = 53;
    });
    await tester.pump();

    expect(state.numValue.value, 42.2);
    expect(state.doubleValue.value, 441.3);
    expect(state.intValue.value, 10);
    expect(state.stringValue.value, 'guten tag');
    expect(state.boolValue.value, true);
    expect(state.controllerValue.value.text, 'blabla');
    expect(state.objectValue.value, 53);
    expect(find.text('guten tag'), findsOneWidget);

    // Restores to previous values.
    await tester.restartAndRestore();
    final _RestorableWidgetState oldState = state;
    state = tester.state(find.byType(_RestorableWidget));
    expect(state, isNot(same(oldState)));

    expect(state.numValue.value, 42.2);
    expect(state.doubleValue.value, 441.3);
    expect(state.intValue.value, 10);
    expect(state.stringValue.value, 'guten tag');
    expect(state.boolValue.value, true);
    expect(state.controllerValue.value.text, 'blabla');
    expect(state.objectValue.value, 53);
    expect(find.text('guten tag'), findsOneWidget);
  });

  testWidgets('cannot set to null', (WidgetTester tester) async {
    await tester.pumpWidget(const RootRestorationScope(
      restorationId: 'root-child',
      child: _RestorableWidget(),
    ));

    expect(find.text('hello world'), findsOneWidget);
    final _RestorableWidgetState state = tester.state(find.byType(_RestorableWidget));

    expect(() => state.numValue.value = null, throwsAssertionError);
    expect(() => state.doubleValue.value = null, throwsAssertionError);
    expect(() => state.intValue.value = null, throwsAssertionError);
    expect(() => state.stringValue.value = null, throwsAssertionError);
    expect(() => state.boolValue.value = null, throwsAssertionError);
  });

  testWidgets('restore to older state', (WidgetTester tester) async {
    await tester.pumpWidget(const RootRestorationScope(
      restorationId: 'root-child',
      child: _RestorableWidget(),
    ));

    expect(find.text('hello world'), findsOneWidget);
    final _RestorableWidgetState state = tester.state(find.byType(_RestorableWidget));

    // Modify values.
    state.setProperties(() {
      state.numValue.value = 42.2;
      state.doubleValue.value = 441.3;
      state.intValue.value = 10;
      state.stringValue.value = 'guten tag';
      state.boolValue.value = true;
      state.controllerValue.value.text = 'blabla';
      state.objectValue.value = 53;
    });
    await tester.pump();
    expect(find.text('guten tag'), findsOneWidget);

    final TestRestorationData restorationData = await tester.getRestorationData();

    // Modify values.
    state.setProperties(() {
      state.numValue.value = 20;
      state.doubleValue.value = 20.0;
      state.intValue.value = 20;
      state.stringValue.value = 'ciao';
      state.boolValue.value = false;
      state.controllerValue.value.text = 'blub';
      state.objectValue.value = 20;
    });
    await tester.pump();
    expect(find.text('ciao'), findsOneWidget);
    final TextEditingController controller = state.controllerValue.value;

    // Restore to previous.
    await tester.restoreFrom(restorationData);
    expect(state.numValue.value, 42.2);
    expect(state.doubleValue.value, 441.3);
    expect(state.intValue.value, 10);
    expect(state.stringValue.value, 'guten tag');
    expect(state.boolValue.value, true);
    expect(state.controllerValue.value.text, 'blabla');
    expect(state.objectValue.value, 53);
    expect(find.text('guten tag'), findsOneWidget);
    expect(state.controllerValue.value, isNot(same(controller)));

    // Restore to empty data will re-initialize to default values.
    await tester.restoreFrom(TestRestorationData.empty);
    expect(state.numValue.value, 99);
    expect(state.doubleValue.value, 123.2);
    expect(state.intValue.value, 42);
    expect(state.stringValue.value, 'hello world');
    expect(state.boolValue.value, false);
    expect(state.controllerValue.value.text, 'FooBar');
    expect(state.objectValue.value, 55);
    expect(find.text('hello world'), findsOneWidget);
  });

  testWidgets('call notifiers when value changes', (WidgetTester tester) async {
    await tester.pumpWidget(const RootRestorationScope(
      restorationId: 'root-child',
      child: _RestorableWidget(),
    ));

    expect(find.text('hello world'), findsOneWidget);
    final _RestorableWidgetState state = tester.state(find.byType(_RestorableWidget));

    final List<String> notifyLog = <String>[];
    state.numValue.addListener(() {
      notifyLog.add('num');
    });
    state.doubleValue.addListener(() {
      notifyLog.add('double');
    });
    state.intValue.addListener(() {
      notifyLog.add('int');
    });
    state.stringValue.addListener(() {
      notifyLog.add('string');
    });
    state.boolValue.addListener(() {
      notifyLog.add('bool');
    });
    state.controllerValue.addListener(() {
      notifyLog.add('controller');
    });
    state.objectValue.addListener(() {
      notifyLog.add('object');
    });

    state.setProperties(() {
      state.numValue.value = 42.2;
    });
    expect(notifyLog.single, 'num');
    notifyLog.clear();

    state.setProperties(() {
      state.doubleValue.value = 42.2;
    });
    expect(notifyLog.single, 'double');
    notifyLog.clear();

    state.setProperties(() {
      state.intValue.value = 45;
    });
    expect(notifyLog.single, 'int');
    notifyLog.clear();

    state.setProperties(() {
      state.stringValue.value = 'bar';
    });
    expect(notifyLog.single, 'string');
    notifyLog.clear();

    state.setProperties(() {
      state.boolValue.value = true;
    });
    expect(notifyLog.single, 'bool');
    notifyLog.clear();

    state.setProperties(() {
      state.controllerValue.value.text = 'foo';
    });
    expect(notifyLog.single, 'controller');
    notifyLog.clear();

    state.setProperties(() {
      state.objectValue.value = 42;
    });
    expect(notifyLog.single, 'object');
    notifyLog.clear();

    await tester.pump();
    expect(find.text('bar'), findsOneWidget);

    // Does not notify when set to same value.
    state.setProperties(() {
      state.numValue.value = 42.2;
      state.doubleValue.value = 42.2;
      state.intValue.value = 45;
      state.stringValue.value = 'bar';
      state.boolValue.value = true;
      state.controllerValue.value.text = 'foo';
    });
    expect(notifyLog, isEmpty);
  });

  testWidgets('RestorableValue calls didUpdateValue', (WidgetTester tester) async {
    await tester.pumpWidget(const RootRestorationScope(
      restorationId: 'root-child',
      child: _RestorableWidget(),
    ));

    expect(find.text('hello world'), findsOneWidget);
    final _RestorableWidgetState state = tester.state(find.byType(_RestorableWidget));

    expect(state.objectValue.didUpdateValueCallCount, 0);

    state.setProperties(() {
      state.objectValue.value = 44;
    });
    expect(state.objectValue.didUpdateValueCallCount, 1);

    await tester.pump();

    state.setProperties(() {
      state.objectValue.value = 44;
    });
    expect(state.objectValue.didUpdateValueCallCount, 1);
  });
}

class _TestRestorableValue extends RestorableValue<Object> {
  @override
  Object createDefaultValue() {
    return 55;
  }

  int didUpdateValueCallCount = 0;

  @override
  void didUpdateValue(Object oldValue) {
    didUpdateValueCallCount++;
    notifyListeners();
  }

  @override
  Object fromPrimitives(Object data) {
    return data;
  }

  @override
  Object toPrimitives() {
    return value;
  }
}

class _RestorableWidget extends StatefulWidget {
  const _RestorableWidget({Key key}) : super(key: key);

  @override
  State<_RestorableWidget> createState() => _RestorableWidgetState();
}

class _RestorableWidgetState extends State<_RestorableWidget> with RestorationMixin {
  final RestorableNum<num> numValue = RestorableNum<num>(99);
  final RestorableDouble doubleValue = RestorableDouble(123.2);
  final RestorableInt intValue = RestorableInt(42);
  final RestorableString stringValue = RestorableString('hello world');
  final RestorableBool boolValue = RestorableBool(false);
  final RestorableTextEditingController controllerValue = RestorableTextEditingController(text: 'FooBar');
  final _TestRestorableValue objectValue = _TestRestorableValue();

  @override
  void restoreState(RestorationBucket oldBucket, bool initialRestore) {
    registerForRestoration(numValue, 'num');
    registerForRestoration(doubleValue, 'double');
    registerForRestoration(intValue, 'int');
    registerForRestoration(stringValue, 'string');
    registerForRestoration(boolValue,'bool');
    registerForRestoration(controllerValue, 'controller');
    registerForRestoration(objectValue, 'object');
  }

  void setProperties(VoidCallback callback) {
    setState(callback);
  }

  @override
  Widget build(BuildContext context) {
    return Text(stringValue.value ?? 'null', textDirection: TextDirection.ltr,);
  }

  @override
  String get restorationId => 'widget';
}
