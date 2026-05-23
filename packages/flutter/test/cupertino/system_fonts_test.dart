// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sends the framework's system-fonts-changed platform message.
Future<void> _sendSystemFontsChange(WidgetTester tester) {
  const data = <String, dynamic>{'type': 'fontsChange'};
  return tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/system',
    SystemChannels.system.codec.encodeMessage(data),
    (ByteData? response) {},
  );
}

void main() {
  testWidgets(
    'CupertinoDatePicker reset cache upon system fonts change - date time mode',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(home: CupertinoDatePicker(onDateTimeChanged: (DateTime dateTime) {})),
      );
      final dynamic state = tester.state(find.byType(CupertinoDatePicker));
      // ignore: avoid_dynamic_calls
      final cache = state.estimatedColumnWidths as Map<int, double>;
      expect(cache.isNotEmpty, isTrue);
      await _sendSystemFontsChange(tester);
      // Cache should be cleaned.
      expect(cache.isEmpty, isTrue);
      final Element element = tester.element(find.byType(CupertinoDatePicker));
      expect(element.dirty, isTrue);
    },
    // TODO(yjbanov): cupertino does not work on the Web yet: https://github.com/flutter/flutter/issues/41920
    skip: isBrowser,
  );

  testWidgets(
    'CupertinoDatePicker reset cache upon system fonts change - date mode',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            onDateTimeChanged: (DateTime dateTime) {},
          ),
        ),
      );
      final dynamic state = tester.state(find.byType(CupertinoDatePicker));
      // ignore: avoid_dynamic_calls
      final cache = state.estimatedColumnWidths as Map<int, double>;
      // Simulates font missing.
      cache.clear();
      await _sendSystemFontsChange(tester);
      // Cache should be replenished
      expect(cache.isNotEmpty, isTrue);
      final Element element = tester.element(find.byType(CupertinoDatePicker));
      expect(element.dirty, isTrue);
    },
    // TODO(yjbanov): cupertino does not work on the Web yet: https://github.com/flutter/flutter/issues/41920
    skip: isBrowser,
  );

  testWidgets(
    'CupertinoDatePicker reset cache upon system fonts change - time mode',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(home: CupertinoTimerPicker(onTimerDurationChanged: (Duration d) {})),
      );
      final dynamic state = tester.state(find.byType(CupertinoTimerPicker));
      // Simulates wrong metrics due to font missing.
      // ignore: avoid_dynamic_calls
      state.numberLabelWidth = 0.0;
      // ignore: avoid_dynamic_calls
      state.numberLabelHeight = 0.0;
      // ignore: avoid_dynamic_calls
      state.numberLabelBaseline = 0.0;
      await _sendSystemFontsChange(tester);
      // Metrics should be refreshed
      // ignore: avoid_dynamic_calls
      expect(state.numberLabelWidth, lessThan(46.0 + precisionErrorTolerance));
      // ignore: avoid_dynamic_calls
      expect(state.numberLabelHeight, lessThan(23.0 + precisionErrorTolerance));
      // ignore: avoid_dynamic_calls
      expect(state.numberLabelBaseline, lessThan(18.400070190429688 + precisionErrorTolerance));
      final Element element = tester.element(find.byType(CupertinoTimerPicker));
      expect(element.dirty, isTrue);
    },
    // TODO(yjbanov): cupertino does not work on the Web yet: https://github.com/flutter/flutter/issues/41920
    skip: isBrowser,
  );
}
