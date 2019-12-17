// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show File;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_driver/flutter_driver.dart';
import 'package:collection/collection.dart';

const String _kPathParent = 'test_driver/goldens/';

/// The utility class that helps test cases to tests screenshots with a [FlutterDriver].
@immutable
class DriverScreenShotTester {
  /// Constructs a [DriverScreenShotTester].
  ///
  /// All the parameters are required and must not be null.
  const DriverScreenShotTester({
    @required this.testName,
    @required this.driver,
    @required this.deviceModel,
  })  : assert(testName != null),
        assert(driver != null),
        assert(deviceModel != null);

  /// The name of the test.
  ///
  /// It needs to match the folder name which the goldens resides under `test_driver/goldens`.
  final String testName;

  /// The `FlutterDriver` used to take the screenshots.
  final FlutterDriver driver;

  /// The device model of the device that the test is running on.
  final String deviceModel;

  /// Compares `screenshot` to the corresponding golden image. Returns true if they match.
  ///
  /// The golden image should exists at `test_driver/goldens/<testName>/<deviceModel>.png`
  /// prior to this call.
  Future<bool> compareScreenshots(List<int> screenshot) async {
    final File file = File(_getImageFilePath());
    final List<int> matcher = await file.readAsBytes();
    final Function listEquals = const ListEquality<int>().equals;
    return listEquals(screenshot, matcher);
  }

  /// Returns a bytes representation of a screenshot on the current screen.
  Future<List<int>> getScreenshotAsBytes() async {
    return await driver.screenshot();
  }

  /// Save the `screenshot` as a golden image.
  ///
  /// The path of the image is defined as:
  /// `test_driver/goldens/<testName>/<deviceModel>.png`
  ///
  /// Can be used when recording the golden for the first time.
  Future<void> saveScreenshot(List<int> screenshot) async {
    final File file = File(_getImageFilePath());
    if (!file.existsSync()) {
      await file.writeAsBytes(screenshot);
    }
  }

  String _getImageFilePath() {
    return path.joinAll(<String>[_kPathParent, testName, deviceModel + '.png']);
  }
}
