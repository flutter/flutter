// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/commands/config.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/context.dart';

void main() {
  MockAndroidStudio mockAndroidStudio;
  MockAndroidSdk mockAndroidSdk;

  setUp(() {
    mockAndroidStudio = new MockAndroidStudio();
    mockAndroidSdk = new MockAndroidSdk();
  });

  group('config', () {
    testUsingContext('machine flag', () async {
      final BufferLogger logger = context[Logger];
      final ConfigCommand command = new ConfigCommand();
      await command.handleMachine();

      expect(logger.statusText, isNotEmpty);
      final dynamic jsonObject = json.decode(logger.statusText);
      expect(jsonObject, isMap);

      expect(jsonObject.containsKey('android-studio-dir'), true);
      expect(jsonObject['android-studio-dir'], isNotNull);

      expect(jsonObject.containsKey('android-sdk'), true);
      expect(jsonObject['android-sdk'], isNotNull);
    }, overrides: <Type, Generator>{
      AndroidStudio: () => mockAndroidStudio,
      AndroidSdk: () => mockAndroidSdk,
    });
  });
}

class MockAndroidStudio extends Mock implements AndroidStudio, Comparable<AndroidStudio> {
  @override
  String get directory => 'path/to/android/stdio';
}

class MockAndroidSdk extends Mock implements AndroidSdk {
  @override
  String get directory => 'path/to/android/sdk';
}
