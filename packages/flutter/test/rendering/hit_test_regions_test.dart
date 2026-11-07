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

ViewConfiguration _viewConfiguration({double devicePixelRatio = 1.0}) {
  final logicalConstraints = BoxConstraints.tight(const Size(800.0, 600.0));
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
    binding.renderView.configuration = _viewConfiguration();
    debugEnableHitTestRegionsOnAllPlatforms = true;
    binding.automaticPointerInterceptorsEnabled = true;
  });

  tearDown(() {
    binding.automaticPointerInterceptorsEnabled = false;
    debugEnableHitTestRegionsOnAllPlatforms = false;
    binding.renderView.configuration = initialConfiguration;
    // Detach this test's platform views from the root pipeline owner.
    binding.renderView.child = null;
  });

  /// Runs a full binding frame, which runs the hit-test region pass after
  /// drawFrame, and returns the payload computed for the root view.
  Float64List? regionsAfterFrame() {
    binding.pumpCompleteFrame();
    return binding.rootPipelineOwner.debugLastHitTestRegions;
  }

  Float64List? regionsFor(RenderBox root) {
    layout(root, phase: EnginePhase.composite);
    return regionsAfterFrame();
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
      owner.rootNode = null;
      parent?.dropChild(owner);
      owner.dispose();
    });
    return owner;
  }

  group('gating and delivery', () {
    test('the pass does not run while the flag is off, nor off the web without the debug flag', () {
      binding.automaticPointerInterceptorsEnabled = false;
      final RenderStack root = _stack(<RenderBox>[
        _at(const Rect.fromLTWH(0, 0, 400, 400), _platformView(1)),
        _at(const Rect.fromLTWH(10, 20, 100, 50), _hitTarget()),
      ]);
      expect(regionsFor(root), isNull);

      if (!kIsWeb) {
        debugEnableHitTestRegionsOnAllPlatforms = false;
        binding.automaticPointerInterceptorsEnabled = true;
        expect(regionsAfterFrame(), isNull);
      }
    });

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

        // Toggling absorbing neither relayouts nor repaints; the next pass sees it.
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
  });
}
