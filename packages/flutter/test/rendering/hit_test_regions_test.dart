// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../services/fake_platform_views.dart';
import 'rendering_tester.dart';

/// Gives [child] the stack parent data that places it exactly at [rect].
RenderBox _at(Rect rect, RenderBox child) {
  child.parentData = StackParentData()
    ..left = rect.left
    ..top = rect.top
    ..width = rect.width
    ..height = rect.height;
  return child;
}

RenderStack _stack(List<RenderBox> children) {
  return RenderStack(textDirection: TextDirection.ltr, children: children);
}

PlatformViewRenderBox _platformView(int viewId) {
  return PlatformViewRenderBox(
    controller: FakePlatformViewController(viewId),
    hitTestBehavior: PlatformViewHitTestBehavior.opaque,
    gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
  );
}

/// A box that fills its (tight) constraints and, when opaque, accepts pointer
/// events everywhere, so it claims its bounds wherever it covers a platform
/// view.
RenderBox _hitTarget({HitTestBehavior behavior = HitTestBehavior.opaque}) {
  return RenderPointerListener(behavior: behavior);
}

/// The payload expected for [groups], given in paint order as
/// `(platformViewId, claimedRects)`: for each group, the ID, the number of
/// rects, and then each rect's left, top, right and bottom multiplied by
/// [scale] (the device pixel ratio).
Float64List _payload(List<(int, List<Rect>)> groups, {double scale = 1.0}) {
  return Float64List.fromList(<double>[
    for (final (int viewId, List<Rect> rects) in groups) ...<double>[
      viewId.toDouble(),
      rects.length.toDouble(),
      for (final Rect rect in rects) ...<double>[
        rect.left * scale,
        rect.top * scale,
        rect.right * scale,
        rect.bottom * scale,
      ],
    ],
  ]);
}

/// A proxy box whose [hitTestsChildren] is read from [childrenHitTestable],
/// so pointer events reach its child only while that is true.
///
/// It is not a render object type the framework knows about, so the
/// hit-test region pass can only learn about its children through
/// [hitTestsChildren].
class _RenderChildHitTestGate extends RenderProxyBoxWithHitTestBehavior {
  _RenderChildHitTestGate({required this.childrenHitTestable, super.behavior, super.child});

  bool childrenHitTestable;

  @override
  bool get hitTestsChildren => childrenHitTestable;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return childrenHitTestable && super.hitTestChildren(result, position: position);
  }
}

ViewConfiguration _viewConfiguration({double devicePixelRatio = 1.0}) {
  final logicalConstraints = BoxConstraints.tight(const Size(800.0, 600.0));
  return ViewConfiguration(
    logicalConstraints: logicalConstraints,
    physicalConstraints: logicalConstraints * devicePixelRatio,
    devicePixelRatio: devicePixelRatio,
  );
}

/// A [TestRenderingFlutterBinding] whose [drawFrame] can skip calling
/// `super.drawFrame()`, to verify that the hit-test region pass is driven by
/// [drawFrame] rather than by a separate persistent frame callback.
class _TestRenderingBinding extends TestRenderingFlutterBinding {
  bool skipSuperDrawFrame = false;

  @override
  void drawFrame() {
    if (skipSuperDrawFrame) {
      rootPipelineOwner.flushLayout();
      rootPipelineOwner.flushCompositingBits();
      rootPipelineOwner.flushPaint();
      for (final RenderView renderView in renderViews) {
        renderView.compositeFrame();
      }
      return;
    }
    super.drawFrame();
  }
}

void main() {
  final binding = _TestRenderingBinding();
  late ViewConfiguration initialConfiguration;

  setUp(() {
    initialConfiguration = binding.renderView.configuration;
    binding.renderView.configuration = _viewConfiguration();
    debugEnableHitTestRegionsOnAllPlatforms = true;
    binding.automaticPointerInterceptorsEnabled = true;
  });

  tearDown(() {
    binding.skipSuperDrawFrame = false;
    binding.phase = EnginePhase.composite;
    binding.automaticPointerInterceptorsEnabled = false;
    debugEnableHitTestRegionsOnAllPlatforms = false;
    binding.renderView.configuration = initialConfiguration;
    // Detach this test's platform views from the root pipeline owner.
    binding.renderView.child = null;
  });

  /// Runs a full binding frame, which runs the hit-test region pass during
  /// drawFrame, and returns the payload computed for the root view.
  Float64List? regionsAfterFrame() {
    binding.pumpCompleteFrame();
    return binding.rootPipelineOwner.debugLastHitTestRegions;
  }

  Float64List? regionsFor(RenderBox root) {
    layout(root, phase: EnginePhase.composite);
    return binding.rootPipelineOwner.debugLastHitTestRegions;
  }

  /// Creates a pipeline owner for a view showing [child] that records every
  /// payload it is sent in [updates], adopted by [parent] (if any) as in a
  /// multi-view app.
  PipelineOwner createViewOwner(
    RenderBox child,
    List<Float64List> updates, {
    PipelineOwner? parent,
  }) {
    final owner = PipelineOwner(onHitTestRegionsUpdate: updates.add);
    parent?.adoptChild(owner);
    final view = RenderView(
      configuration: _viewConfiguration(),
      view: binding.platformDispatcher.views.single,
    );
    owner.rootNode = view;
    view.prepareInitialFrame();
    view.child = child;
    addTearDown(() {
      view.child = null;
      owner.rootNode = null;
      view.dispose();
      parent?.dropChild(owner);
      owner.dispose();
    });
    return owner;
  }

  group('gating and delivery', () {
    test('the pass does not run while the flag is off, nor off the web without the debug flag', () {
      FlutterTimeline.debugCollectionEnabled = true;
      addTearDown(() {
        FlutterTimeline.debugReset();
        FlutterTimeline.debugCollectionEnabled = false;
      });
      const claim = Rect.fromLTWH(10, 20, 100, 50);
      binding.automaticPointerInterceptorsEnabled = false;
      final RenderStack root = _stack(<RenderBox>[
        _at(const Rect.fromLTWH(0, 0, 400, 400), _platformView(1)),
        _at(claim, _hitTarget()),
      ]);
      expect(regionsFor(root), isNull);
      expect(FlutterTimeline.debugCollect().getAggregated('HIT TEST REGIONS (root)').count, 0);

      if (!kIsWeb) {
        debugEnableHitTestRegionsOnAllPlatforms = false;
        binding.automaticPointerInterceptorsEnabled = true;
        expect(regionsAfterFrame(), isNull);
        expect(FlutterTimeline.debugCollect().getAggregated('HIT TEST REGIONS (root)').count, 0);
      }

      debugEnableHitTestRegionsOnAllPlatforms = true;
      binding.automaticPointerInterceptorsEnabled = true;
      expect(
        regionsAfterFrame(),
        _payload(<(int, List<Rect>)>[
          (1, <Rect>[claim]),
        ]),
      );
      expect(FlutterTimeline.debugCollect().getAggregated('HIT TEST REGIONS (root)').count, 1);
    });

    test(
      'runs in the composite phase of drawFrame, after compositing, and not in the paint phase',
      () {
        final link = LayerLink();
        const followerOffset = Offset(10, 15);
        const size = Size(80, 40);
        final RenderBox leader = _at(const Offset(40, 50) & size, RenderLeaderLayer(link: link));
        final RenderStack root = _stack(<RenderBox>[
          _at(const Rect.fromLTWH(0, 0, 400, 400), _platformView(1)),
          leader,
          _at(
            Offset.zero & size,
            RenderFollowerLayer(link: link, offset: followerOffset, child: _hitTarget()),
          ),
        ]);

        // Stopping at paint computes no regions, even across a full frame
        // lifecycle.
        layout(root, phase: EnginePhase.paint);
        expect(binding.rootPipelineOwner.debugLastHitTestRegions, isNull);
        binding.pumpCompleteFrame();
        expect(binding.rootPipelineOwner.debugLastHitTestRegions, isNull);

        // Pumping through composite in drawFrame composites the follower layer
        // first and then computes regions using that frame's leader position.
        pumpFrame(phase: EnginePhase.composite);
        expect(
          binding.rootPipelineOwner.debugLastHitTestRegions,
          _payload(<(int, List<Rect>)>[
            (1, <Rect>[(const Offset(40, 50) + followerOffset) & size]),
          ]),
        );

        // Moving the leader and stopping at paint leaves the previous composite
        // payload untouched until composite runs again.
        (leader.parentData! as StackParentData)
          ..left = 120
          ..top = 140;
        root.markNeedsLayout();
        pumpFrame(phase: EnginePhase.paint);
        binding.pumpCompleteFrame();
        expect(
          binding.rootPipelineOwner.debugLastHitTestRegions,
          _payload(<(int, List<Rect>)>[
            (1, <Rect>[(const Offset(40, 50) + followerOffset) & size]),
          ]),
        );

        pumpFrame(phase: EnginePhase.composite);
        expect(
          binding.rootPipelineOwner.debugLastHitTestRegions,
          _payload(<(int, List<Rect>)>[
            (1, <Rect>[(const Offset(120, 140) + followerOffset) & size]),
          ]),
        );
      },
    );

    test(
      'a RendererBinding subclass whose drawFrame skips super.drawFrame computes no regions',
      () {
        binding.skipSuperDrawFrame = true;
        const claim = Rect.fromLTWH(10, 20, 100, 50);
        layout(
          _stack(<RenderBox>[
            _at(const Rect.fromLTWH(0, 0, 400, 400), _platformView(1)),
            _at(claim, _hitTarget()),
          ]),
          phase: EnginePhase.composite,
        );
        binding.pumpCompleteFrame();
        expect(binding.rootPipelineOwner.debugLastHitTestRegions, isNull);

        binding.skipSuperDrawFrame = false;
        binding.pumpCompleteFrame();
        expect(
          binding.rootPipelineOwner.debugLastHitTestRegions,
          _payload(<(int, List<Rect>)>[
            (1, <Rect>[claim]),
          ]),
        );
      },
    );

    test(
      'sends regions while a platform view is attached, then one empty payload after it detaches',
      () {
        final updates = <Float64List>[];
        final RenderStack root = _stack(<RenderBox>[
          _at(const Rect.fromLTWH(10, 20, 100, 50), _hitTarget()),
        ]);
        final PipelineOwner owner = createViewOwner(root, updates);
        void flush() {
          owner.flushLayout();
          owner.flushHitTestRegions();
        }

        flush();
        expect(owner.debugLastHitTestRegions, isNull);
        expect(updates, isEmpty);

        // Insert a platform view below the hit target.
        final PlatformViewRenderBox platformView = _platformView(7);
        root.insert(_at(const Rect.fromLTWH(0, 0, 300, 300), platformView));
        flush();
        // [viewId, rectCount, left, top, right, bottom]
        final expected = Float64List.fromList(<double>[7, 1, 10, 20, 110, 70]);
        expect(owner.debugLastHitTestRegions, expected);
        expect(updates, <Float64List>[expected]);

        // The empty payload tells the engine to drop its regions, but is only
        // sent once.
        root.remove(platformView);
        flush();
        flush();
        expect(owner.debugLastHitTestRegions, isNull);
        expect(updates, <Float64List>[expected, Float64List(0)]);
      },
    );

    test(
      'flushHitTestRegions and clearHitTestRegions recurse from an owner without a render tree',
      () {
        // In a multi-view app the root pipeline owner has no render tree; each
        // view's child owner tracks its own platform views.
        final root = PipelineOwner();
        addTearDown(root.dispose);
        final updates1 = <Float64List>[];
        final updates2 = <Float64List>[];
        const claim1 = Rect.fromLTWH(10, 20, 50, 40);
        const claim2 = Rect.fromLTWH(30, 40, 70, 60);
        final PipelineOwner owner1 = createViewOwner(
          _stack(<RenderBox>[
            _at(const Rect.fromLTWH(0, 0, 300, 300), _platformView(1)),
            _at(claim1, _hitTarget()),
          ]),
          updates1,
          parent: root,
        );
        final PipelineOwner owner2 = createViewOwner(
          _stack(<RenderBox>[
            _at(const Rect.fromLTWH(0, 0, 300, 300), _platformView(2)),
            _at(claim2, _hitTarget()),
          ]),
          updates2,
          parent: root,
        );

        root.flushLayout();
        root.flushHitTestRegions();
        expect(updates1, <Float64List>[
          _payload(<(int, List<Rect>)>[
            (1, <Rect>[claim1]),
          ]),
        ]);
        expect(updates2, <Float64List>[
          _payload(<(int, List<Rect>)>[
            (2, <Rect>[claim2]),
          ]),
        ]);

        root.clearHitTestRegions();
        expect(owner1.debugLastHitTestRegions, isNull);
        expect(owner2.debugLastHitTestRegions, isNull);
        expect(updates1.last, isEmpty);
        expect(updates2.last, isEmpty);
      },
    );

    test('turning the flag off immediately sends every view an empty payload', () {
      final updates = <Float64List>[];
      final PipelineOwner owner = createViewOwner(
        _stack(<RenderBox>[
          _at(const Rect.fromLTWH(0, 0, 300, 300), _platformView(1)),
          _at(const Rect.fromLTWH(5, 15, 40, 30), _hitTarget()),
        ]),
        updates,
        parent: binding.rootPipelineOwner,
      );
      binding.pumpCompleteFrame();
      expect(updates.single, isNotEmpty);

      // No frame is pumped: the setter itself clears the regions.
      binding.automaticPointerInterceptorsEnabled = false;
      expect(owner.debugLastHitTestRegions, isNull);
      expect(updates, hasLength(2));
      expect(updates.last, isEmpty);
    });

    test(
      'toggling the flag sends nothing on a platform where the pass never runs',
      () {
        final updates = <Float64List>[];
        createViewOwner(
          _stack(<RenderBox>[
            _at(const Rect.fromLTWH(0, 0, 300, 300), _platformView(1)),
            _at(const Rect.fromLTWH(5, 15, 40, 30), _hitTarget()),
          ]),
          updates,
          parent: binding.rootPipelineOwner,
        );

        debugEnableHitTestRegionsOnAllPlatforms = false;
        binding.automaticPointerInterceptorsEnabled = false;
        binding.automaticPointerInterceptorsEnabled = true;
        binding.pumpCompleteFrame();
        binding.automaticPointerInterceptorsEnabled = false;
        expect(updates, isEmpty);
      },
      skip: kIsWeb, // [intended] On the web, the pass always runs.
    );

    test('skips layout and compositingBits phases, and flushes between composite and semantics in later phases', () async {
      final SemanticsHandle semantics = binding.ensureSemantics();
      FlutterTimeline.debugCollectionEnabled = true;
      addTearDown(() {
        semantics.dispose();
        FlutterTimeline.debugReset();
        FlutterTimeline.debugCollectionEnabled = false;
      });

      const firstClaim = Rect.fromLTWH(10, 20, 100, 50);
      const secondClaim = Rect.fromLTWH(40, 60, 100, 50);
      const thirdClaim = Rect.fromLTWH(70, 90, 100, 50);
      final RenderBox annotatedTarget = _at(
        firstClaim,
        RenderSemanticsAnnotations(
          properties: const SemanticsProperties(label: 'tap', button: true),
          container: true,
          textDirection: TextDirection.ltr,
          child: _hitTarget(),
        ),
      );
      final RenderStack root = _stack(<RenderBox>[
        _at(const Rect.fromLTWH(0, 0, 400, 400), _platformView(1)),
        annotatedTarget,
      ]);

      // layout() defaults to EnginePhase.layout.
      layout(root);
      binding.pumpCompleteFrame();
      expect(binding.rootPipelineOwner.debugLastHitTestRegions, isNull);

      pumpFrame(phase: EnginePhase.compositingBits);
      binding.pumpCompleteFrame();
      expect(binding.rootPipelineOwner.debugLastHitTestRegions, isNull);

      List<String> phaseOrder() {
        const tracked = <String>{'COMPOSITING', 'HIT TEST REGIONS (root)', 'SEMANTICS (root)'};
        return <String>[
          for (final TimedBlock block in FlutterTimeline.debugCollect().timedBlocks)
            if (tracked.contains(block.name)) block.name,
        ];
      }

      FlutterTimeline.debugReset();
      pumpFrame(phase: EnginePhase.flushSemantics);
      expect(
        binding.rootPipelineOwner.debugLastHitTestRegions,
        _payload(<(int, List<Rect>)>[
          (1, <Rect>[firstClaim]),
        ]),
      );
      expect(phaseOrder(), <String>['COMPOSITING', 'HIT TEST REGIONS (root)', 'SEMANTICS (root)']);

      (annotatedTarget.parentData! as StackParentData)
        ..left = secondClaim.left
        ..top = secondClaim.top;
      root.markNeedsLayout();
      FlutterTimeline.debugReset();
      pumpFrame(phase: EnginePhase.sendSemanticsUpdate);
      expect(
        binding.rootPipelineOwner.debugLastHitTestRegions,
        _payload(<(int, List<Rect>)>[
          (1, <Rect>[secondClaim]),
        ]),
      );
      expect(phaseOrder(), <String>['COMPOSITING', 'HIT TEST REGIONS (root)', 'SEMANTICS (root)']);

      // EnginePhase.sendSemanticsUpdate delegates to RendererBinding.drawFrame,
      // which respects sendFramesToEngine while the first frame is deferred.
      (annotatedTarget.parentData! as StackParentData)
        ..left = thirdClaim.left
        ..top = thirdClaim.top;
      root.markNeedsLayout();
      binding.resetFirstFrameSent();
      var deferred = true;
      binding.deferFirstFrame();
      addTearDown(() {
        if (deferred) {
          binding.allowFirstFrame();
        }
      });
      FlutterTimeline.debugReset();
      pumpFrame(phase: EnginePhase.sendSemanticsUpdate);
      expect(binding.sendFramesToEngine, isFalse);
      expect(
        binding.rootPipelineOwner.debugLastHitTestRegions,
        _payload(<(int, List<Rect>)>[
          (1, <Rect>[secondClaim]),
        ]),
      );
      expect(phaseOrder(), isEmpty);

      FlutterTimeline.debugReset();
      binding.allowFirstFrame();
      deferred = false;
      await binding.endOfFrame;
      expect(binding.sendFramesToEngine, isTrue);
      expect(
        binding.rootPipelineOwner.debugLastHitTestRegions,
        _payload(<(int, List<Rect>)>[
          (1, <Rect>[thirdClaim]),
        ]),
      );
      expect(phaseOrder(), <String>['COMPOSITING', 'HIT TEST REGIONS (root)', 'SEMANTICS (root)']);
    });

    test('rapidly toggling the flag schedules frames only on changes and avoids duplicate empty payloads', () {
      final updates1 = <Float64List>[];
      final updates2 = <Float64List>[];
      const claim1 = Rect.fromLTWH(10, 20, 50, 40);
      const claim2 = Rect.fromLTWH(30, 40, 70, 60);
      final PlatformViewRenderBox pv2 = _platformView(2);
      final RenderStack root2 = _stack(<RenderBox>[
        _at(const Rect.fromLTWH(0, 0, 300, 300), pv2),
        _at(claim2, _hitTarget()),
      ]);
      final PipelineOwner owner1 = createViewOwner(
        _stack(<RenderBox>[
          _at(const Rect.fromLTWH(0, 0, 300, 300), _platformView(1)),
          _at(claim1, _hitTarget()),
        ]),
        updates1,
        parent: binding.rootPipelineOwner,
      );
      final PipelineOwner owner2 = createViewOwner(
        root2,
        updates2,
        parent: binding.rootPipelineOwner,
      );

      binding.pumpCompleteFrame();
      final Float64List expected1 = _payload(<(int, List<Rect>)>[
        (1, <Rect>[claim1]),
      ]);
      final Float64List expected2 = _payload(<(int, List<Rect>)>[
        (2, <Rect>[claim2]),
      ]);
      expect(updates1, <Float64List>[expected1]);
      expect(updates2, <Float64List>[expected2]);
      expect(binding.hasScheduledFrame, isFalse);

      // Setting the flag to its current value is a no-op.
      binding.automaticPointerInterceptorsEnabled = true;
      expect(binding.hasScheduledFrame, isFalse);
      expect(owner1.debugLastHitTestRegions, expected1);
      expect(updates1, hasLength(1));

      // Flipping false -> false -> true within the same frame clears once,
      // schedules a frame, and resets each owner's non-empty tracking so a
      // platform view detached before the next frame sends no second empty
      // payload.
      binding.automaticPointerInterceptorsEnabled = false;
      binding.automaticPointerInterceptorsEnabled = false;
      binding.automaticPointerInterceptorsEnabled = true;
      expect(binding.hasScheduledFrame, isTrue);
      expect(owner1.debugLastHitTestRegions, isNull);
      expect(owner2.debugLastHitTestRegions, isNull);
      expect(updates1, <Float64List>[expected1, Float64List(0)]);
      expect(updates2, <Float64List>[expected2, Float64List(0)]);

      root2.remove(pv2);
      binding.phase = EnginePhase.paint;
      binding.pumpCompleteFrame();
      expect(updates1, hasLength(2));
      expect(updates2, hasLength(2));

      binding.phase = EnginePhase.composite;
      binding.pumpCompleteFrame();
      expect(updates1, <Float64List>[expected1, Float64List(0), expected1]);
      expect(updates2, <Float64List>[expected2, Float64List(0)]);
    });
  });

  group('geometry', () {
    test('only content painted after and over a platform view claims, in physical pixels', () {
      binding.renderView.configuration = _viewConfiguration(devicePixelRatio: 2.0);
      const overPlatformView = Rect.fromLTWH(10, 20, 100, 50);
      final Float64List? regions = regionsFor(
        _stack(<RenderBox>[
          _at(const Rect.fromLTWH(10, 20, 80, 40), _hitTarget()), // Painted below it.
          _at(const Rect.fromLTWH(0, 0, 300, 300), _platformView(1)),
          _at(overPlatformView, _hitTarget()),
          _at(const Rect.fromLTWH(400, 400, 50, 50), _hitTarget()), // Beside it.
        ]),
      );
      expect(
        regions,
        _payload(<(int, List<Rect>)>[
          (1, <Rect>[overPlatformView]),
        ], scale: 2.0),
      );
    });

    test(
      'claims are transformed and clipped by ancestors, but not clipped to the platform view',
      () {
        // Sent whole even though it overhangs the platform view; the engine may
        // clip it.
        const overhangingClaim = Rect.fromLTWH(0, 0, 300, 300);
        final Float64List? regions = regionsFor(
          _stack(<RenderBox>[
            _at(const Rect.fromLTWH(100, 100, 50, 50), _platformView(1)),
            _at(overhangingClaim, _hitTarget()),
            // A 60x60 clip at (100, 100) around a 60x60 box translated by
            // (30, 30): only (130, 130)-(160, 160) remains visible.
            _at(
              const Rect.fromLTWH(100, 100, 60, 60),
              RenderClipRect(
                child: RenderTransform(
                  transform: Matrix4.translationValues(30, 30, 0),
                  child: _hitTarget(),
                ),
              ),
            ),
          ]),
        );
        expect(
          regions,
          _payload(<(int, List<Rect>)>[
            (1, <Rect>[overhangingClaim, const Rect.fromLTRB(130, 130, 160, 160)]),
          ]),
        );
      },
    );

    test('content clipped away entirely neither claims nor counts as a covered platform view', () {
      // Translates [child] out of its parent's bounds and clips it away.
      RenderBox clippedAway(RenderBox child) => RenderClipRect(
        child: RenderTransform(transform: Matrix4.translationValues(200, 200, 0), child: child),
      );
      final Float64List? regions = regionsFor(
        _stack(<RenderBox>[
          // Would be at (200, 200)-(250, 250) without the clip.
          _at(const Rect.fromLTWH(0, 0, 50, 50), clippedAway(_platformView(1))),
          _at(const Rect.fromLTWH(210, 210, 50, 50), _hitTarget()),
          _at(const Rect.fromLTWH(0, 0, 300, 300), _platformView(2)),
          // Would be at (210, 210)-(260, 260), over platform view 2, without
          // the clip.
          _at(const Rect.fromLTWH(10, 10, 50, 50), clippedAway(_hitTarget())),
        ]),
      );
      expect(regions, _payload(<(int, List<Rect>)>[(1, <Rect>[]), (2, <Rect>[])]));
    });

    test('empty platform views start no group and empty boxes claim nothing', () {
      final RenderStack root = _stack(<RenderBox>[
        _at(Rect.zero, _platformView(1)),
        _at(const Rect.fromLTWH(0, 0, 100, 50), _hitTarget()),
      ]);
      expect(regionsFor(root), isNull);

      root
        ..add(_at(const Rect.fromLTWH(0, 0, 300, 300), _platformView(2)))
        ..add(_at(const Rect.fromLTWH(50, 50, 0, 0), _hitTarget()));
      expect(regionsAfterFrame(), _payload(<(int, List<Rect>)>[(2, <Rect>[])]));
    });

    test('boxes scaled to zero or only touching a platform view edge claim nothing', () {
      const pvRect = Rect.fromLTRB(100, 100, 300, 300);
      const claim = Rect.fromLTWH(120, 120, 80, 40);
      final RenderStack root = _stack(<RenderBox>[
        _at(pvRect, _platformView(1)),
        // Non-empty boxes over the platform view collapsed by zero-scale or
        // singular 2D transforms.
        _at(
          claim,
          RenderTransform(transform: Matrix4.diagonal3Values(0, 1, 1), child: _hitTarget()),
        ),
        _at(
          claim,
          RenderTransform(transform: Matrix4.diagonal3Values(1, 0, 1), child: _hitTarget()),
        ),
        _at(
          claim,
          RenderTransform(
            transform: Matrix4(1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1),
            child: _hitTarget(),
          ),
        ),
        _at(
          claim,
          RenderTransform(
            transform: Matrix4(0, 0, 1, 0, 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 0, 1),
            child: _hitTarget(),
          ),
        ),
        // Boxes sharing an exact edge or corner with pvRect, without interior overlap.
        _at(const Rect.fromLTRB(50, 100, 100, 300), _hitTarget()),
        _at(const Rect.fromLTRB(100, 50, 300, 100), _hitTarget()),
        _at(const Rect.fromLTRB(300, 100, 350, 300), _hitTarget()),
        _at(const Rect.fromLTRB(100, 300, 300, 350), _hitTarget()),
        _at(const Rect.fromLTRB(300, 300, 350, 350), _hitTarget()),
      ]);
      expect(regionsFor(root), _payload(<(int, List<Rect>)>[(1, <Rect>[])]));

      const onePixelOverlap = Rect.fromLTRB(299, 299, 350, 350);
      root.add(_at(onePixelOverlap, _hitTarget()));
      expect(
        regionsAfterFrame(),
        _payload(<(int, List<Rect>)>[
          (1, <Rect>[onePixelOverlap]),
        ]),
      );

      // Zero-scaled or Matrix4.zero() platform views alone start no group.
      expect(
        regionsFor(
          _stack(<RenderBox>[
            _at(
              pvRect,
              RenderTransform(transform: Matrix4.diagonal3Values(0, 1, 1), child: _platformView(1)),
            ),
            _at(pvRect, RenderTransform(transform: Matrix4.zero(), child: _platformView(2))),
          ]),
        ),
        isNull,
      );

      // A zero-scaled platform view between PV1 and a later overlapping box
      // starts no group, so the box remains attributed to PV1.
      expect(
        regionsFor(
          _stack(<RenderBox>[
            _at(pvRect, _platformView(1)),
            _at(
              pvRect,
              RenderTransform(transform: Matrix4.diagonal3Values(0, 1, 1), child: _platformView(2)),
            ),
            _at(claim, _hitTarget()),
          ]),
        ),
        _payload(<(int, List<Rect>)>[
          (1, <Rect>[claim]),
        ]),
      );

      // An unlaid-out root RenderClipRect returns null without throwing inside
      // describeApproximatePaintClip.
      final PlatformViewRenderBox laidOutPv = _platformView(1);
      layout(laidOutPv);
      binding.renderView.child = null;
      final unlaidOutRoot = RenderClipRect(child: laidOutPv);
      final unlaidOutOwner = PipelineOwner()..rootNode = unlaidOutRoot;
      addTearDown(() {
        unlaidOutOwner.rootNode = null;
        unlaidOutRoot.child = null;
        unlaidOutOwner.dispose();
      });
      unlaidOutOwner.flushHitTestRegions();
      expect(unlaidOutOwner.debugLastHitTestRegions, isNull);
    });

    test('claims are grouped under the platform view painted most recently before them', () {
      // Platform view 1 under a modal barrier and a dialog that contains
      // platform view 2.
      const buttonOverPv1 = Rect.fromLTWH(20, 30, 80, 40);
      const barrier = Rect.fromLTWH(0, 0, 800, 600);
      const dialogHeader = Rect.fromLTWH(100, 100, 200, 40);
      const buttonOverPv2 = Rect.fromLTWH(120, 160, 50, 30);
      // Painted after platform view 2 but only overlaps platform view 1; it is
      // still grouped under platform view 2, which is directly beneath it in
      // paint order.
      const onlyOverPv1 = Rect.fromLTWH(320, 20, 40, 40);
      final Float64List? regions = regionsFor(
        _stack(<RenderBox>[
          _at(const Rect.fromLTWH(0, 0, 400, 400), _platformView(1)),
          _at(buttonOverPv1, _hitTarget()),
          _at(barrier, _hitTarget()),
          _at(dialogHeader, _hitTarget()),
          _at(const Rect.fromLTWH(100, 140, 200, 200), _platformView(2)),
          _at(buttonOverPv2, _hitTarget()),
          _at(onlyOverPv1, _hitTarget()),
        ]),
      );
      expect(
        regions,
        _payload(<(int, List<Rect>)>[
          (1, <Rect>[buttonOverPv1, barrier, dialogHeader]),
          (2, <Rect>[buttonOverPv2, onlyOverPv1]),
        ]),
      );
    });
  });

  group('claim rules', () {
    test('ignored, translucent and offstage content claims nothing', () {
      const overlay = Rect.fromLTWH(10, 20, 100, 50);
      final Float64List? regions = regionsFor(
        _stack(<RenderBox>[
          _at(const Rect.fromLTWH(0, 0, 400, 400), _platformView(1)),
          _at(overlay, RenderIgnorePointer(child: _hitTarget())),
          _at(overlay, _hitTarget(behavior: HitTestBehavior.translucent)),
          _at(overlay, RenderOffstage(child: _hitTarget())),
          // Offstage platform views are not painted, so they start no group.
          _at(overlay, RenderOffstage(child: _platformView(2))),
        ]),
      );
      expect(regions, _payload(<(int, List<Rect>)>[(1, <Rect>[])]));
    });

    test(
      'an AbsorbPointer claims its own bounds, instead of its children, only while absorbing',
      () {
        const absorberRect = Rect.fromLTWH(20, 30, 200, 150);
        final absorber = RenderAbsorbPointer(
          absorbing: false,
          child: _stack(<RenderBox>[_at(const Rect.fromLTWH(10, 15, 60, 40), _hitTarget())]),
        );
        final RenderStack root = _stack(<RenderBox>[
          _at(const Rect.fromLTWH(0, 0, 400, 400), _platformView(1)),
          _at(absorberRect, absorber),
        ]);
        expect(
          regionsFor(root),
          _payload(<(int, List<Rect>)>[
            (1, <Rect>[const Rect.fromLTWH(30, 45, 60, 40)]),
          ]),
        );

        // Toggling absorbing marks nothing as needing layout or paint; the next
        // frame's pass still sees the new value.
        absorber.absorbing = true;
        expect(
          regionsAfterFrame(),
          _payload(<(int, List<Rect>)>[
            (1, <Rect>[absorberRect]),
          ]),
        );
      },
    );

    test('a platform view inside an ignoring IgnorePointer still starts a group', () {
      // The browser still sends it pointer events, so content painted over it
      // must claim them.
      const overlay = Rect.fromLTWH(25, 35, 100, 60);
      final Float64List? regions = regionsFor(
        _stack(<RenderBox>[
          _at(
            const Rect.fromLTWH(0, 0, 300, 300),
            RenderIgnorePointer(
              child: _stack(<RenderBox>[
                _at(const Rect.fromLTWH(0, 0, 300, 300), _platformView(1)),
                _at(const Rect.fromLTWH(10, 10, 80, 80), _hitTarget()), // Ignored.
              ]),
            ),
          ),
          _at(overlay, _hitTarget()),
        ]),
      );
      expect(
        regions,
        _payload(<(int, List<Rect>)>[
          (1, <Rect>[overlay]),
        ]),
      );
    });

    test('a platform view inside an absorbing AbsorbPointer still starts a group', () {
      const absorber = Rect.fromLTWH(100, 100, 200, 200);
      const barrier = Rect.fromLTWH(0, 0, 800, 600);
      final Float64List? regions = regionsFor(
        _stack(<RenderBox>[
          _at(const Rect.fromLTWH(0, 0, 400, 400), _platformView(1)),
          _at(
            absorber,
            RenderAbsorbPointer(
              child: _stack(<RenderBox>[
                _at(const Rect.fromLTWH(0, 0, 200, 200), _platformView(2)),
                _at(const Rect.fromLTWH(10, 10, 40, 40), _hitTarget()), // Absorbed.
              ]),
            ),
          ),
          _at(barrier, _hitTarget()),
        ]),
      );
      expect(
        regions,
        _payload(<(int, List<Rect>)>[
          (1, <Rect>[absorber]),
          (2, <Rect>[barrier]),
        ]),
      );
    });

    test('descendants of a render object whose hitTestsChildren is false claim nothing, '
        'but platform views among them still start groups', () {
      const opaqueOverPv1 = Rect.fromLTWH(60, 60, 60, 40);
      const nestedOverPv2 = Rect.fromLTWH(160, 160, 40, 40);
      const overlay = Rect.fromLTWH(250, 250, 100, 100);
      final gate = _RenderChildHitTestGate(
        childrenHitTestable: false,
        child: _stack(<RenderBox>[
          _at(const Rect.fromLTWH(10, 10, 60, 40), _hitTarget()),
          _at(const Rect.fromLTWH(100, 100, 150, 150), _platformView(2)),
          // Its own hitTestsChildren is true, but its ancestor's is not.
          _at(
            const Rect.fromLTWH(110, 110, 40, 40),
            _RenderChildHitTestGate(childrenHitTestable: true, child: _hitTarget()),
          ),
        ]),
      );
      final RenderStack root = _stack(<RenderBox>[
        _at(const Rect.fromLTWH(0, 0, 400, 400), _platformView(1)),
        _at(const Rect.fromLTWH(50, 50, 300, 300), gate),
        _at(overlay, _hitTarget()),
      ]);
      expect(
        regionsFor(root),
        _payload(<(int, List<Rect>)>[
          (1, <Rect>[]),
          (2, <Rect>[overlay]),
        ]),
      );

      // Changing hitTestsChildren marks nothing as needing layout or paint;
      // the next frame's pass still sees the new value.
      gate.childrenHitTestable = true;
      expect(
        regionsAfterFrame(),
        _payload(<(int, List<Rect>)>[
          (1, <Rect>[opaqueOverPv1]),
          (2, <Rect>[nestedOverPv2, overlay]),
        ]),
      );
    });

    test('a render object whose hitTestsChildren is false still claims its own bounds', () {
      const gateRect = Rect.fromLTWH(20, 30, 200, 150);
      final Float64List? regions = regionsFor(
        _stack(<RenderBox>[
          _at(const Rect.fromLTWH(0, 0, 400, 400), _platformView(1)),
          _at(
            gateRect,
            _RenderChildHitTestGate(
              childrenHitTestable: false,
              behavior: HitTestBehavior.opaque,
              child: _stack(<RenderBox>[_at(const Rect.fromLTWH(10, 15, 60, 40), _hitTarget())]),
            ),
          ),
        ]),
      );
      expect(
        regions,
        _payload(<(int, List<Rect>)>[
          (1, <Rect>[gateRect]),
        ]),
      );
    });

    test('a render object under an ignoring IgnorePointer does not claim its own bounds', () {
      final Float64List? regions = regionsFor(
        _stack(<RenderBox>[
          _at(const Rect.fromLTWH(0, 0, 400, 400), _platformView(1)),
          _at(
            const Rect.fromLTWH(0, 0, 300, 300),
            RenderIgnorePointer(
              child: _stack(<RenderBox>[
                _at(
                  const Rect.fromLTWH(10, 10, 100, 100),
                  RenderAbsorbPointer(child: _hitTarget()),
                ),
                _at(
                  const Rect.fromLTWH(150, 150, 100, 100),
                  _RenderChildHitTestGate(
                    childrenHitTestable: false,
                    behavior: HitTestBehavior.opaque,
                    child: _hitTarget(),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      );
      expect(regions, _payload(<(int, List<Rect>)>[(1, <Rect>[])]));
    });

    test('a non-ignoring IgnorePointer or non-absorbing AbsorbPointer under an ignoring '
        'IgnorePointer does not let content claim', () {
      const overlay = Rect.fromLTWH(250, 250, 100, 100);
      final Float64List? regions = regionsFor(
        _stack(<RenderBox>[
          _at(const Rect.fromLTWH(0, 0, 400, 400), _platformView(1)),
          _at(
            const Rect.fromLTWH(0, 0, 300, 300),
            RenderIgnorePointer(
              child: _stack(<RenderBox>[
                _at(
                  const Rect.fromLTWH(10, 10, 50, 50),
                  RenderAbsorbPointer(absorbing: false, child: _hitTarget()),
                ),
                _at(
                  const Rect.fromLTWH(70, 70, 50, 50),
                  RenderIgnorePointer(ignoring: false, child: _hitTarget()),
                ),
                // Painted after both, but still under the ignoring IgnorePointer.
                _at(const Rect.fromLTWH(130, 130, 50, 50), _hitTarget()),
              ]),
            ),
          ),
          _at(overlay, _hitTarget()),
        ]),
      );
      expect(
        regions,
        _payload(<(int, List<Rect>)>[
          (1, <Rect>[overlay]),
        ]),
      );
    });

    test('toggling an IgnorePointer between frames toggles whether its child claims', () {
      const button = Rect.fromLTWH(40, 50, 60, 30);
      const sibling = Rect.fromLTWH(200, 200, 50, 50);
      final ignorer = RenderIgnorePointer(child: _hitTarget());
      final RenderStack root = _stack(<RenderBox>[
        _at(const Rect.fromLTWH(0, 0, 400, 400), _platformView(1)),
        _at(button, RenderAbsorbPointer(absorbing: false, child: ignorer)),
        _at(sibling, _hitTarget()),
      ]);
      expect(
        regionsFor(root),
        _payload(<(int, List<Rect>)>[
          (1, <Rect>[sibling]),
        ]),
      );

      ignorer.ignoring = false;
      expect(
        regionsAfterFrame(),
        _payload(<(int, List<Rect>)>[
          (1, <Rect>[button, sibling]),
        ]),
      );

      ignorer.ignoring = true;
      expect(
        regionsAfterFrame(),
        _payload(<(int, List<Rect>)>[
          (1, <Rect>[sibling]),
        ]),
      );
    });
  });
}
