// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';

const String homeLinux = '/home/me';
const String homeMac = '/Users/me';

const Map<String, dynamic> macStudioInfoPlist = <String, dynamic>{
  'CFBundleGetInfoString': 'Android Studio 3.3, build AI-182.5107.16.33.5199772. Copyright JetBrains s.r.o., (c) 2000-2018',
  'CFBundleShortVersionString': '3.3',
  'CFBundleVersion': 'AI-182.5107.16.33.5199772',
  'JVMOptions': <String, dynamic>{
    'Properties': <String, dynamic>{
      'idea.paths.selector': 'AndroidStudio3.3',
      'idea.platform.prefix': 'AndroidStudio',
    },
  },
};

class MockPlistUtils extends Mock implements PlistParser {}

Platform linuxPlatform() {
  return FakePlatform.fromPlatform(const LocalPlatform())
    ..operatingSystem = 'linux'
    ..environment = <String, String>{'HOME': homeLinux};
}

Platform macPlatform() {
  return FakePlatform.fromPlatform(const LocalPlatform())
    ..operatingSystem = 'macos'
    ..environment = <String, String>{'HOME': homeMac};
}

void main() {
  MemoryFileSystem fs;
  MockPlistUtils plistUtils;

  setUp(() {
    fs = MemoryFileSystem();
    plistUtils = MockPlistUtils();
  });

  group('pluginsPath on Linux', () {
    testUsingContext('extracts custom paths from home dir', () {
      const String installPath = '/opt/android-studio-with-cheese-5.0';
      const String studioHome = '$homeLinux/.AndroidStudioWithCheese5.0';
      const String homeFile = '$studioHome/system/.home';
      fs.directory(installPath).createSync(recursive: true);
      fs.file(homeFile).createSync(recursive: true);
      fs.file(homeFile).writeAsStringSync(installPath);

      final AndroidStudio studio =
      AndroidStudio.fromHomeDot(fs.directory(studioHome));
      expect(studio, isNotNull);
      expect(studio.pluginsPath,
          equals('/home/me/.AndroidStudioWithCheese5.0/config/plugins'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
      // Custom home paths are not supported on macOS nor Windows yet,
      // so we force the platform to fake Linux here.
      Platform: () => linuxPlatform(),
    });
  });

  group('pluginsPath on Mac', () {
    testUsingContext('extracts custom paths for directly downloaded Android Studio on Mac', () {
      final String studioInApplicationPlistFolder = fs.path.join('/', 'Application', 'Android Studio.app', 'Contents');
      fs.directory(studioInApplicationPlistFolder).createSync(recursive: true);

      final String plistFilePath = fs.path.join(studioInApplicationPlistFolder, 'Info.plist');
      when(plistUtils.parseFile(plistFilePath)).thenReturn(macStudioInfoPlist);
      final AndroidStudio studio = AndroidStudio.fromMacOSBundle(fs.directory(studioInApplicationPlistFolder)?.parent?.path);
      expect(studio, isNotNull);
      expect(studio.pluginsPath,
          equals(fs.path.join(homeMac, 'Library', 'Application Support', 'AndroidStudio3.3')));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
      // Custom home paths are not supported on macOS nor Windows yet,
      // so we force the platform to fake Linux here.
      Platform: () => macPlatform(),
      PlistParser: () => plistUtils,
    });

    testUsingContext('extracts custom paths for Android Studio downloaded by JetBrainsToolbox on Mac', () {
      final String jetbrainsStudioInApplicationPlistFolder = fs.path.join(homeMac, 'Application', 'JetBrains Toolbox', 'Android Studio.app', 'Contents');
      fs.directory(jetbrainsStudioInApplicationPlistFolder).createSync(recursive: true);
      const Map<String, dynamic> jetbrainsInfoPlist = <String, dynamic>{
        'CFBundleLongVersionString': '3.3',
        'CFBundleShortVersionString': '3.3',
        'CFBundleVersion': '3.3',
        'JetBrainsToolboxApp': '$homeMac/Library/Application Support/JetBrains/Toolbox/apps/AndroidStudio/ch-0/183.5256920/Android Studio 3.3.app',
      };
      final String jetbrainsPlistFilePath = fs.path.join(jetbrainsStudioInApplicationPlistFolder, 'Info.plist');
      when(plistUtils.parseFile(jetbrainsPlistFilePath)).thenReturn(jetbrainsInfoPlist);

      final String studioInApplicationPlistFolder = fs.path.join(fs.path.join(homeMac, 'Library', 'Application Support'), 'JetBrains', 'Toolbox', 'apps', 'AndroidStudio', 'ch-0', '183.5256920', fs.path.join('Android Studio 3.3.app', 'Contents'));
      fs.directory(studioInApplicationPlistFolder).createSync(recursive: true);
      final String studioPlistFilePath = fs.path.join(studioInApplicationPlistFolder, 'Info.plist');
      when(plistUtils.parseFile(studioPlistFilePath)).thenReturn(macStudioInfoPlist);

      final AndroidStudio studio = AndroidStudio.fromMacOSBundle(fs.directory(jetbrainsStudioInApplicationPlistFolder)?.parent?.path);
      expect(studio, isNotNull);
      expect(studio.pluginsPath,
          equals(fs.path.join(homeMac, 'Library', 'Application Support', 'AndroidStudio3.3')));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
      // Custom home paths are not supported on macOS nor Windows yet,
      // so we force the platform to fake Linux here.
      Platform: () => macPlatform(),
      PlistParser: () => plistUtils,
    });

  });
}
