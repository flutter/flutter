// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:test/fake.dart';

import '../src/common.dart';

void main() {
  test('defaultReloadSourcesHelper() handles empty DeviceReloadReports)', () {
    defaultReloadSourcesHelper(
      _FakeHotRunner(),
      <FlutterDevice?>[_FakeFlutterDevice()],
      false,
      const <String, dynamic>{},
      null,
      null,
      null,
      null,
    );
  });
}

class _FakeHotRunner extends Fake implements HotRunner {
}

class _FakeDevFS extends Fake implements DevFS {
  @override
  final Uri? baseUri 
}

class _FakeFlutterDevice extends Fake implements FlutterDevice {
  @override
  final DevFS? devFS = _FakeDevFS();
}
