// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Tags(<String>['reduced-test-set'])
@TestOn('!chrome')
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/src/widgets/accessibility_inspector.dart';
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
      return json.decode(
            json.encode(await accessibilityExtensions[name]!(const <String, String>{})),
          )
          as Map<String, Object?>;
    }

    // Calling getSemanticsTree before semantics is enabled returns an error.
    final Map<String, Object?> disabledResult = await callExtension(
      AccessibilityServiceExtensions.getSemanticsTree.extensionName,
    );
    expect(disabledResult['error'], equals('Semantics not enabled.'));
    expect(disabledResult['needsFrame'], isNull);

    // Calling enableSemantics enables semantics without returning the tree.
    // Ensure the returned map is mutable (required by BindingBase.registerServiceExtension).
    final Map<String, Object?> enableResult =
        await accessibilityExtensions[AccessibilityServiceExtensions
            .enableSemantics
            .extensionName]!(const <String, String>{});
    expect(enableResult, isEmpty);
    expect(() => enableResult['type'] = '_extensionType', returnsNormally);

    // Calling getSemanticsTree schedules a frame and returns an error map indicating root is null.
    final Map<String, Object?> result1 = await callExtension(
      AccessibilityServiceExtensions.getSemanticsTree.extensionName,
    );

    expect(result1['error'], equals('rootSemanticsNode is null'));
    expect(result1['needsFrame'], isTrue);

    // Pump a frame to build/flush the semantics tree.
    await tester.pump();

    // The second call returns the populated semantics tree.
    final Map<String, Object?> result2 = await callExtension(
      AccessibilityServiceExtensions.getSemanticsTree.extensionName,
    );

    expect(result2['error'], isNull);
    expect(result2['data'], isA<Map<String, Object?>>());
    final nodes = result2['data']! as Map<String, Object?>;
    expect(nodes, isNotEmpty);

    Map<String, Object?> findNodeWithLabel(Map<String, Object?> nodes, String label) {
      for (final Object? value in nodes.values) {
        final node = value! as Map<String, Object?>;
        if ((node['label']! as String).contains(label)) {
          return node;
        }
      }
      return const <String, Object?>{};
    }

    final Map<String, Object?> rootNode = findNodeWithLabel(nodes, 'Root Node');
    expect(rootNode, isNotEmpty);
    expect(rootNode['id'], isNotNull);

    final Map<String, Object?> child1 = findNodeWithLabel(nodes, 'Child Node 1');
    expect(child1, isNotEmpty);
    expect(child1['flags']! as List<Object?>, contains('isButton'));
    expect(child1['tooltip'], equals('This is a tooltip'));

    final Map<String, Object?> child2 = findNodeWithLabel(nodes, 'Child Node 2');
    expect(child2, isNotEmpty);
    expect(child2['value'], equals('42'));
    expect(child2['increasedValue'], equals('43'));
    expect(child2['decreasedValue'], equals('41'));
    expect(child2['actions']! as List<Object?>, contains('increase'));
    expect(child2['actions']! as List<Object?>, contains('decrease'));

    final Map<String, Object?> child3 = findNodeWithLabel(nodes, 'Child Node 3');
    expect(child3, isNotEmpty);
    expect(child3['transform'], isNotNull);
    final transform = child3['transform']! as List<Object?>;
    expect(transform, hasLength(16));
    expect(transform[0], equals(2.0));

    expect(
      rootNode['childrenInTraversalOrder']! as List<Object?>,
      containsAll(<Object?>[child1['id'], child2['id'], child3['id']]),
    );
    expect(
      rootNode['childrenInHitTestOrder']! as List<Object?>,
      containsAll(<Object?>[child1['id'], child2['id'], child3['id']]),
    );

    // Verify issues list is present on all nodes.
    for (final Object? value in nodes.values) {
      final node = value! as Map<String, Object?>;
      expect(node['issues'], isA<List<Object?>>());
    }

    // Calling disposeSemantics succeeds and cleans up semantics handle.
    // Ensure the returned map is mutable.
    final Map<String, Object?> disposeResult =
        await accessibilityExtensions[AccessibilityServiceExtensions
            .disposeSemantics
            .extensionName]!(const <String, String>{});
    expect(disposeResult, isEmpty);
    expect(() => disposeResult['type'] = '_extensionType', returnsNormally);

    AccessibilityInspector.instance.resetAllState();
  }, semanticsEnabled: false);

  testWidgets('ext.flutter.accessibility.getSemanticsTree detects accessibility issues', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Column(
            children: <Widget>[
              // Small tap target without a label.
              SizedBox(
                width: 20.0,
                height: 20.0,
                child: Semantics(onTap: () {}, child: const SizedBox(width: 20.0, height: 20.0)),
              ),
              // Unlabeled image.
              Semantics(image: true, child: const SizedBox(width: 50.0, height: 50.0)),
              // Accessible button with sufficient size and label.
              SizedBox(
                width: 48.0,
                height: 48.0,
                child: Semantics(
                  button: true,
                  label: 'Accessible Button',
                  onTap: () {},
                  child: const SizedBox(width: 48.0, height: 48.0),
                ),
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
      return json.decode(
            json.encode(await accessibilityExtensions[name]!(const <String, String>{})),
          )
          as Map<String, Object?>;
    }

    await callExtension(AccessibilityServiceExtensions.enableSemantics.extensionName);
    await tester.pump();

    final Map<String, Object?> result = await callExtension(
      AccessibilityServiceExtensions.getSemanticsTree.extensionName,
    );

    expect(result['error'], isNull);
    final nodes = result['data']! as Map<String, Object?>;

    // Find node with tapTargetSize issue.
    final tapTargetNodes = <Map<String, Object?>>[];
    final missingLabelNodes = <Map<String, Object?>>[];
    final unlabeledImageNodes = <Map<String, Object?>>[];

    for (final Object? value in nodes.values) {
      final node = value! as Map<String, Object?>;
      final List<Map<String, Object?>> issues = (node['issues']! as List<Object?>)
          .cast<Map<String, Object?>>();
      for (final issue in issues) {
        switch (issue['rule'] as String?) {
          case 'tapTargetSize':
            tapTargetNodes.add(node);
          case 'missingLabel':
            missingLabelNodes.add(node);
          case 'unlabeledLeafNode':
            unlabeledImageNodes.add(node);
        }
      }
    }

    expect(tapTargetNodes, isNotEmpty);
    expect(missingLabelNodes, isNotEmpty);
    // The small unlabeled tap target node should contain multiple issues.
    expect(tapTargetNodes.first['id'], missingLabelNodes.first['id']);
    final List<Map<String, Object?>> multiIssueList =
        (tapTargetNodes.first['issues']! as List<Object?>).cast<Map<String, Object?>>();
    expect(
      multiIssueList.map((Map<String, Object?> issue) => issue['rule']),
      containsAll(<String>['tapTargetSize', 'missingLabel', 'unlabeledLeafNode']),
    );

    final Map<String, Object?> tapTargetIssue = (tapTargetNodes.first['issues']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .firstWhere((Map<String, Object?> issue) => issue['rule'] == 'tapTargetSize');
    expect(tapTargetIssue['description'], contains('expected tap target size'));

    final Map<String, Object?> missingLabelIssue =
        (missingLabelNodes.first['issues']! as List<Object?>)
            .cast<Map<String, Object?>>()
            .firstWhere((Map<String, Object?> issue) => issue['rule'] == 'missingLabel');
    expect(
      missingLabelIssue['description'],
      contains('expected tappable node to have semantic label'),
    );

    expect(unlabeledImageNodes, isNotEmpty);
    final Map<String, Object?> unlabeledImageIssue =
        (unlabeledImageNodes.first['issues']! as List<Object?>)
            .cast<Map<String, Object?>>()
            .firstWhere((Map<String, Object?> issue) => issue['rule'] == 'unlabeledLeafNode');
    expect(
      unlabeledImageIssue['description'],
      contains('expected leaf semantics node to have a label, value, hint, or tooltip'),
    );

    // Check accessible button has no issues.
    final Map<String, Object?> accessibleButton = nodes.values
        .map((Object? v) => v! as Map<String, Object?>)
        .firstWhere(
          (Map<String, Object?> node) => (node['label'] as String?) == 'Accessible Button',
        );
    expect(accessibleButton['issues']! as List<Object?>, isEmpty);

    await callExtension(AccessibilityServiceExtensions.disposeSemantics.extensionName);
    AccessibilityInspector.instance.resetAllState();
  }, semanticsEnabled: false);
}
