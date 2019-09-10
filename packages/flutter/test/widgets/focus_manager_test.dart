// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void sendFakeKeyEvent(Map<String, dynamic> data) {
  ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.keyEvent.name,
    SystemChannels.keyEvent.codec.encodeMessage(data),
    (ByteData data) {},
  );
}

void main() {
  final GlobalKey widgetKey = GlobalKey();
  Future<BuildContext> setupWidget(WidgetTester tester) async {
    await tester.pumpWidget(Container(key: widgetKey));
    return widgetKey.currentContext;
  }

  group(FocusNode, () {
    testWidgets('Can add children.', (WidgetTester tester) async {
      final BuildContext context = await setupWidget(tester);
      final FocusNode parent = FocusNode();
      final FocusAttachment parentAttachment = parent.attach(context);
      final FocusNode child1 = FocusNode();
      final FocusAttachment child1Attachment = child1.attach(context);
      final FocusNode child2 = FocusNode();
      final FocusAttachment child2Attachment = child2.attach(context);
      parentAttachment.reparent(parent: tester.binding.focusManager.rootScope);
      child1Attachment.reparent(parent: parent);
      expect(child1.parent, equals(parent));
      expect(parent.children.first, equals(child1));
      expect(parent.children.last, equals(child1));
      child2Attachment.reparent(parent: parent);
      expect(child1.parent, equals(parent));
      expect(child2.parent, equals(parent));
      expect(parent.children.first, equals(child1));
      expect(parent.children.last, equals(child2));
    });
    testWidgets('Can remove children.', (WidgetTester tester) async {
      final BuildContext context = await setupWidget(tester);
      final FocusNode parent = FocusNode();
      final FocusAttachment parentAttachment = parent.attach(context);
      final FocusNode child1 = FocusNode();
      final FocusAttachment child1Attachment = child1.attach(context);
      final FocusNode child2 = FocusNode();
      final FocusAttachment child2Attachment = child2.attach(context);
      parentAttachment.reparent(parent: tester.binding.focusManager.rootScope);
      child1Attachment.reparent(parent: parent);
      child2Attachment.reparent(parent: parent);
      expect(child1.parent, equals(parent));
      expect(child2.parent, equals(parent));
      expect(parent.children.first, equals(child1));
      expect(parent.children.last, equals(child2));
      child1Attachment.detach();
      expect(child1.parent, isNull);
      expect(child2.parent, equals(parent));
      expect(parent.children.first, equals(child2));
      expect(parent.children.last, equals(child2));
      child2Attachment.detach();
      expect(child1.parent, isNull);
      expect(child2.parent, isNull);
      expect(parent.children, isEmpty);
    });
    testWidgets('implements debugFillProperties', (WidgetTester tester) async {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      FocusNode(
        debugLabel: 'Label',
      ).debugFillProperties(builder);
      final List<String> description = builder.properties.where((DiagnosticsNode n) => !n.isFiltered(DiagnosticLevel.info)).map((DiagnosticsNode n) => n.toString()).toList();
      expect(description, <String>[
        'debugLabel: "Label"',
      ]);
    });
  });
  group(FocusScopeNode, () {
    testWidgets('Can setFirstFocus on a scope with no manager.', (WidgetTester tester) async {
      final BuildContext context = await setupWidget(tester);
      final FocusScopeNode scope = FocusScopeNode(debugLabel: 'Scope');
      scope.attach(context);
      final FocusScopeNode parent = FocusScopeNode(debugLabel: 'Parent');
      parent.attach(context);
      final FocusScopeNode child1 = FocusScopeNode(debugLabel: 'Child 1');
      final FocusAttachment child1Attachment = child1.attach(context);
      final FocusScopeNode child2 = FocusScopeNode(debugLabel: 'Child 2');
      child2.attach(context);
      scope.setFirstFocus(parent);
      parent.setFirstFocus(child1);
      parent.setFirstFocus(child2);
      child1.requestFocus();
      await tester.pump();
      expect(scope.hasFocus, isFalse);
      expect(child1.hasFocus, isFalse);
      expect(child1.hasPrimaryFocus, isFalse);
      expect(scope.focusedChild, equals(parent));
      expect(parent.focusedChild, equals(child1));
      child1Attachment.detach();
      expect(scope.hasFocus, isFalse);
      expect(scope.focusedChild, equals(parent));
    });
    testWidgets('Removing a node removes it from scope.', (WidgetTester tester) async {
      final BuildContext context = await setupWidget(tester);
      final FocusScopeNode scope = FocusScopeNode();
      final FocusAttachment scopeAttachment = scope.attach(context);
      final FocusNode parent = FocusNode();
      final FocusAttachment parentAttachment = parent.attach(context);
      final FocusNode child1 = FocusNode();
      final FocusAttachment child1Attachment = child1.attach(context);
      final FocusNode child2 = FocusNode();
      final FocusAttachment child2Attachment = child2.attach(context);
      scopeAttachment.reparent(parent: tester.binding.focusManager.rootScope);
      parentAttachment.reparent(parent: scope);
      child1Attachment.reparent(parent: parent);
      child2Attachment.reparent(parent: parent);
      child1.requestFocus();
      await tester.pump();
      expect(scope.hasFocus, isTrue);
      expect(child1.hasFocus, isTrue);
      expect(child1.hasPrimaryFocus, isTrue);
      expect(scope.focusedChild, equals(child1));
      child1Attachment.detach();
      expect(scope.hasFocus, isFalse);
      expect(scope.focusedChild, isNull);
    });
    testWidgets('Can add children to scope and focus', (WidgetTester tester) async {
      final BuildContext context = await setupWidget(tester);
      final FocusScopeNode scope = FocusScopeNode();
      final FocusAttachment scopeAttachment = scope.attach(context);
      final FocusNode parent = FocusNode();
      final FocusAttachment parentAttachment = parent.attach(context);
      final FocusNode child1 = FocusNode();
      final FocusAttachment child1Attachment = child1.attach(context);
      final FocusNode child2 = FocusNode();
      final FocusAttachment child2Attachment = child2.attach(context);
      scopeAttachment.reparent(parent: tester.binding.focusManager.rootScope);
      parentAttachment.reparent(parent: scope);
      child1Attachment.reparent(parent: parent);
      child2Attachment.reparent(parent: parent);
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
      final BuildContext context = await setupWidget(tester);
      final FocusScopeNode scope = FocusScopeNode(debugLabel: 'Scope');
      final FocusAttachment scopeAttachment = scope.attach(context);
      final FocusNode parent = FocusNode(debugLabel: 'Parent');
      final FocusAttachment parentAttachment = parent.attach(context);
      final FocusNode child1 = FocusNode(debugLabel: 'Child 1');
      final FocusAttachment child1Attachment = child1.attach(context);
      final FocusNode child2 = FocusNode(debugLabel: 'Child 2');
      final FocusAttachment child2Attachment = child2.attach(context);
      scopeAttachment.reparent(parent: tester.binding.focusManager.rootScope);
      parentAttachment.reparent(parent: scope);
      child1Attachment.reparent(parent: parent);
      child2Attachment.reparent(parent: parent);

      scope.autofocus(child2);
      await tester.pump();

      expect(scope.focusedChild, equals(child2));
      expect(parent.hasFocus, isTrue);
      expect(child1.hasFocus, isFalse);
      expect(child1.hasPrimaryFocus, isFalse);
      expect(child2.hasFocus, isTrue);
      expect(child2.hasPrimaryFocus, isTrue);
      child1.requestFocus();
      scope.autofocus(child2);

      await tester.pump();

      expect(scope.focusedChild, equals(child1));
      expect(parent.hasFocus, isTrue);
      expect(child1.hasFocus, isTrue);
      expect(child1.hasPrimaryFocus, isTrue);
      expect(child2.hasFocus, isFalse);
      expect(child2.hasPrimaryFocus, isFalse);
    });
    testWidgets('Adding a focusedChild to a scope sets scope as focusedChild in parent scope', (WidgetTester tester) async {
      final BuildContext context = await setupWidget(tester);
      final FocusScopeNode scope1 = FocusScopeNode();
      final FocusAttachment scope1Attachment = scope1.attach(context);
      final FocusScopeNode scope2 = FocusScopeNode();
      final FocusAttachment scope2Attachment = scope2.attach(context);
      final FocusNode child1 = FocusNode();
      final FocusAttachment child1Attachment = child1.attach(context);
      final FocusNode child2 = FocusNode();
      final FocusAttachment child2Attachment = child2.attach(context);
      scope1Attachment.reparent(parent: tester.binding.focusManager.rootScope);
      scope2Attachment.reparent(parent: scope1);
      child1Attachment.reparent(parent: scope1);
      child2Attachment.reparent(parent: scope2);
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
      final BuildContext context = await setupWidget(tester);
      final FocusScopeNode scope = FocusScopeNode(debugLabel: 'Scope');
      final FocusAttachment scopeAttachment = scope.attach(context);
      final FocusNode parent1 = FocusNode(debugLabel: 'Parent 1');
      final FocusAttachment parent1Attachment = parent1.attach(context);
      final FocusNode parent2 = FocusNode(debugLabel: 'Parent 2');
      final FocusAttachment parent2Attachment = parent2.attach(context);
      final FocusNode child1 = FocusNode(debugLabel: 'Child 1');
      final FocusAttachment child1Attachment = child1.attach(context);
      final FocusNode child2 = FocusNode(debugLabel: 'Child 2');
      final FocusAttachment child2Attachment = child2.attach(context);
      scopeAttachment.reparent(parent: tester.binding.focusManager.rootScope);
      parent1Attachment.reparent(parent: scope);
      parent2Attachment.reparent(parent: scope);
      child1Attachment.reparent(parent: parent1);
      child2Attachment.reparent(parent: parent1);
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
      child1Attachment.reparent(parent: parent2);
      await tester.pump();

      expect(scope.focusedChild, equals(child1));
      expect(child1.parent, equals(parent2));
      expect(child2.parent, equals(parent1));
      expect(parent1.children.first, equals(child2));
      expect(parent2.children.first, equals(child1));
    });
    testWidgets('Can move node between scopes and lose scope focus', (WidgetTester tester) async {
      final BuildContext context = await setupWidget(tester);
      final FocusScopeNode scope1 = FocusScopeNode(debugLabel: 'scope1')..attach(context);
      final FocusAttachment scope1Attachment = scope1.attach(context);
      final FocusScopeNode scope2 = FocusScopeNode(debugLabel: 'scope2');
      final FocusAttachment scope2Attachment = scope2.attach(context);
      final FocusNode parent1 = FocusNode(debugLabel: 'parent1');
      final FocusAttachment parent1Attachment = parent1.attach(context);
      final FocusNode parent2 = FocusNode(debugLabel: 'parent2');
      final FocusAttachment parent2Attachment = parent2.attach(context);
      final FocusNode child1 = FocusNode(debugLabel: 'child1');
      final FocusAttachment child1Attachment = child1.attach(context);
      final FocusNode child2 = FocusNode(debugLabel: 'child2');
      final FocusAttachment child2Attachment = child2.attach(context);
      final FocusNode child3 = FocusNode(debugLabel: 'child3');
      final FocusAttachment child3Attachment = child3.attach(context);
      final FocusNode child4 = FocusNode(debugLabel: 'child4');
      final FocusAttachment child4Attachment = child4.attach(context);
      scope1Attachment.reparent(parent: tester.binding.focusManager.rootScope);
      scope2Attachment.reparent(parent: tester.binding.focusManager.rootScope);
      parent1Attachment.reparent(parent: scope1);
      parent2Attachment.reparent(parent: scope2);
      child1Attachment.reparent(parent: parent1);
      child2Attachment.reparent(parent: parent1);
      child3Attachment.reparent(parent: parent2);
      child4Attachment.reparent(parent: parent2);

      child1.requestFocus();
      await tester.pump();
      expect(scope1.focusedChild, equals(child1));
      expect(parent2.children.contains(child1), isFalse);

      child1Attachment.reparent(parent: parent2);
      await tester.pump();
      expect(scope1.focusedChild, isNull);
      expect(parent2.children.contains(child1), isTrue);
    });
    testWidgets('Can move focus between scopes and keep focus', (WidgetTester tester) async {
      final BuildContext context = await setupWidget(tester);
      final FocusScopeNode scope1 = FocusScopeNode();
      final FocusAttachment scope1Attachment = scope1.attach(context);
      final FocusScopeNode scope2 = FocusScopeNode();
      final FocusAttachment scope2Attachment = scope2.attach(context);
      final FocusNode parent1 = FocusNode();
      final FocusAttachment parent1Attachment = parent1.attach(context);
      final FocusNode parent2 = FocusNode();
      final FocusAttachment parent2Attachment = parent2.attach(context);
      final FocusNode child1 = FocusNode();
      final FocusAttachment child1Attachment = child1.attach(context);
      final FocusNode child2 = FocusNode();
      final FocusAttachment child2Attachment = child2.attach(context);
      final FocusNode child3 = FocusNode();
      final FocusAttachment child3Attachment = child3.attach(context);
      final FocusNode child4 = FocusNode();
      final FocusAttachment child4Attachment = child4.attach(context);
      scope1Attachment.reparent(parent: tester.binding.focusManager.rootScope);
      scope2Attachment.reparent(parent: tester.binding.focusManager.rootScope);
      parent1Attachment.reparent(parent: scope1);
      parent2Attachment.reparent(parent: scope2);
      child1Attachment.reparent(parent: parent1);
      child2Attachment.reparent(parent: parent1);
      child3Attachment.reparent(parent: parent2);
      child4Attachment.reparent(parent: parent2);
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
    testWidgets('Unfocus works properly', (WidgetTester tester) async {
      final BuildContext context = await setupWidget(tester);
      final FocusScopeNode scope1 = FocusScopeNode(debugLabel: 'scope1')..attach(context);
      final FocusAttachment scope1Attachment = scope1.attach(context);
      final FocusScopeNode scope2 = FocusScopeNode(debugLabel: 'scope2');
      final FocusAttachment scope2Attachment = scope2.attach(context);
      final FocusNode parent1 = FocusNode(debugLabel: 'parent1');
      final FocusAttachment parent1Attachment = parent1.attach(context);
      final FocusNode parent2 = FocusNode(debugLabel: 'parent2');
      final FocusAttachment parent2Attachment = parent2.attach(context);
      final FocusNode child1 = FocusNode(debugLabel: 'child1');
      final FocusAttachment child1Attachment = child1.attach(context);
      final FocusNode child2 = FocusNode(debugLabel: 'child2');
      final FocusAttachment child2Attachment = child2.attach(context);
      final FocusNode child3 = FocusNode(debugLabel: 'child3');
      final FocusAttachment child3Attachment = child3.attach(context);
      final FocusNode child4 = FocusNode(debugLabel: 'child4');
      final FocusAttachment child4Attachment = child4.attach(context);
      scope1Attachment.reparent(parent: tester.binding.focusManager.rootScope);
      scope2Attachment.reparent(parent: tester.binding.focusManager.rootScope);
      parent1Attachment.reparent(parent: scope1);
      parent2Attachment.reparent(parent: scope2);
      child1Attachment.reparent(parent: parent1);
      child2Attachment.reparent(parent: parent1);
      child3Attachment.reparent(parent: parent2);
      child4Attachment.reparent(parent: parent2);

      child1.requestFocus();
      await tester.pump();
      expect(scope1.focusedChild, equals(child1));
      expect(parent2.children.contains(child1), isFalse);

      child1.unfocus();
      await tester.pump();
      expect(scope1.focusedChild, isNull);
      expect(child1.hasPrimaryFocus, isFalse);
      expect(scope1.hasFocus, isFalse);

      child1.requestFocus();
      await tester.pump();
      expect(scope1.focusedChild, equals(child1));
      expect(parent2.children.contains(child1), isFalse);

      scope1.unfocus();
      await tester.pump();
      expect(scope1.focusedChild, isNull);
      expect(child1.hasPrimaryFocus, isFalse);
      expect(scope1.hasFocus, isFalse);
    });
    testWidgets('Key handling bubbles up and terminates when handled.', (WidgetTester tester) async {
      final Set<FocusNode> receivedAnEvent = <FocusNode>{};
      final Set<FocusNode> shouldHandle = <FocusNode>{};
      bool handleEvent(FocusNode node, RawKeyEvent event) {
        if (shouldHandle.contains(node)) {
          receivedAnEvent.add(node);
          return true;
        }
        return false;
      }

      void sendEvent() {
        receivedAnEvent.clear();
        sendFakeKeyEvent(<String, dynamic>{
          'type': 'keydown',
          'keymap': 'fuchsia',
          'hidUsage': 0x04,
          'codePoint': 0x64,
          'modifiers': RawKeyEventDataFuchsia.modifierLeftMeta,
        });
      }

      final BuildContext context = await setupWidget(tester);
      final FocusScopeNode scope1 = FocusScopeNode(debugLabel: 'Scope 1');
      final FocusAttachment scope1Attachment = scope1.attach(context, onKey: handleEvent);
      final FocusScopeNode scope2 = FocusScopeNode(debugLabel: 'Scope 2');
      final FocusAttachment scope2Attachment = scope2.attach(context, onKey: handleEvent);
      final FocusNode parent1 = FocusNode(debugLabel: 'Parent 1', onKey: handleEvent);
      final FocusAttachment parent1Attachment = parent1.attach(context);
      final FocusNode parent2 = FocusNode(debugLabel: 'Parent 2', onKey: handleEvent);
      final FocusAttachment parent2Attachment = parent2.attach(context);
      final FocusNode child1 = FocusNode(debugLabel: 'Child 1');
      final FocusAttachment child1Attachment = child1.attach(context, onKey: handleEvent);
      final FocusNode child2 = FocusNode(debugLabel: 'Child 2');
      final FocusAttachment child2Attachment = child2.attach(context, onKey: handleEvent);
      final FocusNode child3 = FocusNode(debugLabel: 'Child 3');
      final FocusAttachment child3Attachment = child3.attach(context, onKey: handleEvent);
      final FocusNode child4 = FocusNode(debugLabel: 'Child 4');
      final FocusAttachment child4Attachment = child4.attach(context, onKey: handleEvent);
      scope1Attachment.reparent(parent: tester.binding.focusManager.rootScope);
      scope2Attachment.reparent(parent: tester.binding.focusManager.rootScope);
      parent1Attachment.reparent(parent: scope1);
      parent2Attachment.reparent(parent: scope2);
      child1Attachment.reparent(parent: parent1);
      child2Attachment.reparent(parent: parent1);
      child3Attachment.reparent(parent: parent2);
      child4Attachment.reparent(parent: parent2);
      child4.requestFocus();
      await tester.pump();
      shouldHandle.addAll(<FocusNode>{scope2, parent2, child2, child4});
      sendEvent();
      expect(receivedAnEvent, equals(<FocusNode>{child4}));
      shouldHandle.remove(child4);
      sendEvent();
      expect(receivedAnEvent, equals(<FocusNode>{parent2}));
      shouldHandle.remove(parent2);
      sendEvent();
      expect(receivedAnEvent, equals(<FocusNode>{scope2}));
      shouldHandle.clear();
      sendEvent();
      expect(receivedAnEvent, isEmpty);
      child1.requestFocus();
      await tester.pump();
      shouldHandle.addAll(<FocusNode>{scope2, parent2, child2, child4});
      sendEvent();
      // Since none of the focused nodes handle this event, nothing should
      // receive it.
      expect(receivedAnEvent, isEmpty);
    });
    testWidgets('Events change focus highlight mode.', (WidgetTester tester) async {
      await setupWidget(tester);
      int callCount = 0;
      FocusHighlightMode lastMode;
      void handleModeChange(FocusHighlightMode mode) {
        lastMode = mode;
        callCount++;
      }

      final FocusManager focusManager = WidgetsBinding.instance.focusManager;
      focusManager.addHighlightModeListener(handleModeChange);
      addTearDown(() => focusManager.removeHighlightModeListener(handleModeChange));
      expect(callCount, equals(0));
      expect(lastMode, isNull);
      focusManager.highlightStrategy = FocusHighlightStrategy.automatic;
      expect(focusManager.highlightMode, equals(FocusHighlightMode.touch));
      sendFakeKeyEvent(<String, dynamic>{
        'type': 'keydown',
        'keymap': 'fuchsia',
        'hidUsage': 0x04,
        'codePoint': 0x64,
        'modifiers': RawKeyEventDataFuchsia.modifierLeftMeta,
      });
      expect(callCount, equals(1));
      expect(lastMode, FocusHighlightMode.traditional);
      expect(focusManager.highlightMode, equals(FocusHighlightMode.traditional));
      await tester.tap(find.byType(Container));
      expect(callCount, equals(2));
      expect(lastMode, FocusHighlightMode.touch);
      expect(focusManager.highlightMode, equals(FocusHighlightMode.touch));
      final TestGesture gesture = await tester.startGesture(Offset.zero, kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.up();
      expect(callCount, equals(3));
      expect(lastMode, FocusHighlightMode.traditional);
      expect(focusManager.highlightMode, equals(FocusHighlightMode.traditional));
      await tester.tap(find.byType(Container));
      expect(callCount, equals(4));
      expect(lastMode, FocusHighlightMode.touch);
      expect(focusManager.highlightMode, equals(FocusHighlightMode.touch));
      focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      expect(callCount, equals(5));
      expect(lastMode, FocusHighlightMode.traditional);
      expect(focusManager.highlightMode, equals(FocusHighlightMode.traditional));
      focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
      expect(callCount, equals(6));
      expect(lastMode, FocusHighlightMode.touch);
      expect(focusManager.highlightMode, equals(FocusHighlightMode.touch));
    });
    testWidgets('implements debugFillProperties', (WidgetTester tester) async {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      FocusScopeNode(
        debugLabel: 'Scope Label',
      ).debugFillProperties(builder);
      final List<String> description = builder.properties.where((DiagnosticsNode n) => !n.isFiltered(DiagnosticLevel.info)).map((DiagnosticsNode n) => n.toString()).toList();
      expect(description, <String>[
        'debugLabel: "Scope Label"',
      ]);
    });
    testWidgets('debugDescribeFocusTree produces correct output', (WidgetTester tester) async {
      final BuildContext context = await setupWidget(tester);
      final FocusScopeNode scope1 = FocusScopeNode(debugLabel: 'Scope 1');
      final FocusAttachment scope1Attachment = scope1.attach(context);
      final FocusScopeNode scope2 = FocusScopeNode(); // No label, Just to test that it works.
      final FocusAttachment scope2Attachment = scope2.attach(context);
      final FocusNode parent1 = FocusNode(debugLabel: 'Parent 1');
      final FocusAttachment parent1Attachment = parent1.attach(context);
      final FocusNode parent2 = FocusNode(debugLabel: 'Parent 2');
      final FocusAttachment parent2Attachment = parent2.attach(context);
      final FocusNode child1 = FocusNode(debugLabel: 'Child 1');
      final FocusAttachment child1Attachment = child1.attach(context);
      final FocusNode child2 = FocusNode(); // No label, Just to test that it works.
      final FocusAttachment child2Attachment = child2.attach(context);
      final FocusNode child3 = FocusNode(debugLabel: 'Child 3');
      final FocusAttachment child3Attachment = child3.attach(context);
      final FocusNode child4 = FocusNode(debugLabel: 'Child 4');
      final FocusAttachment child4Attachment = child4.attach(context);
      scope1Attachment.reparent(parent: tester.binding.focusManager.rootScope);
      scope2Attachment.reparent(parent: tester.binding.focusManager.rootScope);
      parent1Attachment.reparent(parent: scope1);
      parent2Attachment.reparent(parent: scope2);
      child1Attachment.reparent(parent: parent1);
      child2Attachment.reparent(parent: parent1);
      child3Attachment.reparent(parent: parent2);
      child4Attachment.reparent(parent: parent2);
      child4.requestFocus();
      await tester.pump();
      final String description = debugDescribeFocusTree();
      expect(
        description,
        equalsIgnoringHashCodes(
          'FocusManager#00000\n'
          ' │ primaryFocus: FocusNode#00000\n'
          ' │ primaryFocusCreator: Container-[GlobalKey#00000] ← [root]\n'
          ' │\n'
          ' └─rootScope: FocusScopeNode#00000\n'
          '   │ FOCUSED\n'
          '   │ debugLabel: "Root Focus Scope"\n'
          '   │ focusedChild: FocusScopeNode#00000\n'
          '   │\n'
          '   ├─Child 1: FocusScopeNode#00000\n'
          '   │ │ context: Container-[GlobalKey#00000]\n'
          '   │ │ debugLabel: "Scope 1"\n'
          '   │ │\n'
          '   │ └─Child 1: FocusNode#00000\n'
          '   │   │ context: Container-[GlobalKey#00000]\n'
          '   │   │ debugLabel: "Parent 1"\n'
          '   │   │\n'
          '   │   ├─Child 1: FocusNode#00000\n'
          '   │   │   context: Container-[GlobalKey#00000]\n'
          '   │   │   debugLabel: "Child 1"\n'
          '   │   │\n'
          '   │   └─Child 2: FocusNode#00000\n'
          '   │       context: Container-[GlobalKey#00000]\n'
          '   │\n'
          '   └─Child 2: FocusScopeNode#00000\n'
          '     │ context: Container-[GlobalKey#00000]\n'
          '     │ FOCUSED\n'
          '     │ focusedChild: FocusNode#00000\n'
          '     │\n'
          '     └─Child 1: FocusNode#00000\n'
          '       │ context: Container-[GlobalKey#00000]\n'
          '       │ FOCUSED\n'
          '       │ debugLabel: "Parent 2"\n'
          '       │\n'
          '       ├─Child 1: FocusNode#00000\n'
          '       │   context: Container-[GlobalKey#00000]\n'
          '       │   debugLabel: "Child 3"\n'
          '       │\n'
          '       └─Child 2: FocusNode#00000\n'
          '           context: Container-[GlobalKey#00000]\n'
          '           FOCUSED\n'
          '           debugLabel: "Child 4"\n'
        ));
    });
  });
}
