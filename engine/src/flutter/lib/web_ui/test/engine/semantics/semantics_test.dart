// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:quiver/testing/async.dart';
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import '../../common/rendering.dart';
import '../../common/test_initialization.dart';
import 'semantics_tester.dart';

DateTime _testTime = DateTime(2018, 12, 17);

EngineSemantics semantics() => EngineSemantics.instance;
EngineSemanticsOwner owner() => EnginePlatformDispatcher.instance.implicitView!.semantics;

DomElement get platformViewsHost =>
    EnginePlatformDispatcher.instance.implicitView!.dom.platformViewsHost;

DomElement get flutterViewRoot => EnginePlatformDispatcher.instance.implicitView!.dom.rootElement;

void main() {
  internalBootstrapBrowserTest(() {
    return testMain;
  });
}

Future<void> testMain() async {
  if (ui_web.browser.isFirefox) {
    // Firefox gets stuck in bootstrapAndRunApp for a mysterious reason.
    // https://github.com/flutter/flutter/issues/160096
    return;
  }

  await bootstrapAndRunApp(withImplicitView: true);
  setUpRenderingForTests();
  runSemanticsTests();
}

void runSemanticsTests() {
  setUp(() {
    EngineSemantics.debugResetSemantics();
  });

  group(EngineSemanticsOwner, () {
    _testEngineSemanticsOwner();
  });
  group('longestIncreasingSubsequence', () {
    _testLongestIncreasingSubsequence();
  });
  group(SemanticRole, () {
    _testSemanticRole();
  });
  group('Roles', () {
    _testRoleLifecycle();
  });
  group('labels', () {
    _testLabels();
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
  group('selectables', () {
    _testSelectables();
  });
  group('expandables', () {
    _testExpandables();
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
  group('heading', () {
    _testHeading();
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
  group('alert', () {
    _testAlerts();
  });
  group('group', () {
    _testGroup();
  });
  group('route', () {
    _testRoute();
    _testDialogs();
  });
  group('focusable', () {
    _testFocusable();
  });
  group('link', () {
    _testLink();
  });
  group('tabs', () {
    _testTabs();
  });
  group('table', () {
    _testTables();
  });
  group('list', () {
    _testLists();
  });
  group('controlsNodes', () {
    _testControlsNodes();
  });
  group('menu', () {
    _testMenus();
  });
  group('requirable', () {
    _testRequirable();
  });
  group('traversalOrder', () {
    _testSemanticsTraversalOrder();
  });
  group('SemanticsValidationResult', () {
    _testSemanticsValidationResult();
  });
  group('landmarks', () {
    _testLandmarks();
  });
  group('locale', () {
    _testLocale();
  });
  group('forms', () {
    _testForms();
  });
  group('progressBar', () {
    _testProgressBar();
  });
  group('loadingSpinner', () {
    _testLoadingSpinner();
  });
}

void _testSemanticRole() {
  test('Sets id and flt-semantics-identifier on the element', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      children: <SemanticsNodeUpdate>[tester.updateNode(id: 372), tester.updateNode(id: 599)],
    );
    tester.apply();

    tester.expectSemantics('''
<sem id="flt-semantic-node-0">
    <sem id="flt-semantic-node-372"></sem>
    <sem id="flt-semantic-node-599"></sem>
</sem>''');

    tester.updateNode(
      id: 0,
      children: <SemanticsNodeUpdate>[
        tester.updateNode(id: 372, identifier: 'test-id-123'),
        tester.updateNode(id: 599),
      ],
    );
    tester.apply();

    tester.expectSemantics('''
<sem id="flt-semantic-node-0">
    <sem id="flt-semantic-node-372" flt-semantics-identifier="test-id-123"></sem>
    <sem id="flt-semantic-node-599"></sem>
</sem>''');

    tester.updateNode(
      id: 0,
      children: <SemanticsNodeUpdate>[
        tester.updateNode(id: 372),
        tester.updateNode(id: 599, identifier: 'test-id-211'),
        tester.updateNode(id: 612, identifier: 'test-id-333'),
      ],
    );
    tester.apply();

    tester.expectSemantics('''
<sem id="flt-semantic-node-0">
    <sem id="flt-semantic-node-372"></sem>
    <sem id="flt-semantic-node-599" flt-semantics-identifier="test-id-211"></sem>
    <sem id="flt-semantic-node-612" flt-semantics-identifier="test-id-333"></sem>
</sem>''');
  });

  test(
    'Sets id and flt-semantics-identifier on the element when SemanticRole has no behaviors',
    () {
      semantics()
        ..debugOverrideTimestampFunction(() => _testTime)
        ..semanticsEnabled = true;

      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        children: <SemanticsNodeUpdate>[
          tester.updateNode(
            id: 372,
            flags: const ui.SemanticsFlags(isTextField: true),
          ), // SemanticTextField has no SemanticBehaviors.
          tester.updateNode(id: 599),
        ],
      );
      tester.apply();

      tester.expectSemantics('''
    <sem id="flt-semantic-node-0">
        <sem id="flt-semantic-node-372">
          <input />
        </sem>
        <sem id="flt-semantic-node-599"></sem>
    </sem>''');

      tester.updateNode(
        id: 0,
        children: <SemanticsNodeUpdate>[
          tester.updateNode(
            id: 372,
            identifier: 'test-id-123',
            flags: const ui.SemanticsFlags(isTextField: true),
          ),
          tester.updateNode(id: 599),
        ],
      );
      tester.apply();

      tester.expectSemantics('''
    <sem id="flt-semantic-node-0">
        <sem id="flt-semantic-node-372" flt-semantics-identifier="test-id-123">
          <input />
        </sem>
        <sem id="flt-semantic-node-599"></sem>
    </sem>''');

      tester.updateNode(
        id: 0,
        children: <SemanticsNodeUpdate>[
          tester.updateNode(id: 372, flags: const ui.SemanticsFlags(isTextField: true)),
          tester.updateNode(id: 599, identifier: 'test-id-211'),
          tester.updateNode(id: 612, identifier: 'test-id-333'),
        ],
      );
      tester.apply();

      tester.expectSemantics('''
    <sem id="flt-semantic-node-0">
        <sem id="flt-semantic-node-372">
          <input />
        </sem>
        <sem id="flt-semantic-node-599" flt-semantics-identifier="test-id-211"></sem>
        <sem id="flt-semantic-node-612" flt-semantics-identifier="test-id-333"></sem>
    </sem>''');
    },
  );
}

void _testRoleLifecycle() {
  test('Semantic behaviors are added upon node initialization', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    // Check that roles are initialized immediately
    {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        flags: const ui.SemanticsFlags(isButton: true),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();

      tester.expectSemantics('<sem role="button"></sem>');

      final SemanticsObject node = owner().debugSemanticsTree![0]!;
      expect(node.semanticRole?.kind, EngineSemanticsRole.button);
      expect(
        node.semanticRole?.debugSemanticBehaviorTypes,
        containsAll(<Type>[Focusable, Tappable, LabelAndValue]),
      );
      expect(tester.getSemanticsObject(0).element.tabIndex, -1);
    }

    // Check that roles apply their functionality upon update.
    {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        label: 'a label',
        flags: const ui.SemanticsFlags(isFocused: ui.Tristate.isFalse, isButton: true),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();

      tester.expectSemantics('<sem role="button">a label</sem>');

      final SemanticsObject node = owner().debugSemanticsTree![0]!;
      expect(node.semanticRole?.kind, EngineSemanticsRole.button);
      expect(
        node.semanticRole?.debugSemanticBehaviorTypes,
        containsAll(<Type>[Focusable, Tappable, LabelAndValue]),
      );
      expect(tester.getSemanticsObject(0).element.tabIndex, 0);
    }

    semantics().semanticsEnabled = false;
  });
}

void _testEngineAccessibilityBuilder() {
  final builder = EngineAccessibilityFeaturesBuilder(0);
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

  test('supportsAnnounce', () {
    // By default this starts off true, see EngineAccessibilityFeatures.supportsAnnounce
    expect(features.supportsAnnounce, isTrue);
    builder.supportsAnnounce = false;
    features = builder.build();
    expect(features.supportsAnnounce, isFalse);
  });

  test('reduce motion', () {
    expect(features.reduceMotion, isFalse);
    builder.reduceMotion = true;
    features = builder.build();
    expect(features.reduceMotion, isTrue);
  });

  test('autoPlayAnimatedImages', () {
    // By default this starts off true, see EngineAccessibilityFeatures.autoPlayAnimatedImages.
    expect(features.autoPlayAnimatedImages, isTrue);
    builder.autoPlayAnimatedImages = false;
    features = builder.build();
    expect(features.autoPlayAnimatedImages, isFalse);
  });

  test('autoPlayVideos', () {
    // By default this starts off true, see EngineAccessibilityFeatures.autoPlayVideos.
    expect(features.autoPlayVideos, isTrue);
    builder.autoPlayVideos = false;
    features = builder.build();
    expect(features.autoPlayVideos, isFalse);
  });

  test('deterministicCursor', () {
    expect(features.deterministicCursor, isFalse);
    builder.deterministicCursor = true;
    features = builder.build();
    expect(features.deterministicCursor, isTrue);
  });
}

void _testAlerts() {
  test('nodes with alert role', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.alert,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.semanticRole?.kind, EngineSemanticsRole.alert);
    expect(object.element.getAttribute('role'), 'alert');
  });

  test('nodes with status role', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.status,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.semanticRole?.kind, EngineSemanticsRole.status);
    expect(object.element.getAttribute('role'), 'status');
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

  // Expecting the following DOM structure by default:
  //
  // <body>
  //   <flt-announcement-host>
  //     <flt-announcement-polite></flt-announcement-polite>
  //     <flt-announcement-assertive></flt-announcement-assertive>
  //   </flt-announcement-host>
  // </body>
  test('places accessibility announcements in the <body> tag', () {
    final AccessibilityAnnouncements accessibilityAnnouncements =
        semantics().accessibilityAnnouncements;
    final DomElement politeElement = accessibilityAnnouncements.ariaLiveElementFor(
      Assertiveness.polite,
    );
    final DomElement assertiveElement = accessibilityAnnouncements.ariaLiveElementFor(
      Assertiveness.assertive,
    );
    final DomElement announcementHost = politeElement.parent!;

    // Polite and assertive elements share the same host.
    expect(assertiveElement.parent, announcementHost);

    // The host is a direct child of <body>
    expect(announcementHost.parent, domDocument.body);
  });

  test('accessibilityFeatures copyWith function works', () {
    // Announce, autoPlayAnimatedImages and autoPlayVideos are inverted
    // checks, see EngineAccessibilityFeatures. Therefore, we need to ensure
    // that the original copy starts with false values for them.
    const original = EngineAccessibilityFeatures(0 | 1 << 7 | 1 << 8 | 1 << 9);

    EngineAccessibilityFeatures copy = original.copyWith(accessibleNavigation: true);
    expect(copy.accessibleNavigation, true);
    expect(copy.boldText, false);
    expect(copy.disableAnimations, false);
    expect(copy.highContrast, false);
    expect(copy.invertColors, false);
    expect(copy.onOffSwitchLabels, false);
    expect(copy.supportsAnnounce, false);
    expect(copy.reduceMotion, false);
    expect(copy.autoPlayAnimatedImages, false);
    expect(copy.autoPlayVideos, false);
    expect(copy.deterministicCursor, false);

    copy = original.copyWith(boldText: true);
    expect(copy.accessibleNavigation, false);
    expect(copy.boldText, true);
    expect(copy.disableAnimations, false);
    expect(copy.highContrast, false);
    expect(copy.invertColors, false);
    expect(copy.onOffSwitchLabels, false);
    expect(copy.reduceMotion, false);
    expect(copy.autoPlayAnimatedImages, false);
    expect(copy.autoPlayVideos, false);
    expect(copy.deterministicCursor, false);

    copy = original.copyWith(disableAnimations: true);
    expect(copy.accessibleNavigation, false);
    expect(copy.boldText, false);
    expect(copy.disableAnimations, true);
    expect(copy.highContrast, false);
    expect(copy.invertColors, false);
    expect(copy.onOffSwitchLabels, false);
    expect(copy.supportsAnnounce, false);
    expect(copy.reduceMotion, false);
    expect(copy.autoPlayAnimatedImages, false);
    expect(copy.autoPlayVideos, false);
    expect(copy.deterministicCursor, false);

    copy = original.copyWith(highContrast: true);
    expect(copy.accessibleNavigation, false);
    expect(copy.boldText, false);
    expect(copy.disableAnimations, false);
    expect(copy.highContrast, true);
    expect(copy.invertColors, false);
    expect(copy.onOffSwitchLabels, false);
    expect(copy.supportsAnnounce, false);
    expect(copy.reduceMotion, false);
    expect(copy.autoPlayAnimatedImages, false);
    expect(copy.autoPlayVideos, false);
    expect(copy.deterministicCursor, false);

    copy = original.copyWith(invertColors: true);
    expect(copy.accessibleNavigation, false);
    expect(copy.boldText, false);
    expect(copy.disableAnimations, false);
    expect(copy.highContrast, false);
    expect(copy.invertColors, true);
    expect(copy.onOffSwitchLabels, false);
    expect(copy.supportsAnnounce, false);
    expect(copy.reduceMotion, false);
    expect(copy.autoPlayAnimatedImages, false);
    expect(copy.autoPlayVideos, false);
    expect(copy.deterministicCursor, false);

    copy = original.copyWith(onOffSwitchLabels: true);
    expect(copy.accessibleNavigation, false);
    expect(copy.boldText, false);
    expect(copy.disableAnimations, false);
    expect(copy.highContrast, false);
    expect(copy.invertColors, false);
    expect(copy.onOffSwitchLabels, true);
    expect(copy.reduceMotion, false);
    expect(copy.autoPlayAnimatedImages, false);
    expect(copy.autoPlayVideos, false);
    expect(copy.deterministicCursor, false);

    copy = original.copyWith(supportsAnnounce: true);
    expect(copy.accessibleNavigation, false);
    expect(copy.boldText, false);
    expect(copy.disableAnimations, false);
    expect(copy.highContrast, false);
    expect(copy.invertColors, false);
    expect(copy.onOffSwitchLabels, false);
    expect(copy.supportsAnnounce, true);
    expect(copy.reduceMotion, false);
    expect(copy.autoPlayAnimatedImages, false);
    expect(copy.autoPlayVideos, false);
    expect(copy.deterministicCursor, false);

    copy = original.copyWith(reduceMotion: true);
    expect(copy.accessibleNavigation, false);
    expect(copy.boldText, false);
    expect(copy.disableAnimations, false);
    expect(copy.highContrast, false);
    expect(copy.invertColors, false);
    expect(copy.onOffSwitchLabels, false);
    expect(copy.supportsAnnounce, false);
    expect(copy.reduceMotion, true);
    expect(copy.autoPlayAnimatedImages, false);
    expect(copy.autoPlayVideos, false);
    expect(copy.deterministicCursor, false);

    copy = original.copyWith(autoPlayAnimatedImages: true);
    expect(copy.accessibleNavigation, false);
    expect(copy.boldText, false);
    expect(copy.disableAnimations, false);
    expect(copy.highContrast, false);
    expect(copy.invertColors, false);
    expect(copy.onOffSwitchLabels, false);
    expect(copy.supportsAnnounce, false);
    expect(copy.reduceMotion, false);
    expect(copy.autoPlayAnimatedImages, true);
    expect(copy.autoPlayVideos, false);
    expect(copy.deterministicCursor, false);

    copy = original.copyWith(autoPlayVideos: true);
    expect(copy.accessibleNavigation, false);
    expect(copy.boldText, false);
    expect(copy.disableAnimations, false);
    expect(copy.highContrast, false);
    expect(copy.invertColors, false);
    expect(copy.onOffSwitchLabels, false);
    expect(copy.supportsAnnounce, false);
    expect(copy.reduceMotion, false);
    expect(copy.autoPlayAnimatedImages, false);
    expect(copy.autoPlayVideos, true);
    expect(copy.deterministicCursor, false);

    copy = original.copyWith(deterministicCursor: true);
    expect(copy.accessibleNavigation, false);
    expect(copy.boldText, false);
    expect(copy.disableAnimations, false);
    expect(copy.highContrast, false);
    expect(copy.invertColors, false);
    expect(copy.onOffSwitchLabels, false);
    expect(copy.supportsAnnounce, false);
    expect(copy.reduceMotion, false);
    expect(copy.autoPlayAnimatedImages, false);
    expect(copy.autoPlayVideos, false);
    expect(copy.deterministicCursor, true);
  });

  test('makes the semantic DOM tree invisible', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(id: 0, label: 'I am root', rect: const ui.Rect.fromLTRB(0, 0, 100, 50));
    tester.apply();

    expectSemanticsTree(owner(), '''
<sem style="filter: opacity(0%); color: rgba(0, 0, 0, 0)">
  <span>I am root</span>
</sem>''');

    semantics().semanticsEnabled = false;
  });

  void renderSemantics({String? label, String? tooltip, ui.SemanticsFlags? flags}) {
    final builder = ui.SemanticsUpdateBuilder();
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
      flags: flags ?? ui.SemanticsFlags.none,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 20, 20),
    );
    owner().updateSemantics(builder.build());
  }

  void renderLabel(String label) {
    renderSemantics(label: label);
  }

  test('produces a label', () async {
    semantics().semanticsEnabled = true;

    // Create
    renderLabel('Hello');

    final Map<int, SemanticsObject> tree = owner().debugSemanticsTree!;
    expect(tree.length, 2);
    expect(tree[0]!.id, 0);
    expect(tree[0]!.element.tagName.toLowerCase(), 'flt-semantics');
    expect(tree[1]!.id, 1);
    expect(tree[1]!.label, 'Hello');

    expectSemanticsTree(owner(), '''
<sem>
    <sem><span>Hello</span></sem>
</sem>''');

    // Update
    renderLabel('World');

    expectSemanticsTree(owner(), '''
<sem>
    <sem><span>World</span></sem>
</sem>''');

    // Remove
    renderLabel('');

    expectSemanticsTree(owner(), '''
<sem>
    <sem></sem>
</sem>''');

    semantics().semanticsEnabled = false;
  });

  test('can switch role', () async {
    semantics().semanticsEnabled = true;

    // Create
    renderSemantics(label: 'Hello');

    Map<int, SemanticsObject> tree = owner().debugSemanticsTree!;
    expect(tree.length, 2);
    expect(tree[1]!.element.tagName.toLowerCase(), 'flt-semantics');
    expect(tree[1]!.id, 1);
    expect(tree[1]!.label, 'Hello');
    final DomElement existingParent = tree[1]!.element.parent!;

    expectSemanticsTree(owner(), '''
<sem>
    <sem><span>Hello</span></sem>
</sem>''');

    // Update
    renderSemantics(label: 'Hello', flags: const ui.SemanticsFlags(isLink: true));

    tree = owner().debugSemanticsTree!;
    expect(tree.length, 2);
    expect(tree[1]!.id, 1);
    expect(tree[1]!.label, 'Hello');
    expect(tree[1]!.element.tagName.toLowerCase(), 'a');
    expectSemanticsTree(owner(), '''
<sem>
    <a style="display: block;">Hello</a>
</sem>''');
    expect(existingParent, tree[1]!.element.parent);

    semantics().semanticsEnabled = false;
  });

  test('tooltip is part of label', () async {
    semantics().semanticsEnabled = true;

    // Create
    renderSemantics(tooltip: 'tooltip');

    final Map<int, SemanticsObject> tree = owner().debugSemanticsTree!;
    expect(tree.length, 2);
    expect(tree[0]!.id, 0);
    expect(tree[0]!.element.tagName.toLowerCase(), 'flt-semantics');
    expect(tree[1]!.id, 1);
    expect(tree[1]!.tooltip, 'tooltip');

    expectSemanticsTree(owner(), '''
<sem>
    <sem><span>tooltip</span></sem>
</sem>''');

    // Update
    renderSemantics(label: 'Hello', tooltip: 'tooltip');

    expectSemanticsTree(owner(), '''
<sem>
    <sem><span>tooltip\nHello</span></sem>
</sem>''');

    // Remove
    renderSemantics();

    expectSemanticsTree(owner(), '''
<sem>
    <sem></sem>
</sem>''');

    semantics().semanticsEnabled = false;
  });

  test('clears semantics tree when disabled', () {
    expect(owner().debugSemanticsTree, isEmpty);
    semantics().semanticsEnabled = true;
    renderLabel('Hello');
    expect(owner().debugSemanticsTree, isNotEmpty);
    semantics().semanticsEnabled = false;
    expect(owner().debugSemanticsTree, isEmpty);
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
    final mockSemanticsEnabler = MockSemanticsEnabler();
    semantics().semanticsHelper.semanticsEnabler = mockSemanticsEnabler;
    final DomEvent pointerEvent = createDomEvent('Event', 'pointermove');

    semantics().receiveGlobalEvent(pointerEvent);

    // Verify the interactions.
    expect(mockSemanticsEnabler.shouldEnableSemanticsEvents, <DomEvent>[pointerEvent]);
  });

  test('forwards events to framework if shouldEnableSemantics returns true', () {
    final mockSemanticsEnabler = MockSemanticsEnabler();
    semantics().semanticsHelper.semanticsEnabler = mockSemanticsEnabler;
    final DomEvent pointerEvent = createDomEvent('Event', 'pointermove');
    mockSemanticsEnabler.shouldEnableSemanticsReturnValue = true;
    expect(semantics().receiveGlobalEvent(pointerEvent), isTrue);
  });

  test('semantics owner update phases', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    expect(reason: 'Should start in idle phase', owner().phase, SemanticsUpdatePhase.idle);

    void pumpSemantics({required String label}) {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        children: <SemanticsNodeUpdate>[tester.updateNode(id: 1, label: label)],
      );
      tester.apply();
    }

    SemanticsUpdatePhase? capturedPostUpdateCallbackPhase;
    owner().addOneTimePostUpdateCallback(() {
      capturedPostUpdateCallbackPhase = owner().phase;
    });

    pumpSemantics(label: 'Hello');

    final SemanticsObject semanticsObject = owner().debugSemanticsTree![1]!;

    expect(
      reason: 'Should be in postUpdate phase while calling post-update callbacks',
      capturedPostUpdateCallbackPhase,
      SemanticsUpdatePhase.postUpdate,
    );
    expect(
      reason: 'After the update is done, should go back to idle',
      owner().phase,
      SemanticsUpdatePhase.idle,
    );

    // Rudely replace the role with a mock, and trigger an update.
    final mockRole = MockRole(EngineSemanticsRole.generic, semanticsObject);
    semanticsObject.semanticRole = mockRole;

    pumpSemantics(label: 'World');

    expect(
      reason: 'While updating must be in SemanticsUpdatePhase.updating phase',
      mockRole.log,
      <MockRoleLogEntry>[(method: 'update', phase: SemanticsUpdatePhase.updating)],
    );

    semantics().semanticsEnabled = false;
  });
}

typedef MockRoleLogEntry = ({String method, SemanticsUpdatePhase phase});

class MockRole extends SemanticRole {
  MockRole(super.role, super.semanticsObject) : super.blank();

  final List<MockRoleLogEntry> log = <MockRoleLogEntry>[];

  void _log(String method) {
    log.add((method: method, phase: semanticsObject.owner.phase));
  }

  @override
  void update() {
    super.update();
    _log('update');
  }

  @override
  bool focusAsRouteDefault() {
    throw UnimplementedError();
  }
}

class MockSemanticsEnabler implements SemanticsEnabler {
  @override
  void dispose() {}

  @override
  bool get isWaitingToEnableSemantics => throw UnimplementedError();

  @override
  DomElement get accessibilityPlaceholder => throw UnimplementedError();

  @override
  void updatePlaceholderLabel(String message) {
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
  test(
    'renders an empty labeled header as a heading with a label and uses a sized span for label',
    () {
      semantics()
        ..debugOverrideTimestampFunction(() => _testTime)
        ..semanticsEnabled = true;

      final builder = ui.SemanticsUpdateBuilder();
      updateNode(
        builder,
        flags: const ui.SemanticsFlags(isHeader: true),

        label: 'Header of the page',
        transform: Matrix4.identity().toFloat64(),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );

      owner().updateSemantics(builder.build());
      expectSemanticsTree(owner(), '<h2>Header of the page</span></h2>');

      semantics().semanticsEnabled = false;
    },
  );

  // This is a useless case, but we should at least not crash if it happens.
  test('renders an empty unlabeled header', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      flags: const ui.SemanticsFlags(isHeader: true),
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '<header></header>');

    semantics().semanticsEnabled = false;
  });

  test('renders a header with children and uses aria-label', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      flags: const ui.SemanticsFlags(isHeader: true),
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

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<header aria-label="Header of the page"><sem></sem></header>
''');

    semantics().semanticsEnabled = false;
  });
}

void _testHeading() {
  test('renders aria-level tag for headings with heading level', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      headingLevel: 2,
      label: 'This is a heading',
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '<h2>This is a heading</h2>');

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
    expectLis(<int>[0, 1, -1, 2, -2, 3, -3, 4, -4, 5, -5], <int>[0, 1, 3, 5, 7, 9]);
  });

  test('fully sorted up', () {
    for (var count = 0; count < 100; count += 1) {
      expectLis(
        List<int>.generate(count, (int i) => 10 * i),
        List<int>.generate(count, (int i) => i),
      );
    }
  });

  test('fully sorted down', () {
    for (var count = 1; count < 100; count += 1) {
      expectLis(List<int>.generate(count, (int i) => 10 * (count - i)), <int>[count - 1]);
    }
  });
}

void _testLabels() {
  test('computeDomSemanticsLabel combines tooltip, label, and value', () {
    expect(computeDomSemanticsLabel(tooltip: 'tooltip'), 'tooltip');
    expect(computeDomSemanticsLabel(label: 'label'), 'label');
    expect(computeDomSemanticsLabel(value: 'value'), 'value');
    expect(computeDomSemanticsLabel(tooltip: 'tooltip', label: 'label', value: 'value'), '''
tooltip
label value''');
    expect(computeDomSemanticsLabel(tooltip: 'tooltip', value: 'value'), '''
tooltip
value''');
    expect(computeDomSemanticsLabel(tooltip: 'tooltip', label: 'label', value: 'value'), '''
tooltip
label value''');
    expect(computeDomSemanticsLabel(tooltip: 'tooltip', label: 'label'), '''
tooltip
label''');
  });

  test('computeDomSemanticsLabel collapses empty labels to null', () {
    expect(computeDomSemanticsLabel(), isNull);
    expect(computeDomSemanticsLabel(tooltip: ''), isNull);
    expect(computeDomSemanticsLabel(label: ''), isNull);
    expect(computeDomSemanticsLabel(value: ''), isNull);
    expect(computeDomSemanticsLabel(tooltip: '', label: '', value: ''), isNull);
    expect(computeDomSemanticsLabel(tooltip: '', value: ''), isNull);
    expect(computeDomSemanticsLabel(tooltip: '', label: '', value: ''), isNull);
    expect(computeDomSemanticsLabel(tooltip: '', label: ''), isNull);
  });

  test('LabelAndValue splits label and hint for all representations', () async {
    semantics().semanticsEnabled = true;
    final bool originalSupportsAriaDescription = LabelAndValue.supportsAriaDescription;

    for (final LabelRepresentation representation in LabelRepresentation.values) {
      final tester = SemanticsTester(owner());
      // For container nodes, children force ariaLabel, so test as a leaf node (no children)
      tester.updateNode(
        id: 0,
        label: 'Label',
        hint: 'Hint',
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      final SemanticsObject node = owner().debugSemanticsTree![0]!;
      final DomElement element = node.element;

      // Set the preferred representation directly (simulate what a custom role would do)
      node.semanticRole?.labelAndValue?.preferredRepresentation = representation;
      node.semanticRole?.labelAndValue?.update();

      // Check label is present in the correct place
      switch (representation) {
        case LabelRepresentation.ariaLabel:
          expect(element.getAttribute('aria-label'), 'Label');
        case LabelRepresentation.domText:
          expect(element.text, 'Label');
        case LabelRepresentation.sizedSpan:
          final DomElement? span = element.querySelector('span');
          expect(span, isNotNull);
          expect(span!.text, 'Label');
      }

      // Check hint is present as aria-description or aria-describedby
      LabelAndValue.supportsAriaDescriptionForTest = true;
      node.semanticRole?.labelAndValue?.update();
      expect(element.getAttribute('aria-description'), 'Hint');
      expect(element.getAttribute('aria-describedby'), isNull);

      LabelAndValue.supportsAriaDescriptionForTest = false;
      node.semanticRole?.labelAndValue?.update();
      expect(element.getAttribute('aria-description'), isNull);
      final String? ariaDescribedBy = element.getAttribute('aria-describedby');
      expect(ariaDescribedBy, isNotNull);
      final DomElement? describedNode = domDocument.getElementById(ariaDescribedBy!);
      expect(describedNode, isNotNull);
      expect(describedNode!.text, 'Hint');
    }

    LabelAndValue.supportsAriaDescriptionForTest = originalSupportsAriaDescription;
    semantics().semanticsEnabled = false;
  });

  test(
    'LabelAndValue fallback appends aria-describedby span to document.body when no parent',
    () async {
      semantics().semanticsEnabled = true;
      final bool originalSupportsAriaDescription = LabelAndValue.supportsAriaDescription;

      LabelAndValue.supportsAriaDescriptionForTest = false;

      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        label: 'Label',
        hint: 'Hint',
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();

      final SemanticsObject node = owner().debugSemanticsTree![0]!;
      final DomElement element = node.element;

      final String? ariaDescribedBy = element.getAttribute('aria-describedby');
      expect(ariaDescribedBy, isNotNull);

      // Verify the span was created and has the correct content
      final DomElement? describedNode = domDocument.getElementById(ariaDescribedBy!);
      expect(describedNode, isNotNull);
      expect(describedNode!.text, 'Hint');
      expect(describedNode.getAttribute('hidden'), '');

      // The span should be attached somewhere in the DOM
      expect(describedNode.isConnected, isTrue);

      // Test that the fallback logic works: when we manually remove the element from its parent
      // and call update again, the span should be appended to document.body as fallback
      final DomElement? originalParent = element.parentElement;
      element.remove();

      // Verify the span is still there but potentially orphaned
      final DomElement? describedNodeAfterRemove = domDocument.getElementById(ariaDescribedBy);
      expect(describedNodeAfterRemove, isNotNull);

      // Update should trigger fallback logic
      node.semanticRole?.labelAndValue?.update();

      // The span should still exist and be connected
      final DomElement? describedNodeAfterUpdate = domDocument.getElementById(ariaDescribedBy);
      expect(describedNodeAfterUpdate, isNotNull);
      expect(describedNodeAfterUpdate!.isConnected, isTrue);

      // Re-attach element to its original parent for proper cleanup
      if (originalParent != null) {
        originalParent.append(element);
      }

      LabelAndValue.supportsAriaDescriptionForTest = originalSupportsAriaDescription;
      semantics().semanticsEnabled = false;
    },
  );
}

void _testContainer() {
  test('child node has no transform when there is no rect offset', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    const zeroOffsetRect = ui.Rect.fromLTRB(0, 0, 20, 20);
    updateNode(
      builder,
      transform: Matrix4.identity().toFloat64(),
      rect: zeroOffsetRect,
      childrenInHitTestOrder: Int32List.fromList(<int>[1]),
      childrenInTraversalOrder: Int32List.fromList(<int>[1]),
    );
    updateNode(builder, id: 1, transform: Matrix4.identity().toFloat64(), rect: zeroOffsetRect);

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''<sem><sem></sem></sem>''');

    final DomElement parentElement = owner().semanticsHost.querySelector('flt-semantics')!;
    final DomElement childElement = owner().semanticsHost.querySelector(
      '#${kFlutterSemanticNodePrefix}1',
    )!;

    if (isMacOrIOS) {
      expect(parentElement.style.top, '0px');
      expect(parentElement.style.left, '0px');
      expect(childElement.style.top, '0px');
      expect(childElement.style.left, '0px');
    } else {
      expect(parentElement.style.top, '');
      expect(parentElement.style.left, '');
      expect(childElement.style.top, '');
      expect(childElement.style.left, '');
    }
    expect(parentElement.style.transform, '');
    expect(parentElement.style.transformOrigin, '');
    expect(childElement.style.transform, '');
    expect(childElement.style.transformOrigin, '');
    semantics().semanticsEnabled = false;
  });

  test('child node transform compensates for parent rect offset', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
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
      rect: const ui.Rect.fromLTRB(0, 0, 5, 5),
    );

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''<sem><sem></sem></sem>''');

    final DomElement parentElement = owner().semanticsHost.querySelector('flt-semantics')!;
    final DomElement childElement = owner().semanticsHost.querySelector(
      '#${kFlutterSemanticNodePrefix}1',
    )!;

    expect(parentElement.style.transform, 'matrix(1, 0, 0, 1, 10, 10)');
    if (isSafari) {
      // macOS 13 returns different values than macOS 12.
      expect(
        parentElement.style.transformOrigin,
        anyOf(contains('0px 0px 0px'), contains('0px 0px')),
      );
      expect(
        childElement.style.transformOrigin,
        anyOf(contains('0px 0px 0px'), contains('0px 0px')),
      );
    } else {
      expect(parentElement.style.transformOrigin, '0px 0px 0px');
      expect(childElement.style.transformOrigin, '0px 0px 0px');
    }
    expect(childElement.style.transform, 'matrix(1, 0, 0, 1, -10, -10)');
    expect(childElement.style.left == '0px' || childElement.style.left == '', isTrue);
    expect(childElement.style.top == '0px' || childElement.style.top == '', isTrue);

    semantics().semanticsEnabled = false;
  });

  test(
    'child node transform compensates for parent rect offset when parent rect changed',
    () async {
      semantics()
        ..debugOverrideTimestampFunction(() => _testTime)
        ..semanticsEnabled = true;

      final builder = ui.SemanticsUpdateBuilder();
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
        rect: const ui.Rect.fromLTRB(0, 0, 5, 5),
      );

      owner().updateSemantics(builder.build());
      expectSemanticsTree(owner(), '''<sem><sem></sem></sem>''');

      final DomElement parentElement = owner().semanticsHost.querySelector('flt-semantics')!;
      final DomElement childElement = owner().semanticsHost.querySelector(
        '#${kFlutterSemanticNodePrefix}1',
      )!;

      expect(parentElement.style.transform, 'matrix(1, 0, 0, 1, 10, 10)');
      if (isSafari) {
        // macOS 13 returns different values than macOS 12.
        expect(
          parentElement.style.transformOrigin,
          anyOf(contains('0px 0px 0px'), contains('0px 0px')),
        );
        expect(
          childElement.style.transformOrigin,
          anyOf(contains('0px 0px 0px'), contains('0px 0px')),
        );
      } else {
        expect(parentElement.style.transformOrigin, '0px 0px 0px');
        expect(childElement.style.transformOrigin, '0px 0px 0px');
      }
      expect(childElement.style.transform, 'matrix(1, 0, 0, 1, -10, -10)');
      expect(childElement.style.left == '0px' || childElement.style.left == '', isTrue);
      expect(childElement.style.top == '0px' || childElement.style.top == '', isTrue);

      final builder2 = ui.SemanticsUpdateBuilder();

      updateNode(
        builder2,
        transform: Matrix4.identity().toFloat64(),
        rect: const ui.Rect.fromLTRB(33, 33, 20, 20),
        childrenInHitTestOrder: Int32List.fromList(<int>[1]),
        childrenInTraversalOrder: Int32List.fromList(<int>[1]),
      );

      owner().updateSemantics(builder2.build());
      expectSemanticsTree(owner(), '''<sem><sem></sem></sem>''');

      expect(parentElement.style.transform, 'matrix(1, 0, 0, 1, 33, 33)');
      if (isSafari) {
        // macOS 13 returns different values than macOS 12.
        expect(
          parentElement.style.transformOrigin,
          anyOf(contains('0px 0px 0px'), contains('0px 0px')),
        );
        expect(
          childElement.style.transformOrigin,
          anyOf(contains('0px 0px 0px'), contains('0px 0px')),
        );
      } else {
        expect(parentElement.style.transformOrigin, '0px 0px 0px');
        expect(childElement.style.transformOrigin, '0px 0px 0px');
      }
      expect(childElement.style.transform, 'matrix(1, 0, 0, 1, -33, -33)');
      expect(childElement.style.left == '0px' || childElement.style.left == '', isTrue);
      expect(childElement.style.top == '0px' || childElement.style.top == '', isTrue);

      semantics().semanticsEnabled = false;
    },
  );

  test('renders in traversal order, hit-tests in reverse z-index order', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    // State 1: render initial tree with middle elements swapped hit-test wise
    {
      final builder = ui.SemanticsUpdateBuilder();
      updateNode(
        builder,
        childrenInTraversalOrder: Int32List.fromList(<int>[1, 2, 3, 4]),
        childrenInHitTestOrder: Int32List.fromList(<int>[1, 3, 2, 4]),
      );

      for (var id = 1; id <= 4; id++) {
        updateNode(builder, id: id);
      }

      owner().updateSemantics(builder.build());
      expectSemanticsTree(owner(), '''
<sem>
    <sem style="z-index: 4"></sem>
    <sem style="z-index: 2"></sem>
    <sem style="z-index: 3"></sem>
    <sem style="z-index: 1"></sem>
</sem>''');
    }

    // State 2: update z-index
    {
      final builder = ui.SemanticsUpdateBuilder();
      updateNode(
        builder,
        childrenInTraversalOrder: Int32List.fromList(<int>[1, 2, 3, 4]),
        childrenInHitTestOrder: Int32List.fromList(<int>[1, 2, 3, 4]),
      );
      owner().updateSemantics(builder.build());
      expectSemanticsTree(owner(), '''
<sem>
    <sem style="z-index: 4"></sem>
    <sem style="z-index: 3"></sem>
    <sem style="z-index: 2"></sem>
    <sem style="z-index: 1"></sem>
</sem>''');
    }

    // State 3: update traversal order
    {
      final builder = ui.SemanticsUpdateBuilder();
      updateNode(
        builder,
        childrenInTraversalOrder: Int32List.fromList(<int>[4, 2, 3, 1]),
        childrenInHitTestOrder: Int32List.fromList(<int>[1, 2, 3, 4]),
      );
      owner().updateSemantics(builder.build());
      expectSemanticsTree(owner(), '''
<sem>
    <sem style="z-index: 1"></sem>
    <sem style="z-index: 3"></sem>
    <sem style="z-index: 2"></sem>
    <sem style="z-index: 4"></sem>
</sem>''');
    }

    // State 3: update both orders
    {
      final builder = ui.SemanticsUpdateBuilder();
      updateNode(
        builder,
        childrenInTraversalOrder: Int32List.fromList(<int>[1, 3, 2, 4]),
        childrenInHitTestOrder: Int32List.fromList(<int>[3, 4, 1, 2]),
      );
      owner().updateSemantics(builder.build());
      expectSemanticsTree(owner(), '''
<sem>
    <sem style="z-index: 2"></sem>
    <sem style="z-index: 4"></sem>
    <sem style="z-index: 1"></sem>
    <sem style="z-index: 3"></sem>
</sem>''');
    }

    semantics().semanticsEnabled = false;
  });

  test('container nodes are transparent and leaf children are opaque hit-test wise', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      childrenInTraversalOrder: Int32List.fromList(<int>[1, 2]),
      childrenInHitTestOrder: Int32List.fromList(<int>[1, 2]),
    );
    updateNode(builder, id: 1, actions: ui.SemanticsAction.tap.index);
    updateNode(builder, id: 2, actions: ui.SemanticsAction.tap.index);

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem>
    <sem style="z-index: 2"></sem>
    <sem style="z-index: 1"></sem>
</sem>''');

    final DomElement root = owner().semanticsHost.querySelector('#${kFlutterSemanticNodePrefix}0')!;
    expect(root.style.pointerEvents, 'none');

    final DomElement child1 = owner().semanticsHost.querySelector(
      '#${kFlutterSemanticNodePrefix}1',
    )!;
    expect(child1.style.pointerEvents, 'all');

    final DomElement child2 = owner().semanticsHost.querySelector(
      '#${kFlutterSemanticNodePrefix}2',
    )!;
    expect(child2.style.pointerEvents, 'all');

    semantics().semanticsEnabled = false;
  });

  test('containers can be opaque if tappable', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.tap.index,
      childrenInTraversalOrder: Int32List.fromList(<int>[1, 2]),
      childrenInHitTestOrder: Int32List.fromList(<int>[1, 2]),
    );
    updateNode(builder, id: 1);
    updateNode(builder, id: 2);

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem>
    <sem style="z-index: 2"></sem>
    <sem style="z-index: 1"></sem>
</sem>''');

    final DomElement root = owner().semanticsHost.querySelector('#${kFlutterSemanticNodePrefix}0')!;
    expect(root.style.pointerEvents, 'all');

    semantics().semanticsEnabled = false;
  });
  test('container can be opaque if it is a text field', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      flags: const ui.SemanticsFlags(isTextField: true),
      childrenInTraversalOrder: Int32List.fromList(<int>[1, 2]),
      childrenInHitTestOrder: Int32List.fromList(<int>[1, 2]),
    );
    updateNode(builder, id: 1);
    updateNode(builder, id: 2);

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem>
  <input>
    <sem style="z-index: 2"></sem>
    <sem style="z-index: 1"></sem>
</sem>''');

    final DomElement root = owner().semanticsHost.querySelector('#${kFlutterSemanticNodePrefix}0')!;
    expect(root.style.pointerEvents, 'all');

    semantics().semanticsEnabled = false;
  });

  group('pointer events acceptance', () {
    setUp(() {
      semantics()
        ..debugOverrideTimestampFunction(() => _testTime)
        ..semanticsEnabled = true;
    });

    tearDown(() {
      semantics().semanticsEnabled = false;
    });

    test('non-interactive leaf nodes do not accept pointer events', () async {
      final builder = ui.SemanticsUpdateBuilder();
      // Create a non-interactive leaf node (no actions, no interactive flags)
      updateNode(builder);

      owner().updateSemantics(builder.build());

      final DomElement element = owner().semanticsHost.querySelector(
        '#${kFlutterSemanticNodePrefix}0',
      )!;
      expect(
        element.style.pointerEvents,
        'none',
        reason: 'Non-interactive leaf nodes should not intercept pointer events',
      );
    });

    test('tappable leaf nodes accept pointer events', () async {
      final builder = ui.SemanticsUpdateBuilder();
      updateNode(builder, actions: ui.SemanticsAction.tap.index);

      owner().updateSemantics(builder.build());

      final DomElement element = owner().semanticsHost.querySelector(
        '#${kFlutterSemanticNodePrefix}0',
      )!;
      expect(
        element.style.pointerEvents,
        'all',
        reason: 'Tappable nodes should accept pointer events',
      );
    });

    test('button leaf nodes accept pointer events', () async {
      final builder = ui.SemanticsUpdateBuilder();
      updateNode(
        builder,
        flags: const ui.SemanticsFlags(isButton: true),
        actions: ui.SemanticsAction.tap.index,
      );

      owner().updateSemantics(builder.build());

      final DomElement element = owner().semanticsHost.querySelector(
        '#${kFlutterSemanticNodePrefix}0',
      )!;
      expect(
        element.style.pointerEvents,
        'all',
        reason: 'Button nodes should accept pointer events',
      );
    });

    test('checkable leaf nodes accept pointer events', () async {
      final builder = ui.SemanticsUpdateBuilder();
      updateNode(builder, flags: const ui.SemanticsFlags(isChecked: ui.CheckedState.isFalse));

      owner().updateSemantics(builder.build());

      final DomElement element = owner().semanticsHost.querySelector(
        '#${kFlutterSemanticNodePrefix}0',
      )!;
      expect(
        element.style.pointerEvents,
        'all',
        reason: 'Checkable nodes should accept pointer events',
      );
    });

    test('text field leaf nodes accept pointer events', () async {
      final builder = ui.SemanticsUpdateBuilder();
      updateNode(builder, flags: const ui.SemanticsFlags(isTextField: true));

      owner().updateSemantics(builder.build());

      final DomElement element = owner().semanticsHost.querySelector(
        '#${kFlutterSemanticNodePrefix}0',
      )!;
      expect(
        element.style.pointerEvents,
        'all',
        reason: 'Text field nodes should accept pointer events',
      );
    });

    test('link leaf nodes accept pointer events', () async {
      final builder = ui.SemanticsUpdateBuilder();
      updateNode(builder, flags: const ui.SemanticsFlags(isLink: true));

      owner().updateSemantics(builder.build());

      final DomElement element = owner().semanticsHost.querySelector(
        '#${kFlutterSemanticNodePrefix}0',
      )!;
      expect(element.style.pointerEvents, 'all', reason: 'Link nodes should accept pointer events');
    });

    test('incrementable leaf nodes accept pointer events', () async {
      final builder = ui.SemanticsUpdateBuilder();
      updateNode(builder, actions: ui.SemanticsAction.increase.index);

      owner().updateSemantics(builder.build());

      final DomElement element = owner().semanticsHost.querySelector(
        '#${kFlutterSemanticNodePrefix}0',
      )!;
      expect(
        element.style.pointerEvents,
        'all',
        reason: 'Incrementable nodes should accept pointer events',
      );
    });

    test('non-interactive containers do not accept pointer events', () async {
      final builder = ui.SemanticsUpdateBuilder();
      // Create a container with children but no explicit hitTestBehavior
      updateNode(
        builder,
        childrenInTraversalOrder: Int32List.fromList(<int>[1]),
        childrenInHitTestOrder: Int32List.fromList(<int>[1]),
      );
      updateNode(builder, id: 1);

      owner().updateSemantics(builder.build());

      final DomElement container = owner().semanticsHost.querySelector(
        '#${kFlutterSemanticNodePrefix}0',
      )!;
      expect(
        container.style.pointerEvents,
        'none',
        reason:
            'Non-interactive containers should not accept pointer events when hitTestBehavior is defer',
      );
    });

    test('hitTestBehavior.opaque makes nodes accept pointer events', () async {
      final builder = ui.SemanticsUpdateBuilder();
      updateNode(builder, hitTestBehavior: ui.SemanticsHitTestBehavior.opaque);

      owner().updateSemantics(builder.build());

      final DomElement element = owner().semanticsHost.querySelector(
        '#${kFlutterSemanticNodePrefix}0',
      )!;
      expect(
        element.style.pointerEvents,
        'all',
        reason: 'Nodes with hitTestBehavior.opaque should accept pointer events',
      );
    });

    test('hitTestBehavior.transparent makes nodes not accept pointer events', () async {
      final builder = ui.SemanticsUpdateBuilder();
      updateNode(builder, hitTestBehavior: ui.SemanticsHitTestBehavior.transparent);

      owner().updateSemantics(builder.build());

      final DomElement element = owner().semanticsHost.querySelector(
        '#${kFlutterSemanticNodePrefix}0',
      )!;
      expect(
        element.style.pointerEvents,
        'none',
        reason: 'Nodes with hitTestBehavior.transparent should not accept pointer events',
      );
    });

    test('hitTestBehavior takes precedence over interactive behaviors', () async {
      final builder = ui.SemanticsUpdateBuilder();
      // Create a tappable node with explicit transparent behavior
      updateNode(
        builder,
        actions: ui.SemanticsAction.tap.index,
        hitTestBehavior: ui.SemanticsHitTestBehavior.transparent,
      );

      owner().updateSemantics(builder.build());

      final DomElement element = owner().semanticsHost.querySelector(
        '#${kFlutterSemanticNodePrefix}0',
      )!;
      expect(
        element.style.pointerEvents,
        'none',
        reason:
            'Framework declaration (Tier 1) should take precedence over interactive behaviors (Tier 2)',
      );
    });
  });

  test('descendant nodes are removed from the node map, unless reparented', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    {
      final builder = ui.SemanticsUpdateBuilder();
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

      owner().updateSemantics(builder.build());
      expectSemanticsTree(owner(), '''
  <sem>
      <sem style="z-index: 2">
          <sem style="z-index: 2"></sem>
          <sem style="z-index: 1"></sem>
      </sem>
      <sem style="z-index: 1">
          <sem style="z-index: 2"></sem>
          <sem style="z-index: 1"></sem>
      </sem>
  </sem>''');

      expect(
        owner().debugSemanticsTree!.keys.toList(),
        unorderedEquals(<int>[0, 1, 2, 3, 4, 5, 6]),
      );
    }

    // Remove node #2 => expect nodes #2 and #5 to be removed and #6 reparented.
    {
      final builder = ui.SemanticsUpdateBuilder();
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

      owner().updateSemantics(builder.build());
      expectSemanticsTree(owner(), '''
  <sem>
      <sem style="z-index: 2">
          <sem style="z-index: 3"></sem>
          <sem style="z-index: 2"></sem>
          <sem style="z-index: 1"></sem>
      </sem>
  </sem>''');

      expect(owner().debugSemanticsTree!.keys.toList(), unorderedEquals(<int>[0, 1, 3, 4, 6]));
    }

    semantics().semanticsEnabled = false;
  });

  // Regression test for: https://github.com/flutter/flutter/issues/175180
  test('A subtree of descendant nodes are reparented together', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    {
      final builder = ui.SemanticsUpdateBuilder();
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
      updateNode(
        builder,
        id: 6,
        childrenInTraversalOrder: Int32List.fromList(<int>[7]),
        childrenInHitTestOrder: Int32List.fromList(<int>[7]),
      );
      updateNode(builder, id: 7);

      owner().updateSemantics(builder.build());
      expectSemanticsTree(owner(), '''
  <sem>
      <sem style="z-index: 2">
          <sem style="z-index: 2"></sem>
          <sem style="z-index: 1"></sem>
      </sem>
      <sem style="z-index: 1">
          <sem style="z-index: 2"></sem>
          <sem style="z-index: 1">
              <sem></sem>
          </sem>
      </sem>
  </sem>''');

      expect(
        owner().debugSemanticsTree!.keys.toList(),
        unorderedEquals(<int>[0, 1, 2, 3, 4, 5, 6, 7]),
      );
    }

    // Remove node #2 => expect nodes #2 and #5 to be removed and #6 reparented.
    // Node #7 is #6's child, so it will stay in the tree.
    {
      final builder = ui.SemanticsUpdateBuilder();
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

      owner().updateSemantics(builder.build());
      expectSemanticsTree(owner(), '''
  <sem>
      <sem style="z-index: 2">
          <sem style="z-index: 3"></sem>
          <sem style="z-index: 2"></sem>
          <sem style="z-index: 1">
              <sem></sem>
          </sem>
      </sem>
  </sem>''');

      expect(owner().debugSemanticsTree!.keys.toList(), unorderedEquals(<int>[0, 1, 3, 4, 6, 7]));
    }

    semantics().semanticsEnabled = false;
  });

  test('node updated with role change', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    {
      final builder = ui.SemanticsUpdateBuilder();
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

      owner().updateSemantics(builder.build());
      expectSemanticsTree(owner(), '''
  <sem>
      <sem style="z-index: 2">
          <sem style="z-index: 2"></sem>
          <sem style="z-index: 1"></sem>
      </sem>
      <sem style="z-index: 1">
          <sem style="z-index: 2"></sem>
          <sem style="z-index: 1"></sem>
      </sem>
  </sem>''');

      expect(
        owner().debugSemanticsTree!.keys.toList(),
        unorderedEquals(<int>[0, 1, 2, 3, 4, 5, 6]),
      );
    }

    // update node #2 with a new role
    {
      final builder = ui.SemanticsUpdateBuilder();
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
        role: ui.SemanticsRole.table,
        childrenInTraversalOrder: Int32List.fromList(<int>[5, 6]),
        childrenInHitTestOrder: Int32List.fromList(<int>[5, 6]),
      );
      updateNode(builder, id: 3);
      updateNode(builder, id: 4);
      updateNode(builder, id: 5);
      updateNode(builder, id: 6);

      owner().updateSemantics(builder.build());
      expectSemanticsTree(owner(), '''
  <sem>
      <sem style="z-index: 2">
          <sem style="z-index: 2"></sem>
          <sem style="z-index: 1"></sem>
      </sem>
      <sem style="z-index: 1">
          <sem style="z-index: 2"></sem>
          <sem style="z-index: 1"></sem>
      </sem>
  </sem>''');

      expect(
        owner().debugSemanticsTree!.keys.toList(),
        unorderedEquals(<int>[0, 1, 2, 3, 4, 5, 6]),
      );
    }

    semantics().semanticsEnabled = false;
  });

  test('reparented nodes have correct transform and position', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;
    {
      final builder = ui.SemanticsUpdateBuilder();
      updateNode(
        builder,
        childrenInTraversalOrder: Int32List.fromList(<int>[1, 2]),
        childrenInHitTestOrder: Int32List.fromList(<int>[1, 2]),
        rect: const ui.Rect.fromLTRB(11, 11, 111, 111),
      );
      updateNode(builder, id: 1, rect: const ui.Rect.fromLTRB(10, 10, 20, 20));
      updateNode(
        builder,
        id: 2,
        childrenInTraversalOrder: Int32List.fromList(<int>[3]),
        childrenInHitTestOrder: Int32List.fromList(<int>[3]),
        rect: const ui.Rect.fromLTRB(22, 22, 222, 222),
      );

      updateNode(builder, id: 3);

      owner().updateSemantics(builder.build());

      final DomElement childElement = owner().semanticsHost.querySelector(
        '#${kFlutterSemanticNodePrefix}3',
      )!;

      expectSemanticsTree(owner(), '''
  <sem>
      <sem style="z-index: 2"></sem>
      <sem style="z-index: 1">
        <sem></sem>
      </sem>
  </sem>''');

      expect(owner().debugSemanticsTree!.keys.toList(), unorderedEquals(<int>[0, 1, 2, 3]));

      expect(childElement.style.transform, 'matrix(1, 0, 0, 1, -22, -22)');
      expect(childElement.style.left == '0px' || childElement.style.left == '', isTrue);
      expect(childElement.style.top == '0px' || childElement.style.top == '', isTrue);
    }

    // Remove node #2 => expect nodes #2 to be removed and #3 reparented.
    {
      final builder = ui.SemanticsUpdateBuilder();
      updateNode(
        builder,
        childrenInTraversalOrder: Int32List.fromList(<int>[1]),
        childrenInHitTestOrder: Int32List.fromList(<int>[1]),
      );
      updateNode(
        builder,
        id: 1,
        childrenInTraversalOrder: Int32List.fromList(<int>[3]),
        childrenInHitTestOrder: Int32List.fromList(<int>[3]),
        rect: const ui.Rect.fromLTRB(11, 11, 111, 111),
      );
      updateNode(builder, id: 3);
      owner().updateSemantics(builder.build());

      final DomElement childElement = owner().semanticsHost.querySelector(
        '#${kFlutterSemanticNodePrefix}3',
      )!;
      expectSemanticsTree(owner(), '''
    <sem>
        <sem style="z-index: 2">
            <sem ></sem>
        </sem>
    </sem>''');

      expect(owner().debugSemanticsTree!.keys.toList(), unorderedEquals(<int>[0, 1, 3]));
      expect(childElement.style.transform, 'matrix(1, 0, 0, 1, -11, -11)');
      expect(childElement.style.left == '0px' || childElement.style.left == '', isTrue);
      expect(childElement.style.top == '0px' || childElement.style.top == '', isTrue);
    }

    semantics().semanticsEnabled = false;
  });
}

void _testVerticalScrolling() {
  test('recognizes scrollable node when scroll actions not available', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      flags: const ui.SemanticsFlags(hasImplicitScrolling: true),
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 50, 100),
    );

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
  <sem role="group" style="touch-action: none">
  <flt-semantics-scroll-overflow></flt-semantics-scroll-overflow>
  </sem>''');

    final DomElement scrollable = findScrollable(owner());
    expect(scrollable.scrollTop, isZero);
    semantics().semanticsEnabled = false;
  });

  test('scroll events ignored when actions not available', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      flags: const ui.SemanticsFlags(hasImplicitScrolling: true),
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 50, 100),
    );

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
  <sem role="group" style="touch-action: none">
  <flt-semantics-scroll-overflow></flt-semantics-scroll-overflow>
  </sem>''');

    final scrollable = owner().debugSemanticsTree![0]!.semanticRole! as SemanticScrollable;
    final scrollEvent = createDomEvent('Event', 'scroll') as JSAny;
    final DomEventListener listener = scrollable.scrollListener!;
    expect(() => listener.callAsFunction(null, scrollEvent), returnsNormally);

    semantics().semanticsEnabled = false;
  });

  test('renders an empty scrollable node', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      flags: const ui.SemanticsFlags(hasImplicitScrolling: true),
      actions: 0 | ui.SemanticsAction.scrollUp.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 50, 100),
    );

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem role="group" style="touch-action: none; overflow-y: scroll">
<flt-semantics-scroll-overflow></flt-semantics-scroll-overflow>
</sem>''');

    final DomElement scrollable = findScrollable(owner());
    expect(scrollable.scrollTop, 0);
    semantics().semanticsEnabled = false;
  });

  test('scrollable node with children has a container node', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      flags: const ui.SemanticsFlags(hasImplicitScrolling: true),
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

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem style="touch-action: none; overflow-y: scroll">
<flt-semantics-scroll-overflow></flt-semantics-scroll-overflow>
    <sem></sem>
</sem>''');

    final DomElement scrollable = findScrollable(owner());
    expect(scrollable, isNotNull);

    // When there's less content than the available size the neutral scrollTop
    // is 0.
    expect(scrollable.scrollTop, 0);

    semantics().semanticsEnabled = false;
  });

  test('scrollable node dispatches scroll events', () async {
    Future<ui.SemanticsActionEvent> captureSemanticsEvent() {
      final completer = Completer<ui.SemanticsActionEvent>();
      ui.PlatformDispatcher.instance.onSemanticsActionEvent = (ui.SemanticsActionEvent event) {
        completer.complete(event);
      };
      return completer.future;
    }

    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    addTearDown(() async {
      semantics().semanticsEnabled = false;
    });

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      flags: const ui.SemanticsFlags(hasImplicitScrolling: true),
      actions: 0 | ui.SemanticsAction.scrollUp.index | ui.SemanticsAction.scrollDown.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 50, 100),
      childrenInHitTestOrder: Int32List.fromList(<int>[1, 2, 3]),
      childrenInTraversalOrder: Int32List.fromList(<int>[1, 2, 3]),
    );

    for (var id = 1; id <= 3; id++) {
      updateNode(
        builder,
        id: id,
        transform: Matrix4.translationValues(0, 50.0 * id, 0).toFloat64(),
        rect: const ui.Rect.fromLTRB(0, 0, 50, 50),
      );
    }

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem style="touch-action: none; overflow-y: scroll">
  <flt-semantics-scroll-overflow></flt-semantics-scroll-overflow>
    <sem style="z-index: 3"></sem>
    <sem style="z-index: 2"></sem>
    <sem style="z-index: 1"></sem>
</sem>''');

    final DomElement scrollable = owner().debugSemanticsTree![0]!.element;
    expect(scrollable, isNotNull);
    expect(scrollable.scrollTop, 0);

    Future<ui.SemanticsActionEvent> capturedEventFuture = captureSemanticsEvent();
    scrollable.scrollTop = 20;
    expect(scrollable.scrollTop, 20);
    ui.SemanticsActionEvent capturedEvent = await capturedEventFuture;

    expect(capturedEvent.nodeId, 0);
    expect(capturedEvent.type, ui.SemanticsAction.scrollToOffset);
    expect(capturedEvent.arguments, isNotNull);
    final expectedOffset = Float64List(2);
    expectedOffset[0] = 0.0;
    expectedOffset[1] = 20.0;
    var message =
        const StandardMessageCodec().decodeMessage(capturedEvent.arguments! as ByteData)
            as Float64List;
    expect(message, expectedOffset);

    // Update scrollPosition to scrollTop value.
    final builder2 = ui.SemanticsUpdateBuilder();
    updateNode(
      builder2,
      scrollPosition: 20.0,
      flags: const ui.SemanticsFlags(hasImplicitScrolling: true),
      actions: 0 | ui.SemanticsAction.scrollUp.index | ui.SemanticsAction.scrollDown.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 50, 100),
      childrenInHitTestOrder: Int32List.fromList(<int>[1, 2, 3]),
      childrenInTraversalOrder: Int32List.fromList(<int>[1, 2, 3]),
    );
    owner().updateSemantics(builder2.build());

    capturedEventFuture = captureSemanticsEvent();
    scrollable.scrollTop = 5;
    capturedEvent = await capturedEventFuture;

    expect(scrollable.scrollTop, 5);
    expect(capturedEvent.nodeId, 0);
    expect(capturedEvent.type, ui.SemanticsAction.scrollToOffset);
    expect(capturedEvent.arguments, isNotNull);
    expectedOffset[0] = 0.0;
    expectedOffset[1] = 5.0;
    message =
        const StandardMessageCodec().decodeMessage(capturedEvent.arguments! as ByteData)
            as Float64List;
    expect(message, expectedOffset);
  });

  test('scrollable switches to pointer event mode on a wheel event', () async {
    final actionLog = <ui.SemanticsActionEvent>[];
    ui.PlatformDispatcher.instance.onSemanticsActionEvent = actionLog.add;

    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    addTearDown(() async {
      semantics().semanticsEnabled = false;
    });

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      flags: const ui.SemanticsFlags(hasImplicitScrolling: true),
      actions: 0 | ui.SemanticsAction.scrollUp.index | ui.SemanticsAction.scrollDown.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 50, 100),
      childrenInHitTestOrder: Int32List.fromList(<int>[1, 2, 3]),
      childrenInTraversalOrder: Int32List.fromList(<int>[1, 2, 3]),
    );

    for (var id = 1; id <= 3; id++) {
      updateNode(
        builder,
        id: id,
        transform: Matrix4.translationValues(0, 50.0 * id, 0).toFloat64(),
        rect: const ui.Rect.fromLTRB(0, 0, 50, 50),
      );
    }

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem style="touch-action: none; overflow-y: scroll">
  <flt-semantics-scroll-overflow></flt-semantics-scroll-overflow>
    <sem style="z-index: 3"></sem>
    <sem style="z-index: 2"></sem>
    <sem style="z-index: 1"></sem>
</sem>''');

    final DomElement scrollable = owner().debugSemanticsTree![0]!.element;
    expect(scrollable, isNotNull);

    // Initially, starting at "scrollTop" 0, everything should be
    // in browser gesture mode, react to DOM scroll events, and generate
    // semantic actions.
    expect(scrollable.scrollTop, 0);
    expect(semantics().gestureMode, GestureMode.browserGestures);
    scrollable.scrollTop = 20;
    expect(scrollable.scrollTop, 20);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(actionLog, hasLength(1));
    final ui.SemanticsActionEvent capturedEvent = actionLog.removeLast();
    expect(capturedEvent.type, ui.SemanticsAction.scrollToOffset);

    // Now, starting at the "scrollTop" 20 we set, observing a DOM "wheel" event should
    // swap into pointer event mode, and the scrollable becomes a plain clip,
    // i.e. `overflow: hidden`.
    expect(scrollable.scrollTop, 20);
    expect(semantics().gestureMode, GestureMode.browserGestures);
    expect(scrollable.style.overflowY, 'scroll');

    semantics().receiveGlobalEvent(createDomEvent('Event', 'wheel'));
    expect(semantics().gestureMode, GestureMode.pointerEvents);
    expect(scrollable.style.overflowY, 'hidden');
  });
}

void _testHorizontalScrolling() {
  test('renders an empty scrollable node', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      flags: const ui.SemanticsFlags(hasImplicitScrolling: true),
      actions: 0 | ui.SemanticsAction.scrollLeft.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem role="group" style="touch-action: none; overflow-x: scroll">
<flt-semantics-scroll-overflow></flt-semantics-scroll-overflow>
</sem>''');

    semantics().semanticsEnabled = false;
  });

  test('scrollable node with children has a container node', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      flags: const ui.SemanticsFlags(hasImplicitScrolling: true),
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

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem style="touch-action: none; overflow-x: scroll">
<flt-semantics-scroll-overflow></flt-semantics-scroll-overflow>
    <sem></sem>
</sem>''');

    final DomElement scrollable = findScrollable(owner());
    expect(scrollable, isNotNull);

    // When there's less content than the available size the neutral
    // scrollLeft is still 0.
    expect(scrollable.scrollLeft, 0);

    semantics().semanticsEnabled = false;
  });

  test('scrollable node dispatches scroll events', () async {
    Future<ui.SemanticsActionEvent> captureSemanticsEvent() {
      final completer = Completer<ui.SemanticsActionEvent>();
      ui.PlatformDispatcher.instance.onSemanticsActionEvent = (ui.SemanticsActionEvent event) {
        completer.complete(event);
      };
      return completer.future;
    }

    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    addTearDown(() async {
      semantics().semanticsEnabled = false;
    });

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      flags: const ui.SemanticsFlags(hasImplicitScrolling: true),
      actions: 0 | ui.SemanticsAction.scrollLeft.index | ui.SemanticsAction.scrollRight.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      childrenInHitTestOrder: Int32List.fromList(<int>[1, 2, 3]),
      childrenInTraversalOrder: Int32List.fromList(<int>[1, 2, 3]),
    );

    for (var id = 1; id <= 3; id++) {
      updateNode(
        builder,
        id: id,
        transform: Matrix4.translationValues(50.0 * id, 0, 0).toFloat64(),
        rect: const ui.Rect.fromLTRB(0, 0, 50, 50),
      );
    }

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem style="touch-action: none; overflow-x: scroll">
  <flt-semantics-scroll-overflow></flt-semantics-scroll-overflow>
    <sem style="z-index: 3"></sem>
    <sem style="z-index: 2"></sem>
    <sem style="z-index: 1"></sem>
</sem>''');

    final DomElement scrollable = findScrollable(owner());
    expect(scrollable, isNotNull);
    expect(scrollable.scrollLeft, 0);

    Future<ui.SemanticsActionEvent> capturedEventFuture = captureSemanticsEvent();
    scrollable.scrollLeft = 20;
    expect(scrollable.scrollLeft, 20);
    ui.SemanticsActionEvent capturedEvent = await capturedEventFuture;

    expect(capturedEvent.nodeId, 0);
    expect(capturedEvent.type, ui.SemanticsAction.scrollToOffset);
    expect(capturedEvent.arguments, isNotNull);
    final expectedOffset = Float64List(2);
    expectedOffset[0] = 20.0;
    expectedOffset[1] = 0.0;
    var message =
        const StandardMessageCodec().decodeMessage(capturedEvent.arguments! as ByteData)
            as Float64List;
    expect(message, expectedOffset);

    // Update scrollPosition to scrollLeft value.
    final builder2 = ui.SemanticsUpdateBuilder();
    updateNode(
      builder2,
      scrollPosition: 20.0,
      flags: const ui.SemanticsFlags(hasImplicitScrolling: true),
      actions: 0 | ui.SemanticsAction.scrollLeft.index | ui.SemanticsAction.scrollRight.index,
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 50, 100),
      childrenInHitTestOrder: Int32List.fromList(<int>[1, 2, 3]),
      childrenInTraversalOrder: Int32List.fromList(<int>[1, 2, 3]),
    );
    owner().updateSemantics(builder2.build());

    capturedEventFuture = captureSemanticsEvent();
    scrollable.scrollLeft = 5;
    capturedEvent = await capturedEventFuture;

    expect(scrollable.scrollLeft, 5);
    expect(capturedEvent.nodeId, 0);
    expect(capturedEvent.type, ui.SemanticsAction.scrollToOffset);
    expect(capturedEvent.arguments, isNotNull);
    expectedOffset[0] = 5.0;
    expectedOffset[1] = 0.0;
    message =
        const StandardMessageCodec().decodeMessage(capturedEvent.arguments! as ByteData)
            as Float64List;
    expect(message, expectedOffset);
  });
}

void _testIncrementables() {
  test('renders a trivial incrementable node', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.increase.index,
      value: 'd',
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem>
  <input role="slider" aria-valuenow="1" aria-valuetext="d" aria-valuemax="1" aria-valuemin="1">
</sem>''');

    final SemanticsObject node = owner().debugSemanticsTree![0]!;
    expect(node.semanticRole?.kind, EngineSemanticsRole.incrementable);
    expect(
      reason: 'Incrementables use custom focus management',
      node.semanticRole!.debugSemanticBehaviorTypes,
      isNot(contains(Focusable)),
    );

    semantics().semanticsEnabled = false;
  });

  test('increments', () async {
    final logger = SemanticsActionLogger();
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.increase.index,
      value: 'd',
      increasedValue: 'e',
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem>
  <input role="slider" aria-valuenow="1" aria-valuetext="d" aria-valuemax="2" aria-valuemin="1">
</sem>''');

    final input = owner().semanticsHost.querySelector('input')! as DomHTMLInputElement;
    input.value = '2';
    input.dispatchEvent(createDomEvent('Event', 'change'));

    expect(await logger.idLog.first, 0);
    expect(await logger.actionLog.first, ui.SemanticsAction.increase);

    semantics().semanticsEnabled = false;
  });

  test('decrements', () async {
    final logger = SemanticsActionLogger();
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.decrease.index,
      value: 'd',
      decreasedValue: 'c',
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem>
  <input role="slider" aria-valuenow="1" aria-valuetext="d" aria-valuemax="1" aria-valuemin="0">
</sem>''');

    final input = owner().semanticsHost.querySelector('input')! as DomHTMLInputElement;
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

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.decrease.index | ui.SemanticsAction.increase.index,
      value: 'd',
      increasedValue: 'e',
      decreasedValue: 'c',
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem>
  <input role="slider" aria-valuenow="1" aria-valuetext="d" aria-valuemax="2" aria-valuemin="0">
</sem>''');

    semantics().semanticsEnabled = false;
  });

  test('sends focus events', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    void pumpSemantics({required ui.Tristate isFocused}) {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        hasIncrease: true,
        flags: ui.SemanticsFlags(isFocused: isFocused, isEnabled: ui.Tristate.isTrue),
        value: 'd',
        transform: Matrix4.identity().toFloat64(),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
    }

    final capturedActions = <CapturedAction>[];
    EnginePlatformDispatcher.instance.onSemanticsActionEvent = (ui.SemanticsActionEvent event) {
      capturedActions.add((event.nodeId, event.type, event.arguments));
    };

    pumpSemantics(isFocused: ui.Tristate.isFalse);
    final DomElement element = owner().debugSemanticsTree![0]!.element.querySelector('input')!;
    expect(capturedActions, isEmpty);

    pumpSemantics(isFocused: ui.Tristate.isTrue);
    expect(
      reason: 'Framework requested focus. No need to circle the event back to the framework.',
      capturedActions,
      isEmpty,
    );
    capturedActions.clear();

    element.blur();
    element.focusWithoutScroll();
    expect(
      reason: 'Browser-initiated focus even should be communicated to the framework.',
      capturedActions,
      <CapturedAction>[(0, ui.SemanticsAction.focus, null)],
    );
    capturedActions.clear();

    pumpSemantics(isFocused: ui.Tristate.isFalse);
    expect(reason: 'The engine never calls blur() explicitly.', capturedActions, isEmpty);

    // The web doesn't send didLoseAccessibilityFocus as on the web,
    // accessibility focus is not observable, only input focus is. As of this
    // writing, there is no SemanticsAction.unfocus action, so the test simply
    // asserts that no actions are being sent as a result of blur.
    element.blur();
    expect(capturedActions, isEmpty);

    semantics().semanticsEnabled = false;
  });
}

void _testTextField() {
  test('renders a text field', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.tap.index,
      flags: const ui.SemanticsFlags(isTextField: true),

      value: 'hello',
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    owner().updateSemantics(builder.build());

    expectSemanticsTree(owner(), '''
<sem>
  <input />
</sem>''');

    final SemanticsObject node = owner().debugSemanticsTree![0]!;
    final textFieldRole = node.semanticRole! as SemanticTextField;
    final inputElement = textFieldRole.editableElement as DomHTMLInputElement;

    // TODO(yjbanov): this used to attempt to test that value="hello" but the
    //                test was a false positive. We should revise this test and
    //                make sure it tests the right things:
    //                https://github.com/flutter/flutter/issues/147200
    expect(inputElement.value, '');

    expect(node.semanticRole?.kind, EngineSemanticsRole.textField);
    expect(
      reason: 'Text fields use custom focus management',
      node.semanticRole!.debugSemanticBehaviorTypes,
      isNot(contains(Focusable)),
    );

    semantics().semanticsEnabled = false;
  });
}

void _testCheckables() {
  test('renders a switched on switch element', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.tap.index,
      label: 'test label',
      flags: const ui.SemanticsFlags(
        isEnabled: ui.Tristate.isTrue,
        isToggled: ui.Tristate.isTrue,
        isFocused: ui.Tristate.isFalse,
      ),
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem aria-label="test label" flt-tappable role="switch" aria-checked="true"></sem>
''');

    final SemanticsObject node = owner().debugSemanticsTree![0]!;
    expect(node.semanticRole?.kind, EngineSemanticsRole.checkable);
    expect(
      reason: 'Checkables use generic semantic behaviors',
      node.semanticRole!.debugSemanticBehaviorTypes,
      containsAll(<Type>[Focusable, Tappable]),
    );

    semantics().semanticsEnabled = false;
  });

  test('renders a switched on disabled switch element', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.tap.index,
      flags: const ui.SemanticsFlags(isEnabled: ui.Tristate.isFalse, isToggled: ui.Tristate.isTrue),

      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem role="switch" aria-disabled="true" aria-checked="true"></sem>
''');

    semantics().semanticsEnabled = false;
  });

  test('renders a switched off switch element', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.tap.index,
      flags: const ui.SemanticsFlags(isToggled: ui.Tristate.isFalse, isEnabled: ui.Tristate.isTrue),
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem role="switch" flt-tappable aria-checked="false"></sem>
''');

    semantics().semanticsEnabled = false;
  });

  test('renders a checked checkbox', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.tap.index,

      flags: const ui.SemanticsFlags(
        isEnabled: ui.Tristate.isTrue,
        isChecked: ui.CheckedState.isTrue,
      ),

      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem role="checkbox" flt-tappable aria-checked="true"></sem>
''');

    semantics().semanticsEnabled = false;
  });

  test('renders a checked disabled checkbox', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.tap.index,

      flags: const ui.SemanticsFlags(
        isChecked: ui.CheckedState.isTrue,
        isEnabled: ui.Tristate.isFalse,
      ),
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem role="checkbox" aria-disabled="true" aria-checked="true"></sem>
''');

    semantics().semanticsEnabled = false;
  });

  test('renders an unchecked checkbox', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.tap.index,

      flags: const ui.SemanticsFlags(
        isChecked: ui.CheckedState.isFalse,
        isEnabled: ui.Tristate.isTrue,
      ),
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem role="checkbox" flt-tappable aria-checked="false"></sem>
''');

    semantics().semanticsEnabled = false;
  });

  test('renders a checked radio button', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.tap.index,
      flags: const ui.SemanticsFlags(
        isChecked: ui.CheckedState.isTrue,
        isInMutuallyExclusiveGroup: true,
        isEnabled: ui.Tristate.isTrue,
      ),

      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem role="radio" flt-tappable aria-checked="true"></sem>
''');

    semantics().semanticsEnabled = false;
  });

  test('renders a checked disabled radio button', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.tap.index,
      flags: const ui.SemanticsFlags(
        isEnabled: ui.Tristate.isFalse,
        isChecked: ui.CheckedState.isTrue,
        isInMutuallyExclusiveGroup: true,
      ),
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem role="radio" aria-disabled="true" aria-checked="true"></sem>
''');

    semantics().semanticsEnabled = false;
  });

  test('renders an unchecked checkbox', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      actions: 0 | ui.SemanticsAction.tap.index,
      flags: const ui.SemanticsFlags(
        isChecked: ui.CheckedState.isFalse,
        isInMutuallyExclusiveGroup: true,
        isEnabled: ui.Tristate.isTrue,
      ),
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem role="radio" flt-tappable aria-checked="false"></sem>
''');

    semantics().semanticsEnabled = false;
  });

  test('renders a radio button group', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      role: ui.SemanticsRole.radioGroup,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 40),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(
          id: 1,
          flags: const ui.SemanticsFlags(
            isEnabled: ui.Tristate.isTrue,
            isChecked: ui.CheckedState.isFalse,
            isInMutuallyExclusiveGroup: true,
          ),
          rect: const ui.Rect.fromLTRB(0, 0, 100, 20),
        ),
        tester.updateNode(
          id: 2,
          flags: const ui.SemanticsFlags(
            isEnabled: ui.Tristate.isTrue,
            isChecked: ui.CheckedState.isTrue,
            isInMutuallyExclusiveGroup: true,
          ),
          rect: const ui.Rect.fromLTRB(0, 20, 100, 40),
        ),
      ],
    );
    tester.apply();

    expectSemanticsTree(owner(), '''
<sem role="radiogroup">
    <sem aria-checked="false"></sem>
    <sem aria-checked="true"></sem>
</sem>
''');

    semantics().semanticsEnabled = false;
  });

  test('sends focus events', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    void pumpSemantics({required ui.Tristate isFocused}) {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,

        // The following combination of actions and flags describe a checkbox.
        hasTap: true,
        flags: ui.SemanticsFlags(
          isEnabled: ui.Tristate.isTrue,
          isChecked: ui.CheckedState.isFalse,

          isFocused: isFocused,
        ),
        value: 'd',
        transform: Matrix4.identity().toFloat64(),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
    }

    final capturedActions = <CapturedAction>[];
    EnginePlatformDispatcher.instance.onSemanticsActionEvent = (ui.SemanticsActionEvent event) {
      capturedActions.add((event.nodeId, event.type, event.arguments));
    };

    pumpSemantics(isFocused: ui.Tristate.isFalse);
    final DomElement element = owner().debugSemanticsTree![0]!.element;
    expect(capturedActions, isEmpty);

    pumpSemantics(isFocused: ui.Tristate.isTrue);
    expect(
      reason: 'Framework requested focus. No need to circle the event back to the framework.',
      capturedActions,
      isEmpty,
    );
    capturedActions.clear();

    // The web doesn't send didLoseAccessibilityFocus as on the web,
    // accessibility focus is not observable, only input focus is. As of this
    // writing, there is no SemanticsAction.unfocus action, so the test simply
    // asserts that no actions are being sent as a result of blur.
    element.blur();
    expect(capturedActions, isEmpty);

    element.focusWithoutScroll();
    expect(
      reason: 'Browser-initiated focus even should be communicated to the framework.',
      capturedActions,
      <CapturedAction>[(0, ui.SemanticsAction.focus, null)],
    );
    capturedActions.clear();

    semantics().semanticsEnabled = false;
  });
}

void _testSelectables() {
  test('renders and updates non-selectable, selected, and unselected nodes', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 60),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(
          id: 1,
          flags: ui.SemanticsFlags.none,
          rect: const ui.Rect.fromLTRB(0, 0, 100, 20),
        ),
        tester.updateNode(
          id: 2,
          flags: const ui.SemanticsFlags(isSelected: ui.Tristate.isFalse),
          role: ui.SemanticsRole.row,
          rect: const ui.Rect.fromLTRB(0, 20, 100, 40),
        ),
        tester.updateNode(
          id: 3,
          flags: const ui.SemanticsFlags(isSelected: ui.Tristate.isTrue),
          role: ui.SemanticsRole.tab,
          rect: const ui.Rect.fromLTRB(0, 40, 100, 60),
        ),
        // Add two new nodes to test the aria-current fallback
        tester.updateNode(
          id: 4,
          flags: const ui.SemanticsFlags(isSelected: ui.Tristate.isFalse),
          rect: const ui.Rect.fromLTRB(0, 60, 100, 80),
        ),
        tester.updateNode(
          id: 5,
          flags: const ui.SemanticsFlags(isSelected: ui.Tristate.isTrue),
          rect: const ui.Rect.fromLTRB(0, 80, 100, 100),
        ),
      ],
    );
    tester.apply();

    expectSemanticsTree(owner(), '''
<sem>
    <sem></sem>
    <sem role="row" aria-selected="false"></sem>
    <sem role="tab" aria-selected="true"></sem>
    <sem aria-current="false"></sem>
    <sem aria-current="true"></sem>
</sem>
''');

    // Missing attributes cannot be expressed using HTML patterns, so check directly.
    final DomElement nonSelectable = owner().debugSemanticsTree![0]!.element;
    expect(nonSelectable.getAttribute('aria-selected'), isNull);
    expect(nonSelectable.getAttribute('aria-current'), isNull);

    // Flip the values and check that that ARIA attribute is updated.
    tester.updateNode(
      id: 2,
      flags: const ui.SemanticsFlags(isSelected: ui.Tristate.isTrue),
      role: ui.SemanticsRole.row,
      rect: const ui.Rect.fromLTRB(0, 20, 100, 40),
    );
    tester.updateNode(
      id: 3,
      flags: const ui.SemanticsFlags(isSelected: ui.Tristate.isFalse),
      role: ui.SemanticsRole.tab,
      rect: const ui.Rect.fromLTRB(0, 40, 100, 60),
    );
    // Flip the values for the aria-current fallback nodes
    tester.updateNode(
      id: 4,
      flags: const ui.SemanticsFlags(isSelected: ui.Tristate.isTrue),
      rect: const ui.Rect.fromLTRB(0, 60, 100, 80),
    );
    tester.updateNode(
      id: 5,
      flags: const ui.SemanticsFlags(isSelected: ui.Tristate.isFalse),
      rect: const ui.Rect.fromLTRB(0, 80, 100, 100),
    );
    tester.apply();

    expectSemanticsTree(owner(), '''
<sem>
    <sem></sem>
    <sem role="row" aria-selected="true"></sem>
    <sem role="tab" aria-selected="false"></sem>
    <sem aria-current="true"></sem>
    <sem aria-current="false"></sem>
</sem>
''');

    semantics().semanticsEnabled = false;
  });

  test('Checkable takes precedence over selectable', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      flags: const ui.SemanticsFlags(
        isSelected: ui.Tristate.isTrue,
        isChecked: ui.CheckedState.isTrue,
      ),
      hasTap: true,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 60),
    );
    tester.apply();

    expectSemanticsTree(owner(), '<sem flt-tappable role="checkbox" aria-checked="true"></sem>');

    final SemanticsObject node = owner().debugSemanticsTree![0]!;
    expect(node.semanticRole!.kind, EngineSemanticsRole.checkable);
    expect(node.semanticRole!.debugSemanticBehaviorTypes, isNot(contains(Selectable)));
    expect(node.element.getAttribute('aria-selected'), isNull);

    semantics().semanticsEnabled = false;
  });
}

void _testExpandables() {
  test('renders and updates non-expandable, expanded, and unexpanded nodes', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 60),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(
          id: 1,

          flags: ui.SemanticsFlags.none,
          rect: const ui.Rect.fromLTRB(0, 0, 100, 20),
        ),
        tester.updateNode(
          id: 2,
          flags: const ui.SemanticsFlags(isExpanded: ui.Tristate.isFalse),
          rect: const ui.Rect.fromLTRB(0, 20, 100, 40),
        ),
        tester.updateNode(
          id: 3,
          flags: const ui.SemanticsFlags(isExpanded: ui.Tristate.isTrue),
          rect: const ui.Rect.fromLTRB(0, 40, 100, 60),
        ),
      ],
    );
    tester.apply();

    expectSemanticsTree(owner(), '''
<sem>
    <sem></sem>
    <sem aria-expanded="false"></sem>
    <sem aria-expanded="true"></sem>
</sem>
''');

    // Missing attributes cannot be expressed using HTML patterns, so check directly.
    final DomElement nonExpandable = owner().debugSemanticsTree![1]!.element;
    expect(nonExpandable.getAttribute('aria-expanded'), isNull);

    // Flip the values and check that that ARIA attribute is updated.
    tester.updateNode(
      id: 2,
      flags: const ui.SemanticsFlags(isExpanded: ui.Tristate.isTrue),
      rect: const ui.Rect.fromLTRB(0, 20, 100, 40),
    );
    tester.updateNode(
      id: 3,
      flags: const ui.SemanticsFlags(isExpanded: ui.Tristate.isFalse),
      rect: const ui.Rect.fromLTRB(0, 40, 100, 60),
    );
    tester.apply();

    expectSemanticsTree(owner(), '''
<sem>
    <sem></sem>
    <sem aria-expanded="true"></sem>
    <sem aria-expanded="false"></sem>
</sem>
''');

    semantics().semanticsEnabled = false;
  });
}

void _testTappable() {
  test('renders an enabled button', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      flags: const ui.SemanticsFlags(
        isFocused: ui.Tristate.isFalse,
        isEnabled: ui.Tristate.isTrue,
        isButton: true,
      ),
      hasTap: true,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );
    tester.apply();

    expectSemanticsTree(owner(), '''
<sem role="button" flt-tappable></sem>
''');

    final SemanticsObject node = owner().debugSemanticsTree![0]!;
    expect(node.semanticRole?.kind, EngineSemanticsRole.button);
    expect(node.semanticRole?.debugSemanticBehaviorTypes, containsAll(<Type>[Focusable, Tappable]));
    expect(tester.getSemanticsObject(0).element.tabIndex, 0);

    semantics().semanticsEnabled = false;
  });

  test('renders a disabled button', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      flags: const ui.SemanticsFlags(
        isFocused: ui.Tristate.isFalse,
        isEnabled: ui.Tristate.isFalse,
        isButton: true,
      ),
      hasTap: true,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );
    tester.apply();

    expectSemanticsTree(owner(), '''
<sem role="button" aria-disabled="true"></sem>
''');

    semantics().semanticsEnabled = false;
  });

  test('tappable leaf node is a button', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      // Not a button
      flags: const ui.SemanticsFlags(isFocused: ui.Tristate.isFalse, isEnabled: ui.Tristate.isTrue),

      // But has a tap action and no children
      hasTap: true,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );
    tester.apply();

    expectSemanticsTree(owner(), '''
<sem role="button" flt-tappable></sem>
''');

    final SemanticsObject node = owner().debugSemanticsTree![0]!;
    expect(node.semanticRole?.kind, EngineSemanticsRole.button);
    expect(node.semanticRole?.debugSemanticBehaviorTypes, containsAll(<Type>[Focusable, Tappable]));
    expect(tester.getSemanticsObject(0).element.tabIndex, 0);

    semantics().semanticsEnabled = false;
  });

  test('can switch a button between enabled and disabled', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    void updateTappable({required bool enabled}) {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        flags: ui.SemanticsFlags(
          isEnabled: enabled ? ui.Tristate.isTrue : ui.Tristate.isFalse,
          isButton: true,
        ),
        hasTap: true,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
    }

    updateTappable(enabled: false);
    expectSemanticsTree(owner(), '<sem role="button" aria-disabled="true"></sem>');

    updateTappable(enabled: true);
    expectSemanticsTree(owner(), '<sem role="button" flt-tappable></sem>');

    updateTappable(enabled: false);
    expectSemanticsTree(owner(), '<sem role="button" aria-disabled="true"></sem>');

    updateTappable(enabled: true);
    expectSemanticsTree(owner(), '<sem role="button" flt-tappable></sem>');

    semantics().semanticsEnabled = false;
  });

  test('focuses on a button after element has been attached', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      flags: const ui.SemanticsFlags(
        isEnabled: ui.Tristate.isTrue,
        isButton: true,
        isFocused: ui.Tristate.isTrue,
      ),
      hasTap: true,
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

    void pumpSemantics({required ui.Tristate isFocused}) {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        flags: ui.SemanticsFlags(
          // The following combination of actions and flags describe a button.
          isEnabled: ui.Tristate.isTrue,
          isButton: true,
          isFocused: isFocused,
        ),
        hasTap: true,
        value: 'd',
        transform: Matrix4.identity().toFloat64(),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
    }

    final capturedActions = <CapturedAction>[];
    EnginePlatformDispatcher.instance.onSemanticsActionEvent = (ui.SemanticsActionEvent event) {
      capturedActions.add((event.nodeId, event.type, event.arguments));
    };

    pumpSemantics(isFocused: ui.Tristate.isFalse);
    final DomElement element = owner().debugSemanticsTree![0]!.element;
    expect(capturedActions, isEmpty);

    pumpSemantics(isFocused: ui.Tristate.isTrue);
    expect(
      reason: 'Framework requested focus. No need to circle the event back to the framework.',
      capturedActions,
      isEmpty,
    );
    expect(domDocument.activeElement, element);
    capturedActions.clear();

    // The web doesn't send didLoseAccessibilityFocus as on the web,
    // accessibility focus is not observable, only input focus is. As of this
    // writing, there is no SemanticsAction.unfocus action, so the test simply
    // asserts that no actions are being sent as a result of blur.
    element.blur();
    expect(capturedActions, isEmpty);

    element.focusWithoutScroll();
    expect(
      reason: 'Browser-initiated focus even should be communicated to the framework.',
      capturedActions,
      <CapturedAction>[(0, ui.SemanticsAction.focus, null)],
    );
    capturedActions.clear();

    pumpSemantics(isFocused: ui.Tristate.isFalse);
    expect(capturedActions, isEmpty);

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

    final capturedActions = <CapturedAction>[];
    EnginePlatformDispatcher.instance.onSemanticsActionEvent = (ui.SemanticsActionEvent event) {
      capturedActions.add((event.nodeId, event.type, event.arguments));
    };

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      flags: const ui.SemanticsFlags(
        isFocused: ui.Tristate.isFalse,
        isEnabled: ui.Tristate.isTrue,
        isButton: true,
      ),
      hasTap: true,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(
          id: 1,
          flags: const ui.SemanticsFlags(
            isFocused: ui.Tristate.isFalse,
            isEnabled: ui.Tristate.isTrue,
            isButton: true,
          ),
          hasTap: true,
          rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
        ),
      ],
    );
    tester.apply();

    expectSemanticsTree(owner(), '''
<sem flt-tappable role="button">
    <sem flt-tappable role="button"></sem>
</sem>
''');

    // Tap on the outer element
    {
      final DomElement element = tester.getSemanticsObject(0).element;
      final DomRect rect = element.getBoundingClientRect();

      element.dispatchEvent(
        createDomMouseEvent('click', <Object?, Object?>{
          'clientX': (rect.left + (rect.right - rect.left) / 2).floor(),
          'clientY': (rect.top + (rect.bottom - rect.top) / 2).floor(),
        }),
      );

      expect(capturedActions, <CapturedAction>[
        (0, ui.SemanticsAction.focus, null),
        (0, ui.SemanticsAction.tap, null),
      ]);
    }

    // Tap on the inner element
    {
      capturedActions.clear();
      final DomElement element = tester.getSemanticsObject(1).element;
      final DomRect rect = element.getBoundingClientRect();

      element.dispatchEvent(
        createDomMouseEvent('click', <Object?, Object?>{
          'bubbles': true,
          'clientX': (rect.left + (rect.right - rect.left) / 2).floor(),
          'clientY': (rect.top + (rect.bottom - rect.top) / 2).floor(),
        }),
      );

      // The click on the inner element should not propagate to the parent to
      // avoid sending a second SemanticsAction.tap action to the framework.
      expect(capturedActions, <CapturedAction>[
        (1, ui.SemanticsAction.focus, null),
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

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      flags: const ui.SemanticsFlags(isImage: true),
      label: 'Test Image Label',
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem role="img" aria-label="Test Image Label"></sem>
''');

    semantics().semanticsEnabled = false;
  });

  test('renders an image with a child node and with a label', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      flags: const ui.SemanticsFlags(isImage: true),
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

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem>
  <sem-img role="img" aria-label="Test Image Label"></sem-img>
    <sem></sem>
</sem>''');

    semantics().semanticsEnabled = false;
  });

  test('renders an image with no child nodes without a label', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      flags: const ui.SemanticsFlags(isImage: true),
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '<sem role="img"></sem>');

    semantics().semanticsEnabled = false;
  });

  test('renders an image with a child node and without a label', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      flags: const ui.SemanticsFlags(isImage: true),
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

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem>
  <sem-img role="img"></sem-img>
    <sem></sem>
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
    throw UnsupportedError('ariaLiveElementFor is not supported in MockAccessibilityAnnouncements');
  }

  @override
  void handleMessage(StandardMessageCodec codec, ByteData? data) {
    throw UnsupportedError('handleMessage is not supported in MockAccessibilityAnnouncements!');
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

    final mockAccessibilityAnnouncements = MockAccessibilityAnnouncements();
    LiveRegion.debugOverrideAccessibilityAnnouncements(mockAccessibilityAnnouncements);

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      label: 'This is a snackbar',
      flags: const ui.SemanticsFlags(isLiveRegion: true),

      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );
    owner().updateSemantics(builder.build());
    expect(mockAccessibilityAnnouncements.announceInvoked, 1);

    semantics().semanticsEnabled = false;
  });

  test('does not announce anything if there is no label', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final mockAccessibilityAnnouncements = MockAccessibilityAnnouncements();
    LiveRegion.debugOverrideAccessibilityAnnouncements(mockAccessibilityAnnouncements);

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      flags: const ui.SemanticsFlags(isLiveRegion: true),
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );
    owner().updateSemantics(builder.build());
    expect(mockAccessibilityAnnouncements.announceInvoked, 0);

    semantics().semanticsEnabled = false;
  });

  test('does not announce the same label over and over', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final mockAccessibilityAnnouncements = MockAccessibilityAnnouncements();
    LiveRegion.debugOverrideAccessibilityAnnouncements(mockAccessibilityAnnouncements);

    var builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      label: 'This is a snackbar',
      flags: const ui.SemanticsFlags(isLiveRegion: true),
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );
    owner().updateSemantics(builder.build());
    expect(mockAccessibilityAnnouncements.announceInvoked, 1);

    builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      label: 'This is a snackbar',
      flags: const ui.SemanticsFlags(isLiveRegion: true),
      transform: Matrix4.identity().toFloat64(),
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );
    owner().updateSemantics(builder.build());
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
      final builder = ui.SemanticsUpdateBuilder();
      updateNode(builder, platformViewId: 5, rect: const ui.Rect.fromLTRB(0, 0, 100, 50));
      owner().updateSemantics(builder.build());
      expectSemanticsTree(owner(), '<sem aria-owns="flt-pv-5"></sem>');
    }

    // Update.
    {
      final builder = ui.SemanticsUpdateBuilder();
      updateNode(builder, platformViewId: 42, rect: const ui.Rect.fromLTRB(0, 0, 100, 50));
      owner().updateSemantics(builder.build());
      expectSemanticsTree(owner(), '<sem aria-owns="flt-pv-42"></sem>');
    }

    semantics().semanticsEnabled = false;
  });

  test('is transparent w.r.t. hit testing', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(builder, platformViewId: 5, rect: const ui.Rect.fromLTRB(0, 0, 100, 50));
    owner().updateSemantics(builder.build());

    expectSemanticsTree(owner(), '<sem aria-owns="flt-pv-5"></sem>');
    final DomElement element = owner().semanticsHost.querySelector('flt-semantics')!;
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

    final sceneBuilder = ui.SceneBuilder();
    sceneBuilder.addPlatformView(0, offset: const ui.Offset(0, 15), width: 20, height: 30);
    await renderScene(sceneBuilder.build());

    final builder = ui.SemanticsUpdateBuilder();
    final double dpr = EngineFlutterDisplay.instance.devicePixelRatio;
    updateNode(
      builder,
      rect: const ui.Rect.fromLTRB(0, 0, 20, 60),
      childrenInTraversalOrder: Int32List.fromList(<int>[1, 2, 3]),
      childrenInHitTestOrder: Int32List.fromList(<int>[1, 2, 3]),
      transform: Float64List.fromList(Matrix4.diagonal3Values(dpr, dpr, 1).storage),
    );
    updateNode(
      builder,
      id: 1,
      actions: ui.SemanticsAction.tap.index,
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
      actions: ui.SemanticsAction.tap.index,
      rect: const ui.Rect.fromLTRB(0, 35, 20, 60),
    );

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem>
    <sem style="z-index: 3"></sem>
    <sem style="z-index: 2" aria-owns="flt-pv-0"></sem>
    <sem style="z-index: 1"></sem>
</sem>''');

    final DomElement root = owner().semanticsHost.querySelector('#${kFlutterSemanticNodePrefix}0')!;
    expect(root.style.pointerEvents, 'none');

    final DomElement child1 = owner().semanticsHost.querySelector(
      '#${kFlutterSemanticNodePrefix}1',
    )!;
    expect(
      child1.style.pointerEvents,
      'all',
      reason: 'Tappable nodes should accept pointer events',
    );
    final DomRect child1Rect = child1.getBoundingClientRect();
    expect(child1Rect.left, 0);
    expect(child1Rect.top, 0);
    expect(child1Rect.right, 20);
    expect(child1Rect.bottom, 25);

    final DomElement child2 = owner().semanticsHost.querySelector(
      '#${kFlutterSemanticNodePrefix}2',
    )!;
    expect(child2.style.pointerEvents, 'none');
    final DomRect child2Rect = child2.getBoundingClientRect();
    expect(child2Rect.left, 0);
    expect(child2Rect.top, 15);
    expect(child2Rect.right, 20);
    expect(child2Rect.bottom, 45);

    final DomElement child3 = owner().semanticsHost.querySelector(
      '#${kFlutterSemanticNodePrefix}3',
    )!;
    expect(
      child3.style.pointerEvents,
      'all',
      reason: 'Tappable nodes should accept pointer events',
    );
    final DomRect child3Rect = child3.getBoundingClientRect();
    expect(child3Rect.left, 0);
    expect(child3Rect.top, 35);
    expect(child3Rect.right, 20);
    expect(child3Rect.bottom, 60);

    final DomElement platformViewElement = platformViewsHost.querySelector('#view-0')!;
    final DomRect platformViewRect = platformViewElement.getBoundingClientRect();
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

  test('removes aria-owns when platform view is hidden', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    // Create a platform view that is visible (has aria-owns).
    {
      final builder = ui.SemanticsUpdateBuilder();
      updateNode(builder, platformViewId: 5, rect: const ui.Rect.fromLTRB(0, 0, 100, 50));
      owner().updateSemantics(builder.build());
      expectSemanticsTree(owner(), '<sem aria-owns="flt-pv-5"></sem>');
    }

    // Hide the platform view (should remove aria-owns).
    {
      final builder = ui.SemanticsUpdateBuilder();
      updateNode(
        builder,
        platformViewId: 5,
        flags: const ui.SemanticsFlags(isHidden: true),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      owner().updateSemantics(builder.build());
      expectSemanticsTree(owner(), '<sem></sem>');
    }

    // Show the platform view again (should restore aria-owns).
    {
      final builder = ui.SemanticsUpdateBuilder();
      updateNode(builder, platformViewId: 5, rect: const ui.Rect.fromLTRB(0, 0, 100, 50));
      owner().updateSemantics(builder.build());
      expectSemanticsTree(owner(), '<sem aria-owns="flt-pv-5"></sem>');
    }

    semantics().semanticsEnabled = false;
  });
}

void _testGroup() {
  test('nodes with children and labels use group role with aria label', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
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

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
<sem role="group" aria-label="this is a label for a group of elements"><sem></sem></sem>
''');

    semantics().semanticsEnabled = false;
  });
}

void _testRoute() {
  test('renders named and labeled routes', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      label: 'this is a route label',
      flags: const ui.SemanticsFlags(scopesRoute: true, namesRoute: true),

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

    owner().updateSemantics(builder.build());
    expectSemanticsTree(owner(), '''
      <sem aria-label="this is a route label"><sem></sem></sem>
    ''');

    expect(owner().debugSemanticsTree![0]!.semanticRole?.kind, EngineSemanticsRole.route);

    semantics().semanticsEnabled = false;
  });

  test('warns about missing label', () {
    final warnings = <String>[];
    printWarning = warnings.add;

    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final builder = ui.SemanticsUpdateBuilder();
    updateNode(
      builder,
      flags: const ui.SemanticsFlags(scopesRoute: true, namesRoute: true),
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

    owner().updateSemantics(builder.build());
    expect(warnings, <String>[
      'Semantic node 0 had both scopesRoute and namesRoute set, indicating a self-labelled route, but it is missing the label. A route should be labelled either by setting namesRoute on itself and providing a label, or by containing a child node with namesRoute that can describe it with its content.',
    ]);

    expectSemanticsTree(owner(), '''
      <sem aria-label=""><sem></sem></sem>
    ''');

    expect(owner().debugSemanticsTree![0]!.semanticRole?.kind, EngineSemanticsRole.route);

    semantics().semanticsEnabled = false;
  });

  test('route can be described by a descendant', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    void pumpSemantics({required String label}) {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        flags: const ui.SemanticsFlags(scopesRoute: true),
        transform: Matrix4.identity().toFloat64(),
        children: <SemanticsNodeUpdate>[
          tester.updateNode(
            id: 1,
            children: <SemanticsNodeUpdate>[
              tester.updateNode(
                id: 2,
                flags: const ui.SemanticsFlags(namesRoute: true),
                label: label,
              ),
            ],
          ),
        ],
      );
      tester.apply();

      expectSemanticsTree(owner(), '''
        <sem aria-describedby="flt-semantic-node-2">
            <sem>
                <sem><span>$label</span></sem>
            </sem>
        </sem>
      ''');
    }

    pumpSemantics(label: 'Route label');

    expect(owner().debugSemanticsTree![0]!.semanticRole?.kind, EngineSemanticsRole.route);
    expect(owner().debugSemanticsTree![2]!.semanticRole?.kind, EngineSemanticsRole.generic);
    expect(
      owner().debugSemanticsTree![2]!.semanticRole?.debugSemanticBehaviorTypes,
      contains(RouteName),
    );

    pumpSemantics(label: 'Updated route label');

    semantics().semanticsEnabled = false;
  });

  test('scopesRoute alone sets the SemanticRoute role and with no label', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      flags: const ui.SemanticsFlags(scopesRoute: true),
      transform: Matrix4.identity().toFloat64(),
    );
    tester.apply();

    expectSemanticsTree(owner(), '''
      <sem></sem>
    ''');

    expect(owner().debugSemanticsTree![0]!.semanticRole?.kind, EngineSemanticsRole.route);
    expect(owner().debugSemanticsTree![0]!.semanticRole?.behaviors, isNot(contains(RouteName)));

    semantics().semanticsEnabled = false;
  });

  test('namesRoute alone has no effect', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      transform: Matrix4.identity().toFloat64(),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(
          id: 1,
          children: <SemanticsNodeUpdate>[
            tester.updateNode(
              id: 2,
              flags: const ui.SemanticsFlags(namesRoute: true),
              label: 'Hello',
            ),
          ],
        ),
      ],
    );
    tester.apply();

    expectSemanticsTree(owner(), '''
      <sem>
          <sem>
              <sem><span>Hello</span></sem>
          </sem>
      </sem>
    ''');

    expect(owner().debugSemanticsTree![0]!.semanticRole?.kind, EngineSemanticsRole.generic);
    expect(
      owner().debugSemanticsTree![2]!.semanticRole?.debugSemanticBehaviorTypes,
      contains(RouteName),
    );

    semantics().semanticsEnabled = false;
  });

  // Test the simple scenario of a route coming up and containing focusable
  // descendants that are not initially focused. The expectation is that the
  // first descendant will be auto-focused.
  test('focuses on the first unfocused Focusable', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final capturedActions = <CapturedAction>[];
    EnginePlatformDispatcher.instance.onSemanticsActionEvent = (ui.SemanticsActionEvent event) {
      capturedActions.add((event.nodeId, event.type, event.arguments));
    };

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      flags: const ui.SemanticsFlags(scopesRoute: true),
      transform: Matrix4.identity().toFloat64(),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(
          id: 1,
          // None of the children should have isFocused set to `true` to make
          // sure that the auto-focus logic kicks in.
          children: <SemanticsNodeUpdate>[
            tester.updateNode(
              id: 2,
              label: 'Button 1',
              flags: const ui.SemanticsFlags(
                isEnabled: ui.Tristate.isTrue,
                isButton: true,
                isFocused: ui.Tristate.isFalse,
              ),
              hasTap: true,
              rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
            ),
            tester.updateNode(
              id: 3,
              label: 'Button 2',
              flags: const ui.SemanticsFlags(
                isEnabled: ui.Tristate.isTrue,
                isButton: true,
                isFocused: ui.Tristate.isFalse,
              ),
              hasTap: true,
              rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
            ),
          ],
        ),
      ],
    );
    tester.apply();

    // Auto-focus does not notify the framework about the focused widget.
    expect(capturedActions, isEmpty);

    semantics().semanticsEnabled = false;
  });

  // Test the scenario of a route coming up and containing focusable
  // descendants with one of them explicitly requesting focus. The expectation
  // is that the route will not attempt to auto-focus on anything and let the
  // respective descendant take focus.
  test('does nothing if a descendant asks for focus explicitly', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final capturedActions = <CapturedAction>[];
    EnginePlatformDispatcher.instance.onSemanticsActionEvent = (ui.SemanticsActionEvent event) {
      capturedActions.add((event.nodeId, event.type, event.arguments));
    };

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      flags: const ui.SemanticsFlags(scopesRoute: true),
      transform: Matrix4.identity().toFloat64(),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(
          id: 1,
          children: <SemanticsNodeUpdate>[
            tester.updateNode(
              id: 2,
              label: 'Button 1',
              flags: const ui.SemanticsFlags(
                isEnabled: ui.Tristate.isTrue,
                isButton: true,
                isFocused: ui.Tristate.isFalse,
              ),
              hasTap: true,
              rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
            ),
            tester.updateNode(
              id: 3,
              label: 'Button 2',
              flags: const ui.SemanticsFlags(
                isEnabled: ui.Tristate.isTrue,
                isButton: true,
                // Asked for focus explicitly.
                isFocused: ui.Tristate.isTrue,
              ),
              hasTap: true,
              rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
            ),
          ],
        ),
      ],
    );
    tester.apply();

    // Auto-focus does not notify the framework about the focused widget.
    expect(capturedActions, isEmpty);

    semantics().semanticsEnabled = false;
  });

  // Test the scenario of a route coming up and containing non-focusable
  // descendants that can have a11y focus. The expectation is that the first
  // descendant will be auto-focused, even if it's not input-focusable.
  test('focuses on the first non-focusable descedant', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final capturedActions = <CapturedAction>[];
    EnginePlatformDispatcher.instance.onSemanticsActionEvent = (ui.SemanticsActionEvent event) {
      capturedActions.add((event.nodeId, event.type, event.arguments));
    };

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      flags: const ui.SemanticsFlags(scopesRoute: true),
      transform: Matrix4.identity().toFloat64(),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(
          id: 1,
          children: <SemanticsNodeUpdate>[
            tester.updateNode(id: 2, label: 'Heading', rect: const ui.Rect.fromLTRB(0, 0, 100, 50)),
            tester.updateNode(
              id: 3,
              label: 'Click me!',
              flags: const ui.SemanticsFlags(
                isEnabled: ui.Tristate.isTrue,
                isButton: true,
                isFocused: ui.Tristate.isFalse,
              ),
              hasTap: true,
              rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
            ),
          ],
        ),
      ],
    );
    tester.apply();

    // The focused node is not focusable, so no notification is sent to the
    // framework.
    expect(capturedActions, isEmpty);

    // However, the element should have gotten the focus.

    tester.expectSemantics('''
<flt-semantics>
    <flt-semantics>
        <flt-semantics id="flt-semantic-node-2">
          <span tabindex="-1">Heading</span>
        </flt-semantics>
        <flt-semantics role="button" tabindex="0" flt-tappable="">Click me!</flt-semantics>
    </flt-semantics>
</flt-semantics>''');

    final DomElement span = owner().debugSemanticsTree![2]!.element.querySelectorAll('span').single;
    expect(span.tabIndex, -1);
    expect(domDocument.activeElement, span);

    semantics().semanticsEnabled = false;
  });

  // This mostly makes sure the engine doesn't crash if given a completely empty
  // route trying to find something to focus on.
  test('does nothing if nothing is focusable inside the route', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final capturedActions = <CapturedAction>[];
    EnginePlatformDispatcher.instance.onSemanticsActionEvent = (ui.SemanticsActionEvent event) {
      capturedActions.add((event.nodeId, event.type, event.arguments));
    };

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      flags: const ui.SemanticsFlags(scopesRoute: true),
      transform: Matrix4.identity().toFloat64(),
    );
    tester.apply();

    expect(capturedActions, isEmpty);
    expect(domDocument.activeElement, flutterViewRoot);

    semantics().semanticsEnabled = false;
  });
}

void _testDialogs() {
  test('nodes with dialog role', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.dialog,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.semanticRole?.kind, EngineSemanticsRole.dialog);
    expect(object.element.getAttribute('role'), 'dialog');
  });

  test('nodes with alertdialog role', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.alertDialog,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.semanticRole?.kind, EngineSemanticsRole.alertDialog);
    expect(object.element.getAttribute('role'), 'alertdialog');
  });

  test('dialog can be described by a descendant', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    void pumpSemantics({required String label}) {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.dialog,
        transform: Matrix4.identity().toFloat64(),
        children: <SemanticsNodeUpdate>[
          tester.updateNode(
            id: 1,
            children: <SemanticsNodeUpdate>[
              tester.updateNode(
                id: 2,
                flags: const ui.SemanticsFlags(namesRoute: true),
                label: label,
              ),
            ],
          ),
        ],
      );
      tester.apply();

      expectSemanticsTree(owner(), '''
        <sem role="dialog" aria-describedby="flt-semantic-node-2">
            <sem>
                <sem><span>$label</span></sem>
            </sem>
        </sem>
      ''');
    }

    pumpSemantics(label: 'Route label');

    expect(owner().debugSemanticsTree![0]!.semanticRole?.kind, EngineSemanticsRole.dialog);
    expect(owner().debugSemanticsTree![2]!.semanticRole?.kind, EngineSemanticsRole.generic);
    expect(
      owner().debugSemanticsTree![2]!.semanticRole?.debugSemanticBehaviorTypes,
      contains(RouteName),
    );

    pumpSemantics(label: 'Updated route label');

    semantics().semanticsEnabled = false;
  });
}

typedef CapturedAction = (int nodeId, ui.SemanticsAction action, Object? args);

void _testFocusable() {
  test('AccessibilityFocusManager can manage element focus', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    void pumpSemantics() {
      final builder = ui.SemanticsUpdateBuilder();
      updateNode(
        builder,
        label: 'Dummy root element',
        transform: Matrix4.identity().toFloat64(),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
        childrenInHitTestOrder: Int32List.fromList(<int>[]),
        childrenInTraversalOrder: Int32List.fromList(<int>[]),
      );
      owner().updateSemantics(builder.build());
    }

    final capturedActions = <CapturedAction>[];
    EnginePlatformDispatcher.instance.onSemanticsActionEvent = (ui.SemanticsActionEvent event) {
      capturedActions.add((event.nodeId, event.type, event.arguments));
    };
    expect(capturedActions, isEmpty);

    final manager = AccessibilityFocusManager(owner());
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
    expect(capturedActions, isEmpty);

    // Give up focus
    manager.changeFocus(false);
    pumpSemantics(); // triggers post-update callbacks
    expect(capturedActions, isEmpty);
    expect(domDocument.activeElement, element);

    // Browser blurs the element
    element.blur();
    expect(domDocument.activeElement, isNot(element));
    // The web doesn't send didLoseAccessibilityFocus as on the web,
    // accessibility focus is not observable, only input focus is. As of this
    // writing, there is no SemanticsAction.unfocus action, so the test simply
    // asserts that no actions are being sent as a result of blur.
    expect(capturedActions, isEmpty);

    // Request focus again
    manager.changeFocus(true);
    pumpSemantics(); // triggers post-update callbacks
    expect(domDocument.activeElement, element);
    expect(capturedActions, isEmpty);

    // Double-request focus
    manager.changeFocus(true);
    pumpSemantics(); // triggers post-update callbacks
    expect(domDocument.activeElement, element);
    expect(
      reason: 'Nothing should be sent to the framework on focus re-request.',
      capturedActions,
      isEmpty,
    );
    capturedActions.clear();

    // Blur and emulate browser requesting focus
    element.blur();
    expect(domDocument.activeElement, isNot(element));
    element.focusWithoutScroll();
    expect(domDocument.activeElement, element);
    expect(capturedActions, <CapturedAction>[(1, ui.SemanticsAction.focus, null)]);
    capturedActions.clear();

    // Stop managing
    manager.stopManaging();
    pumpSemantics(); // triggers post-update callbacks
    expect(
      reason:
          'There should be no notification to the framework because the '
          'framework should already know. Otherwise, it would not have '
          'asked to stop managing the node.',
      capturedActions,
      isEmpty,
    );
    expect(domDocument.activeElement, element);

    // Attempt to request focus when not managing an element.
    element.blur();
    manager.changeFocus(true);
    pumpSemantics(); // triggers post-update callbacks
    expect(
      reason:
          'Attempting to request focus on a node that is not managed should '
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
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        transform: Matrix4.identity().toFloat64(),
        children: <SemanticsNodeUpdate>[
          tester.updateNode(
            id: 1,
            label: 'focusable text',
            flags: const ui.SemanticsFlags(isFocused: ui.Tristate.isFalse),
            rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
          ),
        ],
      );
      tester.apply();
    }

    expectSemanticsTree(owner(), '''
<sem>
    <sem><span>focusable text</span></sem>
</sem>
''');

    final SemanticsObject node = owner().debugSemanticsTree![1]!;
    expect(node.isFocusable, isTrue);
    expect(node.semanticRole?.kind, EngineSemanticsRole.generic);
    expect(node.semanticRole?.debugSemanticBehaviorTypes, contains(Focusable));

    final DomElement element = node.element;
    expect(domDocument.activeElement, isNot(element));

    {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 1,
        label: 'test focusable',
        flags: const ui.SemanticsFlags(isFocused: ui.Tristate.isTrue),
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
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        flags: const ui.SemanticsFlags(isLink: true),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.element.tagName.toLowerCase(), 'a');
    expect(object.element.hasAttribute('href'), isFalse);
  });

  test('link nodes with linkUrl set the href attribute', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        flags: const ui.SemanticsFlags(isLink: true),
        linkUrl: 'https://flutter.dev',
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.element.tagName.toLowerCase(), 'a');
    expect(object.element.getAttribute('href'), 'https://flutter.dev');
  });

  test('a node that is both a link and a button is rendered as a link', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    const url = 'https://flutter.dev';
    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      linkUrl: url,
      flags: const ui.SemanticsFlags(isLink: true, isButton: true),
      label: 'link button label',
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );
    tester.apply();

    tester.expectSemantics('<a style="display: block;">link button label</a>');
    final SemanticsObject node = owner().debugSemanticsTree![0]!;
    expect(node.semanticRole?.kind, EngineSemanticsRole.link);
    expect(node.linkUrl, url);
    expect(
      node.semanticRole?.debugSemanticBehaviorTypes,
      containsAll(<Type>[Focusable, Tappable, LabelAndValue]),
    );

    semantics().semanticsEnabled = false;
  });
}

void _testTabs() {
  test('nodes with tab role', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.tab,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.semanticRole?.kind, EngineSemanticsRole.tab);
    expect(object.element.getAttribute('role'), 'tab');
  });

  test('tab with tap action', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      role: ui.SemanticsRole.tab,
      hasTap: true,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );
    tester.apply();

    final SemanticsObject object = tester.getSemanticsObject(0);
    expect(object.semanticRole?.kind, EngineSemanticsRole.tab);
    expect(object.element.getAttribute('role'), 'tab');
    expect(object.element.hasAttribute('flt-tappable'), isTrue);
  });

  test('nodes with tab panel role', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.tabPanel,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.semanticRole?.kind, EngineSemanticsRole.tabPanel);
    expect(object.element.getAttribute('role'), 'tabpanel');
  });

  test('nodes with tab bar role', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.tabBar,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.semanticRole?.kind, EngineSemanticsRole.tabList);
    expect(object.element.getAttribute('role'), 'tablist');
  });
}

void _testTables() {
  test('nodes with table role', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.table,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.semanticRole?.kind, EngineSemanticsRole.table);
    expect(object.element.getAttribute('role'), 'table');
  });

  test('nodes with cell role', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.cell,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.semanticRole?.kind, EngineSemanticsRole.cell);
    expect(object.element.getAttribute('role'), 'cell');
  });

  test('nodes with row role', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.row,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.semanticRole?.kind, EngineSemanticsRole.row);
    expect(object.element.getAttribute('role'), 'row');
  });

  test('nodes with column header  role', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.columnHeader,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.semanticRole?.kind, EngineSemanticsRole.columnHeader);
    expect(object.element.getAttribute('role'), 'columnheader');
  });

  test('table with text and button in cells ', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      flags: const ui.SemanticsFlags(scopesRoute: true),
      transform: Matrix4.identity().toFloat64(),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(
          id: 1,
          role: ui.SemanticsRole.table,
          rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
          children: <SemanticsNodeUpdate>[
            tester.updateNode(
              id: 2,
              role: ui.SemanticsRole.row,
              rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
              children: <SemanticsNodeUpdate>[
                tester.updateNode(
                  id: 3,
                  role: ui.SemanticsRole.cell,
                  label: 'hello world',
                  rect: const ui.Rect.fromLTRB(0, 0, 50, 50),
                ),
                tester.updateNode(
                  id: 4,
                  role: ui.SemanticsRole.cell,
                  rect: const ui.Rect.fromLTRB(50, 0, 100, 50),
                  children: <SemanticsNodeUpdate>[
                    tester.updateNode(
                      id: 5,
                      flags: const ui.SemanticsFlags(isButton: true),
                      label: 'Button',
                      rect: const ui.Rect.fromLTRB(0, 0, 50, 50),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    tester.apply();

    tester.expectSemantics('''
<sem id="flt-semantic-node-0">
    <sem id="flt-semantic-node-1" role="table">
        <sem id="flt-semantic-node-2" role="row">
            <sem id="flt-semantic-node-3" role="cell">
                <span>hello world</span>
            </sem>
            <sem id="flt-semantic-node-4" role="cell">
                <sem id="flt-semantic-node-5" role="button">Button</sem>
            </sem>
        </sem>
    </sem>
</sem>
''');
    final SemanticsObject object = tester.getSemanticsObject(1);
    expect(object.semanticRole?.kind, EngineSemanticsRole.table);
  });

  semantics().semanticsEnabled = false;
}

void _testMenus() {
  test('nodes with menu role', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.menu,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.semanticRole?.kind, EngineSemanticsRole.menu);
    expect(object.element.getAttribute('role'), 'menu');
  });

  test('menu can have non-immidiate menu item nodes', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      role: ui.SemanticsRole.menu,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(
          id: 1,
          rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
          children: <SemanticsNodeUpdate>[
            tester.updateNode(id: 2, role: ui.SemanticsRole.menuItem),
            tester.updateNode(id: 3, role: ui.SemanticsRole.menuItem),
            tester.updateNode(id: 4, role: ui.SemanticsRole.menuItem),
          ],
        ),
      ],
    );
    tester.apply();

    final SemanticsObject object = tester.getSemanticsObject(0);
    expect(
      object.element.getAttribute('aria-owns'),
      'flt-semantic-node-2 flt-semantic-node-3 flt-semantic-node-4',
    );
  });

  test('nested menus have correct menu item nodes', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      role: ui.SemanticsRole.menu,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(
          id: 1,
          rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
          children: <SemanticsNodeUpdate>[
            tester.updateNode(id: 2, role: ui.SemanticsRole.menuItem),
            tester.updateNode(id: 3, role: ui.SemanticsRole.menuItem),
            tester.updateNode(
              id: 4,
              role: ui.SemanticsRole.menuItem,
              flags: const ui.SemanticsFlags(isExpanded: ui.Tristate.isTrue),
              children: <SemanticsNodeUpdate>[
                tester.updateNode(
                  id: 5,
                  role: ui.SemanticsRole.menu,
                  children: <SemanticsNodeUpdate>[
                    tester.updateNode(
                      id: 6,
                      children: <SemanticsNodeUpdate>[
                        tester.updateNode(id: 7, role: ui.SemanticsRole.menuItem),
                        tester.updateNode(id: 8, role: ui.SemanticsRole.menuItem),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    tester.apply();

    final SemanticsObject object0 = tester.getSemanticsObject(0);
    expect(
      object0.element.getAttribute('aria-owns'),
      'flt-semantic-node-2 flt-semantic-node-3 flt-semantic-node-4',
    );
    final SemanticsObject object1 = tester.getSemanticsObject(5);
    expect(object1.element.getAttribute('aria-owns'), 'flt-semantic-node-7 flt-semantic-node-8');
  });

  test('menu bar can have non-immidiate menu item nodes', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      role: ui.SemanticsRole.menuBar,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(
          id: 1,
          rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
          children: <SemanticsNodeUpdate>[
            tester.updateNode(id: 2, role: ui.SemanticsRole.menuItem),
            tester.updateNode(id: 3, role: ui.SemanticsRole.menuItem),
            tester.updateNode(id: 4, role: ui.SemanticsRole.menuItem),
          ],
        ),
      ],
    );
    tester.apply();

    final SemanticsObject object = tester.getSemanticsObject(0);
    expect(
      object.element.getAttribute('aria-owns'),
      'flt-semantic-node-2 flt-semantic-node-3 flt-semantic-node-4',
    );
  });

  test('menu bar and its submenu have correct menu item nodes', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      role: ui.SemanticsRole.menuBar,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(
          id: 1,
          rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
          children: <SemanticsNodeUpdate>[
            tester.updateNode(id: 2, role: ui.SemanticsRole.menuItem),
            tester.updateNode(id: 3, role: ui.SemanticsRole.menuItem),
            tester.updateNode(
              id: 4,
              role: ui.SemanticsRole.menuItem,
              flags: const ui.SemanticsFlags(isExpanded: ui.Tristate.isTrue),
              children: <SemanticsNodeUpdate>[
                tester.updateNode(
                  id: 5,
                  role: ui.SemanticsRole.menu,
                  children: <SemanticsNodeUpdate>[
                    tester.updateNode(
                      id: 6,
                      children: <SemanticsNodeUpdate>[
                        tester.updateNode(id: 7, role: ui.SemanticsRole.menuItem),
                        tester.updateNode(id: 8, role: ui.SemanticsRole.menuItem),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    tester.apply();

    final SemanticsObject object0 = tester.getSemanticsObject(0);
    expect(
      object0.element.getAttribute('aria-owns'),
      'flt-semantic-node-2 flt-semantic-node-3 flt-semantic-node-4',
    );
    final SemanticsObject object1 = tester.getSemanticsObject(5);
    expect(object1.element.getAttribute('aria-owns'), 'flt-semantic-node-7 flt-semantic-node-8');
  });

  test('nodes with menuitem role', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.menuItem,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.semanticRole?.kind, EngineSemanticsRole.menuItem);
    expect(object.element.getAttribute('role'), 'menuitem');
  });

  test('nodes with menuitem role and hasPopup attribute', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics(ui.Tristate isExpanded) {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.menuItem,
        flags: ui.SemanticsFlags(isExpanded: isExpanded),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object0 = pumpSemantics(ui.Tristate.isFalse);
    expect(object0.semanticRole?.kind, EngineSemanticsRole.menuItem);
    expect(object0.element.getAttribute('role'), 'menuitem');
    expect(object0.element.getAttribute('aria-haspopup'), 'menu');

    final SemanticsObject object1 = pumpSemantics(ui.Tristate.none);
    expect(object1.element.getAttribute('role'), 'menuitem');
    expect(object1.element.getAttribute('aria-haspopup'), isNull);
  });

  test('nodes with menubar role', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.menuBar,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.semanticRole?.kind, EngineSemanticsRole.menuBar);
    expect(object.element.getAttribute('role'), 'menubar');
  });

  test('nodes with menuitemcheckbox role', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.menuItemCheckbox,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.semanticRole?.kind, EngineSemanticsRole.menuItemCheckbox);
    expect(object.element.getAttribute('role'), 'menuitemcheckbox');
  });

  test('nodes with menuitemRadio role', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.menuItemRadio,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.semanticRole?.kind, EngineSemanticsRole.menuItemRadio);
    expect(object.element.getAttribute('role'), 'menuitemradio');
  });

  semantics().semanticsEnabled = false;
}

void _testLists() {
  test('nodes with list role', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.list,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.semanticRole?.kind, EngineSemanticsRole.list);
    expect(object.element.getAttribute('role'), 'list');
  });

  test('nodes with list item role', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.listItem,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.semanticRole?.kind, EngineSemanticsRole.listItem);
    expect(object.element.getAttribute('role'), 'listitem');
  });

  semantics().semanticsEnabled = false;
}

void _testControlsNodes() {
  test('can have multiple controlled nodes', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      controlsNodes: <String>['a'],
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(id: 1, identifier: 'a'),
        tester.updateNode(id: 2, identifier: 'b'),
      ],
    );
    tester.apply();

    SemanticsObject object = tester.getSemanticsObject(0);
    expect(object.element.getAttribute('aria-controls'), 'flt-semantic-node-1');

    tester.updateNode(
      id: 0,
      controlsNodes: <String>['b'],
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(id: 1, identifier: 'a'),
        tester.updateNode(id: 2, identifier: 'b'),
      ],
    );
    tester.apply();

    object = tester.getSemanticsObject(0);
    expect(object.element.getAttribute('aria-controls'), 'flt-semantic-node-2');

    tester.updateNode(
      id: 0,
      controlsNodes: <String>['a', 'b'],
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(id: 1, identifier: 'a'),
        tester.updateNode(id: 2, identifier: 'b'),
      ],
    );
    tester.apply();

    object = tester.getSemanticsObject(0);
    expect(object.element.getAttribute('aria-controls'), 'flt-semantic-node-1 flt-semantic-node-2');

    tester.updateNode(
      id: 0,
      controlsNodes: <String>['a', 'b', 'c'],
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(id: 1, identifier: 'a'),
        tester.updateNode(id: 2, identifier: 'b'),
        tester.updateNode(id: 3, identifier: 'c'),
        tester.updateNode(id: 4, identifier: 'd'),
      ],
    );
    tester.apply();

    object = tester.getSemanticsObject(0);
    expect(
      object.element.getAttribute('aria-controls'),
      'flt-semantic-node-1 flt-semantic-node-2 flt-semantic-node-3',
    );

    tester.updateNode(
      id: 0,
      controlsNodes: <String>['a', 'b', 'd'],
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(id: 1, identifier: 'a'),
        tester.updateNode(id: 2, identifier: 'b'),
        tester.updateNode(id: 3, identifier: 'c'),
        tester.updateNode(id: 4, identifier: 'd'),
      ],
    );
    tester.apply();

    object = tester.getSemanticsObject(0);
    expect(
      object.element.getAttribute('aria-controls'),
      'flt-semantic-node-1 flt-semantic-node-2 flt-semantic-node-4',
    );
  });

  semantics().semanticsEnabled = false;
}

void _testRequirable() {
  test('renders and updates non-requirable, required, and unrequired nodes', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 60),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(
          id: 1,
          flags: ui.SemanticsFlags.none,
          rect: const ui.Rect.fromLTRB(0, 0, 100, 20),
        ),
        tester.updateNode(
          id: 2,
          flags: const ui.SemanticsFlags(isRequired: ui.Tristate.isFalse),
          rect: const ui.Rect.fromLTRB(0, 20, 100, 40),
        ),
        tester.updateNode(
          id: 3,
          flags: const ui.SemanticsFlags(isRequired: ui.Tristate.isTrue),
          rect: const ui.Rect.fromLTRB(0, 40, 100, 60),
        ),
      ],
    );
    tester.apply();

    expectSemanticsTree(owner(), '''
<sem>
    <sem></sem>
    <sem aria-required="false"></sem>
    <sem aria-required="true"></sem>
</sem>
''');

    // Missing attributes cannot be expressed using HTML patterns, so check directly.
    final DomElement notRequirable1 = owner().debugSemanticsTree![1]!.element;
    expect(notRequirable1.getAttribute('aria-required'), isNull);

    // Flip the values and check that that ARIA attribute is updated.
    tester.updateNode(
      id: 2,
      flags: const ui.SemanticsFlags(isRequired: ui.Tristate.isTrue),
      rect: const ui.Rect.fromLTRB(0, 20, 100, 40),
    );
    tester.updateNode(
      id: 3,
      flags: const ui.SemanticsFlags(isRequired: ui.Tristate.isFalse),
      rect: const ui.Rect.fromLTRB(0, 40, 100, 60),
    );
    tester.apply();

    expectSemanticsTree(owner(), '''
<sem>
    <sem></sem>
    <sem aria-required="true"></sem>
    <sem aria-required="false"></sem>
</sem>
''');

    // Remove the ARIA attribute
    tester.updateNode(
      id: 2,
      flags: ui.SemanticsFlags.none,
      rect: const ui.Rect.fromLTRB(0, 20, 100, 40),
    );
    tester.updateNode(
      id: 3,
      flags: ui.SemanticsFlags.none,
      rect: const ui.Rect.fromLTRB(0, 40, 100, 60),
    );
    tester.apply();

    expectSemanticsTree(owner(), '''
<sem>
    <sem></sem>
    <sem></sem>
    <sem></sem>
</sem>
''');

    // Missing attributes cannot be expressed using HTML patterns, so check directly.
    final DomElement notRequirable2 = owner().debugSemanticsTree![2]!.element;
    expect(notRequirable2.getAttribute('aria-required'), isNull);

    final DomElement notRequirable3 = owner().debugSemanticsTree![3]!.element;
    expect(notRequirable3.getAttribute('aria-required'), isNull);

    semantics().semanticsEnabled = false;
  });
}

void _testSemanticsTraversalOrder() {
  test('aria-owns is correctly set', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 60),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(
          id: 1,
          rect: const ui.Rect.fromLTRB(0, 0, 100, 20),
          children: <SemanticsNodeUpdate>[
            tester.updateNode(
              id: 4,
              children: <SemanticsNodeUpdate>[tester.updateNode(id: 6), tester.updateNode(id: 7)],
            ),
            tester.updateNode(id: 5),
          ],
        ),
        tester.updateNode(id: 2, rect: const ui.Rect.fromLTRB(0, 20, 100, 40), traversalParent: 4),
        tester.updateNode(id: 3, rect: const ui.Rect.fromLTRB(0, 40, 100, 60)),
      ],
    );
    tester.apply();

    expectSemanticsTree(owner(), '''
<sem>
    <sem>
        <sem id="flt-semantic-node-4" aria-owns="flt-semantic-node-2">
            <sem></sem>
            <sem></sem>
        </sem>
        <sem></sem>
    </sem>
    <sem id="flt-semantic-node-2"></sem>
    <sem></sem>
</sem>
''');

    final SemanticsObject node4 = tester.getSemanticsObject(4);
    expect(node4.element.getAttribute('aria-owns'), 'flt-semantic-node-2');
  });

  test('aria-owns is correctly set with nested traversalParent relationship', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 60),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(
          id: 1,
          rect: const ui.Rect.fromLTRB(0, 0, 100, 20),
          children: <SemanticsNodeUpdate>[
            tester.updateNode(
              id: 4,
              children: <SemanticsNodeUpdate>[tester.updateNode(id: 6), tester.updateNode(id: 7)],
            ),
            tester.updateNode(id: 5),
          ],
        ),
        tester.updateNode(id: 2, rect: const ui.Rect.fromLTRB(0, 20, 100, 40), traversalParent: 4),
        tester.updateNode(id: 3, rect: const ui.Rect.fromLTRB(0, 40, 100, 60)),
        tester.updateNode(id: 8, rect: const ui.Rect.fromLTRB(0, 40, 100, 60), traversalParent: 6),
      ],
    );
    tester.apply();

    expectSemanticsTree(owner(), '''
<sem>
    <sem>
        <sem id="flt-semantic-node-4" aria-owns="flt-semantic-node-2">
            <sem id="flt-semantic-node-6" aria-owns="flt-semantic-node-8"></sem>
            <sem></sem>
        </sem>
        <sem></sem>
    </sem>
    <sem id="flt-semantic-node-2"></sem>
    <sem></sem>
    <sem id="flt-semantic-node-8"></sem>
</sem>
''');

    final SemanticsObject node4 = tester.getSemanticsObject(4);
    expect(node4.element.getAttribute('aria-owns'), 'flt-semantic-node-2');
    final SemanticsObject node6 = tester.getSemanticsObject(6);
    expect(node6.element.getAttribute('aria-owns'), 'flt-semantic-node-8');
  });

  test('aria-owns is correctly set when one traversalParent has multiple children', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 60),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(
          id: 1,
          rect: const ui.Rect.fromLTRB(0, 0, 100, 20),
          children: <SemanticsNodeUpdate>[
            tester.updateNode(
              id: 4,
              children: <SemanticsNodeUpdate>[tester.updateNode(id: 6), tester.updateNode(id: 7)],
            ),
            tester.updateNode(id: 5),
          ],
        ),
        tester.updateNode(id: 2, rect: const ui.Rect.fromLTRB(0, 20, 100, 40), traversalParent: 4),
        tester.updateNode(id: 3, rect: const ui.Rect.fromLTRB(0, 40, 100, 60), traversalParent: 4),
        tester.updateNode(id: 8, rect: const ui.Rect.fromLTRB(0, 40, 100, 60), traversalParent: 4),
      ],
    );
    tester.apply();

    expectSemanticsTree(owner(), '''
<sem>
    <sem>
        <sem id="flt-semantic-node-4" aria-owns="flt-semantic-node-2 flt-semantic-node-3 flt-semantic-node-8">
            <sem></sem>
            <sem></sem>
        </sem>
        <sem></sem>
    </sem>
    <sem id="flt-semantic-node-2"></sem>
    <sem id="flt-semantic-node-3"></sem>
    <sem id="flt-semantic-node-8"></sem>
</sem>
''');

    final SemanticsObject node4 = tester.getSemanticsObject(4);
    expect(
      node4.element.getAttribute('aria-owns'),
      'flt-semantic-node-2 flt-semantic-node-3 flt-semantic-node-8',
    );
  });
}

void _testSemanticsValidationResult() {
  test('renders validation result', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      children: <SemanticsNodeUpdate>[
        // This node does not validate its contents and should not have an
        // aria-invalid attribute at all.
        tester.updateNode(id: 1),
        // This node is valid. aria-invalid should be "false".
        tester.updateNode(id: 2, validationResult: ui.SemanticsValidationResult.valid),
        // This node is invalid. aria-invalid should be "true".
        tester.updateNode(id: 3, validationResult: ui.SemanticsValidationResult.invalid),
      ],
    );
    tester.apply();

    tester.expectSemantics('''
<sem id="flt-semantic-node-0" aria-invalid--missing>
  <sem id="flt-semantic-node-1" aria-invalid--missing></sem>
  <sem id="flt-semantic-node-2" aria-invalid="false"></sem>
  <sem id="flt-semantic-node-3" aria-invalid="true"></sem>
</sem>''');

    // Shift all values, observe that the values changed accordingly
    tester.updateNode(
      id: 0,
      children: <SemanticsNodeUpdate>[
        // This node is valid. aria-invalid should be "false".
        tester.updateNode(id: 1, validationResult: ui.SemanticsValidationResult.valid),
        // This node is invalid. aria-invalid should be "true".
        tester.updateNode(id: 2, validationResult: ui.SemanticsValidationResult.invalid),
        // This node does not validate its contents and should not have an
        // aria-invalid attribute at all.
        tester.updateNode(id: 3),
      ],
    );
    tester.apply();

    tester.expectSemantics('''
<sem id="flt-semantic-node-0" aria-invalid--missing>
  <sem id="flt-semantic-node-1" aria-invalid="false"></sem>
  <sem id="flt-semantic-node-2" aria-invalid="true"></sem>
  <sem id="flt-semantic-node-3" aria-invalid--missing></sem>
</sem>''');
  });
}

void _testLandmarks() {
  test('nodes with complementary role', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.complementary,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.semanticRole?.kind, EngineSemanticsRole.complementary);
    expect(object.element.getAttribute('role'), 'complementary');
  });

  test('nodes with the same complementary role have labels', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(
          id: 1,
          role: ui.SemanticsRole.complementary,
          label: 'complementary 1',
          rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
        ),
        tester.updateNode(
          id: 2,
          role: ui.SemanticsRole.complementary,
          label: 'complementary 2',
          rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
        ),
        tester.updateNode(
          id: 3,
          rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
          children: <SemanticsNodeUpdate>[
            tester.updateNode(
              id: 4,
              role: ui.SemanticsRole.complementary,
              label: 'complementary 4',
              rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
            ),
          ],
        ),
      ],
    );
    tester.apply();
    final SemanticsObject object = tester.getSemanticsObject(1);
    expect(object.semanticRole?.kind, EngineSemanticsRole.complementary);
    expect(object.element.getAttribute('role'), 'complementary');
    expect(object.element.getAttribute('aria-label'), 'complementary 1');

    final SemanticsObject object2 = tester.getSemanticsObject(2);
    expect(object2.semanticRole?.kind, EngineSemanticsRole.complementary);
    expect(object2.element.getAttribute('role'), 'complementary');
    expect(object2.element.getAttribute('aria-label'), 'complementary 2');

    final SemanticsObject object4 = tester.getSemanticsObject(4);
    expect(object4.semanticRole?.kind, EngineSemanticsRole.complementary);
    expect(object4.element.getAttribute('role'), 'complementary');
    expect(object4.element.getAttribute('aria-label'), 'complementary 4');
  });

  test('nodes with contentInfo role', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.contentInfo,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.semanticRole?.kind, EngineSemanticsRole.contentInfo);
    expect(object.element.getAttribute('role'), 'contentinfo');
  });

  test('nodes with the same contentInfo role have labels', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(
          id: 1,
          role: ui.SemanticsRole.contentInfo,
          label: 'contentInfo 1',
          rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
        ),
        tester.updateNode(
          id: 2,
          role: ui.SemanticsRole.contentInfo,
          label: 'contentInfo 2',
          rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
        ),
      ],
    );
    tester.apply();
    final SemanticsObject object1 = tester.getSemanticsObject(1);
    expect(object1.semanticRole?.kind, EngineSemanticsRole.contentInfo);
    expect(object1.element.getAttribute('role'), 'contentinfo');
    expect(object1.element.getAttribute('aria-label'), 'contentInfo 1');

    final SemanticsObject object2 = tester.getSemanticsObject(2);
    expect(object2.semanticRole?.kind, EngineSemanticsRole.contentInfo);
    expect(object2.element.getAttribute('role'), 'contentinfo');
    expect(object2.element.getAttribute('aria-label'), 'contentInfo 2');
  });

  test('nodes with main role', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.main,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.semanticRole?.kind, EngineSemanticsRole.main);
    expect(object.element.getAttribute('role'), 'main');
  });

  test('node with the same main role have labels', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(
          id: 1,
          label: 'main 1',
          role: ui.SemanticsRole.main,
          rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
        ),
        tester.updateNode(
          id: 2,
          label: 'main 2',
          role: ui.SemanticsRole.main,
          rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
        ),
      ],
    );
    tester.apply();
    final SemanticsObject object1 = tester.getSemanticsObject(1);
    expect(object1.semanticRole?.kind, EngineSemanticsRole.main);
    expect(object1.element.getAttribute('role'), 'main');
    expect(object1.element.getAttribute('aria-label'), 'main 1');

    final SemanticsObject object2 = tester.getSemanticsObject(2);
    expect(object2.semanticRole?.kind, EngineSemanticsRole.main);
    expect(object2.element.getAttribute('role'), 'main');
    expect(object2.element.getAttribute('aria-label'), 'main 2');
  });

  test('nodes with navigation role', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.navigation,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.semanticRole?.kind, EngineSemanticsRole.navigation);
    expect(object.element.getAttribute('role'), 'navigation');
  });

  test('nodes with the same navigation role have labels', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(
          id: 1,
          role: ui.SemanticsRole.navigation,
          label: 'navigation 1',
          rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
        ),
        tester.updateNode(
          id: 2,
          role: ui.SemanticsRole.navigation,
          label: 'navigation 2',
          rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
        ),
      ],
    );
    tester.apply();
    final SemanticsObject object = tester.getSemanticsObject(1);
    expect(object.semanticRole?.kind, EngineSemanticsRole.navigation);
    expect(object.element.getAttribute('role'), 'navigation');
    expect(object.element.getAttribute('aria-label'), 'navigation 1');

    final SemanticsObject object2 = tester.getSemanticsObject(2);
    expect(object2.semanticRole?.kind, EngineSemanticsRole.navigation);
    expect(object2.element.getAttribute('role'), 'navigation');
    expect(object2.element.getAttribute('aria-label'), 'navigation 2');
  });

  test('nodes with region role', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        label: 'Header 1',
        role: ui.SemanticsRole.region,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.semanticRole?.kind, EngineSemanticsRole.region);
    expect(object.element.getAttribute('role'), 'region');
    expect(object.element.getAttribute('aria-label'), 'Header 1');
  });

  semantics().semanticsEnabled = false;
}

void _testLocale() {
  test('nodes with locale update correctly', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        locale: const ui.Locale('es-MX'),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.element.getAttribute('lang'), 'es-MX');
  });

  test('nodes with same locale as parent does not set lang', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    SemanticsObject pumpSemantics() {
      tester.updateNode(
        id: 0,
        locale: const ui.Locale('es-MX'),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
        children: <SemanticsNodeUpdate>[
          tester.updateNode(
            id: 1,
            locale: const ui.Locale('es-MX'),
            rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
          ),
        ],
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.element.getAttribute('lang'), 'es-MX');
    final SemanticsObject node1 = tester.getSemanticsObject(1);
    expect(node1.element.getAttribute('lang'), null);
  });

  test('nodes changing locale set lang correctly', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    SemanticsObject pumpSemantics() {
      tester.updateNode(
        id: 0,
        locale: const ui.Locale('es-MX'),
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
        children: <SemanticsNodeUpdate>[
          tester.updateNode(
            id: 1,
            locale: const ui.Locale('es-MX'),
            rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
            children: <SemanticsNodeUpdate>[
              tester.updateNode(
                id: 2,
                locale: const ui.Locale('en-US'),
                rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
              ),
            ],
          ),
        ],
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.element.getAttribute('lang'), 'es-MX');
    final SemanticsObject node1 = tester.getSemanticsObject(1);
    expect(node1.element.getAttribute('lang'), null);
    final SemanticsObject node2 = tester.getSemanticsObject(2);
    expect(node2.element.getAttribute('lang'), 'en-US');
  });

  semantics().semanticsEnabled = false;
}

void _testForms() {
  test('nodes with form role', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      role: ui.SemanticsRole.form,
      rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
    );
    tester.apply();

    tester.expectSemantics('''<form id="flt-semantic-node-0" ></form>''');
    final SemanticsObject object = tester.getSemanticsObject(0);
    expect(object.semanticRole?.kind, EngineSemanticsRole.form);
  });

  test('form with children ', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    final tester = SemanticsTester(owner());
    tester.updateNode(
      id: 0,
      flags: const ui.SemanticsFlags(scopesRoute: true),
      transform: Matrix4.identity().toFloat64(),
      children: <SemanticsNodeUpdate>[
        tester.updateNode(
          id: 1,
          role: ui.SemanticsRole.form,
          rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
          children: <SemanticsNodeUpdate>[
            tester.updateNode(
              id: 2,
              flags: const ui.SemanticsFlags(isTextField: true),
              rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
            ),
          ],
        ),
      ],
    );
    tester.apply();

    tester.expectSemantics('''
<sem id="flt-semantic-node-0">
  <form id="flt-semantic-node-1">
    <sem id="flt-semantic-node-2">
      <input />
    </sem>
  </form>
</sem>''');
    final SemanticsObject object = tester.getSemanticsObject(1);
    expect(object.semanticRole?.kind, EngineSemanticsRole.form);
  });

  semantics().semanticsEnabled = false;
}

void _testProgressBar() {
  test('nodes with progress bar role', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.progressBar,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.semanticRole?.kind, EngineSemanticsRole.progressBar);
    expect(object.element.getAttribute('role'), 'progressbar');
  });

  semantics().semanticsEnabled = false;
}

void _testLoadingSpinner() {
  test('nodes with loading spinner role', () {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    SemanticsObject pumpSemantics() {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        role: ui.SemanticsRole.loadingSpinner,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
      );
      tester.apply();
      return tester.getSemanticsObject(0);
    }

    final SemanticsObject object = pumpSemantics();
    expect(object.semanticRole?.kind, EngineSemanticsRole.loadingSpinner);
  });

  semantics().semanticsEnabled = false;
}

/// A facade in front of [ui.SemanticsUpdateBuilder.updateNode] that
/// supplies default values for semantics attributes.
void updateNode(
  ui.SemanticsUpdateBuilder builder, {
  int id = 0,
  ui.SemanticsFlags flags = ui.SemanticsFlags.none,
  int actions = 0,
  int maxValueLength = 0,
  int currentValueLength = 0,
  int textSelectionBase = 0,
  int textSelectionExtent = 0,
  int platformViewId = -1, // -1 means not a platform view
  int scrollChildren = 0,
  int scrollIndex = 0,
  int traversalParent = -1,
  double scrollPosition = 0.0,
  double scrollExtentMax = 0.0,
  double scrollExtentMin = 0.0,
  ui.Rect rect = ui.Rect.zero,
  String identifier = '',
  String label = '',
  List<ui.StringAttribute> labelAttributes = const <ui.StringAttribute>[],
  String hint = '',
  List<ui.StringAttribute> hintAttributes = const <ui.StringAttribute>[],
  String value = '',
  List<ui.StringAttribute> valueAttributes = const <ui.StringAttribute>[],
  String increasedValue = '',
  List<ui.StringAttribute> increasedValueAttributes = const <ui.StringAttribute>[],
  String decreasedValue = '',
  List<ui.StringAttribute> decreasedValueAttributes = const <ui.StringAttribute>[],
  String tooltip = '',
  ui.TextDirection textDirection = ui.TextDirection.ltr,
  Float64List? transform,
  Float64List? hitTestTransform,
  Int32List? childrenInTraversalOrder,
  Int32List? childrenInHitTestOrder,
  Int32List? additionalActions,
  int headingLevel = 0,
  String? linkUrl,
  List<String>? controlsNodes,
  ui.SemanticsRole role = ui.SemanticsRole.none,
  ui.SemanticsHitTestBehavior hitTestBehavior = ui.SemanticsHitTestBehavior.defer,
  ui.SemanticsInputType inputType = ui.SemanticsInputType.none,
  ui.Locale? locale,
  String minValue = '0',
  String maxValue = '0',
}) {
  transform ??= Float64List.fromList(Matrix4.identity().storage);
  hitTestTransform ??= Float64List.fromList(Matrix4.identity().storage);
  childrenInTraversalOrder ??= Int32List(0);
  childrenInHitTestOrder ??= Int32List(0);
  additionalActions ??= Int32List(0);
  builder.updateNode(
    id: id,
    role: role,
    flags: flags,
    actions: actions,
    maxValueLength: maxValueLength,
    currentValueLength: currentValueLength,
    textSelectionBase: textSelectionBase,
    textSelectionExtent: textSelectionExtent,
    platformViewId: platformViewId,
    scrollChildren: scrollChildren,
    scrollIndex: scrollIndex,
    traversalParent: traversalParent,
    scrollPosition: scrollPosition,
    scrollExtentMax: scrollExtentMax,
    scrollExtentMin: scrollExtentMin,
    rect: rect,
    identifier: identifier,
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
    hitTestTransform: hitTestTransform,
    childrenInTraversalOrder: childrenInTraversalOrder,
    childrenInHitTestOrder: childrenInHitTestOrder,
    additionalActions: additionalActions,
    headingLevel: headingLevel,
    linkUrl: linkUrl,
    controlsNodes: controlsNodes,
    hitTestBehavior: hitTestBehavior,
    inputType: inputType,
    locale: locale,
    minValue: minValue,
    maxValue: maxValue,
  );
}

const MethodCodec codec = StandardMethodCodec();

/// Sends a platform message to create a Platform View with the given id and viewType.
Future<void> createPlatformView(int id, String viewType) {
  final completer = Completer<void>();
  ui.PlatformDispatcher.instance.sendPlatformMessage(
    'flutter/platform_views',
    codec.encodeMethodCall(MethodCall('create', <String, dynamic>{'id': id, 'viewType': viewType})),
    (dynamic _) => completer.complete(),
  );
  return completer.future;
}
