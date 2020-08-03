// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  testWithoutContext('AndroidDevice.stopApp handles a null ApplicationPackage', () async {
    final AndroidDevice androidDevice = AndroidDevice('1234',
      androidSdk: MockAndroidSdk(),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      platform: FakePlatform(operatingSystem: 'linux'),
      processManager: FakeProcessManager.any(),
    );

    expect(await androidDevice.stopApp(null), false);
  });
}

class MockAndroidSdk extends Mock implements AndroidSdk {}
