// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

// Connect and disconnect from the empty app.
void main() {
  // Load the license file from disk to compare it with the one in the app.
  final licenseFile = File(path.join('..', '..', '..', 'packages', 'flutter', 'LICENSE'));
  if (!licenseFile.existsSync()) {
    print('Test failed. Unable to find LICENSE file at ${licenseFile.path}');
    exit(-1);
  }
  final newlineSplit = RegExp(r'\s+');
  final String license = licenseFile.readAsStringSync().split(newlineSplit).join(' ').trim();

  group('License file check', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
      await driver.waitUntilFirstFrameRasterized();
    });

    tearDownAll(() async {
      await driver.close();
    });

    test('flutter license', () async {
      await driver.waitFor(find.byValueKey('Header'));
      final String foundPackage = await driver.getText(find.byValueKey('FlutterPackage'));
      final String foundLicense = await driver.getText(find.byValueKey('FlutterLicense'));
      expect(foundPackage, equals('flutter'));
      expect(foundLicense, equals(license));
    }, timeout: Timeout.none);

    test('engine license', () async {
      await driver.waitFor(find.byValueKey('Header'));
      final String foundPackage = await driver.getText(find.byValueKey('EnginePackage'));
      final String foundLicense = await driver.getText(find.byValueKey('EngineLicense'));
      expect(foundPackage, equals('engine'));
      // The engine has the same license, but with a different Copyright date.
      expect(foundLicense, contains(license.replaceFirst('2014', '2013')));
    }, timeout: Timeout.none);
  });
}
