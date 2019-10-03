// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/io.dart' show ProcessException, ProcessResult;
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

class MockProcessManager extends Mock implements ProcessManager {}
class MockXcodeProjectInterpreter extends Mock implements XcodeProjectInterpreter {}
class MockPlatform extends Mock implements Platform {}

void main() {
  group('Xcode', () {
    MockProcessManager mockProcessManager;
    Xcode xcode;
    MockXcodeProjectInterpreter mockXcodeProjectInterpreter;
    MockPlatform mockPlatform;

    setUp(() {
      mockProcessManager = MockProcessManager();
      mockXcodeProjectInterpreter = MockXcodeProjectInterpreter();
      xcode = Xcode();
      mockPlatform = MockPlatform();
    });

    testUsingContext('xcodeSelectPath returns null when xcode-select is not installed', () {
      when(mockProcessManager.runSync(<String>['/usr/bin/xcode-select', '--print-path']))
          .thenThrow(const ProcessException('/usr/bin/xcode-select', <String>['--print-path']));
      expect(xcode.xcodeSelectPath, isNull);
      when(mockProcessManager.runSync(<String>['/usr/bin/xcode-select', '--print-path']))
          .thenThrow(ArgumentError('Invalid argument(s): Cannot find executable for /usr/bin/xcode-select'));
      expect(xcode.xcodeSelectPath, isNull);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('xcodeSelectPath returns path when xcode-select is installed', () {
      const String xcodePath = '/Applications/Xcode8.0.app/Contents/Developer';
      when(mockProcessManager.runSync(<String>['/usr/bin/xcode-select', '--print-path']))
          .thenReturn(ProcessResult(1, 0, xcodePath, ''));
      expect(xcode.xcodeSelectPath, xcodePath);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('xcodeVersionSatisfactory is false when version is less than minimum', () {
      when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
      when(mockXcodeProjectInterpreter.majorVersion).thenReturn(8);
      when(mockXcodeProjectInterpreter.minorVersion).thenReturn(17);
      expect(xcode.isVersionSatisfactory, isFalse);
    }, overrides: <Type, Generator>{
      XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
    });

    testUsingContext('xcodeVersionSatisfactory is false when xcodebuild tools are not installed', () {
      when(mockXcodeProjectInterpreter.isInstalled).thenReturn(false);
      expect(xcode.isVersionSatisfactory, isFalse);
    }, overrides: <Type, Generator>{
      XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
    });

    testUsingContext('xcodeVersionSatisfactory is true when version meets minimum', () {
      when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
      when(mockXcodeProjectInterpreter.majorVersion).thenReturn(9);
      when(mockXcodeProjectInterpreter.minorVersion).thenReturn(0);
      expect(xcode.isVersionSatisfactory, isTrue);
    }, overrides: <Type, Generator>{
      XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
    });

    testUsingContext('xcodeVersionSatisfactory is true when major version exceeds minimum', () {
      when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
      when(mockXcodeProjectInterpreter.majorVersion).thenReturn(10);
      when(mockXcodeProjectInterpreter.minorVersion).thenReturn(0);
      expect(xcode.isVersionSatisfactory, isTrue);
    }, overrides: <Type, Generator>{
      XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
    });

    testUsingContext('xcodeVersionSatisfactory is true when minor version exceeds minimum', () {
      when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
      when(mockXcodeProjectInterpreter.majorVersion).thenReturn(9);
      when(mockXcodeProjectInterpreter.minorVersion).thenReturn(1);
      expect(xcode.isVersionSatisfactory, isTrue);
    }, overrides: <Type, Generator>{
      XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
    });

    testUsingContext('isInstalledAndMeetsVersionCheck is false when not macOS', () {
      when(mockPlatform.isMacOS).thenReturn(false);
      expect(xcode.isInstalledAndMeetsVersionCheck, isFalse);
    }, overrides: <Type, Generator>{
      XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
      Platform: () => mockPlatform,
    });

    testUsingContext('isInstalledAndMeetsVersionCheck is false when not installed', () {
      when(mockPlatform.isMacOS).thenReturn(true);

      const String xcodePath = '/Applications/Xcode8.0.app/Contents/Developer';
      when(mockProcessManager.runSync(<String>['/usr/bin/xcode-select', '--print-path']))
        .thenReturn(ProcessResult(1, 0, xcodePath, ''));

      when(mockXcodeProjectInterpreter.isInstalled).thenReturn(false);
      expect(xcode.isInstalledAndMeetsVersionCheck, isFalse);
    }, overrides: <Type, Generator>{
      XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
      Platform: () => mockPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('isInstalledAndMeetsVersionCheck is false when no xcode-select', () {
      when(mockPlatform.isMacOS).thenReturn(true);

      when(mockProcessManager.runSync(<String>['/usr/bin/xcode-select', '--print-path']))
        .thenReturn(ProcessResult(1, 127, '', 'ERROR'));

      when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
      when(mockXcodeProjectInterpreter.majorVersion).thenReturn(9);
      when(mockXcodeProjectInterpreter.minorVersion).thenReturn(1);

      expect(xcode.isInstalledAndMeetsVersionCheck, isFalse);
    }, overrides: <Type, Generator>{
      XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
      Platform: () => mockPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('isInstalledAndMeetsVersionCheck is false when version not satisfied', () {
      when(mockPlatform.isMacOS).thenReturn(true);

      const String xcodePath = '/Applications/Xcode8.0.app/Contents/Developer';
      when(mockProcessManager.runSync(<String>['/usr/bin/xcode-select', '--print-path']))
        .thenReturn(ProcessResult(1, 0, xcodePath, ''));

      when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
      when(mockXcodeProjectInterpreter.majorVersion).thenReturn(8);
      when(mockXcodeProjectInterpreter.minorVersion).thenReturn(0);
      expect(xcode.isInstalledAndMeetsVersionCheck, isFalse);
    }, overrides: <Type, Generator>{
      XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
      Platform: () => mockPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('isInstalledAndMeetsVersionCheck is true when macOS and installed and version is satisfied', () {
      when(mockPlatform.isMacOS).thenReturn(true);

      const String xcodePath = '/Applications/Xcode8.0.app/Contents/Developer';
      when(mockProcessManager.runSync(<String>['/usr/bin/xcode-select', '--print-path']))
        .thenReturn(ProcessResult(1, 0, xcodePath, ''));

      when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
      when(mockXcodeProjectInterpreter.majorVersion).thenReturn(9);
      when(mockXcodeProjectInterpreter.minorVersion).thenReturn(1);
      expect(xcode.isInstalledAndMeetsVersionCheck, isTrue);
    }, overrides: <Type, Generator>{
      XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
      Platform: () => mockPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('eulaSigned is false when clang is not installed', () {
      when(mockProcessManager.runSync(<String>['/usr/bin/xcrun', 'clang']))
          .thenThrow(const ProcessException('/usr/bin/xcrun', <String>['clang']));
      expect(xcode.eulaSigned, isFalse);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('eulaSigned is false when clang output indicates EULA not yet accepted', () {
      when(mockProcessManager.runSync(<String>['/usr/bin/xcrun', 'clang']))
          .thenReturn(ProcessResult(1, 1, '', 'Xcode EULA has not been accepted.\nLaunch Xcode and accept the license.'));
      expect(xcode.eulaSigned, isFalse);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('eulaSigned is true when clang output indicates EULA has been accepted', () {
      when(mockProcessManager.runSync(<String>['/usr/bin/xcrun', 'clang']))
          .thenReturn(ProcessResult(1, 1, '', 'clang: error: no input files'));
      expect(xcode.eulaSigned, isTrue);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });
  });
}
