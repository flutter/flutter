// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// An override in which every metric is set, and set to something other than
/// what the test environment reports, so that a metric that fails to round trip
/// or to compare cannot hide behind a coincidence.
const DebugViewMetricsOverride _fullyPopulated = DebugViewMetricsOverride(
  devicePixelRatio: 3.5,
  physicalSize: ui.Size(1170, 2532),
  textScaleFactor: 1.75,
  platformBrightness: ui.Brightness.dark,
  padding: DebugViewPadding(left: 1, top: 2, right: 3, bottom: 4),
  viewPadding: DebugViewPadding(left: 5, top: 6, right: 7, bottom: 8),
  viewInsets: DebugViewPadding(left: 9, top: 10, right: 11, bottom: 12),
  alwaysUse24HourFormat: true,
  accessibleNavigation: true,
  invertColors: true,
  disableAnimations: true,
  boldText: true,
  reduceMotion: true,
  highContrast: true,
  onOffSwitchLabels: true,
  supportsAnnounce: false,
  autoPlayAnimatedImages: false,
  autoPlayVideos: false,
  deterministicCursor: true,
);

/// Every metric [_fullyPopulated] sets, paired with a way to change just that
/// one metric.
///
/// Used as the completeness guard: a metric that is threaded through the
/// constructor but forgotten in `copyWith`, `toJson`, `fromJson` or `==` shows
/// up here rather than as a metric that quietly never applies.
final Map<String, DebugViewMetricsOverride Function(DebugViewMetricsOverride)> _perMetricChange =
    <String, DebugViewMetricsOverride Function(DebugViewMetricsOverride)>{
      'devicePixelRatio': (DebugViewMetricsOverride o) => o.copyWith(devicePixelRatio: 2.0),
      'physicalSize': (DebugViewMetricsOverride o) =>
          o.copyWith(physicalSize: const ui.Size(10, 20)),
      'textScaleFactor': (DebugViewMetricsOverride o) => o.copyWith(textScaleFactor: 0.5),
      'platformBrightness': (DebugViewMetricsOverride o) =>
          o.copyWith(platformBrightness: ui.Brightness.light),
      'padding': (DebugViewMetricsOverride o) =>
          o.copyWith(padding: const DebugViewPadding.all(99)),
      'viewPadding': (DebugViewMetricsOverride o) =>
          o.copyWith(viewPadding: const DebugViewPadding.all(99)),
      'viewInsets': (DebugViewMetricsOverride o) =>
          o.copyWith(viewInsets: const DebugViewPadding.all(99)),
      'alwaysUse24HourFormat': (DebugViewMetricsOverride o) =>
          o.copyWith(alwaysUse24HourFormat: false),
      'accessibleNavigation': (DebugViewMetricsOverride o) =>
          o.copyWith(accessibleNavigation: false),
      'invertColors': (DebugViewMetricsOverride o) => o.copyWith(invertColors: false),
      'disableAnimations': (DebugViewMetricsOverride o) => o.copyWith(disableAnimations: false),
      'boldText': (DebugViewMetricsOverride o) => o.copyWith(boldText: false),
      'reduceMotion': (DebugViewMetricsOverride o) => o.copyWith(reduceMotion: false),
      'highContrast': (DebugViewMetricsOverride o) => o.copyWith(highContrast: false),
      'onOffSwitchLabels': (DebugViewMetricsOverride o) => o.copyWith(onOffSwitchLabels: false),
      'supportsAnnounce': (DebugViewMetricsOverride o) => o.copyWith(supportsAnnounce: true),
      'autoPlayAnimatedImages': (DebugViewMetricsOverride o) =>
          o.copyWith(autoPlayAnimatedImages: true),
      'autoPlayVideos': (DebugViewMetricsOverride o) => o.copyWith(autoPlayVideos: true),
      'deterministicCursor': (DebugViewMetricsOverride o) => o.copyWith(deterministicCursor: false),
    };

/// Every metric [DebugViewMetricsOverride] supports, according to
/// [DebugViewMetricsOverride.fromJson], which names them when it rejects one it
/// does not know — the only place the full set is available at runtime.
Set<String> _allOverridableMetrics() {
  try {
    DebugViewMetricsOverride.fromJson(const <String, Object?>{'not-a-metric': true});
  } on FormatException catch (error) {
    const marker = 'Supported metrics are: ';
    final int start = error.message.indexOf(marker);
    expect(start, isNonNegative, reason: 'fromJson no longer lists the metrics it supports');
    return error.message.substring(start + marker.length).replaceAll('.', '').split(', ').toSet();
  }
  fail('fromJson accepted an unknown metric');
}

/// A [ui.PlatformDispatcher] that cannot be asked what its callbacks are.
///
/// A test double that implements `dart:ui` through `noSuchMethod` behaves this
/// way, which is why reading a callback is guarded rather than only calling it.
class _UnreadableCallbackPlatformDispatcher extends _TwoViewPlatformDispatcher {
  /// Whether reading a callback throws.
  ///
  /// Switchable, because a wrapped dispatcher is told about every later
  /// override change for as long as it is alive: one that cannot be read has to
  /// become readable again before the tear down that clears the override runs.
  bool unreadable = true;

  @override
  ui.VoidCallback? get onMetricsChanged => unreadable
      ? throw UnimplementedError('onMetricsChanged is not readable')
      : super.onMetricsChanged;
}

/// A [ui.PlatformDispatcher] with two views, so that per-view resolution can be
/// tested: the engine the framework's own tests run against only ever has one.
class _TwoViewPlatformDispatcher implements ui.PlatformDispatcher {
  _TwoViewPlatformDispatcher() {
    _views[1] = _FakeView(this, 1, 2.0);
    _views[2] = _FakeView(this, 2, 4.0);
  }

  final Map<int, _FakeView> _views = <int, _FakeView>{};

  /// The fake view with the given id, for a test that reads back what the
  /// wrapper asked it to do.
  _FakeView viewFor(int id) => _views[id]!;

  /// Stands in for `PlatformDispatcher._removeView`, which the engine calls
  /// when a window is closed.
  void removeView(int id) => _views.remove(id);

  /// Stands in for `PlatformDispatcher._addView`.
  void addView(int id, double devicePixelRatio) =>
      _views[id] = _FakeView(this, id, devicePixelRatio);

  @override
  Iterable<ui.FlutterView> get views => _views.values;

  @override
  ui.FlutterView? view({required int id}) => _views[id];

  @override
  ui.FlutterView? get implicitView => _views[1];

  @override
  double get textScaleFactor => 1.0;

  @override
  double scaleFontSize(double unscaledFontSize) => unscaledFontSize;

  @override
  ui.Brightness get platformBrightness => ui.Brightness.light;

  @override
  bool get alwaysUse24HourFormat => false;

  @override
  ui.AccessibilityFeatures get accessibilityFeatures => const _NoAccessibilityFeatures();

  @override
  Iterable<ui.Display> get displays => const <ui.Display>[];

  @override
  ui.VoidCallback? onAccessibilityFeaturesChanged;

  @override
  ui.VoidCallback? onMetricsChanged;

  @override
  ui.VoidCallback? onPlatformBrightnessChanged;

  @override
  ui.VoidCallback? onPlatformConfigurationChanged;

  @override
  ui.VoidCallback? onTextScaleFactorChanged;

  @override
  ui.ViewFocusChangeCallback? onViewFocusChange;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not needed by these tests.');
}

class _FakeView implements ui.FlutterView {
  _FakeView(this.platformDispatcher, this.viewId, this.devicePixelRatio);

  @override
  List<ui.DisplayFeature> get displayFeatures => const <ui.DisplayFeature>[
    ui.DisplayFeature(
      bounds: ui.Rect.fromLTRB(20, 0, 30, 100),
      type: ui.DisplayFeatureType.hinge,
      state: ui.DisplayFeatureState.postureFlat,
    ),
  ];

  @override
  final ui.PlatformDispatcher platformDispatcher;

  @override
  final int viewId;

  @override
  final double devicePixelRatio;

  @override
  ui.Size get physicalSize => const ui.Size(100, 200);

  @override
  ui.ViewConstraints get physicalConstraints => const ui.ViewConstraints();

  @override
  ui.ViewPadding get padding => ui.ViewPadding.zero;

  @override
  ui.ViewPadding get viewInsets => ui.ViewPadding.zero;

  @override
  ui.ViewPadding get viewPadding => ui.ViewPadding.zero;

  /// The size the last [render] was asked for, which stays null when a
  /// caller's omitted size is forwarded as omitted; [renders] is what says a
  /// render happened at all.
  ui.Size? renderedSize;
  int renders = 0;

  @override
  void render(ui.Scene scene, {ui.Size? size}) {
    renderedSize = size;
    renders += 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not needed by these tests.');
}

class _NoAccessibilityFeatures implements ui.AccessibilityFeatures {
  const _NoAccessibilityFeatures();

  @override
  bool get boldText => false;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not needed by these tests.');
}

void main() {
  group('DebugViewMetricsOverride', () {
    test('an empty override overrides nothing', () {
      expect(const DebugViewMetricsOverride().isEmpty, isTrue);
      expect(const DebugViewMetricsOverride(devicePixelRatio: 2.0).isEmpty, isFalse);
      expect(const DebugViewMetricsOverride(boldText: false).isEmpty, isFalse);
      expect(_fullyPopulated.isEmpty, isFalse);
    });

    test('is usable in a const expression', () {
      // Identical, not just equal: two const expressions with the same
      // arguments are canonicalized to the same instance only if they really
      // were evaluated at compile time. This pins the constructor's asserts to
      // expressions that a const evaluation can perform, which `Size.isFinite`
      // and the like cannot.
      const copy = DebugViewMetricsOverride(
        devicePixelRatio: 3.5,
        physicalSize: ui.Size(1170, 2532),
        textScaleFactor: 1.75,
        platformBrightness: ui.Brightness.dark,
        padding: DebugViewPadding(left: 1, top: 2, right: 3, bottom: 4),
        viewPadding: DebugViewPadding(left: 5, top: 6, right: 7, bottom: 8),
        viewInsets: DebugViewPadding(left: 9, top: 10, right: 11, bottom: 12),
        alwaysUse24HourFormat: true,
        accessibleNavigation: true,
        invertColors: true,
        disableAnimations: true,
        boldText: true,
        reduceMotion: true,
        highContrast: true,
        onOffSwitchLabels: true,
        supportsAnnounce: false,
        autoPlayAnimatedImages: false,
        autoPlayVideos: false,
        deterministicCursor: true,
      );
      expect(identical(copy, _fullyPopulated), isTrue);
    });

    test('rejects a device pixel ratio that would break layout', () {
      expect(() => DebugViewMetricsOverride(devicePixelRatio: 0.0), throwsAssertionError);
      expect(() => DebugViewMetricsOverride(devicePixelRatio: -1.0), throwsAssertionError);
      expect(
        () => DebugViewMetricsOverride(devicePixelRatio: double.infinity),
        throwsAssertionError,
      );
      expect(() => DebugViewMetricsOverride(devicePixelRatio: double.nan), throwsAssertionError);
    });

    test('rejects a text scale factor that would break text layout', () {
      expect(() => DebugViewMetricsOverride(textScaleFactor: -1.0), throwsAssertionError);
      expect(
        () => DebugViewMetricsOverride(textScaleFactor: double.infinity),
        throwsAssertionError,
      );
      expect(() => DebugViewMetricsOverride(textScaleFactor: double.nan), throwsAssertionError);
      // Zero is a legitimate setting: it hides text entirely.
      expect(const DebugViewMetricsOverride(textScaleFactor: 0.0).textScaleFactor, 0.0);
    });

    test('copyWith replaces only what it is given', () {
      const original = DebugViewMetricsOverride(devicePixelRatio: 2.0, boldText: true);
      expect(original.copyWith(boldText: false).devicePixelRatio, 2.0);
      expect(original.copyWith(boldText: false).boldText, isFalse);
      // A null argument means "leave it alone", not "clear it".
      expect(original.copyWith().boldText, isTrue);
    });

    test('equality covers every metric', () {
      expect(_fullyPopulated, equals(_fullyPopulated.copyWith()));
      expect(_fullyPopulated.hashCode, _fullyPopulated.copyWith().hashCode);
      expect(const DebugViewMetricsOverride(), equals(const DebugViewMetricsOverride()));
      expect(_fullyPopulated, isNot(equals(const DebugViewMetricsOverride())));
      for (final MapEntry<String, DebugViewMetricsOverride Function(DebugViewMetricsOverride)> entry
          in _perMetricChange.entries) {
        expect(
          entry.value(_fullyPopulated),
          isNot(equals(_fullyPopulated)),
          reason: 'Changing ${entry.key} did not change equality.',
        );
      }
    });

    test('debugFillProperties lists every overridden metric', () {
      List<String> shownNames(DebugViewMetricsOverride override) {
        final builder = DiagnosticPropertiesBuilder();
        override.debugFillProperties(builder);
        return builder.properties
            .where((DiagnosticsNode node) => node.level.index >= DiagnosticLevel.info.index)
            .map((DiagnosticsNode node) => node.name!)
            .toList();
      }

      expect(shownNames(_fullyPopulated), unorderedEquals(_perMetricChange.keys));
      // Metrics that are not overridden are not shown at all.
      expect(shownNames(const DebugViewMetricsOverride()), isEmpty);
      expect(shownNames(const DebugViewMetricsOverride(boldText: false)), <String>['boldText']);
    });
  });

  group('DebugViewMetricsOverride serialization', () {
    test('round trips every metric and emits exactly the expected keys', () {
      final Map<String, Object?> json = _fullyPopulated.toJson();
      expect(json.keys, unorderedEquals(_perMetricChange.keys));
      expect(DebugViewMetricsOverride.fromJson(json), equals(_fullyPopulated));

      // Each individually changed metric survives a round trip too, which
      // catches a metric that is serialized but read back into the wrong field.
      for (final MapEntry<String, DebugViewMetricsOverride Function(DebugViewMetricsOverride)> entry
          in _perMetricChange.entries) {
        final DebugViewMetricsOverride changed = entry.value(_fullyPopulated);
        expect(
          DebugViewMetricsOverride.fromJson(changed.toJson()),
          equals(changed),
          reason: '${entry.key} did not survive a round trip.',
        );
      }
    });

    test('omits metrics that are not overridden', () {
      expect(const DebugViewMetricsOverride().toJson(), isEmpty);
      expect(const DebugViewMetricsOverride(boldText: false).toJson(), <String, Object?>{
        'boldText': false,
      });
    });

    test('an empty object is an empty override', () {
      expect(DebugViewMetricsOverride.fromJson(const <String, Object?>{}).isEmpty, isTrue);
    });

    test('accepts integers where doubles are expected', () {
      final override = DebugViewMetricsOverride.fromJson(const <String, Object?>{
        'devicePixelRatio': 3,
        'textScaleFactor': 2,
        'physicalSize': <String, Object?>{'width': 100, 'height': 200},
        'padding': <String, Object?>{'left': 1, 'top': 2, 'right': 3, 'bottom': 4},
      });
      expect(override.devicePixelRatio, 3.0);
      expect(override.textScaleFactor, 2.0);
      expect(override.physicalSize, const ui.Size(100, 200));
      expect(override.padding, const DebugViewPadding(left: 1, top: 2, right: 3, bottom: 4));
    });

    test('rejects unknown metrics rather than silently dropping them', () {
      expect(
        () => DebugViewMetricsOverride.fromJson(const <String, Object?>{'boldTextt': true}),
        throwsA(
          isA<FormatException>().having(
            (FormatException e) => e.message,
            'message',
            contains('boldTextt'),
          ),
        ),
      );
    });

    test('rejects values of the wrong type', () {
      expect(
        () => DebugViewMetricsOverride.fromJson(const <String, Object?>{'devicePixelRatio': '3.0'}),
        throwsFormatException,
      );
      expect(
        () => DebugViewMetricsOverride.fromJson(const <String, Object?>{'boldText': 'true'}),
        throwsFormatException,
      );
      expect(
        () => DebugViewMetricsOverride.fromJson(const <String, Object?>{'physicalSize': 100}),
        throwsFormatException,
      );
      expect(
        () => DebugViewMetricsOverride.fromJson(const <String, Object?>{
          'physicalSize': <String, Object?>{'width': 100},
        }),
        throwsFormatException,
      );
      expect(
        () => DebugViewMetricsOverride.fromJson(const <String, Object?>{'padding': 4}),
        throwsFormatException,
      );
      expect(
        () => DebugViewMetricsOverride.fromJson(const <String, Object?>{
          'padding': <String, Object?>{'left': 1, 'top': 2, 'right': 3},
        }),
        throwsFormatException,
      );
      expect(
        () => DebugViewMetricsOverride.fromJson(const <String, Object?>{
          'platformBrightness': 'DARK',
        }),
        throwsFormatException,
      );
    });

    test('rejects unknown members of nested objects', () {
      // A misspelled nested member is the same tooling mistake as a misspelled
      // metric: the value it was meant to carry is silently not applied.
      expect(
        () => DebugViewMetricsOverride.fromJson(const <String, Object?>{
          'viewInsets': <String, Object?>{'left': 0, 'top': 0, 'right': 0, 'botom': 4},
        }),
        throwsFormatException,
      );
      expect(
        () => DebugViewMetricsOverride.fromJson(const <String, Object?>{
          'viewInsets': <String, Object?>{'left': 0, 'top': 0, 'right': 0, 'bottom': 4, 'botom': 4},
        }),
        throwsA(
          isA<FormatException>().having(
            (FormatException e) => e.message,
            'message',
            allOf(contains('botom'), contains('viewInsets')),
          ),
        ),
      );
      expect(
        () => DebugViewMetricsOverride.fromJson(const <String, Object?>{
          'physicalSize': <String, Object?>{'width': 1, 'height': 2, 'depth': 3},
        }),
        throwsFormatException,
      );
      // The service extension hands fromJson what json.decode produces, which is
      // Map<String, dynamic> rather than the literals above, so the nested
      // check has to match that type too.
      expect(
        () => DebugViewMetricsOverride.fromJson(
          json.decode('{"viewInsets": {"left": 0, "top": 0, "right": 0, "bottom": 4, "botom": 9}}')
              as Map<String, Object?>,
        ),
        throwsA(
          isA<FormatException>().having(
            (FormatException e) => e.message,
            'message',
            contains('botom'),
          ),
        ),
      );
      expect(
        DebugViewMetricsOverride.fromJson(
          json.decode('{"viewInsets": {"left": 0, "top": 0, "right": 0, "bottom": 4}}')
              as Map<String, Object?>,
        ).viewInsets,
        const DebugViewPadding(bottom: 4),
      );

      for (final key in <String>['padding', 'viewPadding', 'viewInsets']) {
        expect(
          () => DebugViewMetricsOverride.fromJson(<String, Object?>{
            key: const <String, Object?>{'left': 0, 'top': 0, 'right': 0, 'bottom': 0, 'extra': 0},
          }),
          throwsFormatException,
          reason: '$key accepted an unknown member',
        );
      }
    });

    test('rejects out of range values', () {
      for (final value in <Object>[0, -1, double.infinity, double.nan]) {
        expect(
          () => DebugViewMetricsOverride.fromJson(<String, Object?>{'devicePixelRatio': value}),
          throwsFormatException,
          reason: 'devicePixelRatio: $value was accepted.',
        );
      }
      for (final value in <Object>[-1, double.infinity, double.nan]) {
        expect(
          () => DebugViewMetricsOverride.fromJson(<String, Object?>{'textScaleFactor': value}),
          throwsFormatException,
          reason: 'textScaleFactor: $value was accepted.',
        );
        expect(
          () => DebugViewMetricsOverride.fromJson(<String, Object?>{
            'physicalSize': <String, Object?>{'width': value, 'height': 100},
          }),
          throwsFormatException,
          reason: 'physicalSize.width: $value was accepted.',
        );
        expect(
          () => DebugViewMetricsOverride.fromJson(<String, Object?>{
            'physicalSize': <String, Object?>{'width': 100, 'height': value},
          }),
          throwsFormatException,
          reason: 'physicalSize.height: $value was accepted.',
        );
        for (final edge in <String>['left', 'top', 'right', 'bottom']) {
          expect(
            () => DebugViewMetricsOverride.fromJson(<String, Object?>{
              'viewInsets': <String, Object?>{
                'left': 0,
                'top': 0,
                'right': 0,
                'bottom': 0,
                edge: value,
              },
            }),
            throwsFormatException,
            reason: 'viewInsets.$edge: $value was accepted.',
          );
        }
      }
      // Zero extents are legal, they just mean "nothing there".
      expect(
        DebugViewMetricsOverride.fromJson(const <String, Object?>{
          'physicalSize': <String, Object?>{'width': 0, 'height': 0},
        }).physicalSize,
        ui.Size.zero,
      );
    });
  });

  group('DebugViewPadding', () {
    test('defaults every edge to zero', () {
      // Deliberately not DebugViewPadding.zero: the point is that the unnamed
      // constructor defaults every edge, which is what makes them equal.
      // ignore: use_named_constants
      const padding = DebugViewPadding();
      expect(padding.left, 0.0);
      expect(padding.top, 0.0);
      expect(padding.right, 0.0);
      expect(padding.bottom, 0.0);
      expect(padding, DebugViewPadding.zero);
      expect(const DebugViewPadding.all(3).bottom, 3.0);
    });

    test('is a ui.ViewPadding with value equality', () {
      const padding = DebugViewPadding(left: 1, top: 2, right: 3, bottom: 4);
      expect(padding, isA<ui.ViewPadding>());
      expect(padding, const DebugViewPadding(left: 1, top: 2, right: 3, bottom: 4));
      expect(
        padding.hashCode,
        const DebugViewPadding(left: 1, top: 2, right: 3, bottom: 4).hashCode,
      );
      expect(padding, isNot(const DebugViewPadding(left: 1, top: 2, right: 3, bottom: 5)));
    });
  });

  group('debugViewMetricsOverrides', () {
    tearDown(debugClearViewMetricsOverrides);

    test('starts empty and cannot be mutated directly', () {
      expect(debugViewMetricsOverrides, isEmpty);
      expect(
        () => debugViewMetricsOverrides[0] = const DebugViewMetricsOverride(boldText: true),
        throwsUnsupportedError,
      );
      expect(() => debugViewMetricsOverrides.clear(), throwsUnsupportedError);
    });

    test('reports whether anything actually changed', () {
      const override = DebugViewMetricsOverride(boldText: true);
      expect(debugSetViewMetricsOverride(7, override), isTrue);
      expect(debugViewMetricsOverrides, <int, DebugViewMetricsOverride>{7: override});

      // Setting an equal but distinct instance is not a change.
      expect(
        debugSetViewMetricsOverride(7, const DebugViewMetricsOverride(boldText: true)),
        isFalse,
      );
      expect(
        debugSetViewMetricsOverride(7, const DebugViewMetricsOverride(boldText: false)),
        isTrue,
      );

      expect(debugSetViewMetricsOverride(7, null), isTrue);
      expect(debugSetViewMetricsOverride(7, null), isFalse);
      expect(debugViewMetricsOverrides, isEmpty);
    });

    test('an empty override removes the entry rather than storing it', () {
      expect(
        debugSetViewMetricsOverride(7, const DebugViewMetricsOverride(boldText: true)),
        isTrue,
      );
      expect(debugSetViewMetricsOverride(7, const DebugViewMetricsOverride()), isTrue);
      expect(debugViewMetricsOverrides, isEmpty);
      // ...and installing an empty override where there was none is a no-op.
      expect(debugSetViewMetricsOverride(7, const DebugViewMetricsOverride()), isFalse);
    });

    test('keeps views independent', () {
      debugSetViewMetricsOverride(1, const DebugViewMetricsOverride(boldText: true));
      debugSetViewMetricsOverride(2, const DebugViewMetricsOverride(highContrast: true));
      expect(debugViewMetricsOverrides[1]!.boldText, isTrue);
      expect(debugViewMetricsOverrides[1]!.highContrast, isNull);
      expect(debugViewMetricsOverrides[2]!.boldText, isNull);
      expect(debugViewMetricsOverrides[2]!.highContrast, isTrue);
    });

    test('debugClearViewMetricsOverrides reports whether anything was removed', () {
      expect(debugClearViewMetricsOverrides(), isFalse);
      debugSetViewMetricsOverride(1, const DebugViewMetricsOverride(boldText: true));
      debugSetViewMetricsOverride(2, const DebugViewMetricsOverride(boldText: true));
      expect(debugClearViewMetricsOverrides(), isTrue);
      expect(debugViewMetricsOverrides, isEmpty);
      expect(debugClearViewMetricsOverrides(), isFalse);
    });

    test('rejects geometry that cannot be laid out, built directly', () {
      // The const constructor cannot check these, and tooling payloads go
      // through fromJson, so debugSetViewMetricsOverride is the only gate a
      // directly built override passes through.
      const invalid = <DebugViewMetricsOverride>[
        DebugViewMetricsOverride(physicalSize: ui.Size(double.nan, 100)),
        DebugViewMetricsOverride(physicalSize: ui.Size(100, double.infinity)),
        DebugViewMetricsOverride(physicalSize: ui.Size(-1, 100)),
        DebugViewMetricsOverride(physicalSize: ui.Size(100, -1)),
        DebugViewMetricsOverride(padding: DebugViewPadding(left: -1)),
        DebugViewMetricsOverride(padding: DebugViewPadding(top: double.nan)),
        DebugViewMetricsOverride(viewPadding: DebugViewPadding(right: double.infinity)),
        DebugViewMetricsOverride(viewInsets: DebugViewPadding(bottom: -1)),
      ];
      for (final override in invalid) {
        expect(
          () => debugSetViewMetricsOverride(1, override),
          throwsFlutterError,
          reason: '$override was stored',
        );
        expect(debugViewMetricsOverrides, isEmpty, reason: '$override left state behind');
      }

      // Zero extents are legal, and a rejected override does not disturb one
      // that is already installed.
      const valid = DebugViewMetricsOverride(
        physicalSize: ui.Size.zero,
        padding: DebugViewPadding.zero,
      );
      expect(debugSetViewMetricsOverride(1, valid), isTrue);
      expect(
        () => debugSetViewMetricsOverride(
          1,
          const DebugViewMetricsOverride(viewInsets: DebugViewPadding(bottom: -1)),
        ),
        throwsFlutterError,
      );
      expect(debugViewMetricsOverrides[1], valid);
      debugClearViewMetricsOverrides();
    });

    test('debugAssertAllFoundationVarsUnset treats a leftover override as a leak', () {
      expect(debugAssertAllFoundationVarsUnset('leak'), isTrue);
      debugSetViewMetricsOverride(1, const DebugViewMetricsOverride(boldText: true));
      expect(() => debugAssertAllFoundationVarsUnset('leak'), throwsFlutterError);
      debugClearViewMetricsOverrides();
      expect(debugAssertAllFoundationVarsUnset('leak'), isTrue);
    });
  });

  group('debugApplyViewMetricsOverrides', () {
    test('is idempotent and stable', () {
      final ui.PlatformDispatcher real = ui.PlatformDispatcher.instance;
      final ui.PlatformDispatcher wrapped = debugApplyViewMetricsOverrides(real);
      expect(wrapped, isNot(same(real)));
      expect(debugApplyViewMetricsOverrides(real), same(wrapped));
      expect(debugApplyViewMetricsOverrides(wrapped), same(wrapped));
    });

    test('vends views with a stable identity', () {
      final ui.PlatformDispatcher wrapped = debugApplyViewMetricsOverrides(
        ui.PlatformDispatcher.instance,
      );
      final ui.FlutterView implicitView = wrapped.implicitView!;
      expect(wrapped.implicitView, same(implicitView));
      expect(wrapped.view(id: implicitView.viewId), same(implicitView));
      expect(wrapped.views, contains(same(implicitView)));
      expect(implicitView, isNot(same(ui.PlatformDispatcher.instance.implicitView)));

      // Installing and removing an override does not change it: RenderView and
      // the widgets layer hold on to view objects and compare them by identity.
      debugSetViewMetricsOverride(
        implicitView.viewId,
        const DebugViewMetricsOverride(devicePixelRatio: 7.0),
      );
      expect(wrapped.implicitView, same(implicitView));
      debugClearViewMetricsOverrides();
      expect(wrapped.implicitView, same(implicitView));
    });

    test('binds a dispatcher to a view id', () {
      final ui.PlatformDispatcher real = ui.PlatformDispatcher.instance;
      final ui.FlutterView implicitView = debugApplyViewMetricsOverrides(real).implicitView!;

      // A view this library vends already owns a correctly bound dispatcher, so
      // asking by that view's id hands back the very same object rather than
      // retaining a second one.
      expect(
        debugApplyViewMetricsOverridesForView(real, implicitView.viewId),
        same(implicitView.platformDispatcher),
      );

      // For an id the platform reports no view for, there is nothing to tie the
      // result to, so a fresh one is built per call and the caller holds it.
      final ui.PlatformDispatcher viewless = debugApplyViewMetricsOverridesForView(real, 123456);
      expect(viewless, isNot(same(implicitView.platformDispatcher)));
      expect(debugApplyViewMetricsOverridesForView(real, 123456), isNot(same(viewless)));

      // It resolves the override registered for the id it was bound to, and
      // only that one.
      debugSetViewMetricsOverride(123456, const DebugViewMetricsOverride(textScaleFactor: 3.0));
      final double bound = viewless.textScaleFactor;
      final double unbound = implicitView.platformDispatcher.textScaleFactor;
      debugClearViewMetricsOverrides();

      expect(bound, 3.0);
      expect(unbound, real.textScaleFactor);
    });

    test('returns null for a view that does not exist', () {
      final ui.PlatformDispatcher wrapped = debugApplyViewMetricsOverrides(
        ui.PlatformDispatcher.instance,
      );
      expect(wrapped.view(id: 123456), isNull);
    });
  });

  group('the wrapper delegates when nothing is overridden', () {
    late ui.PlatformDispatcher real;
    late ui.PlatformDispatcher wrapped;
    late ui.FlutterView realView;
    late ui.FlutterView wrappedView;

    setUp(() {
      real = ui.PlatformDispatcher.instance;
      wrapped = debugApplyViewMetricsOverrides(real);
      realView = real.implicitView!;
      wrappedView = wrapped.implicitView!;
      expect(debugViewMetricsOverrides, isEmpty);
    });

    test('every overridable PlatformDispatcher metric', () {
      expect(wrapped.accessibilityFeatures, same(real.accessibilityFeatures));
      expect(wrapped.alwaysUse24HourFormat, real.alwaysUse24HourFormat);
      expect(wrapped.platformBrightness, real.platformBrightness);
      expect(wrapped.textScaleFactor, real.textScaleFactor);
      expect(wrapped.scaleFontSize(14.0), real.scaleFontSize(14.0));
      expect(wrapped.scaleFontSize(14.5), real.scaleFontSize(14.5));
    });

    test('every forwarded PlatformDispatcher member', () {
      expect(wrapped.defaultRouteName, real.defaultRouteName);
      expect(wrapped.displays, real.displays);
      expect(wrapped.engineId, real.engineId);
      expect(wrapped.frameData.frameNumber, real.frameData.frameNumber);
      expect(wrapped.initialLifecycleState, real.initialLifecycleState);
      expect(wrapped.letterSpacingOverride, real.letterSpacingOverride);
      expect(wrapped.lineHeightScaleFactorOverride, real.lineHeightScaleFactorOverride);
      expect(wrapped.locale, real.locale);
      expect(wrapped.locales, real.locales);
      expect(wrapped.nativeSpellCheckServiceDefined, real.nativeSpellCheckServiceDefined);
      expect(wrapped.brieflyShowPassword, real.brieflyShowPassword);
      expect(wrapped.paragraphSpacingOverride, real.paragraphSpacingOverride);
      expect(wrapped.semanticsEnabled, real.semanticsEnabled);
      expect(wrapped.supportsShowingSystemContextMenu, real.supportsShowingSystemContextMenu);
      expect(wrapped.systemFontFamily, real.systemFontFamily);
      expect(wrapped.wordSpacingOverride, real.wordSpacingOverride);
      expect(wrapped.views.length, real.views.length);
      expect(
        wrapped.views.map((ui.FlutterView view) => view.viewId),
        real.views.map((ui.FlutterView view) => view.viewId),
      );
    });

    test('callback registration goes straight through to the platform', () {
      // The wrapper must not hold onto callbacks: the entries that
      // debugSetViewMetricsOverride replays are read back off the real
      // dispatcher, and the engine delivers real platform events to it.
      void handler() {}
      final ui.VoidCallback? previous = real.onSemanticsEnabledChanged;
      addTearDown(() => real.onSemanticsEnabledChanged = previous);

      wrapped.onSemanticsEnabledChanged = handler;
      expect(real.onSemanticsEnabledChanged, same(handler));
      expect(wrapped.onSemanticsEnabledChanged, same(handler));
    });

    test('every overridable FlutterView metric', () {
      expect(wrappedView.viewId, realView.viewId);
      expect(wrappedView.devicePixelRatio, realView.devicePixelRatio);
      expect(wrappedView.physicalSize, realView.physicalSize);
      expect(wrappedView.physicalConstraints, realView.physicalConstraints);
      expect(wrappedView.padding, same(realView.padding));
      expect(wrappedView.viewInsets, same(realView.viewInsets));
      expect(wrappedView.viewPadding, same(realView.viewPadding));
    });

    test('every forwarded FlutterView member', () {
      expect(wrappedView.display, same(realView.display));
      expect(wrappedView.displayCornerRadii, realView.displayCornerRadii);
      expect(wrappedView.gestureSettings, realView.gestureSettings);
      expect(wrappedView.systemGestureInsets, same(realView.systemGestureInsets));
      // Display features are only rewritten when the device pixel ratio is
      // overridden; otherwise the platform's own list is handed straight back.
      expect(wrappedView.displayFeatures, same(realView.displayFeatures));
    });

    test('the view reports a dispatcher that resolves that view', () {
      // Not the same object as the wrapper the binding hands out: a view's
      // dispatcher resolves the platform-wide metrics from that view's own
      // override.
      expect(wrappedView.platformDispatcher, isNot(same(wrapped)));
      expect(wrappedView.platformDispatcher.textScaleFactor, real.textScaleFactor);
      expect(wrappedView.platformDispatcher.implicitView, same(wrappedView));
      expect(wrappedView.platformDispatcher.view(id: wrappedView.viewId), same(wrappedView));
    });
  });

  group('the wrapper resolves each view separately', () {
    tearDown(debugClearViewMetricsOverrides);

    test('view metrics and platform metrics both follow the view they belong to', () {
      final dispatcher = _TwoViewPlatformDispatcher();
      final ui.PlatformDispatcher wrapped = debugApplyViewMetricsOverrides(dispatcher);
      final ui.FlutterView first = wrapped.view(id: 1)!;
      final ui.FlutterView second = wrapped.view(id: 2)!;

      debugSetViewMetricsOverride(
        1,
        const DebugViewMetricsOverride(
          devicePixelRatio: 7.0,
          textScaleFactor: 3.0,
          boldText: true,
          platformBrightness: ui.Brightness.dark,
        ),
      );

      expect(first.devicePixelRatio, 7.0);
      expect(second.devicePixelRatio, 4.0);

      // Metrics that dart:ui exposes on the dispatcher rather than on the view
      // are resolved through the dispatcher each view reports, so they are
      // per-view too.
      expect(first.platformDispatcher.textScaleFactor, 3.0);
      expect(second.platformDispatcher.textScaleFactor, 1.0);
      expect(first.platformDispatcher.scaleFontSize(10.0), 30.0);
      expect(second.platformDispatcher.scaleFontSize(10.0), 10.0);
      expect(first.platformDispatcher.accessibilityFeatures.boldText, isTrue);
      expect(second.platformDispatcher.accessibilityFeatures.boldText, isFalse);
      expect(first.platformDispatcher.platformBrightness, ui.Brightness.dark);
      expect(second.platformDispatcher.platformBrightness, ui.Brightness.light);

      // The dispatcher that is not tied to a view resolves the implicit view's
      // override, for consumers such as SemanticsBinding that have no view.
      expect(wrapped.textScaleFactor, 3.0);
      expect(wrapped.accessibilityFeatures.boldText, isTrue);

      // Every dispatcher vends the same view wrappers.
      expect(first.platformDispatcher.view(id: 2), same(second));
      expect(second.platformDispatcher.implicitView, same(first));
    });

    test('TestPlatformDispatcher preserves per-view metrics and test-value precedence', () {
      final dispatcher = _TwoViewPlatformDispatcher();
      final testDispatcher = TestPlatformDispatcher(
        platformDispatcher: debugApplyViewMetricsOverrides(dispatcher),
      );
      final ui.FlutterView first = testDispatcher.view(id: 1)!;
      final ui.FlutterView second = testDispatcher.view(id: 2)!;

      debugSetViewMetricsOverride(
        2,
        const DebugViewMetricsOverride(
          textScaleFactor: 3.0,
          platformBrightness: ui.Brightness.dark,
          alwaysUse24HourFormat: true,
          boldText: true,
        ),
      );

      expect(first.platformDispatcher.textScaleFactor, 1.0);
      expect(first.platformDispatcher.platformBrightness, ui.Brightness.light);
      expect(first.platformDispatcher.alwaysUse24HourFormat, isFalse);
      expect(first.platformDispatcher.accessibilityFeatures.boldText, isFalse);
      expect(second.platformDispatcher.textScaleFactor, 3.0);
      expect(second.platformDispatcher.scaleFontSize(10.0), 30.0);
      expect(second.platformDispatcher.platformBrightness, ui.Brightness.dark);
      expect(second.platformDispatcher.alwaysUse24HourFormat, isTrue);
      expect(second.platformDispatcher.accessibilityFeatures.boldText, isTrue);

      testDispatcher.textScaleFactorTestValue = 4.0;
      testDispatcher.platformBrightnessTestValue = ui.Brightness.light;
      testDispatcher.alwaysUse24HourFormatTestValue = false;
      testDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures();

      expect(second.platformDispatcher.textScaleFactor, 4.0);
      expect(second.platformDispatcher.scaleFontSize(10.0), 40.0);
      expect(second.platformDispatcher.platformBrightness, ui.Brightness.light);
      expect(second.platformDispatcher.alwaysUse24HourFormat, isFalse);
      expect(second.platformDispatcher.accessibilityFeatures.boldText, isFalse);
    });

    test('follows views as they are added and removed', () {
      final dispatcher = _TwoViewPlatformDispatcher();
      final ui.PlatformDispatcher wrapped = debugApplyViewMetricsOverrides(dispatcher);
      final ui.FlutterView second = wrapped.view(id: 2)!;
      expect(wrapped.views.map((ui.FlutterView view) => view.viewId), <int>[1, 2]);

      dispatcher.removeView(2);
      expect(wrapped.view(id: 2), isNull);
      expect(wrapped.views.map((ui.FlutterView view) => view.viewId), <int>[1]);
      // A wrapper the framework is still holding keeps working; it reports what
      // the view it wraps last reported.
      expect(second.devicePixelRatio, 4.0);

      dispatcher.addView(3, 6.0);
      final ui.FlutterView third = wrapped.view(id: 3)!;
      expect(third.devicePixelRatio, 6.0);
      expect(wrapped.view(id: 3), same(third));
      expect(wrapped.views.map((ui.FlutterView view) => view.viewId), <int>[1, 3]);

      debugSetViewMetricsOverride(3, const DebugViewMetricsOverride(devicePixelRatio: 9.0));
      expect(third.devicePixelRatio, 9.0);
      expect(wrapped.view(id: 3), same(third));
    });

    test('moves display features into the overridden logical space', () {
      final dispatcher = _TwoViewPlatformDispatcher();
      final ui.PlatformDispatcher wrapped = debugApplyViewMetricsOverrides(dispatcher);
      final ui.FlutterView first = wrapped.view(id: 1)!;

      // dart:ui reports DisplayFeature.bounds in logical pixels, unlike every
      // other FlutterView metric, so overriding the device pixel ratio has to
      // move them: at 2.0 the hinge spans logical 20..30, and at 4.0 the same
      // physical pixels are logical 10..15.
      expect(first.displayFeatures.single.bounds, const ui.Rect.fromLTRB(20, 0, 30, 100));

      debugSetViewMetricsOverride(1, const DebugViewMetricsOverride(devicePixelRatio: 4.0));
      expect(first.displayFeatures.single.bounds, const ui.Rect.fromLTRB(10, 0, 15, 50));
      expect(first.displayFeatures.single.type, ui.DisplayFeatureType.hinge);
      expect(first.displayFeatures.single.state, ui.DisplayFeatureState.postureFlat);

      // A different view, and a metric that is not the ratio, leave them alone.
      expect(
        wrapped.view(id: 2)!.displayFeatures.single.bounds,
        const ui.Rect.fromLTRB(20, 0, 30, 100),
      );
      debugSetViewMetricsOverride(1, const DebugViewMetricsOverride(boldText: true));
      expect(first.displayFeatures.single.bounds, const ui.Rect.fromLTRB(20, 0, 30, 100));
    });

    test('an override on a non implicit view leaves the implicit one alone', () {
      final dispatcher = _TwoViewPlatformDispatcher();
      final ui.PlatformDispatcher wrapped = debugApplyViewMetricsOverrides(dispatcher);

      debugSetViewMetricsOverride(
        2,
        const DebugViewMetricsOverride(devicePixelRatio: 7.0, textScaleFactor: 3.0),
      );

      expect(wrapped.view(id: 1)!.devicePixelRatio, 2.0);
      expect(wrapped.view(id: 2)!.devicePixelRatio, 7.0);
      expect(wrapped.view(id: 1)!.platformDispatcher.textScaleFactor, 1.0);
      expect(wrapped.view(id: 2)!.platformDispatcher.textScaleFactor, 3.0);
      expect(wrapped.textScaleFactor, 1.0);
    });
  });

  group('the wrapper applies overrides', () {
    late ui.PlatformDispatcher real;
    late ui.PlatformDispatcher wrapped;
    late ui.FlutterView wrappedView;
    late int viewId;

    setUp(() {
      real = ui.PlatformDispatcher.instance;
      wrapped = debugApplyViewMetricsOverrides(real);
      wrappedView = wrapped.implicitView!;
      viewId = wrappedView.viewId;
    });

    tearDown(debugClearViewMetricsOverrides);

    test('to the view metrics', () {
      debugSetViewMetricsOverride(
        viewId,
        const DebugViewMetricsOverride(
          devicePixelRatio: 7.0,
          physicalSize: ui.Size(1170, 2532),
          padding: DebugViewPadding(top: 141),
          viewPadding: DebugViewPadding(top: 141, bottom: 34),
          viewInsets: DebugViewPadding(bottom: 700),
        ),
      );
      expect(wrappedView.devicePixelRatio, 7.0);
      expect(wrappedView.physicalSize, const ui.Size(1170, 2532));
      expect(wrappedView.physicalConstraints, ui.ViewConstraints.tight(const ui.Size(1170, 2532)));
      expect(wrappedView.padding.top, 141);
      expect(wrappedView.viewPadding.bottom, 34);
      expect(wrappedView.viewInsets.bottom, 700);
      // Metrics that were not overridden still come from the platform.
      expect(wrappedView.systemGestureInsets, same(real.implicitView!.systemGestureInsets));
      expect(wrappedView.displayFeatures, real.implicitView!.displayFeatures);
    });

    test('to the platform metrics', () {
      debugSetViewMetricsOverride(
        viewId,
        const DebugViewMetricsOverride(
          textScaleFactor: 2.5,
          platformBrightness: ui.Brightness.dark,
          alwaysUse24HourFormat: true,
          boldText: true,
          highContrast: true,
          supportsAnnounce: false,
        ),
      );
      expect(wrapped.textScaleFactor, 2.5);
      expect(wrapped.platformBrightness, ui.Brightness.dark);
      expect(wrapped.alwaysUse24HourFormat, isTrue);
      expect(wrapped.accessibilityFeatures.boldText, isTrue);
      expect(wrapped.accessibilityFeatures.highContrast, isTrue);
      expect(wrapped.accessibilityFeatures.supportsAnnounce, isFalse);
      // Flags that were not overridden still come from the platform.
      expect(wrapped.accessibilityFeatures.invertColors, real.accessibilityFeatures.invertColors);
      expect(
        wrapped.accessibilityFeatures.accessibleNavigation,
        real.accessibilityFeatures.accessibleNavigation,
      );
    });

    test('to font sizes, linearly', () {
      debugSetViewMetricsOverride(viewId, const DebugViewMetricsOverride(textScaleFactor: 2.5));
      // An overridden text scale factor has to reach scaleFontSize too:
      // SystemTextScaler.scale calls it, so overriding only textScaleFactor
      // would change what MediaQuery reports without changing any text.
      expect(wrapped.scaleFontSize(14.0), 35.0);
      expect(wrapped.scaleFontSize(14.5), 36.25);
      expect(wrappedView.platformDispatcher.scaleFontSize(10.0), 25.0);
    });

    test('to the accessibility features, for consumers that pattern match them', () {
      // Cupertino's menu anchor switches on the features object with an
      // `AccessibilityFeatures(disableAnimations: true)` object pattern, which
      // only matches if the overridden object is still an AccessibilityFeatures.
      debugSetViewMetricsOverride(viewId, const DebugViewMetricsOverride(disableAnimations: true));
      final ui.AccessibilityFeatures features = wrapped.accessibilityFeatures;
      expect(features, isA<ui.AccessibilityFeatures>());
      expect(switch (features) {
        ui.AccessibilityFeatures(disableAnimations: true) => 'disableAnimations',
        ui.AccessibilityFeatures(reduceMotion: true) => 'reduceMotion',
        _ => 'neither',
      }, 'disableAnimations');
    });

    test('to the accessibility features, without disturbing equality', () {
      final ui.AccessibilityFeatures platformFeatures = real.accessibilityFeatures;
      debugSetViewMetricsOverride(viewId, const DebugViewMetricsOverride(boldText: true));
      final ui.AccessibilityFeatures overridden = wrapped.accessibilityFeatures;
      expect(overridden, isNot(same(platformFeatures)));
      expect(overridden == platformFeatures, isFalse);
      expect(platformFeatures == overridden, isFalse);
      expect(overridden, equals(wrapped.accessibilityFeatures));
      expect(overridden.hashCode, wrapped.accessibilityFeatures.hashCode);
      expect(overridden.toString(), contains('boldText'));
    });

    test('only to the view they name', () {
      // 1 is not a real view id in this test environment, so the implicit view
      // must be unaffected by an override registered for it.
      final double realRatio = real.implicitView!.devicePixelRatio;
      debugSetViewMetricsOverride(
        viewId + 1000,
        const DebugViewMetricsOverride(devicePixelRatio: 7.0),
      );
      expect(wrappedView.devicePixelRatio, realRatio);
    });

    test('to the size a scene without one is rendered at', () {
      // FlutterView.render takes the view's own physicalSize when it is given
      // no size, and this view's physical size is the overridden one. Forwarded
      // as omitted, it would resolve to the size the platform reports instead.
      final fake = _TwoViewPlatformDispatcher();
      final ui.FlutterView wrappedView = debugApplyViewMetricsOverrides(fake).view(id: 1)!;
      final ui.Scene scene = ui.SceneBuilder().build();
      addTearDown(scene.dispose);
      debugSetViewMetricsOverride(
        1,
        const DebugViewMetricsOverride(physicalSize: ui.Size(400, 800)),
      );

      wrappedView.render(scene);
      expect(fake.viewFor(1).renderedSize, const ui.Size(400, 800));

      // A size the caller gives is the caller's.
      wrappedView.render(scene, size: const ui.Size(10, 20));
      expect(fake.viewFor(1).renderedSize, const ui.Size(10, 20));
    });

    test('and forwards a scene with no size to a view with no size override', () {
      // Only an override supplies a size that was not asked for. Resolving the
      // omission against the size the platform already reports would answer the
      // same, but it is not the same request: the web engine takes a size it is
      // given as a resize and writes it to the DOM, so a wrapper that is
      // supposed to cost nothing while nothing is overridden would cost a
      // reflow on every frame.
      final fake = _TwoViewPlatformDispatcher();
      final ui.FlutterView wrappedView = debugApplyViewMetricsOverrides(fake).view(id: 1)!;
      final ui.Scene scene = ui.SceneBuilder().build();
      addTearDown(scene.dispose);

      wrappedView.render(scene);
      expect(fake.viewFor(1).renders, 1, reason: 'the scene still has to reach the view');
      expect(fake.viewFor(1).renderedSize, isNull);

      // Nor does an override that leaves the size alone supply one.
      debugSetViewMetricsOverride(1, const DebugViewMetricsOverride(devicePixelRatio: 3.0));
      wrappedView.render(scene);
      expect(fake.viewFor(1).renders, 2);
      expect(fake.viewFor(1).renderedSize, isNull);

      // Nor does one registered for a different view: each view resolves its
      // own entry, not whichever one happens to be registered.
      debugSetViewMetricsOverride(
        2,
        const DebugViewMetricsOverride(physicalSize: ui.Size(400, 800)),
      );
      wrappedView.render(scene);
      expect(fake.viewFor(1).renderedSize, isNull);
      debugApplyViewMetricsOverrides(fake).view(id: 2)!.render(scene);
      expect(fake.viewFor(2).renderedSize, const ui.Size(400, 800));
    });

    test('overriding a size makes the view a fixed size view', () {
      debugSetViewMetricsOverride(
        viewId,
        const DebugViewMetricsOverride(physicalSize: ui.Size(400, 800)),
      );
      expect(wrappedView.physicalConstraints.isTight, isTrue);
      expect(wrappedView.physicalConstraints.isSatisfiedBy(const ui.Size(400, 800)), isTrue);
      expect(wrappedView.physicalConstraints.isSatisfiedBy(const ui.Size(10, 10)), isFalse);
    });
  });

  group('an override change is reported', () {
    tearDown(debugClearViewMetricsOverrides);

    test('to the dispatcher the framework registered its callbacks on', () {
      // A binding that supplies its own PlatformDispatcher registers the
      // framework's callbacks on that one, so reporting an override to
      // ui.PlatformDispatcher.instance would leave such an application stale:
      // its overridden metrics would change with nothing told to re-read them.
      final fake = _TwoViewPlatformDispatcher();
      final ui.PlatformDispatcher wrapped = debugApplyViewMetricsOverrides(fake);
      var metricsChanged = 0;
      var textScaleFactorChanged = 0;
      wrapped.onMetricsChanged = () => metricsChanged += 1;
      wrapped.onTextScaleFactorChanged = () => textScaleFactorChanged += 1;

      debugSetViewMetricsOverride(1, const DebugViewMetricsOverride(devicePixelRatio: 3.0));
      expect(metricsChanged, 1);
      expect(textScaleFactorChanged, 0);

      // The ratio goes away as the factor arrives, so both groups changed.
      debugSetViewMetricsOverride(1, const DebugViewMetricsOverride(textScaleFactor: 2.0));
      expect(metricsChanged, 2);
      expect(textScaleFactorChanged, 1);

      debugClearViewMetricsOverrides();
      expect(metricsChanged, 2);
      expect(textScaleFactorChanged, 2);
    });

    test('through onPlatformConfigurationChanged as well, once', () {
      // dart:ui reports everything in its platform configuration through the
      // umbrella notification first, and then through the callback for the
      // field that changed, when that field has one.
      final fake = _TwoViewPlatformDispatcher();
      final ui.PlatformDispatcher wrapped = debugApplyViewMetricsOverrides(fake);
      final notifications = <String>[];
      wrapped.onPlatformConfigurationChanged = () => notifications.add('configuration');
      wrapped.onTextScaleFactorChanged = () => notifications.add('textScaleFactor');
      wrapped.onPlatformBrightnessChanged = () => notifications.add('platformBrightness');
      wrapped.onAccessibilityFeaturesChanged = () => notifications.add('accessibilityFeatures');
      wrapped.onMetricsChanged = () => notifications.add('metrics');

      // View metrics are not part of the platform configuration.
      debugSetViewMetricsOverride(1, const DebugViewMetricsOverride(devicePixelRatio: 3.0));
      expect(notifications, <String>['metrics']);

      notifications.clear();
      debugSetViewMetricsOverride(
        1,
        const DebugViewMetricsOverride(
          devicePixelRatio: 3.0,
          textScaleFactor: 2.0,
          platformBrightness: ui.Brightness.dark,
          boldText: true,
        ),
      );
      expect(notifications, <String>[
        'configuration',
        'textScaleFactor',
        'platformBrightness',
        'accessibilityFeatures',
      ]);

      // The 24 hour format has no callback of its own: the configuration
      // notification is the only one that names it, and onMetricsChanged is
      // what tells the framework to re-read it.
      notifications.clear();
      debugSetViewMetricsOverride(
        1,
        const DebugViewMetricsOverride(
          devicePixelRatio: 3.0,
          textScaleFactor: 2.0,
          platformBrightness: ui.Brightness.dark,
          boldText: true,
          alwaysUse24HourFormat: true,
        ),
      );
      expect(notifications, <String>['configuration', 'metrics']);
    });

    test('for every metric there is, through exactly the callbacks dart:ui would', () {
      // The completeness guard for the notification groupings: a metric added
      // to DebugViewMetricsOverride has to reach the notification that reports
      // it, and no other, rather than compare and store correctly while never
      // being announced or announcing something that did not change.
      const viewMetrics = <String>{
        'devicePixelRatio',
        'physicalSize',
        'padding',
        'viewPadding',
        'viewInsets',
      };
      expect(
        _perMetricChange.keys.toSet(),
        _allOverridableMetrics(),
        reason: 'this table is the enumeration the guards below run over',
      );

      final fake = _TwoViewPlatformDispatcher();
      final ui.PlatformDispatcher wrapped = debugApplyViewMetricsOverrides(fake);
      final notifications = <String>[];
      wrapped.onPlatformConfigurationChanged = () => notifications.add('configuration');
      wrapped.onMetricsChanged = () => notifications.add('metrics');
      wrapped.onTextScaleFactorChanged = () => notifications.add('textScaleFactor');
      wrapped.onPlatformBrightnessChanged = () => notifications.add('platformBrightness');
      wrapped.onAccessibilityFeaturesChanged = () => notifications.add('accessibilityFeatures');

      for (final MapEntry<String, DebugViewMetricsOverride Function(DebugViewMetricsOverride)> entry
          in _perMetricChange.entries) {
        debugSetViewMetricsOverride(1, _fullyPopulated);
        notifications.clear();
        debugSetViewMetricsOverride(1, entry.value(_fullyPopulated));
        expect(notifications.toSet(), switch (entry.key) {
          // dart:ui has no callback of its own for the 24 hour format: it
          // reports it through the configuration notification, and the
          // framework re-reads it when the view metrics change.
          'alwaysUse24HourFormat' => <String>{'configuration', 'metrics'},
          'textScaleFactor' => <String>{'configuration', 'textScaleFactor'},
          'platformBrightness' => <String>{'configuration', 'platformBrightness'},
          final String metric when viewMetrics.contains(metric) => <String>{'metrics'},
          _ => <String>{'configuration', 'accessibilityFeatures'},
        }, reason: 'changing ${entry.key} announced $notifications');
      }
    });

    test('and its views apply it whether or not it is a target', () {
      // Being told about a change is not what makes a view apply an override:
      // a view that MediaQueryData.fromView credits with one has to be a view
      // that applies it, or it reports neither the override nor the platform
      // data an ancestor supplied.
      final fake = _TwoViewPlatformDispatcher();
      final ui.FlutterView raw = fake.view(id: 1)!;
      debugApplyViewMetricsOverridesForView(fake, 1);
      debugSetViewMetricsOverride(1, const DebugViewMetricsOverride(devicePixelRatio: 7.0));

      expect(debugViewWithMetricsOverrides(raw).devicePixelRatio, 7.0);
    });

    test('but not to a dispatcher that was only asked to resolve a view id', () {
      // A dispatcher becomes a notification target by being wrapped, which is
      // what a binding does with the dispatcher it registers the framework's
      // callbacks on. Resolving a view id against one says nothing about that,
      // and reading callbacks off a dispatcher nobody registered any on is how
      // an incomplete test double starts throwing from an unrelated test.
      final fake = _TwoViewPlatformDispatcher();
      debugApplyViewMetricsOverridesForView(fake, 1);
      var metricsChanged = 0;
      fake.onMetricsChanged = () => metricsChanged += 1;

      debugSetViewMetricsOverride(1, const DebugViewMetricsOverride(devicePixelRatio: 3.0));
      expect(metricsChanged, 0);
    });

    test('to one wrapped for a view first and as a binding dispatcher after', () {
      // Resolving a view id first must not keep a dispatcher from becoming a
      // notification target when a binding wraps it afterwards, and wrapping it
      // again must not make it one twice over.
      final fake = _TwoViewPlatformDispatcher();
      debugApplyViewMetricsOverridesForView(fake, 1);
      final ui.PlatformDispatcher wrapped = debugApplyViewMetricsOverrides(fake);
      debugApplyViewMetricsOverrides(fake);
      var metricsChanged = 0;
      wrapped.onMetricsChanged = () => metricsChanged += 1;

      debugSetViewMetricsOverride(1, const DebugViewMetricsOverride(devicePixelRatio: 3.0));
      expect(metricsChanged, 1);
    });

    test('in the zone each callback was registered in', () {
      // dart:ui runs a notification in the zone its callback was registered in
      // rather than wherever the event was delivered from, and a replayed one
      // has to as well: a callback that runs in whichever zone changed the
      // override loses that zone's values and its error handling.
      //
      // Each callback is registered in a zone of its own, so that a replay
      // which reaches for the wrong one of the five recorded zones is caught
      // rather than answering alike.
      final fake = _TwoViewPlatformDispatcher();
      final ui.PlatformDispatcher wrapped = debugApplyViewMetricsOverrides(fake);
      final ranIn = <Object?>[];
      void registerIn(String zone, void Function(ui.VoidCallback callback) register) {
        runZoned(
          () => register(() => ranIn.add(Zone.current[#viewMetricsTestZone])),
          zoneValues: <Object?, Object?>{#viewMetricsTestZone: zone},
        );
      }

      registerIn('configuration', (cb) => wrapped.onPlatformConfigurationChanged = cb);
      registerIn('textScaleFactor', (cb) => wrapped.onTextScaleFactorChanged = cb);
      registerIn('brightness', (cb) => wrapped.onPlatformBrightnessChanged = cb);
      registerIn('accessibility', (cb) => wrapped.onAccessibilityFeaturesChanged = cb);
      registerIn('metrics', (cb) => wrapped.onMetricsChanged = cb);

      runZoned(() {
        debugSetViewMetricsOverride(
          1,
          const DebugViewMetricsOverride(
            devicePixelRatio: 3.0,
            textScaleFactor: 2.0,
            platformBrightness: ui.Brightness.dark,
            boldText: true,
          ),
        );
      }, zoneValues: <Object?, Object?>{#viewMetricsTestZone: 'mutation'});

      // In dart:ui's order, each in its own zone.
      expect(ranIn, <Object?>[
        'configuration',
        'textScaleFactor',
        'brightness',
        'accessibility',
        'metrics',
      ]);
    });

    test('as this replay when a callback fails, not into the zone it belongs to', () {
      // Running the callback rather than guarding it is what keeps a failure
      // reportable: dart:ui's own dispatch would hand it to the registration
      // zone, and a notification the framework synthesized would surface as one
      // the platform sent, in a zone that has nothing to do with the override
      // that was changed.
      final fake = _TwoViewPlatformDispatcher();
      final ui.PlatformDispatcher wrapped = debugApplyViewMetricsOverrides(fake);
      final reported = <String>[];
      final libraries = <String?>[];
      final stacks = <StackTrace?>[];
      var brightnessChanged = 0;
      runZoned(() {
        wrapped.onTextScaleFactorChanged = () => throw StateError('boom');
        wrapped.onPlatformBrightnessChanged = () => brightnessChanged += 1;
      }, zoneValues: <Object?, Object?>{#viewMetricsTestZone: 'registration'});
      // A wrapped dispatcher is told about every later override change too, for
      // as long as it is alive, so a callback that throws has to stop throwing
      // before the tear-down that clears this test's override runs.
      addTearDown(() {
        wrapped.onTextScaleFactorChanged = null;
        wrapped.onPlatformBrightnessChanged = null;
      });

      final FlutterExceptionHandler? previousOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        reported.add(details.context.toString());
        libraries.add(details.library);
        stacks.add(details.stack);
      };
      addTearDown(() => FlutterError.onError = previousOnError);

      debugSetViewMetricsOverride(
        1,
        const DebugViewMetricsOverride(
          textScaleFactor: 2.0,
          platformBrightness: ui.Brightness.dark,
        ),
      );

      expect(reported, <String>[
        'while telling a PlatformDispatcher that a debug view metrics override changed',
      ]);
      expect(libraries, <String>['foundation library']);
      expect(stacks.single, isNotNull, reason: 'a report without a stack cannot be traced');
      // And the notification after the failing one still happened.
      expect(brightnessChanged, 1);
    });

    test('in the zone a callback registered through one of its views was', () {
      // A view's platformDispatcher is a wrapper of its own, and setting a
      // callback on it sets it on the very dispatcher the root wrapper replays
      // through. The zone it captured has to reach that replay, or the root has
      // none and falls back to whichever zone changed the override.
      final fake = _TwoViewPlatformDispatcher();
      final ui.PlatformDispatcher wrapped = debugApplyViewMetricsOverrides(fake);
      final ui.PlatformDispatcher perView = wrapped.view(id: 1)!.platformDispatcher;
      final ranIn = <Object?>[];
      void registerIn(String zone, void Function(ui.VoidCallback callback) register) {
        runZoned(
          () => register(() => ranIn.add(Zone.current[#viewMetricsTestZone])),
          zoneValues: <Object?, Object?>{#viewMetricsTestZone: zone},
        );
      }

      // All five, because each setter records the zone for itself.
      registerIn('configuration', (cb) => perView.onPlatformConfigurationChanged = cb);
      registerIn('textScaleFactor', (cb) => perView.onTextScaleFactorChanged = cb);
      registerIn('brightness', (cb) => perView.onPlatformBrightnessChanged = cb);
      registerIn('accessibility', (cb) => perView.onAccessibilityFeaturesChanged = cb);
      registerIn('metrics', (cb) => perView.onMetricsChanged = cb);

      runZoned(() {
        debugSetViewMetricsOverride(
          1,
          const DebugViewMetricsOverride(
            devicePixelRatio: 3.0,
            textScaleFactor: 2.0,
            platformBrightness: ui.Brightness.dark,
            boldText: true,
          ),
        );
      }, zoneValues: <Object?, Object?>{#viewMetricsTestZone: 'mutation'});

      expect(ranIn, <Object?>[
        'configuration',
        'textScaleFactor',
        'brightness',
        'accessibility',
        'metrics',
      ]);
    });

    test('and a callback that cannot even be read is reported like one that throws', () {
      // Reading the callback is inside the guard, not only calling it: a
      // dispatcher that implements dart:ui through noSuchMethod throws from the
      // read, and the notifications after it still have to happen.
      final fake = _UnreadableCallbackPlatformDispatcher();
      final ui.PlatformDispatcher wrapped = debugApplyViewMetricsOverrides(fake);
      var textScaleFactorChanged = 0;
      wrapped.onTextScaleFactorChanged = () => textScaleFactorChanged += 1;
      addTearDown(() {
        fake.unreadable = false;
        wrapped.onTextScaleFactorChanged = null;
      });

      final errors = <Object>[];
      final FlutterExceptionHandler? previousOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) => errors.add(details.exception);
      addTearDown(() => FlutterError.onError = previousOnError);

      debugSetViewMetricsOverride(
        1,
        const DebugViewMetricsOverride(devicePixelRatio: 3.0, textScaleFactor: 2.0),
      );

      expect(errors.single, isUnimplementedError);
      expect(textScaleFactorChanged, 1);
    });

    test('to one reached through a wrapper of its own', () {
      // What BindingBase.platformDispatcher tells a subclass to wrap can
      // already be a wrapper. Notifying it means notifying the dispatcher its
      // callbacks were forwarded to.
      final fake = _TwoViewPlatformDispatcher();
      debugApplyViewMetricsOverrides(debugApplyViewMetricsOverridesForView(fake, 1));
      var metricsChanged = 0;
      fake.onMetricsChanged = () => metricsChanged += 1;

      debugSetViewMetricsOverride(1, const DebugViewMetricsOverride(devicePixelRatio: 3.0));
      expect(metricsChanged, 1);

      // And the dispatcher underneath it is the same one, so wrapping that
      // does not make it a second target.
      debugApplyViewMetricsOverrides(fake);
      debugClearViewMetricsOverrides();

      expect(metricsChanged, 2);
    });

    test('through every callback and to every dispatcher, even when one fails', () {
      // A metric that changed and was not reported leaves the framework reading
      // a value nothing told it to re-read. Neither the notifications after a
      // failing one, nor the dispatchers after it — the framework's own is one
      // of them — may be skipped because of it.
      final failing = _TwoViewPlatformDispatcher();
      final reached = _TwoViewPlatformDispatcher();
      final ui.PlatformDispatcher wrapped = debugApplyViewMetricsOverrides(failing);
      wrapped.onPlatformConfigurationChanged = () =>
          throw StateError('this dispatcher cannot be notified');
      // Unregistered here rather than at the end of the body: the tear down
      // replays this override once more, and an expectation that fails below
      // would otherwise leave something to throw from every later test.
      addTearDown(() => wrapped.onPlatformConfigurationChanged = null);
      var stillTold = 0;
      wrapped.onTextScaleFactorChanged = () => stillTold += 1;
      wrapped.onMetricsChanged = () => stillTold += 1;
      var notified = 0;
      debugApplyViewMetricsOverrides(reached).onMetricsChanged = () => notified += 1;

      final errors = <Object>[];
      final FlutterExceptionHandler? previousOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) => errors.add(details.exception);
      addTearDown(() => FlutterError.onError = previousOnError);

      debugSetViewMetricsOverride(
        1,
        const DebugViewMetricsOverride(devicePixelRatio: 3.0, textScaleFactor: 2.0),
      );

      // Reported rather than thrown, so that a caller is not left with an
      // override installed and half the application told about it.
      expect(errors, hasLength(1));
      expect(errors.single, isStateError);
      // The failing dispatcher still heard about the factor and the metrics.
      expect(stillTold, 2);
      expect(notified, 1);
    });
  });
}
