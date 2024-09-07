// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:native_driver/native_driver.dart';
import 'package:test/test.dart';

void main() async {
  // To test the golden file generation locally, comment out the following line.
  autoUpdateGoldenFiles = true;

  const String appName = 'com.example.native_driver_test';
  late final FlutterDriver flutterDriver;
  late final NativeDriver nativeDriver;

  setUpAll(() async {
    flutterDriver = await FlutterDriver.connect();
    nativeDriver = await AndroidNativeDriver.connect();
  });

  tearDownAll(() async {
    await nativeDriver.close();
    await flutterDriver.close();
  });

  test('should screenshot and match an external smiley face texture', () async {
    await flutterDriver.waitFor(find.byType('Texture'));

    // On Android: Background the app, trim memory, and restore the app.
    if (nativeDriver case final AndroidNativeDriver nativeDriver) {
      print('Backgrounding the app, trimming memory, and resuming the app.');
      await nativeDriver.backgroundApp();

      print('Trimming memory.');
      await nativeDriver.simulateLowMemory(appName: appName);

      print('Resuming the app.');
      await nativeDriver.resumeApp(appName: appName);
    }

    await expectLater(
      nativeDriver.screenshot(),
      matchesGoldenFile('external_texture_smiley_face.android.png'),
    );
  }, timeout: Timeout.none);
}
