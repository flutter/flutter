// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../services/fake_platform_views.dart';
import 'rendering_tester.dart';

RenderBox _positioned({
  double? left,
  double? top,
  double? right,
  double? bottom,
  double? width,
  double? height,
  required RenderBox child,
}) {
  child.parentData = StackParentData()
    ..left = left
    ..top = top
    ..right = right
    ..bottom = bottom
    ..width = width
    ..height = height;
  return child;
}

PlatformViewRenderBox _createPlatformView(int viewId) {
  return PlatformViewRenderBox(
    controller: FakePlatformViewController(viewId),
    hitTestBehavior: PlatformViewHitTestBehavior.opaque,
    gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
  );
}

RenderBox _createHitTarget({
  double width = 100.0,
  double height = 50.0,
  HitTestBehavior behavior = HitTestBehavior.opaque,
  RenderBox? child,
}) {
  return RenderConstrainedBox(
    additionalConstraints: BoxConstraints.tightFor(width: width, height: height),
    child: RenderPointerListener(behavior: behavior, child: child),
  );
}

ViewConfiguration _createViewConfiguration({
  Size size = const Size(800.0, 600.0),
  double devicePixelRatio = 1.0,
}) {
  final logicalConstraints = BoxConstraints.tight(size);
  return ViewConfiguration(
    logicalConstraints: logicalConstraints,
    physicalConstraints: logicalConstraints * devicePixelRatio,
    devicePixelRatio: devicePixelRatio,
  );
}

void main() {
  final TestRenderingFlutterBinding binding = TestRenderingFlutterBinding.ensureInitialized();
  late ViewConfiguration initialConfiguration;

  setUp(() {
    initialConfiguration = binding.renderView.configuration;
    binding.renderView.configuration = _createViewConfiguration();
    binding.automaticPointerInterceptorsEnabled = false;
    debugEnableHitTestRegionsOnAllPlatforms = false;
  });

  tearDown(() {
    binding.automaticPointerInterceptorsEnabled = false;
    debugEnableHitTestRegionsOnAllPlatforms = false;
    binding.renderView.configuration = initialConfiguration;
    final RenderBox emptyBox = RenderConstrainedBox(
      additionalConstraints: const BoxConstraints.tightFor(width: 0.0, height: 0.0),
    );
    layout(emptyBox);
  });

  test('does not compute hit-test regions when flag is off or not on web without override', () {
    final PlatformViewRenderBox pv = _createPlatformView(1);
    final RenderBox overlay = _createHitTarget();
    final stack = RenderStack(
      textDirection: TextDirection.ltr,
      children: <RenderBox>[
        _positioned(left: 0, top: 0, width: 400, height: 400, child: pv),
        _positioned(left: 10, top: 20, width: 100, height: 50, child: overlay),
      ],
    );

    // 1. Flag off, debug override on -> null.
    debugEnableHitTestRegionsOnAllPlatforms = true;
    binding.automaticPointerInterceptorsEnabled = false;
    layout(stack, phase: EnginePhase.composite);
    binding.pumpCompleteFrame();
    expect(binding.rootPipelineOwner.debugLastHitTestRegions, isNull);

    // 2. Flag on, debug override off (when not running on web) -> null.
    if (!kIsWeb) {
      debugEnableHitTestRegionsOnAllPlatforms = false;
      binding.automaticPointerInterceptorsEnabled = true;
      pumpFrame(phase: EnginePhase.composite);
      binding.pumpCompleteFrame();
      expect(binding.rootPipelineOwner.debugLastHitTestRegions, isNull);
    }
  });

  test(
    'returns null when no platform view is present and sends empty list once on last detach',
    () {
      debugEnableHitTestRegionsOnAllPlatforms = true;
      binding.automaticPointerInterceptorsEnabled = true;

      final updates = <Float64List>[];
      final owner = PipelineOwner(onHitTestRegionsUpdate: updates.add);
      final view = RenderView(
        configuration: _createViewConfiguration(),
        view: binding.platformDispatcher.views.single,
      );
      owner.rootNode = view;
      view.prepareInitialFrame();
      addTearDown(() {
        owner.rootNode = null;
        owner.dispose();
      });

      final stack = RenderStack(
        textDirection: TextDirection.ltr,
        children: <RenderBox>[
          _positioned(left: 10, top: 20, width: 100, height: 50, child: _createHitTarget()),
        ],
      );
      view.child = stack;
      owner.flushLayout();
      owner.flushCompositingBits();
      owner.flushPaint();
      owner.flushHitTestRegions();

      expect(owner.debugLastHitTestRegions, isNull);
      expect(updates, isEmpty);

      // Attach a platform view below the hit target.
      final PlatformViewRenderBox pv = _createPlatformView(7);
      stack.insert(_positioned(left: 0, top: 0, width: 300, height: 300, child: pv));
      owner.flushLayout();
      owner.flushCompositingBits();
      owner.flushPaint();
      owner.flushHitTestRegions();

      expect(
        owner.debugLastHitTestRegions,
        equals(Float64List.fromList(<double>[7.0, 1.0, 10.0, 20.0, 110.0, 70.0])),
      );
      expect(updates, hasLength(1));
      expect(
        updates.single,
        equals(Float64List.fromList(<double>[7.0, 1.0, 10.0, 20.0, 110.0, 70.0])),
      );

      // Remove the last platform view: debugLastHitTestRegions becomes null and
      // an empty Float64List is sent once to clear stale proxy elements.
      stack.remove(pv);
      owner.flushLayout();
      owner.flushCompositingBits();
      owner.flushPaint();
      owner.flushHitTestRegions();

      expect(owner.debugLastHitTestRegions, isNull);
      expect(updates, hasLength(2));
      expect(updates.last, isEmpty);

      // Subsequent flushes with 0 platform views do not keep sending empty updates.
      owner.flushHitTestRegions();
      expect(updates, hasLength(2));
    },
  );

  test(
    'ignores content painted before platform view and scales overlay rect by devicePixelRatio',
    () {
      debugEnableHitTestRegionsOnAllPlatforms = true;
      binding.automaticPointerInterceptorsEnabled = true;

      final RenderBox beforePv = _createHitTarget(width: 80, height: 40);
      final PlatformViewRenderBox pv = _createPlatformView(1);
      final RenderBox overPv = _createHitTarget(width: 100, height: 50);
      final RenderBox disjointAfterPv = _createHitTarget(width: 50, height: 50);

      final stack = RenderStack(
        textDirection: TextDirection.ltr,
        children: <RenderBox>[
          _positioned(left: 10, top: 20, width: 80, height: 40, child: beforePv),
          _positioned(left: 0, top: 0, width: 300, height: 300, child: pv),
          _positioned(left: 10, top: 20, width: 100, height: 50, child: overPv),
          _positioned(left: 400, top: 400, width: 50, height: 50, child: disjointAfterPv),
        ],
      );

      // At DPR 1.0: logical (10, 20, 110, 70) -> physical [10, 20, 110, 70].
      layout(stack, phase: EnginePhase.composite);
      binding.pumpCompleteFrame();
      expect(
        binding.rootPipelineOwner.debugLastHitTestRegions,
        equals(Float64List.fromList(<double>[1.0, 1.0, 10.0, 20.0, 110.0, 70.0])),
      );

      // At DPR 3.0: logical (10, 20, 110, 70) -> physical [30, 60, 330, 210].
      binding.renderView.configuration = _createViewConfiguration(devicePixelRatio: 3.0);
      pumpFrame(phase: EnginePhase.composite);
      binding.pumpCompleteFrame();
      expect(
        binding.rootPipelineOwner.debugLastHitTestRegions,
        equals(Float64List.fromList(<double>[1.0, 1.0, 30.0, 60.0, 330.0, 210.0])),
      );
    },
  );

  test('applies ancestor paint clips and transforms, and keeps claimed rect unclipped to platform view', () {
    debugEnableHitTestRegionsOnAllPlatforms = true;
    binding.automaticPointerInterceptorsEnabled = true;

    // Small platform view at (100, 100) to (150, 150).
    final PlatformViewRenderBox pv = _createPlatformView(1);
    // Large overlay at (0, 0) to (300, 300) partially overlapping pv -> emitted unclipped to pv.
    final RenderBox largeOverlay = _createHitTarget(width: 300, height: 300);
    // Clipped and translated overlay: ClipRect of 60x60 translated to (110, 110) containing
    // a 200x200 hit target -> clipped to [110, 110, 170, 170].
    final RenderBox clippedAndTranslated = RenderTransform(
      transform: Matrix4.translationValues(110.0, 110.0, 0.0),
      child: RenderConstrainedBox(
        additionalConstraints: const BoxConstraints.tightFor(width: 60.0, height: 60.0),
        child: RenderClipRect(child: _createHitTarget(width: 200, height: 200)),
      ),
    );

    final stack = RenderStack(
      textDirection: TextDirection.ltr,
      children: <RenderBox>[
        _positioned(left: 100, top: 100, width: 50, height: 50, child: pv),
        _positioned(left: 0, top: 0, width: 300, height: 300, child: largeOverlay),
        _positioned(left: 0, top: 0, width: 60, height: 60, child: clippedAndTranslated),
      ],
    );

    layout(stack, phase: EnginePhase.composite);
    binding.pumpCompleteFrame();

    expect(
      binding.rootPipelineOwner.debugLastHitTestRegions,
      equals(
        Float64List.fromList(<double>[
          1.0,
          2.0,
          0.0,
          0.0,
          300.0,
          300.0,
          110.0,
          110.0,
          170.0,
          170.0,
        ]),
      ),
    );
  });

  test('partitions claims across multiple platform views (PV1 under barrier and dialog containing PV2)', () {
    debugEnableHitTestRegionsOnAllPlatforms = true;
    binding.automaticPointerInterceptorsEnabled = true;

    final RenderBox homeBeforePv1 = _createHitTarget(width: 100, height: 100);
    final PlatformViewRenderBox pv1 = _createPlatformView(10);
    final RenderBox buttonOverPv1 = _createHitTarget(width: 80, height: 40);
    final RenderBox modalBarrier = _createHitTarget(width: 800, height: 600);
    final RenderBox dialogChromeBeforePv2 = _createHitTarget(width: 200, height: 40);
    final PlatformViewRenderBox pv2 = _createPlatformView(20);
    final RenderBox dialogButtonOverPv2 = _createHitTarget(width: 50, height: 30);

    final stack = RenderStack(
      textDirection: TextDirection.ltr,
      children: <RenderBox>[
        _positioned(left: 0, top: 0, width: 100, height: 100, child: homeBeforePv1),
        _positioned(left: 0, top: 0, width: 400, height: 400, child: pv1),
        _positioned(left: 20, top: 30, width: 80, height: 40, child: buttonOverPv1),
        _positioned(left: 0, top: 0, width: 800, height: 600, child: modalBarrier),
        _positioned(left: 100, top: 100, width: 200, height: 40, child: dialogChromeBeforePv2),
        _positioned(left: 100, top: 140, width: 200, height: 200, child: pv2),
        _positioned(left: 120, top: 160, width: 50, height: 30, child: dialogButtonOverPv2),
      ],
    );

    layout(stack, phase: EnginePhase.composite);
    binding.pumpCompleteFrame();

    // PV1 group (id 10) receives exactly the 3 rects painted between PV1 and PV2.
    // PV2 group (id 20) receives only the rect painted after PV2.
    expect(
      binding.rootPipelineOwner.debugLastHitTestRegions,
      equals(
        Float64List.fromList(<double>[
          10.0,
          3.0,
          20.0,
          30.0,
          100.0,
          70.0,
          0.0,
          0.0,
          800.0,
          600.0,
          100.0,
          100.0,
          300.0,
          140.0,
          20.0,
          1.0,
          120.0,
          160.0,
          170.0,
          190.0,
        ]),
      ),
    );
  });

  test(
    'toggling barrier RenderIgnorePointer drops barrier rect without repainting underlying content',
    () {
      debugEnableHitTestRegionsOnAllPlatforms = true;
      binding.automaticPointerInterceptorsEnabled = true;

      final PlatformViewRenderBox pv = _createPlatformView(1);
      final barrierIgnorePointer = RenderIgnorePointer(
        ignoring: false,
        child: _createHitTarget(width: 800, height: 600),
      );

      final stack = RenderStack(
        textDirection: TextDirection.ltr,
        children: <RenderBox>[
          _positioned(left: 0, top: 0, width: 400, height: 400, child: pv),
          _positioned(left: 0, top: 0, width: 800, height: 600, child: barrierIgnorePointer),
        ],
      );

      layout(stack, phase: EnginePhase.composite);
      binding.pumpCompleteFrame();
      expect(
        binding.rootPipelineOwner.debugLastHitTestRegions,
        equals(Float64List.fromList(<double>[1.0, 1.0, 0.0, 0.0, 800.0, 600.0])),
      );

      // Simulate dialog exit animation: barrier IgnorePointer flips to ignoring: true.
      barrierIgnorePointer.ignoring = true;
      expect(pv.debugNeedsPaint, isFalse);
      expect(barrierIgnorePointer.debugNeedsPaint, isFalse);

      binding.pumpCompleteFrame();
      expect(
        binding.rootPipelineOwner.debugLastHitTestRegions,
        equals(Float64List.fromList(<double>[1.0, 0.0])),
      );
    },
  );

  test(
    'handles RenderIgnorePointer, RenderAbsorbPointer, RenderOffstage, and translucent behavior',
    () {
      debugEnableHitTestRegionsOnAllPlatforms = true;
      binding.automaticPointerInterceptorsEnabled = true;

      final PlatformViewRenderBox pv = _createPlatformView(1);

      // 1. RenderIgnorePointer overlay -> no rect.
      final ignoredOverlay = RenderIgnorePointer(child: _createHitTarget(width: 100, height: 50));

      // 2. RenderAbsorbPointer -> claims its own rect once; nothing in its subtree claims.
      final absorbingOverlay = RenderAbsorbPointer(
        child: RenderStack(
          textDirection: TextDirection.ltr,
          children: <RenderBox>[
            _positioned(left: 0, top: 0, width: 60, height: 30, child: _createHitTarget()),
            _positioned(left: 10, top: 10, width: 40, height: 20, child: _createHitTarget()),
          ],
        ),
      );

      // 3. Translucent RenderPointerListener -> hitTestSelf is false -> no rect.
      final RenderBox translucentOverlay = _createHitTarget(
        width: 100,
        height: 50,
        behavior: HitTestBehavior.translucent,
      );

      // 4. RenderOffstage(offstage: true) -> skipped completely.
      final offstageOverlay = RenderOffstage(child: _createHitTarget(width: 100, height: 50));
      final offstagePv = RenderOffstage(child: _createPlatformView(99));

      final stack = RenderStack(
        textDirection: TextDirection.ltr,
        children: <RenderBox>[
          _positioned(left: 0, top: 0, width: 400, height: 400, child: pv),
          _positioned(left: 10, top: 10, width: 100, height: 50, child: ignoredOverlay),
          _positioned(left: 50, top: 60, width: 120, height: 80, child: absorbingOverlay),
          _positioned(left: 20, top: 20, width: 100, height: 50, child: translucentOverlay),
          _positioned(left: 30, top: 30, width: 100, height: 50, child: offstageOverlay),
          _positioned(left: 0, top: 0, width: 200, height: 200, child: offstagePv),
        ],
      );

      layout(stack, phase: EnginePhase.composite);
      binding.pumpCompleteFrame();

      // Only the RenderAbsorbPointer's own rect [50, 60, 170, 140] is emitted for PV 1;
      // offstage PV 99 is not registered.
      expect(
        binding.rootPipelineOwner.debugLastHitTestRegions,
        equals(Float64List.fromList(<double>[1.0, 1.0, 50.0, 60.0, 170.0, 140.0])),
      );
    },
  );

  test('discovers PlatformViewRenderBox inside RenderIgnorePointer while suppressing sibling claims inside it', () {
    debugEnableHitTestRegionsOnAllPlatforms = true;
    binding.automaticPointerInterceptorsEnabled = true;

    final PlatformViewRenderBox pvInsideIgnore = _createPlatformView(5);
    final RenderBox siblingInsideIgnore = _createHitTarget(width: 80, height: 80);

    final ignoredSubtree = RenderIgnorePointer(
      child: RenderStack(
        textDirection: TextDirection.ltr,
        children: <RenderBox>[
          _positioned(left: 0, top: 0, width: 300, height: 300, child: pvInsideIgnore),
          _positioned(left: 10, top: 10, width: 80, height: 80, child: siblingInsideIgnore),
        ],
      ),
    );

    final RenderBox overlayAboveIgnore = _createHitTarget(width: 100, height: 60);

    final stack = RenderStack(
      textDirection: TextDirection.ltr,
      children: <RenderBox>[
        _positioned(left: 0, top: 0, width: 300, height: 300, child: ignoredSubtree),
        _positioned(left: 25, top: 35, width: 100, height: 60, child: overlayAboveIgnore),
      ],
    );

    layout(stack, phase: EnginePhase.composite);
    binding.pumpCompleteFrame();

    expect(
      binding.rootPipelineOwner.debugLastHitTestRegions,
      equals(Float64List.fromList(<double>[5.0, 1.0, 25.0, 35.0, 125.0, 95.0])),
    );
  });

  test('discovers PlatformViewRenderBox inside absorbing RenderAbsorbPointer painted after another platform view', () {
    debugEnableHitTestRegionsOnAllPlatforms = true;
    binding.automaticPointerInterceptorsEnabled = true;

    final PlatformViewRenderBox pv1 = _createPlatformView(1);
    final PlatformViewRenderBox pv2 = _createPlatformView(2);
    final RenderBox siblingInsideAbsorber = _createHitTarget(width: 40, height: 40);

    final absorber = RenderAbsorbPointer(
      child: RenderStack(
        textDirection: TextDirection.ltr,
        children: <RenderBox>[
          _positioned(left: 0, top: 0, width: 200, height: 200, child: pv2),
          // Painted over PV2, but inside the absorber, so it never claims.
          _positioned(left: 10, top: 10, width: 40, height: 40, child: siblingInsideAbsorber),
        ],
      ),
    );

    final RenderBox barrier = _createHitTarget(width: 800, height: 600);

    final stack = RenderStack(
      textDirection: TextDirection.ltr,
      children: <RenderBox>[
        _positioned(left: 0, top: 0, width: 400, height: 400, child: pv1),
        _positioned(left: 100, top: 100, width: 200, height: 200, child: absorber),
        // Painted last, over both platform views.
        _positioned(left: 0, top: 0, width: 800, height: 600, child: barrier),
      ],
    );

    layout(stack, phase: EnginePhase.composite);
    binding.pumpCompleteFrame();

    // PV1's group holds the absorber's own rect; PV2 still starts its own group,
    // which holds the barrier painted on top of it.
    expect(
      binding.rootPipelineOwner.debugLastHitTestRegions,
      equals(
        Float64List.fromList(<double>[
          1.0, 1.0, 100.0, 100.0, 300.0, 300.0, //
          2.0, 1.0, 0.0, 0.0, 800.0, 600.0,
        ]),
      ),
    );
  });

  test('multi-view PipelineOwner hierarchy: flushHitTestRegions and clearHitTestRegions recurse into child owners when parent has no rootNode', () {
    final parentUpdates = <Float64List>[];
    final child1Updates = <Float64List>[];
    final child2Updates = <Float64List>[];

    final parentOwner = PipelineOwner(onHitTestRegionsUpdate: parentUpdates.add);
    final childOwner1 = PipelineOwner(onHitTestRegionsUpdate: child1Updates.add);
    final childOwner2 = PipelineOwner(onHitTestRegionsUpdate: child2Updates.add);
    parentOwner.adoptChild(childOwner1);
    parentOwner.adoptChild(childOwner2);

    final view1 = RenderView(
      configuration: _createViewConfiguration(),
      view: binding.platformDispatcher.views.single,
    );
    final view2 = RenderView(
      configuration: _createViewConfiguration(),
      view: binding.platformDispatcher.views.single,
    );
    childOwner1.rootNode = view1;
    childOwner2.rootNode = view2;
    view1.prepareInitialFrame();
    view2.prepareInitialFrame();

    addTearDown(() {
      childOwner1.rootNode = null;
      childOwner2.rootNode = null;
      parentOwner.dropChild(childOwner1);
      parentOwner.dropChild(childOwner2);
      childOwner1.dispose();
      childOwner2.dispose();
      parentOwner.dispose();
    });

    view1.child = RenderStack(
      textDirection: TextDirection.ltr,
      children: <RenderBox>[
        _positioned(left: 0, top: 0, width: 300, height: 300, child: _createPlatformView(101)),
        _positioned(left: 10, top: 20, width: 50, height: 40, child: _createHitTarget()),
      ],
    );
    view2.child = RenderStack(
      textDirection: TextDirection.ltr,
      children: <RenderBox>[
        _positioned(left: 0, top: 0, width: 300, height: 300, child: _createPlatformView(202)),
        _positioned(left: 30, top: 40, width: 70, height: 60, child: _createHitTarget()),
      ],
    );

    parentOwner.flushLayout();
    parentOwner.flushCompositingBits();
    parentOwner.flushPaint();

    // parentOwner has rootNode == null and 0 direct platform views, but must still recurse.
    expect(parentOwner.rootNode, isNull);
    parentOwner.flushHitTestRegions();

    expect(parentUpdates, isEmpty);
    expect(
      childOwner1.debugLastHitTestRegions,
      equals(Float64List.fromList(<double>[101.0, 1.0, 10.0, 20.0, 60.0, 60.0])),
    );
    expect(
      childOwner2.debugLastHitTestRegions,
      equals(Float64List.fromList(<double>[202.0, 1.0, 30.0, 40.0, 100.0, 100.0])),
    );
    expect(child1Updates, hasLength(1));
    expect(child2Updates, hasLength(1));

    // clearHitTestRegions recurses to all children and dispatches empty Float64List(0).
    parentOwner.clearHitTestRegions();
    expect(childOwner1.debugLastHitTestRegions, isNull);
    expect(childOwner2.debugLastHitTestRegions, isNull);
    expect(child1Updates.last, isEmpty);
    expect(child2Updates.last, isEmpty);
  });

  test('toggling automaticPointerInterceptorsEnabled from true to false immediately clears regions and dispatches empty payload', () {
    debugEnableHitTestRegionsOnAllPlatforms = true;
    binding.automaticPointerInterceptorsEnabled = true;

    final childUpdates = <Float64List>[];
    final childOwner = PipelineOwner(onHitTestRegionsUpdate: childUpdates.add);
    binding.rootPipelineOwner.adoptChild(childOwner);
    final childView = RenderView(
      configuration: _createViewConfiguration(),
      view: binding.platformDispatcher.views.single,
    );
    childOwner.rootNode = childView;
    childView.prepareInitialFrame();
    addTearDown(() {
      childOwner.rootNode = null;
      binding.rootPipelineOwner.dropChild(childOwner);
      childOwner.dispose();
    });

    childView.child = RenderStack(
      textDirection: TextDirection.ltr,
      children: <RenderBox>[
        _positioned(left: 0, top: 0, width: 300, height: 300, child: _createPlatformView(11)),
        _positioned(left: 5, top: 15, width: 40, height: 30, child: _createHitTarget()),
      ],
    );

    final stack = RenderStack(
      textDirection: TextDirection.ltr,
      children: <RenderBox>[
        _positioned(left: 0, top: 0, width: 300, height: 300, child: _createPlatformView(1)),
        _positioned(left: 10, top: 20, width: 100, height: 50, child: _createHitTarget()),
      ],
    );

    layout(stack, phase: EnginePhase.composite);
    binding.pumpCompleteFrame();

    expect(binding.rootPipelineOwner.debugLastHitTestRegions, isNotNull);
    expect(childOwner.debugLastHitTestRegions, isNotNull);
    expect(childUpdates, hasLength(1));
    expect(childUpdates.single, isNotEmpty);

    // Toggle off at runtime -> immediately clears debugLastHitTestRegions and sends Float64List(0).
    binding.automaticPointerInterceptorsEnabled = false;
    expect(binding.rootPipelineOwner.debugLastHitTestRegions, isNull);
    expect(childOwner.debugLastHitTestRegions, isNull);
    expect(childUpdates, hasLength(2));
    expect(childUpdates.last, isEmpty);
  });

  test(
    'toggling automaticPointerInterceptorsEnabled does not dispatch anything when the pass cannot run on this platform',
    () {
      final childUpdates = <Float64List>[];
      final childOwner = PipelineOwner(onHitTestRegionsUpdate: childUpdates.add);
      binding.rootPipelineOwner.adoptChild(childOwner);
      final childView = RenderView(
        configuration: _createViewConfiguration(),
        view: binding.platformDispatcher.views.single,
      );
      childOwner.rootNode = childView;
      childView.prepareInitialFrame();
      addTearDown(() {
        childOwner.rootNode = null;
        binding.rootPipelineOwner.dropChild(childOwner);
        childOwner.dispose();
      });

      childView.child = RenderStack(
        textDirection: TextDirection.ltr,
        children: <RenderBox>[
          _positioned(left: 0, top: 0, width: 300, height: 300, child: _createPlatformView(11)),
          _positioned(left: 5, top: 15, width: 40, height: 30, child: _createHitTarget()),
        ],
      );

      // Compute regions once with the debug override on, so that there is
      // something that a teardown could clear.
      debugEnableHitTestRegionsOnAllPlatforms = true;
      binding.automaticPointerInterceptorsEnabled = true;
      binding.pumpCompleteFrame();
      expect(childUpdates, hasLength(1));
      expect(childUpdates.single, isNotEmpty);

      // Without the override, a non-web platform never runs the pass, so
      // turning the flag off must not dispatch an (empty) update either.
      debugEnableHitTestRegionsOnAllPlatforms = false;
      binding.automaticPointerInterceptorsEnabled = false;
      expect(childUpdates, hasLength(1));

      // Turning the flag back on without the override does not run the pass.
      binding.automaticPointerInterceptorsEnabled = true;
      binding.pumpCompleteFrame();
      expect(childUpdates, hasLength(1));

      binding.automaticPointerInterceptorsEnabled = false;
      expect(childUpdates, hasLength(1));
    },
    skip: kIsWeb, // [intended] On the web, the pass always runs regardless of the debug override.
  );

  test('drops overlays clipped to empty intersection and does not overlap against completely clipped platform view', () {
    debugEnableHitTestRegionsOnAllPlatforms = true;
    binding.automaticPointerInterceptorsEnabled = true;

    // PV 1 is inside a 50x50 ClipRect at (0, 0), but translated to (200, 200) -> clipped to empty.
    final RenderBox clippedOutPv = RenderConstrainedBox(
      additionalConstraints: const BoxConstraints.tightFor(width: 50.0, height: 50.0),
      child: RenderClipRect(
        child: RenderTransform(
          transform: Matrix4.translationValues(200.0, 200.0, 0.0),
          child: RenderConstrainedBox(
            additionalConstraints: const BoxConstraints.tightFor(width: 100.0, height: 100.0),
            child: _createPlatformView(1),
          ),
        ),
      ),
    );
    // Overlay at (210, 210) would overlap PV 1's unclipped bounds, but PV 1 is clipped out.
    final RenderBox overlayOverUnclippedPv1 = _createHitTarget(width: 50, height: 50);

    // PV 2 is unclipped at (0, 0) to (300, 300).
    final PlatformViewRenderBox pv2 = _createPlatformView(2);
    // Overlay inside a 50x50 ClipRect at (10, 10), translated to (100, 100) -> disjoint from clip.
    final RenderBox clippedOutOverlay = RenderConstrainedBox(
      additionalConstraints: const BoxConstraints.tightFor(width: 50.0, height: 50.0),
      child: RenderClipRect(
        child: RenderTransform(
          transform: Matrix4.translationValues(100.0, 100.0, 0.0),
          child: _createHitTarget(width: 80, height: 40),
        ),
      ),
    );

    final stack = RenderStack(
      textDirection: TextDirection.ltr,
      children: <RenderBox>[
        _positioned(left: 0, top: 0, width: 50, height: 50, child: clippedOutPv),
        _positioned(left: 210, top: 210, width: 50, height: 50, child: overlayOverUnclippedPv1),
        _positioned(left: 0, top: 0, width: 300, height: 300, child: pv2),
        _positioned(left: 10, top: 10, width: 50, height: 50, child: clippedOutOverlay),
      ],
    );

    layout(stack, phase: EnginePhase.composite);
    binding.pumpCompleteFrame();

    expect(
      binding.rootPipelineOwner.debugLastHitTestRegions,
      equals(Float64List.fromList(<double>[1.0, 0.0, 2.0, 0.0])),
    );
  });

  test('RenderAbsorbPointer(absorbing: false) descends into child hit target and toggling to true claims own bounds', () {
    debugEnableHitTestRegionsOnAllPlatforms = true;
    binding.automaticPointerInterceptorsEnabled = true;

    final PlatformViewRenderBox pv = _createPlatformView(1);
    final absorbPointer = RenderAbsorbPointer(
      absorbing: false,
      child: RenderStack(
        textDirection: TextDirection.ltr,
        children: <RenderBox>[
          _positioned(left: 10, top: 15, width: 60, height: 40, child: _createHitTarget()),
        ],
      ),
    );

    final stack = RenderStack(
      textDirection: TextDirection.ltr,
      children: <RenderBox>[
        _positioned(left: 0, top: 0, width: 400, height: 400, child: pv),
        _positioned(left: 20, top: 30, width: 200, height: 150, child: absorbPointer),
      ],
    );

    layout(stack, phase: EnginePhase.composite);
    binding.pumpCompleteFrame();

    // When absorbing is false, only the inner child rect [30, 45, 90, 85] is claimed.
    expect(
      binding.rootPipelineOwner.debugLastHitTestRegions,
      equals(Float64List.fromList(<double>[1.0, 1.0, 30.0, 45.0, 90.0, 85.0])),
    );

    // Toggling absorbing to true claims the RenderAbsorbPointer bounds [20, 30, 220, 180]
    // and its children no longer claim.
    absorbPointer.absorbing = true;
    binding.pumpCompleteFrame();
    expect(
      binding.rootPipelineOwner.debugLastHitTestRegions,
      equals(Float64List.fromList(<double>[1.0, 1.0, 20.0, 30.0, 220.0, 180.0])),
    );
  });

  test('zero-sized PlatformViewRenderBox does not emit a group and zero-sized overlay over valid platform view is dropped', () {
    debugEnableHitTestRegionsOnAllPlatforms = true;
    binding.automaticPointerInterceptorsEnabled = true;

    final PlatformViewRenderBox zeroPv = _createPlatformView(1);
    final RenderBox validOverlay = _createHitTarget(width: 100, height: 50);

    final stack = RenderStack(
      textDirection: TextDirection.ltr,
      children: <RenderBox>[
        _positioned(left: 0, top: 0, width: 0, height: 0, child: zeroPv),
        _positioned(left: 0, top: 0, width: 100, height: 50, child: validOverlay),
      ],
    );

    layout(stack, phase: EnginePhase.composite);
    binding.pumpCompleteFrame();

    // Only a zero-sized platform view is present -> returns null.
    expect(binding.rootPipelineOwner.debugLastHitTestRegions, isNull);

    // Add a valid platform view (id 2) and a zero-sized overlay on top of it.
    final PlatformViewRenderBox validPv = _createPlatformView(2);
    final RenderBox zeroOverlay = _createHitTarget(width: 0, height: 0);
    stack.add(_positioned(left: 0, top: 0, width: 300, height: 300, child: validPv));
    stack.add(_positioned(left: 50, top: 50, width: 0, height: 0, child: zeroOverlay));

    pumpFrame(phase: EnginePhase.composite);
    binding.pumpCompleteFrame();

    // Zero-sized PV 1 is omitted and zero-sized overlay over PV 2 is dropped.
    expect(
      binding.rootPipelineOwner.debugLastHitTestRegions,
      equals(Float64List.fromList(<double>[2.0, 0.0])),
    );
  });
}
