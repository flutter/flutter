// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/commands/list.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:test/test.dart';

import 'src/common.dart';
import 'src/context.dart';

main() => defineTests();

defineTests() {
  group('list', () {
    testUsingContext('returns 0 when called', () {
      ListCommand command = new ListCommand();
      return createTestCommandRunner(command).run(['list']).then((int code) {
        expect(code, equals(0));
      });
    });

    testUsingContext('no error when no connected devices', () {
      ListCommand command = new ListCommand();
      return createTestCommandRunner(command).run(['list']).then((int code) {
        expect(code, equals(0));
        expect(testLogger.statusText, contains('No connected devices'));
      });
    }, overrides: <Type, dynamic>{
      AndroidSdk: null,
      DeviceManager: new DeviceManager()
    });
  });
}
