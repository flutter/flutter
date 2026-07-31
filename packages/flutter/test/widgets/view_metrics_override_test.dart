// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show json;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

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
}

void main() {
  final ViewMetricsOverrideTestBinding binding =
      ViewMetricsOverrideTestBinding.ensureInitialized();

  tearDown(() {
    debugClearViewMetricsOverrides();
  });

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

  group('ViewMetricsOverride', () {
    test('isEmpty is true only when nothing is overridden', () {
      expect(const ViewMetricsOverride().isEmpty, isTrue);
      expect(const ViewMetricsOverride(boldText: false).isEmpty, isFalse);
      expect(const ViewMetricsOverride(devicePixelRatio: 1.0).isEmpty, isFalse);
    });

    test('affectsViewConfiguration is true only for layout metrics', () {
      expect(const ViewMetricsOverride(boldText: true).affectsViewConfiguration, isFalse);
      expect(const ViewMetricsOverride(devicePixelRatio: 2.0).affectsViewConfiguration, isTrue);
      expect(
        const ViewMetricsOverride(physicalSize: ui.Size(1, 1)).affectsViewConfiguration,
        isTrue,
      );
    });

    test('== and hashCode compare every field', () {
      const a = ViewMetricsOverride(boldText: true, highContrast: false);
      const b = ViewMetricsOverride(boldText: true, highContrast: false);
      const c = ViewMetricsOverride(boldText: true);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('copyWith replaces provided fields and keeps the rest', () {
      const original = ViewMetricsOverride(boldText: true);
      final ViewMetricsOverride updated = original.copyWith(highContrast: true);
      expect(updated.boldText, isTrue);
      expect(updated.highContrast, isTrue);
      // A null argument keeps the existing override rather than clearing it.
      expect(original.copyWith().boldText, isTrue);
    });

    test('round trips through JSON', () {
      const original = ViewMetricsOverride(
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
        highContrast: false,
        onOffSwitchLabels: true,
      );
      expect(ViewMetricsOverride.fromJson(original.toJson()), equals(original));
    });

    test('toJson omits metrics that are not overridden', () {
      expect(const ViewMetricsOverride().toJson(), isEmpty);
      expect(const ViewMetricsOverride(boldText: true).toJson(), <String, Object?>{
        'boldText': true,
      });
    });

    test('fromJson treats absent keys as not overridden', () {
      final override = ViewMetricsOverride.fromJson(const <String, Object?>{
        'boldText': true,
      });
      expect(override.boldText, isTrue);
      expect(override.textScaler, isNull);
      expect(override.physicalSize, isNull);
    });

    test('fromJson rejects malformed values', () {
      expect(
        () => ViewMetricsOverride.fromJson(const <String, Object?>{'boldText': 'yes'}),
        throwsFormatException,
      );
      expect(
        () => ViewMetricsOverride.fromJson(const <String, Object?>{'devicePixelRatio': 'big'}),
        throwsFormatException,
      );
      expect(
        () => ViewMetricsOverride.fromJson(const <String, Object?>{'platformBrightness': 'purple'}),
        throwsFormatException,
      );
      expect(
        () => ViewMetricsOverride.fromJson(const <String, Object?>{
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
          () => ViewMetricsOverride.fromJson(<String, Object?>{'devicePixelRatio': ratio}),
          throwsFormatException,
          reason: 'devicePixelRatio $ratio should be rejected',
        );
      }
      expect(
        () => ViewMetricsOverride.fromJson(const <String, Object?>{
          'physicalSize': <String, Object?>{'width': -1, 'height': 10},
        }),
        throwsFormatException,
      );
      expect(
        () => ViewMetricsOverride.fromJson(const <String, Object?>{
          'physicalSize': <String, Object?>{'width': double.infinity, 'height': 10},
        }),
        throwsFormatException,
      );
      expect(
        () => ViewMetricsOverride.fromJson(const <String, Object?>{'textScaleFactor': -1}),
        throwsFormatException,
      );
    });

    test('asserts on an invalid devicePixelRatio passed directly', () {
      expect(() => ViewMetricsOverride(devicePixelRatio: 0), throwsAssertionError);
      expect(() => ViewMetricsOverride(devicePixelRatio: -1), throwsAssertionError);
      expect(() => ViewMetricsOverride(devicePixelRatio: double.infinity), throwsAssertionError);
    });

    test('stays usable in a const expression', () {
      // The devicePixelRatio assert must remain const-evaluable, otherwise
      // every const ViewMetricsOverride at a call site fails to compile.
      const override = ViewMetricsOverride(
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

      expect(debugSetViewMetricsOverride(7, const ViewMetricsOverride(boldText: true)), isTrue);
      expect(debugViewMetricsOverrides[7], const ViewMetricsOverride(boldText: true));

      // Setting the same value again is a no-op.
      expect(debugSetViewMetricsOverride(7, const ViewMetricsOverride(boldText: true)), isFalse);

      expect(debugSetViewMetricsOverride(7, const ViewMetricsOverride(boldText: false)), isTrue);
      expect(debugViewMetricsOverrides[7], const ViewMetricsOverride(boldText: false));

      expect(debugSetViewMetricsOverride(7, null), isTrue);
      expect(debugViewMetricsOverrides, isEmpty);
      expect(debugSetViewMetricsOverride(7, null), isFalse);
    });

    test('an empty override removes the entry', () {
      debugSetViewMetricsOverride(7, const ViewMetricsOverride(boldText: true));
      expect(debugSetViewMetricsOverride(7, const ViewMetricsOverride()), isTrue);
      expect(debugViewMetricsOverrides, isEmpty);
    });

    test('notifies listeners only when something changed', () {
      var notifications = 0;
      void listener() => notifications += 1;
      debugViewMetricsOverridesNotifier.addListener(listener);
      addTearDown(() => debugViewMetricsOverridesNotifier.removeListener(listener));

      debugSetViewMetricsOverride(7, const ViewMetricsOverride(boldText: true));
      expect(notifications, 1);
      debugSetViewMetricsOverride(7, const ViewMetricsOverride(boldText: true));
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

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const ViewMetricsOverride(
          boldText: true,
          highContrast: true,
          textScaler: TextScaler.linear(2.0),
        ),
      );
      await tester.pump();

      expect(data.boldText, isTrue);
      expect(data.highContrast, isTrue);
      expect(data.textScaler, const TextScaler.linear(2.0));

      debugSetViewMetricsOverride(tester.view.viewId, null);
      await tester.pump();

      expect(data.boldText, isFalse);
      expect(data.highContrast, isFalse);
      expect(data.textScaler.scale(10), 10.0);
    });

    testWidgets('overrides padding, insets and brightness', (WidgetTester tester) async {
      late MediaQueryData data;
      await pumpProbe(tester, (MediaQueryData value) => data = value);

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const ViewMetricsOverride(
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
        const ViewMetricsOverride(boldText: true),
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
        const ViewMetricsOverride(physicalSize: ui.Size(1000, 500), devicePixelRatio: 2.0),
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
        ViewMetricsOverride(devicePixelRatio: originalRatio * 2),
      );
      await tester.pumpAndSettle();

      expect(data.devicePixelRatio, originalRatio * 2);
      expect(data.size, originalSize / 2);
      expect(tester.getSize(find.byType(SizedBox)), originalSize / 2);

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
