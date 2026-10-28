// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// An override in which every metric is set, and set to something other than
/// what the test environment reports, so that a metric that fails to round trip
/// or to compare cannot hide behind a coincidence.
const DebugViewMetricsOverride _fullyPopulated = DebugViewMetricsOverride(
  devicePixelRatio: 3.5,
  physicalSize: ui.Size(1170, 2532),
  textScaling: <ui.Offset>[ui.Offset(8, 16), ui.Offset(30, 38), ui.Offset(100, 100)],
  platformBrightness: ui.Brightness.dark,
  padding: FakeViewPadding(left: 1, top: 2, right: 3, bottom: 4),
  viewPadding: FakeViewPadding(left: 5, top: 6, right: 7, bottom: 8),
  viewInsets: FakeViewPadding(left: 9, top: 10, right: 11, bottom: 12),
  systemGestureInsets: FakeViewPadding(left: 13, top: 14, right: 15, bottom: 16),
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

/// A padding that shares no edge with any padding of [_fullyPopulated].
const FakeViewPadding _otherPadding = FakeViewPadding(left: 99, top: 99, right: 99, bottom: 99);

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
      'textScaling': (DebugViewMetricsOverride o) =>
          o.copyWith(textScaling: const <ui.Offset>[ui.Offset(1, 0.5)]),
      'platformBrightness': (DebugViewMetricsOverride o) =>
          o.copyWith(platformBrightness: ui.Brightness.light),
      'padding': (DebugViewMetricsOverride o) => o.copyWith(padding: _otherPadding),
      'viewPadding': (DebugViewMetricsOverride o) => o.copyWith(viewPadding: _otherPadding),
      'viewInsets': (DebugViewMetricsOverride o) => o.copyWith(viewInsets: _otherPadding),
      'systemGestureInsets': (DebugViewMetricsOverride o) =>
          o.copyWith(systemGestureInsets: _otherPadding),
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

/// Tables that cannot be interpolated, or that would report a scale factor
/// that is not a finite number, by what is wrong with each.
///
/// Both gates, [DebugViewMetricsOverride.fromJson] and
/// [debugSetViewMetricsOverride], have to reject every one of them.
const Map<String, List<ui.Offset>> _invalidTextScaling = <String, List<ui.Offset>>{
  'no points': <ui.Offset>[],
  'zero unscaled size': <ui.Offset>[ui.Offset(0, 1)],
  'negative unscaled size': <ui.Offset>[ui.Offset(-1, 1)],
  'infinite unscaled size': <ui.Offset>[ui.Offset(double.infinity, 1)],
  'NaN unscaled size': <ui.Offset>[ui.Offset(double.nan, 1)],
  'negative scaled size': <ui.Offset>[ui.Offset(1, -1)],
  'infinite scaled size': <ui.Offset>[ui.Offset(1, double.infinity)],
  'NaN scaled size': <ui.Offset>[ui.Offset(1, double.nan)],
  'repeated unscaled size': <ui.Offset>[ui.Offset(1, 1), ui.Offset(1, 2)],
  'decreasing unscaled size': <ui.Offset>[ui.Offset(2, 2), ui.Offset(1, 1)],
  'decreasing scaled size': <ui.Offset>[ui.Offset(1, 2), ui.Offset(2, 1)],
};

/// The edges of a [ui.ViewPadding], which has no `==` of its own and which
/// the web engine builds afresh on every read.
(double, double, double, double) _edges(ui.ViewPadding padding) =>
    (padding.left, padding.top, padding.right, padding.bottom);

/// Every metric [DebugViewMetricsOverride] supports as reported by
/// [DebugViewMetricsOverride.fromJson] when it rejects an unknown metric.
Set<String> _allOverridableMetricsFromJsonError() {
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

void main() {
  group('DebugViewMetricsOverride', () {
    test('the per-metric table covers every metric', () {
      final enumMetricNames = <String>{
        for (final DebugViewMetric metric in DebugViewMetric.values) metric.name,
      };
      expect(
        _perMetricChange.keys.toSet(),
        enumMetricNames,
        reason: 'this table is the enumeration the guards below run over',
      );
      expect(_allOverridableMetricsFromJsonError(), enumMetricNames);
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
        textScaling: <ui.Offset>[ui.Offset(8, 16), ui.Offset(30, 38), ui.Offset(100, 100)],
        platformBrightness: ui.Brightness.dark,
        padding: FakeViewPadding(left: 1, top: 2, right: 3, bottom: 4),
        viewPadding: FakeViewPadding(left: 5, top: 6, right: 7, bottom: 8),
        viewInsets: FakeViewPadding(left: 9, top: 10, right: 11, bottom: 12),
        systemGestureInsets: FakeViewPadding(left: 13, top: 14, right: 15, bottom: 16),
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

      // Passing invalid geometry, ratios or tables throws an error.
      expect(
        () => original.copyWith(physicalSize: const ui.Size(-10, 10)),
        throwsA(isA<FlutterError>()),
      );
      expect(() => original.copyWith(devicePixelRatio: 0.0), throwsAssertionError);
      expect(
        () => original.copyWith(textScaling: const <ui.Offset>[]),
        throwsA(isA<FlutterError>()),
      );
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

    test('compares paddings and text scaling by value', () {
      // ui.ViewPadding has no == of its own and a List compares by identity, so
      // equality has to look inside both, or reinstalling the override that is
      // already installed would count as a change and post an event.
      const json = <String, Object?>{
        'padding': <String, Object?>{'top': 1},
        'textScaling': <Object?>[
          <Object?>[1, 2],
        ],
      };
      const override = DebugViewMetricsOverride(
        padding: FakeViewPadding(top: 1),
        textScaling: <ui.Offset>[ui.Offset(1, 2)],
      );
      expect(DebugViewMetricsOverride.fromJson(json), override);
      expect(DebugViewMetricsOverride.fromJson(json).hashCode, override.hashCode);
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
      expect(
        DebugViewMetricsOverride.fromJson(const <String, Object?>{
          'devicePixelRatio': 3,
          'textScaling': <Object?>[
            <Object?>[1, 2],
          ],
          'physicalSize': <String, Object?>{'width': 100, 'height': 200},
          'padding': <String, Object?>{'left': 1, 'top': 2, 'right': 3, 'bottom': 4},
        }),
        const DebugViewMetricsOverride(
          devicePixelRatio: 3.0,
          textScaling: <ui.Offset>[ui.Offset(1, 2)],
          physicalSize: ui.Size(100, 200),
          padding: FakeViewPadding(left: 1, top: 2, right: 3, bottom: 4),
        ),
      );
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
      // A bare number is not read as a linear factor, so that linear scaling
      // has one spelling on the wire: a single point, [[1, factor]].
      for (final malformed in <Object>[
        2,
        <Object?>[1, 2],
        <Object?>[
          <Object?>[1],
        ],
        <Object?>[
          <Object?>['1', '2'],
        ],
      ]) {
        expect(
          () => DebugViewMetricsOverride.fromJson(<String, Object?>{'textScaling': malformed}),
          throwsFormatException,
          reason: 'textScaling: $malformed was accepted.',
        );
      }
    });

    test('defaults missing padding edges to zero', () {
      expect(
        DebugViewMetricsOverride.fromJson(const <String, Object?>{
          'padding': <String, Object?>{'left': 1, 'top': 2, 'right': 3},
        }),
        const DebugViewMetricsOverride(padding: FakeViewPadding(left: 1, top: 2, right: 3)),
      );
    });

    test('accepts the brightnessOverride spelling of platformBrightness', () {
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

    test('rejects text scaling that cannot be interpolated', () {
      for (final MapEntry<String, List<ui.Offset>> entry in _invalidTextScaling.entries) {
        expect(
          () => DebugViewMetricsOverride.fromJson(<String, Object?>{
            'textScaling': <Object?>[
              for (final ui.Offset point in entry.value) <Object?>[point.dx, point.dy],
            ],
          }),
          throwsFormatException,
          reason: 'textScaling with ${entry.key} was accepted.',
        );
      }
      // Scaling to zero is legal: it hides text. So is scaling two sizes to the
      // same size; only a decrease is rejected.
      expect(
        DebugViewMetricsOverride.fromJson(const <String, Object?>{
          'textScaling': <Object?>[
            <Object?>[1, 0],
          ],
        }).textScaling,
        const <ui.Offset>[ui.Offset(1, 0)],
      );
      expect(
        DebugViewMetricsOverride.fromJson(const <String, Object?>{
          'textScaling': <Object?>[
            <Object?>[1, 2],
            <Object?>[2, 2],
          ],
        }).textScaling,
        const <ui.Offset>[ui.Offset(1, 2), ui.Offset(2, 2)],
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

    test('rejects values that cannot be applied, built directly', () {
      // physicalSize, the paddings and textScaling cannot assert in a const
      // constructor, and tooling payloads go through fromJson, so
      // debugSetViewMetricsOverride is the only gate a directly built override
      // with an invalid one of them passes through.
      final invalid = <DebugViewMetricsOverride>[
        const DebugViewMetricsOverride(physicalSize: ui.Size(double.nan, 100)),
        const DebugViewMetricsOverride(physicalSize: ui.Size(100, double.infinity)),
        const DebugViewMetricsOverride(physicalSize: ui.Size(-1, 100)),
        const DebugViewMetricsOverride(physicalSize: ui.Size(100, -1)),
        const DebugViewMetricsOverride(padding: FakeViewPadding(left: -1)),
        const DebugViewMetricsOverride(viewPadding: FakeViewPadding(top: double.nan)),
        const DebugViewMetricsOverride(viewInsets: FakeViewPadding(right: double.infinity)),
        const DebugViewMetricsOverride(systemGestureInsets: FakeViewPadding(bottom: -1)),
        for (final List<ui.Offset> points in _invalidTextScaling.values)
          DebugViewMetricsOverride(textScaling: points),
      ];
      for (final override in invalid) {
        expect(
          () => debugSetViewMetricsOverride(1, override),
          throwsFlutterError,
          reason: '$override was stored',
        );
        expect(debugViewMetricsOverrides, isEmpty, reason: '$override left state behind');
      }

      // Zero extents and scaling to zero are legal, and a rejected override
      // does not disturb one that is already installed.
      const valid = DebugViewMetricsOverride(
        physicalSize: ui.Size.zero,
        padding: FakeViewPadding.zero,
        textScaling: <ui.Offset>[ui.Offset(1, 0)],
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

    test('rejects negative viewId', () {
      expect(
        () => debugSetViewMetricsOverride(-1, const DebugViewMetricsOverride(boldText: true)),
        throwsAssertionError,
      );
      expect(debugViewMetricsOverrides, isEmpty);
    });
  });

  group('debugApplyViewMetricsOverrides', () {
    tearDown(debugClearViewMetricsOverrides);

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

    test('returns null for a view that does not exist', () {
      final ui.PlatformDispatcher wrapped = debugApplyViewMetricsOverrides(
        ui.PlatformDispatcher.instance,
      );
      expect(wrapped.view(id: 123456), isNull);
    });
  });

  group('debugViewWithMetricsOverrides', () {
    tearDown(debugClearViewMetricsOverrides);

    test('normalizes a raw engine view to the view the binding vends', () {
      final ui.FlutterView raw = ui.PlatformDispatcher.instance.implicitView!;
      final ui.FlutterView normalized = debugViewWithMetricsOverrides(raw);
      expect(normalized, isNot(same(raw)));
      expect(
        normalized,
        same(debugApplyViewMetricsOverrides(ui.PlatformDispatcher.instance).implicitView),
      );
      // Already normalized, so it is handed back as is.
      expect(debugViewWithMetricsOverrides(normalized), same(normalized));
      // And it applies the override registered for the raw view's id.
      debugSetViewMetricsOverride(
        raw.viewId,
        const DebugViewMetricsOverride(devicePixelRatio: 7.0),
      );
      expect(normalized.devicePixelRatio, 7.0);
      expect(raw.devicePixelRatio, isNot(7.0));
    });

    test('leaves a view of a dispatcher nobody wrapped alone', () {
      final dispatcher = _TwoViewPlatformDispatcher();
      final ui.FlutterView raw = dispatcher.view(id: 1)!;
      expect(debugViewWithMetricsOverrides(raw), same(raw));

      // Once the dispatcher is wrapped, its views normalize to the wrappers it
      // vends.
      final ui.PlatformDispatcher wrapped = debugApplyViewMetricsOverrides(dispatcher);
      expect(debugViewWithMetricsOverrides(raw), same(wrapped.view(id: 1)));
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
      expect(_edges(wrappedView.padding), _edges(realView.padding));
      expect(_edges(wrappedView.viewInsets), _edges(realView.viewInsets));
      expect(_edges(wrappedView.viewPadding), _edges(realView.viewPadding));
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
          textScaling: <ui.Offset>[ui.Offset(1, 3)],
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

    test('resolves no platform metrics when there is no implicit view', () {
      final dispatcher = _NoImplicitViewPlatformDispatcher();
      final ui.PlatformDispatcher wrapped = debugApplyViewMetricsOverrides(dispatcher);

      expect(wrapped.implicitView, isNull);

      debugSetViewMetricsOverride(
        2,
        const DebugViewMetricsOverride(
          textScaling: <ui.Offset>[ui.Offset(1, 3)],
          platformBrightness: ui.Brightness.dark,
        ),
      );

      // Nothing says which view a platform-wide read off the root wrapper meant,
      // so no entry is resolved. Taking the only entry there happens to be would
      // apply view 2's override to a dispatcher that has nothing to do with it,
      // and would silently start reporting something else as soon as a second
      // entry was registered.
      expect(wrapped.textScaleFactor, dispatcher.textScaleFactor);
      expect(wrapped.platformBrightness, dispatcher.platformBrightness);

      debugSetViewMetricsOverride(
        1,
        const DebugViewMetricsOverride(
          textScaling: <ui.Offset>[ui.Offset(1, 2)],
          platformBrightness: ui.Brightness.light,
        ),
      );

      expect(wrapped.textScaleFactor, dispatcher.textScaleFactor);
      expect(wrapped.platformBrightness, dispatcher.platformBrightness);

      // The views themselves still resolve their own entries: it is only the
      // view-less read that has nothing to resolve against.
      expect(wrapped.view(id: 2)!.platformDispatcher.textScaleFactor, 3.0);
      expect(wrapped.view(id: 1)!.platformDispatcher.textScaleFactor, 2.0);
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
        const DebugViewMetricsOverride(
          devicePixelRatio: 7.0,
          textScaling: <ui.Offset>[ui.Offset(1, 3)],
        ),
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
          padding: FakeViewPadding(top: 141),
          viewPadding: FakeViewPadding(top: 141, bottom: 34),
          viewInsets: FakeViewPadding(bottom: 700),
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

      debugSetViewMetricsOverride(
        viewId,
        const DebugViewMetricsOverride(systemGestureInsets: FakeViewPadding(left: 50, right: 60)),
      );
      expect(wrappedView.systemGestureInsets.left, 50);
      expect(wrappedView.systemGestureInsets.right, 60);
    });

    test('to the platform metrics', () {
      debugSetViewMetricsOverride(
        viewId,
        const DebugViewMetricsOverride(
          textScaling: <ui.Offset>[ui.Offset(2, 5)],
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

    test('to font sizes, linearly from a single point', () {
      debugSetViewMetricsOverride(
        viewId,
        const DebugViewMetricsOverride(textScaling: <ui.Offset>[ui.Offset(2, 5)]),
      );
      // An overridden table has to reach scaleFontSize too: SystemTextScaler
      // scales through it, so overriding only textScaleFactor would change what
      // MediaQuery reports without changing any text.
      expect(wrapped.scaleFontSize(14.0), 35.0);
      expect(wrapped.scaleFontSize(14.5), 36.25);
      expect(wrappedView.platformDispatcher.scaleFontSize(10.0), 25.0);
    });

    test('to font sizes, by interpolating a table', () {
      debugSetViewMetricsOverride(
        viewId,
        const DebugViewMetricsOverride(
          textScaling: <ui.Offset>[ui.Offset(8, 16), ui.Offset(30, 38), ui.Offset(100, 100)],
        ),
      );
      // The factor is the ratio of the first point.
      expect(wrapped.textScaleFactor, 2.0);
      // Points map to their scaled size.
      expect(wrapped.scaleFontSize(8), 16);
      expect(wrapped.scaleFontSize(30), 38);
      expect(wrapped.scaleFontSize(100), 100);
      // Between two points the size is interpolated linearly.
      expect(wrapped.scaleFontSize(19), 27);
      expect(wrapped.scaleFontSize(65), 69);
      // Outside the points it is scaled by the ratio of the nearest point.
      expect(wrapped.scaleFontSize(4), 8);
      expect(wrapped.scaleFontSize(0), 0);
      expect(wrapped.scaleFontSize(200), 200);
      // Sizes the platform tolerates are not rejected.
      expect(wrapped.scaleFontSize(-4), -8);
      expect(wrapped.scaleFontSize(double.nan), isNaN);
      expect(wrapped.scaleFontSize(double.infinity), double.infinity);
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

      // An override that touches no flag leaves the platform's own object, and
      // its equality, alone.
      debugSetViewMetricsOverride(viewId, const DebugViewMetricsOverride(devicePixelRatio: 2.0));
      expect(wrapped.accessibilityFeatures, same(platformFeatures));
    });

    test('only to the view they name', () {
      // An id the platform reports no view for, so the implicit view must be
      // unaffected by an override registered for it.
      final double realRatio = real.implicitView!.devicePixelRatio;
      debugSetViewMetricsOverride(
        viewId + 1000,
        const DebugViewMetricsOverride(devicePixelRatio: 7.0),
      );
      expect(wrappedView.devicePixelRatio, realRatio);
    });

    test('withholding an overridden size from render', () {
      // The engine discards a frame whose size does not satisfy the view's real
      // constraints, so a scene laid out for an overridden size is rendered at
      // the real size: neither the override's size nor a size the caller
      // computed from it is passed on.
      final fake = _TwoViewPlatformDispatcher();
      final ui.FlutterView wrappedView = debugApplyViewMetricsOverrides(fake).view(id: 1)!;
      final ui.Scene scene = ui.SceneBuilder().build();
      addTearDown(scene.dispose);
      debugSetViewMetricsOverride(
        1,
        const DebugViewMetricsOverride(physicalSize: ui.Size(400, 800)),
      );

      wrappedView.render(scene, size: const ui.Size(400, 800));
      expect(fake.viewFor(1).renders, 1, reason: 'the scene still has to reach the view');
      expect(fake.viewFor(1).renderedSize, isNull);

      wrappedView.render(scene);
      expect(fake.viewFor(1).renders, 2);
      expect(fake.viewFor(1).renderedSize, isNull);
    });

    test('and passes the size, or its absence, through to a view with no size override', () {
      // An omitted size is forwarded as omitted rather than resolved against
      // the size the platform reports: the web engine takes a size it is given
      // as a resize and writes it to the DOM, so a wrapper that is supposed to
      // cost nothing while nothing is overridden would cost a reflow per frame.
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
      wrappedView.render(scene, size: const ui.Size(10, 20));
      expect(fake.viewFor(1).renderedSize, const ui.Size(10, 20));
      debugApplyViewMetricsOverrides(fake)
          .view(id: 2)!
          .render(scene, size: const ui.Size(400, 800));
      expect(fake.viewFor(2).renders, 1);
      expect(fake.viewFor(2).renderedSize, isNull);
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

      // The ratio goes away as the table arrives, so both groups changed.
      debugSetViewMetricsOverride(
        1,
        const DebugViewMetricsOverride(textScaling: <ui.Offset>[ui.Offset(1, 2)]),
      );
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
          textScaling: <ui.Offset>[ui.Offset(1, 2)],
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
          textScaling: <ui.Offset>[ui.Offset(1, 2)],
          platformBrightness: ui.Brightness.dark,
          boldText: true,
          alwaysUse24HourFormat: true,
        ),
      );
      expect(notifications, <String>['configuration', 'metrics']);

      // A table that scales differently but reports the same factor is still a
      // change of text scaling.
      notifications.clear();
      debugSetViewMetricsOverride(
        1,
        const DebugViewMetricsOverride(
          devicePixelRatio: 3.0,
          textScaling: <ui.Offset>[ui.Offset(1, 2), ui.Offset(10, 15)],
          platformBrightness: ui.Brightness.dark,
          boldText: true,
          alwaysUse24HourFormat: true,
        ),
      );
      expect(notifications, <String>['configuration', 'textScaleFactor']);
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
        'systemGestureInsets',
      };
      expect(
        _perMetricChange.keys.toSet(),
        _allOverridableMetricsFromJsonError(),
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
          'textScaling' => <String>{'configuration', 'textScaleFactor'},
          'platformBrightness' => <String>{'configuration', 'platformBrightness'},
          final String metric when viewMetrics.contains(metric) => <String>{'metrics'},
          _ => <String>{'configuration', 'accessibilityFeatures'},
        }, reason: 'changing ${entry.key} announced $notifications');
      }
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
        const DebugViewMetricsOverride(
          devicePixelRatio: 3.0,
          textScaling: <ui.Offset>[ui.Offset(1, 2)],
        ),
      );

      expect(errors.single, isUnimplementedError);
      expect(textScaleFactorChanged, 1);
    });

    test('through every callback and to every dispatcher, even when one fails', () {
      // A metric that changed and was not reported leaves the framework reading
      // a value nothing told it to re-read. Neither the notifications after a
      // failing one, nor the dispatchers after it — the framework's own is one
      // of them — may be skipped because of it.
      final failing = _TwoViewPlatformDispatcher();
      final reached = _TwoViewPlatformDispatcher();
      final ui.PlatformDispatcher wrapped = debugApplyViewMetricsOverrides(failing);
      failing.onPlatformConfigurationChanged = () =>
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
        const DebugViewMetricsOverride(
          devicePixelRatio: 3.0,
          textScaling: <ui.Offset>[ui.Offset(1, 2)],
        ),
      );

      // Reported rather than thrown, so that a caller is not left with an
      // override installed and half the application told about it.
      expect(errors, hasLength(1));
      expect(errors.single, isStateError);
      // The failing dispatcher still heard about the table and the metrics.
      expect(stillTold, 2);
      expect(notified, 1);
    });
  });

  group('engine roll tolerance', () {
    test('wrappers declare no noSuchMethod', () {
      final fake = _TwoViewPlatformDispatcher();
      final ui.PlatformDispatcher dispatcher = debugApplyViewMetricsOverrides(fake);
      final ui.FlutterView view = dispatcher.implicitView!;

      debugSetViewMetricsOverride(view.viewId, const DebugViewMetricsOverride(boldText: true));
      addTearDown(debugClearViewMetricsOverrides);

      final ui.AccessibilityFeatures features = dispatcher.accessibilityFeatures;

      // A `noSuchMethod` returning null would absorb a member added on the
      // engine side, and would then put a dispatcher that answers null for it
      // in front of the whole framework in every debug build. Every member is
      // spelled out instead, so an engine roll that adds one is a compile
      // error in this library rather than a null at some unrelated call site.
      expect(() => (dispatcher as dynamic).unimplementedMember, throwsNoSuchMethodError);
      expect(() => (view as dynamic).unimplementedMember, throwsNoSuchMethodError);
      expect(() => (features as dynamic).unimplementedMember, throwsNoSuchMethodError);
    });
  });
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

class _NoImplicitViewPlatformDispatcher extends _TwoViewPlatformDispatcher {
  @override
  ui.FlutterView? get implicitView => null;
}

class _NoAccessibilityFeatures implements ui.AccessibilityFeatures {
  const _NoAccessibilityFeatures();

  @override
  bool get boldText => false;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not needed by these tests.');
}
