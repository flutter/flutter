// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

typedef FutureOr<Map<String, Object>> InspectorServiceExtensionCallback(Map<String, String> parameters);

void main() {
  TestWidgetInspectorService.runTests();
}

class TestWidgetInspectorService extends Object with WidgetInspectorService {
  final Map<String, InspectorServiceExtensionCallback> extensions = <String, InspectorServiceExtensionCallback>{};

  @override
  void registerServiceExtension({
    @required String name,
    @required FutureOr<Map<String, Object>> callback(Map<String, String> parameters),
  }) {
    assert(!extensions.containsKey(name));
    extensions[name] = callback;
  }

  Future<Object> testExtension(String name, Map<String, String> arguments) async {
    expect(extensions.containsKey(name), isTrue);
    // Encode and decode to JSON to match behavior using a real service
    // extension where only JSON is allowed.
    return json.decode(json.encode(await extensions[name](arguments)))['result'];
  }

  Future<String> testBoolExtension(String name, Map<String, String> arguments) async {
    expect(extensions.containsKey(name), isTrue);
    // Encode and decode to JSON to match behavior using a real service
    // extension where only JSON is allowed.
    return json.decode(json.encode(await extensions[name](arguments)))['enabled'];
  }

  int rebuildCount = 0;

  @override
  Future<Null> forceRebuild() async {
    rebuildCount++;
    return null;
  }


  // These tests need access to protected members of WidgetInspectorService.
  static void runTests() {
    final TestWidgetInspectorService service = new TestWidgetInspectorService();
    WidgetInspectorService.instance = service;

    testWidgets('WidgetInspector smoke test', (WidgetTester tester) async {
      // This is a smoke test to verify that adding the inspector doesn't crash.
      await tester.pumpWidget(
        new Directionality(
          textDirection: TextDirection.ltr,
          child: new Stack(
            children: const <Widget>[
              const Text('a', textDirection: TextDirection.ltr),
              const Text('b', textDirection: TextDirection.ltr),
              const Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );

      await tester.pumpWidget(
        new Directionality(
          textDirection: TextDirection.ltr,
          child: new WidgetInspector(
            selectButtonBuilder: null,
            child: new Stack(
              children: const <Widget>[
                const Text('a', textDirection: TextDirection.ltr),
                const Text('b', textDirection: TextDirection.ltr),
                const Text('c', textDirection: TextDirection.ltr),
              ],
            ),
          ),
        ),
      );

      expect(true, isTrue); // Expect that we reach here without crashing.
    });

    testWidgets('WidgetInspector interaction test', (WidgetTester tester) async {
      final List<String> log = <String>[];
      final GlobalKey selectButtonKey = new GlobalKey();
      final GlobalKey inspectorKey = new GlobalKey();
      final GlobalKey topButtonKey = new GlobalKey();

      Widget selectButtonBuilder(BuildContext context, VoidCallback onPressed) {
        return new Material(child: new RaisedButton(onPressed: onPressed, key: selectButtonKey));
      }
      // State type is private, hence using dynamic.
      dynamic getInspectorState() => inspectorKey.currentState;
      String paragraphText(RenderParagraph paragraph) => paragraph.text.text;

      await tester.pumpWidget(
        new Directionality(
          textDirection: TextDirection.ltr,
          child: new WidgetInspector(
            key: inspectorKey,
            selectButtonBuilder: selectButtonBuilder,
            child: new Material(
              child: new ListView(
                children: <Widget>[
                  new RaisedButton(
                    key: topButtonKey,
                    onPressed: () {
                      log.add('top');
                    },
                    child: const Text('TOP'),
                  ),
                  new RaisedButton(
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

      expect(getInspectorState().selection.current, isNull);
      await tester.tap(find.text('TOP'));
      await tester.pump();
      // Tap intercepted by the inspector
      expect(log, equals(<String>[]));
      final InspectorSelection selection = getInspectorState().selection;
      expect(paragraphText(selection.current), equals('TOP'));
      final RenderObject topButton = find.byKey(topButtonKey).evaluate().first.renderObject;
      expect(selection.candidates.contains(topButton), isTrue);

      await tester.tap(find.text('TOP'));
      expect(log, equals(<String>['top']));
      log.clear();

      await tester.tap(find.text('BOTTOM'));
      expect(log, equals(<String>['bottom']));
      log.clear();
      // Ensure the inspector selection has not changed to bottom.
      expect(paragraphText(getInspectorState().selection.current), equals('TOP'));

      await tester.tap(find.byKey(selectButtonKey));
      await tester.pump();

      // We are now back in select mode so tapping the bottom button will have
      // not trigger a click but will cause it to be selected.
      await tester.tap(find.text('BOTTOM'));
      expect(log, equals(<String>[]));
      log.clear();
      expect(paragraphText(getInspectorState().selection.current), equals('BOTTOM'));
    });

    testWidgets('WidgetInspector non-invertible transform regression test', (WidgetTester tester) async {
      await tester.pumpWidget(
        new Directionality(
          textDirection: TextDirection.ltr,
          child: new WidgetInspector(
            selectButtonBuilder: null,
            child: new Transform(
              transform: new Matrix4.identity()..scale(0.0),
              child: new Stack(
                children: const <Widget>[
                  const Text('a', textDirection: TextDirection.ltr),
                  const Text('b', textDirection: TextDirection.ltr),
                  const Text('c', textDirection: TextDirection.ltr),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Transform));

      expect(true, isTrue); // Expect that we reach here without crashing.
    });

    testWidgets('WidgetInspector scroll test', (WidgetTester tester) async {
      final Key childKey = new UniqueKey();
      final GlobalKey selectButtonKey = new GlobalKey();
      final GlobalKey inspectorKey = new GlobalKey();

      Widget selectButtonBuilder(BuildContext context, VoidCallback onPressed) {
        return new Material(child: new RaisedButton(onPressed: onPressed, key: selectButtonKey));
      }
      // State type is private, hence using dynamic.
      dynamic getInspectorState() => inspectorKey.currentState;

      await tester.pumpWidget(
        new Directionality(
          textDirection: TextDirection.ltr,
          child: new WidgetInspector(
            key: inspectorKey,
            selectButtonBuilder: selectButtonBuilder,
            child: new ListView(
              children: <Widget>[
                new Container(
                  key: childKey,
                  height: 5000.0,
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.getTopLeft(find.byKey(childKey)).dy, equals(0.0));

      await tester.fling(find.byType(ListView), const Offset(0.0, -200.0), 200.0);
      await tester.pump();

      // Fling does nothing as are in inspect mode.
      expect(tester.getTopLeft(find.byKey(childKey)).dy, equals(0.0));

      await tester.fling(find.byType(ListView), const Offset(200.0, 0.0), 200.0);
      await tester.pump();

      // Fling still does nothing as are in inspect mode.
      expect(tester.getTopLeft(find.byKey(childKey)).dy, equals(0.0));

      await tester.tap(find.byType(ListView));
      await tester.pump();
      expect(getInspectorState().selection.current, isNotNull);

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
        new Directionality(
          textDirection: TextDirection.ltr,
          child: new WidgetInspector(
            selectButtonBuilder: null,
            child: new GestureDetector(
              onLongPress: () {
                expect(didLongPress, isFalse);
                didLongPress = true;
              },
              child: const Text('target', textDirection: TextDirection.ltr),
            ),
          ),
        ),
      );

      await tester.longPress(find.text('target'));
      // The inspector will swallow the long press.
      expect(didLongPress, isFalse);
    });

    testWidgets('WidgetInspector offstage', (WidgetTester tester) async {
      final GlobalKey inspectorKey = new GlobalKey();
      final GlobalKey clickTarget = new GlobalKey();

      Widget createSubtree({ double width, Key key }) {
        return new Stack(
          children: <Widget>[
            new Positioned(
              key: key,
              left: 0.0,
              top: 0.0,
              width: width,
              height: 100.0,
              child: new Text(width.toString(), textDirection: TextDirection.ltr),
            ),
          ],
        );
      }
      await tester.pumpWidget(
        new Directionality(
          textDirection: TextDirection.ltr,
          child: new WidgetInspector(
            key: inspectorKey,
            selectButtonBuilder: null,
            child: new Overlay(
              initialEntries: <OverlayEntry>[
                new OverlayEntry(
                  opaque: false,
                  maintainState: true,
                  builder: (BuildContext _) => createSubtree(width: 94.0),
                ),
                new OverlayEntry(
                  opaque: true,
                  maintainState: true,
                  builder: (BuildContext _) => createSubtree(width: 95.0),
                ),
                new OverlayEntry(
                  opaque: false,
                  maintainState: true,
                  builder: (BuildContext _) => createSubtree(width: 96.0, key: clickTarget),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.longPress(find.byKey(clickTarget));
      // State type is private, hence using dynamic.
      final dynamic inspectorState = inspectorKey.currentState;
      // The object with width 95.0 wins over the object with width 94.0 because
      // the subtree with width 94.0 is offstage.
      expect(inspectorState.selection.current.semanticBounds.width, equals(95.0));

      // Exactly 2 out of the 3 text elements should be in the candidate list of
      // objects to select as only 2 are onstage.
      expect(inspectorState.selection.candidates.where((RenderObject object) => object is RenderParagraph).length, equals(2));
    });

    test('WidgetInspectorService null id', () {
      service.disposeAllGroups();
      expect(service.toObject(null), isNull);
      expect(service.toId(null, 'test-group'), isNull);
    });

    test('WidgetInspectorService dispose group', () {
      service.disposeAllGroups();
      final Object a = new Object();
      const String group1 = 'group-1';
      const String group2 = 'group-2';
      const String group3 = 'group-3';
      final String aId = service.toId(a, group1);
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
      final Object a = new Object();
      final Object b = new Object();
      const String group1 = 'group-1';
      const String group2 = 'group-2';
      final String aId = service.toId(a, group1);
      final String bId = service.toId(b, group1);
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
      const Text widget = const Text('a', textDirection: TextDirection.ltr);
      service.disposeAllGroups();
      final String id = service.toId(widget, group);
      expect(service.toObjectForSourceLocation(id), equals(widget));
      final Element element = widget.createElement();
      final String elementId = service.toId(element, group);
      expect(service.toObjectForSourceLocation(elementId), equals(widget));
      expect(element, isNot(equals(widget)));
      service.disposeGroup(group);
      expect(() => service.toObjectForSourceLocation(elementId), throwsFlutterError);
    });

    test('WidgetInspectorService object id test', () {
      const Text a = const Text('a', textDirection: TextDirection.ltr);
      const Text b = const Text('b', textDirection: TextDirection.ltr);
      const Text c = const Text('c', textDirection: TextDirection.ltr);
      const Text d = const Text('d', textDirection: TextDirection.ltr);

      const String group1 = 'group-1';
      const String group2 = 'group-2';
      const String group3 = 'group-3';
      service.disposeAllGroups();

      final String aId = service.toId(a, group1);
      final String bId = service.toId(b, group2);
      final String cId = service.toId(c, group3);
      final String dId = service.toId(d, group1);
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
        new Directionality(
          textDirection: TextDirection.ltr,
          child: new Stack(
            children: const <Widget>[
              const Text('a', textDirection: TextDirection.ltr),
              const Text('b', textDirection: TextDirection.ltr),
              const Text('c', textDirection: TextDirection.ltr),
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
      expect(service.selection.currentElement, equals(elementB.renderObject.debugCreator.element));

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

    testWidgets('WidgetInspectorService getParentChain', (WidgetTester tester) async {
      const String group = 'test-group';

      await tester.pumpWidget(
        new Directionality(
          textDirection: TextDirection.ltr,
          child: new Stack(
            children: const <Widget>[
              const Text('a', textDirection: TextDirection.ltr),
              const Text('b', textDirection: TextDirection.ltr),
              const Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );

      service.disposeAllGroups();
      final Element elementB = find.text('b').evaluate().first;
      final String bId = service.toId(elementB, group);
      final Object jsonList = json.decode(service.getParentChain(bId, group));
      expect(jsonList, isList);
      final List<Object> chainElements = jsonList;
      final List<Element> expectedChain = elementB.debugGetDiagnosticChain()?.reversed?.toList();
      // Sanity check that the chain goes back to the root.
      expect(expectedChain.first, tester.binding.renderViewElement);

      expect(chainElements.length, equals(expectedChain.length));
      for (int i = 0; i < expectedChain.length; i += 1) {
        expect(chainElements[i], isMap);
        final Map<String, Object> chainNode = chainElements[i];
        final Element element = expectedChain[i];
        expect(chainNode['node'], isMap);
        final Map<String, Object> jsonNode = chainNode['node'];
        expect(service.toObject(jsonNode['valueId']), equals(element));
        expect(service.toObject(jsonNode['objectId']), const isInstanceOf<DiagnosticsNode>());

        expect(chainNode['children'], isList);
        final List<Object> jsonChildren = chainNode['children'];
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
          final Map<String, Object> childJson = jsonChildren[j];
          expect(service.toObject(childJson['valueId']), equals(childrenElements[j]));
          expect(service.toObject(childJson['objectId']), const isInstanceOf<DiagnosticsNode>());
        }
      }
    });

    test('WidgetInspectorService getProperties', () {
      final DiagnosticsNode diagnostic = const Text('a', textDirection: TextDirection.ltr).toDiagnosticsNode();
      const String group = 'group';
      service.disposeAllGroups();
      final String id = service.toId(diagnostic, group);
      final List<Object> propertiesJson = json.decode(service.getProperties(id, group));
      final List<DiagnosticsNode> properties = diagnostic.getProperties();
      expect(properties, isNotEmpty);
      expect(propertiesJson.length, equals(properties.length));
      for (int i = 0; i < propertiesJson.length; ++i) {
        final Map<String, Object> propertyJson = propertiesJson[i];
        expect(service.toObject(propertyJson['valueId']), equals(properties[i].value));
        expect(service.toObject(propertyJson['objectId']), const isInstanceOf<DiagnosticsNode>());
      }
    });

    testWidgets('WidgetInspectorService getChildren', (WidgetTester tester) async {
      const String group = 'test-group';

      await tester.pumpWidget(
        new Directionality(
          textDirection: TextDirection.ltr,
          child: new Stack(
            children: const <Widget>[
              const Text('a', textDirection: TextDirection.ltr),
              const Text('b', textDirection: TextDirection.ltr),
              const Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final DiagnosticsNode diagnostic = find.byType(Stack).evaluate().first.toDiagnosticsNode();
      service.disposeAllGroups();
      final String id = service.toId(diagnostic, group);
      final List<Object> propertiesJson = json.decode(service.getChildren(id, group));
      final List<DiagnosticsNode> children = diagnostic.getChildren();
      expect(children.length, equals(3));
      expect(propertiesJson.length, equals(children.length));
      for (int i = 0; i < propertiesJson.length; ++i) {
        final Map<String, Object> propertyJson = propertiesJson[i];
        expect(service.toObject(propertyJson['valueId']), equals(children[i].value));
        expect(service.toObject(propertyJson['objectId']), const isInstanceOf<DiagnosticsNode>());
      }
    });

    testWidgets('WidgetInspectorService creationLocation', (WidgetTester tester) async {
      await tester.pumpWidget(
        new Directionality(
          textDirection: TextDirection.ltr,
          child: new Stack(
            children: const <Widget>[
              const Text('a'),
              const Text('b', textDirection: TextDirection.ltr),
              const Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final Element elementA = find.text('a').evaluate().first;
      final Element elementB = find.text('b').evaluate().first;

      service.disposeAllGroups();
      service.setPubRootDirectories(<Object>[]);
      service.setSelection(elementA, 'my-group');
      final Map<String, Object> jsonA = json.decode(service.getSelectedWidget(null, 'my-group'));
      final Map<String, Object> creationLocationA = jsonA['creationLocation'];
      expect(creationLocationA, isNotNull);
      final String fileA = creationLocationA['file'];
      final int lineA = creationLocationA['line'];
      final int columnA = creationLocationA['column'];
      final List<Object> parameterLocationsA = creationLocationA['parameterLocations'];

      service.setSelection(elementB, 'my-group');
      final Map<String, Object> jsonB = json.decode(service.getSelectedWidget(null, 'my-group'));
      final Map<String, Object> creationLocationB = jsonB['creationLocation'];
      expect(creationLocationB, isNotNull);
      final String fileB = creationLocationB['file'];
      final int lineB = creationLocationB['line'];
      final int columnB = creationLocationB['column'];
      final List<Object> parameterLocationsB = creationLocationB['parameterLocations'];
      expect(fileA, endsWith('widget_inspector_test.dart'));
      expect(fileA, equals(fileB));
      // We don't hardcode the actual lines the widgets are created on as that
      // would make this test fragile.
      expect(lineA + 1, equals(lineB));
      // Column numbers are more stable than line numbers.
      expect(columnA, equals(21));
      expect(columnA, equals(columnB));
      expect(parameterLocationsA.length, equals(1));
      final Map<String, Object> paramA = parameterLocationsA[0];
      expect(paramA['name'], equals('data'));
      expect(paramA['line'], equals(lineA));
      expect(paramA['column'], equals(26));

      expect(parameterLocationsB.length, equals(2));
      final Map<String, Object> paramB1 = parameterLocationsB[0];
      expect(paramB1['name'], equals('data'));
      expect(paramB1['line'], equals(lineB));
      expect(paramB1['column'], equals(26));
      final Map<String, Object> paramB2 = parameterLocationsB[1];
      expect(paramB2['name'], equals('textDirection'));
      expect(paramB2['line'], equals(lineB));
      expect(paramB2['column'], equals(31));
    }, skip: !WidgetInspectorService.instance.isWidgetCreationTracked()); // Test requires --track-widget-creation flag.

    testWidgets('WidgetInspectorService setPubRootDirectories', (WidgetTester tester) async {
      await tester.pumpWidget(
        new Directionality(
          textDirection: TextDirection.ltr,
          child: new Stack(
            children: const <Widget>[
              const Text('a'),
              const Text('b', textDirection: TextDirection.ltr),
              const Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final Element elementA = find.text('a').evaluate().first;

      service.disposeAllGroups();
      service.setPubRootDirectories(<Object>[]);
      service.setSelection(elementA, 'my-group');
      Map<String, Object> jsonObject = json.decode(service.getSelectedWidget(null, 'my-group'));
      Map<String, Object> creationLocation = jsonObject['creationLocation'];
      expect(creationLocation, isNotNull);
      final String fileA = creationLocation['file'];
      expect(fileA, endsWith('widget_inspector_test.dart'));
      expect(jsonObject, isNot(contains('createdByLocalProject')));
      final List<String> segments = Uri.parse(fileA).pathSegments;
      // Strip a couple subdirectories away to generate a plausible pub root
      // directory.
      final String pubRootTest = '/' + segments.take(segments.length - 2).join('/');
      service.setPubRootDirectories(<Object>[pubRootTest]);

      service.setSelection(elementA, 'my-group');
      expect(json.decode(service.getSelectedWidget(null, 'my-group')), contains('createdByLocalProject'));

      service.setPubRootDirectories(<Object>['/invalid/$pubRootTest']);
      expect(json.decode(service.getSelectedWidget(null, 'my-group')), isNot(contains('createdByLocalProject')));

      service.setPubRootDirectories(<Object>['file://$pubRootTest']);
      expect(json.decode(service.getSelectedWidget(null, 'my-group')), contains('createdByLocalProject'));

      service.setPubRootDirectories(<Object>['$pubRootTest/different']);
      expect(json.decode(service.getSelectedWidget(null, 'my-group')), isNot(contains('createdByLocalProject')));

      service.setPubRootDirectories(<Object>[
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
      service.setPubRootDirectories(<Object>[pubRootTest]);
      jsonObject = json.decode(service.getSelectedWidget(null, 'my-group'));
      expect(jsonObject, isNot(contains('createdByLocalProject')));
      creationLocation = jsonObject['creationLocation'];
      expect(creationLocation, isNotNull);
      // This RichText widget is created by the build method of the Text widget
      // thus the creation location is in text.dart not basic.dart
      final List<String> pathSegmentsFramework = Uri.parse(creationLocation['file']).pathSegments;
      expect(pathSegmentsFramework.join('/'), endsWith('/packages/flutter/lib/src/widgets/text.dart'));

      // Strip off /src/widgets/text.dart.
      final String pubRootFramework = '/' + pathSegmentsFramework.take(pathSegmentsFramework.length - 3).join('/');
      service.setPubRootDirectories(<Object>[pubRootFramework]);
      expect(json.decode(service.getSelectedWidget(null, 'my-group')), contains('createdByLocalProject'));
      service.setSelection(elementA, 'my-group');
      expect(json.decode(service.getSelectedWidget(null, 'my-group')), isNot(contains('createdByLocalProject')));

      service.setPubRootDirectories(<Object>[pubRootFramework, pubRootTest]);
      service.setSelection(elementA, 'my-group');
      expect(json.decode(service.getSelectedWidget(null, 'my-group')), contains('createdByLocalProject'));
      service.setSelection(richText, 'my-group');
      expect(json.decode(service.getSelectedWidget(null, 'my-group')), contains('createdByLocalProject'));
    }, skip: !WidgetInspectorService.instance.isWidgetCreationTracked()); // Test requires --track-widget-creation flag.

    test('ext.flutter.inspector.disposeGroup', () async {
      final Object a = new Object();
      const String group1 = 'group-1';
      const String group2 = 'group-2';
      const String group3 = 'group-3';
      final String aId = service.toId(a, group1);
      expect(service.toId(a, group2), equals(aId));
      expect(service.toId(a, group3), equals(aId));
      await service.testExtension('disposeGroup', <String, String>{'objectGroup': group1});
      await service.testExtension('disposeGroup', <String, String>{'objectGroup': group2});
      expect(service.toObject(aId), equals(a));
      await service.testExtension('disposeGroup', <String, String>{'objectGroup': group3});
      expect(() => service.toObject(aId), throwsFlutterError);
    });

    test('ext.flutter.inspector.disposeId', () async {
      final Object a = new Object();
      final Object b = new Object();
      const String group1 = 'group-1';
      const String group2 = 'group-2';
      final String aId = service.toId(a, group1);
      final String bId = service.toId(b, group1);
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
        new Directionality(
          textDirection: TextDirection.ltr,
          child: new Stack(
            children: const <Widget>[
              const Text('a', textDirection: TextDirection.ltr),
              const Text('b', textDirection: TextDirection.ltr),
              const Text('c', textDirection: TextDirection.ltr),
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
      expect(service.selection.currentElement, equals(elementB.renderObject.debugCreator.element));

      service.setSelection('invalid selection');
      expect(selectionChangedCount, equals(2));
      expect(service.selection.current, equals(elementB.renderObject));

      await service.testExtension('setSelectionById', <String, String>{'arg' : service.toId(elementA, 'my-group'), 'objectGroup': 'my-group'});
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
        new Directionality(
          textDirection: TextDirection.ltr,
          child: new Stack(
            children: const <Widget>[
              const Text('a', textDirection: TextDirection.ltr),
              const Text('b', textDirection: TextDirection.ltr),
              const Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );

      final Element elementB = find.text('b').evaluate().first;
      final String bId = service.toId(elementB, group);
      final Object jsonList = await service.testExtension('getParentChain', <String, String>{'arg': bId, 'objectGroup': group});
      expect(jsonList, isList);
      final List<Object> chainElements = jsonList;
      final List<Element> expectedChain = elementB.debugGetDiagnosticChain()?.reversed?.toList();
      // Sanity check that the chain goes back to the root.
      expect(expectedChain.first, tester.binding.renderViewElement);

      expect(chainElements.length, equals(expectedChain.length));
      for (int i = 0; i < expectedChain.length; i += 1) {
        expect(chainElements[i], isMap);
        final Map<String, Object> chainNode = chainElements[i];
        final Element element = expectedChain[i];
        expect(chainNode['node'], isMap);
        final Map<String, Object> jsonNode = chainNode['node'];
        expect(service.toObject(jsonNode['valueId']), equals(element));
        expect(service.toObject(jsonNode['objectId']), const isInstanceOf<DiagnosticsNode>());

        expect(chainNode['children'], isList);
        final List<Object> jsonChildren = chainNode['children'];
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
          final Map<String, Object> childJson = jsonChildren[j];
          expect(service.toObject(childJson['valueId']), equals(childrenElements[j]));
          expect(service.toObject(childJson['objectId']), const isInstanceOf<DiagnosticsNode>());
        }
      }
    });

    test('ext.flutter.inspector.getProperties', () async {
      final DiagnosticsNode diagnostic = const Text('a', textDirection: TextDirection.ltr).toDiagnosticsNode();
      const String group = 'group';
      final String id = service.toId(diagnostic, group);
      final List<Object> propertiesJson = await service.testExtension('getProperties', <String, String>{'arg': id, 'objectGroup': group});
      final List<DiagnosticsNode> properties = diagnostic.getProperties();
      expect(properties, isNotEmpty);
      expect(propertiesJson.length, equals(properties.length));
      for (int i = 0; i < propertiesJson.length; ++i) {
        final Map<String, Object> propertyJson = propertiesJson[i];
        expect(service.toObject(propertyJson['valueId']), equals(properties[i].value));
        expect(service.toObject(propertyJson['objectId']), const isInstanceOf<DiagnosticsNode>());
      }
    });

    testWidgets('ext.flutter.inspector.getChildren', (WidgetTester tester) async {
      const String group = 'test-group';

      await tester.pumpWidget(
        new Directionality(
          textDirection: TextDirection.ltr,
          child: new Stack(
            children: const <Widget>[
              const Text('a', textDirection: TextDirection.ltr),
              const Text('b', textDirection: TextDirection.ltr),
              const Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final DiagnosticsNode diagnostic = find.byType(Stack).evaluate().first.toDiagnosticsNode();
      final String id = service.toId(diagnostic, group);
      final List<Object> propertiesJson = await service.testExtension('getChildren', <String, String>{'arg': id, 'objectGroup': group});
      final List<DiagnosticsNode> children = diagnostic.getChildren();
      expect(children.length, equals(3));
      expect(propertiesJson.length, equals(children.length));
      for (int i = 0; i < propertiesJson.length; ++i) {
        final Map<String, Object> propertyJson = propertiesJson[i];
        expect(service.toObject(propertyJson['valueId']), equals(children[i].value));
        expect(service.toObject(propertyJson['objectId']), const isInstanceOf<DiagnosticsNode>());
      }
    });

    testWidgets('ext.flutter.inspector.getChildrenDetailsSubtree', (WidgetTester tester) async {
      const String group = 'test-group';

      await tester.pumpWidget(
        new Directionality(
          textDirection: TextDirection.ltr,
          child: new Stack(
            children: const <Widget>[
              const Text('a', textDirection: TextDirection.ltr),
              const Text('b', textDirection: TextDirection.ltr),
              const Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final DiagnosticsNode diagnostic = find.byType(Stack).evaluate().first.toDiagnosticsNode();
      final String id = service.toId(diagnostic, group);
      final List<Object> childrenJson = await service.testExtension('getChildrenDetailsSubtree', <String, String>{'arg': id, 'objectGroup': group});
      final List<DiagnosticsNode> children = diagnostic.getChildren();
      expect(children.length, equals(3));
      expect(childrenJson.length, equals(children.length));
      for (int i = 0; i < childrenJson.length; ++i) {
        final Map<String, Object> childJson = childrenJson[i];
        expect(service.toObject(childJson['valueId']), equals(children[i].value));
        expect(service.toObject(childJson['objectId']), const isInstanceOf<DiagnosticsNode>());
        final List<Object> propertiesJson = childJson['properties'];
        final DiagnosticsNode diagnosticsNode = service.toObject(childJson['objectId']);
        final List<DiagnosticsNode> expectedProperties = diagnosticsNode.getProperties();
        for (Map<String, Object> propertyJson in propertiesJson) {
          final Object property = service.toObject(propertyJson['objectId']);
          expect(property, const isInstanceOf<DiagnosticsNode>());
          expect(expectedProperties.contains(property), isTrue);
        }
      }
    });

    testWidgets('WidgetInspectorService getDetailsSubtree', (WidgetTester tester) async {
      const String group = 'test-group';

      await tester.pumpWidget(
        new Directionality(
          textDirection: TextDirection.ltr,
          child: new Stack(
            children: const <Widget>[
              const Text('a', textDirection: TextDirection.ltr),
              const Text('b', textDirection: TextDirection.ltr),
              const Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final DiagnosticsNode diagnostic = find.byType(Stack).evaluate().first.toDiagnosticsNode();
      final String id = service.toId(diagnostic, group);
      final Map<String, Object> subtreeJson = await service.testExtension('getDetailsSubtree', <String, String>{'arg': id, 'objectGroup': group});
      expect(subtreeJson['objectId'], equals(id));
      final List<Object> childrenJson = subtreeJson['children'];
      final List<DiagnosticsNode> children = diagnostic.getChildren();
      expect(children.length, equals(3));
      expect(childrenJson.length, equals(children.length));
      for (int i = 0; i < childrenJson.length; ++i) {
        final Map<String, Object> childJson = childrenJson[i];
        expect(service.toObject(childJson['valueId']), equals(children[i].value));
        expect(service.toObject(childJson['objectId']), const isInstanceOf<DiagnosticsNode>());
        final List<Object> propertiesJson = childJson['properties'];
        final DiagnosticsNode diagnosticsNode = service.toObject(childJson['objectId']);
        final List<DiagnosticsNode> expectedProperties = diagnosticsNode.getProperties();
        for (Map<String, Object> propertyJson in propertiesJson) {
          final Object property = service.toObject(propertyJson['objectId']);
          expect(property, const isInstanceOf<DiagnosticsNode>());
          expect(expectedProperties.contains(property), isTrue);
        }
      }
    });

    testWidgets('ext.flutter.inspector.getRootWidgetSummaryTree', (WidgetTester tester) async {
      const String group = 'test-group';

      await tester.pumpWidget(
        new Directionality(
          textDirection: TextDirection.ltr,
          child: new Stack(
            children: const <Widget>[
              const Text('a', textDirection: TextDirection.ltr),
              const Text('b', textDirection: TextDirection.ltr),
              const Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final Element elementA = find.text('a').evaluate().first;

      service.disposeAllGroups();
      await service.testExtension('setPubRootDirectories', <String, String>{});
      service.setSelection(elementA, 'my-group');
      final Map<String, Object> jsonA = await service.testExtension('getSelectedWidget', <String, String>{'arg': null, 'objectGroup': 'my-group'});

      await service.testExtension('setPubRootDirectories', <String, String>{});
      Map<String, Object> rootJson = await service.testExtension('getRootWidgetSummaryTree', <String, String>{'objectGroup': group});
      // We haven't yet properly specified which directories are summary tree
      // directories so we get an empty tree other than the root that is always
      // included.
      final Object rootWidget = service.toObject(rootJson['valueId']);
      expect(rootWidget, equals(WidgetsBinding.instance?.renderViewElement));
      List<Object> childrenJson = rootJson['children'];
      // There are no summary tree children.
      expect(childrenJson.length, equals(0));

      final Map<String, Object> creationLocation = jsonA['creationLocation'];
      expect(creationLocation, isNotNull);
      final String testFile = creationLocation['file'];
      expect(testFile, endsWith('widget_inspector_test.dart'));
      final List<String> segments = Uri.parse(testFile).pathSegments;
      // Strip a couple subdirectories away to generate a plausible pub root
      // directory.
      final String pubRootTest = '/' + segments.take(segments.length - 2).join('/');
      await service.testExtension('setPubRootDirectories', <String, String>{'arg0': pubRootTest});

      rootJson = await service.testExtension('getRootWidgetSummaryTree', <String, String>{'objectGroup': group});
      childrenJson = rootJson['children'];
      // The tree of nodes returned contains all widgets created directly by the
      // test.
      childrenJson = rootJson['children'];
      expect(childrenJson.length, equals(1));

      List<Object> alternateChildrenJson = await service.testExtension('getChildrenSummaryTree', <String, String>{'arg': rootJson['objectId'], 'objectGroup': group});
      expect(alternateChildrenJson.length, equals(1));
      Map<String, Object> childJson = childrenJson[0];
      Map<String, Object> alternateChildJson = alternateChildrenJson[0];
      expect(childJson['description'], startsWith('Directionality'));
      expect(alternateChildJson['description'], startsWith('Directionality'));
      expect(alternateChildJson['valueId'], equals(childJson['valueId']));

      childrenJson = childJson['children'];
      alternateChildrenJson = await service.testExtension('getChildrenSummaryTree', <String, String>{'arg': childJson['objectId'], 'objectGroup': group});
      expect(alternateChildrenJson.length, equals(1));
      expect(childrenJson.length, equals(1));
      alternateChildJson = alternateChildrenJson[0];
      childJson = childrenJson[0];
      expect(childJson['description'], startsWith('Stack'));
      expect(alternateChildJson['description'], startsWith('Stack'));
      expect(alternateChildJson['valueId'], equals(childJson['valueId']));
      childrenJson = childJson['children'];

      childrenJson = childJson['children'];
      alternateChildrenJson = await service.testExtension('getChildrenSummaryTree', <String, String>{'arg': childJson['objectId'], 'objectGroup': group});
      expect(alternateChildrenJson.length, equals(3));
      expect(childrenJson.length, equals(3));
      alternateChildJson = alternateChildrenJson[2];
      childJson = childrenJson[2];
      expect(childJson['description'], startsWith('Text'));
      expect(alternateChildJson['description'], startsWith('Text'));
      expect(alternateChildJson['valueId'], equals(childJson['valueId']));
      alternateChildrenJson = await service.testExtension('getChildrenSummaryTree', <String, String>{'arg': childJson['objectId'], 'objectGroup': group});
      expect(alternateChildrenJson.length , equals(0));
      expect(childJson['chidlren'], isNull);
    }, skip: !WidgetInspectorService.instance.isWidgetCreationTracked()); // Test requires --track-widget-creation flag.

    testWidgets('ext.flutter.inspector.getSelectedSummaryWidget', (WidgetTester tester) async {
      const String group = 'test-group';

      await tester.pumpWidget(
        new Directionality(
          textDirection: TextDirection.ltr,
          child: new Stack(
            children: const <Widget>[
              const Text('a', textDirection: TextDirection.ltr),
              const Text('b', textDirection: TextDirection.ltr),
              const Text('c', textDirection: TextDirection.ltr),
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
      final Map<String, Object> jsonA = await service.testExtension('getSelectedWidget', <String, String>{'arg': null, 'objectGroup': 'my-group'});
      service.setSelection(richTextDiagnostic.value, 'my-group');

      await service.testExtension('setPubRootDirectories', <String, String>{});
      Map<String, Object> summarySelection = await service.testExtension('getSelectedSummaryWidget', <String, String>{'objectGroup': group});
      // No summary selection because we haven't set the pub root directories
      // yet to indicate what directories are in the summary tree.
      expect(summarySelection, isNull);

      final Map<String, Object> creationLocation = jsonA['creationLocation'];
      expect(creationLocation, isNotNull);
      final String testFile = creationLocation['file'];
      expect(testFile, endsWith('widget_inspector_test.dart'));
      final List<String> segments = Uri.parse(testFile).pathSegments;
      // Strip a couple subdirectories away to generate a plausible pub root
      // directory.
      final String pubRootTest = '/' + segments.take(segments.length - 2).join('/');
      await service.testExtension('setPubRootDirectories', <String, String>{'arg0': pubRootTest});

      summarySelection = await service.testExtension('getSelectedSummaryWidget', <String, String>{'objectGroup': group});
      expect(summarySelection['valueId'], isNotNull);
      // We got the Text element instead of the selected RichText element
      // because only the RichText element is part of the summary tree.
      expect(service.toObject(summarySelection['valueId']), elementA);

      // Verify tha the regular getSelectedWidget method still returns
      // the RichText object not the Text element.
      final Map<String, Object> regularSelection = await service.testExtension('getSelectedWidget', <String, String>{'arg': null, 'objectGroup': 'my-group'});
      expect(service.toObject(regularSelection['valueId']), richTextDiagnostic.value);
   }, skip: !WidgetInspectorService.instance.isWidgetCreationTracked()); // Test requires --track-widget-creation flag.

    testWidgets('ext.flutter.inspector creationLocation', (WidgetTester tester) async {
      await tester.pumpWidget(
        new Directionality(
          textDirection: TextDirection.ltr,
          child: new Stack(
            children: const <Widget>[
              const Text('a'),
              const Text('b', textDirection: TextDirection.ltr),
              const Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final Element elementA = find.text('a').evaluate().first;
      final Element elementB = find.text('b').evaluate().first;

      service.disposeAllGroups();
      await service.testExtension('setPubRootDirectories', <String, String>{});
      service.setSelection(elementA, 'my-group');
      final Map<String, Object> jsonA = await service.testExtension('getSelectedWidget', <String, String>{'arg': null, 'objectGroup': 'my-group'});
      final Map<String, Object> creationLocationA = jsonA['creationLocation'];
      expect(creationLocationA, isNotNull);
      final String fileA = creationLocationA['file'];
      final int lineA = creationLocationA['line'];
      final int columnA = creationLocationA['column'];
      final List<Object> parameterLocationsA = creationLocationA['parameterLocations'];

      service.setSelection(elementB, 'my-group');
      final Map<String, Object> jsonB = await service.testExtension('getSelectedWidget', <String, String>{'arg': null, 'objectGroup': 'my-group'});
      final Map<String, Object> creationLocationB = jsonB['creationLocation'];
      expect(creationLocationB, isNotNull);
      final String fileB = creationLocationB['file'];
      final int lineB = creationLocationB['line'];
      final int columnB = creationLocationB['column'];
      final List<Object> parameterLocationsB = creationLocationB['parameterLocations'];
      expect(fileA, endsWith('widget_inspector_test.dart'));
      expect(fileA, equals(fileB));
      // We don't hardcode the actual lines the widgets are created on as that
      // would make this test fragile.
      expect(lineA + 1, equals(lineB));
      // Column numbers are more stable than line numbers.
      expect(columnA, equals(21));
      expect(columnA, equals(columnB));
      expect(parameterLocationsA.length, equals(1));
      final Map<String, Object> paramA = parameterLocationsA[0];
      expect(paramA['name'], equals('data'));
      expect(paramA['line'], equals(lineA));
      expect(paramA['column'], equals(26));

      expect(parameterLocationsB.length, equals(2));
      final Map<String, Object> paramB1 = parameterLocationsB[0];
      expect(paramB1['name'], equals('data'));
      expect(paramB1['line'], equals(lineB));
      expect(paramB1['column'], equals(26));
      final Map<String, Object> paramB2 = parameterLocationsB[1];
      expect(paramB2['name'], equals('textDirection'));
      expect(paramB2['line'], equals(lineB));
      expect(paramB2['column'], equals(31));
    }, skip: !WidgetInspectorService.instance.isWidgetCreationTracked()); // Test requires --track-widget-creation flag.

    testWidgets('ext.flutter.inspector.setPubRootDirectories', (WidgetTester tester) async {
      await tester.pumpWidget(
        new Directionality(
          textDirection: TextDirection.ltr,
          child: new Stack(
            children: const <Widget>[
              const Text('a'),
              const Text('b', textDirection: TextDirection.ltr),
              const Text('c', textDirection: TextDirection.ltr),
            ],
          ),
        ),
      );
      final Element elementA = find.text('a').evaluate().first;

      await service.testExtension('setPubRootDirectories', <String, String>{});
      service.setSelection(elementA, 'my-group');
      Map<String, Object> jsonObject = await service.testExtension('getSelectedWidget', <String, String>{'arg': null, 'objectGroup': 'my-group'});
      Map<String, Object> creationLocation = jsonObject['creationLocation'];
      expect(creationLocation, isNotNull);
      final String fileA = creationLocation['file'];
      expect(fileA, endsWith('widget_inspector_test.dart'));
      expect(jsonObject, isNot(contains('createdByLocalProject')));
      final List<String> segments = Uri.parse(fileA).pathSegments;
      // Strip a couple subdirectories away to generate a plausible pub root
      // directory.
      final String pubRootTest = '/' + segments.take(segments.length - 2).join('/');
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
      service.setPubRootDirectories(<Object>[pubRootTest]);
      jsonObject = json.decode(service.getSelectedWidget(null, 'my-group'));
      expect(jsonObject, isNot(contains('createdByLocalProject')));
      creationLocation = jsonObject['creationLocation'];
      expect(creationLocation, isNotNull);
      // This RichText widget is created by the build method of the Text widget
      // thus the creation location is in text.dart not basic.dart
      final List<String> pathSegmentsFramework = Uri.parse(creationLocation['file']).pathSegments;
      expect(pathSegmentsFramework.join('/'), endsWith('/packages/flutter/lib/src/widgets/text.dart'));

      // Strip off /src/widgets/text.dart.
      final String pubRootFramework = '/' + pathSegmentsFramework.take(pathSegmentsFramework.length - 3).join('/');
      await service.testExtension('setPubRootDirectories', <String, String>{'arg0': pubRootFramework});
      expect(await service.testExtension('getSelectedWidget', <String, String>{'objectGroup': 'my-group'}), contains('createdByLocalProject'));
      service.setSelection(elementA, 'my-group');
      expect(await service.testExtension('getSelectedWidget', <String, String>{'objectGroup': 'my-group'}), isNot(contains('createdByLocalProject')));

      await service.testExtension('setPubRootDirectories', <String, String>{'arg0': pubRootFramework, 'arg1': pubRootTest});
      service.setSelection(elementA, 'my-group');
      expect(await service.testExtension('getSelectedWidget', <String, String>{'objectGroup': 'my-group'}), contains('createdByLocalProject'));
      service.setSelection(richText, 'my-group');
      expect(await service.testExtension('getSelectedWidget', <String, String>{'objectGroup': 'my-group'}), contains('createdByLocalProject'));
    }, skip: !WidgetInspectorService.instance.isWidgetCreationTracked()); // Test requires --track-widget-creation flag.

    testWidgets('ext.flutter.inspector.show', (WidgetTester tester) async {
      service.rebuildCount = 0;
      expect(await service.testBoolExtension('show', <String, String>{'enabled': 'true'}), equals('true'));
      expect(service.rebuildCount, equals(1));
      expect(await service.testBoolExtension('show', <String, String>{}), equals('true'));
      expect(WidgetsApp.debugShowWidgetInspectorOverride, isTrue);
      expect(await service.testBoolExtension('show', <String, String>{'enabled': 'true'}), equals('true'));
      expect(service.rebuildCount, equals(1));
      expect(await service.testBoolExtension('show', <String, String>{'enabled': 'false'}), equals('false'));
      expect(await service.testBoolExtension('show', <String, String>{}), equals('false'));
      expect(service.rebuildCount, equals(2));
      expect(WidgetsApp.debugShowWidgetInspectorOverride, isFalse);
    });
  }
}
