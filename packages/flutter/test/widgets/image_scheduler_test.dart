// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late int originalCacheSize;

  setUp(() async {
    originalCacheSize = imageCache.maximumSize;
    imageCache.clear();
    imageCache.clearLiveImages();
  });

  tearDown(() {
    imageCache.maximumSize = originalCacheSize;
  });

  testWidgets('asset image is loaded through scheduler task', (WidgetTester tester) async {
    final Key key = UniqueKey();
    await tester.pumpWidget(Center(
      child: RepaintBoundary(
        key: key,
        child: Container(
          width: 150.0,
          height: 50.0,
          decoration: BoxDecoration(
            border: Border.all(
              width: 2.0,
              color: const Color(0xFF00FF99),
            ),
          ),
          child: Image.asset('missing-asset-x'),
        ),
      ),
    ));

    // Ensure AssetManifest is loaded before attempting to test
    // individual asset load.
    expect(tester.takeException(), isNotNull);
    tester.binding.immediatelyScheduleTasks = false;

    await tester.pumpWidget(Center(
      child: RepaintBoundary(
        key: key,
        child: Container(
          width: 150.0,
          height: 50.0,
          decoration: BoxDecoration(
            border: Border.all(
              width: 2.0,
              color: const Color(0xFF00FF99),
            ),
          ),
          child: Image.asset('missing-asset-y'),
        ),
      ),
    ));

    await tester.pump();
    await SchedulerBinding.instance.handleEventLoopCallback();
    await tester.pump();

    expect(tester.takeException(), isNotNull);
  }, skip: kIsWeb); // https://github.com/flutter/flutter/issues/74935 (broken assets not being reported on web)
}
