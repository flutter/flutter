// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:flutter_driver/src/native_driver.dart';
import 'package:test/test.dart';

import '_flutter_goldens_fork.dart';

// TODO(matanlurey): This is done automatically by 'flutter test' but not by
// 'flutter drive'. If we get closer to shipping the native 'flutter drive'
// command, we should look into if 'flutter_test_config.dart', or a similar
// mechanism, can be used to configure this automatically.
void main() async {
  await testExecutable(_main);
}

Future<void> _main() async {
  // To generate golden files locally, uncomment the following line.
  // autoUpdateGoldenFiles = true;

  late FlutterDriver flutterDriver;
  late NativeDriver nativeDriver;

  setUpAll(() async {
    flutterDriver = await FlutterDriver.connect();
    nativeDriver = await AndroidNativeDriver.connect();
  });

  tearDownAll(() async {
    await nativeDriver.close();
    await flutterDriver.close();
  });

  test('should screenshot and match a full-screen blue rectangle', () async {
    await flutterDriver.waitFor(find.byType('DecoratedBox'));
    await expectLater(
      nativeDriver.screenshot(),
      matchesGoldenFile('android_driver_test.BlueRectangle.png'),
    );
  }, timeout: Timeout.none);
}
