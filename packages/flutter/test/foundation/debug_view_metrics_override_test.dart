// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
  systemGestureInsets: DebugViewPadding(left: 13, top: 14, right: 15, bottom: 16),
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
      'systemGestureInsets': (DebugViewMetricsOverride o) =>
          o.copyWith(systemGestureInsets: const DebugViewPadding.all(99)),
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

class _NegativeViewPadding implements ui.ViewPadding {
  const _NegativeViewPadding({this.left = 0, this.top = 0, this.right = 0, this.bottom = 0});

  @override
  final double left;

  @override
  final double top;

  @override
  final double right;

  @override
  final double bottom;
}

void main() {
  group('DebugViewMetricsOverride', () {
    test('the per-metric table covers every metric', () {
      expect(
        _perMetricChange.keys.toSet(),
        _allOverridableMetrics(),
        reason: 'this table is the enumeration the guards below run over',
      );
    });

    test('an empty override overrides nothing', () {
      expect(const DebugViewMetricsOverride().isEmpty, isTrue);
      expect(const DebugViewMetricsOverride().isNotEmpty, isFalse);
      expect(const DebugViewMetricsOverride(devicePixelRatio: 2.0).isEmpty, isFalse);
      expect(const DebugViewMetricsOverride(devicePixelRatio: 2.0).isNotEmpty, isTrue);
      expect(const DebugViewMetricsOverride(boldText: false).isEmpty, isFalse);
      expect(const DebugViewMetricsOverride(boldText: false).isNotEmpty, isTrue);
      expect(_fullyPopulated.isEmpty, isFalse);
      expect(_fullyPopulated.isNotEmpty, isTrue);
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
        systemGestureInsets: DebugViewPadding(left: 13, top: 14, right: 15, bottom: 16),
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
      // An omitted argument leaves the existing override in place, and so does
      // an explicit null: null is what an unset metric already reads as, so a
      // caller forwarding an optional value cannot clear one by accident.
      expect(original.copyWith().boldText, isTrue);
      bool? forwarded;
      expect(original.copyWith(boldText: forwarded).boldText, isTrue);
      // Clearing is spelled out, so that it cannot be requested by accident.
      expect(original.copyWith(clear: const {DebugViewMetric.boldText}).boldText, isNull);
      expect(original.copyWith(clear: const {DebugViewMetric.boldText}).devicePixelRatio, 2.0);
      expect(
        original.copyWith(clear: const {DebugViewMetric.devicePixelRatio}).devicePixelRatio,
        isNull,
      );
      // Setting and clearing the same metric in one call is contradictory, and
      // is caught rather than resolved in favour of either one.
      expect(
        () => original.copyWith(
          devicePixelRatio: 3.0,
          clear: const {DebugViewMetric.devicePixelRatio},
        ),
        throwsAssertionError,
      );

      // Passing invalid geometry or ratios throws an error.
      expect(
        () => original.copyWith(physicalSize: const ui.Size(-10, 10)),
        throwsA(isA<FlutterError>()),
      );
      expect(() => original.copyWith(devicePixelRatio: 0.0), throwsAssertionError);
      expect(() => original.copyWith(textScaleFactor: -1.0), throwsAssertionError);
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

    test('copyWith changes only the metric it names', () {
      // The checks above assert only that changing a metric changes something.
      // A copyWith that wrote to the wrong field, or a toJson that emitted the
      // right value under the wrong key, would satisfy them. Comparing the
      // whole serialized form pins each metric to its own key without naming
      // all of them twice.
      final Map<String, Object?> base = _fullyPopulated.toJson();
      for (final MapEntry<String, DebugViewMetricsOverride Function(DebugViewMetricsOverride)> entry
          in _perMetricChange.entries) {
        final Map<String, Object?> changed = entry.value(_fullyPopulated).toJson();
        expect(
          changed[entry.key],
          isNot(base[entry.key]),
          reason: 'Changing ${entry.key} left ${entry.key} alone.',
        );
        for (final String other in base.keys.where((String key) => key != entry.key)) {
          expect(changed[other], base[other], reason: 'Changing ${entry.key} also changed $other.');
        }
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
      expect(DebugViewMetricsOverride.fromJson(const <String, Object?>{}).isNotEmpty, isFalse);
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
          'padding': <String, Object?>{'left': 'not-a-number'},
        }),
        throwsFormatException,
      );
      // Partial padding maps are accepted and default missing edges to 0.
      expect(
        DebugViewMetricsOverride.fromJson(const <String, Object?>{
          'padding': <String, Object?>{'left': 1, 'top': 2, 'right': 3},
        }).padding,
        const DebugViewPadding(left: 1, top: 2, right: 3),
      );
      // Loosely typed / un-reified maps are accepted for both the payload and nested geometry.
      expect(
        DebugViewMetricsOverride.fromJson(const <dynamic, dynamic>{
          'padding': <dynamic, dynamic>{'left': 10, 'top': 20},
          'physicalSize': <dynamic, dynamic>{'width': 800, 'height': 600},
        }),
        const DebugViewMetricsOverride(
          padding: DebugViewPadding(left: 10, top: 20),
          physicalSize: ui.Size(800, 600),
        ),
      );
      // Unknown members inside an un-reified map are rejected.
      expect(
        () => DebugViewMetricsOverride.fromJson(const <dynamic, dynamic>{
          'padding': <dynamic, dynamic>{'left': 10, 'unknown': 20},
        }),
        throwsFormatException,
      );
      expect(
        () => DebugViewMetricsOverride.fromJson(const <dynamic, dynamic>{
          'physicalSize': <dynamic, dynamic>{'width': 800, 'height': 600, 'extra': 5},
        }),
        throwsFormatException,
      );
      expect(
        DebugViewMetricsOverride.fromJson(const <String, Object?>{
          'systemGestureInsets': <String, Object?>{'top': 48},
        }).systemGestureInsets,
        const DebugViewPadding(top: 48),
      );
      expect(
        DebugViewMetricsOverride.fromJson(const <String, Object?>{
          'platformBrightness': 'Brightness.dark',
        }).platformBrightness,
        ui.Brightness.dark,
      );
      expect(
        DebugViewMetricsOverride.fromJson(const <String, Object?>{
          'platformBrightness': 'Brightness.light',
        }).platformBrightness,
        ui.Brightness.light,
      );
      expect(
        DebugViewMetricsOverride.fromJson(const <String, Object?>{'platformBrightness': 'dark'})
            .platformBrightness,
        ui.Brightness.dark,
      );
      expect(
        DebugViewMetricsOverride.fromJson(const <String, Object?>{'platformBrightness': 'light'})
            .platformBrightness,
        ui.Brightness.light,
      );
      expect(
        DebugViewMetricsOverride.fromJson(const <String, Object?>{
          'platformBrightness': ui.Brightness.dark,
        }).platformBrightness,
        ui.Brightness.dark,
      );
      expect(
        DebugViewMetricsOverride.fromJson(const <String, Object?>{
          'platformBrightness': ui.Brightness.light,
        }).platformBrightness,
        ui.Brightness.light,
      );
      expect(
        () => DebugViewMetricsOverride.fromJson(const <String, Object?>{
          'platformBrightness': 'DARK',
        }),
        throwsA(
          isA<FormatException>().having(
            (FormatException e) => e.message,
            'message',
            contains(
              'Expected "light", "dark", "Brightness.light", "Brightness.dark", or a Brightness enum',
            ),
          ),
        ),
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

      for (final key in <String>['padding', 'viewPadding', 'viewInsets', 'systemGestureInsets']) {
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

    test('fromViewPadding copies all edges from a ui.ViewPadding', () {
      final copyFromZero = DebugViewPadding.fromViewPadding(ui.ViewPadding.zero);
      expect(copyFromZero, DebugViewPadding.zero);

      const ui.ViewPadding original = DebugViewPadding(left: 10, top: 20, right: 30, bottom: 40);
      final copy = DebugViewPadding.fromViewPadding(original);
      expect(copy.left, 10.0);
      expect(copy.top, 20.0);
      expect(copy.right, 30.0);
      expect(copy.bottom, 40.0);
      expect(copy, original);
    });

    test('copyWith updates specified edges and preserves others', () {
      const original = DebugViewPadding(left: 1, top: 2, right: 3, bottom: 4);
      expect(original.copyWith(), original);
      expect(
        original.copyWith(left: 10),
        const DebugViewPadding(left: 10, top: 2, right: 3, bottom: 4),
      );
      expect(
        original.copyWith(top: 20),
        const DebugViewPadding(left: 1, top: 20, right: 3, bottom: 4),
      );
      expect(
        original.copyWith(right: 30),
        const DebugViewPadding(left: 1, top: 2, right: 30, bottom: 4),
      );
      expect(
        original.copyWith(bottom: 40),
        const DebugViewPadding(left: 1, top: 2, right: 3, bottom: 40),
      );
      expect(
        original.copyWith(left: 10, top: 20, right: 30, bottom: 40),
        const DebugViewPadding(left: 10, top: 20, right: 30, bottom: 40),
      );
      expect(() => original.copyWith(left: -1), throwsAssertionError);
      expect(() => original.copyWith(top: -1), throwsAssertionError);
      expect(() => original.copyWith(right: -1), throwsAssertionError);
      expect(() => original.copyWith(bottom: -1), throwsAssertionError);
    });

    test('rejects negative or non-finite distances', () {
      expect(() => DebugViewPadding(left: -1), throwsAssertionError);
      expect(() => DebugViewPadding(left: double.nan), throwsAssertionError);
      expect(() => DebugViewPadding(top: -1), throwsAssertionError);
      expect(() => DebugViewPadding(top: double.nan), throwsAssertionError);
      expect(() => DebugViewPadding(right: -1), throwsAssertionError);
      expect(() => DebugViewPadding(right: double.infinity), throwsAssertionError);
      expect(() => DebugViewPadding(bottom: -1), throwsAssertionError);
      expect(() => DebugViewPadding(bottom: double.infinity), throwsAssertionError);
      expect(() => DebugViewPadding.all(-1), throwsAssertionError);
      expect(() => DebugViewPadding.all(double.nan), throwsAssertionError);
      expect(() => DebugViewPadding.all(double.infinity), throwsAssertionError);
      expect(
        () => DebugViewPadding.fromViewPadding(const _NegativeViewPadding(left: -1)),
        throwsAssertionError,
      );
      expect(
        () => DebugViewPadding.fromViewPadding(const _NegativeViewPadding(top: -1)),
        throwsAssertionError,
      );
      expect(
        () => DebugViewPadding.fromViewPadding(const _NegativeViewPadding(right: -1)),
        throwsAssertionError,
      );
      expect(
        () => DebugViewPadding.fromViewPadding(const _NegativeViewPadding(bottom: -1)),
        throwsAssertionError,
      );
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
      expect(debugViewMetricsOverrides[7], const DebugViewMetricsOverride(boldText: false));

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
      // physicalSize cannot assert in a const constructor, and tooling payloads
      // go through fromJson, so debugSetViewMetricsOverride is the only gate a
      // directly built override with an invalid physicalSize passes through.
      const invalid = <DebugViewMetricsOverride>[
        DebugViewMetricsOverride(physicalSize: ui.Size(double.nan, 100)),
        DebugViewMetricsOverride(physicalSize: ui.Size(100, double.infinity)),
        DebugViewMetricsOverride(physicalSize: ui.Size(-1, 100)),
        DebugViewMetricsOverride(physicalSize: ui.Size(100, -1)),
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
          const DebugViewMetricsOverride(physicalSize: ui.Size(-1, -1)),
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
}
