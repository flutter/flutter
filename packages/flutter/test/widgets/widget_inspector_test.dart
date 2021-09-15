// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// no-shuffle:
//   //TODO(gspencergoog): Remove this tag once this test's state leaks/test
//   dependencies have been fixed.
//   https://github.com/flutter/flutter/issues/85160
//   Fails with "flutter test --test-randomize-ordering-seed=456"
// reduced-test-set:
//   This file is run as part of a reduced test set in CI on Mac and Windows
//   machines.
@Tags(<String>['reduced-test-set', 'no-shuffle'])

@TestOn('!chrome')

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_inspector_test_utils.dart';

// Start of block of code where widget creation location line numbers and
// columns will impact whether tests pass.

class ClockDemo extends StatefulWidget {
  const ClockDemo({ Key? key }) : super(key: key);
  @override
  State<ClockDemo> createState() => _ClockDemoState();
}

class _ClockDemoState extends State<ClockDemo> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text('World Clock'),
          makeClock('Local', DateTime.now().timeZoneOffset.inHours),
          makeClock('UTC', 0),
          makeClock('New York, NY', -4),
          makeClock('Chicago, IL', -5),
          makeClock('Denver, CO', -6),
          makeClock('Los Angeles, CA', -7),
        ],
      ),
    );
  }

  Widget makeClock(String label, int utcOffset) {
    return Stack(
      children: <Widget>[
        const Icon(Icons.watch),
        Text(label),
        ClockText(utcOffset: utcOffset),
      ],
    );
  }
}

class ClockText extends StatefulWidget {
  const ClockText({
    Key? key,
    this.utcOffset = 0,
  }) : super(key: key);

  final int utcOffset;

  @override
  State<ClockText> createState() => _ClockTextState();
}

class _ClockTextState extends State<ClockText> {
  DateTime? currentTime = DateTime.now();

  void updateTime() {
    setState(() {
      currentTime = DateTime.now();
    });
  }

  void stopClock() {
    setState(() {
      currentTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (currentTime == null) {
      return const Text('stopped');
    }
    return Text(
      currentTime!
          .toUtc()
          .add(Duration(hours: widget.utcOffset))
          .toIso8601String(),
    );
  }
}

// End of block of code where widget creation location line numbers and
// columns will impact whether tests pass.

// Class to enable building trees of nodes with cycles between properties of
// nodes and the properties of those properties.
// This exposed a bug in code serializing DiagnosticsNode objects that did not
// handle these sorts of cycles robustly.
class CyclicDiagnostic extends DiagnosticableTree {
  CyclicDiagnostic(this.name);

  // Field used to create cyclic relationships.
  CyclicDiagnostic? related;
  final List<DiagnosticsNode> children = <DiagnosticsNode>[];

  final String name;

  @override
  String toStringShort() => '${objectRuntimeType(this, 'CyclicDiagnostic')}-$name';

  // We have to override toString to avoid the toString call itself triggering a
  // stack overflow.
  @override
  String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return toStringShort();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CyclicDiagnostic>('related', related));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() => children;
}

class _CreationLocation {
  _CreationLocation({
    required this.id,
    required this.file,
    required this.line,
    required this.column,
    required this.name,
  });

  final int id;
  final String file;
  final int line;
  final int column;
  String? name;
}

typedef InspectorServiceExtensionCallback = FutureOr<Map<String, Object>> Function(Map<String, String> parameters);

class RenderRepaintBoundaryWithDebugPaint extends RenderRepaintBoundary {
  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    super.debugPaintSize(context, offset);
    assert(() {
      // Draw some debug paint UI interleaving creating layers and drawing
      // directly to the context's canvas.
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.red;
      {
        final PictureLayer pictureLayer = PictureLayer(Offset.zero & size);
        final ui.PictureRecorder recorder = ui.PictureRecorder();
        final Canvas pictureCanvas = Canvas(recorder);
        pictureCanvas.drawCircle(Offset.zero, 20.0, paint);
        pictureLayer.picture = recorder.endRecording();
        context.addLayer(
          OffsetLayer()
            ..offset = offset
            ..append(pictureLayer),
        );
      }
      context.canvas.drawLine(
        offset,
        offset.translate(size.width, size.height),
        paint,
      );
      {
        final PictureLayer pictureLayer = PictureLayer(Offset.zero & size);
        final ui.PictureRecorder recorder = ui.PictureRecorder();
        final Canvas pictureCanvas = Canvas(recorder);
        pictureCanvas.drawCircle(const Offset(20.0, 20.0), 20.0, paint);
        pictureLayer.picture = recorder.endRecording();
        context.addLayer(
          OffsetLayer()
            ..offset = offset
            ..append(pictureLayer),
        );
      }
      paint.color = Colors.blue;
      context.canvas.drawLine(
        offset,
        offset.translate(size.width * 0.5, size.height * 0.5),
        paint,
      );
      return true;
    }());
  }
}

class RepaintBoundaryWithDebugPaint extends RepaintBoundary {
  /// Creates a widget that isolates repaints.
  const RepaintBoundaryWithDebugPaint({
    Key? key,
    Widget? child,
  }) : super(key: key, child: child);

  @override
  RenderRepaintBoundary createRenderObject(BuildContext context) {
    return RenderRepaintBoundaryWithDebugPaint();
  }
}

int getChildLayerCount(OffsetLayer layer) {
  Layer? child = layer.firstChild;
  int count = 0;
  while (child != null) {
    count++;
    child = child.nextSibling;
  }
  return count;
}

void main() {
  _TestWidgetInspectorService.runTests();
}

class _TestWidgetInspectorService extends TestWidgetInspectorService {
  // These tests need access to protected members of WidgetInspectorService.
  static void runTests() {
    final TestWidgetInspectorService service = TestWidgetInspectorService();
    WidgetInspectorService.instance = service;

    tearDown(() {
      service.resetAllState();
    });

    testWidgets('WidgetInspector smoke test', (WidgetTester tester) async {
      // This is a smoke test to verify that adding the inspector doesn't crash.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: const <Widget>[
              Text('a', textDirection: TextDirection.ltr),
              Text('b', textDirection: TextDirection.ltr),
              Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: WidgetInspector(
            selectButtonBuilder: null,
            child: Stack(
              children: const <Widget>[
                Text('a', textDirection: TextDirection.ltr),
                Text('b', textDirection: TextDirection.ltr),
                Text('c', textDirection: TextDirection.ltr),
              ],
            ),
          ),
        ),
      );

      expect(true, isTrue); // Expect that we reach here without crashing.
    });

    testWidgets('WidgetInspector interaction test', (WidgetTester tester) async {
      final List<String> log = <String>[];
      final GlobalKey selectButtonKey = GlobalKey();
      final GlobalKey inspectorKey = GlobalKey();
      final GlobalKey topButtonKey = GlobalKey();

      Widget selectButtonBuilder(BuildContext context, VoidCallback onPressed) {
        return Material(child: ElevatedButton(onPressed: onPressed, key: selectButtonKey, child: null));
      }
      // State type is private, hence using dynamic.
      dynamic getInspectorState() => inspectorKey.currentState;
      String paragraphText(RenderParagraph paragraph) {
        final TextSpan textSpan = paragraph.text as TextSpan;
        return textSpan.text!;
      }

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: WidgetInspector(
            key: inspectorKey,
            selectButtonBuilder: selectButtonBuilder,
            child: Material(
              child: ListView(
                children: <Widget>[
                  ElevatedButton(
                    key: topButtonKey,
                    onPressed: () {
                      log.add('top');
                    },
                    child: const Text('TOP'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      log.add('bottom');
                    },
                    child: const Text('BOTTOM'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(getInspectorState().selection.current, isNull); // ignore: avoid_dynamic_calls
      await tester.tap(find.text('TOP'), warnIfMissed: false);
      await tester.pump();
      // Tap intercepted by the inspector
      expect(log, equals(<String>[]));
      // ignore: avoid_dynamic_calls
      final InspectorSelection selection = getInspectorState().selection as InspectorSelection;
      expect(paragraphText(selection.current! as RenderParagraph), equals('TOP'));
      final RenderObject topButton = find.byKey(topButtonKey).evaluate().first.renderObject!;
      expect(selection.candidates, contains(topButton));

      await tester.tap(find.text('TOP'));
      expect(log, equals(<String>['top']));
      log.clear();

      await tester.tap(find.text('BOTTOM'));
      expect(log, equals(<String>['bottom']));
      log.clear();
      // Ensure the inspector selection has not changed to bottom.
      // ignore: avoid_dynamic_calls
      expect(paragraphText(getInspectorState().selection.current as RenderParagraph), equals('TOP'));

      await tester.tap(find.byKey(selectButtonKey));
      await tester.pump();

      // We are now back in select mode so tapping the bottom button will have
      // not trigger a click but will cause it to be selected.
      await tester.tap(find.text('BOTTOM'), warnIfMissed: false);
      expect(log, equals(<String>[]));
      log.clear();
      // ignore: avoid_dynamic_calls
      expect(paragraphText(getInspectorState().selection.current as RenderParagraph), equals('BOTTOM'));
    });

    testWidgets('WidgetInspector non-invertible transform regression test', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: WidgetInspector(
            selectButtonBuilder: null,
            child: Transform(
              transform: Matrix4.identity()..scale(0.0),
              child: Stack(
                children: const <Widget>[
                  Text('a', textDirection: TextDirection.ltr),
                  Text('b', textDirection: TextDirection.ltr),
                  Text('c', textDirection: TextDirection.ltr),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Transform), warnIfMissed: false);

      expect(true, isTrue); // Expect that we reach here without crashing.
    });

    testWidgets('WidgetInspector scroll test', (WidgetTester tester) async {
      final Key childKey = UniqueKey();
      final GlobalKey selectButtonKey = GlobalKey();
      final GlobalKey inspectorKey = GlobalKey();

      Widget selectButtonBuilder(BuildContext context, VoidCallback onPressed) {
        return Material(child: ElevatedButton(onPressed: onPressed, key: selectButtonKey, child: null));
      }
      // State type is private, hence using dynamic.
      dynamic getInspectorState() => inspectorKey.currentState;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: WidgetInspector(
            key: inspectorKey,
            selectButtonBuilder: selectButtonBuilder,
            child: ListView(
              dragStartBehavior: DragStartBehavior.down,
              children: <Widget>[
                Container(
                  key: childKey,
                  height: 5000.0,
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.getTopLeft(find.byKey(childKey)).dy, equals(0.0));

      await tester.fling(find.byType(ListView), const Offset(0.0, -200.0), 200.0, warnIfMissed: false);
      await tester.pump();

      // Fling does nothing as are in inspect mode.
      expect(tester.getTopLeft(find.byKey(childKey)).dy, equals(0.0));

      await tester.fling(find.byType(ListView), const Offset(200.0, 0.0), 200.0, warnIfMissed: false);
      await tester.pump();

      // Fling still does nothing as are in inspect mode.
      expect(tester.getTopLeft(find.byKey(childKey)).dy, equals(0.0));

      await tester.tap(find.byType(ListView), warnIfMissed: false);
      await tester.pump();
      expect(getInspectorState().selection.current, isNotNull); // ignore: avoid_dynamic_calls

      // Now out of inspect mode due to the click.
      await tester.fling(find.byType(ListView), const Offset(0.0, -200.0), 200.0);
      await tester.pump();

      expect(tester.getTopLeft(find.byKey(childKey)).dy, equals(-200.0));

      await tester.fling(find.byType(ListView), const Offset(0.0, 200.0), 200.0);
      await tester.pump();

      expect(tester.getTopLeft(find.byKey(childKey)).dy, equals(0.0));
    });

    testWidgets('WidgetInspector long press', (WidgetTester tester) async {
      bool didLongPress = false;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: WidgetInspector(
            selectButtonBuilder: null,
            child: GestureDetector(
              onLongPress: () {
                expect(didLongPress, isFalse);
                didLongPress = true;
              },
              child: const Text('target', textDirection: TextDirection.ltr),
            ),
          ),
        ),
      );

      await tester.longPress(find.text('target'), warnIfMissed: false);
      // The inspector will swallow the long press.
      expect(didLongPress, isFalse);
    });

    testWidgets('WidgetInspector offstage', (WidgetTester tester) async {
      final GlobalKey inspectorKey = GlobalKey();
      final GlobalKey clickTarget = GlobalKey();

      Widget createSubtree({ double? width, Key? key }) {
        return Stack(
          children: <Widget>[
            Positioned(
              key: key,
              left: 0.0,
              top: 0.0,
              width: width,
              height: 100.0,
              child: Text(width.toString(), textDirection: TextDirection.ltr),
            ),
          ],
        );
      }
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: WidgetInspector(
            key: inspectorKey,
            selectButtonBuilder: null,
            child: Overlay(
              initialEntries: <OverlayEntry>[
                OverlayEntry(
                  opaque: false,
                  maintainState: true,
                  builder: (BuildContext _) => createSubtree(width: 94.0),
                ),
                OverlayEntry(
                  opaque: true,
                  maintainState: true,
                  builder: (BuildContext _) => createSubtree(width: 95.0),
                ),
                OverlayEntry(
                  opaque: false,
                  maintainState: true,
                  builder: (BuildContext _) => createSubtree(width: 96.0, key: clickTarget),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.longPress(find.byKey(clickTarget), warnIfMissed: false);
      // State type is private, hence using dynamic.
      final dynamic inspectorState = inspectorKey.currentState;
      // The object with width 95.0 wins over the object with width 94.0 because
      // the subtree with width 94.0 is offstage.
      // ignore: avoid_dynamic_calls
      expect(inspectorState.selection.current.semanticBounds.width, equals(95.0));

      // Exactly 2 out of the 3 text elements should be in the candidate list of
      // objects to select as only 2 are onstage.
      // ignore: avoid_dynamic_calls
      expect(inspectorState.selection.candidates.where((RenderObject object) => object is RenderParagraph).length, equals(2));
    });

    testWidgets('WidgetInspector with Transform above', (WidgetTester tester) async {
      final GlobalKey childKey = GlobalKey();
      final GlobalKey repaintBoundaryKey = GlobalKey();

      final Matrix4 mainTransform = Matrix4.identity()
          ..translate(50.0, 30.0)
          ..scale(0.8, 0.8)
          ..translate(100.0, 50.0);

      await tester.pumpWidget(
        RepaintBoundary(
          key: repaintBoundaryKey,
          child: Container(
            color: Colors.grey,
            child: Transform(
              transform: mainTransform,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: WidgetInspector(
                  selectButtonBuilder: null,
                  child: Container(
                    color: Colors.white,
                    child: Center(
                      child: Container(
                        key: childKey,
                        height: 100.0,
                        width: 50.0,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(childKey), warnIfMissed: false);
      await tester.pump();

      await expectLater(
        find.byKey(repaintBoundaryKey),
        matchesGoldenFile('inspector.overlay_positioning_with_transform.png'),
      );
    });

    testWidgets('Multiple widget inspectors', (WidgetTester tester) async {
      // This test verifies that interacting with different inspectors
      // works correctly. This use case may be an app that displays multiple
      // apps inside (i.e. a storyboard).
      final GlobalKey selectButton1Key = GlobalKey();
      final GlobalKey selectButton2Key = GlobalKey();

      final GlobalKey inspector1Key = GlobalKey();
      final GlobalKey inspector2Key = GlobalKey();

      final GlobalKey child1Key = GlobalKey();
      final GlobalKey child2Key = GlobalKey();

      InspectorSelectButtonBuilder selectButtonBuilder(Key key) {
        return (BuildContext context, VoidCallback onPressed) {
          return Material(child: ElevatedButton(onPressed: onPressed, key: key, child: null));
        };
      }

      // State type is private, hence using dynamic.
      // The inspector state is static, so it's enough with reading one of them.
      dynamic getInspectorState() => inspector1Key.currentState;
      String paragraphText(RenderParagraph paragraph) {
        final TextSpan textSpan = paragraph.text as TextSpan;
        return textSpan.text!;
      }

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: <Widget>[
              Flexible(
                child: WidgetInspector(
                  key: inspector1Key,
                  selectButtonBuilder: selectButtonBuilder(selectButton1Key),
                  child: Container(
                    key: child1Key,
                    child: const Text('Child 1'),
                  ),
                ),
              ),
              Flexible(
                child: WidgetInspector(
                  key: inspector2Key,
                  selectButtonBuilder: selectButtonBuilder(selectButton2Key),
                  child: Container(
                    key: child2Key,
                    child: const Text('Child 2'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      // ignore: avoid_dynamic_calls
      final InspectorSelection selection = getInspectorState().selection as InspectorSelection;
      // The selection is static, so it may be initialized from previous tests.
      selection.clear();

      await tester.tap(find.text('Child 1'), warnIfMissed: false);
      await tester.pump();
      expect(paragraphText(selection.current! as RenderParagraph), equals('Child 1'));

      await tester.tap(find.text('Child 2'), warnIfMissed: false);
      await tester.pump();
      expect(paragraphText(selection.current! as RenderParagraph), equals('Child 2'));
    });

    test('WidgetInspectorService null id', () {
      service.disposeAllGroups();
      expect(service.toObject(null), isNull);
      expect(service.toId(null, 'test-group'), isNull);
    });

    test('WidgetInspectorService dispose group', () {
      service.disposeAllGroups();
      final Object a = Object();
      const String group1 = 'group-1';
      const String group2 = 'group-2';
      const String group3 = 'group-3';
      final String? aId = service.toId(a, group1);
      expect(service.toId(a, group2), equals(aId));
      expect(service.toId(a, group3), equals(aId));
      service.disposeGroup(group1);
      service.disposeGroup(group2);
      expect(service.toObject(aId), equals(a));
      service.disposeGroup(group3);
      expect(() => service.toObject(aId), throwsFlutterError);
    });

    test('WidgetInspectorService dispose id', () {
      service.disposeAllGroups();
      final Object a = Object();
      final Object b = Object();
      const String group1 = 'group-1';
      const String group2 = 'group-2';
      final String? aId = service.toId(a, group1);
      final String? bId = service.toId(b, group1);
      expect(service.toId(a, group2), equals(aId));
      service.disposeId(bId, group1);
      expect(() => service.toObject(bId), throwsFlutterError);
      service.disposeId(aId, group1);
      expect(service.toObject(aId), equals(a));
      service.disposeId(aId, group2);
      expect(() => service.toObject(aId), throwsFlutterError);
    });

    test('WidgetInspectorService toObjectForSourceLocation', () {
      const String group = 'test-group';
      const Text widget = Text('a', textDirection: TextDirection.ltr);
      service.disposeAllGroups();
      final String id = service.toId(widget, group)!;
      expect(service.toObjectForSourceLocation(id), equals(widget));
      final Element element = widget.createElement();
      final String elementId = service.toId(element, group)!;
      expect(service.toObjectForSourceLocation(elementId), equals(widget));
      expect(element, isNot(equals(widget)));
      service.disposeGroup(group);
      expect(() => service.toObjectForSourceLocation(elementId), throwsFlutterError);
    });

    test('WidgetInspectorService object id test', () {
      const Text a = Text('a', textDirection: TextDirection.ltr);
      const Text b = Text('b', textDirection: TextDirection.ltr);
      const Text c = Text('c', textDirection: TextDirection.ltr);
      const Text d = Text('d', textDirection: TextDirection.ltr);

      const String group1 = 'group-1';
      const String group2 = 'group-2';
      const String group3 = 'group-3';
      service.disposeAllGroups();

      final String? aId = service.toId(a, group1);
      final String? bId = service.toId(b, group2);
      final String? cId = service.toId(c, group3);
      final String? dId = service.toId(d, group1);
      // Make sure we get a consistent id if we add the object to a group multiple
      // times.
      expect(aId, equals(service.toId(a, group1)));
      expect(service.toObject(aId), equals(a));
      expect(service.toObject(aId), isNot(equals(b)));
      expect(service.toObject(bId), equals(b));
      expect(service.toObject(cId), equals(c));
      expect(service.toObject(dId), equals(d));
      // Make sure we get a consistent id even if we add the object to a different
      // group.
      expect(aId, equals(service.toId(a, group3)));
      expect(aId, isNot(equals(bId)));
      expect(aId, isNot(equals(cId)));

      service.disposeGroup(group3);
    });

    testWidgets('WidgetInspectorService maybeSetSelection', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: const <Widget>[
              Text('a', textDirection: TextDirection.ltr),
              Text('b', textDirection: TextDirection.ltr),
              Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final Element elementA = find.text('a').evaluate().first;
      final Element elementB = find.text('b').evaluate().first;

      service.disposeAllGroups();
      service.selection.clear();
      int selectionChangedCount = 0;
      service.selectionChangedCallback = () => selectionChangedCount++;
      service.setSelection('invalid selection');
      expect(selectionChangedCount, equals(0));
      expect(service.selection.currentElement, isNull);
      service.setSelection(elementA);
      expect(selectionChangedCount, equals(1));
      expect(service.selection.currentElement, equals(elementA));
      expect(service.selection.current, equals(elementA.renderObject));

      service.setSelection(elementB.renderObject);
      expect(selectionChangedCount, equals(2));
      expect(service.selection.current, equals(elementB.renderObject));
      expect(service.selection.currentElement, equals((elementB.renderObject!.debugCreator! as DebugCreator).element));

      service.setSelection('invalid selection');
      expect(selectionChangedCount, equals(2));
      expect(service.selection.current, equals(elementB.renderObject));

      service.setSelectionById(service.toId(elementA, 'my-group'));
      expect(selectionChangedCount, equals(3));
      expect(service.selection.currentElement, equals(elementA));
      expect(service.selection.current, equals(elementA.renderObject));

      service.setSelectionById(service.toId(elementA, 'my-group'));
      expect(selectionChangedCount, equals(3));
      expect(service.selection.currentElement, equals(elementA));
    });

    testWidgets('WidgetInspectorService defunct selection regression test', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: const <Widget>[
              Text('a', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final Element elementA = find.text('a').evaluate().first;

      service.setSelection(elementA);
      expect(service.selection.currentElement, equals(elementA));
      expect(service.selection.current, equals(elementA.renderObject));

      await tester.pumpWidget(
        const SizedBox(
          child: Text('b', textDirection: TextDirection.ltr),
        ),
      );
      // Selection is now empty as the element is defunct.
      expect(service.selection.currentElement, equals(null));
      expect(service.selection.current, equals(null));

      // Verify that getting the debug creation location of the defunct element
      // does not crash.
      expect(debugIsLocalCreationLocation(elementA), isFalse);

      // Verify that generating json for a defunct element does not crash.
      expect(
        elementA.toDiagnosticsNode().toJsonMap(
          InspectorSerializationDelegate(
            service: service,
            summaryTree: false,
            includeProperties: true,
            addAdditionalPropertiesCallback: null,
          ),
        ),
        isNotNull,
      );

      final Element elementB = find.text('b').evaluate().first;
      service.setSelection(elementB);
      expect(service.selection.currentElement, equals(elementB));
      expect(service.selection.current, equals(elementB.renderObject));

      // Set selection back to a defunct element.
      service.setSelection(elementA);

      expect(service.selection.currentElement, equals(null));
      expect(service.selection.current, equals(null));
    });

    testWidgets('WidgetInspectorService getParentChain', (WidgetTester tester) async {
      const String group = 'test-group';

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: const <Widget>[
              Text('a', textDirection: TextDirection.ltr),
              Text('b', textDirection: TextDirection.ltr),
              Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );

      service.disposeAllGroups();
      final Element elementB = find.text('b').evaluate().first;
      final String bId = service.toId(elementB, group)!;
      final Object? jsonList = json.decode(service.getParentChain(bId, group));
      expect(jsonList, isList);
      final List<Object?> chainElements = jsonList! as List<Object?>;
      final List<Element> expectedChain = elementB.debugGetDiagnosticChain().reversed.toList();
      // Sanity check that the chain goes back to the root.
      expect(expectedChain.first, tester.binding.renderViewElement);

      expect(chainElements.length, equals(expectedChain.length));
      for (int i = 0; i < expectedChain.length; i += 1) {
        expect(chainElements[i], isMap);
        final Map<String, Object?> chainNode = chainElements[i]! as Map<String, Object?>;
        final Element element = expectedChain[i];
        expect(chainNode['node'], isMap);
        final Map<String, Object?> jsonNode = chainNode['node']! as Map<String, Object?>;
        expect(service.toObject(jsonNode['valueId']! as String), equals(element));
        expect(service.toObject(jsonNode['objectId']! as String), isA<DiagnosticsNode>());

        expect(chainNode['children'], isList);
        final List<Object?> jsonChildren = chainNode['children']! as List<Object?>;
        final List<Element> childrenElements = <Element>[];
        element.visitChildren(childrenElements.add);
        expect(jsonChildren.length, equals(childrenElements.length));
        if (i + 1 == expectedChain.length) {
          expect(chainNode['childIndex'], isNull);
        } else {
          expect(chainNode['childIndex'], equals(childrenElements.indexOf(expectedChain[i+1])));
        }
        for (int j = 0; j < childrenElements.length; j += 1) {
          expect(jsonChildren[j], isMap);
          final Map<String, Object?> childJson = jsonChildren[j]! as Map<String, Object?>;
          expect(service.toObject(childJson['valueId']! as String), equals(childrenElements[j]));
          expect(service.toObject(childJson['objectId']! as String), isA<DiagnosticsNode>());
        }
      }
    });

    test('WidgetInspectorService getProperties', () {
      final DiagnosticsNode diagnostic = const Text('a', textDirection: TextDirection.ltr).toDiagnosticsNode();
      const String group = 'group';
      service.disposeAllGroups();
      final String id = service.toId(diagnostic, group)!;
      final List<Object?> propertiesJson = json.decode(service.getProperties(id, group)) as List<Object?>;
      final List<DiagnosticsNode> properties = diagnostic.getProperties();
      expect(properties, isNotEmpty);
      expect(propertiesJson.length, equals(properties.length));
      for (int i = 0; i < propertiesJson.length; ++i) {
        final Map<String, Object?> propertyJson = propertiesJson[i]! as Map<String, Object?>;
        expect(service.toObject(propertyJson['valueId'] as String?), equals(properties[i].value));
        expect(service.toObject(propertyJson['objectId']! as String), isA<DiagnosticsNode>());
      }
    });

    testWidgets('WidgetInspectorService getChildren', (WidgetTester tester) async {
      const String group = 'test-group';

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: const <Widget>[
              Text('a', textDirection: TextDirection.ltr),
              Text('b', textDirection: TextDirection.ltr),
              Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final DiagnosticsNode diagnostic = find.byType(Stack).evaluate().first.toDiagnosticsNode();
      service.disposeAllGroups();
      final String id = service.toId(diagnostic, group)!;
      final List<Object?> propertiesJson = json.decode(service.getChildren(id, group)) as List<Object?>;
      final List<DiagnosticsNode> children = diagnostic.getChildren();
      expect(children.length, equals(3));
      expect(propertiesJson.length, equals(children.length));
      for (int i = 0; i < propertiesJson.length; ++i) {
        final Map<String, Object?> propertyJson = propertiesJson[i]! as Map<String, Object?>;
        expect(service.toObject(propertyJson['valueId']! as String), equals(children[i].value));
        expect(service.toObject(propertyJson['objectId']! as String), isA<DiagnosticsNode>());
      }
    });

    testWidgets('WidgetInspectorService creationLocation', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: const <Widget>[
              Text('a'),
              Text('b', textDirection: TextDirection.ltr),
              Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final Element elementA = find.text('a').evaluate().first;
      final Element elementB = find.text('b').evaluate().first;

      service.disposeAllGroups();
      service.setPubRootDirectories(<String>[]);
      service.setSelection(elementA, 'my-group');
      final Map<String, Object?> jsonA = json.decode(service.getSelectedWidget(null, 'my-group')) as Map<String, Object?>;
      final Map<String, Object?> creationLocationA = jsonA['creationLocation']! as Map<String, Object?>;
      expect(creationLocationA, isNotNull);
      final String fileA = creationLocationA['file']! as String;
      final int lineA = creationLocationA['line']! as int;
      final int columnA = creationLocationA['column']! as int;
      final String nameA = creationLocationA['name']! as String;
      expect(nameA, equals('Text'));

      service.setSelection(elementB, 'my-group');
      final Map<String, Object?> jsonB = json.decode(service.getSelectedWidget(null, 'my-group')) as Map<String, Object?>;
      final Map<String, Object?> creationLocationB = jsonB['creationLocation']! as Map<String, Object?>;
      expect(creationLocationB, isNotNull);
      final String fileB = creationLocationB['file']! as String;
      final int lineB = creationLocationB['line']! as int;
      final int columnB = creationLocationB['column']! as int;
      final String? nameB = creationLocationB['name'] as String?;
      expect(nameB, equals('Text'));
      expect(fileA, endsWith('widget_inspector_test.dart'));
      expect(fileA, equals(fileB));
      // We don't hardcode the actual lines the widgets are created on as that
      // would make this test fragile.
      expect(lineA + 1, equals(lineB));
      // Column numbers are more stable than line numbers.
      expect(columnA, equals(15));
      expect(columnA, equals(columnB));
    }, skip: !WidgetInspectorService.instance.isWidgetCreationTracked()); // [intended] Test requires --track-widget-creation flag.

    testWidgets('test transformDebugCreator will re-order if after stack trace', (WidgetTester tester) async {
      final bool widgetTracked = WidgetInspectorService.instance.isWidgetCreationTracked();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: const <Widget>[
              Text('a'),
              Text('b', textDirection: TextDirection.ltr),
              Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final Element elementA = find.text('a').evaluate().first;
      service.setSelection(elementA, 'my-group');
      late String pubRootTest;
      if (widgetTracked) {
        final Map<String, Object?> jsonObject = json.decode(
          service.getSelectedWidget(null, 'my-group'),
        ) as Map<String, Object?>;
        final Map<String, Object?> creationLocation = jsonObject['creationLocation']! as Map<String, Object?>;
        expect(creationLocation, isNotNull);
        final String fileA = creationLocation['file']! as String;
        expect(fileA, endsWith('widget_inspector_test.dart'));
        expect(jsonObject, isNot(contains('createdByLocalProject')));
        final List<String> segments = Uri
          .parse(fileA)
          .pathSegments;
        // Strip a couple subdirectories away to generate a plausible pub root
        // directory.
        pubRootTest = '/${segments.take(segments.length - 2).join('/')}';
        service.setPubRootDirectories(<String>[pubRootTest]);
      }
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      builder.add(StringProperty('dummy1', 'value'));
      builder.add(StringProperty('dummy2', 'value'));
      builder.add(DiagnosticsStackTrace('When the exception was thrown, this was the stack', null));
      builder.add(DiagnosticsDebugCreator(DebugCreator(elementA)));

      final List<DiagnosticsNode> nodes = List<DiagnosticsNode>.from(debugTransformDebugCreator(builder.properties));
      expect(nodes.length, 5);
      expect(nodes[0].runtimeType, StringProperty);
      expect(nodes[0].name, 'dummy1');
      expect(nodes[1].runtimeType, StringProperty);
      expect(nodes[1].name, 'dummy2');
      // transformed node should come in front of stack trace.
      if (widgetTracked) {
        expect(nodes[2].runtimeType, DiagnosticsBlock);
        final DiagnosticsBlock node = nodes[2] as DiagnosticsBlock;
        final List<DiagnosticsNode> children = node.getChildren();
        expect(children.length, 1);
        final ErrorDescription child = children[0] as ErrorDescription;
        expect(child.valueToString(), contains(Uri.parse(pubRootTest).path));
      } else {
        expect(nodes[2].runtimeType, ErrorDescription);
        final ErrorDescription node = nodes[2] as ErrorDescription;
        expect(node.valueToString().startsWith('Widget creation tracking is currently disabled.'), true);
      }
      expect(nodes[3].runtimeType, ErrorSpacer);
      expect(nodes[4].runtimeType, DiagnosticsStackTrace);
    });

    testWidgets('test transformDebugCreator will not re-order if before stack trace', (WidgetTester tester) async {
      final bool widgetTracked = WidgetInspectorService.instance.isWidgetCreationTracked();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: const <Widget>[
              Text('a'),
              Text('b', textDirection: TextDirection.ltr),
              Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final Element elementA = find.text('a').evaluate().first;
      late String pubRootTest;
      if (widgetTracked) {
        final Map<String, Object?> jsonObject = json.decode(
          service.getSelectedWidget(null, 'my-group'),
        ) as Map<String, Object?>;
        final Map<String, Object?> creationLocation = jsonObject['creationLocation']! as Map<String, Object?>;
        expect(creationLocation, isNotNull);
        final String fileA = creationLocation['file']! as String;
        expect(fileA, endsWith('widget_inspector_test.dart'));
        expect(jsonObject, isNot(contains('createdByLocalProject')));
        final List<String> segments = Uri
          .parse(fileA)
          .pathSegments;
        // Strip a couple subdirectories away to generate a plausible pub root
        // directory.
        pubRootTest = '/${segments.take(segments.length - 2).join('/')}';
        service.setPubRootDirectories(<String>[pubRootTest]);
      }
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      builder.add(StringProperty('dummy1', 'value'));
      builder.add(DiagnosticsDebugCreator(DebugCreator(elementA)));
      builder.add(StringProperty('dummy2', 'value'));
      builder.add(DiagnosticsStackTrace('When the exception was thrown, this was the stack', null));

      final List<DiagnosticsNode> nodes = List<DiagnosticsNode>.from(debugTransformDebugCreator(builder.properties));
      expect(nodes.length, 5);
      expect(nodes[0].runtimeType, StringProperty);
      expect(nodes[0].name, 'dummy1');
      // transformed node stays at original place.
      if (widgetTracked) {
        expect(nodes[1].runtimeType, DiagnosticsBlock);
        final DiagnosticsBlock node = nodes[1] as DiagnosticsBlock;
        final List<DiagnosticsNode> children = node.getChildren();
        expect(children.length, 1);
        final ErrorDescription child = children[0] as ErrorDescription;
        expect(child.valueToString(), contains(Uri.parse(pubRootTest).path));
      } else {
        expect(nodes[1].runtimeType, ErrorDescription);
        final ErrorDescription node = nodes[1] as ErrorDescription;
        expect(node.valueToString().startsWith('Widget creation tracking is currently disabled.'), true);
      }
      expect(nodes[2].runtimeType, ErrorSpacer);
      expect(nodes[3].runtimeType, StringProperty);
      expect(nodes[3].name, 'dummy2');
      expect(nodes[4].runtimeType, DiagnosticsStackTrace);
    }, skip: WidgetInspectorService.instance.isWidgetCreationTracked()); // [intended] Test requires --no-track-widget-creation flag.

    testWidgets('test transformDebugCreator will add DevToolsDeepLinkProperty for overflow errors', (WidgetTester tester) async {
      activeDevToolsServerAddress = 'http://127.0.0.1:9100';
      connectedVmServiceUri = 'http://127.0.0.1:55269/798ay5al_FM=/';

      setupDefaultPubRootDirectory(service);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: const <Widget>[
              Text('a'),
              Text('b', textDirection: TextDirection.ltr),
              Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final Element elementA = find.text('a').evaluate().first;

      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      builder.add(ErrorSummary('A RenderFlex overflowed by 273 pixels on the bottom'));
      builder.add(DiagnosticsDebugCreator(DebugCreator(elementA)));
      builder.add(StringProperty('dummy2', 'value'));

      final List<DiagnosticsNode> nodes = List<DiagnosticsNode>.from(debugTransformDebugCreator(builder.properties));
      expect(nodes.length, 6);
      expect(nodes[0].runtimeType, ErrorSummary);
      expect(nodes[1].runtimeType, DiagnosticsBlock);
      expect(nodes[2].runtimeType, ErrorSpacer);
      expect(nodes[3].runtimeType, DevToolsDeepLinkProperty);
      expect(nodes[4].runtimeType, ErrorSpacer);
      expect(nodes[5].runtimeType, StringProperty);
    }, skip: !WidgetInspectorService.instance.isWidgetCreationTracked()); // [intended] Test requires --track-widget-creation flag.

    testWidgets('test transformDebugCreator will not add DevToolsDeepLinkProperty for non-overflow errors', (WidgetTester tester) async {
      activeDevToolsServerAddress = 'http://127.0.0.1:9100';
      connectedVmServiceUri = 'http://127.0.0.1:55269/798ay5al_FM=/';
      setupDefaultPubRootDirectory(service);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: const <Widget>[
              Text('a'),
              Text('b', textDirection: TextDirection.ltr),
              Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final Element elementA = find.text('a').evaluate().first;

      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      builder.add(ErrorSummary('some other error'));
      builder.add(DiagnosticsDebugCreator(DebugCreator(elementA)));
      builder.add(StringProperty('dummy2', 'value'));

      final List<DiagnosticsNode> nodes = List<DiagnosticsNode>.from(debugTransformDebugCreator(builder.properties));
      expect(nodes.length, 4);
      expect(nodes[0].runtimeType, ErrorSummary);
      expect(nodes[1].runtimeType, DiagnosticsBlock);
      expect(nodes[2].runtimeType, ErrorSpacer);
      expect(nodes[3].runtimeType, StringProperty);
    }, skip: !WidgetInspectorService.instance.isWidgetCreationTracked());  // [intended] Test requires --track-widget-creation flag.

    testWidgets('test transformDebugCreator will not add DevToolsDeepLinkProperty if devtoolsServerAddress is unavailable', (WidgetTester tester) async {
      activeDevToolsServerAddress = null;
      connectedVmServiceUri = 'http://127.0.0.1:55269/798ay5al_FM=/';
      setupDefaultPubRootDirectory(service);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: const <Widget>[
              Text('a'),
              Text('b', textDirection: TextDirection.ltr),
              Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final Element elementA = find.text('a').evaluate().first;

      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      builder.add(ErrorSummary('A RenderFlex overflowed by 273 pixels on the bottom'));
      builder.add(DiagnosticsDebugCreator(DebugCreator(elementA)));
      builder.add(StringProperty('dummy2', 'value'));

      final List<DiagnosticsNode> nodes = List<DiagnosticsNode>.from(debugTransformDebugCreator(builder.properties));
      expect(nodes.length, 4);
      expect(nodes[0].runtimeType, ErrorSummary);
      expect(nodes[1].runtimeType, DiagnosticsBlock);
      expect(nodes[2].runtimeType, ErrorSpacer);
      expect(nodes[3].runtimeType, StringProperty);
    }, skip: !WidgetInspectorService.instance.isWidgetCreationTracked());  // [intended] Test requires --track-widget-creation flag.

    testWidgets('WidgetInspectorService setPubRootDirectories', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: const <Widget>[
              Text('a'),
              Text('b', textDirection: TextDirection.ltr),
              Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final Element elementA = find.text('a').evaluate().first;

      service.disposeAllGroups();
      service.setPubRootDirectories(<String>[]);
      service.setSelection(elementA, 'my-group');
      Map<String, Object?> jsonObject = json.decode(service.getSelectedWidget(null, 'my-group')) as Map<String, Object?>;
      Map<String, Object?> creationLocation = jsonObject['creationLocation']! as Map<String, Object?>;
      expect(creationLocation, isNotNull);
      final String fileA = creationLocation['file']! as String;
      expect(fileA, endsWith('widget_inspector_test.dart'));
      expect(jsonObject, isNot(contains('createdByLocalProject')));
      final List<String> segments = Uri.parse(fileA).pathSegments;
      // Strip a couple subdirectories away to generate a plausible pub root
      // directory.
      final String pubRootTest = '/${segments.take(segments.length - 2).join('/')}';
      service.setPubRootDirectories(<String>[pubRootTest]);

      service.setSelection(elementA, 'my-group');
      expect(json.decode(service.getSelectedWidget(null, 'my-group')), contains('createdByLocalProject'));

      service.setPubRootDirectories(<String>['/invalid/$pubRootTest']);
      expect(json.decode(service.getSelectedWidget(null, 'my-group')), isNot(contains('createdByLocalProject')));

      service.setPubRootDirectories(<String>['file://$pubRootTest']);
      expect(json.decode(service.getSelectedWidget(null, 'my-group')), contains('createdByLocalProject'));

      service.setPubRootDirectories(<String>['$pubRootTest/different']);
      expect(json.decode(service.getSelectedWidget(null, 'my-group')), isNot(contains('createdByLocalProject')));

      service.setPubRootDirectories(<String>[
        '/invalid/$pubRootTest',
        pubRootTest,
      ]);
      expect(json.decode(service.getSelectedWidget(null, 'my-group')), contains('createdByLocalProject'));

      // The RichText child of the Text widget is created by the core framework
      // not the current package.
      final Element richText = find.descendant(
        of: find.text('a'),
        matching: find.byType(RichText),
      ).evaluate().first;
      service.setSelection(richText, 'my-group');
      service.setPubRootDirectories(<String>[pubRootTest]);
      jsonObject = json.decode(service.getSelectedWidget(null, 'my-group')) as Map<String, Object?>;
      expect(jsonObject, isNot(contains('createdByLocalProject')));
      creationLocation = jsonObject['creationLocation']! as Map<String, Object?>;
      expect(creationLocation, isNotNull);
      // This RichText widget is created by the build method of the Text widget
      // thus the creation location is in text.dart not basic.dart
      final List<String> pathSegmentsFramework = Uri.parse(creationLocation['file']! as String).pathSegments;
      expect(pathSegmentsFramework.join('/'), endsWith('/flutter/lib/src/widgets/text.dart'));

      // Strip off /src/widgets/text.dart.
      final String pubRootFramework = '/${pathSegmentsFramework.take(pathSegmentsFramework.length - 3).join('/')}';
      service.setPubRootDirectories(<String>[pubRootFramework]);
      expect(json.decode(service.getSelectedWidget(null, 'my-group')), contains('createdByLocalProject'));
      service.setSelection(elementA, 'my-group');
      expect(json.decode(service.getSelectedWidget(null, 'my-group')), isNot(contains('createdByLocalProject')));

      service.setPubRootDirectories(<String>[pubRootFramework, pubRootTest]);
      service.setSelection(elementA, 'my-group');
      expect(json.decode(service.getSelectedWidget(null, 'my-group')), contains('createdByLocalProject'));
      service.setSelection(richText, 'my-group');
      expect(json.decode(service.getSelectedWidget(null, 'my-group')), contains('createdByLocalProject'));
    }, skip: !WidgetInspectorService.instance.isWidgetCreationTracked()); // [intended] Test requires --track-widget-creation flag.

    test('ext.flutter.inspector.disposeGroup', () async {
      final Object a = Object();
      const String group1 = 'group-1';
      const String group2 = 'group-2';
      const String group3 = 'group-3';
      final String? aId = service.toId(a, group1);
      expect(service.toId(a, group2), equals(aId));
      expect(service.toId(a, group3), equals(aId));
      await service.testExtension('disposeGroup', <String, String>{'objectGroup': group1});
      await service.testExtension('disposeGroup', <String, String>{'objectGroup': group2});
      expect(service.toObject(aId), equals(a));
      await service.testExtension('disposeGroup', <String, String>{'objectGroup': group3});
      expect(() => service.toObject(aId), throwsFlutterError);
    });

    test('ext.flutter.inspector.disposeId', () async {
      final Object a = Object();
      final Object b = Object();
      const String group1 = 'group-1';
      const String group2 = 'group-2';
      final String aId = service.toId(a, group1)!;
      final String bId = service.toId(b, group1)!;
      expect(service.toId(a, group2), equals(aId));
      await service.testExtension('disposeId', <String, String>{'arg': bId, 'objectGroup': group1});
      expect(() => service.toObject(bId), throwsFlutterError);
      await service.testExtension('disposeId', <String, String>{'arg': aId, 'objectGroup': group1});
      expect(service.toObject(aId), equals(a));
      await service.testExtension('disposeId', <String, String>{'arg': aId, 'objectGroup': group2});
      expect(() => service.toObject(aId), throwsFlutterError);
    });

    testWidgets('ext.flutter.inspector.setSelection', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: const <Widget>[
              Text('a', textDirection: TextDirection.ltr),
              Text('b', textDirection: TextDirection.ltr),
              Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final Element elementA = find.text('a').evaluate().first;
      final Element elementB = find.text('b').evaluate().first;

      service.disposeAllGroups();
      service.selection.clear();
      int selectionChangedCount = 0;
      service.selectionChangedCallback = () => selectionChangedCount++;
      service.setSelection('invalid selection');
      expect(selectionChangedCount, equals(0));
      expect(service.selection.currentElement, isNull);
      service.setSelection(elementA);
      expect(selectionChangedCount, equals(1));
      expect(service.selection.currentElement, equals(elementA));
      expect(service.selection.current, equals(elementA.renderObject));

      service.setSelection(elementB.renderObject);
      expect(selectionChangedCount, equals(2));
      expect(service.selection.current, equals(elementB.renderObject));
      expect(service.selection.currentElement, equals((elementB.renderObject!.debugCreator! as DebugCreator).element));

      service.setSelection('invalid selection');
      expect(selectionChangedCount, equals(2));
      expect(service.selection.current, equals(elementB.renderObject));

      await service.testExtension('setSelectionById', <String, String>{'arg': service.toId(elementA, 'my-group')!, 'objectGroup': 'my-group'});
      expect(selectionChangedCount, equals(3));
      expect(service.selection.currentElement, equals(elementA));
      expect(service.selection.current, equals(elementA.renderObject));

      service.setSelectionById(service.toId(elementA, 'my-group'));
      expect(selectionChangedCount, equals(3));
      expect(service.selection.currentElement, equals(elementA));
    });

    testWidgets('ext.flutter.inspector.getParentChain', (WidgetTester tester) async {
      const String group = 'test-group';

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: const <Widget>[
              Text('a', textDirection: TextDirection.ltr),
              Text('b', textDirection: TextDirection.ltr),
              Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );

      final Element elementB = find.text('b').evaluate().first;
      final String bId = service.toId(elementB, group)!;
      final Object? jsonList = await service.testExtension('getParentChain', <String, String>{'arg': bId, 'objectGroup': group});
      expect(jsonList, isList);
      final List<Object?> chainElements = jsonList! as List<Object?>;
      final List<Element> expectedChain = elementB.debugGetDiagnosticChain().reversed.toList();
      // Sanity check that the chain goes back to the root.
      expect(expectedChain.first, tester.binding.renderViewElement);

      expect(chainElements.length, equals(expectedChain.length));
      for (int i = 0; i < expectedChain.length; i += 1) {
        expect(chainElements[i], isMap);
        final Map<String, Object?> chainNode = chainElements[i]! as Map<String, Object?>;
        final Element element = expectedChain[i];
        expect(chainNode['node'], isMap);
        final Map<String, Object?> jsonNode = chainNode['node']! as Map<String, Object?>;
        expect(service.toObject(jsonNode['valueId']! as String), equals(element));
        expect(service.toObject(jsonNode['objectId']! as String), isA<DiagnosticsNode>());

        expect(chainNode['children'], isList);
        final List<Object?> jsonChildren = chainNode['children']! as List<Object?>;
        final List<Element> childrenElements = <Element>[];
        element.visitChildren(childrenElements.add);
        expect(jsonChildren.length, equals(childrenElements.length));
        if (i + 1 == expectedChain.length) {
          expect(chainNode['childIndex'], isNull);
        } else {
          expect(chainNode['childIndex'], equals(childrenElements.indexOf(expectedChain[i+1])));
        }
        for (int j = 0; j < childrenElements.length; j += 1) {
          expect(jsonChildren[j], isMap);
          final Map<String, Object?> childJson = jsonChildren[j]! as Map<String, Object?>;
          expect(service.toObject(childJson['valueId']! as String), equals(childrenElements[j]));
          expect(service.toObject(childJson['objectId']! as String), isA<DiagnosticsNode>());
        }
      }
    });

    test('ext.flutter.inspector.getProperties', () async {
      final DiagnosticsNode diagnostic = const Text('a', textDirection: TextDirection.ltr).toDiagnosticsNode();
      const String group = 'group';
      final String id = service.toId(diagnostic, group)!;
      final List<Object?> propertiesJson = (await service.testExtension('getProperties', <String, String>{'arg': id, 'objectGroup': group}))! as List<Object?>;
      final List<DiagnosticsNode> properties = diagnostic.getProperties();
      expect(properties, isNotEmpty);
      expect(propertiesJson.length, equals(properties.length));
      for (int i = 0; i < propertiesJson.length; ++i) {
        final Map<String, Object?> propertyJson = propertiesJson[i]! as Map<String, Object?>;
        expect(service.toObject(propertyJson['valueId'] as String?), equals(properties[i].value));
        expect(service.toObject(propertyJson['objectId']! as String), isA<DiagnosticsNode>());
      }
    });

    testWidgets('ext.flutter.inspector.getChildren', (WidgetTester tester) async {
      const String group = 'test-group';

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: const <Widget>[
              Text('a', textDirection: TextDirection.ltr),
              Text('b', textDirection: TextDirection.ltr),
              Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final DiagnosticsNode diagnostic = find.byType(Stack).evaluate().first.toDiagnosticsNode();
      final String id = service.toId(diagnostic, group)!;
      final List<Object?> propertiesJson = (await service.testExtension('getChildren', <String, String>{'arg': id, 'objectGroup': group}))! as List<Object?>;
      final List<DiagnosticsNode> children = diagnostic.getChildren();
      expect(children.length, equals(3));
      expect(propertiesJson.length, equals(children.length));
      for (int i = 0; i < propertiesJson.length; ++i) {
        final Map<String, Object?> propertyJson = propertiesJson[i]! as Map<String, Object?>;
        expect(service.toObject(propertyJson['valueId']! as String), equals(children[i].value));
        expect(service.toObject(propertyJson['objectId']! as String), isA<DiagnosticsNode>());
      }
    });

    testWidgets('ext.flutter.inspector.getChildrenDetailsSubtree', (WidgetTester tester) async {
      const String group = 'test-group';

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: const <Widget>[
              Text('a', textDirection: TextDirection.ltr),
              Text('b', textDirection: TextDirection.ltr),
              Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final DiagnosticsNode diagnostic = find.byType(Stack).evaluate().first.toDiagnosticsNode();
      final String id = service.toId(diagnostic, group)!;
      final List<Object?> childrenJson = (await service.testExtension('getChildrenDetailsSubtree', <String, String>{'arg': id, 'objectGroup': group}))! as List<Object?>;
      final List<DiagnosticsNode> children = diagnostic.getChildren();
      expect(children.length, equals(3));
      expect(childrenJson.length, equals(children.length));
      for (int i = 0; i < childrenJson.length; ++i) {
        final Map<String, Object?> childJson = childrenJson[i]! as Map<String, Object?>;
        expect(service.toObject(childJson['valueId']! as String), equals(children[i].value));
        expect(service.toObject(childJson['objectId']! as String), isA<DiagnosticsNode>());
        final List<Object?> propertiesJson = childJson['properties']! as List<Object?>;
        final DiagnosticsNode diagnosticsNode = service.toObject(childJson['objectId']! as String)! as DiagnosticsNode;
        final List<DiagnosticsNode> expectedProperties = diagnosticsNode.getProperties();
        for (final Map<String, Object?> propertyJson in propertiesJson.cast<Map<String, Object?>>()) {
          final Object? property = service.toObject(propertyJson['objectId']! as String);
          expect(property, isA<DiagnosticsNode>());
          expect(expectedProperties, contains(property));
        }
      }
    });

    testWidgets('WidgetInspectorService getDetailsSubtree', (WidgetTester tester) async {
      const String group = 'test-group';

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: const <Widget>[
              Text('a', textDirection: TextDirection.ltr),
              Text('b', textDirection: TextDirection.ltr),
              Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final DiagnosticsNode diagnostic = find.byType(Stack).evaluate().first.toDiagnosticsNode();
      final String id = service.toId(diagnostic, group)!;
      final Map<String, Object?> subtreeJson = (await service.testExtension('getDetailsSubtree', <String, String>{'arg': id, 'objectGroup': group}))! as Map<String, Object?>;
      expect(subtreeJson['objectId'], equals(id));
      final List<Object?> childrenJson = subtreeJson['children']! as List<Object?>;
      final List<DiagnosticsNode> children = diagnostic.getChildren();
      expect(children.length, equals(3));
      expect(childrenJson.length, equals(children.length));
      for (int i = 0; i < childrenJson.length; ++i) {
        final Map<String, Object?> childJson = childrenJson[i]! as Map<String, Object?>;
        expect(service.toObject(childJson['valueId']! as String), equals(children[i].value));
        expect(service.toObject(childJson['objectId']! as String), isA<DiagnosticsNode>());
        final List<Object?> propertiesJson = childJson['properties']! as List<Object?>;
        for (final Map<String, Object?> propertyJson in propertiesJson.cast<Map<String, Object?>>()) {
          expect(propertyJson, isNot(contains('children')));
        }
        final DiagnosticsNode diagnosticsNode = service.toObject(childJson['objectId']! as String)! as DiagnosticsNode;
        final List<DiagnosticsNode> expectedProperties = diagnosticsNode.getProperties();
        for (final Map<String, Object?> propertyJson in propertiesJson.cast<Map<String, Object?>>()) {
          final Object property = service.toObject(propertyJson['objectId']! as String)!;
          expect(property, isA<DiagnosticsNode>());
          expect(expectedProperties, contains(property));
        }
      }

      final Map<String, Object?> deepSubtreeJson = (await service.testExtension(
        'getDetailsSubtree',
        <String, String>{'arg': id, 'objectGroup': group, 'subtreeDepth': '3'},
      ))! as Map<String, Object?>;
      final List<Object?> deepChildrenJson = deepSubtreeJson['children']! as List<Object?>;
      for (final Map<String, Object?> childJson in deepChildrenJson.cast<Map<String, Object?>>()) {
        final List<Object?> propertiesJson = childJson['properties']! as List<Object?>;
        for (final Map<String, Object?> propertyJson in propertiesJson.cast<Map<String, Object?>>()) {
          expect(propertyJson, contains('children'));
        }
      }
    });

    testWidgets('cyclic diagnostics regression test', (WidgetTester tester) async {
      const String group = 'test-group';
      final CyclicDiagnostic a = CyclicDiagnostic('a');
      final CyclicDiagnostic b = CyclicDiagnostic('b');
      a.related = b;
      a.children.add(b.toDiagnosticsNode());
      b.related = a;

      final DiagnosticsNode diagnostic = a.toDiagnosticsNode();
      final String id = service.toId(diagnostic, group)!;
      final Map<String, Object?> subtreeJson = (await service.testExtension('getDetailsSubtree', <String, String>{'arg': id, 'objectGroup': group}))! as Map<String, Object?>;
      expect(subtreeJson['objectId'], equals(id));
      expect(subtreeJson, contains('children'));
      final List<Object?> propertiesJson = subtreeJson['properties']! as List<Object?>;
      expect(propertiesJson.length, equals(1));
      final Map<String, Object?> relatedProperty = propertiesJson.first! as Map<String, Object?>;
      expect(relatedProperty['name'], equals('related'));
      expect(relatedProperty['description'], equals('CyclicDiagnostic-b'));
      expect(relatedProperty, contains('isDiagnosticableValue'));
      expect(relatedProperty, isNot(contains('children')));
      expect(relatedProperty, contains('properties'));
      final List<Object?> relatedWidgetProperties = relatedProperty['properties']! as List<Object?>;
      expect(relatedWidgetProperties.length, equals(1));
      final Map<String, Object?> nestedRelatedProperty = relatedWidgetProperties.first! as Map<String, Object?>;
      expect(nestedRelatedProperty['name'], equals('related'));
      // Make sure we do not include properties or children for diagnostic a
      // which we already included as the root node as that would indicate a
      // cycle.
      expect(nestedRelatedProperty['description'], equals('CyclicDiagnostic-a'));
      expect(nestedRelatedProperty, contains('isDiagnosticableValue'));
      expect(nestedRelatedProperty, isNot(contains('properties')));
      expect(nestedRelatedProperty, isNot(contains('children')));
    });

    testWidgets('ext.flutter.inspector.getRootWidgetSummaryTree', (WidgetTester tester) async {
      const String group = 'test-group';

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: const <Widget>[
              Text('a', textDirection: TextDirection.ltr),
              Text('b', textDirection: TextDirection.ltr),
              Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final Element elementA = find.text('a').evaluate().first;

      service.disposeAllGroups();
      await service.testExtension('setPubRootDirectories', <String, String>{});
      service.setSelection(elementA, 'my-group');
      final Map<String, dynamic> jsonA = (await service.testExtension('getSelectedWidget', <String, String>{'objectGroup': 'my-group'}))! as Map<String, dynamic>;

      await service.testExtension('setPubRootDirectories', <String, String>{});
      Map<String, Object?> rootJson = (await service.testExtension('getRootWidgetSummaryTree', <String, String>{'objectGroup': group}))! as Map<String, Object?>;
      // We haven't yet properly specified which directories are summary tree
      // directories so we get an empty tree other than the root that is always
      // included.
      final Object? rootWidget = service.toObject(rootJson['valueId']! as String);
      expect(rootWidget, equals(WidgetsBinding.instance?.renderViewElement));
      List<Object?> childrenJson = rootJson['children']! as List<Object?>;
      // There are no summary tree children.
      expect(childrenJson.length, equals(0));

      final Map<String, Object?> creationLocation = jsonA['creationLocation']! as Map<String, Object?>;
      expect(creationLocation, isNotNull);
      final String testFile = creationLocation['file']! as String;
      expect(testFile, endsWith('widget_inspector_test.dart'));
      final List<String> segments = Uri.parse(testFile).pathSegments;
      // Strip a couple subdirectories away to generate a plausible pub root
      // directory.
      final String pubRootTest = '/${segments.take(segments.length - 2).join('/')}';
      await service.testExtension('setPubRootDirectories', <String, String>{'arg0': pubRootTest});

      rootJson = (await service.testExtension('getRootWidgetSummaryTree', <String, String>{'objectGroup': group}))! as Map<String, Object?>;
      childrenJson = rootJson['children']! as List<Object?>;
      // The tree of nodes returned contains all widgets created directly by the
      // test.
      childrenJson = rootJson['children']! as List<Object?>;
      expect(childrenJson.length, equals(1));

      List<Object?> alternateChildrenJson = (await service.testExtension('getChildrenSummaryTree', <String, String>{'arg': rootJson['objectId']! as String, 'objectGroup': group}))! as List<Object?>;
      expect(alternateChildrenJson.length, equals(1));
      Map<String, Object?> childJson = childrenJson[0]! as Map<String, Object?>;
      Map<String, Object?> alternateChildJson = alternateChildrenJson[0]! as Map<String, Object?>;
      expect(childJson['description'], startsWith('Directionality'));
      expect(alternateChildJson['description'], startsWith('Directionality'));
      expect(alternateChildJson['valueId'], equals(childJson['valueId']));

      childrenJson = childJson['children']! as List<Object?>;
      alternateChildrenJson = (await service.testExtension('getChildrenSummaryTree', <String, String>{'arg': childJson['objectId']! as String, 'objectGroup': group}))! as List<Object?>;
      expect(alternateChildrenJson.length, equals(1));
      expect(childrenJson.length, equals(1));
      alternateChildJson = alternateChildrenJson[0]! as Map<String, Object?>;
      childJson = childrenJson[0]! as Map<String, Object?>;
      expect(childJson['description'], startsWith('Stack'));
      expect(alternateChildJson['description'], startsWith('Stack'));
      expect(alternateChildJson['valueId'], equals(childJson['valueId']));
      childrenJson = childJson['children']! as List<Object?>;

      childrenJson = childJson['children']! as List<Object?>;
      alternateChildrenJson = (await service.testExtension('getChildrenSummaryTree', <String, String>{'arg': childJson['objectId']! as String, 'objectGroup': group}))! as List<Object?>;
      expect(alternateChildrenJson.length, equals(3));
      expect(childrenJson.length, equals(3));
      alternateChildJson = alternateChildrenJson[2]! as Map<String, Object?>;
      childJson = childrenJson[2]! as Map<String, Object?>;
      expect(childJson['description'], startsWith('Text'));
      expect(alternateChildJson['description'], startsWith('Text'));
      expect(alternateChildJson['valueId'], equals(childJson['valueId']));
      alternateChildrenJson = (await service.testExtension('getChildrenSummaryTree', <String, String>{'arg': childJson['objectId']! as String, 'objectGroup': group}))! as List<Object?>;
      expect(alternateChildrenJson.length , equals(0));
      // Tests are failing when this typo is fixed.
      expect(childJson['chidlren'], isNull);
    }, skip: !WidgetInspectorService.instance.isWidgetCreationTracked()); // [intended] Test requires --track-widget-creation flag.

    testWidgets('ext.flutter.inspector.getSelectedSummaryWidget', (WidgetTester tester) async {
      const String group = 'test-group';

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: const <Widget>[
              Text('a', textDirection: TextDirection.ltr),
              Text('b', textDirection: TextDirection.ltr),
              Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final Element elementA = find.text('a').evaluate().first;

      final List<DiagnosticsNode> children = elementA.debugDescribeChildren();
      expect(children.length, equals(1));
      final DiagnosticsNode richTextDiagnostic = children.first;

      service.disposeAllGroups();
      await service.testExtension('setPubRootDirectories', <String, String>{});
      service.setSelection(elementA, 'my-group');
      final Map<String, Object?> jsonA = (await service.testExtension('getSelectedWidget', <String, String>{'objectGroup': 'my-group'}))! as Map<String, Object?>;
      service.setSelection(richTextDiagnostic.value, 'my-group');

      await service.testExtension('setPubRootDirectories', <String, String>{});
      Map<String, Object?>? summarySelection = await service.testExtension('getSelectedSummaryWidget', <String, String>{'objectGroup': group}) as Map<String, Object?>?;
      // No summary selection because we haven't set the pub root directories
      // yet to indicate what directories are in the summary tree.
      expect(summarySelection, isNull);

      final Map<String, Object?> creationLocation = jsonA['creationLocation']! as Map<String, Object?>;
      expect(creationLocation, isNotNull);
      final String testFile = creationLocation['file']! as String;
      expect(testFile, endsWith('widget_inspector_test.dart'));
      final List<String> segments = Uri.parse(testFile).pathSegments;
      // Strip a couple subdirectories away to generate a plausible pub root
      // directory.
      final String pubRootTest = '/${segments.take(segments.length - 2).join('/')}';
      await service.testExtension('setPubRootDirectories', <String, String>{'arg0': pubRootTest});

      summarySelection = (await service.testExtension('getSelectedSummaryWidget', <String, String>{'objectGroup': group}))! as Map<String, Object?>;
      expect(summarySelection['valueId'], isNotNull);
      // We got the Text element instead of the selected RichText element
      // because only the RichText element is part of the summary tree.
      expect(service.toObject(summarySelection['valueId']! as String), elementA);

      // Verify tha the regular getSelectedWidget method still returns
      // the RichText object not the Text element.
      final Map<String, Object?> regularSelection = (await service.testExtension('getSelectedWidget', <String, String>{'objectGroup': 'my-group'}))! as Map<String, Object?>;
      expect(service.toObject(regularSelection['valueId']! as String), richTextDiagnostic.value);
    }, skip: !WidgetInspectorService.instance.isWidgetCreationTracked()); // [intended] Test requires --track-widget-creation flag.

    testWidgets('ext.flutter.inspector creationLocation', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: const <Widget>[
              Text('a'),
              Text('b', textDirection: TextDirection.ltr),
              Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final Element elementA = find.text('a').evaluate().first;
      final Element elementB = find.text('b').evaluate().first;

      service.disposeAllGroups();
      await service.testExtension('setPubRootDirectories', <String, String>{});
      service.setSelection(elementA, 'my-group');
      final Map<String, Object?> jsonA = (await service.testExtension('getSelectedWidget', <String, String>{'objectGroup': 'my-group'}))! as Map<String, Object?>;
      final Map<String, Object?> creationLocationA = jsonA['creationLocation']! as Map<String, Object?>;
      expect(creationLocationA, isNotNull);
      final String fileA = creationLocationA['file']! as String;
      final int lineA = creationLocationA['line']! as int;
      final int columnA = creationLocationA['column']! as int;

      service.setSelection(elementB, 'my-group');
      final Map<String, Object?> jsonB = (await service.testExtension('getSelectedWidget', <String, String>{'objectGroup': 'my-group'}))! as Map<String, Object?>;
      final Map<String, Object?> creationLocationB = jsonB['creationLocation']! as Map<String, Object?>;
      expect(creationLocationB, isNotNull);
      final String fileB = creationLocationB['file']! as String;
      final int lineB = creationLocationB['line']! as int;
      final int columnB = creationLocationB['column']! as int;
      expect(fileA, endsWith('widget_inspector_test.dart'));
      expect(fileA, equals(fileB));
      // We don't hardcode the actual lines the widgets are created on as that
      // would make this test fragile.
      expect(lineA + 1, equals(lineB));
      // Column numbers are more stable than line numbers.
      expect(columnA, equals(15));
      expect(columnA, equals(columnB));
    }, skip: !WidgetInspectorService.instance.isWidgetCreationTracked()); // [intended] Test requires --track-widget-creation flag.

    testWidgets('ext.flutter.inspector.setPubRootDirectories', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: const <Widget>[
              Text('a'),
              Text('b', textDirection: TextDirection.ltr),
              Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final Element elementA = find.text('a').evaluate().first;

      await service.testExtension('setPubRootDirectories', <String, String>{});
      service.setSelection(elementA, 'my-group');
      Map<String, Object?> jsonObject = (await service.testExtension('getSelectedWidget', <String, String>{'objectGroup': 'my-group'}))! as Map<String, Object?>;
      Map<String, Object?> creationLocation = jsonObject['creationLocation']! as Map<String, Object?>;
      expect(creationLocation, isNotNull);
      final String fileA = creationLocation['file']! as String;
      expect(fileA, endsWith('widget_inspector_test.dart'));
      expect(jsonObject, isNot(contains('createdByLocalProject')));
      final List<String> segments = Uri.parse(fileA).pathSegments;
      // Strip a couple subdirectories away to generate a plausible pub root
      // directory.
      final String pubRootTest = '/${segments.take(segments.length - 2).join('/')}';
      await service.testExtension('setPubRootDirectories', <String, String>{'arg0': pubRootTest});

      service.setSelection(elementA, 'my-group');
      expect(await service.testExtension('getSelectedWidget', <String, String>{'objectGroup': 'my-group'}), contains('createdByLocalProject'));

      await service.testExtension('setPubRootDirectories', <String, String>{'arg0': '/invalid/$pubRootTest'});
      expect(await service.testExtension('getSelectedWidget', <String, String>{'objectGroup': 'my-group'}), isNot(contains('createdByLocalProject')));

      await service.testExtension('setPubRootDirectories', <String, String>{'arg0': 'file://$pubRootTest'});
      expect(await service.testExtension('getSelectedWidget', <String, String>{'objectGroup': 'my-group'}), contains('createdByLocalProject'));

      await service.testExtension('setPubRootDirectories', <String, String>{'arg0': '$pubRootTest/different'});
      expect(await service.testExtension('getSelectedWidget', <String, String>{'objectGroup': 'my-group'}), isNot(contains('createdByLocalProject')));

      await service.testExtension('setPubRootDirectories', <String, String>{
        'arg0': '/unrelated/$pubRootTest',
        'arg1': 'file://$pubRootTest',
      });

      expect(await service.testExtension('getSelectedWidget', <String, String>{'objectGroup': 'my-group'}), contains('createdByLocalProject'));

      // The RichText child of the Text widget is created by the core framework
      // not the current package.
      final Element richText = find.descendant(
        of: find.text('a'),
        matching: find.byType(RichText),
      ).evaluate().first;
      service.setSelection(richText, 'my-group');
      service.setPubRootDirectories(<String>[pubRootTest]);
      jsonObject = json.decode(service.getSelectedWidget(null, 'my-group')) as Map<String, Object?>;
      expect(jsonObject, isNot(contains('createdByLocalProject')));
      creationLocation = jsonObject['creationLocation']! as Map<String, Object?>;
      expect(creationLocation, isNotNull);
      // This RichText widget is created by the build method of the Text widget
      // thus the creation location is in text.dart not basic.dart
      final List<String> pathSegmentsFramework = Uri.parse(creationLocation['file']! as String).pathSegments;
      expect(pathSegmentsFramework.join('/'), endsWith('/flutter/lib/src/widgets/text.dart'));

      // Strip off /src/widgets/text.dart.
      final String pubRootFramework = '/${pathSegmentsFramework.take(pathSegmentsFramework.length - 3).join('/')}';
      await service.testExtension('setPubRootDirectories', <String, String>{'arg0': pubRootFramework});
      expect(await service.testExtension('getSelectedWidget', <String, String>{'objectGroup': 'my-group'}), contains('createdByLocalProject'));
      service.setSelection(elementA, 'my-group');
      expect(await service.testExtension('getSelectedWidget', <String, String>{'objectGroup': 'my-group'}), isNot(contains('createdByLocalProject')));

      await service.testExtension('setPubRootDirectories', <String, String>{'arg0': pubRootFramework, 'arg1': pubRootTest});
      service.setSelection(elementA, 'my-group');
      expect(await service.testExtension('getSelectedWidget', <String, String>{'objectGroup': 'my-group'}), contains('createdByLocalProject'));
      service.setSelection(richText, 'my-group');
      expect(await service.testExtension('getSelectedWidget', <String, String>{'objectGroup': 'my-group'}), contains('createdByLocalProject'));
    }, skip: !WidgetInspectorService.instance.isWidgetCreationTracked()); // [intended] Test requires --track-widget-creation flag.

    testWidgets('ext.flutter.inspector.setPubRootDirectories extra args regression test', (WidgetTester tester) async {
      // Ensure that passing the isolate id as an argument won't break
      // setPubRootDirectories command.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: const <Widget>[
              Text('a'),
              Text('b', textDirection: TextDirection.ltr),
              Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final Element elementA = find.text('a').evaluate().first;

      await service.testExtension('setPubRootDirectories', <String, String>{'isolateId': '34'});
      service.setSelection(elementA, 'my-group');
      final Map<String, Object?> jsonObject = (await service.testExtension('getSelectedWidget', <String, String>{'objectGroup': 'my-group'}))! as Map<String, Object?>;
      final Map<String, Object?> creationLocation = jsonObject['creationLocation']! as Map<String, Object?>;
      expect(creationLocation, isNotNull);
      final String fileA = creationLocation['file']! as String;
      expect(fileA, endsWith('widget_inspector_test.dart'));
      expect(jsonObject, isNot(contains('createdByLocalProject')));
      final List<String> segments = Uri.parse(fileA).pathSegments;
      // Strip a couple subdirectories away to generate a plausible pub root
      // directory.
      final String pubRootTest = '/${segments.take(segments.length - 2).join('/')}';
      await service.testExtension('setPubRootDirectories', <String, String>{'arg0': pubRootTest, 'isolateId': '34'});

      service.setSelection(elementA, 'my-group');
      expect(await service.testExtension('getSelectedWidget', <String, String>{'objectGroup': 'my-group'}), contains('createdByLocalProject'));

      await service.testExtension('setPubRootDirectories', <String, String>{'arg0': '/invalid/$pubRootTest', 'isolateId': '34'});
      expect(await service.testExtension('getSelectedWidget', <String, String>{'objectGroup': 'my-group'}), isNot(contains('createdByLocalProject')));

      await service.testExtension('setPubRootDirectories', <String, String>{'arg0': 'file://$pubRootTest', 'isolateId': '34'});
      expect(await service.testExtension('getSelectedWidget', <String, String>{'objectGroup': 'my-group'}), contains('createdByLocalProject'));

      await service.testExtension('setPubRootDirectories', <String, String>{'arg0': '$pubRootTest/different', 'isolateId': '34'});
      expect(await service.testExtension('getSelectedWidget', <String, String>{'objectGroup': 'my-group'}), isNot(contains('createdByLocalProject')));

      await service.testExtension('setPubRootDirectories', <String, String>{
        'arg0': '/unrelated/$pubRootTest',
        'isolateId': '34',
        'arg1': 'file://$pubRootTest',
      });

      expect(await service.testExtension('getSelectedWidget', <String, String>{'objectGroup': 'my-group'}), contains('createdByLocalProject'));
    }, skip: !WidgetInspectorService.instance.isWidgetCreationTracked()); // [intended] Test requires --track-widget-creation flag.

    Map<Object, Object?> removeLastEvent(List<Map<Object, Object?>> events) {
      final Map<Object, Object?> event = events.removeLast();
      // Verify that the event is json encodable.
      json.encode(event);
      return event;
    }

    testWidgets('ext.flutter.inspector.trackRebuildDirtyWidgets', (WidgetTester tester) async {
      service.rebuildCount = 0;

      await tester.pumpWidget(const ClockDemo());

      final Element clockDemoElement = find.byType(ClockDemo).evaluate().first;

      service.setSelection(clockDemoElement, 'my-group');
      final Map<String, Object?> jsonObject = (await service.testExtension(
        'getSelectedWidget',
        <String, String>{'objectGroup': 'my-group'},
      ))! as Map<String, Object?>;
      final Map<String, Object?> creationLocation = jsonObject['creationLocation']! as Map<String, Object?>;
      expect(creationLocation, isNotNull);
      final String file = creationLocation['file']! as String;
      expect(file, endsWith('widget_inspector_test.dart'));
      final List<String> segments = Uri.parse(file).pathSegments;
      // Strip a couple subdirectories away to generate a plausible pub root
      // directory.
      final String pubRootTest = '/${segments.take(segments.length - 2).join('/')}';
      await service.testExtension('setPubRootDirectories', <String, String>{'arg0': pubRootTest});

      final List<Map<Object, Object?>> rebuildEvents =
          service.getEventsDispatched('Flutter.RebuiltWidgets');
      expect(rebuildEvents, isEmpty);

      expect(service.rebuildCount, equals(0));
      expect(
        await service.testBoolExtension('trackRebuildDirtyWidgets', <String, String>{'enabled': 'true'}),
        equals('true'),
      );
      expect(service.rebuildCount, equals(1));
      await tester.pump();

      expect(rebuildEvents.length, equals(1));
      Map<Object, Object?> event = removeLastEvent(rebuildEvents);
      expect(event['startTime'], isA<int>());
      List<int> data = event['events']! as List<int>;
      expect(data.length, equals(14));
      final int numDataEntries = data.length ~/ 2;
      Map<String, List<int>> newLocations = event['newLocations']! as Map<String, List<int>>;
      expect(newLocations, isNotNull);
      expect(newLocations.length, equals(1));
      expect(newLocations.keys.first, equals(file));
      Map<String, Map<String, List<Object?>>> fileLocationsMap = event['locations']! as Map<String, Map<String, List<Object?>>>;
      expect(fileLocationsMap, isNotNull);
      expect(fileLocationsMap.length, equals(1));
      expect(fileLocationsMap.keys.first, equals(file));
      final List<int> locationsForFile = newLocations[file]!;
      expect(locationsForFile.length, equals(21));
      final int numLocationEntries = locationsForFile.length ~/ 3;
      expect(numLocationEntries, equals(numDataEntries));
      final Map<String, List<Object?>> locations = fileLocationsMap[file]!;
      expect(locations.length, equals(4));
      expect(locations['ids']!.length, equals(7));

      final Map<int, _CreationLocation> knownLocations = <int, _CreationLocation>{};
      _addToKnownLocationsMap(
        knownLocations: knownLocations,
        newLocations: fileLocationsMap,
      );
      int totalCount = 0;
      int maxCount = 0;
      for (int i = 0; i < data.length; i += 2) {
        final int id = data[i];
        final int count = data[i + 1];
        totalCount += count;
        maxCount = max(maxCount, count);
        expect(knownLocations, contains(id));
      }
      expect(totalCount, equals(27));
      // The creation locations that were rebuilt the most were rebuilt 6 times
      // as there are 6 instances of the ClockText widget.
      expect(maxCount, equals(6));

      final List<Element> clocks = find.byType(ClockText).evaluate().toList();
      expect(clocks.length, equals(6));
      // Update a single clock.
      StatefulElement clockElement = clocks.first as StatefulElement;
      _ClockTextState state = clockElement.state as _ClockTextState;
      state.updateTime(); // Triggers a rebuild.
      await tester.pump();
      expect(rebuildEvents.length, equals(1));
      event = removeLastEvent(rebuildEvents);
      expect(event['startTime'], isA<int>());
      data = event['events']! as List<int>;
      // No new locations were rebuilt.
      expect(event, isNot(contains('newLocations')));
      expect(event, isNot(contains('locations')));

      // There were two rebuilds: one for the ClockText element itself and one
      // for its child.
      expect(data.length, equals(4));
      int id = data[0];
      int count = data[1];
      _CreationLocation location = knownLocations[id]!;
      expect(location.file, equals(file));
      // ClockText widget.
      expect(location.line, equals(64));
      expect(location.column, equals(9));
      expect(location.name, equals('ClockText'));
      expect(count, equals(1));

      id = data[2];
      count = data[3];
      location = knownLocations[id]!;
      expect(location.file, equals(file));
      // Text widget in _ClockTextState build method.
      expect(location.line, equals(102));
      expect(location.column, equals(12));
      expect(location.name, equals('Text'));
      expect(count, equals(1));

      // Update 3 of the clocks;
      for (int i = 0; i < 3; i++) {
        clockElement = clocks[i] as StatefulElement;
        state = clockElement.state as _ClockTextState;
        state.updateTime(); // Triggers a rebuild.
      }

      await tester.pump();
      expect(rebuildEvents.length, equals(1));
      event = removeLastEvent(rebuildEvents);
      expect(event['startTime'], isA<int>());
      data = event['events']! as List<int>;
      // No new locations were rebuilt.
      expect(event, isNot(contains('newLocations')));
      expect(event, isNot(contains('locations')));

      expect(data.length, equals(4));
      id = data[0];
      count = data[1];
      location = knownLocations[id]!;
      expect(location.file, equals(file));
      // ClockText widget.
      expect(location.line, equals(64));
      expect(location.column, equals(9));
      expect(location.name, equals('ClockText'));
      expect(count, equals(3)); // 3 clock widget instances rebuilt.

      id = data[2];
      count = data[3];
      location = knownLocations[id]!;
      expect(location.file, equals(file));
      // Text widget in _ClockTextState build method.
      expect(location.line, equals(102));
      expect(location.column, equals(12));
      expect(location.name, equals('Text'));
      expect(count, equals(3)); // 3 clock widget instances rebuilt.

      // Update one clock 3 times.
      clockElement = clocks.first as StatefulElement;
      state = clockElement.state as _ClockTextState;
      state.updateTime(); // Triggers a rebuild.
      state.updateTime(); // Triggers a rebuild.
      state.updateTime(); // Triggers a rebuild.

      await tester.pump();
      expect(rebuildEvents.length, equals(1));
      event = removeLastEvent(rebuildEvents);
      expect(event['startTime'], isA<int>());
      data = event['events']! as List<int>;
      // No new locations were rebuilt.
      expect(event, isNot(contains('newLocations')));
      expect(event, isNot(contains('locations')));

      expect(data.length, equals(4));
      id = data[0];
      count = data[1];
      // Even though a rebuild was triggered 3 times, only one rebuild actually
      // occurred.
      expect(count, equals(1));

      // Trigger a widget creation location that wasn't previously triggered.
      state.stopClock();
      await tester.pump();
      expect(rebuildEvents.length, equals(1));
      event = removeLastEvent(rebuildEvents);
      expect(event['startTime'], isA<int>());
      data = event['events']! as List<int>;
      newLocations = event['newLocations']! as Map<String, List<int>>;
      fileLocationsMap = event['locations']! as Map<String, Map<String, List<Object?>>>;

      expect(data.length, equals(4));
      // The second pair in data is the previously unseen rebuild location.
      id = data[2];
      count = data[3];
      expect(count, equals(1));
      // Verify the rebuild location is new.
      expect(knownLocations, isNot(contains(id)));
      _addToKnownLocationsMap(
        knownLocations: knownLocations,
        newLocations: fileLocationsMap,
      );
      // Verify the rebuild location was included in the newLocations data.
      expect(knownLocations, contains(id));

      // Turn off rebuild counts.
      expect(
        await service.testBoolExtension('trackRebuildDirtyWidgets', <String, String>{'enabled': 'false'}),
        equals('false'),
      );

      state.updateTime(); // Triggers a rebuild.
      await tester.pump();
      // Verify that rebuild events are not fired once the extension is disabled.
      expect(rebuildEvents, isEmpty);
    }, skip: !WidgetInspectorService.instance.isWidgetCreationTracked()); // [intended] Test requires --track-widget-creation flag.

    testWidgets('ext.flutter.inspector.trackRepaintWidgets', (WidgetTester tester) async {
      service.rebuildCount = 0;

      await tester.pumpWidget(const ClockDemo());

      final Element clockDemoElement = find.byType(ClockDemo).evaluate().first;

      service.setSelection(clockDemoElement, 'my-group');
      final Map<String, Object?> jsonObject = (await service.testExtension(
        'getSelectedWidget',
        <String, String>{'objectGroup': 'my-group'},
      ))! as Map<String, Object?>;
      final Map<String, Object?> creationLocation =
          jsonObject['creationLocation']! as Map<String, Object?>;
      expect(creationLocation, isNotNull);
      final String file = creationLocation['file']! as String;
      expect(file, endsWith('widget_inspector_test.dart'));
      final List<String> segments = Uri.parse(file).pathSegments;
      // Strip a couple subdirectories away to generate a plausible pub root
      // directory.
      final String pubRootTest = '/${segments.take(segments.length - 2).join('/')}';
      await service.testExtension('setPubRootDirectories', <String, String>{'arg0': pubRootTest});

      final List<Map<Object, Object?>> repaintEvents =
          service.getEventsDispatched('Flutter.RepaintWidgets');
      expect(repaintEvents, isEmpty);

      expect(service.rebuildCount, equals(0));
      expect(
        await service.testBoolExtension('trackRepaintWidgets', <String, String>{'enabled': 'true'}),
        equals('true'),
      );
      // Unlike trackRebuildDirtyWidgets, trackRepaintWidgets doesn't force a full
      // rebuild.
      expect(service.rebuildCount, equals(0));

      await tester.pump();

      expect(repaintEvents.length, equals(1));
      Map<Object, Object?> event = removeLastEvent(repaintEvents);
      expect(event['startTime'], isA<int>());
      List<int> data = event['events']! as List<int>;
      expect(data.length, equals(18));
      final int numDataEntries = data.length ~/ 2;
      final Map<String, List<int>> newLocations = event['newLocations']! as Map<String, List<int>>;
      expect(newLocations, isNotNull);
      expect(newLocations.length, equals(1));
      expect(newLocations.keys.first, equals(file));
      final Map<String, Map<String, List<Object?>>> fileLocationsMap = event['locations']! as Map<String, Map<String, List<Object?>>>;
      expect(fileLocationsMap, isNotNull);
      expect(fileLocationsMap.length, equals(1));
      expect(fileLocationsMap.keys.first, equals(file));
      final List<int> locationsForFile = newLocations[file]!;
      expect(locationsForFile.length, equals(27));
      final int numLocationEntries = locationsForFile.length ~/ 3;
      expect(numLocationEntries, equals(numDataEntries));
      final Map<String, List<Object?>> locations = fileLocationsMap[file]!;
      expect(locations.length, equals(4));
      expect(locations['ids']!.length, equals(9));

      final Map<int, _CreationLocation> knownLocations = <int, _CreationLocation>{};
      _addToKnownLocationsMap(
        knownLocations: knownLocations,
        newLocations: fileLocationsMap,
      );
      int totalCount = 0;
      int maxCount = 0;
      for (int i = 0; i < data.length; i += 2) {
        final int id = data[i];
        final int count = data[i + 1];
        totalCount += count;
        maxCount = max(maxCount, count);
        expect(knownLocations, contains(id));
      }
      expect(totalCount, equals(34));
      // The creation locations that were rebuilt the most were rebuilt 6 times
      // as there are 6 instances of the ClockText widget.
      expect(maxCount, equals(6));

      final List<Element> clocks = find.byType(ClockText).evaluate().toList();
      expect(clocks.length, equals(6));
      // Update a single clock.
      final StatefulElement clockElement = clocks.first as StatefulElement;
      final _ClockTextState state = clockElement.state as _ClockTextState;
      state.updateTime(); // Triggers a rebuild.
      await tester.pump();
      expect(repaintEvents.length, equals(1));
      event = removeLastEvent(repaintEvents);
      expect(event['startTime'], isA<int>());
      data = event['events']! as List<int>;
      // No new locations were rebuilt.
      expect(event, isNot(contains('newLocations')));
      expect(event, isNot(contains('locations')));

      // Triggering a rebuild of one widget in this app causes the whole app
      // to repaint.
      expect(data.length, equals(18));

      // TODO(jacobr): add an additional repaint test that uses multiple repaint
      // boundaries to test more complex repaint conditions.

      // Turn off rebuild counts.
      expect(
        await service.testBoolExtension('trackRepaintWidgets', <String, String>{'enabled': 'false'}),
        equals('false'),
      );

      state.updateTime(); // Triggers a rebuild.
      await tester.pump();
      // Verify that repaint events are not fired once the extension is disabled.
      expect(repaintEvents, isEmpty);
    }, skip: !WidgetInspectorService.instance.isWidgetCreationTracked()); // [intended] Test requires --track-widget-creation flag.

    testWidgets('ext.flutter.inspector.show', (WidgetTester tester) async {
      final Iterable<Map<Object, Object?>> extensionChangedEvents = service.getServiceExtensionStateChangedEvents('ext.flutter.inspector.show');
      Map<Object, Object?> extensionChangedEvent;

      service.rebuildCount = 0;
      expect(extensionChangedEvents, isEmpty);
      expect(await service.testBoolExtension('show', <String, String>{'enabled': 'true'}), equals('true'));
      expect(extensionChangedEvents.length, equals(1));
      extensionChangedEvent = extensionChangedEvents.last;
      expect(extensionChangedEvent['extension'], equals('ext.flutter.inspector.show'));
      expect(extensionChangedEvent['value'], isTrue);
      expect(service.rebuildCount, equals(1));
      expect(await service.testBoolExtension('show', <String, String>{}), equals('true'));
      expect(WidgetsApp.debugShowWidgetInspectorOverride, isTrue);
      expect(extensionChangedEvents.length, equals(1));
      expect(await service.testBoolExtension('show', <String, String>{'enabled': 'true'}), equals('true'));
      expect(extensionChangedEvents.length, equals(2));
      extensionChangedEvent = extensionChangedEvents.last;
      expect(extensionChangedEvent['extension'], equals('ext.flutter.inspector.show'));
      expect(extensionChangedEvent['value'], isTrue);
      expect(service.rebuildCount, equals(1));
      expect(await service.testBoolExtension('show', <String, String>{'enabled': 'false'}), equals('false'));
      expect(extensionChangedEvents.length, equals(3));
      extensionChangedEvent = extensionChangedEvents.last;
      expect(extensionChangedEvent['extension'], equals('ext.flutter.inspector.show'));
      expect(extensionChangedEvent['value'], isFalse);
      expect(await service.testBoolExtension('show', <String, String>{}), equals('false'));
      expect(extensionChangedEvents.length, equals(3));
      expect(service.rebuildCount, equals(2));
      expect(WidgetsApp.debugShowWidgetInspectorOverride, isFalse);
    });

    testWidgets('ext.flutter.inspector.screenshot', (WidgetTester tester) async {
      final GlobalKey outerContainerKey = GlobalKey();
      final GlobalKey paddingKey = GlobalKey();
      final GlobalKey redContainerKey = GlobalKey();
      final GlobalKey whiteContainerKey = GlobalKey();
      final GlobalKey sizedBoxKey = GlobalKey();

      // Complex widget tree intended to exercise features such as children
      // with rotational transforms and clipping without introducing platform
      // specific behavior as text rendering would.
      await tester.pumpWidget(
        Center(
          child: RepaintBoundaryWithDebugPaint(
            child: Container(
              key: outerContainerKey,
              color: Colors.white,
              child: Padding(
                key: paddingKey,
                padding: const EdgeInsets.all(100.0),
                child: SizedBox(
                  key: sizedBoxKey,
                  height: 100.0,
                  width: 100.0,
                  child: Transform.rotate(
                    angle: 1.0, // radians
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.elliptical(10.0, 20.0),
                        topRight: Radius.elliptical(5.0, 30.0),
                        bottomLeft: Radius.elliptical(2.5, 12.0),
                        bottomRight: Radius.elliptical(15.0, 6.0),
                      ),
                      child: Container(
                        key: redContainerKey,
                        color: Colors.red,
                        child: Container(
                          key: whiteContainerKey,
                          color: Colors.white,
                          child: RepaintBoundary(
                            child: Center(
                              child: Container(
                                color: Colors.black,
                                height: 10.0,
                                width: 10.0,
                              ),
                            ),
                          ),
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

      final Element repaintBoundary =
          find.byType(RepaintBoundaryWithDebugPaint).evaluate().single;

      final RenderRepaintBoundary renderObject = repaintBoundary.renderObject! as RenderRepaintBoundary;

      final OffsetLayer layer = renderObject.debugLayer! as OffsetLayer;
      final int expectedChildLayerCount = getChildLayerCount(layer);
      expect(expectedChildLayerCount, equals(2));
      await expectLater(
        layer.toImage(renderObject.semanticBounds.inflate(50.0)),
        matchesGoldenFile('inspector.repaint_boundary_margin.png'),
      );

      // Regression test for how rendering with a pixel scale other than 1.0
      // was handled.
      await expectLater(
        layer.toImage(
          renderObject.semanticBounds.inflate(50.0),
          pixelRatio: 0.5,
        ),
        matchesGoldenFile('inspector.repaint_boundary_margin_small.png'),
      );

      await expectLater(
        layer.toImage(
          renderObject.semanticBounds.inflate(50.0),
          pixelRatio: 2.0,
        ),
        matchesGoldenFile('inspector.repaint_boundary_margin_large.png'),
      );

      final Layer? layerParent = layer.parent;
      final Layer? firstChild = layer.firstChild;

      expect(layerParent, isNotNull);
      expect(firstChild, isNotNull);

      await expectLater(
        service.screenshot(
          repaintBoundary,
          width: 300.0,
          height: 300.0,
        ),
        matchesGoldenFile('inspector.repaint_boundary.png'),
      );

      // Verify that taking a screenshot didn't change the layers associated with
      // the renderObject.
      expect(renderObject.debugLayer, equals(layer));
      // Verify that taking a screenshot did not change the number of children
      // of the layer.
      expect(getChildLayerCount(layer), equals(expectedChildLayerCount));

      await expectLater(
        service.screenshot(
          repaintBoundary,
          width: 500.0,
          height: 500.0,
          margin: 50.0,
        ),
        matchesGoldenFile('inspector.repaint_boundary_margin.png'),
      );

      // Verify that taking a screenshot didn't change the layers associated with
      // the renderObject.
      expect(renderObject.debugLayer, equals(layer));
      // Verify that taking a screenshot did not change the number of children
      // of the layer.
      expect(getChildLayerCount(layer), equals(expectedChildLayerCount));

      // Make sure taking a screenshot didn't change the parent of the layer.
      expect(layer.parent, equals(layerParent));

      await expectLater(
        service.screenshot(
          repaintBoundary,
          width: 300.0,
          height: 300.0,
          debugPaint: true,
        ),
        matchesGoldenFile('inspector.repaint_boundary_debugPaint.png'),
      );
      // Verify that taking a screenshot with debug paint on did not change
      // the number of children the layer has.
      expect(getChildLayerCount(layer), equals(expectedChildLayerCount));

      // Ensure that creating screenshots including ones with debug paint
      // hasn't changed the regular render of the widget.
      await expectLater(
        find.byType(RepaintBoundaryWithDebugPaint),
        matchesGoldenFile('inspector.repaint_boundary.png'),
      );

      expect(renderObject.debugLayer, equals(layer));
      expect(layer.attached, isTrue);

      // Full size image
      await expectLater(
        service.screenshot(
          find.byKey(outerContainerKey).evaluate().single,
          width: 100.0,
          height: 100.0,
        ),
        matchesGoldenFile('inspector.container.png'),
      );

      await expectLater(
        service.screenshot(
          find.byKey(outerContainerKey).evaluate().single,
          width: 100.0,
          height: 100.0,
          debugPaint: true,
        ),
        matchesGoldenFile('inspector.container_debugPaint.png'),
      );

      {
        // Verify calling the screenshot method still works if the RenderObject
        // needs to be laid out again.
        final RenderObject container =
            find.byKey(outerContainerKey).evaluate().single.renderObject!;
        container
          ..markNeedsLayout()
          ..markNeedsPaint();
        expect(container.debugNeedsLayout, isTrue);

        await expectLater(
          service.screenshot(
            find.byKey(outerContainerKey).evaluate().single,
            width: 100.0,
            height: 100.0,
            debugPaint: true,
          ),
          matchesGoldenFile('inspector.container_debugPaint.png'),
        );
        expect(container.debugNeedsLayout, isFalse);
      }

      // Small image
      await expectLater(
        service.screenshot(
          find.byKey(outerContainerKey).evaluate().single,
          width: 50.0,
          height: 100.0,
        ),
        matchesGoldenFile('inspector.container_small.png'),
      );

      await expectLater(
        service.screenshot(
          find.byKey(outerContainerKey).evaluate().single,
          width: 400.0,
          height: 400.0,
          maxPixelRatio: 3.0,
        ),
        matchesGoldenFile('inspector.container_large.png'),
      );

      // This screenshot will show the clip rect debug paint but no other
      // debug paint.
      await expectLater(
        service.screenshot(
          find.byType(ClipRRect).evaluate().single,
          width: 100.0,
          height: 100.0,
          debugPaint: true,
        ),
        matchesGoldenFile('inspector.clipRect_debugPaint.png'),
      );

      final Element clipRect = find.byType(ClipRRect).evaluate().single;

      final Future<ui.Image?> clipRectScreenshot = service.screenshot(
        clipRect,
        width: 100.0,
        height: 100.0,
        margin: 20.0,
        debugPaint: true,
      );
      // Add a margin so that the clip icon shows up in the screenshot.
      // This golden image is platform dependent due to the clip icon.
      await expectLater(
        clipRectScreenshot,
        matchesGoldenFile('inspector.clipRect_debugPaint_margin.png'),
      );

      // Verify we get the same image if we go through the service extension
      // instead of invoking the screenshot method directly.
      final Future<Object?> base64ScreenshotFuture = service.testExtension(
        'screenshot',
        <String, String>{
          'id': service.toId(clipRect, 'group')!,
          'width': '100.0',
          'height': '100.0',
          'margin': '20.0',
          'debugPaint': 'true',
        },
      );

      final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized() as TestWidgetsFlutterBinding;
      final ui.Image screenshotImage = (await binding.runAsync<ui.Image>(() async {
        final String base64Screenshot = (await base64ScreenshotFuture)! as String;
        final ui.Codec codec = await ui.instantiateImageCodec(base64.decode(base64Screenshot));
        final ui.FrameInfo frame = await codec.getNextFrame();
        return frame.image;
      }, additionalTime: const Duration(seconds: 11)))!;

      await expectLater(
        screenshotImage,
        matchesReferenceImage((await clipRectScreenshot)!),
      );

      // Test with a very visible debug paint
      await expectLater(
        service.screenshot(
          find.byKey(paddingKey).evaluate().single,
          width: 300.0,
          height: 300.0,
          debugPaint: true,
        ),
        matchesGoldenFile('inspector.padding_debugPaint.png'),
      );

      // The bounds for this box crop its rendered content.
      await expectLater(
        service.screenshot(
          find.byKey(sizedBoxKey).evaluate().single,
          width: 300.0,
          height: 300.0,
          debugPaint: true,
        ),
        matchesGoldenFile('inspector.sizedBox_debugPaint.png'),
      );

      // Verify that setting a margin includes the previously cropped content.
      await expectLater(
        service.screenshot(
          find.byKey(sizedBoxKey).evaluate().single,
          width: 300.0,
          height: 300.0,
          margin: 50.0,
          debugPaint: true,
        ),
        matchesGoldenFile('inspector.sizedBox_debugPaint_margin.png'),
      );
    });

    test('ext.flutter.inspector.structuredErrors', () async {
      List<Map<Object, Object?>> flutterErrorEvents = service.getEventsDispatched('Flutter.Error');
      expect(flutterErrorEvents, isEmpty);

      final FlutterExceptionHandler oldHandler = FlutterError.presentError;

      try {
        // Enable structured errors.
        expect(
          await service.testBoolExtension('structuredErrors', <String, String>{'enabled': 'true'}),
          equals('true'),
        );

        // Create an error.
        FlutterError.reportError(FlutterErrorDetails(
          library: 'rendering library',
          context: ErrorDescription('during layout'),
          exception: StackTrace.current,
        ));

        // Validate that we received an error.
        flutterErrorEvents = service.getEventsDispatched('Flutter.Error');
        expect(flutterErrorEvents, hasLength(1));

        // Validate the error contents.
        Map<Object, Object?> error = flutterErrorEvents.first;
        expect(error['description'], 'Exception caught by rendering library');
        expect(error['children'], isEmpty);

        // Validate that we received an error count.
        expect(error['errorsSinceReload'], 0);
        expect(
          error['renderedErrorText'],
          startsWith('══╡ EXCEPTION CAUGHT BY RENDERING LIBRARY ╞════════════'),
        );

        // Send a second error.
        FlutterError.reportError(FlutterErrorDetails(
          library: 'rendering library',
          context: ErrorDescription('also during layout'),
          exception: StackTrace.current,
        ));

        // Validate that the error count increased.
        flutterErrorEvents = service.getEventsDispatched('Flutter.Error');
        expect(flutterErrorEvents, hasLength(2));
        error = flutterErrorEvents.last;
        expect(error['errorsSinceReload'], 1);
        expect(error['renderedErrorText'], startsWith('Another exception was thrown:'));

        // Reloads the app.
        final FlutterExceptionHandler? oldHandler = FlutterError.onError;
        final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized() as TestWidgetsFlutterBinding;
        // We need the runTest to setup the fake async in the test binding.
        await binding.runTest(() async {
          binding.reassembleApplication();
          await binding.pump();
        }, () { });
        // The run test overrides the flutter error handler, so we should
        // restore it back for the structure error to continue working.
        FlutterError.onError = oldHandler;
        // Cleans up the fake async so it does not bleed into next test.
        binding.postTest();

        // Send another error.
        FlutterError.reportError(FlutterErrorDetails(
          library: 'rendering library',
          context: ErrorDescription('during layout'),
          exception: StackTrace.current,
        ));

        // And, validate that the error count has been reset.
        flutterErrorEvents = service.getEventsDispatched('Flutter.Error');
        expect(flutterErrorEvents, hasLength(3));
        error = flutterErrorEvents.last;
        expect(error['errorsSinceReload'], 0);
      } finally {
        FlutterError.presentError = oldHandler;
      }
    });

    testWidgets('Screenshot of composited transforms - only offsets', (WidgetTester tester) async {
      // Composited transforms are challenging to take screenshots of as the
      // LeaderLayer and FollowerLayer classes used by CompositedTransformTarget
      // and CompositedTransformFollower depend on traversing ancestors of the
      // layer tree and mutating a [LayerLink] object when attaching layers to
      // the tree so that the FollowerLayer knows about the LeaderLayer.
      // 1. Finding the correct position for the follower layers requires
      // traversing the ancestors of the follow layer to find a common ancestor
      // with the leader layer.
      // 2. Creating a LeaderLayer and attaching it to a layer tree has side
      // effects as the leader layer will attempt to modify the mutable
      // LeaderLayer object shared by the LeaderLayer and FollowerLayer.
      // These tests verify that screenshots can still be taken and look correct
      // when the leader and follower layer are both in the screenshots and when
      // only the leader or follower layer is in the screenshot.
      final LayerLink link = LayerLink();
      final GlobalKey key = GlobalKey();
      final GlobalKey mainStackKey = GlobalKey();
      final GlobalKey transformTargetParent = GlobalKey();
      final GlobalKey stackWithTransformFollower = GlobalKey();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            child: Stack(
              key: mainStackKey,
              children: <Widget>[
                Stack(
                  key: transformTargetParent,
                  children: <Widget>[
                    Positioned(
                      left: 123.0,
                      top: 456.0,
                      child: CompositedTransformTarget(
                        link: link,
                        child: Container(height: 20.0, width: 20.0, color: const Color.fromARGB(128, 255, 0, 0)),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 787.0,
                  top: 343.0,
                  child: Stack(
                    key: stackWithTransformFollower,
                    children: <Widget>[
                      // Container so we can see how the follower layer was
                      // transformed relative to its initial location.
                      Container(height: 15.0, width: 15.0, color: const Color.fromARGB(128, 0, 0, 255)),
                      CompositedTransformFollower(
                        link: link,
                        child: Container(key: key, height: 10.0, width: 10.0, color: const Color.fromARGB(128, 0, 255, 0)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      final RenderBox box = key.currentContext!.findRenderObject()! as RenderBox;
      expect(box.localToGlobal(Offset.zero), const Offset(123.0, 456.0));

      await expectLater(
        find.byKey(mainStackKey),
        matchesGoldenFile('inspector.composited_transform.only_offsets.png'),
      );

      await expectLater(
        WidgetInspectorService.instance.screenshot(
          find.byKey(stackWithTransformFollower).evaluate().first,
          width: 5000.0,
          height: 500.0,
        ),
        matchesGoldenFile('inspector.composited_transform.only_offsets_follower.png'),
      );

      await expectLater(
        WidgetInspectorService.instance.screenshot(find.byType(Stack).evaluate().first, width: 300.0, height: 300.0),
        matchesGoldenFile('inspector.composited_transform.only_offsets_small.png'),
      );

      await expectLater(
        WidgetInspectorService.instance.screenshot(
          find.byKey(transformTargetParent).evaluate().first,
          width: 500.0,
          height: 500.0,
        ),
        matchesGoldenFile('inspector.composited_transform.only_offsets_target.png'),
      );
    });

    testWidgets('Screenshot composited transforms - with rotations', (WidgetTester tester) async {
      final LayerLink link = LayerLink();
      final GlobalKey key1 = GlobalKey();
      final GlobalKey key2 = GlobalKey();
      final GlobalKey rotate1 = GlobalKey();
      final GlobalKey rotate2 = GlobalKey();
      final GlobalKey mainStackKey = GlobalKey();
      final GlobalKey stackWithTransformTarget = GlobalKey();
      final GlobalKey stackWithTransformFollower = GlobalKey();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            key: mainStackKey,
            children: <Widget>[
              Stack(
                key: stackWithTransformTarget,
                children: <Widget>[
                  Positioned(
                    top: 123.0,
                    left: 456.0,
                    child: Transform.rotate(
                      key: rotate1,
                      angle: 1.0, // radians
                      child: CompositedTransformTarget(
                        link: link,
                        child: Container(key: key1, height: 20.0, width: 20.0, color: const Color.fromARGB(128, 255, 0, 0)),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 487.0,
                left: 243.0,
                child: Stack(
                  key: stackWithTransformFollower,
                  children: <Widget>[
                    Container(height: 15.0, width: 15.0, color: const Color.fromARGB(128, 0, 0, 255)),
                    Transform.rotate(
                      key: rotate2,
                      angle: -0.3, // radians
                      child: CompositedTransformFollower(
                        link: link,
                        child: Container(key: key2, height: 10.0, width: 10.0, color: const Color.fromARGB(128, 0, 255, 0)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      final RenderBox box1 = key1.currentContext!.findRenderObject()! as RenderBox;
      final RenderBox box2 = key2.currentContext!.findRenderObject()! as RenderBox;
      // Snapshot the positions of the two relevant boxes to ensure that taking
      // screenshots doesn't impact their positions.
      final Offset position1 = box1.localToGlobal(Offset.zero);
      final Offset position2 = box2.localToGlobal(Offset.zero);
      expect(position1.dx, moreOrLessEquals(position2.dx));
      expect(position1.dy, moreOrLessEquals(position2.dy));

      // Image of the full scene to use as reference to help validate that the
      // screenshots of specific subtrees are reasonable.
      await expectLater(
        find.byKey(mainStackKey),
        matchesGoldenFile('inspector.composited_transform.with_rotations.png'),
      );

      await expectLater(
        WidgetInspectorService.instance.screenshot(
          find.byKey(mainStackKey).evaluate().first,
          width: 500.0,
          height: 500.0,
        ),
        matchesGoldenFile('inspector.composited_transform.with_rotations_small.png'),
      );

      await expectLater(
        WidgetInspectorService.instance.screenshot(
          find.byKey(stackWithTransformTarget).evaluate().first,
          width: 500.0,
          height: 500.0,
        ),
        matchesGoldenFile('inspector.composited_transform.with_rotations_target.png'),
      );

      await expectLater(
        WidgetInspectorService.instance.screenshot(
          find.byKey(stackWithTransformFollower).evaluate().first,
          width: 500.0,
          height: 500.0,
        ),
        matchesGoldenFile('inspector.composited_transform.with_rotations_follower.png'),
      );

      // Make sure taking screenshots hasn't modified the positions of the
      // TransformTarget or TransformFollower layers.
      expect(identical(key1.currentContext!.findRenderObject(), box1), isTrue);
      expect(identical(key2.currentContext!.findRenderObject(), box2), isTrue);
      expect(box1.localToGlobal(Offset.zero), equals(position1));
      expect(box2.localToGlobal(Offset.zero), equals(position2));
    });

    testWidgets('getChildrenDetailsSubtree', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          title: 'Hello, World',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Hello, World'),
            ),
            body: const Center(
              child: Text('Hello, World!'),
            ),
          ),
        ),
      );
      service.setSelection(find.text('Hello, World!').evaluate().first, 'my-group');

      // Figure out the pubRootDirectory
      final Map<String, Object?> jsonObject = (await service.testExtension(
          'getSelectedWidget',
          <String, String>{'objectGroup': 'my-group'},
      ))! as Map<String, Object?>;
      final Map<String, Object?> creationLocation = jsonObject['creationLocation']! as Map<String, Object?>;
      expect(creationLocation, isNotNull);
      final String file = creationLocation['file']! as String;
      expect(file, endsWith('widget_inspector_test.dart'));
      final List<String> segments = Uri.parse(file).pathSegments;
      // Strip a couple subdirectories away to generate a plausible pub rootdirectory.
      final String pubRootTest = '/${segments.take(segments.length - 2).join('/')}';
      service.setPubRootDirectories(<String>[pubRootTest]);

      final String summary = service.getRootWidgetSummaryTree('foo1');
      // ignore: avoid_dynamic_calls
      final List<Object?> childrenOfRoot = json.decode(summary)['children'] as List<Object?>;
      final List<Object?> childrenOfMaterialApp = (childrenOfRoot.first! as Map<String, Object?>)['children']! as List<Object?>;
      final Map<String, Object?> scaffold = childrenOfMaterialApp.first! as Map<String, Object?>;
      expect(scaffold['description'], 'Scaffold');
      final String objectId = scaffold['objectId']! as String;
      final String details = service.getDetailsSubtree(objectId, 'foo2');
      // ignore: avoid_dynamic_calls
      final List<Object?> detailedChildren = json.decode(details)['children'] as List<Object?>;

      final List<Map<String, Object?>> appBars = <Map<String, Object?>>[];
      void visitChildren(List<Object?> children) {
        for (final Map<String, Object?> child in children.cast<Map<String, Object?>>()) {
          if (child['description'] == 'AppBar') {
            appBars.add(child);
          }
          if (child.containsKey('children')) {
            visitChildren(child['children']! as List<Object?>);
          }
        }
      }
      visitChildren(detailedChildren);
      expect(appBars.single, isNot(contains('children')));
    }, skip: !WidgetInspectorService.instance.isWidgetCreationTracked()); // [intended] Test requires --track-widget-creation flag.

    testWidgets('InspectorSerializationDelegate addAdditionalPropertiesCallback', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          title: 'Hello World!',
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Hello World!'),
            ),
            body: Center(
              child: Column(
                children: const <Widget>[
                  Text('Hello World!'),
                ],
              ),
            ),
          ),
        ),
      );
      final Finder columnWidgetFinder = find.byType(Column);
      expect(columnWidgetFinder, findsOneWidget);
      final Element columnWidgetElement = columnWidgetFinder
        .evaluate()
        .first;
      final DiagnosticsNode node = columnWidgetElement.toDiagnosticsNode();
      final InspectorSerializationDelegate delegate =
        InspectorSerializationDelegate(
          service: service,
          summaryTree: false,
          includeProperties: true,
          addAdditionalPropertiesCallback:
            (DiagnosticsNode node, InspectorSerializationDelegate delegate) {
              final Map<String, Object> additionalJson = <String, Object>{};
              final Object? value = node.value;
              if (value is Element) {
                final RenderObject? renderObject = value.renderObject;
                if (renderObject != null) {
                  additionalJson['renderObject'] =
                      renderObject.toDiagnosticsNode().toJsonMap(
                        delegate.copyWith(subtreeDepth: 0),
                      );
                }
              }
              additionalJson['callbackExecuted'] = true;
              return additionalJson;
            },
        );
      final Map<String, Object?> json = node.toJsonMap(delegate);
      expect(json['callbackExecuted'], true);
      expect(json.containsKey('renderObject'), true);
      expect(json['renderObject'], isA<Map<String, Object?>>());
      final Map<String, Object?> renderObjectJson = json['renderObject']! as Map<String, Object?>;
      expect(renderObjectJson['description'], startsWith('RenderFlex'));

      final InspectorSerializationDelegate emptyDelegate =
        InspectorSerializationDelegate(
          service: service,
          summaryTree: false,
          includeProperties: true,
          addAdditionalPropertiesCallback:
            (DiagnosticsNode node, InspectorSerializationDelegate delegate) {
              return null;
            },
        );
      final InspectorSerializationDelegate defaultDelegate =
        InspectorSerializationDelegate(
          service: service,
          summaryTree: false,
          includeProperties: true,
          addAdditionalPropertiesCallback: null,
        );
      expect(node.toJsonMap(emptyDelegate), node.toJsonMap(defaultDelegate));
    });

    testWidgets('debugIsLocalCreationLocation test', (WidgetTester tester) async {
      setupDefaultPubRootDirectory(service);

      final GlobalKey key = GlobalKey();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Text('target', key: key, textDirection: TextDirection.ltr),
          ),
        ),
      );

      final Element element = key.currentContext! as Element;

      expect(debugIsLocalCreationLocation(element), isTrue);
      expect(debugIsLocalCreationLocation(element.widget), isTrue);

      // Padding is inside container
      final Finder paddingFinder = find.byType(Padding);

      final Element paddingElement = paddingFinder.evaluate().first;

      expect(debugIsLocalCreationLocation(paddingElement), isFalse);
      expect(debugIsLocalCreationLocation(paddingElement.widget), isFalse);
    }, skip: !WidgetInspectorService.instance.isWidgetCreationTracked()); // [intended] Test requires --track-widget-creation flag.

    test('devToolsInspectorUri test', () {
      activeDevToolsServerAddress = 'http://127.0.0.1:9100';
      connectedVmServiceUri = 'http://127.0.0.1:55269/798ay5al_FM=/';
      expect(
        WidgetInspectorService.instance.devToolsInspectorUri('inspector-0'),
        equals('http://127.0.0.1:9100/#/inspector?uri=http%3A%2F%2F127.0.0.1%3A55269%2F798ay5al_FM%3D%2F&inspectorRef=inspector-0'),
      );
    });

    test('DevToolsDeepLinkProperty test', () {
      final DevToolsDeepLinkProperty node =
      DevToolsDeepLinkProperty(
        'description of the deep link',
        'http://the-deeplink/',
      );
      expect(node.toString(), equals('description of the deep link'));
      expect(node.name, isEmpty);
      expect(node.value, equals('http://the-deeplink/'));
      expect(
        node.toJsonMap(const DiagnosticsSerializationDelegate()),
        equals(<String, dynamic>{
          'description': 'description of the deep link',
          'type': 'DevToolsDeepLinkProperty',
          'name': '',
          'style': 'singleLine',
          'allowNameWrap': true,
          'missingIfNull': false,
          'propertyType': 'String',
          'defaultLevel': 'info',
          'value': 'http://the-deeplink/',
        }),
      );
    });
  }

  static void setupDefaultPubRootDirectory(TestWidgetInspectorService service) {
    final Map<String, Object?> jsonObject = const SizedBox().toDiagnosticsNode().toJsonMap(InspectorSerializationDelegate(service: service));
    final Map<String, Object?> creationLocation = jsonObject['creationLocation']! as Map<String, Object?>;
    expect(creationLocation, isNotNull);
    final String file = creationLocation['file']! as String;
    expect(file, endsWith('widget_inspector_test.dart'));
    final List<String> segments = Uri
        .parse(file)
        .pathSegments;
    final String pubRootTest = '/${segments.take(segments.length - 2).join('/')}';

    // Strip a couple subdirectories away to generate a plausible pub root
    // directory.
    service.setPubRootDirectories(<String>[pubRootTest]);
  }
}

void _addToKnownLocationsMap({
  required Map<int, _CreationLocation> knownLocations,
  required Map<String, Map<String, List<Object?>>> newLocations,
}) {
  newLocations.forEach((String file, Map<String, List<Object?>> entries) {
    final List<int> ids = entries['ids']!.cast<int>();
    final List<int> lines = entries['lines']!.cast<int>();
    final List<int> columns = entries['columns']!.cast<int>();
    final List<String> names = entries['names']!.cast<String>();

    for (int i = 0; i < ids.length; i++) {
      final int id = ids[i];
      knownLocations[id] = _CreationLocation(
        id: id,
        file: file,
        line: lines[i],
        column: columns[i],
        name: names[i],
      );
    }
  });
}
