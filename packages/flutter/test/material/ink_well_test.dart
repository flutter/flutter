// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';
import 'feedback_tester.dart';

void main() {
  testWidgets('InkWell gestures control test', (WidgetTester tester) async {
    final List<String> log = <String>[];

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        child: Center(
          child: InkWell(
            onTap: () {
              log.add('tap');
            },
            onDoubleTap: () {
              log.add('double-tap');
            },
            onLongPress: () {
              log.add('long-press');
            },
            onTapDown: (TapDownDetails details) {
              log.add('tap-down');
            },
            onTapCancel: () {
              log.add('tap-cancel');
            },
          ),
        ),
      ),
    ));

    await tester.tap(find.byType(InkWell), pointer: 1);

    expect(log, isEmpty);

    await tester.pump(const Duration(seconds: 1));

    expect(log, equals(<String>['tap-down', 'tap']));
    log.clear();

    await tester.tap(find.byType(InkWell), pointer: 2);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byType(InkWell), pointer: 3);

    expect(log, equals(<String>['double-tap']));
    log.clear();

    await tester.longPress(find.byType(InkWell), pointer: 4);

    expect(log, equals(<String>['tap-down', 'tap-cancel', 'long-press']));

    log.clear();
    TestGesture gesture = await tester.startGesture(tester.getRect(find.byType(InkWell)).center);
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['tap-down']));
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));

    log.clear();
    gesture = await tester.startGesture(tester.getRect(find.byType(InkWell)).center);
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0.0, 200.0));
    await gesture.cancel();
    expect(log, equals(<String>['tap-down', 'tap-cancel']));
  });

  testWidgets('long-press and tap on disabled should not throw', (WidgetTester tester) async {
    await tester.pumpWidget(const Material(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: InkWell(),
        ),
      ),
    ));
    await tester.tap(find.byType(InkWell), pointer: 1);
    await tester.pump(const Duration(seconds: 1));
    await tester.longPress(find.byType(InkWell), pointer: 1);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('ink well changes color on hover', (WidgetTester tester) async {
    await tester.pumpWidget(Material(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Container(
            width: 100,
            height: 100,
            child: InkWell(
              hoverColor: const Color(0xff00ff00),
              splashColor: const Color(0xffff0000),
              focusColor: const Color(0xff0000ff),
              highlightColor: const Color(0xf00fffff),
              onTap: () { },
              onLongPress: () { },
              onHover: (bool hover) { },
            ),
          ),
        ),
      ),
    ));
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(Container)));
    await tester.pumpAndSettle();
    final RenderObject inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, paints..rect(rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0), color: const Color(0xff00ff00)));
  });

  testWidgets('ink response changes color on focus', (WidgetTester tester) async {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    final FocusNode focusNode = FocusNode(debugLabel: 'Ink Focus');
    await tester.pumpWidget(
      Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: Container(
              width: 100,
              height: 100,
              child: InkWell(
                focusNode: focusNode,
                hoverColor: const Color(0xff00ff00),
                splashColor: const Color(0xffff0000),
                focusColor: const Color(0xff0000ff),
                highlightColor: const Color(0xf00fffff),
                onTap: () { },
                onLongPress: () { },
                onHover: (bool hover) { },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final RenderObject inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, paintsExactlyCountTimes(#rect, 0));
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(inkFeatures, paints
      ..rect(rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0), color: const Color(0xff0000ff)));
  });

  testWidgets("ink response doesn't change color on focus when on touch device", (WidgetTester tester) async {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
    final FocusNode focusNode = FocusNode(debugLabel: 'Ink Focus');
    await tester.pumpWidget(Material(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Focus(
            focusNode: focusNode,
            child: Container(
              width: 100,
              height: 100,
              child: InkWell(
                  hoverColor: const Color(0xff00ff00),
                  splashColor: const Color(0xffff0000),
                  focusColor: const Color(0xff0000ff),
                  highlightColor: const Color(0xf00fffff),
                  onTap: () { },
                  onLongPress: () { },
                  onHover: (bool hover) { },
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final RenderObject inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, paintsExactlyCountTimes(#rect, 0));
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(inkFeatures, paintsExactlyCountTimes(#rect, 0));
  });

  testWidgets('InkWell.mouseCursor changes cursor on hover', (WidgetTester tester) async {
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    await gesture.addPointer(location: const Offset(1, 1));
    addTearDown(gesture.removePointer);

    // Test argument works
    await tester.pumpWidget(
      Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MouseRegion(
            cursor: SystemMouseCursors.forbidden,
            child: InkWell(
              mouseCursor: SystemMouseCursors.click,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.click);

    // Test default of InkWell()
    await tester.pumpWidget(
      Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MouseRegion(
            cursor: SystemMouseCursors.forbidden,
            child: InkWell(
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.forbidden);

    // Test default of InkResponse()
    await tester.pumpWidget(
      Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MouseRegion(
            cursor: SystemMouseCursors.forbidden,
            child: InkResponse(
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.forbidden);
  });

  group('feedback', () {
    FeedbackTester feedback;

    setUp(() {
      feedback = FeedbackTester();
    });

    tearDown(() {
      feedback?.dispose();
    });

    testWidgets('enabled (default)', (WidgetTester tester) async {
      await tester.pumpWidget(Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: InkWell(
              onTap: () { },
              onLongPress: () { },
            ),
          ),
        ),
      ));
      await tester.tap(find.byType(InkWell), pointer: 1);
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 1);
      expect(feedback.hapticCount, 0);

      await tester.tap(find.byType(InkWell), pointer: 1);
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 2);
      expect(feedback.hapticCount, 0);

      await tester.longPress(find.byType(InkWell), pointer: 1);
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 2);
      expect(feedback.hapticCount, 1);
    });

    testWidgets('disabled', (WidgetTester tester) async {
      await tester.pumpWidget(Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: InkWell(
              onTap: () { },
              onLongPress: () { },
              enableFeedback: false,
            ),
          ),
        ),
      ));
      await tester.tap(find.byType(InkWell), pointer: 1);
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 0);
      expect(feedback.hapticCount, 0);

      await tester.longPress(find.byType(InkWell), pointer: 1);
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 0);
      expect(feedback.hapticCount, 0);
    });
  });

  testWidgets('splashing survives scrolling when keep-alive is enabled', (WidgetTester tester) async {
    Future<void> runTest(bool keepAlive) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: CompositedTransformFollower(
              // forces a layer, which makes the paints easier to separate out
              link: LayerLink(),
              child: ListView(
                addAutomaticKeepAlives: keepAlive,
                dragStartBehavior: DragStartBehavior.down,
                children: <Widget>[
                  Container(height: 500.0, child: InkWell(onTap: () {}, child: const Placeholder())),
                  Container(height: 500.0),
                  Container(height: 500.0),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.renderObject<RenderProxyBox>(find.byType(PhysicalModel)).child, isNot(paints..circle()));
      await tester.tap(find.byType(InkWell));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      expect(tester.renderObject<RenderProxyBox>(find.byType(PhysicalModel)).child, paints..circle());
      await tester.drag(find.byType(ListView), const Offset(0.0, -1000.0));
      await tester.pump(const Duration(milliseconds: 10));
      await tester.drag(find.byType(ListView), const Offset(0.0, 1000.0));
      await tester.pump(const Duration(milliseconds: 10));
      expect(
        tester.renderObject<RenderProxyBox>(find.byType(PhysicalModel)).child,
        keepAlive ? (paints..circle()) : isNot(paints..circle()),
      );
    }

    await runTest(true);
    await runTest(false);
  });

  testWidgets('excludeFromSemantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        child: InkWell(
          onTap: () { },
          child: const Text('Button'),
        ),
      ),
    ));
    expect(semantics, includesNodeWith(label: 'Button', actions: <SemanticsAction>[SemanticsAction.tap]));

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        child: InkWell(
          onTap: () { },
          child: const Text('Button'),
          excludeFromSemantics: true,
        ),
      ),
    ));
    expect(semantics, isNot(includesNodeWith(label: 'Button', actions: <SemanticsAction>[SemanticsAction.tap])));

    semantics.dispose();
  });

  testWidgets("ink response doesn't focus when disabled", (WidgetTester tester) async {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
    final FocusNode focusNode = FocusNode(debugLabel: 'Ink Focus');
    final GlobalKey childKey = GlobalKey();
    await tester.pumpWidget(
      Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: InkWell(
            autofocus: true,
            onTap: () {},
            onLongPress: () {},
            onHover: (bool hover) {},
            focusNode: focusNode,
            child: Container(key: childKey),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(focusNode.hasPrimaryFocus, isTrue);
    await tester.pumpWidget(
      Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: InkWell(
            focusNode: focusNode,
            child: Container(key: childKey),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(focusNode.hasPrimaryFocus, isFalse);
  });

  testWidgets('ink response accepts focus when disabled in directional navigation mode', (WidgetTester tester) async {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
    final FocusNode focusNode = FocusNode(debugLabel: 'Ink Focus');
    final GlobalKey childKey = GlobalKey();
    await tester.pumpWidget(
      Material(
        child: MediaQuery(
          data: const MediaQueryData(
            navigationMode: NavigationMode.directional,
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: InkWell(
              autofocus: true,
              onTap: () {},
              onLongPress: () {},
              onHover: (bool hover) {},
              focusNode: focusNode,
              child: Container(key: childKey),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(focusNode.hasPrimaryFocus, isTrue);
    await tester.pumpWidget(
      Material(
        child: MediaQuery(
          data: const MediaQueryData(
            navigationMode: NavigationMode.directional,
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: InkWell(
              focusNode: focusNode,
              child: Container(key: childKey),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(focusNode.hasPrimaryFocus, isTrue);
  });

  testWidgets("ink response doesn't hover when disabled", (WidgetTester tester) async {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
    final FocusNode focusNode = FocusNode(debugLabel: 'Ink Focus');
    final GlobalKey childKey = GlobalKey();
    bool hovering = false;
    await tester.pumpWidget(
      Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            width: 100,
            height: 100,
            child: InkWell(
              autofocus: true,
              onTap: () {},
              onLongPress: () {},
              onHover: (bool value) { hovering = value; },
              focusNode: focusNode,
              child: Container(key: childKey),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(focusNode.hasPrimaryFocus, isTrue);
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byKey(childKey)));
    await tester.pumpAndSettle();
    expect(hovering, isTrue);

    await tester.pumpWidget(
      Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            width: 100,
            height: 100,
            child: InkWell(
              focusNode: focusNode,
              onHover: (bool value) { hovering = value; },
              child: Container(key: childKey),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(focusNode.hasPrimaryFocus, isFalse);
  });

  testWidgets('When ink wells are nested, only the inner one is triggered by tap splash', (WidgetTester tester) async {
    final GlobalKey middleKey = GlobalKey();
    final GlobalKey innerKey = GlobalKey();
    Widget paddedInkWell({Key key, Widget child}) {
      return InkWell(
        key: key,
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(50),
          child: child,
        ),
      );
    }

    await tester.pumpWidget(
      Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: paddedInkWell(
              child: paddedInkWell(
                key: middleKey,
                child: paddedInkWell(
                  key: innerKey,
                  child: Container(width: 50, height: 50),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final MaterialInkController material = Material.of(tester.element(find.byKey(innerKey)));

    // Press
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byKey(innerKey)), pointer: 1);
    await tester.pump(const Duration(milliseconds: 200));
    expect(material, paintsExactlyCountTimes(#drawCircle, 1));

    // Up
    await gesture.up();
    await tester.pumpAndSettle();
    expect(material, paintsNothing);

    // Press again
    await gesture.down(tester.getCenter(find.byKey(innerKey)));
    await tester.pump(const Duration(milliseconds: 200));
    expect(material, paintsExactlyCountTimes(#drawCircle, 1));

    // Cancel
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(material, paintsNothing);

    // Press again
    await gesture.down(tester.getCenter(find.byKey(innerKey)));
    await tester.pump(const Duration(milliseconds: 200));
    expect(material, paintsExactlyCountTimes(#drawCircle, 1));

    // Use a second pointer to press
    final TestGesture gesture2 = await tester.startGesture(tester.getCenter(find.byKey(innerKey)), pointer: 2);
    await tester.pump(const Duration(milliseconds: 200));
    expect(material, paintsExactlyCountTimes(#drawCircle, 1));
    await gesture2.up();
  });

  testWidgets('Reparenting parent should allow both inkwells to show splash afterwards', (WidgetTester tester) async {
    final GlobalKey middleKey = GlobalKey();
    final GlobalKey innerKey = GlobalKey();
    Widget paddedInkWell({Key key, Widget child}) {
      return InkWell(
        key: key,
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(50),
          child: child,
        ),
      );
    }

    await tester.pumpWidget(
      Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: 200,
              height: 100,
              child: Row(
                children: <Widget>[
                  paddedInkWell(
                    key: middleKey,
                    child: paddedInkWell(
                      key: innerKey,
                    ),
                  ),
                  Container(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final MaterialInkController material = Material.of(tester.element(find.byKey(innerKey)));

    // Press
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byKey(innerKey)), pointer: 1);
    await tester.pump(const Duration(milliseconds: 200));
    expect(material, paintsExactlyCountTimes(#drawCircle, 1));

    // Reparent parent
    await tester.pumpWidget(
      Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: 200,
              height: 100,
              child: Row(
                children: <Widget>[
                  paddedInkWell(
                    key: innerKey,
                  ),
                  paddedInkWell(
                    key: middleKey,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Up
    await gesture.up();
    await tester.pumpAndSettle();
    expect(material, paintsNothing);

    // Press the previous parent
    await gesture.down(tester.getCenter(find.byKey(middleKey)));
    await tester.pump(const Duration(milliseconds: 200));
    expect(material, paintsExactlyCountTimes(#drawCircle, 1));

    // Use a second pointer to press the previous child
    await tester.startGesture(tester.getCenter(find.byKey(innerKey)), pointer: 2);
    await tester.pump(const Duration(milliseconds: 200));
    expect(material, paintsExactlyCountTimes(#drawCircle, 2));
  });

  testWidgets('Parent inkwell does not block child inkwells from splashes', (WidgetTester tester) async {
    final GlobalKey middleKey = GlobalKey();
    final GlobalKey innerKey = GlobalKey();
    Widget paddedInkWell({Key key, Widget child}) {
      return InkWell(
        key: key,
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(50),
          child: child,
        ),
      );
    }

    await tester.pumpWidget(
      Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: paddedInkWell(
              child: paddedInkWell(
                key: middleKey,
                child: paddedInkWell(
                  key: innerKey,
                  child: Container(width: 50, height: 50),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final MaterialInkController material = Material.of(tester.element(find.byKey(innerKey)));

    // Press middle
    await tester.startGesture(tester.getTopLeft(find.byKey(middleKey)) + const Offset(1, 1), pointer: 1);
    await tester.pump(const Duration(milliseconds: 200));
    expect(material, paintsExactlyCountTimes(#drawCircle, 1));

    // Press inner
    await tester.startGesture(tester.getCenter(find.byKey(innerKey)), pointer: 2);
    await tester.pump(const Duration(milliseconds: 200));
    expect(material, paintsExactlyCountTimes(#drawCircle, 2));
  });

  testWidgets('Parent inkwell can count the number of pressed children to prevent splash', (WidgetTester tester) async {
    final GlobalKey parentKey = GlobalKey();
    final GlobalKey leftKey = GlobalKey();
    final GlobalKey rightKey = GlobalKey();
    await tester.pumpWidget(
      Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: Container(
              width: 100,
              height: 100,
              child: InkWell(
                key: parentKey,
                onTap: () {},
                child: Center(
                  child: Container(
                    width: 100,
                    height: 50,
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 50,
                          height: 50,
                          child: InkWell(
                            key: leftKey,
                            onTap: () {},
                          ),
                        ),
                        Container(
                          width: 50,
                          height: 50,
                          child: InkWell(
                            key: rightKey,
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final MaterialInkController material = Material.of(tester.element(find.byKey(leftKey)));

    final Offset parentPosition = tester.getTopLeft(find.byKey(parentKey)) + const Offset(1, 1);

    // Press left child
    final TestGesture gesture1 = await tester.startGesture(tester.getCenter(find.byKey(leftKey)), pointer: 1);
    await tester.pump(const Duration(milliseconds: 200));
    expect(material, paintsExactlyCountTimes(#drawCircle, 1));

    // Press right child
    final TestGesture gesture2 = await tester.startGesture(tester.getCenter(find.byKey(rightKey)), pointer: 2);
    await tester.pump(const Duration(milliseconds: 200));
    expect(material, paintsExactlyCountTimes(#drawCircle, 2));

    // Press parent
    final TestGesture gesture3 = await tester.startGesture(parentPosition, pointer: 3);
    await tester.pump(const Duration(milliseconds: 200));
    expect(material, paintsExactlyCountTimes(#drawCircle, 2));
    await gesture3.up();

    // Release left child
    await gesture1.up();
    await tester.pumpAndSettle();
    expect(material, paintsExactlyCountTimes(#drawCircle, 1));

    // Press parent
    await gesture3.down(parentPosition);
    await tester.pump(const Duration(milliseconds: 200));
    expect(material, paintsExactlyCountTimes(#drawCircle, 1));
    await gesture3.up();

    // Release right child
    await gesture2.up();
    await tester.pumpAndSettle();
    expect(material, paintsExactlyCountTimes(#drawCircle, 0));

    // Press parent
    await gesture3.down(parentPosition);
    await tester.pump(const Duration(milliseconds: 200));
    expect(material, paintsExactlyCountTimes(#drawCircle, 1));
    await gesture3.up();
  });

  testWidgets('When ink wells are reparented, the old parent can display splash while the new parent can not', (WidgetTester tester) async {
    final GlobalKey innerKey = GlobalKey();
    final GlobalKey leftKey = GlobalKey();
    final GlobalKey rightKey = GlobalKey();

    Widget doubleInkWellRow({
      double leftWidth,
      double rightWidth,
      Widget leftChild,
      Widget rightChild,
    }) {
      return Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: leftWidth+rightWidth,
              height: 100,
              child: Row(
                children: <Widget>[
                  Container(
                    width: leftWidth,
                    height: 100,
                    child: InkWell(
                      key: leftKey,
                      onTap: () {},
                      child: Center(
                        child: Container(
                          width: leftWidth,
                          height: 50,
                          child: leftChild,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: rightWidth,
                    height: 100,
                    child: InkWell(
                      key: rightKey,
                      onTap: () {},
                      child: Center(
                        child: Container(
                          width: leftWidth,
                          height: 50,
                          child: rightChild,
                        ),
                      ),
                    )
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(
      doubleInkWellRow(
        leftWidth: 110,
        rightWidth: 90,
        leftChild: InkWell(
          key: innerKey,
          onTap: () {},
        ),
      ),
    );
    final MaterialInkController material = Material.of(tester.element(find.byKey(innerKey)));

    // Press inner
    final TestGesture gesture = await tester.startGesture(const Offset(100, 50), pointer: 1);
    await tester.pump(const Duration(milliseconds: 200));
    expect(material, paintsExactlyCountTimes(#drawCircle, 1));

    // Switch side
    await tester.pumpWidget(
      doubleInkWellRow(
        leftWidth: 90,
        rightWidth: 110,
        rightChild: InkWell(
          key: innerKey,
          onTap: () {},
        ),
      ),
    );
    expect(material, paintsExactlyCountTimes(#drawCircle, 0));

    // A second pointer presses inner
    final TestGesture gesture2 = await tester.startGesture(const Offset(100, 50), pointer: 2);
    await tester.pump(const Duration(milliseconds: 200));
    expect(material, paintsExactlyCountTimes(#drawCircle, 1));

    await gesture.up();
    await gesture2.up();
    await tester.pumpAndSettle();

    // Press inner
    await gesture.down(const Offset(100, 50));
    await tester.pump(const Duration(milliseconds: 200));
    expect(material, paintsExactlyCountTimes(#drawCircle, 1));

    // Press left
    await gesture2.down(const Offset(50, 50));
    await tester.pump(const Duration(milliseconds: 200));
    expect(material, paintsExactlyCountTimes(#drawCircle, 2));

    await gesture.up();
    await gesture2.up();
  });

  testWidgets("Ink wells's splash starts before tap is confirmed and disappear after tap is canceled", (WidgetTester tester) async {
    final GlobalKey innerKey = GlobalKey();
    await tester.pumpWidget(
      Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: GestureDetector(
            onHorizontalDragStart: (_) {},
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                child: InkWell(
                  onTap: () {},
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 50,
                      child: InkWell(
                        key: innerKey,
                        onTap: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final MaterialInkController material = Material.of(tester.element(find.byKey(innerKey)));

    // Press
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byKey(innerKey)), pointer: 1);
    await tester.pump(const Duration(milliseconds: 200));
    expect(material, paintsExactlyCountTimes(#drawCircle, 1));

    // Scroll upward
    await gesture.moveBy(const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(material, paintsNothing);

    // Up
    await gesture.up();
    await tester.pumpAndSettle();
    expect(material, paintsNothing);

    // Press again
    await gesture.down(tester.getCenter(find.byKey(innerKey)));
    await tester.pump(const Duration(milliseconds: 200));
    expect(material, paintsExactlyCountTimes(#drawCircle, 1));
  });
}
