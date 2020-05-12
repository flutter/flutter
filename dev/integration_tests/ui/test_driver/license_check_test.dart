// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;
import 'package:vm_service_client/vm_service_client.dart';

// Connect and disconnect from the empty app.
void main() {
  // Load the license file from disk to compare it with the one in the app.
  final File licenseFile = File(path.join('..', '..', '..', 'packages', 'flutter', 'LICENSE'));
  if (!licenseFile.existsSync()) {
    print('Test failed. Unable to find LICENSE file at ${licenseFile.path}');
    exit(-1);
  }
  final RegExp newlineSplit = RegExp(r'\s+');
  final String license = licenseFile.readAsStringSync().split(newlineSplit).join(' ').trim();

  group('License file check', () {
    FlutterDriver driver;
    IsolatesWorkaround workaround;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
      workaround = IsolatesWorkaround(driver);
      await workaround.resumeIsolates();
      await driver.waitUntilFirstFrameRasterized();
    });

    tearDownAll(() async {
      if (driver != null) {
        await driver.close();
        await workaround.tearDown();
      }
    });

    test('flutter license', () async {
      await driver.waitFor(find.byValueKey('Header'));
      final String foundPackage = await driver.getText(find.byValueKey('FlutterPackage'));
      final String foundLicense = await driver.getText(find.byValueKey('FlutterLicense'));
      expect(foundPackage, equals('flutter'));
      expect(foundLicense, equals(license));
    });

    test('engine license', () async {
      await driver.waitFor(find.byValueKey('Header'));
      final String foundPackage = await driver.getText(find.byValueKey('EnginePackage'));
      final String foundLicense = await driver.getText(find.byValueKey('EngineLicense'));
      expect(foundPackage, equals('engine'));
      // The engine has the same license, but with a different Copyright date.
      expect(foundLicense, contains(license.replaceFirst('2014', '2013')));
    });
  });
}

/// Workaround for isolates being paused by driver tests.
/// https://github.com/flutter/flutter/issues/24703
class IsolatesWorkaround {
  IsolatesWorkaround(this._driver);

  final FlutterDriver _driver;
  StreamSubscription<VMIsolateRef> _streamSubscription;

  Future<void> resumeIsolates() async {
    final VM vm = await _driver.serviceClient.getVM();
    // Resume any paused isolate
    for (final VMIsolateRef isolateRef in vm.isolates) {
      final VMIsolate isolate = await isolateRef.load();
      if (isolate.isPaused) {
        isolate.resume();
      }
    }
    if (_streamSubscription != null) {
      return;
    }
    _streamSubscription = _driver.serviceClient.onIsolateRunnable
        .asBroadcastStream()
        .listen((VMIsolateRef isolateRef) async {
      final VMIsolate isolate = await isolateRef.load();
      if (isolate.isPaused) {
        isolate.resume();
      }
    });
  }

  Future<void> tearDown() async {
    if (_streamSubscription != null) {
      await _streamSubscription.cancel();
    }
  }
}
