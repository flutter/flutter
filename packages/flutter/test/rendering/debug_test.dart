// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show json;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'rendering_tester.dart';

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  final ViewMetricsOverrideTestBinding binding = ViewMetricsOverrideTestBinding.ensureInitialized();

  tearDown(() {
    debugClearViewMetricsOverrides();
  });

  /// Dispatches a down/up pair at [physicalPosition], in physical pixels,
  /// through the real [ui.PointerDataPacket] path.
  ///
  /// [WidgetTester]'s own gestures take logical pixels and bypass
  /// [PointerEventConverter], so they cannot exercise the physical -> logical
  /// conversion this is meant to cover.
  Future<void> sendTapAt(WidgetTester tester, Offset physicalPosition) async {
    final int viewId = tester.view.viewId;
    ui.PointerData data(ui.PointerChange change) => ui.PointerData(
      viewId: viewId,
      change: change,
      physicalX: physicalPosition.dx,
      physicalY: physicalPosition.dy,
    );
    tester.binding.platformDispatcher.onPointerDataPacket!(
      ui.PointerDataPacket(
        data: <ui.PointerData>[data(ui.PointerChange.down), data(ui.PointerChange.up)],
      ),
    );
    await tester.pump();
  }

  /// Pumps a widget that reports the ambient [MediaQueryData] into [sink].
  Future<void> pumpProbe(WidgetTester tester, void Function(MediaQueryData) sink) {
    return tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          sink(MediaQuery.of(context));
          return const SizedBox.expand();
        },
      ),
    );
  }

  test('Describe transform control test', () {
    final identity = Matrix4.identity();
    final List<String> description = debugDescribeTransform(identity);
    expect(description, <String>[
      '[0] 1.0,0.0,0.0,0.0',
      '[1] 0.0,1.0,0.0,0.0',
      '[2] 0.0,0.0,1.0,0.0',
      '[3] 0.0,0.0,0.0,1.0',
    ]);
  });

  test('transform property test', () {
    final transform = Matrix4.diagonal3(Vector3.all(2.0));
    final simple = TransformProperty('transform', transform);
    expect(simple.name, equals('transform'));
    expect(simple.value, same(transform));
    expect(
      simple.toString(parentConfiguration: sparseTextConfiguration),
      equals(
        'transform:\n'
        '  [0] 2.0,0.0,0.0,0.0\n'
        '  [1] 0.0,2.0,0.0,0.0\n'
        '  [2] 0.0,0.0,2.0,0.0\n'
        '  [3] 0.0,0.0,0.0,1.0',
      ),
    );
    expect(
      simple.toString(parentConfiguration: singleLineTextConfiguration),
      equals('transform: [2.0,0.0,0.0,0.0; 0.0,2.0,0.0,0.0; 0.0,0.0,2.0,0.0; 0.0,0.0,0.0,1.0]'),
    );

    final nullProperty = TransformProperty('transform', null);
    expect(nullProperty.name, equals('transform'));
    expect(nullProperty.value, isNull);
    expect(nullProperty.toString(), equals('transform: null'));

    final hideNull = TransformProperty('transform', null, defaultValue: null);
    expect(hideNull.value, isNull);
    expect(hideNull.toString(), equals('transform: null'));
  });

  test('debugPaintPadding', () {
    expect((Canvas canvas) {
      debugPaintPadding(canvas, const Rect.fromLTRB(10.0, 10.0, 20.0, 20.0), null);
    }, paints..rect(color: const Color(0x90909090)));
    expect(
      (Canvas canvas) {
        debugPaintPadding(
          canvas,
          const Rect.fromLTRB(10.0, 10.0, 20.0, 20.0),
          const Rect.fromLTRB(11.0, 11.0, 19.0, 19.0),
        );
      },
      paints
        ..path(color: const Color(0x900090FF))
        ..path(color: const Color(0xFF0090FF)),
    );
    expect(
      (Canvas canvas) {
        debugPaintPadding(
          canvas,
          const Rect.fromLTRB(10.0, 10.0, 20.0, 20.0),
          const Rect.fromLTRB(15.0, 15.0, 15.0, 15.0),
        );
      },
      paints
        ..rect(rect: const Rect.fromLTRB(10.0, 10.0, 20.0, 20.0), color: const Color(0x90909090)),
    );
  });

  test('debugPaintPadding from render objects', () {
    debugPaintSizeEnabled = true;
    RenderSliver s;
    RenderBox b;
    final root = RenderViewport(
      crossAxisDirection: AxisDirection.right,
      offset: ViewportOffset.zero(),
      children: <RenderSliver>[
        s = RenderSliverPadding(
          padding: const EdgeInsets.all(10.0),
          child: RenderSliverToBoxAdapter(
            child: b = RenderPadding(padding: const EdgeInsets.all(10.0)),
          ),
        ),
      ],
    );
    layout(root);
    expect(
      b.debugPaint,
      paints
        ..rect(color: const Color(0xFF00FFFF))
        ..rect(color: const Color(0x90909090)),
    );
    expect(b.debugPaint, isNot(paints..path()));
    expect(
      s.debugPaint,
      paints
        ..circle(hasMaskFilter: true)
        ..line(hasMaskFilter: true)
        ..path(hasMaskFilter: true)
        ..path(hasMaskFilter: true)
        ..path(color: const Color(0x900090FF))
        ..path(color: const Color(0xFF0090FF)),
    );
    expect(s.debugPaint, isNot(paints..rect()));
    debugPaintSizeEnabled = false;
  });

  test('debugPaintPadding from render objects', () {
    debugPaintSizeEnabled = true;
    RenderSliver s;
    final RenderBox b = RenderPadding(
      padding: const EdgeInsets.all(10.0),
      child: RenderViewport(
        crossAxisDirection: AxisDirection.right,
        offset: ViewportOffset.zero(),
        children: <RenderSliver>[s = RenderSliverPadding(padding: const EdgeInsets.all(10.0))],
      ),
    );
    layout(b);
    expect(s.debugPaint, paints..rect(color: const Color(0x90909090)));
    expect(
      s.debugPaint,
      isNot(
        paints
          ..circle(hasMaskFilter: true)
          ..line(hasMaskFilter: true)
          ..path(hasMaskFilter: true)
          ..path(hasMaskFilter: true)
          ..path(color: const Color(0x900090FF))
          ..path(color: const Color(0xFF0090FF)),
      ),
    );
    expect(
      b.debugPaint,
      paints
        ..rect(color: const Color(0xFF00FFFF))
        ..path(color: const Color(0x900090FF))
        ..path(color: const Color(0xFF0090FF)),
    );
    expect(b.debugPaint, isNot(paints..rect(color: const Color(0x90909090))));
    debugPaintSizeEnabled = false;
  });

  test('debugPaintPadding from render objects with inverted direction vertical', () {
    debugPaintSizeEnabled = true;
    RenderSliver s;
    final root = RenderViewport(
      axisDirection: AxisDirection.up,
      crossAxisDirection: AxisDirection.right,
      offset: ViewportOffset.zero(),
      children: <RenderSliver>[
        s = RenderSliverPadding(
          padding: const EdgeInsets.all(10.0),
          child: RenderSliverToBoxAdapter(
            child: RenderPadding(padding: const EdgeInsets.all(10.0)),
          ),
        ),
      ],
    );
    layout(root);
    final context = PaintingContext(ContainerLayer(), const Rect.fromLTRB(0.0, 0.0, 800.0, 600.0));
    s.debugPaint(context, const Offset(0.0, 500));
    debugPaintSizeEnabled = false;
  });

  test('debugPaintPadding from render objects with inverted direction horizontal', () {
    debugPaintSizeEnabled = true;
    RenderSliver s;
    final root = RenderViewport(
      axisDirection: AxisDirection.left,
      crossAxisDirection: AxisDirection.down,
      offset: ViewportOffset.zero(),
      children: <RenderSliver>[
        s = RenderSliverPadding(
          padding: const EdgeInsets.all(10.0),
          child: RenderSliverToBoxAdapter(
            child: RenderPadding(padding: const EdgeInsets.all(10.0)),
          ),
        ),
      ],
    );
    layout(root);
    final context = PaintingContext(ContainerLayer(), const Rect.fromLTRB(0.0, 0.0, 800.0, 600.0));
    s.debugPaint(context, const Offset(0.0, 500));
    debugPaintSizeEnabled = false;
  });

  test('debugDisableOpacity keeps things in the right spot', () {
    debugDisableOpacityLayers = true;

    final blackBox = RenderDecoratedBox(
      decoration: const BoxDecoration(color: Color(0xff000000)),
      child: RenderConstrainedBox(
        additionalConstraints: BoxConstraints.tight(const Size.square(20.0)),
      ),
    );
    final root = RenderOpacity(opacity: .5, child: RenderRepaintBoundary(child: blackBox));
    layout(root, phase: EnginePhase.compositingBits);

    final rootLayer = OffsetLayer();
    final context = PaintingContext(rootLayer, const Rect.fromLTWH(0, 0, 500, 500));
    context.paintChild(root, const Offset(40, 40));

    final opacityLayer = rootLayer.firstChild! as OpacityLayer;
    expect(opacityLayer.offset, const Offset(40, 40));
    debugDisableOpacityLayers = false;
  });

  test('debugAssertAllRenderVarsUnset warns when debugProfileLayoutsEnabled set', () {
    debugProfileLayoutsEnabled = true;
    expect(() => debugAssertAllRenderVarsUnset('ERROR'), throwsFlutterError);
    debugProfileLayoutsEnabled = false;
  });

  test('debugAssertAllRenderVarsUnset warns when debugDisableClipLayers set', () {
    debugDisableClipLayers = true;
    expect(() => debugAssertAllRenderVarsUnset('ERROR'), throwsFlutterError);
    debugDisableClipLayers = false;
  });

  test('debugAssertAllRenderVarsUnset warns when debugDisablePhysicalShapeLayers set', () {
    debugDisablePhysicalShapeLayers = true;
    expect(() => debugAssertAllRenderVarsUnset('ERROR'), throwsFlutterError);
    debugDisablePhysicalShapeLayers = false;
  });

  test('debugAssertAllRenderVarsUnset warns when debugDisableOpacityLayers set', () {
    debugDisableOpacityLayers = true;
    expect(() => debugAssertAllRenderVarsUnset('ERROR'), throwsFlutterError);
    debugDisableOpacityLayers = false;
  });

  test('debugCheckHasBoundedAxis warns for vertical and horizontal axis', () {
    expect(
      () => debugCheckHasBoundedAxis(Axis.vertical, const BoxConstraints()),
      throwsFlutterError,
    );
    expect(
      () => debugCheckHasBoundedAxis(Axis.horizontal, const BoxConstraints()),
      throwsFlutterError,
    );
  });
  group('ViewMetricsOverride', () {
    test('isEmpty is true only when nothing is overridden', () {
      expect(const DebugViewMetricsOverride().isEmpty, isTrue);
      expect(const DebugViewMetricsOverride(boldText: false).isEmpty, isFalse);
      expect(const DebugViewMetricsOverride(devicePixelRatio: 1.0).isEmpty, isFalse);
    });

    test('affectsViewConfiguration is true only for layout metrics', () {
      expect(const DebugViewMetricsOverride(boldText: true).affectsViewConfiguration, isFalse);
      expect(
        const DebugViewMetricsOverride(devicePixelRatio: 2.0).affectsViewConfiguration,
        isTrue,
      );
      expect(
        const DebugViewMetricsOverride(physicalSize: ui.Size(1, 1)).affectsViewConfiguration,
        isTrue,
      );
    });

    test('== and hashCode compare every field', () {
      const a = DebugViewMetricsOverride(boldText: true, highContrast: false);
      const b = DebugViewMetricsOverride(boldText: true, highContrast: false);
      const c = DebugViewMetricsOverride(boldText: true);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('copyWith replaces provided fields and keeps the rest', () {
      const original = DebugViewMetricsOverride(boldText: true);
      final DebugViewMetricsOverride updated = original.copyWith(highContrast: true);
      expect(updated.boldText, isTrue);
      expect(updated.highContrast, isTrue);
      // A null argument keeps the existing override rather than clearing it.
      expect(original.copyWith().boldText, isTrue);
    });

    test('round trips through JSON', () {
      const original = DebugViewMetricsOverride(
        devicePixelRatio: 2.5,
        physicalSize: ui.Size(1000, 500),
        textScaler: TextScaler.linear(1.5),
        platformBrightness: ui.Brightness.dark,
        padding: EdgeInsets.only(top: 24),
        viewPadding: EdgeInsets.only(top: 24, bottom: 8),
        viewInsets: EdgeInsets.only(bottom: 300),
        alwaysUse24HourFormat: true,
        accessibleNavigation: true,
        invertColors: false,
        disableAnimations: true,
        boldText: true,
        reduceMotion: true,
        highContrast: false,
        onOffSwitchLabels: true,
        supportsAnnounce: true,
      );
      expect(DebugViewMetricsOverride.fromJson(original.toJson()), equals(original));
    });

    test('every metric survives copyWith and JSON, so none can be silently dropped', () {
      // Guard against a metric that is threaded through the constructor but
      // forgotten in copyWith, toJson, fromJson or ==. When a metric is added to
      // ViewMetricsOverride, add it here; these assertions then fail until the
      // rest of the class learns about it.
      //
      // The set below is every boolean AccessibilityFeatures flag that
      // MediaQueryData surfaces, plus the non-accessibility metrics from
      // flutter.dev/go/view-metrics-overrides. Deliberately excluded:
      // MediaQueryData.supportsShowingSystemContextMenu (a platform capability,
      // not a user setting), and the dart:ui flags MediaQueryData does not carry
      // at all (autoPlayAnimatedImages, autoPlayVideos, deterministicCursor),
      // which cannot be overridden through MediaQuery until it exposes them.
      const everything = DebugViewMetricsOverride(
        devicePixelRatio: 2.5,
        physicalSize: ui.Size(1000, 500),
        textScaler: TextScaler.linear(1.5),
        platformBrightness: ui.Brightness.dark,
        padding: EdgeInsets.only(top: 24),
        viewPadding: EdgeInsets.only(top: 24, bottom: 8),
        viewInsets: EdgeInsets.only(bottom: 300),
        alwaysUse24HourFormat: true,
        accessibleNavigation: true,
        invertColors: true,
        disableAnimations: true,
        boldText: true,
        reduceMotion: true,
        highContrast: true,
        onOffSwitchLabels: true,
        supportsAnnounce: false,
      );

      expect(everything.toJson().keys.toSet(), <String>{
        'devicePixelRatio',
        'physicalSize',
        'textScaleFactor',
        'platformBrightness',
        'padding',
        'viewPadding',
        'viewInsets',
        'alwaysUse24HourFormat',
        'accessibleNavigation',
        'invertColors',
        'disableAnimations',
        'boldText',
        'reduceMotion',
        'highContrast',
        'onOffSwitchLabels',
        'supportsAnnounce',
      });
      // A field missing from copyWith's body would come back null here.
      expect(everything.copyWith(), equals(everything));
      // A field missing from toJson or fromJson would break the round trip.
      expect(DebugViewMetricsOverride.fromJson(everything.toJson()), equals(everything));
      // A field missing from isEmpty would not be noticed by either check above.
      expect(everything.isEmpty, isFalse);
    });

    test('toJson omits metrics that are not overridden', () {
      expect(const DebugViewMetricsOverride().toJson(), isEmpty);
      expect(const DebugViewMetricsOverride(boldText: true).toJson(), <String, Object?>{
        'boldText': true,
      });
    });

    test('fromJson treats absent keys as not overridden', () {
      final override = DebugViewMetricsOverride.fromJson(const <String, Object?>{'boldText': true});
      expect(override.boldText, isTrue);
      expect(override.textScaler, isNull);
      expect(override.physicalSize, isNull);
    });

    test('fromJson rejects malformed values', () {
      expect(
        () => DebugViewMetricsOverride.fromJson(const <String, Object?>{'boldText': 'yes'}),
        throwsFormatException,
      );
      expect(
        () => DebugViewMetricsOverride.fromJson(const <String, Object?>{'devicePixelRatio': 'big'}),
        throwsFormatException,
      );
      expect(
        () => DebugViewMetricsOverride.fromJson(const <String, Object?>{
          'platformBrightness': 'purple',
        }),
        throwsFormatException,
      );
      expect(
        () => DebugViewMetricsOverride.fromJson(const <String, Object?>{
          'physicalSize': <String, Object?>{'width': 10},
        }),
        throwsFormatException,
      );
    });

    test('fromJson rejects values that would produce infinite or NaN layout', () {
      // These arrive from tooling, so they must be reported as errors rather
      // than tripping the constructor's asserts and killing the app.
      for (final ratio in <double>[0, -1, double.infinity, double.nan]) {
        expect(
          () => DebugViewMetricsOverride.fromJson(<String, Object?>{'devicePixelRatio': ratio}),
          throwsFormatException,
          reason: 'devicePixelRatio $ratio should be rejected',
        );
      }
      expect(
        () => DebugViewMetricsOverride.fromJson(const <String, Object?>{
          'physicalSize': <String, Object?>{'width': -1, 'height': 10},
        }),
        throwsFormatException,
      );
      expect(
        () => DebugViewMetricsOverride.fromJson(const <String, Object?>{
          'physicalSize': <String, Object?>{'width': double.infinity, 'height': 10},
        }),
        throwsFormatException,
      );
      expect(
        () => DebugViewMetricsOverride.fromJson(const <String, Object?>{'textScaleFactor': -1}),
        throwsFormatException,
      );
    });

    test('fromJson rejects negative or non-finite insets', () {
      // Insets feed straight into layout, so a bad component would produce
      // negative or NaN geometry instead of a visibly wrong screen.
      for (final key in <String>['padding', 'viewPadding', 'viewInsets']) {
        for (final bad in <double>[-1, double.infinity, double.nan]) {
          for (final edge in <String>['left', 'top', 'right', 'bottom']) {
            expect(
              () => DebugViewMetricsOverride.fromJson(<String, Object?>{
                key: <String, Object?>{'left': 0, 'top': 0, 'right': 0, 'bottom': 0, edge: bad},
              }),
              throwsFormatException,
              reason: '$key.$edge of $bad should be rejected',
            );
          }
        }
        // Zero and positive components remain valid.
        expect(
          DebugViewMetricsOverride.fromJson(<String, Object?>{
            key: const <String, Object?>{'left': 0, 'top': 12, 'right': 0, 'bottom': 34},
          }),
          isA<DebugViewMetricsOverride>(),
        );
      }
    });

    test('asserts on an invalid devicePixelRatio passed directly', () {
      expect(() => DebugViewMetricsOverride(devicePixelRatio: 0), throwsAssertionError);
      expect(() => DebugViewMetricsOverride(devicePixelRatio: -1), throwsAssertionError);
      expect(
        () => DebugViewMetricsOverride(devicePixelRatio: double.infinity),
        throwsAssertionError,
      );
    });

    test('stays usable in a const expression', () {
      // The devicePixelRatio assert must remain const-evaluable, otherwise
      // every const DebugViewMetricsOverride at a call site fails to compile.
      const override = DebugViewMetricsOverride(
        devicePixelRatio: 2.0,
        physicalSize: ui.Size(1000, 500),
        textScaler: TextScaler.linear(1.5),
      );
      expect(override.devicePixelRatio, 2.0);
    });
  });

  group('debugSetViewMetricsOverride', () {
    test('installs, replaces, and removes entries', () {
      expect(debugViewMetricsOverrides, isEmpty);

      expect(
        debugSetViewMetricsOverride(7, const DebugViewMetricsOverride(boldText: true)),
        isTrue,
      );
      expect(debugViewMetricsOverrides[7], const DebugViewMetricsOverride(boldText: true));

      // Setting the same value again is a no-op.
      expect(
        debugSetViewMetricsOverride(7, const DebugViewMetricsOverride(boldText: true)),
        isFalse,
      );

      expect(
        debugSetViewMetricsOverride(7, const DebugViewMetricsOverride(boldText: false)),
        isTrue,
      );
      expect(debugViewMetricsOverrides[7], const DebugViewMetricsOverride(boldText: false));

      expect(debugSetViewMetricsOverride(7, null), isTrue);
      expect(debugViewMetricsOverrides, isEmpty);
      expect(debugSetViewMetricsOverride(7, null), isFalse);
    });

    test('the exposed map is read-only', () {
      // Direct mutation cannot notify listeners, so it must fail loudly rather
      // than silently leaving views stale.
      expect(
        () => debugViewMetricsOverrides[7] = const DebugViewMetricsOverride(boldText: true),
        throwsUnsupportedError,
      );
      expect(() => debugViewMetricsOverrides.remove(7), throwsUnsupportedError);
      expect(debugViewMetricsOverrides.clear, throwsUnsupportedError);
      expect(debugViewMetricsOverrides, isEmpty);
    });

    test('an empty override removes the entry', () {
      debugSetViewMetricsOverride(7, const DebugViewMetricsOverride(boldText: true));
      expect(debugSetViewMetricsOverride(7, const DebugViewMetricsOverride()), isTrue);
      expect(debugViewMetricsOverrides, isEmpty);
    });

    test('notifies listeners only when something changed', () {
      var notifications = 0;
      void listener() => notifications += 1;
      debugViewMetricsOverridesNotifier.addListener(listener);
      addTearDown(() => debugViewMetricsOverridesNotifier.removeListener(listener));

      debugSetViewMetricsOverride(7, const DebugViewMetricsOverride(boldText: true));
      expect(notifications, 1);
      debugSetViewMetricsOverride(7, const DebugViewMetricsOverride(boldText: true));
      expect(notifications, 1);
      debugClearViewMetricsOverrides();
      expect(notifications, 2);
      debugClearViewMetricsOverrides();
      expect(notifications, 2);
    });
  });

  group('MediaQuery', () {
    testWidgets('picks up accessibility overrides and drops them again', (
      WidgetTester tester,
    ) async {
      late MediaQueryData data;
      await pumpProbe(tester, (MediaQueryData value) => data = value);

      expect(data.boldText, isFalse);
      expect(data.highContrast, isFalse);
      // The unoverridden scaler is a SystemTextScaler, so compare behaviour
      // rather than identity.
      expect(data.textScaler.scale(10), 10.0);
      // The platform reports supportsAnnounce as true by default, so
      // overriding it to false is observable.
      expect(data.supportsAnnounce, isTrue);
      // reduceMotion is a separate platform setting from disableAnimations.
      expect(data.reduceMotion, isFalse);
      expect(data.disableAnimations, isFalse);

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(
          boldText: true,
          highContrast: true,
          reduceMotion: true,
          supportsAnnounce: false,
          textScaler: TextScaler.linear(2.0),
        ),
      );
      await tester.pump();

      expect(data.boldText, isTrue);
      expect(data.highContrast, isTrue);
      expect(data.textScaler, const TextScaler.linear(2.0));
      expect(data.supportsAnnounce, isFalse);
      expect(data.reduceMotion, isTrue);
      // Overriding reduceMotion must not imply disableAnimations.
      expect(data.disableAnimations, isFalse);

      debugSetViewMetricsOverride(tester.view.viewId, null);
      await tester.pump();

      expect(data.boldText, isFalse);
      expect(data.highContrast, isFalse);
      expect(data.supportsAnnounce, isTrue);
      expect(data.reduceMotion, isFalse);
      expect(data.textScaler.scale(10), 10.0);
    });

    testWidgets('overrides padding, insets and brightness', (WidgetTester tester) async {
      late MediaQueryData data;
      await pumpProbe(tester, (MediaQueryData value) => data = value);

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(
          platformBrightness: ui.Brightness.dark,
          padding: EdgeInsets.only(top: 44),
          viewInsets: EdgeInsets.only(bottom: 300),
        ),
      );
      await tester.pump();

      expect(data.platformBrightness, ui.Brightness.dark);
      expect(data.padding, const EdgeInsets.only(top: 44));
      expect(data.viewInsets, const EdgeInsets.only(bottom: 300));

      // Rendering debug variables must be reset inside the test body:
      // debugAssertAllRenderVarsUnset runs before tearDown.
      debugClearViewMetricsOverrides();
    });

    testWidgets('only affects the view it targets', (WidgetTester tester) async {
      late MediaQueryData data;
      await pumpProbe(tester, (MediaQueryData value) => data = value);

      debugSetViewMetricsOverride(
        tester.view.viewId + 1,
        const DebugViewMetricsOverride(boldText: true),
      );
      await tester.pump();

      expect(data.boldText, isFalse);

      debugClearViewMetricsOverrides();
    });
  });

  group('view configuration', () {
    testWidgets('an overridden physicalSize actually relayouts the app', (
      WidgetTester tester,
    ) async {
      late MediaQueryData data;
      await pumpProbe(tester, (MediaQueryData value) => data = value);

      final ui.Size originalSize = tester.getSize(find.byType(SizedBox));
      expect(data.size, originalSize);

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(physicalSize: ui.Size(1000, 500), devicePixelRatio: 2.0),
      );
      await tester.pumpAndSettle();

      // MediaQuery reports the overridden metrics...
      expect(data.devicePixelRatio, 2.0);
      expect(data.size, const ui.Size(500, 250));
      // ...and the render tree actually lays out at that size, rather than
      // MediaQuery reporting a size the app does not use.
      expect(tester.getSize(find.byType(SizedBox)), const ui.Size(500, 250));

      debugClearViewMetricsOverrides();
      await tester.pumpAndSettle();

      expect(data.size, originalSize);
      expect(tester.getSize(find.byType(SizedBox)), originalSize);
    });

    testWidgets('overriding only devicePixelRatio preserves the physical size', (
      WidgetTester tester,
    ) async {
      late MediaQueryData data;
      await pumpProbe(tester, (MediaQueryData value) => data = value);

      final ui.Size originalSize = data.size;
      final double originalRatio = data.devicePixelRatio;

      debugSetViewMetricsOverride(
        tester.view.viewId,
        DebugViewMetricsOverride(devicePixelRatio: originalRatio * 2),
      );
      await tester.pumpAndSettle();

      expect(data.devicePixelRatio, originalRatio * 2);
      expect(data.size, originalSize / 2);
      expect(tester.getSize(find.byType(SizedBox)), originalSize / 2);

      debugClearViewMetricsOverrides();
      await tester.pumpAndSettle();
    });

    testWidgets('overriding devicePixelRatio rescales every DPR-derived metric', (
      WidgetTester tester,
    ) async {
      // The platform reports these in physical pixels; MediaQueryData divides
      // each by the device pixel ratio. Overriding the ratio must rescale all
      // of them, not just the size.
      tester.view.physicalSize = const ui.Size(1200, 2400);
      tester.view.devicePixelRatio = 2.0;
      tester.view.padding = const FakeViewPadding(top: 40, bottom: 20);
      tester.view.viewPadding = const FakeViewPadding(top: 40, bottom: 60);
      tester.view.viewInsets = const FakeViewPadding(bottom: 600);
      tester.view.systemGestureInsets = const FakeViewPadding(left: 80, right: 80);
      tester.view.gestureSettings = const ui.GestureSettings(physicalTouchSlop: 36);
      addTearDown(tester.view.reset);

      late MediaQueryData data;
      await pumpProbe(tester, (MediaQueryData value) => data = value);

      // At DPR 2: 40 physical -> 20 logical.
      expect(data.size, const ui.Size(600, 1200));
      expect(data.padding, const EdgeInsets.only(top: 20, bottom: 10));
      expect(data.viewPadding, const EdgeInsets.only(top: 20, bottom: 30));
      expect(data.viewInsets, const EdgeInsets.only(bottom: 300));
      expect(data.systemGestureInsets, const EdgeInsets.only(left: 40, right: 40));
      expect(data.gestureSettings.touchSlop, 18);

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(devicePixelRatio: 4.0),
      );
      await tester.pumpAndSettle();

      // At DPR 4 the same physical values are half as many logical pixels.
      expect(data.devicePixelRatio, 4.0);
      expect(data.size, const ui.Size(300, 600));
      expect(data.padding, const EdgeInsets.only(top: 10, bottom: 5));
      expect(data.viewPadding, const EdgeInsets.only(top: 10, bottom: 15));
      expect(data.viewInsets, const EdgeInsets.only(bottom: 150));
      expect(data.systemGestureInsets, const EdgeInsets.only(left: 20, right: 20));
      expect(data.gestureSettings.touchSlop, 9);

      debugClearViewMetricsOverrides();
      await tester.pumpAndSettle();

      expect(data.padding, const EdgeInsets.only(top: 20, bottom: 10));
      expect(data.gestureSettings.touchSlop, 18);
    });

    testWidgets('reported size matches the laid out size at a non-integer ratio', (
      WidgetTester tester,
    ) async {
      // Regression test: deriving the logical size by rescaling the existing
      // logical size divides twice and lands a float away from the constraints
      // RendererBinding derives from the physical size, so MediaQuery.sizeOf
      // would disagree with the size the view actually lays out at. Ratios that
      // are powers of two do not expose this.
      tester.view.physicalSize = const ui.Size(1000, 1000);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      late MediaQueryData data;
      await pumpProbe(tester, (MediaQueryData value) => data = value);

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(devicePixelRatio: 7.0),
      );
      await tester.pumpAndSettle();

      expect(data.size, const ui.Size(1000 / 7, 1000 / 7));
      expect(tester.getSize(find.byType(SizedBox)), data.size);

      debugClearViewMetricsOverrides();
      await tester.pumpAndSettle();
    });

    testWidgets('an explicit padding override wins over DPR rescaling', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const ui.Size(1200, 2400);
      tester.view.devicePixelRatio = 2.0;
      tester.view.padding = const FakeViewPadding(top: 40);
      addTearDown(tester.view.reset);

      late MediaQueryData data;
      await pumpProbe(tester, (MediaQueryData value) => data = value);

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(devicePixelRatio: 4.0, padding: EdgeInsets.only(top: 99)),
      );
      await tester.pumpAndSettle();

      // The explicit value is already logical, so it is used verbatim rather
      // than rescaled to 49.5.
      expect(data.padding, const EdgeInsets.only(top: 99));
      // Unoverridden metrics still rescale.
      expect(data.size, const ui.Size(300, 600));

      debugClearViewMetricsOverrides();
      await tester.pumpAndSettle();
    });

    testWidgets('overriding only physicalSize leaves padding untouched', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const ui.Size(1200, 2400);
      tester.view.devicePixelRatio = 2.0;
      tester.view.padding = const FakeViewPadding(top: 40);
      addTearDown(tester.view.reset);

      late MediaQueryData data;
      await pumpProbe(tester, (MediaQueryData value) => data = value);

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(physicalSize: ui.Size(600, 1200)),
      );
      await tester.pumpAndSettle();

      // The ratio did not change, so logical padding must not change either.
      expect(data.size, const ui.Size(300, 600));
      expect(data.padding, const EdgeInsets.only(top: 20));

      debugClearViewMetricsOverrides();
      await tester.pumpAndSettle();
    });
  });

  group('metrics notifications', () {
    testWidgets('only layout-affecting overrides report a metrics change', (
      WidgetTester tester,
    ) async {
      // didChangeMetrics is the platform's "the window changed" signal. Tooling
      // toggling boldText must not make applications believe that happened.
      final observer = _MetricsObserver();
      tester.binding.addObserver(observer);
      addTearDown(() => tester.binding.removeObserver(observer));

      late MediaQueryData data;
      await pumpProbe(tester, (MediaQueryData value) => data = value);
      expect(observer.changeCount, 0);

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(boldText: true),
      );
      await tester.pumpAndSettle();

      // The view still rebuilt and picked the override up...
      expect(data.boldText, isTrue);
      // ...but no false platform-metrics event reached the application.
      expect(observer.changeCount, 0);

      debugClearViewMetricsOverrides();
      await tester.pumpAndSettle();
      expect(observer.changeCount, 0);
    });
  });

  group('pointer conversion', () {
    test('devicePixelRatioForView reports the overridden ratio', () {
      final int viewId = binding.platformDispatcher.implicitView!.viewId;
      final double realRatio = binding.platformDispatcher.implicitView!.devicePixelRatio;

      expect(binding.testDevicePixelRatioForView(viewId), realRatio);

      debugSetViewMetricsOverride(viewId, const DebugViewMetricsOverride(devicePixelRatio: 4.0));
      expect(binding.testDevicePixelRatioForView(viewId), 4.0);

      // An override that does not touch the ratio leaves conversion alone.
      debugSetViewMetricsOverride(viewId, const DebugViewMetricsOverride(boldText: true));
      expect(binding.testDevicePixelRatioForView(viewId), realRatio);

      debugClearViewMetricsOverrides();
      expect(binding.testDevicePixelRatioForView(viewId), realRatio);

      // Unknown views still convert to null so their pointer data is dropped.
      expect(binding.testDevicePixelRatioForView(viewId + 1000), isNull);
    });

    testWidgets('a tap lands on the widget it was aimed at under a DPR override', (
      WidgetTester tester,
    ) async {
      // WidgetTester gestures are already in logical pixels, so they cannot
      // expose this: the bug is in the physical -> logical conversion that only
      // raw pointer packets go through.
      tester.view.physicalSize = const ui.Size(1200, 1200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final tapped = <String>[];
      Widget buildProbe() {
        return Align(
          alignment: Alignment.topLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final String name in <String>['first', 'second'])
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => tapped.add(name),
                  child: const SizedBox(width: 100, height: 100),
                ),
            ],
          ),
        );
      }

      await tester.pumpWidget(buildProbe());

      // Aim at physical y = 250. At the real ratio of 2 that is logical y = 125,
      // which is inside 'second' (logical y 100..200).
      await sendTapAt(tester, const Offset(50, 250));
      expect(tapped, <String>['second']);
      tapped.clear();

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(devicePixelRatio: 4.0),
      );
      await tester.pumpAndSettle();

      // The view now lays out at ratio 4, so physical y = 250 is logical
      // y = 62.5, which is inside 'first'. Before the pointer converter honored
      // the override it still divided by 2 and hit 'second'.
      await sendTapAt(tester, const Offset(50, 250));
      expect(tapped, <String>['first']);

      debugClearViewMetricsOverrides();
      await tester.pumpAndSettle();
    });
  });

  group('viewMetricsOverride service extension', () {
    final String extensionName = WidgetsServiceExtensions.viewMetricsOverride.name;

    testWidgets('sets, reads back, and clears an override', (WidgetTester tester) async {
      late MediaQueryData data;
      await pumpProbe(tester, (MediaQueryData value) => data = value);
      final int viewId = tester.view.viewId;

      Map<String, Object?> result = await binding.testExtension(extensionName, <String, String>{
        'viewId': '$viewId',
        'overrides': json.encode(<String, Object?>{'boldText': true, 'textScaleFactor': 1.5}),
      });
      await tester.pump();

      expect(result['overrides'], <String, Object?>{'textScaleFactor': 1.5, 'boldText': true});
      expect(result['overriddenViewIds'], <int>[viewId]);
      expect(data.boldText, isTrue);
      expect(data.textScaler, const TextScaler.linear(1.5));

      // A read does not disturb the override.
      result = await binding.testExtension(extensionName, <String, String>{'viewId': '$viewId'});
      expect(result['overrides'], <String, Object?>{'textScaleFactor': 1.5, 'boldText': true});

      result = await binding.testExtension(extensionName, <String, String>{'clearAll': 'true'});
      await tester.pump();

      expect(result['overrides'], isEmpty);
      expect(result['overriddenViewIds'], isEmpty);
      expect(data.boldText, isFalse);
    });

    testWidgets('an empty overrides object removes the override', (WidgetTester tester) async {
      late MediaQueryData data;
      await pumpProbe(tester, (MediaQueryData value) => data = value);
      final int viewId = tester.view.viewId;

      await binding.testExtension(extensionName, <String, String>{
        'viewId': '$viewId',
        'overrides': json.encode(<String, Object?>{'boldText': true}),
      });
      await tester.pump();
      expect(data.boldText, isTrue);

      await binding.testExtension(extensionName, <String, String>{
        'viewId': '$viewId',
        'overrides': json.encode(<String, Object?>{}),
      });
      await tester.pump();
      expect(data.boldText, isFalse);
      expect(debugViewMetricsOverrides, isEmpty);
    });

    testWidgets('reports errors instead of applying a partial override', (
      WidgetTester tester,
    ) async {
      await pumpProbe(tester, (MediaQueryData value) {});
      final int viewId = tester.view.viewId;

      await expectLater(
        binding.testExtension(extensionName, <String, String>{
          'overrides': json.encode(<String, Object?>{'boldText': true}),
        }),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        binding.testExtension(extensionName, <String, String>{'viewId': 'not-a-number'}),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        binding.testExtension(extensionName, <String, String>{
          'viewId': '$viewId',
          'overrides': json.encode(<String, Object?>{'boldText': true, 'highContrast': 'nope'}),
        }),
        throwsFormatException,
      );

      // The rejected payload left no trace.
      expect(debugViewMetricsOverrides, isEmpty);
    });
  });
}

class _MetricsObserver with WidgetsBindingObserver {
  int changeCount = 0;

  @override
  void didChangeMetrics() {
    changeCount += 1;
  }
}

class ViewMetricsOverrideTestBinding extends AutomatedTestWidgetsFlutterBinding {
  static ViewMetricsOverrideTestBinding? _instance;

  static ViewMetricsOverrideTestBinding ensureInitialized() {
    return _instance ??= ViewMetricsOverrideTestBinding();
  }

  final Map<String, ServiceExtensionCallback> extensions = .new();

  @override
  @protected
  void registerServiceExtension({
    required String name,
    required ServiceExtensionCallback callback,
  }) {
    extensions[name] = callback;
    super.registerServiceExtension(name: name, callback: callback);
  }

  Future<Map<String, Object?>> testExtension(String name, Map<String, String> arguments) async {
    if (!extensions.containsKey(name)) {
      throw StateError('Extension $name not found');
    }
    return (await extensions[name]!(arguments)).cast<String, Object?>();
  }

  /// Exposes the protected pointer conversion ratio hook to tests.
  double? testDevicePixelRatioForView(int viewId) => devicePixelRatioForView(viewId);
}
