// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' show ProcessException, ProcessResult;
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:platform/platform.dart';

import '../../src/common.dart';
import '../../src/context.dart';

class MockProcessManager extends Mock implements ProcessManager {}
class MockXcodeProjectInterpreter extends Mock implements XcodeProjectInterpreter {}
class MockPlatform extends Mock implements Platform {}

void main() {
  ProcessManager processManager;
  Xcode xcode;
  MockXcodeProjectInterpreter mockXcodeProjectInterpreter;
  MockPlatform platform;
  Logger logger;
  FileSystem fileSystem;

  setUp(() {
    logger = MockLogger();
    fileSystem = MemoryFileSystem();
    processManager = MockProcessManager();
    mockXcodeProjectInterpreter = MockXcodeProjectInterpreter();
    platform = MockPlatform();
    xcode = Xcode(
      logger: logger,
      platform: platform,
      fileSystem: fileSystem,
      processManager: processManager,
      xcodeProjectInterpreter: mockXcodeProjectInterpreter,
    );
  });

  testWithoutContext('xcodeSelectPath returns null when xcode-select is not installed', () {
    when(processManager.runSync(<String>['/usr/bin/xcode-select', '--print-path']))
        .thenThrow(const ProcessException('/usr/bin/xcode-select', <String>['--print-path']));
    expect(xcode.xcodeSelectPath, isNull);
    when(processManager.runSync(<String>['/usr/bin/xcode-select', '--print-path']))
        .thenThrow(ArgumentError('Invalid argument(s): Cannot find executable for /usr/bin/xcode-select'));

    expect(xcode.xcodeSelectPath, isNull);
  });

  testWithoutContext('xcodeSelectPath returns path when xcode-select is installed', () {
    const String xcodePath = '/Applications/Xcode8.0.app/Contents/Developer';
    when(processManager.runSync(<String>['/usr/bin/xcode-select', '--print-path']))
        .thenReturn(ProcessResult(1, 0, xcodePath, ''));

    expect(xcode.xcodeSelectPath, xcodePath);
  });

  testWithoutContext('xcodeVersionSatisfactory is false when version is less than minimum', () {
    when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
    when(mockXcodeProjectInterpreter.majorVersion).thenReturn(9);
    when(mockXcodeProjectInterpreter.minorVersion).thenReturn(0);

    expect(xcode.isVersionSatisfactory, isFalse);
  });

  testWithoutContext('xcodeVersionSatisfactory is false when xcodebuild tools are not installed', () {
    when(mockXcodeProjectInterpreter.isInstalled).thenReturn(false);

    expect(xcode.isVersionSatisfactory, isFalse);
  });

  testWithoutContext('xcodeVersionSatisfactory is true when version meets minimum', () {
    when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
    when(mockXcodeProjectInterpreter.majorVersion).thenReturn(10);
    when(mockXcodeProjectInterpreter.minorVersion).thenReturn(2);

    expect(xcode.isVersionSatisfactory, isTrue);
  });

  testWithoutContext('xcodeVersionSatisfactory is true when major version exceeds minimum', () {
    when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
    when(mockXcodeProjectInterpreter.majorVersion).thenReturn(11);
    when(mockXcodeProjectInterpreter.minorVersion).thenReturn(2);

    expect(xcode.isVersionSatisfactory, isTrue);
  });

  testWithoutContext('xcodeVersionSatisfactory is true when minor version exceeds minimum', () {
    when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
    when(mockXcodeProjectInterpreter.majorVersion).thenReturn(10);
    when(mockXcodeProjectInterpreter.minorVersion).thenReturn(3);

    expect(xcode.isVersionSatisfactory, isTrue);
  });

  testWithoutContext('isInstalledAndMeetsVersionCheck is false when not macOS', () {
    when(platform.isMacOS).thenReturn(false);

    expect(xcode.isInstalledAndMeetsVersionCheck, isFalse);
  });

  testWithoutContext('isInstalledAndMeetsVersionCheck is false when not installed', () {
    when(platform.isMacOS).thenReturn(true);
    const String xcodePath = '/Applications/Xcode8.0.app/Contents/Developer';
    when(processManager.runSync(<String>['/usr/bin/xcode-select', '--print-path']))
      .thenReturn(ProcessResult(1, 0, xcodePath, ''));
    when(mockXcodeProjectInterpreter.isInstalled).thenReturn(false);

    expect(xcode.isInstalledAndMeetsVersionCheck, isFalse);
  });

  testWithoutContext('isInstalledAndMeetsVersionCheck is false when no xcode-select', () {
    when(platform.isMacOS).thenReturn(true);
    when(processManager.runSync(<String>['/usr/bin/xcode-select', '--print-path']))
      .thenReturn(ProcessResult(1, 127, '', 'ERROR'));
    when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
    when(mockXcodeProjectInterpreter.majorVersion).thenReturn(10);
    when(mockXcodeProjectInterpreter.minorVersion).thenReturn(2);

    expect(xcode.isInstalledAndMeetsVersionCheck, isFalse);
  });

  testWithoutContext('isInstalledAndMeetsVersionCheck is false when version not satisfied', () {
    when(platform.isMacOS).thenReturn(true);
    const String xcodePath = '/Applications/Xcode8.0.app/Contents/Developer';
    when(processManager.runSync(<String>['/usr/bin/xcode-select', '--print-path']))
      .thenReturn(ProcessResult(1, 0, xcodePath, ''));
    when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
    when(mockXcodeProjectInterpreter.majorVersion).thenReturn(9);
    when(mockXcodeProjectInterpreter.minorVersion).thenReturn(0);

    expect(xcode.isInstalledAndMeetsVersionCheck, isFalse);
  });

  testWithoutContext('isInstalledAndMeetsVersionCheck is true when macOS and installed and version is satisfied', () {
    when(platform.isMacOS).thenReturn(true);
    const String xcodePath = '/Applications/Xcode8.0.app/Contents/Developer';
    when(processManager.runSync(<String>['/usr/bin/xcode-select', '--print-path']))
      .thenReturn(ProcessResult(1, 0, xcodePath, ''));
    when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
    when(mockXcodeProjectInterpreter.majorVersion).thenReturn(10);
    when(mockXcodeProjectInterpreter.minorVersion).thenReturn(2);

    expect(xcode.isInstalledAndMeetsVersionCheck, isTrue);
  });

  testWithoutContext('eulaSigned is false when clang is not installed', () {
    when(processManager.runSync(<String>['/usr/bin/xcrun', 'clang']))
        .thenThrow(const ProcessException('/usr/bin/xcrun', <String>['clang']));

    expect(xcode.eulaSigned, isFalse);
  });

  testWithoutContext('eulaSigned is false when clang output indicates EULA not yet accepted', () {
    when(processManager.runSync(<String>['/usr/bin/xcrun', 'clang']))
        .thenReturn(ProcessResult(1, 1, '', 'Xcode EULA has not been accepted.\nLaunch Xcode and accept the license.'));

    expect(xcode.eulaSigned, isFalse);
  });

  testWithoutContext('eulaSigned is true when clang output indicates EULA has been accepted', () {
    when(processManager.runSync(<String>['/usr/bin/xcrun', 'clang']))
        .thenReturn(ProcessResult(1, 1, '', 'clang: error: no input files'));

    expect(xcode.eulaSigned, isTrue);
  });

  testWithoutContext('SDK name', () {
    expect(getNameForSdk(SdkType.iPhone), 'iphoneos');
    expect(getNameForSdk(SdkType.iPhoneSimulator), 'iphonesimulator');
    expect(getNameForSdk(SdkType.macOS), 'macosx');
  });
}

class MockLogger extends Mock implements Logger {}
