// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/error_handling_file_system.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:path/path.dart' as path; // ignore: package_path_import

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/testbed.dart';

class MockFile extends Mock implements File {}
class MockFileSystem extends Mock implements FileSystem {}
class MockPlatform extends Mock implements Platform {}
class MockPathContext extends Mock implements path.Context {}

void main() {
  group('throws ToolExit on Windows', () {
    const int kDeviceFull = 112;
    const int kUserMappedSectionOpened = 1224;
    Testbed testbed;
    MockFileSystem mockFileSystem;
    MockPlatform windowsPlatform;
    ErrorHandlingFileSystem fs;

    setUp(() {
      mockFileSystem = MockFileSystem();
      fs = ErrorHandlingFileSystem(mockFileSystem);

      windowsPlatform = MockPlatform();
      when(windowsPlatform.isWindows).thenReturn(true);
      when(windowsPlatform.isLinux).thenReturn(false);
      when(windowsPlatform.isMacOS).thenReturn(false);
      when(mockFileSystem.path).thenReturn(MockPathContext());
      testbed = Testbed(overrides: <Type, Generator>{
        Platform: () => windowsPlatform,
      });
    });

    void writeTests({
      String testName,
      int errorCode,
      String expectedMessage,
    }) {
      test(testName, () => testbed.run(() async {
        final MockFile mockFile = MockFile();
        when(mockFileSystem.file(any)).thenReturn(mockFile);
        when(mockFile.writeAsBytes(
          any,
          mode: anyNamed('mode'),
          flush: anyNamed('flush'),
        )).thenAnswer((_) async {
          throw FileSystemException('', '', OSError('', errorCode));
        });
        when(mockFile.writeAsString(
          any,
          mode: anyNamed('mode'),
          encoding: anyNamed('encoding'),
          flush: anyNamed('flush'),
        )).thenAnswer((_) async {
          throw FileSystemException('', '', OSError('', errorCode));
        });
        when(mockFile.writeAsBytesSync(
          any,
          mode: anyNamed('mode'),
          flush: anyNamed('flush'),
        )).thenThrow(FileSystemException('', '', OSError('', errorCode)));
        when(mockFile.writeAsStringSync(
          any,
          mode: anyNamed('mode'),
          encoding: anyNamed('encoding'),
          flush: anyNamed('flush'),
        )).thenThrow(FileSystemException('', '', OSError('', errorCode)));

        final File file = fs.file('file');

        expect(() async => await file.writeAsBytes(<int>[0]),
               throwsToolExit(message: expectedMessage));
        expect(() async => await file.writeAsString(''),
               throwsToolExit(message: expectedMessage));
        expect(() => file.writeAsBytesSync(<int>[0]),
               throwsToolExit(message: expectedMessage));
        expect(() => file.writeAsStringSync(''),
               throwsToolExit(message: expectedMessage));
      }));
    }

    writeTests(
      testName: 'when writing to a full device',
      errorCode: kDeviceFull,
      expectedMessage: 'The target device is full',
    );
    writeTests(
      testName: 'when the file is being used by another program',
      errorCode: kUserMappedSectionOpened,
      expectedMessage: 'The file is being used by another program',
    );
  });

  test('Caches path context correctly', () {
    final MockFileSystem mockFileSystem = MockFileSystem();
    final FileSystem fs = ErrorHandlingFileSystem(mockFileSystem);

    expect(identical(fs.path, fs.path), true);
  });

  test('Clears cache when CWD changes', () {
    final MockFileSystem mockFileSystem = MockFileSystem();
    final FileSystem fs = ErrorHandlingFileSystem(mockFileSystem);

    final Object firstPath = fs.path;

    fs.currentDirectory = null;
    when(mockFileSystem.path).thenReturn(MockPathContext());

    expect(identical(firstPath, fs.path), false);
  });
}
