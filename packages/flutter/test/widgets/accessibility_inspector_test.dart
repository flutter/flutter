// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Tags(<String>['reduced-test-set'])
@TestOn('!chrome')
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ext.flutter.accessibility.getSemanticsTree', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Semantics(
          label: 'Root Node',
          container: true,
          explicitChildNodes: true,
          child: Column(
            children: <Widget>[
              Semantics(
                label: 'Child Node 1',
                button: true,
                tooltip: 'This is a tooltip',
                child: const Text('Button 1'),
              ),
              Semantics(
                label: 'Child Node 2',
                value: '42',
                increasedValue: '43',
                decreasedValue: '41',
                onIncrease: () {},
                onDecrease: () {},
                child: const Text('Value 2'),
              ),
              Transform.scale(
                scale: 2.0,
                child: Semantics(label: 'Child Node 3', child: const Text('Scaled')),
              ),
            ],
          ),
        ),
      ),
    );

    final accessibilityExtensions = <String, ServiceExtensionCallback>{};
    AccessibilityInspector.instance.initServiceExtensions(({
      required String name,
      required ServiceExtensionCallback callback,
    }) {
      accessibilityExtensions[name] = callback;
    });

    Future<Map<String, Object?>> callExtension(String name) async {
      return json.decode(json.encode(await accessibilityExtensions[name]!(<String, String>{})))
          as Map<String, Object?>;
    }

    // The first call registers semantics, schedules a frame, and returns an error map indicating root is null.
    final Map<String, Object?> result1 = await callExtension('accessibility.getSemanticsTree');

    expect(result1['error'], equals('rootSemanticsNode is null'));
    expect(result1['needsFrame'], isTrue);

    // Pump a frame to build/flush the semantics tree.
    await tester.pump();

    // The second call returns the populated semantics tree.
    final Map<String, Object?> result2 = await callExtension('accessibility.getSemanticsTree');

    expect(result2['error'], isNull);
    expect(result2['id'], isNotNull);

    // Let's explore the children structure recursively
    Map<String, Object?> findNodeWithLabel(Map<String, Object?> node, String label) {
      if ((node['label']! as String).contains(label)) {
        return node;
      }
      final children = node['children']! as List<Object?>;
      for (final child in children) {
        final Map<String, Object?> result = findNodeWithLabel(
          child! as Map<String, Object?>,
          label,
        );
        if (result.isNotEmpty) {
          return result;
        }
      }
      return <String, Object?>{};
    }

    final Map<String, Object?> rootNode = findNodeWithLabel(result2, 'Root Node');
    expect(rootNode, isNotEmpty);
    expect(rootNode['id'], isNotNull);

    final Map<String, Object?> child1 = findNodeWithLabel(result2, 'Child Node 1');
    expect(child1, isNotEmpty);
    expect(child1['flags']! as List<Object?>, contains('isButton'));
    expect(child1['tooltip'], equals('This is a tooltip'));

    final Map<String, Object?> child2 = findNodeWithLabel(result2, 'Child Node 2');
    expect(child2, isNotEmpty);
    expect(child2['value'], equals('42'));
    expect(child2['increasedValue'], equals('43'));
    expect(child2['decreasedValue'], equals('41'));
    expect(child2['actions']! as List<Object?>, contains('increase'));
    expect(child2['actions']! as List<Object?>, contains('decrease'));

    final Map<String, Object?> child3 = findNodeWithLabel(result2, 'Child Node 3');
    expect(child3, isNotEmpty);
    expect(child3['transform'], isNotNull);
    final transform = child3['transform']! as List<Object?>;
    expect(transform, hasLength(16));
    expect(transform[0], equals(2.0));

    AccessibilityInspector.instance.resetAllState();
  }, semanticsEnabled: false);
}
