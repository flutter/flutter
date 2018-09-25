// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class TestState extends State<StatefulWidget> {
  @override
  Widget build(BuildContext context) => null;
}

@optionalTypeArgs
class _MyGlobalObjectKey<T extends State<StatefulWidget>> extends GlobalObjectKey<T> {
  const _MyGlobalObjectKey(Object value) : super(value);
}

void main() {
  testWidgets('UniqueKey control test', (WidgetTester tester) async {
    final Key key = UniqueKey();
    expect(key, hasOneLineDescription);
    expect(key, isNot(equals(UniqueKey())));
  });

  testWidgets('ObjectKey control test', (WidgetTester tester) async {
    final Object a = Object();
    final Object b = Object();
    final Key keyA = ObjectKey(a);
    final Key keyA2 = ObjectKey(a);
    final Key keyB = ObjectKey(b);

    expect(keyA, hasOneLineDescription);
    expect(keyA, equals(keyA2));
    expect(keyA.hashCode, equals(keyA2.hashCode));
    expect(keyA, isNot(equals(keyB)));
  });

  testWidgets('GlobalObjectKey toString test', (WidgetTester tester) async {
    const GlobalObjectKey one = GlobalObjectKey(1);
    const GlobalObjectKey<TestState> two = GlobalObjectKey<TestState>(2);
    const GlobalObjectKey three = _MyGlobalObjectKey(3);
    const GlobalObjectKey<TestState> four = _MyGlobalObjectKey<TestState>(4);

    expect(one.toString(), equals('[GlobalObjectKey ${describeIdentity(1)}]'));
    expect(two.toString(), equals('[GlobalObjectKey<TestState> ${describeIdentity(2)}]'));
    expect(three.toString(), equals('[_MyGlobalObjectKey ${describeIdentity(3)}]'));
    expect(four.toString(), equals('[_MyGlobalObjectKey<TestState> ${describeIdentity(4)}]'));
  });

  testWidgets('GlobalObjectKey control test', (WidgetTester tester) async {
    final Object a = Object();
    final Object b = Object();
    final Key keyA = GlobalObjectKey(a);
    final Key keyA2 = GlobalObjectKey(a);
    final Key keyB = GlobalObjectKey(b);

    expect(keyA, hasOneLineDescription);
    expect(keyA, equals(keyA2));
    expect(keyA.hashCode, equals(keyA2.hashCode));
    expect(keyA, isNot(equals(keyB)));
  });

  testWidgets('GlobalKey duplication 1 - double appearance', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(
          key: const ValueKey<int>(1),
          child: SizedBox(key: key),
        ),
        Container(
          key: const ValueKey<int>(2),
          child: Placeholder(key: key),
        ),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 2 - splitting and changing type', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');

    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(
          key: const ValueKey<int>(1),
        ),
        Container(
          key: const ValueKey<int>(2),
        ),
        Container(
          key: key
        ),
      ],
    ));

    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(
          key: const ValueKey<int>(1),
          child: SizedBox(key: key),
        ),
        Container(
          key: const ValueKey<int>(2),
          child: Placeholder(key: key),
        ),
      ],
    ));

    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 3 - splitting and changing type', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: key),
      ],
    ));
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        SizedBox(key: key),
        Placeholder(key: key),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 4 - splitting and half changing type', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: key),
      ],
    ));
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: key),
        Placeholder(key: key),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 5 - splitting and half changing type', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: key),
      ],
    ));
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Placeholder(key: key),
        Container(key: key),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 6 - splitting and not changing type', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: key),
      ],
    ));
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: key),
        Container(key: key),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 7 - appearing later', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: const ValueKey<int>(1), child: Container(key: key)),
        Container(key: const ValueKey<int>(2)),
      ],
    ));
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: const ValueKey<int>(1), child: Container(key: key)),
        Container(key: const ValueKey<int>(2), child: Container(key: key)),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 8 - appearing earlier', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: const ValueKey<int>(1)),
        Container(key: const ValueKey<int>(2), child: Container(key: key)),
      ],
    ));
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: const ValueKey<int>(1), child: Container(key: key)),
        Container(key: const ValueKey<int>(2), child: Container(key: key)),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 9 - moving and appearing later', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: const ValueKey<int>(0), child: Container(key: key)),
        Container(key: const ValueKey<int>(1)),
        Container(key: const ValueKey<int>(2)),
      ],
    ));
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: const ValueKey<int>(0)),
        Container(key: const ValueKey<int>(1), child: Container(key: key)),
        Container(key: const ValueKey<int>(2), child: Container(key: key)),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 10 - moving and appearing earlier', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: const ValueKey<int>(1)),
        Container(key: const ValueKey<int>(2)),
        Container(key: const ValueKey<int>(3), child: Container(key: key)),
      ],
    ));
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: const ValueKey<int>(1), child: Container(key: key)),
        Container(key: const ValueKey<int>(2), child: Container(key: key)),
        Container(key: const ValueKey<int>(3)),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 11 - double sibling appearance', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: key),
        Container(key: key),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 12 - all kinds of badness at once', (WidgetTester tester) async {
    final Key key1 = GlobalKey(debugLabel: 'problematic');
    final Key key2 = GlobalKey(debugLabel: 'problematic'); // intentionally the same label
    final Key key3 = GlobalKey(debugLabel: 'also problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: key1),
        Container(key: key1),
        Container(key: key2),
        Container(key: key1),
        Container(key: key1),
        Container(key: key2),
        Container(key: key1),
        Container(key: key1),
        Row(
          children: <Widget>[
            Container(key: key1),
            Container(key: key1),
            Container(key: key2),
            Container(key: key2),
            Container(key: key2),
            Container(key: key3),
            Container(key: key2),
          ],
        ),
        Row(
          children: <Widget>[
            Container(key: key1),
            Container(key: key1),
            Container(key: key3),
          ],
        ),
        Container(key: key3),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 13 - all kinds of badness at once', (WidgetTester tester) async {
    final Key key1 = GlobalKey(debugLabel: 'problematic');
    final Key key2 = GlobalKey(debugLabel: 'problematic'); // intentionally the same label
    final Key key3 = GlobalKey(debugLabel: 'also problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: key1),
        Container(key: key2),
        Container(key: key3),
      ]),
    );
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: key1),
        Container(key: key1),
        Container(key: key2),
        Container(key: key1),
        Container(key: key1),
        Container(key: key2),
        Container(key: key1),
        Container(key: key1),
        Row(
          children: <Widget>[
            Container(key: key1),
            Container(key: key1),
            Container(key: key2),
            Container(key: key2),
            Container(key: key2),
            Container(key: key3),
            Container(key: key2),
          ],
        ),
        Row(
          children: <Widget>[
            Container(key: key1),
            Container(key: key1),
            Container(key: key3),
          ],
        ),
        Container(key: key3),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 14 - moving during build - before', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: key),
        Container(key: const ValueKey<int>(0)),
        Container(key: const ValueKey<int>(1)),
      ],
    ));
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: const ValueKey<int>(0)),
        Container(key: const ValueKey<int>(1), child: Container(key: key)),
      ],
    ));
  });

  testWidgets('GlobalKey duplication 15 - duplicating during build - before', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: key),
        Container(key: const ValueKey<int>(0)),
        Container(key: const ValueKey<int>(1)),
      ],
    ));
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: key),
        Container(key: const ValueKey<int>(0)),
        Container(key: const ValueKey<int>(1), child: Container(key: key)),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 16 - moving during build - after', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: const ValueKey<int>(0)),
        Container(key: const ValueKey<int>(1)),
        Container(key: key),
      ],
    ));
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: const ValueKey<int>(0)),
        Container(key: const ValueKey<int>(1), child: Container(key: key)),
      ],
    ));
  });

  testWidgets('GlobalKey duplication 17 - duplicating during build - after', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: const ValueKey<int>(0)),
        Container(key: const ValueKey<int>(1)),
        Container(key: key),
      ],
    ));
    int count = 0;
    final FlutterExceptionHandler oldHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      expect(details.exception, isFlutterError);
      count += 1;
    };
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: const ValueKey<int>(0)),
        Container(key: const ValueKey<int>(1), child: Container(key: key)),
        Container(key: key),
      ],
    ));
    FlutterError.onError = oldHandler;
    expect(count, 2);
  });

  testWidgets('Defunct setState throws exception', (WidgetTester tester) async {
    StateSetter setState;

    await tester.pumpWidget(StatefulBuilder(
      builder: (BuildContext context, StateSetter setter) {
        setState = setter;
        return Container();
      },
    ));

    // Control check that setState doesn't throw an exception.
    setState(() { });

    await tester.pumpWidget(Container());

    expect(() { setState(() { }); }, throwsFlutterError);
  });

  testWidgets('State toString', (WidgetTester tester) async {
    final TestState state = TestState();
    expect(state.toString(), contains('no widget'));
  });

  testWidgets('debugPrintGlobalKeyedWidgetLifecycle control test', (WidgetTester tester) async {
    expect(debugPrintGlobalKeyedWidgetLifecycle, isFalse);

    final DebugPrintCallback oldCallback = debugPrint;
    debugPrintGlobalKeyedWidgetLifecycle = true;

    final List<String> log = <String>[];
    debugPrint = (String message, { int wrapWidth }) {
      log.add(message);
    };

    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(Container(key: key));
    expect(log, isEmpty);
    await tester.pumpWidget(const Placeholder());
    debugPrint = oldCallback;
    debugPrintGlobalKeyedWidgetLifecycle = false;

    expect(log.length, equals(2));
    expect(log[0], matches('Deactivated'));
    expect(log[1], matches('Discarding .+ from inactive elements list.'));
  });

  testWidgets('MultiChildRenderObjectElement.children', (WidgetTester tester) async {
    GlobalKey key0, key1, key2;
    await tester.pumpWidget(Column(
      key: key0 = GlobalKey(),
      children: <Widget>[
        Container(),
        Container(key: key1 = GlobalKey()),
        Container(child: Container()),
        Container(key: key2 = GlobalKey()),
        Container(),
      ],
    ));
    final MultiChildRenderObjectElement element = key0.currentContext;
    expect(
      element.children.map((Element element) => element.widget.key), // ignore: INVALID_USE_OF_PROTECTED_MEMBER
      <Key>[null, key1, null, key2, null],
    );
  });

  testWidgets('Element diagnostics', (WidgetTester tester) async {
    GlobalKey key0;
    await tester.pumpWidget(Column(
      key: key0 = GlobalKey(),
      children: <Widget>[
        Container(),
        Container(key: GlobalKey()),
        Container(child: Container()),
        Container(key: GlobalKey()),
        Container(),
      ],
    ));
    final MultiChildRenderObjectElement element = key0.currentContext;

    expect(element, hasAGoodToStringDeep);
    expect(
      element.toStringDeep(),
      equalsIgnoringHashCodes(
        'Column-[GlobalKey#00000](direction: vertical, mainAxisAlignment: start, crossAxisAlignment: center, renderObject: RenderFlex#00000)\n'
        '├Container\n'
        '│└LimitedBox(maxWidth: 0.0, maxHeight: 0.0, renderObject: RenderLimitedBox#00000 relayoutBoundary=up1)\n'
        '│ └ConstrainedBox(BoxConstraints(biggest), renderObject: RenderConstrainedBox#00000 relayoutBoundary=up2)\n'
        '├Container-[GlobalKey#00000]\n'
        '│└LimitedBox(maxWidth: 0.0, maxHeight: 0.0, renderObject: RenderLimitedBox#00000 relayoutBoundary=up1)\n'
        '│ └ConstrainedBox(BoxConstraints(biggest), renderObject: RenderConstrainedBox#00000 relayoutBoundary=up2)\n'
        '├Container\n'
        '│└Container\n'
        '│ └LimitedBox(maxWidth: 0.0, maxHeight: 0.0, renderObject: RenderLimitedBox#00000 relayoutBoundary=up1)\n'
        '│  └ConstrainedBox(BoxConstraints(biggest), renderObject: RenderConstrainedBox#00000 relayoutBoundary=up2)\n'
        '├Container-[GlobalKey#00000]\n'
        '│└LimitedBox(maxWidth: 0.0, maxHeight: 0.0, renderObject: RenderLimitedBox#00000 relayoutBoundary=up1)\n'
        '│ └ConstrainedBox(BoxConstraints(biggest), renderObject: RenderConstrainedBox#00000 relayoutBoundary=up2)\n'
        '└Container\n'
        ' └LimitedBox(maxWidth: 0.0, maxHeight: 0.0, renderObject: RenderLimitedBox#00000 relayoutBoundary=up1)\n'
        '  └ConstrainedBox(BoxConstraints(biggest), renderObject: RenderConstrainedBox#00000 relayoutBoundary=up2)\n',
      ),
    );
  });

  testWidgets('Element diagnostics with null child', (WidgetTester tester) async {
    await tester.pumpWidget(NullChildTest());
    final NullChildElement test = tester.element<NullChildElement>(find.byType(NullChildTest));
    test.includeChild = true;
    expect(
      tester.binding.renderViewElement.toStringDeep(),
      equalsIgnoringHashCodes(
        '[root](renderObject: RenderView#4a0f0)\n'
        '└NullChildTest(dirty)\n'
        ' └<null child>\n',
      ),
    );
    test.includeChild = false;
  });
}

class NullChildTest extends Widget {
  @override
  Element createElement() => NullChildElement(this);
}

class NullChildElement extends Element {
  NullChildElement(Widget widget) : super(widget);

  bool includeChild = false;

  @override
  void visitChildren(ElementVisitor visitor) {
    if (includeChild)
      visitor(null);
  }

  @override
  void forgetChild(Element child) { }

  @override
  void performRebuild() { }
}
