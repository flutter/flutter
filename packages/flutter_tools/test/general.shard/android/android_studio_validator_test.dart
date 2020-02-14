// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/android/android_studio_validator.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

const String home = '/home/me';

Platform linuxPlatform() {
  return FakePlatform.fromPlatform(const LocalPlatform())
    ..operatingSystem = 'linux'
    ..environment = <String, String>{'HOME': home};
}

void main() {
  group('NoAndroidStudioValidator', () {
    testUsingContext('shows Android Studio as "not available" when not available.', () async {
      final NoAndroidStudioValidator validator = NoAndroidStudioValidator();
      expect((await validator.validate()).type, equals(ValidationType.notAvailable));
    }, overrides: <Type, Generator>{
      // Custom home paths are not supported on macOS nor Windows yet,
      // so we force the platform to fake Linux here.
      Platform: () => linuxPlatform(),
    });
  });

  group('AndroidStudioValidator', () {
    MemoryFileSystem fs;
    MockProcessManager mockProcessManager;
    setUp(() {
      fs = MemoryFileSystem();
      mockProcessManager = MockProcessManager();
    });

    testUsingContext('gives doctor error on java crash', () async {
      when(mockProcessManager.canRun(any)).thenReturn(true);
      when(mockProcessManager.runSync(any)).thenAnswer((Invocation _) {
        throw const ProcessException('java', <String>['--version']);
      });
      const String installPath = '/opt/android-studio-with-cheese-5.0';
      const String studioHome = '$home/.AndroidStudioWithCheese5.0';
      const String homeFile = '$studioHome/system/.home';
      globals.fs.directory(installPath).createSync(recursive: true);
      globals.fs.file(homeFile).createSync(recursive: true);
      globals.fs.file(homeFile).writeAsStringSync(installPath);

      // This checks that running the validator doesn't throw an unhandled
      // exception and that the ProcessException makes it into the error
      // message list.
      for (final DoctorValidator validator in AndroidStudioValidator.allValidators) {
        final ValidationResult result = await validator.validate();
        expect(result.messages.where((ValidationMessage message) {
          return message.isError && message.message.contains('ProcessException');
        }).isNotEmpty, true);
      }
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
      Platform: () => linuxPlatform(),
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
