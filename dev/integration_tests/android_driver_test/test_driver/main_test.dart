// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

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

final bool _isLuciCi = io.Platform.environment['LUCI_CI'] == 'True';

Future<void> _main() async {
  // To generate golden files locally, uncomment the following line.
  // autoUpdateGoldenFiles = true;

  late FlutterDriver flutterDriver;
  late NativeDriver nativeDriver;

  setUpAll(() async {
    flutterDriver = await FlutterDriver.connect(
      // TODO(matanlurey): Workaround log uploading in LUCI not being enabled.
      // Default to true on CI because log uploading doesn't work.
      // See <https://github.com/flutter/flutter/issues/152775>.
      printCommunication: _isLuciCi,
    );
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
