// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:platform/platform.dart';

import '../src/common.dart';
import '../src/context.dart';

const String kExecutable = 'foo';
const String kPath1 = '/bar/bin/$kExecutable';
const String kPath2 = '/another/bin/$kExecutable';

void main() {
  ProcessManager mockProcessManager;

  setUp(() {
    mockProcessManager = MockProcessManager();
  });

  group('which on POSIX', () {

    testUsingContext('returns null when executable does not exist', () async {
      when(mockProcessManager.runSync(<String>['which', kExecutable]))
          .thenReturn(ProcessResult(0, 1, null, null));
      final OperatingSystemUtils utils = OperatingSystemUtils();
      expect(utils.which(kExecutable), isNull);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Platform: () => FakePlatform(operatingSystem: 'linux')
    });

    testUsingContext('returns exactly one result', () async {
      when(mockProcessManager.runSync(<String>['which', 'foo']))
          .thenReturn(ProcessResult(0, 0, kPath1, null));
      final OperatingSystemUtils utils = OperatingSystemUtils();
      expect(utils.which(kExecutable).path, kPath1);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Platform: () => FakePlatform(operatingSystem: 'linux')
    });

    testUsingContext('returns all results for whichAll', () async {
      when(mockProcessManager.runSync(<String>['which', '-a', kExecutable]))
          .thenReturn(ProcessResult(0, 0, '$kPath1\n$kPath2', null));
      final OperatingSystemUtils utils = OperatingSystemUtils();
      final List<File> result = utils.whichAll(kExecutable);
      expect(result, hasLength(2));
      expect(result[0].path, kPath1);
      expect(result[1].path, kPath2);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Platform: () => FakePlatform(operatingSystem: 'linux')
    });
  });

  group('which on Windows', () {

    testUsingContext('returns null when executable does not exist', () async {
      when(mockProcessManager.runSync(<String>['where', kExecutable]))
          .thenReturn(ProcessResult(0, 1, null, null));
      final OperatingSystemUtils utils = OperatingSystemUtils();
      expect(utils.which(kExecutable), isNull);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Platform: () => FakePlatform(operatingSystem: 'windows')
    });

    testUsingContext('returns exactly one result', () async {
      when(mockProcessManager.runSync(<String>['where', 'foo']))
          .thenReturn(ProcessResult(0, 0, '$kPath1\n$kPath2', null));
      final OperatingSystemUtils utils = OperatingSystemUtils();
      expect(utils.which(kExecutable).path, kPath1);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Platform: () => FakePlatform(operatingSystem: 'windows')
    });

    testUsingContext('returns all results for whichAll', () async {
      when(mockProcessManager.runSync(<String>['where', kExecutable]))
          .thenReturn(ProcessResult(0, 0, '$kPath1\n$kPath2', null));
      final OperatingSystemUtils utils = OperatingSystemUtils();
      final List<File> result = utils.whichAll(kExecutable);
      expect(result, hasLength(2));
      expect(result[0].path, kPath1);
      expect(result[1].path, kPath2);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Platform: () => FakePlatform(operatingSystem: 'windows')
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
