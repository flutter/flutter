// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  group(FocusNode, () {
    setUp(() {
      // Reset the focus manager between tests, to avoid leaking state.
      WidgetsBinding.instance.focusManager.reset();
    });
    testWidgets('Can add children.', (WidgetTester tester) async {
      final FocusNode parent = FocusNode();
      final FocusNode child1 = FocusNode();
      final FocusNode child2 = FocusNode();
      tester.binding.focusManager.rootScope.reparentIfNeeded(parent);
      parent.reparentIfNeeded(child1);
      expect(child1.parent, equals(parent));
      expect(parent.children.first, equals(child1));
      expect(parent.children.last, equals(child1));
      parent.reparentIfNeeded(child2);
      expect(child1.parent, equals(parent));
      expect(child2.parent, equals(parent));
      expect(parent.children.first, equals(child1));
      expect(parent.children.last, equals(child2));
    });
    testWidgets('Can remove children.', (WidgetTester tester) async {
      final FocusNode parent = FocusNode();
      final FocusNode child1 = FocusNode();
      final FocusNode child2 = FocusNode();
      tester.binding.focusManager.rootScope.reparentIfNeeded(parent);
      parent.reparentIfNeeded(child1);
      parent.reparentIfNeeded(child2);
      expect(child1.parent, equals(parent));
      expect(child2.parent, equals(parent));
      expect(parent.children.first, equals(child1));
      expect(parent.children.last, equals(child2));
      parent.removeChild(child1);
      expect(child1.parent, isNull);
      expect(child2.parent, equals(parent));
      expect(parent.children.first, equals(child2));
      expect(parent.children.last, equals(child2));
      parent.removeChild(child2);
      expect(child1.parent, isNull);
      expect(child2.parent, isNull);
      expect(parent.children, isEmpty);
    });
    testWidgets('Removing a node removes it from scope.', (WidgetTester tester) async {
      final FocusScopeNode scope = FocusScopeNode();
      final FocusNode parent = FocusNode();
      final FocusNode child1 = FocusNode();
      final FocusNode child2 = FocusNode();
      tester.binding.focusManager.rootScope.reparentIfNeeded(scope);
      scope.reparentIfNeeded(parent);
      parent.reparentIfNeeded(child1);
      parent.reparentIfNeeded(child2);
      child1.requestFocus();
      await tester.pump();
      expect(scope.hasFocus, isTrue);
      expect(child1.hasFocus, isTrue);
      expect(child1.hasPrimaryFocus, isTrue);
      expect(scope.focusedChild, equals(child1));
      parent.removeChild(child1);
      expect(scope.hasFocus, isFalse);
      expect(scope.focusedChild, isNull);
    });
    testWidgets('Can add children to scope and focus', (WidgetTester tester) async {
      final FocusScopeNode scope = FocusScopeNode();
      final FocusNode parent = FocusNode();
      final FocusNode child1 = FocusNode();
      final FocusNode child2 = FocusNode();
      tester.binding.focusManager.rootScope.reparentIfNeeded(scope);
      scope.reparentIfNeeded(parent);
      parent.reparentIfNeeded(child1);
      parent.reparentIfNeeded(child2);
      expect(scope.children.first, equals(parent));
      expect(parent.parent, equals(scope));
      expect(child1.parent, equals(parent));
      expect(child2.parent, equals(parent));
      expect(parent.children.first, equals(child1));
      expect(parent.children.last, equals(child2));
      child1.requestFocus();
      await tester.pump();
      expect(scope.focusedChild, equals(child1));
      expect(parent.hasFocus, isTrue);
      expect(parent.hasPrimaryFocus, isFalse);
      expect(child1.hasFocus, isTrue);
      expect(child1.hasPrimaryFocus, isTrue);
      expect(child2.hasFocus, isFalse);
      expect(child2.hasPrimaryFocus, isFalse);
      child2.requestFocus();
      await tester.pump();
      expect(scope.focusedChild, equals(child2));
      expect(parent.hasFocus, isTrue);
      expect(parent.hasPrimaryFocus, isFalse);
      expect(child1.hasFocus, isFalse);
      expect(child1.hasPrimaryFocus, isFalse);
      expect(child2.hasFocus, isTrue);
      expect(child2.hasPrimaryFocus, isTrue);
    });
    testWidgets('Autofocus works.', (WidgetTester tester) async {
      final FocusScopeNode scope = FocusScopeNode();
      final FocusNode parent = FocusNode();
      final FocusNode child1 = FocusNode();
      final FocusNode child2 = FocusNode(isAutoFocus: true);
      tester.binding.focusManager.rootScope.reparentIfNeeded(scope);
      scope.reparentIfNeeded(parent);
      parent.reparentIfNeeded(child1);
      parent.reparentIfNeeded(child2);

      await tester.pump();

      expect(scope.focusedChild, equals(child2));
      expect(parent.hasFocus, isTrue);
      expect(child1.hasFocus, isFalse);
      expect(child1.hasPrimaryFocus, isFalse);
      expect(child2.hasFocus, isTrue);
      expect(child2.hasPrimaryFocus, isTrue);
      child1.requestFocus();

      await tester.pump();

      expect(scope.focusedChild, equals(child1));
      expect(parent.hasFocus, isTrue);
      expect(child1.hasFocus, isTrue);
      expect(child1.hasPrimaryFocus, isTrue);
      expect(child2.hasFocus, isFalse);
      expect(child2.hasPrimaryFocus, isFalse);
    });
    testWidgets('Adding a focusedChild to a scope sets scope as focusedChild in parent scope', (WidgetTester tester) async {
      final FocusScopeNode scope1 = FocusScopeNode();
      final FocusScopeNode scope2 = FocusScopeNode();
      final FocusNode child1 = FocusNode();
      final FocusNode child2 = FocusNode();
      tester.binding.focusManager.rootScope.reparentIfNeeded(scope1);
      scope1.reparentIfNeeded(scope2);
      scope1.reparentIfNeeded(child1);
      scope2.reparentIfNeeded(child2);
      child2.requestFocus();
      await tester.pump();
      expect(scope2.focusedChild, equals(child2));
      expect(scope1.focusedChild, equals(scope2));
      expect(child1.hasFocus, isFalse);
      expect(child1.hasPrimaryFocus, isFalse);
      expect(child2.hasFocus, isTrue);
      expect(child2.hasPrimaryFocus, isTrue);
      child1.requestFocus();
      await tester.pump();
      expect(scope2.focusedChild, equals(child2));
      expect(scope1.focusedChild, equals(child1));
      expect(child1.hasFocus, isTrue);
      expect(child1.hasPrimaryFocus, isTrue);
      expect(child2.hasFocus, isFalse);
      expect(child2.hasPrimaryFocus, isFalse);
    });
    testWidgets('Can move node with focus without losing focus', (WidgetTester tester) async {
      final FocusScopeNode scope = FocusScopeNode(debugLabel: 'Scope');
      final FocusNode parent1 = FocusNode(debugLabel: 'Parent 1');
      final FocusNode parent2 = FocusNode(debugLabel: 'Parent 2');
      final FocusNode child1 = FocusNode(debugLabel: 'Child 1');
      final FocusNode child2 = FocusNode(debugLabel: 'Child 2');
      tester.binding.focusManager.rootScope.reparentIfNeeded(scope);
      scope.reparentIfNeeded(parent1);
      scope.reparentIfNeeded(parent2);
      parent1.reparentIfNeeded(child1);
      parent1.reparentIfNeeded(child2);
      expect(scope.children.first, equals(parent1));
      expect(scope.children.last, equals(parent2));
      expect(parent1.parent, equals(scope));
      expect(parent2.parent, equals(scope));
      expect(child1.parent, equals(parent1));
      expect(child2.parent, equals(parent1));
      expect(parent1.children.first, equals(child1));
      expect(parent1.children.last, equals(child2));
      child1.requestFocus();
      await tester.pump();
      parent2.reparentIfNeeded(child1);
      await tester.pump();

      expect(scope.focusedChild, equals(child1));
      expect(child1.parent, equals(parent2));
      expect(child2.parent, equals(parent1));
      expect(parent1.children.first, equals(child2));
      expect(parent2.children.first, equals(child1));
    });
    testWidgets('Can move node between scopes and lose scope focus', (WidgetTester tester) async {
      final FocusScopeNode scope1 = FocusScopeNode();
      final FocusScopeNode scope2 = FocusScopeNode();
      final FocusNode parent1 = FocusNode();
      final FocusNode parent2 = FocusNode();
      final FocusNode child1 = FocusNode();
      final FocusNode child2 = FocusNode();
      final FocusNode child3 = FocusNode();
      final FocusNode child4 = FocusNode();
      tester.binding.focusManager.rootScope.reparentIfNeeded(scope1);
      tester.binding.focusManager.rootScope.reparentIfNeeded(scope2);
      scope1.reparentIfNeeded(parent1);
      scope2.reparentIfNeeded(parent2);
      parent1.reparentIfNeeded(child1);
      parent1.reparentIfNeeded(child2);
      parent2.reparentIfNeeded(child3);
      parent2.reparentIfNeeded(child4);

      child1.requestFocus();
      await tester.pump();
      expect(scope1.focusedChild, equals(child1));
      expect(parent2.children.contains(child1), isFalse);

      parent2.reparentIfNeeded(child1);
      await tester.pump();
      expect(scope1.focusedChild, isNull);
      expect(parent2.children.contains(child1), isTrue);
    });
    testWidgets('Can move focus between scopes and keep focus', (WidgetTester tester) async {
      final FocusScopeNode scope1 = FocusScopeNode();
      final FocusScopeNode scope2 = FocusScopeNode();
      final FocusNode parent1 = FocusNode();
      final FocusNode parent2 = FocusNode();
      final FocusNode child1 = FocusNode();
      final FocusNode child2 = FocusNode();
      final FocusNode child3 = FocusNode();
      final FocusNode child4 = FocusNode();
      tester.binding.focusManager.rootScope.reparentIfNeeded(scope1);
      tester.binding.focusManager.rootScope.reparentIfNeeded(scope2);
      scope1.reparentIfNeeded(parent1);
      scope2.reparentIfNeeded(parent2);
      parent1.reparentIfNeeded(child1);
      parent1.reparentIfNeeded(child2);
      parent2.reparentIfNeeded(child3);
      parent2.reparentIfNeeded(child4);
      child4.requestFocus();
      await tester.pump();
      child1.requestFocus();
      await tester.pump();
      expect(child4.hasFocus, isFalse);
      expect(child4.hasPrimaryFocus, isFalse);
      expect(child1.hasFocus, isTrue);
      expect(child1.hasPrimaryFocus, isTrue);
      expect(scope1.hasFocus, isTrue);
      expect(scope1.hasPrimaryFocus, isFalse);
      expect(scope2.hasFocus, isFalse);
      expect(scope2.hasPrimaryFocus, isFalse);
      expect(parent1.hasFocus, isTrue);
      expect(parent2.hasFocus, isFalse);
      expect(scope1.focusedChild, equals(child1));
      expect(scope2.focusedChild, equals(child4));
      scope2.requestFocus();
      await tester.pump();
      expect(child4.hasFocus, isTrue);
      expect(child4.hasPrimaryFocus, isTrue);
      expect(child1.hasFocus, isFalse);
      expect(child1.hasPrimaryFocus, isFalse);
      expect(scope1.hasFocus, isFalse);
      expect(scope1.hasPrimaryFocus, isFalse);
      expect(scope2.hasFocus, isTrue);
      expect(scope2.hasPrimaryFocus, isFalse);
      expect(parent1.hasFocus, isFalse);
      expect(parent2.hasFocus, isTrue);
      expect(scope1.focusedChild, equals(child1));
      expect(scope2.focusedChild, equals(child4));
    });
  });
}
