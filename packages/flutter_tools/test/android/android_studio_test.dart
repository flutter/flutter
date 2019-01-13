// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';

import '../src/common.dart';
import '../src/context.dart';

const String home = '/home/me';

Platform linuxPlatform() {
  return FakePlatform.fromPlatform(const LocalPlatform())
    ..operatingSystem = 'linux'
    ..environment = <String, String>{'HOME': home};
}

void main() {
  const String installPath = '/opt/android-studio-with-cheese-5.0';
  const String studioHome = '$home/.AndroidStudioWithCheese5.0';
  const String homeFile = '$studioHome/system/.home';

  MemoryFileSystem fs;

  setUp(() {
    fs = MemoryFileSystem();
    fs.directory(installPath).createSync(recursive: true);
    fs.file(homeFile).createSync(recursive: true);
    fs.file(homeFile).writeAsStringSync(installPath);
  });

  group('pluginsPath', () {
    testUsingContext('extracts custom paths from home dir', () {
      final AndroidStudio studio =
          AndroidStudio.fromHomeDot(fs.directory(studioHome));
      expect(studio, isNotNull);
      expect(studio.pluginsPath,
          equals('/home/me/.AndroidStudioWithCheese5.0/config/plugins'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      // Custom home paths are not supported on macOS nor Windows yet,
      // so we force the platform to fake Linux here.
      Platform: () => linuxPlatform(),
    });
  });
}
