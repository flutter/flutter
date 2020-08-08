// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:test/test.dart';

void main() {
  test('window.sendPlatformMessage preserves callback zone', () {
    runZoned(() {
      final Zone innerZone = Zone.current;
      window.sendPlatformMessage('test', ByteData.view(Uint8List(0).buffer), expectAsync1((ByteData data) {
        final Zone runZone = Zone.current;
        expect(runZone, isNotNull);
        expect(runZone, same(innerZone));
      }));
    });
  });

  test('FrameTiming.toString has the correct format', () {
    final FrameTiming timing = FrameTiming(
      vsyncStart: 500,
      buildStart: 1000,
      buildFinish: 8000,
      rasterStart: 9000,
      rasterFinish: 19500
    );
    expect(timing.toString(), 'FrameTiming(buildDuration: 7.0ms, rasterDuration: 10.5ms, vsyncOverhead: 0.5ms, totalSpan: 19.0ms)');
  });

  test('computePlatformResolvedLocale basic', () {
    final List<Locale> supportedLocales = <Locale>[
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans', countryCode: 'CN'),
      const Locale.fromSubtags(languageCode: 'fr', countryCode: 'FR'),
      const Locale.fromSubtags(languageCode: 'en', countryCode: 'US'),
      const Locale.fromSubtags(languageCode: 'en'),
    ];
    // The default implementation returns null due to lack of a real platform.
    final Locale result = window.computePlatformResolvedLocale(supportedLocales);
    expect(result, null);
  });
}
