// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

final RegExp _calibrationRegExp = RegExp('Flutter frame rate is (.*)fps');
final RegExp _statsRegExp = RegExp('Produced: (.*)fps\nConsumed: (.*)fps\nWidget builds: (.*)');
const Duration _samplingTime = Duration(seconds: 8);

Future<void> main() async {
  late final FlutterDriver driver;

  setUpAll(() async {
    driver = await FlutterDriver.connect();
  });

  tearDownAll(() async {
    await driver.close();
  });

  // Verifies we consume texture frames at a rate close to the minimum of the
  // rate at which they are produced and Flutter's frame rate. In addition,
  // it verifies that widget builds are not triggered by external texture
  // frames.
  test('renders frames from the device at a rate similar to the frames produced', () async {
    final SerializableFinder fab = find.byValueKey('fab');
    final SerializableFinder summary = find.byValueKey('summary');

    // Wait for calibration to complete and fab to appear.
    await driver.waitFor(fab);

    final String calibrationResult = await driver.getText(summary);
    final Match? matchCalibration = _calibrationRegExp.matchAsPrefix(calibrationResult);
    expect(matchCalibration, isNotNull);
    final double flutterFrameRate = double.parse(matchCalibration?.group(1) ?? '0');

    // Texture frame stats at 0.5x Flutter frame rate
    await driver.tap(fab);
    await Future<void>.delayed(_samplingTime);
    await driver.tap(fab);

    final String statsSlow = await driver.getText(summary);
    final Match matchSlow = _statsRegExp.matchAsPrefix(statsSlow)!;
    expect(matchSlow, isNotNull);

    double framesProduced = double.parse(matchSlow.group(1)!);
    expect(framesProduced, closeTo(flutterFrameRate / 2.0, 5.0));
    double framesConsumed = double.parse(matchSlow.group(2)!);
    expect(framesConsumed, closeTo(flutterFrameRate / 2.0, 5.0));
    int widgetBuilds = int.parse(matchSlow.group(3)!);
    expect(widgetBuilds, 1);

    // Texture frame stats at 2.0x Flutter frame rate
    await driver.tap(fab);
    await Future<void>.delayed(_samplingTime);
    await driver.tap(fab);

    final String statsFast = await driver.getText(summary);
    final Match matchFast = _statsRegExp.matchAsPrefix(statsFast)!;
    expect(matchFast, isNotNull);

    framesProduced = double.parse(matchFast.group(1)!);
    expect(framesProduced, closeTo(flutterFrameRate * 2.0, 5.0));
    framesConsumed = double.parse(matchFast.group(2)!);
    expect(framesConsumed, closeTo(flutterFrameRate, 10.0));
    widgetBuilds = int.parse(matchSlow.group(3)!);
    expect(widgetBuilds, 1);
  }, timeout: Timeout.none);
}
