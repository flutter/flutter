// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('chrome || safari || firefox')
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:quiver/testing/async.dart';
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import 'semantics_tester.dart';

DateTime _testTime = DateTime(2018, 12, 17);

EngineSemanticsOwner semantics() => EngineSemanticsOwner.instance;

DomShadowRoot get renderingHost =>
    EnginePlatformDispatcher.instance.implicitView!.dom.renderingHost;
DomElement get platformViewsHost =>
    EnginePlatformDispatcher.instance.implicitView!.dom.platformViewsHost;

void main() {
  internalBootstrapBrowserTest(() {
    return testMain;
  });
}

Future<void> testMain() async {
  await ui_web.bootstrapEngine();
  runSemanticsTests();
}

void runSemanticsTests() {
  setUp(() {
    EngineSemanticsOwner.debugResetSemantics();
  });

  group(EngineSemanticsOwner, () {
    _testEngineSemanticsOwner();
  });
  group('longestIncreasingSubsequence', () {
    _testLongestIncreasingSubsequence();
  });
  group('Role managers', () {
    _testRoleManagerLifecycle();
  });
  group('container', () {
    _testContainer();
  });
  group('vertical scrolling', () {
    _testVerticalScrolling();
  });
  group('horizontal scrolling', () {
    _testHorizontalScrolling();
  });
  group('incrementable', () {
    _testIncrementables();
  });
  group('text field', () {
    _testTextField();
  });
  group('checkboxes, radio buttons and switches', () {
    _testCheckables();
  });
  group('tappable', () {
    _testTappable();
  });
  group('image', () {
    _testImage();
  });
  group('header', () {
    _testHeader();
  });
  group('live region', () {
    _testLiveRegion();
  });
  group('platform view', () {
    _testPlatformView();
  });
  group('accessibility builder', () {
    _testEngineAccessibilityBuilder();
  });
  group('group', () {
    _testGroup();
  });
  group('dialog', () {
    _testDialog();
  });
  group('focusable', () {
    _testFocusable();
  });
  group('link', () {
    _testLink();
  });
}

void _testRoleManagerLifecycle() {
  test('Secondary role managers are added upon node initialization', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    // Check that roles are initialized immediately
    {
      final SemanticsTester tester = SemanticsTester(semantics());
      tester.updateNode(
        id: 0,
        isButton: true,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();

      expectSemanticsTree('<sem role="button" style="$rootSemanticStyle"></sem>');

      final SemanticsObject node = semantics().debugSemanticsTree![0]!;
      expect(node.primaryRole?.role, PrimaryRole.button);
      expect(
        node.primaryRole?.debugSecondaryRoles,
        containsAll(<Role>[Role.focusable, Role.tappable, Role.labelAndValue]),
      );
      expect(tester.getSemanticsObject(0).element.tabIndex, -1);
    }

    // Check that roles apply their functionality upon update.
    {
      final SemanticsTester tester = SemanticsTester(semantics());
      tester.updateNode(
        id: 0,
        label: 'a label',
        isFocusable: true,
        isButton: true,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();

      expectSemanticsTree('<sem aria-label="a label" role="button" style="$rootSemanticStyle"></sem>');

      final SemanticsObject node = semantics().debugSemanticsTree![0]!;
      expect(node.primaryRole?.role, PrimaryRole.button);
      expect(
        node.primaryRole?.debugSecondaryRoles,
        containsAll(<Role>[Role.focusable, Role.tappable, Role.labelAndValue]),
      );
      expect(tester.getSemanticsObject(0).element.tabIndex, 0);
    }

    semantics().semanticsEnabled = false;
  });
}

void _testEngineAccessibilityBuilder() {
  final EngineAccessibilityFeaturesBuilder builder =
      EngineAccessibilityFeaturesBuilder(0);
  EngineAccessibilityFeatures features = builder.build();

  test('accessible navigation', () {
    expect(features.accessibleNavigation, isFalse);
    builder.accessibleNavigation = true;
    features = builder.build();
    expect(features.accessibleNavigation, isTrue);
  });

  test('bold text', () {
    expect(features.boldText, isFalse);
    builder.boldText = true;
    features = builder.build();
    expect(features.boldText, isTrue);
  });

  test('disable animations', () {
    expect(features.disableAnimations, isFalse);
    builder.disableAnimations = true;
    features = builder.build();
    expect(features.disableAnimations, isTrue);
  });

  test('high contrast', () {
    expect(features.highContrast, isFalse);
    builder.highContrast = true;
    features = builder.build();
    expect(features.highContrast, isTrue);
  });

  test('invert colors', () {
    expect(features.invertColors, isFalse);
    builder.invertColors = true;
    features = builder.build();
    expect(features.invertColors, isTrue);
  });

  test('on off switch labels', () {
    expect(features.onOffSwitchLabels, isFalse);
    builder.onOffSwitchLabels = true;
    features = builder.build();
    expect(features.onOffSwitchLabels, isTrue);
  });

  test('reduce motion', () {
    expect(features.reduceMotion, isFalse);
    builder.reduceMotion = true;
    features = builder.build();
    expect(features.reduceMotion, isTrue);
  });
}

void _testEngineSemanticsOwner() {
  test('instantiates a singleton', () {
    expect(semantics(), same(semantics()));
  });

  test('semantics is off by default', () {
    expect(semantics().semanticsEnabled, isFalse);
  });

  test('default mode is "unknown"', () {
    expect(semantics().mode, AccessibilityMode.unknown);
  });

  test('placeholder enables semantics', () async {
    flutterViewEmbedder.reset(); // triggers `autoEnableOnTap` to be called
    expect(semantics().semanticsEnabled, isFalse);

    // Synthesize a click on the placeholder.
    final DomElement placeholder =
        renderingHost.querySelector('flt-semantics-placeholder')!;

    expect(placeholder.isConnected, isTrue);

    final DomRect rect = placeholder.getBoundingClientRect();
    placeholder.dispatchEvent(createDomMouseEvent('click', <Object?, Object?>{
      'clientX': (rect.left + (rect.right - rect.left) / 2).floor(),
      'clientY': (rect.top + (rect.bottom - rect.top) / 2).floor(),
    }));

    // On mobile semantics is enabled asynchronously.
    if (isMobile) {
      while (placeholder.isConnected!) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
    expect(semantics().semanticsEnabled, isTrue);
    expect(placeholder.isConnected, isFalse);
  });

  test('accessibilityFeatures copyWith function works', () {
    const EngineAccessibilityFeatures original = EngineAccessibilityFeatures(0);
    EngineAccessibilityFeatures copy =
        original.copyWith(accessibleNavigation: true);
    expect(copy.accessibleNavigation, true);
    expect(copy.boldText, false);
    expect(copy.disableAnimations, false);
    expect(copy.highContrast, false);
    expect(copy.invertColors, false);
    expect(copy.onOffSwitchLabels, false);
    expect(copy.reduceMotion, false);

    copy = original.copyWith(boldText: true);
    expect(copy.accessibleNavigation, false);
    expect(copy.boldText, true);
    expect(copy.disableAnimations, false);
    expect(copy.highContrast, false);
    expect(copy.invertColors, false);
    expect(copy.onOffSwitchLabels, false);
    expect(copy.reduceMotion, false);

    copy = original.copyWith(disableAnimations: true);
    expect(copy.accessibleNavigation, false);
    expect(copy.boldText, false);
    expect(copy.disableAnimations, true);
    expect(copy.highContrast, false);
    expect(copy.invertColors, false);
    expect(copy.onOffSwitchLabels, false);
    expect(copy.reduceMotion, false);

    copy = original.copyWith(highContrast: true);
    expect(copy.accessibleNavigation, false);
    expect(copy.boldText, false);
    expect(copy.disableAnimations, false);
    expect(copy.highContrast, true);
    expect(copy.invertColors, false);
    expect(copy.onOffSwitchLabels, false);
    expect(copy.reduceMotion, false);

    copy = original.copyWith(invertColors: true);
    expect(copy.accessibleNavigation, false);
    expect(copy.boldText, false);
    expect(copy.disableAnimations, false);
    expect(copy.highContrast, false);
    expect(copy.invertColors, true);
    expect(copy.onOffSwitchLabels, false);
    expect(copy.reduceMotion, false);

    copy = original.copyWith(onOffSwitchLabels: true);
    expect(copy.accessibleNavigation, false);
    expect(copy.boldText, false);
    expect(copy.disableAnimations, false);
    expect(copy.highContrast, false);
    expect(copy.invertColors, false);
    expect(copy.onOffSwitchLabels, true);
    expect(copy.reduceMotion, false);

    copy = original.copyWith(reduceMotion: true);
    expect(copy.accessibleNavigation, false);
    expect(copy.boldText, false);
    expect(copy.disableAnimations, false);
    expect(copy.highContrast, false);
    expect(copy.invertColors, false);
    expect(copy.onOffSwitchLabels, false);
    expect(copy.reduceMotion, true);
  });

  test('auto-enables semantics', () async {
    flutterViewEmbedder.reset(); // triggers `autoEnableOnTap` to be called
    expect(semantics().semanticsEnabled, isFalse);
    expect(
        EnginePlatformDispatcher
            .instance.accessibilityFeatures.accessibleNavigation,
        isFalse);

    final DomElement placeholder =
        renderingHost.querySelector('flt-semantics-placeholder')!;

    expect(placeholder.isConnected, isTrue);

    // Sending a semantics update should auto-enable engine semantics.
    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(builder);
    semantics().updateSemantics(builder.build());

    expect(semantics().semanticsEnabled, isTrue);
    expect(
        EnginePlatformDispatcher
            .instance.accessibilityFeatures.accessibleNavigation,
        isTrue);

    // The placeholder should be removed
    expect(placeholder.isConnected, isFalse);
  });

  void renderSemantics({String? label, String? tooltip, Set<ui.SemanticsFlag> flags = const <ui.SemanticsFlag>{}}) {
    int flagValues = 0;
    for (final ui.SemanticsFlag flag in flags) {
      flagValues = flagValues | flag.index;
    }
    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 20, 20),
      childrenInHitTestOrder: Int32List.fromList(<int>[1]),
      childrenInTraversalOrder: Int32List.fromList(<int>[1]),
    );
    updateNode(
      builder,
      id: 1,
      label: label ?? '',
      tooltip: tooltip ?? '',
      flags: flagValues,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 20, 20),
    );
    semantics().updateSemantics(builder.build());
  }

  void renderLabel(String label) {
    renderSemantics(label: label);
  }

  test('produces an aria-label', () async {
    semantics().semanticsEnabled = true;

    // Create
    renderLabel('Hello');

    final Map<int, SemanticsObject> tree = semantics().debugSemanticsTree!;
    expect(tree.length, 2);
    expect(tree[0]!.id, 0);
    expect(tree[0]!.element.tagName.toLowerCase(), 'flt-semantics');
    expect(tree[1]!.id, 1);
    expect(tree[1]!.label, 'Hello');

    expectSemanticsTree('''
<sem style="$rootSemanticStyle">
  <sem-c>
    <sem role="text" aria-label="Hello"></sem>
  </sem-c>
</sem>''');

    // Update
    renderLabel('World');

    expectSemanticsTree('''
<sem style="$rootSemanticStyle">
  <sem-c>
    <sem role="text" aria-label="World"></sem>
  </sem-c>
</sem>''');

    // Remove
    renderLabel('');

    expectSemanticsTree('''
<sem style="$rootSemanticStyle">
  <sem-c>
    <sem role="text"></sem>
  </sem-c>
</sem>''');

    semantics().semanticsEnabled = false;
  });

  test('can switch role', () async {
    semantics().semanticsEnabled = true;

    // Create
    renderSemantics(label: 'Hello');

    Map<int, SemanticsObject> tree = semantics().debugSemanticsTree!;
    expect(tree.length, 2);
    expect(tree[1]!.element.tagName.toLowerCase(), 'flt-semantics');
    expect(tree[1]!.id, 1);
    expect(tree[1]!.label, 'Hello');
    final DomElement existingParent = tree[1]!.element.parent!;

    expectSemanticsTree('''
<sem style="$rootSemanticStyle">
  <sem-c>
    <sem aria-label="Hello" role="text"></sem>
  </sem-c>
</sem>''');

    // Update
    renderSemantics(label: 'Hello', flags: <ui.SemanticsFlag>{ ui.SemanticsFlag.isLink });

    tree = semantics().debugSemanticsTree!;
    expect(tree.length, 2);
    expect(tree[1]!.id, 1);
    expect(tree[1]!.label, 'Hello');
    expect(tree[1]!.element.tagName.toLowerCase(), 'a');
    expectSemanticsTree('''
<sem style="$rootSemanticStyle">
  <sem-c>
    <a aria-label="Hello" style="display: block;"></a>
  </sem-c>
</sem>''');
    expect(existingParent, tree[1]!.element.parent);

    semantics().semanticsEnabled = false;
  });

  test('tooltip is part of label', () async {
    semantics().semanticsEnabled = true;

    // Create
    renderSemantics(tooltip: 'tooltip');

    final Map<int, SemanticsObject> tree = semantics().debugSemanticsTree!;
    expect(tree.length, 2);
    expect(tree[0]!.id, 0);
    expect(tree[0]!.element.tagName.toLowerCase(), 'flt-semantics');
    expect(tree[1]!.id, 1);
    expect(tree[1]!.tooltip, 'tooltip');

    expectSemanticsTree('''
<sem style="$rootSemanticStyle">
  <sem-c>
    <sem aria-label="tooltip"></sem>
  </sem-c>
</sem>''');

    // Update
    renderSemantics(label: 'Hello', tooltip: 'tooltip');

    expectSemanticsTree('''
<sem style="$rootSemanticStyle">
  <sem-c>
    <sem role="text" aria-label="tooltip\nHello"></sem>
  </sem-c>
</sem>''');

    // Remove
    renderSemantics();

    expectSemanticsTree('''
<sem style="$rootSemanticStyle">
  <sem-c>
    <sem role="text"></sem>
  </sem-c>
</sem>''');

    semantics().semanticsEnabled = false;
  });

  test('clears semantics tree when disabled', () {
    expect(semantics().debugSemanticsTree, isEmpty);
    semantics().semanticsEnabled = true;
    renderLabel('Hello');
    expect(semantics().debugSemanticsTree, isNotEmpty);
    semantics().semanticsEnabled = false;
    expect(semantics().debugSemanticsTree, isEmpty);
  });

  test('accepts standalone browser gestures', () {
    semantics().semanticsEnabled = true;
    expect(semantics().shouldAcceptBrowserGesture('click'), isTrue);
    semantics().semanticsEnabled = false;
  });

  test('rejects browser gestures accompanied by pointer click', () {
    FakeAsync().run((FakeAsync fakeAsync) {
      semantics()
        ..debugOverrideTimestampFunction(fakeAsync.getClock(_testTime).now)
        ..semanticsEnabled = true;
      expect(semantics().shouldAcceptBrowserGesture('click'), isTrue);
      semantics().receiveGlobalEvent(createDomEvent('Event', 'pointermove'));
      expect(semantics().shouldAcceptBrowserGesture('click'), isFalse);

      // After 1 second of inactivity a browser gestures counts as standalone.
      fakeAsync.elapse(const Duration(seconds: 1));
      expect(semantics().shouldAcceptBrowserGesture('click'), isTrue);
      semantics().semanticsEnabled = false;
    });
  });
  test('checks shouldEnableSemantics for every global event', () {
    final MockSemanticsEnabler mockSemanticsEnabler = MockSemanticsEnabler();
    semantics().semanticsHelper.semanticsEnabler = mockSemanticsEnabler;
    final DomEvent pointerEvent = createDomEvent('Event', 'pointermove');

    semantics().receiveGlobalEvent(pointerEvent);

    // Verify the interactions.
    expect(
      mockSemanticsEnabler.shouldEnableSemanticsEvents,
      <DomEvent>[pointerEvent],
    );
  });

  test('forwards events to framework if shouldEnableSemantics returns true',
      () {
    final MockSemanticsEnabler mockSemanticsEnabler = MockSemanticsEnabler();
    semantics().semanticsHelper.semanticsEnabler = mockSemanticsEnabler;
    final DomEvent pointerEvent = createDomEvent('Event', 'pointermove');
    mockSemanticsEnabler.shouldEnableSemanticsReturnValue = true;
    expect(semantics().receiveGlobalEvent(pointerEvent), isTrue);
  });

  test('semantics owner update phases', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    expect(
      reason: 'Should start in idle phase',
      semantics().phase,
      SemanticsUpdatePhase.idle,
    );

    void pumpSemantics({ required String label }) {
      final SemanticsTester tester = SemanticsTester(semantics());
      tester.updateNode(
        id: 0,
        children: <SemanticsNodeUpdate>[
          tester.updateNode(id: 1, label: label),
        ],
      );
      tester.apply();
    }

    SemanticsUpdatePhase? capturedPostUpdateCallbackPhase;
    semantics().addOneTimePostUpdateCallback(() {
      capturedPostUpdateCallbackPhase = semantics().phase;
    });

    pumpSemantics(label: 'Hello');

    final SemanticsObject semanticsObject = semantics().debugSemanticsTree![1]!;

    expect(
      reason: 'Should be in postUpdate phase while calling post-update callbacks',
      capturedPostUpdateCallbackPhase,
      SemanticsUpdatePhase.postUpdate,
    );
    expect(
      reason: 'After the update is done, should go back to idle',
      semantics().phase,
      SemanticsUpdatePhase.idle,
    );

    // Rudely replace the role manager with a mock, and trigger an update.
    final MockRoleManager mockRoleManager = MockRoleManager(PrimaryRole.generic, semanticsObject);
    semanticsObject.primaryRole = mockRoleManager;

    pumpSemantics(label: 'World');

    expect(
      reason: 'While updating must be in SemanticsUpdatePhase.updating phase',
      mockRoleManager.log,
      <MockRoleManagerLogEntry>[
        (method: 'update', phase: SemanticsUpdatePhase.updating),
      ],
    );

    semantics().semanticsEnabled = false;
  });
}

typedef MockRoleManagerLogEntry = ({
  String method,
  SemanticsUpdatePhase phase,
});

class MockRoleManager extends PrimaryRoleManager {
  MockRoleManager(super.role, super.semanticsObject) : super.blank();

  final List<MockRoleManagerLogEntry> log = <MockRoleManagerLogEntry>[];

  void _log(String method) {
    log.add((
      method: method,
      phase: semanticsObject.owner.phase,
    ));
  }

  @override
  void update() {
    super.update();
    _log('update');
  }
}

class MockSemanticsEnabler implements SemanticsEnabler {
  @override
  void dispose() {}

  @override
  bool get isWaitingToEnableSemantics => throw UnimplementedError();

  @override
  DomElement prepareAccessibilityPlaceholder() {
    throw UnimplementedError();
  }

  bool shouldEnableSemanticsReturnValue = false;
  final List<DomEvent> shouldEnableSemanticsEvents = <DomEvent>[];

  @override
  bool shouldEnableSemantics(DomEvent event) {
    shouldEnableSemanticsEvents.add(event);
    return shouldEnableSemanticsReturnValue;
  }

  @override
  bool tryEnableSemantics(DomEvent event) {
    throw UnimplementedError();
  }
}

void _testHeader() {
  test('renders heading role for headers', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      flags: 0 | ui.SemanticsFlag.isHeader.index,
      label: 'Header of the page',
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem role="heading" aria-label="Header of the page" style="$rootSemanticStyle"></sem>
''');

    semantics().semanticsEnabled = false;
  });

  // When a header has child elements, role="heading" prevents AT from reaching
  // child elements. To fix that role="group" is used, even though that causes
  // the heading to not be announced as a heading. If the app really needs the
  // heading to be announced as a heading, the developer can restructure the UI
  // such that the heading is not a parent node, but a side-note, e.g. preceding
  // the child list.
  test('uses group role for headers when children are present', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      flags: 0 | ui.SemanticsFlag.isHeader.index,
      label: 'Header of the page',
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      childrenInHitTestOrder: Int32List.fromList(<int>[1]),
      childrenInTraversalOrder: Int32List.fromList(<int>[1]),
    );
    updateNode(
      builder,
      id: 1,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem role="group" aria-label="Header of the page" style="$rootSemanticStyle"><sem-c><sem></sem></sem-c></sem>
''');

    semantics().semanticsEnabled = false;
  });
}

void _testLongestIncreasingSubsequence() {
  void expectLis(List<int> list, List<int> seq) {
    expect(longestIncreasingSubsequence(list), seq);
  }

  test('trivial case', () {
    expectLis(<int>[], <int>[]);
  });

  test('longest in the middle', () {
    expectLis(<int>[10, 1, 2, 3, 0], <int>[1, 2, 3]);
  });

  test('longest at head', () {
    expectLis(<int>[1, 2, 3, 0], <int>[0, 1, 2]);
  });

  test('longest at tail', () {
    expectLis(<int>[10, 1, 2, 3], <int>[1, 2, 3]);
  });

  test('longest in a jagged pattern', () {
    expectLis(
        <int>[0, 1, -1, 2, -2, 3, -3, 4, -4, 5, -5], <int>[0, 1, 3, 5, 7, 9]);
  });

  test('fully sorted up', () {
    for (int count = 0; count < 100; count += 1) {
      expectLis(
        List<int>.generate(count, (int i) => 10 * i),
        List<int>.generate(count, (int i) => i),
      );
    }
  });

  test('fully sorted down', () {
    for (int count = 1; count < 100; count += 1) {
      expectLis(
        List<int>.generate(count, (int i) => 10 * (count - i)),
        <int>[count - 1],
      );
    }
  });
}

void _testContainer() {
  test('container node has no transform when there is no rect offset',
      () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    const ui.Rect zeroOffsetRect = ui.Rect.fromLTRB(0, 0, 20, 20);
    updateNode(
      builder,
      transform: Matrix4.identity().toFloat64(),
      rect: zeroOffsetRect,
      childrenInHitTestOrder: Int32List.fromList(<int>[1]),
      childrenInTraversalOrder: Int32List.fromList(<int>[1]),
    );
    updateNode(
      builder,
      id: 1,
      transform: Matrix4.identity().toFloat64(),
      rect: zeroOffsetRect,
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem style="$rootSemanticStyle">
  <sem-c>
    <sem></sem>
  </sem-c>
</sem>''');

    final DomElement parentElement =
        rootElement.querySelector('flt-semantics')!;
    final DomElement container =
        rootElement.querySelector('flt-semantics-container')!;

    if (isMacOrIOS) {
      expect(parentElement.style.top, '0px');
      expect(parentElement.style.left, '0px');
      expect(container.style.top, '0px');
      expect(container.style.left, '0px');
    } else {
      expect(parentElement.style.top, '');
      expect(parentElement.style.left, '');
      expect(container.style.top, '');
      expect(container.style.left, '');
    }
    expect(parentElement.style.transform, '');
    expect(parentElement.style.transformOrigin, '');
    expect(container.style.transform, '');
    expect(container.style.transformOrigin, '');
    semantics().semanticsEnabled = false;
  });

  test('container node compensates for rect offset', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(10, 10, 20, 20),
      childrenInHitTestOrder: Int32List.fromList(<int>[1]),
      childrenInTraversalOrder: Int32List.fromList(<int>[1]),
    );
    updateNode(
      builder,
      id: 1,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(10, 10, 20, 20),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem style="$rootSemanticStyle">
  <sem-c>
    <sem></sem>
  </sem-c>
</sem>''');

    final DomElement parentElement =
        rootElement.querySelector('flt-semantics')!;
    final DomElement container =
        rootElement.querySelector('flt-semantics-container')!;

    expect(parentElement.style.transform, 'matrix(1, 0, 0, 1, 10, 10)');
    expect(parentElement.style.transformOrigin, '0px 0px 0px');
    expect(container.style.top, '-10px');
    expect(container.style.left, '-10px');
    semantics().semanticsEnabled = false;
  });

  test('0 offsets are not removed for voiceover', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 20, 20),
      childrenInHitTestOrder: Int32List.fromList(<int>[1]),
      childrenInTraversalOrder: Int32List.fromList(<int>[1]),
    );
    updateNode(
      builder,
      id: 1,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(10, 10, 20, 20),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem style="$rootSemanticStyle">
  <sem-c>
    <sem></sem>
  </sem-c>
</sem>''');

    final DomElement parentElement =
        rootElement.querySelector('flt-semantics')!;
    final DomElement container =
        rootElement.querySelector('flt-semantics-container')!;

    if (isMacOrIOS) {
      expect(parentElement.style.top, '0px');
      expect(parentElement.style.left, '0px');
      expect(container.style.top, '0px');
      expect(container.style.left, '0px');
    } else {
      expect(parentElement.style.top, '');
      expect(parentElement.style.left, '');
      expect(container.style.top, '');
      expect(container.style.left, '');
    }
    expect(parentElement.style.transform, '');
    expect(parentElement.style.transformOrigin, '');
    expect(container.style.transform, '');
    expect(container.style.transformOrigin, '');

    semantics().semanticsEnabled = false;
  });

  test('renders in traversal order, hit-tests in reverse z-index order',
      () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    // State 1: render initial tree with middle elements swapped hit-test wise
    {
      final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
      updateNode(
        builder,
        childrenInTraversalOrder: Int32List.fromList(<int>[1, 2, 3, 4]),
        childrenInHitTestOrder: Int32List.fromList(<int>[1, 3, 2, 4]),
      );

      for (int id = 1; id <= 4; id++) {
        updateNode(builder, id: id);
      }

      semantics().updateSemantics(builder.build());
      expectSemanticsTree('''
<sem style="$rootSemanticStyle">
  <sem-c>
    <sem style="z-index: 4"></sem>
    <sem style="z-index: 2"></sem>
    <sem style="z-index: 3"></sem>
    <sem style="z-index: 1"></sem>
  </sem-c>
</sem>''');
    }

    // State 2: update z-index
    {
      final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
      updateNode(
        builder,
        childrenInTraversalOrder: Int32List.fromList(<int>[1, 2, 3, 4]),
        childrenInHitTestOrder: Int32List.fromList(<int>[1, 2, 3, 4]),
      );
      semantics().updateSemantics(builder.build());
      expectSemanticsTree('''
<sem style="$rootSemanticStyle">
  <sem-c>
    <sem style="z-index: 4"></sem>
    <sem style="z-index: 3"></sem>
    <sem style="z-index: 2"></sem>
    <sem style="z-index: 1"></sem>
  </sem-c>
</sem>''');
    }

    // State 3: update traversal order
    {
      final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
      updateNode(
        builder,
        childrenInTraversalOrder: Int32List.fromList(<int>[4, 2, 3, 1]),
        childrenInHitTestOrder: Int32List.fromList(<int>[1, 2, 3, 4]),
      );
      semantics().updateSemantics(builder.build());
      expectSemanticsTree('''
<sem style="$rootSemanticStyle">
  <sem-c>
    <sem style="z-index: 1"></sem>
    <sem style="z-index: 3"></sem>
    <sem style="z-index: 2"></sem>
    <sem style="z-index: 4"></sem>
  </sem-c>
</sem>''');
    }

    // State 3: update both orders
    {
      final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
      updateNode(
        builder,
        childrenInTraversalOrder: Int32List.fromList(<int>[1, 3, 2, 4]),
        childrenInHitTestOrder: Int32List.fromList(<int>[3, 4, 1, 2]),
      );
      semantics().updateSemantics(builder.build());
      expectSemanticsTree('''
<sem style="$rootSemanticStyle">
  <sem-c>
    <sem style="z-index: 2"></sem>
    <sem style="z-index: 4"></sem>
    <sem style="z-index: 1"></sem>
    <sem style="z-index: 3"></sem>
  </sem-c>
</sem>''');
    }

    semantics().semanticsEnabled = false;
  });

  test(
      'container nodes are transparent and leaf children are opaque hit-test wise',
      () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      childrenInTraversalOrder: Int32List.fromList(<int>[1, 2]),
      childrenInHitTestOrder: Int32List.fromList(<int>[1, 2]),
    );
    updateNode(builder, id: 1);
    updateNode(builder, id: 2);

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem style="$rootSemanticStyle">
  <sem-c>
    <sem style="z-index: 2"></sem>
    <sem style="z-index: 1"></sem>
  </sem-c>
</sem>''');

    final DomElement root = rootElement.querySelector('#flt-semantic-node-0')!;
    expect(root.style.pointerEvents, 'none');

    final DomElement child1 =
        rootElement.querySelector('#flt-semantic-node-1')!;
    expect(child1.style.pointerEvents, 'all');

    final DomElement child2 =
        rootElement.querySelector('#flt-semantic-node-2')!;
    expect(child2.style.pointerEvents, 'all');

    semantics().semanticsEnabled = false;
  });

  test('descendant nodes are removed from the node map, unless reparented', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    {
      final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
      updateNode(
        builder,
        childrenInTraversalOrder: Int32List.fromList(<int>[1, 2]),
        childrenInHitTestOrder: Int32List.fromList(<int>[1, 2]),
      );
      updateNode(
        builder,
        id: 1,
        childrenInTraversalOrder: Int32List.fromList(<int>[3, 4]),
        childrenInHitTestOrder: Int32List.fromList(<int>[3, 4]),
      );
      updateNode(
        builder,
        id: 2,
        childrenInTraversalOrder: Int32List.fromList(<int>[5, 6]),
        childrenInHitTestOrder: Int32List.fromList(<int>[5, 6]),
      );
      updateNode(builder, id: 3);
      updateNode(builder, id: 4);
      updateNode(builder, id: 5);
      updateNode(builder, id: 6);

      semantics().updateSemantics(builder.build());
      expectSemanticsTree('''
  <sem style="$rootSemanticStyle">
    <sem-c>
      <sem style="z-index: 2">
        <sem-c>
          <sem style="z-index: 2"></sem>
          <sem style="z-index: 1"></sem>
        </sem-c>
      </sem>
      <sem style="z-index: 1">
        <sem-c>
          <sem style="z-index: 2"></sem>
          <sem style="z-index: 1"></sem>
        </sem-c>
      </sem>
    </sem-c>
  </sem>''');

      expect(EngineSemanticsOwner.instance.debugSemanticsTree!.keys.toList(), unorderedEquals(<int>[0, 1, 2, 3, 4, 5, 6]));
    }

    // Remove node #2 => expect nodes #2 and #5 to be removed and #6 reparented.
    {
      final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
      updateNode(
        builder,
        childrenInTraversalOrder: Int32List.fromList(<int>[1]),
        childrenInHitTestOrder: Int32List.fromList(<int>[1]),
      );
      updateNode(
        builder,
        id: 1,
        childrenInTraversalOrder: Int32List.fromList(<int>[3, 4, 6]),
        childrenInHitTestOrder: Int32List.fromList(<int>[3, 4, 6]),
      );

      semantics().updateSemantics(builder.build());
      expectSemanticsTree('''
  <sem style="$rootSemanticStyle">
    <sem-c>
      <sem style="z-index: 2">
        <sem-c>
          <sem style="z-index: 3"></sem>
          <sem style="z-index: 2"></sem>
          <sem style="z-index: 1"></sem>
        </sem-c>
      </sem>
    </sem-c>
  </sem>''');

      expect(EngineSemanticsOwner.instance.debugSemanticsTree!.keys.toList(), unorderedEquals(<int>[0, 1, 3, 4, 6]));
    }

    semantics().semanticsEnabled = false;
  });
}

void _testVerticalScrolling() {
  test('renders an empty scrollable node', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.scrollUp.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 50, 100),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem style="$rootSemanticStyle; touch-action: none; overflow-y: scroll">
<flt-semantics-scroll-overflow></flt-semantics-scroll-overflow>
</sem>''');

    final DomElement? scrollable = findScrollable();
    expect(scrollable!.scrollTop, isPositive);
    semantics().semanticsEnabled = false;
  });

  test('scrollable node with children has a container node', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.scrollUp.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 50, 100),
      childrenInHitTestOrder: Int32List.fromList(<int>[1]),
      childrenInTraversalOrder: Int32List.fromList(<int>[1]),
    );
    updateNode(
      builder,
      id: 1,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(10, 10, 20, 20),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem style="$rootSemanticStyle; touch-action: none; overflow-y: scroll">
<flt-semantics-scroll-overflow></flt-semantics-scroll-overflow>
  <sem-c>
    <sem></sem>
  </sem-c>
</sem>''');

    final DomElement? scrollable = findScrollable();
    expect(scrollable, isNotNull);

    // When there's less content than the available size the neutral scrollTop
    // is still a positive number.
    expect(scrollable!.scrollTop, isPositive);

    semantics().semanticsEnabled = false;
  });

  test('scrollable node dispatches scroll events', () async {
    final StreamController<int> idLogController = StreamController<int>();
    final StreamController<ui.SemanticsAction> actionLogController =
        StreamController<ui.SemanticsAction>();
    final Stream<int> idLog = idLogController.stream.asBroadcastStream();
    final Stream<ui.SemanticsAction> actionLog =
        actionLogController.stream.asBroadcastStream();

    // The browser kicks us out of the test zone when the scroll event happens.
    // We memorize the test zone so we can call expect when the callback is
    // fired.
    final Zone testZone = Zone.current;

    ui.PlatformDispatcher.instance.onSemanticsActionEvent =
        (ui.SemanticsActionEvent event) {
      idLogController.add(event.nodeId);
      actionLogController.add(event.type);
      testZone.run(() {
        expect(event.arguments, null);
      });
    };
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 |
          ui.SemanticsAction.scrollUp.index |
          ui.SemanticsAction.scrollDown.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 50, 100),
      childrenInHitTestOrder: Int32List.fromList(<int>[1, 2, 3]),
      childrenInTraversalOrder: Int32List.fromList(<int>[1, 2, 3]),
    );

    for (int id = 1; id <= 3; id++) {
      updateNode(
        builder,
        id: id,
        transform: Matrix4.translationValues(0, 50.0 * id, 0).toFloat64(),
        rect: const ui.Rect.fromLTRB(0, 0, 50, 50),
      );
    }

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem style="$rootSemanticStyle; touch-action: none; overflow-y: scroll">
  <flt-semantics-scroll-overflow></flt-semantics-scroll-overflow>
  <sem-c>
    <sem style="z-index: 3"></sem>
    <sem style="z-index: 2"></sem>
    <sem style="z-index: 1"></sem>
  </sem-c>
</sem>''');

    final DomElement? scrollable = findScrollable();
    expect(scrollable, isNotNull);

    // When there's more content than the available size the neutral scrollTop
    // is greater than 0 with a maximum of 10 or 9.
    int browserMaxScrollDiff = 0;
    // The max scroll value varies between `9` and `10` for Safari desktop
    // browsers.
    if (browserEngine == BrowserEngine.webkit &&
        operatingSystem == OperatingSystem.macOs) {
      browserMaxScrollDiff = 1;
    }

    expect(scrollable!.scrollTop >= (10 - browserMaxScrollDiff), isTrue);

    scrollable.scrollTop = 20;
    expect(scrollable.scrollTop, 20);
    expect(await idLog.first, 0);
    expect(await actionLog.first, ui.SemanticsAction.scrollUp);
    // Engine semantics returns scroll top back to neutral.
    expect(scrollable.scrollTop >= (10 - browserMaxScrollDiff), isTrue);

    scrollable.scrollTop = 5;
    expect(scrollable.scrollTop >= (5 - browserMaxScrollDiff), isTrue);
    expect(await idLog.first, 0);
    expect(await actionLog.first, ui.SemanticsAction.scrollDown);
    // Engine semantics returns scroll top back to neutral.
    expect(scrollable.scrollTop >= (10 - browserMaxScrollDiff), isTrue);

    semantics().semanticsEnabled = false;
  }, skip: isWasm); // https://github.com/dart-lang/sdk/issues/50778
}

void _testHorizontalScrolling() {
  test('renders an empty scrollable node', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.scrollLeft.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem style="$rootSemanticStyle; touch-action: none; overflow-x: scroll">
<flt-semantics-scroll-overflow></flt-semantics-scroll-overflow>
</sem>''');

    semantics().semanticsEnabled = false;
  });

  test('scrollable node with children has a container node', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.scrollLeft.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      childrenInHitTestOrder: Int32List.fromList(<int>[1]),
      childrenInTraversalOrder: Int32List.fromList(<int>[1]),
    );
    updateNode(
      builder,
      id: 1,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(10, 10, 20, 20),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem style="$rootSemanticStyle; touch-action: none; overflow-x: scroll">
<flt-semantics-scroll-overflow></flt-semantics-scroll-overflow>
  <sem-c>
    <sem></sem>
  </sem-c>
</sem>''');

    final DomElement? scrollable = findScrollable();
    expect(scrollable, isNotNull);

    // When there's less content than the available size the neutral
    // scrollLeft is still a positive number.
    expect(scrollable!.scrollLeft, isPositive);

    semantics().semanticsEnabled = false;
  });

  test('scrollable node dispatches scroll events', () async {
    final SemanticsActionLogger logger = SemanticsActionLogger();
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 |
          ui.SemanticsAction.scrollLeft.index |
          ui.SemanticsAction.scrollRight.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      childrenInHitTestOrder: Int32List.fromList(<int>[1, 2, 3]),
      childrenInTraversalOrder: Int32List.fromList(<int>[1, 2, 3]),
    );

    for (int id = 1; id <= 3; id++) {
      updateNode(
        builder,
        id: id,
        transform: Matrix4.translationValues(50.0 * id, 0, 0).toFloat64(),
        rect: const ui.Rect.fromLTRB(0, 0, 50, 50),
      );
    }

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem style="$rootSemanticStyle; touch-action: none; overflow-x: scroll">
  <flt-semantics-scroll-overflow></flt-semantics-scroll-overflow>
  <sem-c>
    <sem style="z-index: 3"></sem>
    <sem style="z-index: 2"></sem>
    <sem style="z-index: 1"></sem>
  </sem-c>
</sem>''');

    final DomElement? scrollable = findScrollable();
    expect(scrollable, isNotNull);

    // When there's more content than the available size the neutral scrollTop
    // is greater than 0 with a maximum of 10.
    int browserMaxScrollDiff = 0;
    // The max scroll value varies between `9` and `10` for Safari desktop
    // browsers.
    if (browserEngine == BrowserEngine.webkit &&
        operatingSystem == OperatingSystem.macOs) {
      browserMaxScrollDiff = 1;
    }
    expect(scrollable!.scrollLeft >= (10 - browserMaxScrollDiff), isTrue);

    scrollable.scrollLeft = 20;
    expect(scrollable.scrollLeft, 20);
    expect(await logger.idLog.first, 0);
    expect(await logger.actionLog.first, ui.SemanticsAction.scrollLeft);
    // Engine semantics returns scroll position back to neutral.
    expect(scrollable.scrollLeft >= (10 - browserMaxScrollDiff), isTrue);

    scrollable.scrollLeft = 5;
    expect(scrollable.scrollLeft >= (5 - browserMaxScrollDiff), isTrue);
    expect(await logger.idLog.first, 0);
    expect(await logger.actionLog.first, ui.SemanticsAction.scrollRight);
    // Engine semantics returns scroll top back to neutral.
    expect(scrollable.scrollLeft >= (10 - browserMaxScrollDiff), isTrue);

    semantics().semanticsEnabled = false;
  }, skip: isWasm); // https://github.com/dart-lang/sdk/issues/50778
}

void _testIncrementables() {
  test('renders a trivial incrementable node', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.increase.index,
      value: 'd',
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem style="$rootSemanticStyle">
  <input role="slider" aria-valuenow="1" aria-valuetext="d" aria-valuemax="1" aria-valuemin="1">
</sem>''');

    final SemanticsObject node = semantics().debugSemanticsTree![0]!;
    expect(node.primaryRole?.role, PrimaryRole.incrementable);
    expect(
      reason: 'Incrementables use custom focus management',
      node.primaryRole!.debugSecondaryRoles,
      isNot(contains(Role.focusable)),
    );

    semantics().semanticsEnabled = false;
  });

  test('increments', () async {
    final SemanticsActionLogger logger = SemanticsActionLogger();
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.increase.index,
      value: 'd',
      increasedValue: 'e',
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem style="$rootSemanticStyle">
  <input role="slider" aria-valuenow="1" aria-valuetext="d" aria-valuemax="2" aria-valuemin="1">
</sem>''');

    final DomHTMLInputElement input =
        rootElement.querySelector('input')! as DomHTMLInputElement;
    input.value = '2';
    input.dispatchEvent(createDomEvent('Event', 'change'));

    expect(await logger.idLog.first, 0);
    expect(await logger.actionLog.first, ui.SemanticsAction.increase);

    semantics().semanticsEnabled = false;
  });

  test('decrements', () async {
    final SemanticsActionLogger logger = SemanticsActionLogger();
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.decrease.index,
      value: 'd',
      decreasedValue: 'c',
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem style="$rootSemanticStyle">
  <input role="slider" aria-valuenow="1" aria-valuetext="d" aria-valuemax="1" aria-valuemin="0">
</sem>''');

    final DomHTMLInputElement input =
        rootElement.querySelector('input')! as DomHTMLInputElement;
    input.value = '0';
    input.dispatchEvent(createDomEvent('Event', 'change'));

    expect(await logger.idLog.first, 0);
    expect(await logger.actionLog.first, ui.SemanticsAction.decrease);

    semantics().semanticsEnabled = false;
  });

  test('renders a node that can both increment and decrement', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 |
          ui.SemanticsAction.decrease.index |
          ui.SemanticsAction.increase.index,
      value: 'd',
      increasedValue: 'e',
      decreasedValue: 'c',
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem style="$rootSemanticStyle">
  <input role="slider" aria-valuenow="1" aria-valuetext="d" aria-valuemax="2" aria-valuemin="0">
</sem>''');

    semantics().semanticsEnabled = false;
  });

  test('sends focus events', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    void pumpSemantics({ required bool isFocused }) {
      final SemanticsTester tester = SemanticsTester(semantics());
      tester.updateNode(
        id: 0,
        hasIncrease: true,
        isFocusable: true,
        isFocused: isFocused,
        hasEnabledState: true,
        isEnabled: true,
        value: 'd',
        transform: Matrix4.identity().toFloat64(),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
    }

    final List<CapturedAction> capturedActions = <CapturedAction>[];
    EnginePlatformDispatcher.instance.onSemanticsActionEvent = (ui.SemanticsActionEvent event) {
      capturedActions.add((event.nodeId, event.type, event.arguments));
    };

    pumpSemantics(isFocused: false);
    expect(capturedActions, isEmpty);

    pumpSemantics(isFocused: true);
    expect(capturedActions, <CapturedAction>[
      (0, ui.SemanticsAction.didGainAccessibilityFocus, null),
    ]);

    pumpSemantics(isFocused: false);
    expect(capturedActions, <CapturedAction>[
      (0, ui.SemanticsAction.didGainAccessibilityFocus, null),
      (0, ui.SemanticsAction.didLoseAccessibilityFocus, null),
    ]);

    semantics().semanticsEnabled = false;
  });
}

void _testTextField() {
  test('renders a text field', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.tap.index,
      flags: 0 | ui.SemanticsFlag.isTextField.index,
      value: 'hello',
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem style="$rootSemanticStyle">
  <input value="hello" />
</sem>''');

    final SemanticsObject node = semantics().debugSemanticsTree![0]!;
    expect(node.primaryRole?.role, PrimaryRole.textField);
    expect(
      reason: 'Text fields use custom focus management',
      node.primaryRole!.debugSecondaryRoles,
      isNot(contains(Role.focusable)),
    );

    semantics().semanticsEnabled = false;
  });

  // TODO(yjbanov): this test will need to be adjusted for Safari when we add
  //                Safari testing.
  test('sends a focus action when text field is activated', () async {
    final SemanticsActionLogger logger = SemanticsActionLogger();
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.didGainAccessibilityFocus.index,
      flags: 0 | ui.SemanticsFlag.isTextField.index,
      value: 'hello',
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    semantics().updateSemantics(builder.build());

    final DomElement textField =
        rootElement.querySelector('input[data-semantics-role="text-field"]')!;

    expect(rootElement.ownerDocument?.activeElement, isNot(textField));

    textField.focus();

    expect(rootElement.ownerDocument?.activeElement, textField);
    expect(await logger.idLog.first, 0);
    expect(await logger.actionLog.first, ui.SemanticsAction.didGainAccessibilityFocus);

    semantics().semanticsEnabled = false;
  }, // TODO(yjbanov): https://github.com/flutter/flutter/issues/46638
      // TODO(yjbanov): https://github.com/flutter/flutter/issues/50590
      skip: browserEngine != BrowserEngine.blink);
}

void _testCheckables() {
  test('renders a switched on switch element', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.tap.index,
      label: 'test label',
      flags: 0 |
          ui.SemanticsFlag.isEnabled.index |
          ui.SemanticsFlag.hasEnabledState.index |
          ui.SemanticsFlag.hasToggledState.index |
          ui.SemanticsFlag.isToggled.index |
          ui.SemanticsFlag.isFocusable.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem aria-label="test label" flt-tappable role="switch" aria-checked="true" style="$rootSemanticStyle"></sem>
''');

    final SemanticsObject node = semantics().debugSemanticsTree![0]!;
    expect(node.primaryRole?.role, PrimaryRole.checkable);
    expect(
      reason: 'Checkables use generic secondary roles',
      node.primaryRole!.debugSecondaryRoles,
      containsAll(<Role>[Role.focusable, Role.tappable]),
    );

    semantics().semanticsEnabled = false;
  });

  test('renders a switched on disabled switch element', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.tap.index,
      flags: 0 |
          ui.SemanticsFlag.hasToggledState.index |
          ui.SemanticsFlag.isToggled.index |
          ui.SemanticsFlag.hasEnabledState.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem role="switch" aria-disabled="true" aria-checked="true" style="$rootSemanticStyle"></sem>
''');

    semantics().semanticsEnabled = false;
  });

  test('renders a switched off switch element', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.tap.index,
      flags: 0 |
          ui.SemanticsFlag.hasToggledState.index |
          ui.SemanticsFlag.isEnabled.index |
          ui.SemanticsFlag.hasEnabledState.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem role="switch" flt-tappable aria-checked="false" style="$rootSemanticStyle"></sem>
''');

    semantics().semanticsEnabled = false;
  });

  test('renders a checked checkbox', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.tap.index,
      flags: 0 |
          ui.SemanticsFlag.isEnabled.index |
          ui.SemanticsFlag.hasEnabledState.index |
          ui.SemanticsFlag.hasCheckedState.index |
          ui.SemanticsFlag.isChecked.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem role="checkbox" flt-tappable aria-checked="true" style="$rootSemanticStyle"></sem>
''');

    semantics().semanticsEnabled = false;
  });

  test('renders a checked disabled checkbox', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.tap.index,
      flags: 0 |
          ui.SemanticsFlag.hasCheckedState.index |
          ui.SemanticsFlag.hasEnabledState.index |
          ui.SemanticsFlag.isChecked.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem role="checkbox" aria-disabled="true" aria-checked="true" style="$rootSemanticStyle"></sem>
''');

    semantics().semanticsEnabled = false;
  });

  test('renders an unchecked checkbox', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.tap.index,
      flags: 0 |
          ui.SemanticsFlag.hasCheckedState.index |
          ui.SemanticsFlag.isEnabled.index |
          ui.SemanticsFlag.hasEnabledState.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem role="checkbox" flt-tappable aria-checked="false" style="$rootSemanticStyle"></sem>
''');

    semantics().semanticsEnabled = false;
  });

  test('renders a checked radio button', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.tap.index,
      flags: 0 |
          ui.SemanticsFlag.isEnabled.index |
          ui.SemanticsFlag.hasEnabledState.index |
          ui.SemanticsFlag.hasCheckedState.index |
          ui.SemanticsFlag.isInMutuallyExclusiveGroup.index |
          ui.SemanticsFlag.isChecked.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem role="radio" flt-tappable aria-checked="true" style="$rootSemanticStyle"></sem>
''');

    semantics().semanticsEnabled = false;
  });

  test('renders a checked disabled radio button', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.tap.index,
      flags: 0 |
          ui.SemanticsFlag.hasEnabledState.index |
          ui.SemanticsFlag.hasCheckedState.index |
          ui.SemanticsFlag.isInMutuallyExclusiveGroup.index |
          ui.SemanticsFlag.isChecked.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem role="radio" aria-disabled="true" aria-checked="true" style="$rootSemanticStyle"></sem>
''');

    semantics().semanticsEnabled = false;
  });

  test('renders an unchecked checkbox', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.tap.index,
      flags: 0 |
          ui.SemanticsFlag.isEnabled.index |
          ui.SemanticsFlag.hasEnabledState.index |
          ui.SemanticsFlag.hasCheckedState.index |
          ui.SemanticsFlag.isInMutuallyExclusiveGroup.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem role="radio" flt-tappable aria-checked="false" style="$rootSemanticStyle"></sem>
''');

    semantics().semanticsEnabled = false;
  });

  test('sends focus events', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    void pumpSemantics({ required bool isFocused }) {
      final SemanticsTester tester = SemanticsTester(semantics());
      tester.updateNode(
        id: 0,

        // The following combination of actions and flags describe a checkbox.
        hasTap: true,
        hasEnabledState: true,
        isEnabled: true,
        hasCheckedState: true,
        isFocusable: true,
        isFocused: isFocused,

        value: 'd',
        transform: Matrix4.identity().toFloat64(),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
    }

    final List<CapturedAction> capturedActions = <CapturedAction>[];
    EnginePlatformDispatcher.instance.onSemanticsActionEvent = (ui.SemanticsActionEvent event) {
      capturedActions.add((event.nodeId, event.type, event.arguments));
    };

    pumpSemantics(isFocused: false);
    expect(capturedActions, isEmpty);

    pumpSemantics(isFocused: true);
    expect(capturedActions, <CapturedAction>[
      (0, ui.SemanticsAction.didGainAccessibilityFocus, null),
    ]);

    pumpSemantics(isFocused: false);
    expect(capturedActions, <CapturedAction>[
      (0, ui.SemanticsAction.didGainAccessibilityFocus, null),
      (0, ui.SemanticsAction.didLoseAccessibilityFocus, null),
    ]);

    semantics().semanticsEnabled = false;
  });
}

void _testTappable() {
  test('renders an enabled tappable widget', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final SemanticsTester tester = SemanticsTester(semantics());
    tester.updateNode(
      id: 0,
      isFocusable: true,
      hasTap: true,
      hasEnabledState: true,
      isEnabled: true,
      isButton: true,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );
    tester.apply();

    expectSemanticsTree('''
<sem role="button" flt-tappable style="$rootSemanticStyle"></sem>
''');

    final SemanticsObject node = semantics().debugSemanticsTree![0]!;
    expect(node.primaryRole?.role, PrimaryRole.button);
    expect(
      node.primaryRole?.debugSecondaryRoles,
      containsAll(<Role>[Role.focusable, Role.tappable]),
    );
    expect(tester.getSemanticsObject(0).element.tabIndex, 0);

    semantics().semanticsEnabled = false;
  });

  test('renders a disabled tappable widget', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.tap.index,
      flags: 0 |
          ui.SemanticsFlag.hasEnabledState.index |
          ui.SemanticsFlag.isButton.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem role="button" aria-disabled="true" style="$rootSemanticStyle"></sem>
''');

    semantics().semanticsEnabled = false;
  });

  test('can switch tappable between enabled and disabled', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    void updateTappable({required bool enabled}) {
      final SemanticsTester tester = SemanticsTester(semantics());
      tester.updateNode(
        id: 0,
        hasTap: true,
        hasEnabledState: true,
        isEnabled: enabled,
        isButton: true,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
    }

    updateTappable(enabled: false);
    expectSemanticsTree(
        '<sem role="button" aria-disabled="true" style="$rootSemanticStyle"></sem>');

    updateTappable(enabled: true);
    expectSemanticsTree('<sem role="button" flt-tappable style="$rootSemanticStyle"></sem>');

    updateTappable(enabled: false);
    expectSemanticsTree(
        '<sem role="button" aria-disabled="true" style="$rootSemanticStyle"></sem>');

    updateTappable(enabled: true);
    expectSemanticsTree('<sem role="button" flt-tappable style="$rootSemanticStyle"></sem>');

    semantics().semanticsEnabled = false;
  });

  test('focuses on tappable after element has been attached', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final SemanticsTester tester = SemanticsTester(semantics());
    tester.updateNode(
      id: 0,
      hasTap: true,
      hasEnabledState: true,
      isEnabled: true,
      isButton: true,
      isFocusable: true,
      isFocused: true,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );
    tester.apply();

    expect(domDocument.activeElement, tester.getSemanticsObject(0).element);
    semantics().semanticsEnabled = false;
  });

  test('sends focus events', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    void pumpSemantics({ required bool isFocused }) {
      final SemanticsTester tester = SemanticsTester(semantics());
      tester.updateNode(
        id: 0,

        // The following combination of actions and flags describe a button.
        hasTap: true,
        hasEnabledState: true,
        isEnabled: true,
        isButton: true,
        isFocusable: true,
        isFocused: isFocused,

        value: 'd',
        transform: Matrix4.identity().toFloat64(),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
    }

    final List<CapturedAction> capturedActions = <CapturedAction>[];
    EnginePlatformDispatcher.instance.onSemanticsActionEvent = (ui.SemanticsActionEvent event) {
      capturedActions.add((event.nodeId, event.type, event.arguments));
    };

    pumpSemantics(isFocused: false);
    expect(capturedActions, isEmpty);

    pumpSemantics(isFocused: true);
    expect(capturedActions, <CapturedAction>[
      (0, ui.SemanticsAction.didGainAccessibilityFocus, null),
    ]);

    pumpSemantics(isFocused: false);
    expect(capturedActions, <CapturedAction>[
      (0, ui.SemanticsAction.didGainAccessibilityFocus, null),
      (0, ui.SemanticsAction.didLoseAccessibilityFocus, null),
    ]);

    semantics().semanticsEnabled = false;
  });

  // Regression test for: https://github.com/flutter/flutter/issues/134842
  //
  // If the click event is allowed to propagate through the hierarchy, then both
  // the descendant and the parent will generate a SemanticsAction.tap, causing
  // a double-tap to happen on the framework side.
  test('inner tappable overrides ancestor tappable', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final List<CapturedAction> capturedActions = <CapturedAction>[];
    EnginePlatformDispatcher.instance.onSemanticsActionEvent = (ui.SemanticsActionEvent event) {
      capturedActions.add((event.nodeId, event.type, event.arguments));
    };

    final SemanticsTester tester = SemanticsTester(semantics());
    tester.updateNode(
      id: 0,
      isFocusable: true,
      hasTap: true,
      hasEnabledState: true,
      isEnabled: true,
      isButton: true,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(
          id: 1,
          isFocusable: true,
          hasTap: true,
          hasEnabledState: true,
          isEnabled: true,
          isButton: true,
          rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
        ),
      ],
    );
    tester.apply();

    expectSemanticsTree('''
<sem flt-tappable role="button" style="$rootSemanticStyle">
  <sem-c>
    <sem flt-tappable role="button"></sem>
  </sem-c>
</sem>
''');

    // Tap on the outer element
    {
      final DomElement element = tester.getSemanticsObject(0).element;
      final DomRect rect = element.getBoundingClientRect();

      element.dispatchEvent(createDomMouseEvent('click', <Object?, Object?>{
        'clientX': (rect.left + (rect.right - rect.left) / 2).floor(),
        'clientY': (rect.top + (rect.bottom - rect.top) / 2).floor(),
      }));

      expect(capturedActions, <CapturedAction>[
        (0, ui.SemanticsAction.tap, null),
      ]);
    }

    // Tap on the inner element
    {
      capturedActions.clear();
      final DomElement element = tester.getSemanticsObject(1).element;
      final DomRect rect = element.getBoundingClientRect();

      element.dispatchEvent(createDomMouseEvent('click', <Object?, Object?>{
        'bubbles': true,
        'clientX': (rect.left + (rect.right - rect.left) / 2).floor(),
        'clientY': (rect.top + (rect.bottom - rect.top) / 2).floor(),
      }));

      // The click on the inner element should not propagate to the parent to
      // avoid sending a second SemanticsAction.tap action to the framework.
      expect(capturedActions, <CapturedAction>[
        (1, ui.SemanticsAction.tap, null),
      ]);
    }

    semantics().semanticsEnabled = false;
  });
}

void _testImage() {
  test('renders an image with no child nodes and with a label', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      flags: 0 | ui.SemanticsFlag.isImage.index,
      label: 'Test Image Label',
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem role="img" aria-label="Test Image Label" style="$rootSemanticStyle"></sem>
''');

    semantics().semanticsEnabled = false;
  });

  test('renders an image with a child node and with a label', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      flags: 0 | ui.SemanticsFlag.isImage.index,
      label: 'Test Image Label',
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      childrenInHitTestOrder: Int32List.fromList(<int>[1]),
      childrenInTraversalOrder: Int32List.fromList(<int>[1]),
    );
    updateNode(
      builder,
      id: 1,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(10, 10, 20, 20),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem style="$rootSemanticStyle">
  <sem-img role="img" aria-label="Test Image Label">
  </sem-img>
  <sem-c>
    <sem></sem>
  </sem-c>
</sem>''');

    semantics().semanticsEnabled = false;
  });

  test('renders an image with no child nodes without a label', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      flags: 0 | ui.SemanticsFlag.isImage.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree(
        '''<sem role="img" style="$rootSemanticStyle"></sem>''');

    semantics().semanticsEnabled = false;
  });

  test('renders an image with a child node and without a label', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      flags: 0 | ui.SemanticsFlag.isImage.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      childrenInHitTestOrder: Int32List.fromList(<int>[1]),
      childrenInTraversalOrder: Int32List.fromList(<int>[1]),
    );
    updateNode(
      builder,
      id: 1,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(10, 10, 20, 20),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem style="$rootSemanticStyle">
  <sem-img role="img">
  </sem-img>
  <sem-c>
    <sem></sem>
  </sem-c>
</sem>''');

    semantics().semanticsEnabled = false;
  });
}

class MockAccessibilityAnnouncements implements AccessibilityAnnouncements {
  int announceInvoked = 0;

  @override
  void announce(String message, Assertiveness assertiveness) {
    announceInvoked += 1;
  }

  @override
  DomHTMLElement ariaLiveElementFor(Assertiveness assertiveness) {
    throw UnsupportedError(
        'ariaLiveElementFor is not supported in MockAccessibilityAnnouncements');
  }

  @override
  void handleMessage(StandardMessageCodec codec, ByteData? data) {
    throw UnsupportedError(
        'handleMessage is not supported in MockAccessibilityAnnouncements!');
  }
}

void _testLiveRegion() {
  tearDown(() {
    LiveRegion.debugOverrideAccessibilityAnnouncements(null);
  });

  test('announces the label after an update', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final MockAccessibilityAnnouncements mockAccessibilityAnnouncements =
        MockAccessibilityAnnouncements();
    LiveRegion.debugOverrideAccessibilityAnnouncements(mockAccessibilityAnnouncements);

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      label: 'This is a snackbar',
      flags: 0 | ui.SemanticsFlag.isLiveRegion.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );
    semantics().updateSemantics(builder.build());
    expect(mockAccessibilityAnnouncements.announceInvoked, 1);

    semantics().semanticsEnabled = false;
  });

  test('does not announce anything if there is no label', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final MockAccessibilityAnnouncements mockAccessibilityAnnouncements =
        MockAccessibilityAnnouncements();
    LiveRegion.debugOverrideAccessibilityAnnouncements(mockAccessibilityAnnouncements);

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      flags: 0 | ui.SemanticsFlag.isLiveRegion.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );
    semantics().updateSemantics(builder.build());
    expect(mockAccessibilityAnnouncements.announceInvoked, 0);

    semantics().semanticsEnabled = false;
  });

  test('does not announce the same label over and over', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final MockAccessibilityAnnouncements mockAccessibilityAnnouncements =
        MockAccessibilityAnnouncements();
    LiveRegion.debugOverrideAccessibilityAnnouncements(mockAccessibilityAnnouncements);

    ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      label: 'This is a snackbar',
      flags: 0 | ui.SemanticsFlag.isLiveRegion.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );
    semantics().updateSemantics(builder.build());
    expect(mockAccessibilityAnnouncements.announceInvoked, 1);

    builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      label: 'This is a snackbar',
      flags: 0 | ui.SemanticsFlag.isLiveRegion.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );
    semantics().updateSemantics(builder.build());
    expect(mockAccessibilityAnnouncements.announceInvoked, 1);

    semantics().semanticsEnabled = false;
  });
}

void _testPlatformView() {
  test('sets and updates aria-owns', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    // Set.
    {
      final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
      updateNode(
        builder,
        platformViewId: 5,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      semantics().updateSemantics(builder.build());
      expectSemanticsTree('<sem aria-owns="flt-pv-5" style="$rootSemanticStyle"></sem>');
    }

    // Update.
    {
      final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
      updateNode(
        builder,
        platformViewId: 42,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      semantics().updateSemantics(builder.build());
      expectSemanticsTree('<sem aria-owns="flt-pv-42" style="$rootSemanticStyle"></sem>');
    }

    semantics().semanticsEnabled = false;
  });

  test('is transparent w.r.t. hit testing', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      platformViewId: 5,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );
    semantics().updateSemantics(builder.build());

    expectSemanticsTree('<sem aria-owns="flt-pv-5" style="$rootSemanticStyle"></sem>');
    final DomElement element = rootElement.querySelector('flt-semantics')!;
    expect(element.style.pointerEvents, 'none');

    semantics().semanticsEnabled = false;
  });

  // This test simulates the scenario of three child semantic nodes contained by
  // a common parent. The first and the last nodes are plain leaf nodes. The
  // middle node is a platform view node. Nodes overlap. The test hit tests
  // various points and verifies that the correct DOM element receives the
  // event. The test does this using `documentOrShadow.elementFromPoint`, which,
  // if browsers are to be trusted, should do the same thing as if a pointer
  // event landed at the given location.
  //
  // 0px   -------------
  //       |           |
  //       |           | <- plain semantic node
  //       |     1     |
  // 15px  | -------------
  //       | |           |
  // 25px  --|           |
  //         |     2     |  <- platform view
  //         |           |
  // 35px    | -------------
  //         | |           |
  // 45px    --|           |
  //           |     3     |  <- plain semantic node
  //           |           |
  //           |           |
  // 60px      -------------
  test('is reachable via a hit test', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    ui_web.platformViewRegistry.registerViewFactory(
      'test-platform-view',
      (int viewId) => createDomHTMLDivElement()
        ..id = 'view-0'
        ..style.width = '100%'
        ..style.height = '100%',
    );
    await createPlatformView(0, 'test-platform-view');

    final ui.SceneBuilder sceneBuilder = ui.SceneBuilder();
    sceneBuilder.addPlatformView(
      0,
      offset: const ui.Offset(0, 15),
      width: 20,
      height: 30,
    );
    ui.PlatformDispatcher.instance.render(sceneBuilder.build());

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    final double dpr = EngineFlutterDisplay.instance.devicePixelRatio;
    updateNode(builder,
        rect: const ui.Rect.fromLTRB(0, 0, 20, 60),
        childrenInTraversalOrder: Int32List.fromList(<int>[1, 2, 3]),
        childrenInHitTestOrder: Int32List.fromList(<int>[1, 2, 3]),
        transform: Float64List.fromList(Matrix4.diagonal3Values(dpr, dpr, 1).storage));
    updateNode(
      builder,
      id: 1,
      rect: const ui.Rect.fromLTRB(0, 0, 20, 25),
    );
    updateNode(
      builder,
      id: 2,
      // This has to match the values passed to `addPlatformView` above.
      rect: const ui.Rect.fromLTRB(0, 15, 20, 45),
      platformViewId: 0,
    );
    updateNode(
      builder,
      id: 3,
      rect: const ui.Rect.fromLTRB(0, 35, 20, 60),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem style="$rootSemanticStyle">
  <sem-c>
    <sem style="z-index: 3"></sem>
    <sem style="z-index: 2" aria-owns="flt-pv-0"></sem>
    <sem style="z-index: 1"></sem>
  </sem-c>
</sem>''');

    final DomElement root = rootElement.querySelector('#flt-semantic-node-0')!;
    expect(root.style.pointerEvents, 'none');

    final DomElement child1 =
        rootElement.querySelector('#flt-semantic-node-1')!;
    expect(child1.style.pointerEvents, 'all');
    final DomRect child1Rect = child1.getBoundingClientRect();
    expect(child1Rect.left, 0);
    expect(child1Rect.top, 0);
    expect(child1Rect.right, 20);
    expect(child1Rect.bottom, 25);

    final DomElement child2 =
        rootElement.querySelector('#flt-semantic-node-2')!;
    expect(child2.style.pointerEvents, 'none');
    final DomRect child2Rect = child2.getBoundingClientRect();
    expect(child2Rect.left, 0);
    expect(child2Rect.top, 15);
    expect(child2Rect.right, 20);
    expect(child2Rect.bottom, 45);

    final DomElement child3 =
        rootElement.querySelector('#flt-semantic-node-3')!;
    expect(child3.style.pointerEvents, 'all');
    final DomRect child3Rect = child3.getBoundingClientRect();
    expect(child3Rect.left, 0);
    expect(child3Rect.top, 35);
    expect(child3Rect.right, 20);
    expect(child3Rect.bottom, 60);

    final DomElement platformViewElement =
        platformViewsHost.querySelector('#view-0')!;
    final DomRect platformViewRect =
        platformViewElement.getBoundingClientRect();
    expect(platformViewRect.left, 0);
    expect(platformViewRect.top, 15);
    expect(platformViewRect.right, 20);
    expect(platformViewRect.bottom, 45);

    // Hit test child 1
    expect(domDocument.elementFromPoint(10, 10), child1);

    // Hit test overlap between child 1 and 2
    // TODO(yjbanov): this is a known limitation, see https://github.com/flutter/flutter/issues/101439
    expect(domDocument.elementFromPoint(10, 20), child1);

    // Hit test child 2
    // Clicking at the location of the middle semantics node should allow the
    // event to go through the semantic tree and hit the platform view. Since
    // platform views are projected into the shadow DOM from outside the shadow
    // root, it would be reachable both from the shadow root (by hitting the
    // corresponding <slot> tag) and from the document (by hitting the platform
    // view element itself).

    // Browsers disagree about which element should be returned when hit testing
    // a shadow root. However, they do agree when hit testing `document`.
    //
    // See:
    //   * https://github.com/w3c/csswg-drafts/issues/556
    //   * https://bugzilla.mozilla.org/show_bug.cgi?id=1502369
    expect(domDocument.elementFromPoint(10, 30), platformViewElement);

    // Hit test overlap between child 2 and 3
    expect(domDocument.elementFromPoint(10, 40), child3);

    // Hit test child 3
    expect(domDocument.elementFromPoint(10, 50), child3);

    semantics().semanticsEnabled = false;
  });
}

void _testGroup() {
  test('nodes with children and labels use group role with aria label', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      label: 'this is a label for a group of elements',
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      childrenInHitTestOrder: Int32List.fromList(<int>[1]),
      childrenInTraversalOrder: Int32List.fromList(<int>[1]),
    );
    updateNode(
      builder,
      id: 1,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
<sem role="group" aria-label="this is a label for a group of elements" style="$rootSemanticStyle"><sem-c><sem></sem></sem-c></sem>
''');

    semantics().semanticsEnabled = false;
  });
}

void _testDialog() {
  test('renders named and labeled routes', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      label: 'this is a dialog label',
      flags: 0 | ui.SemanticsFlag.scopesRoute.index | ui.SemanticsFlag.namesRoute.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      childrenInHitTestOrder: Int32List.fromList(<int>[1]),
      childrenInTraversalOrder: Int32List.fromList(<int>[1]),
    );
    updateNode(
      builder,
      id: 1,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    semantics().updateSemantics(builder.build());
    expectSemanticsTree('''
      <sem role="dialog" aria-label="this is a dialog label" style="$rootSemanticStyle"><sem-c><sem></sem></sem-c></sem>
    ''');

    expect(
      semantics().debugSemanticsTree![0]!.primaryRole?.role,
      PrimaryRole.dialog,
    );

    semantics().semanticsEnabled = false;
  });

  test('warns about missing label', () {
    final List<String> warnings = <String>[];
    printWarning = warnings.add;

    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      flags: 0 | ui.SemanticsFlag.scopesRoute.index | ui.SemanticsFlag.namesRoute.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      childrenInHitTestOrder: Int32List.fromList(<int>[1]),
      childrenInTraversalOrder: Int32List.fromList(<int>[1]),
    );
    updateNode(
      builder,
      id: 1,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    semantics().updateSemantics(builder.build());
    expect(
      warnings,
      <String>[
        'Semantic node 0 had both scopesRoute and namesRoute set, indicating a self-labelled dialog, but it is missing the label. A dialog should be labelled either by setting namesRoute on itself and providing a label, or by containing a child node with namesRoute that can describe it with its content.',
      ],
    );

    // But still sets the dialog role.
    expectSemanticsTree('''
      <sem role="dialog" aria-label="" style="$rootSemanticStyle"><sem-c><sem></sem></sem-c></sem>
    ''');

    expect(
      semantics().debugSemanticsTree![0]!.primaryRole?.role,
      PrimaryRole.dialog,
    );

    semantics().semanticsEnabled = false;
  });

  test('dialog can be described by a descendant', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    void pumpSemantics({ required String label }) {
      final SemanticsTester tester = SemanticsTester(semantics());
      tester.updateNode(
        id: 0,
        scopesRoute: true,
        transform: Matrix4.identity().toFloat64(),
        children: <SemanticsNodeUpdate>[
          tester.updateNode(
            id: 1,
            children: <SemanticsNodeUpdate>[
              tester.updateNode(
                id: 2,
                namesRoute: true,
                label: label,
              ),
            ],
          ),
        ],
      );
      tester.apply();

      expectSemanticsTree('''
        <sem role="dialog" aria-describedby="flt-semantic-node-2" style="$rootSemanticStyle">
          <sem-c>
            <sem>
              <sem-c>
                <sem role="text" aria-label="$label"></sem>
              </sem-c>
            </sem>
          </sem-c>
        </sem>
      ''');
    }

    pumpSemantics(label: 'Dialog label');

    expect(
      semantics().debugSemanticsTree![0]!.primaryRole?.role,
      PrimaryRole.dialog,
    );
    expect(
      semantics().debugSemanticsTree![2]!.primaryRole?.role,
      PrimaryRole.generic,
    );
    expect(
      semantics().debugSemanticsTree![2]!.primaryRole?.debugSecondaryRoles,
      contains(Role.routeName),
    );

    pumpSemantics(label: 'Updated dialog label');

    semantics().semanticsEnabled = false;
  });

  test('scopesRoute alone sets the dialog role with no label', () {
    final List<String> warnings = <String>[];
    printWarning = warnings.add;

    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final SemanticsTester tester = SemanticsTester(semantics());
    tester.updateNode(
      id: 0,
      scopesRoute: true,
      transform: Matrix4.identity().toFloat64(),
    );
    tester.apply();

    expectSemanticsTree('''
      <sem style="$rootSemanticStyle"></sem>
    ''');

    expect(
      semantics().debugSemanticsTree![0]!.primaryRole?.role,
      PrimaryRole.dialog,
    );
    expect(
      semantics().debugSemanticsTree![0]!.primaryRole?.secondaryRoleManagers,
      isNot(contains(Role.routeName)),
    );

    semantics().semanticsEnabled = false;
  });

  test('namesRoute alone has no effect', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final SemanticsTester tester = SemanticsTester(semantics());
    tester.updateNode(
      id: 0,
      transform: Matrix4.identity().toFloat64(),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(
          id: 1,
          children: <SemanticsNodeUpdate>[
            tester.updateNode(
              id: 2,
              namesRoute: true,
              label: 'Hello',
            ),
          ],
        ),
      ],
    );
    tester.apply();

    expectSemanticsTree('''
      <sem style="$rootSemanticStyle">
        <sem-c>
          <sem>
            <sem-c>
              <sem role="text" aria-label="Hello"></sem>
            </sem-c>
          </sem>
        </sem-c>
      </sem>
    ''');

    expect(
      semantics().debugSemanticsTree![0]!.primaryRole?.role,
      PrimaryRole.generic,
    );
    expect(
      semantics().debugSemanticsTree![2]!.primaryRole?.debugSecondaryRoles,
      contains(Role.routeName),
    );

    semantics().semanticsEnabled = false;
  });
}

typedef CapturedAction = (int nodeId, ui.SemanticsAction action, Object? args);

void _testFocusable() {
  test('AccessibilityFocusManager can manage element focus', () async {
    final EngineSemanticsOwner owner = semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    void pumpSemantics() {
      final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
      updateNode(
        builder,
        label: 'Dummy root element',
        transform: Matrix4.identity().toFloat64(),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
        childrenInHitTestOrder: Int32List.fromList(<int>[]),
        childrenInTraversalOrder: Int32List.fromList(<int>[]),
      );
      semantics().updateSemantics(builder.build());
    }

    final List<CapturedAction> capturedActions = <CapturedAction>[];
    EnginePlatformDispatcher.instance.onSemanticsActionEvent = (ui.SemanticsActionEvent event) {
      capturedActions.add((event.nodeId, event.type, event.arguments));
    };
    expect(capturedActions, isEmpty);

    final AccessibilityFocusManager manager = AccessibilityFocusManager(owner);
    expect(capturedActions, isEmpty);

    final DomElement element = createDomElement('test-element');
    expect(element.tabIndex, -1);
    domDocument.body!.append(element);

    // Start managing element
    manager.manage(1, element);
    expect(element.tabIndex, 0);
    expect(capturedActions, isEmpty);
    expect(domDocument.activeElement, isNot(element));

    // Request focus
    manager.changeFocus(true);
    pumpSemantics(); // triggers post-update callbacks
    expect(domDocument.activeElement, element);
    expect(capturedActions, <CapturedAction>[
      (1, ui.SemanticsAction.didGainAccessibilityFocus, null),
    ]);
    capturedActions.clear();

    // Give up focus
    manager.changeFocus(false);
    pumpSemantics(); // triggers post-update callbacks
    expect(capturedActions, <CapturedAction>[
      (1, ui.SemanticsAction.didLoseAccessibilityFocus, null),
    ]);
    capturedActions.clear();
    expect(domDocument.activeElement, isNot(element));

    // Request focus again
    manager.changeFocus(true);
    pumpSemantics(); // triggers post-update callbacks
    expect(domDocument.activeElement, element);
    expect(capturedActions, <CapturedAction>[
      (1, ui.SemanticsAction.didGainAccessibilityFocus, null),
    ]);
    capturedActions.clear();

    // Stop managing
    manager.stopManaging();
    pumpSemantics(); // triggers post-update callbacks
    expect(
      reason: 'Even though the element was blurred after stopManaging there '
              'should be no notification to the framework because the framework '
              'should already know. Otherwise, it would not have asked to stop '
              'managing the node.',
      capturedActions,
      isEmpty,
    );
    expect(domDocument.activeElement, isNot(element));

    // Attempt to request focus when not managing an element.
    manager.changeFocus(true);
    pumpSemantics(); // triggers post-update callbacks
    expect(
      reason: 'Attempting to request focus on a node that is not managed should '
              'not result in any notifications to the framework.',
      capturedActions,
      isEmpty,
    );
    expect(domDocument.activeElement, isNot(element));

    semantics().semanticsEnabled = false;
  });

  test('applies generic Focusable role', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    {
      final SemanticsTester tester = SemanticsTester(semantics());
      tester.updateNode(
        id: 0,
        transform: Matrix4.identity().toFloat64(),
        children: <SemanticsNodeUpdate>[
          tester.updateNode(
            id: 1,
            label: 'focusable text',
            isFocusable: true,
            rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
          ),
        ],
      );
      tester.apply();
    }

    expectSemanticsTree('''
<sem style="$rootSemanticStyle">
  <sem-c>
    <sem role="text" aria-label="focusable text"></sem>
  </sem-c>
</sem>
''');

    final SemanticsObject node = semantics().debugSemanticsTree![1]!;
    expect(node.isFocusable, isTrue);
    expect(
      node.primaryRole?.role,
      PrimaryRole.generic,
    );
    expect(
      node.primaryRole?.debugSecondaryRoles,
      contains(Role.focusable),
    );

    final DomElement element = node.element;
    expect(domDocument.activeElement, isNot(element));

    {
      final SemanticsTester tester = SemanticsTester(semantics());
      tester.updateNode(
        id: 1,
        label: 'test focusable',
        isFocusable: true,
        isFocused: true,
        transform: Matrix4.identity().toFloat64(),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
    }
    expect(domDocument.activeElement, element);

    semantics().semanticsEnabled = false;
  });
}

void _testLink() {
  test('nodes with link: true creates anchor tag', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final SemanticsTester tester = SemanticsTester(semantics());
      tester.updateNode(
        id: 0,
        isLink: true,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.element.tagName.toLowerCase(), 'a');
  });
}

/// A facade in front of [ui.SemanticsUpdateBuilder.updateNode] that
/// supplies default values for semantics attributes.
void updateNode(
  ui.SemanticsUpdateBuilder builder, {
  int id = 0,
  int flags = 0,
  int actions = 0,
  int maxValueLength = 0,
  int currentValueLength = 0,
  int textSelectionBase = 0,
  int textSelectionExtent = 0,
  int platformViewId = -1, // -1 means not a platform view
  int scrollChildren = 0,
  int scrollIndex = 0,
  double scrollPosition = 0.0,
  double scrollExtentMax = 0.0,
  double scrollExtentMin = 0.0,
  double elevation = 0.0,
  double thickness = 0.0,
  ui.Rect rect = ui.Rect.zero,
  String label = '',
  List<ui.StringAttribute> labelAttributes = const <ui.StringAttribute>[],
  String hint = '',
  List<ui.StringAttribute> hintAttributes = const <ui.StringAttribute>[],
  String value = '',
  List<ui.StringAttribute> valueAttributes = const <ui.StringAttribute>[],
  String increasedValue = '',
  List<ui.StringAttribute> increasedValueAttributes =
      const <ui.StringAttribute>[],
  String decreasedValue = '',
  List<ui.StringAttribute> decreasedValueAttributes =
      const <ui.StringAttribute>[],
  String tooltip = '',
  ui.TextDirection textDirection = ui.TextDirection.ltr,
  Float64List? transform,
  Int32List? childrenInTraversalOrder,
  Int32List? childrenInHitTestOrder,
  Int32List? additionalActions,
}) {
  transform ??= Float64List.fromList(Matrix4.identity().storage);
  childrenInTraversalOrder ??= Int32List(0);
  childrenInHitTestOrder ??= Int32List(0);
  additionalActions ??= Int32List(0);
  builder.updateNode(
    id: id,
    flags: flags,
    actions: actions,
    maxValueLength: maxValueLength,
    currentValueLength: currentValueLength,
    textSelectionBase: textSelectionBase,
    textSelectionExtent: textSelectionExtent,
    platformViewId: platformViewId,
    scrollChildren: scrollChildren,
    scrollIndex: scrollIndex,
    scrollPosition: scrollPosition,
    scrollExtentMax: scrollExtentMax,
    scrollExtentMin: scrollExtentMin,
    elevation: elevation,
    thickness: thickness,
    rect: rect,
    label: label,
    labelAttributes: labelAttributes,
    hint: hint,
    hintAttributes: hintAttributes,
    value: value,
    valueAttributes: valueAttributes,
    increasedValue: increasedValue,
    increasedValueAttributes: increasedValueAttributes,
    decreasedValue: decreasedValue,
    decreasedValueAttributes: decreasedValueAttributes,
    tooltip: tooltip,
    textDirection: textDirection,
    transform: transform,
    childrenInTraversalOrder: childrenInTraversalOrder,
    childrenInHitTestOrder: childrenInHitTestOrder,
    additionalActions: additionalActions,
  );
}

const MethodCodec codec = StandardMethodCodec();

/// Sends a platform message to create a Platform View with the given id and viewType.
Future<void> createPlatformView(int id, String viewType) {
  final Completer<void> completer = Completer<void>();
  ui.PlatformDispatcher.instance.sendPlatformMessage(
    'flutter/platform_views',
    codec.encodeMethodCall(MethodCall(
      'create',
      <String, dynamic>{
        'id': id,
        'viewType': viewType,
      },
    )),
    (dynamic _) => completer.complete(),
  );
  return completer.future;
}

/// Disposes of the platform view with the given [id].
Future<void> disposePlatformView(int id) {
  final Completer<void> completer = Completer<void>();
  ui.PlatformDispatcher.instance.sendPlatformMessage(
    'flutter/platform_views',
    codec.encodeMethodCall(MethodCall('dispose', id)),
    (dynamic _) => completer.complete(),
  );
  return completer.future;
}
