// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_workflow.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart' show MockAndroidSdk, MockProcessManager, MockStdio;

void main() {
  AndroidSdk sdk;
  MemoryFileSystem fs;
  MockProcessManager processManager;
  MockStdio stdio;

  setUp(() {
    sdk = new MockAndroidSdk();
    fs = new MemoryFileSystem();
    processManager = new MockProcessManager();
    stdio = new MockStdio();
  });

  testUsingContext('runLicenseManager succeeds for version >= 26', () async {
    fs.directory('/home/me').createSync(recursive: true);
    MockAndroidSdk.createSdkDirectory();
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    when(sdk.sdkManagerVersion).thenReturn('26.0.0');

    expect(await AndroidWorkflow.runLicenseManager(), isTrue);
  }, overrides: <Type, Generator>{
    AndroidSdk: () => sdk,
    FileSystem: () => fs,
    Platform: () => new FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
    ProcessManager: () => processManager,
    Stdio: () => stdio,
  });

  testUsingContext('runLicenseManager errors for version < 26', () async {
    fs.directory('/home/me').createSync(recursive: true);
    MockAndroidSdk.createSdkDirectory();
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    when(sdk.sdkManagerVersion).thenReturn('25.0.0');

    expect(AndroidWorkflow.runLicenseManager(), throwsToolExit());
  }, overrides: <Type, Generator>{
    AndroidSdk: () => sdk,
    FileSystem: () => fs,
    Platform: () => new FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
    ProcessManager: () => processManager,
    Stdio: () => stdio,
  });

  testUsingContext('runLicenseManager errors when sdkmanager is not found', () async {
    fs.directory('/home/me').createSync(recursive: true);
    MockAndroidSdk.createSdkDirectory();
    when(sdk.sdkManagerPath).thenReturn('/foo/bar/sdkmanager');
    processManager.succeed = false;

    expect(AndroidWorkflow.runLicenseManager(), throwsToolExit());
  }, overrides: <Type, Generator>{
    AndroidSdk: () => sdk,
    FileSystem: () => fs,
    Platform: () => new FakePlatform()..environment = <String, String>{'HOME': '/home/me'},
    ProcessManager: () => processManager,
    Stdio: () => stdio,
  });
}
