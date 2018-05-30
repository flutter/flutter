// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart' hide TypeMatcher;
import 'package:flutter/widgets.dart';

typedef void TestCallback(BuildContext context);

class TestWidget extends StatefulWidget {
  const TestWidget(this.callback);

  final TestCallback callback;

  @override
  TestWidgetState createState() => new TestWidgetState();
}

class TestWidgetState extends State<TestWidget> {
  @override
  void dispose() {
    widget.callback(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Text('test', textDirection: TextDirection.ltr);
}

void main() {
  testWidgets('inheritFromWidgetOfExactType() called from dispose() throws error', (WidgetTester tester) async {
    bool disposeCalled = false;
    await tester.pumpWidget(
      new TestWidget((BuildContext context) {
        disposeCalled = true;
        context.inheritFromWidgetOfExactType(Container);
      }),
    );
    await tester.pumpWidget(new Container());
    expect(disposeCalled, isTrue);
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('ancestorInheritedElementForWidgetOfExactType() called from dispose() throws error', (WidgetTester tester) async {
    bool disposeCalled = false;
    await tester.pumpWidget(
      new TestWidget((BuildContext context) {
        disposeCalled = true;
        context.ancestorInheritedElementForWidgetOfExactType(Container);
      }),
    );
    await tester.pumpWidget(new Container());
    expect(disposeCalled, isTrue);
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('ancestorWidgetOfExactType() called from dispose() throws error', (WidgetTester tester) async {
    bool disposeCalled = false;
    await tester.pumpWidget(
      new TestWidget((BuildContext context) {
        disposeCalled = true;
        context.ancestorWidgetOfExactType(Container);
      }),
    );
    await tester.pumpWidget(new Container());
    expect(disposeCalled, isTrue);
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('ancestorStateOfType() called from dispose() throws error', (WidgetTester tester) async {
    bool disposeCalled = false;
    await tester.pumpWidget(
      new TestWidget((BuildContext context) {
        disposeCalled = true;
        context.ancestorStateOfType(const TypeMatcher<Container>());
      }),
    );
    await tester.pumpWidget(new Container());
    expect(disposeCalled, isTrue);
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('ancestorRenderObjectOfType() called from dispose() throws error', (WidgetTester tester) async {
    bool disposeCalled = false;
    await tester.pumpWidget(
      new TestWidget((BuildContext context) {
        disposeCalled = true;
        context.ancestorRenderObjectOfType(const TypeMatcher<Container>());
      }),
    );
    await tester.pumpWidget(new Container());
    expect(disposeCalled, isTrue);
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('visitAncestorElements() called from dispose() throws error', (WidgetTester tester) async {
    bool disposeCalled = false;
    await tester.pumpWidget(
      new TestWidget((BuildContext context) {
        disposeCalled = true;
        context.visitAncestorElements((Element element) { });
      }),
    );
    await tester.pumpWidget(new Container());
    expect(disposeCalled, isTrue);
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('dispose() method does not unconditionally throw an error', (WidgetTester tester) async {
    bool disposeCalled = false;
    await tester.pumpWidget(
      new TestWidget((BuildContext context) {
        disposeCalled = true;
      }),
    );
    await tester.pumpWidget(new Container());
    expect(disposeCalled, isTrue);
  });



}
