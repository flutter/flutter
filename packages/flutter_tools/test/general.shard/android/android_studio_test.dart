// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
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

final Platform linuxPlatform = FakePlatform(
  operatingSystem: 'linux',
  environment: <String, String>{'HOME': homeLinux},
);

final Platform windowsPlatform = FakePlatform(
  operatingSystem: 'windows',
  environment: <String, String>{
    'LOCALAPPDATA': 'C:\\Users\\Dash\\AppData\\Local',
  }
);

class MockPlistUtils extends Mock implements PlistParser {}

Platform macPlatform() {
  return FakePlatform(
    operatingSystem: 'macos',
    environment: <String, String>{'HOME': homeMac},
  );
}

void main() {
  FileSystem fileSystem;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
  });

  testUsingContext('pluginsPath on Linux extracts custom paths from home dir', () {
    const String installPath = '/opt/android-studio-with-cheese-5.0';
    const String studioHome = '$homeLinux/.AndroidStudioWithCheese5.0';
    const String homeFile = '$studioHome/system/.home';
    globals.fs.directory(installPath).createSync(recursive: true);
    globals.fs.file(homeFile).createSync(recursive: true);
    globals.fs.file(homeFile).writeAsStringSync(installPath);

    final AndroidStudio studio =
      AndroidStudio.fromHomeDot(globals.fs.directory(studioHome));
    expect(studio, isNotNull);
    expect(studio.pluginsPath,
        equals('/home/me/.AndroidStudioWithCheese5.0/config/plugins'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    // Custom home paths are not supported on macOS nor Windows yet,
    // so we force the platform to fake Linux here.
    Platform: () => linuxPlatform,
    FileSystemUtils: () => FileSystemUtils(
      fileSystem: fileSystem,
      platform: linuxPlatform,
    ),
  });

  group('pluginsPath on Mac', () {
    FileSystemUtils fsUtils;
    Platform platform;
    MockPlistUtils plistUtils;

    setUp(() {
      plistUtils = MockPlistUtils();
      platform = macPlatform();
      fsUtils = FileSystemUtils(
        fileSystem: fileSystem,
        platform: platform,
      );
    });

    testUsingContext('extracts custom paths for directly downloaded Android Studio on Mac', () {
      final String studioInApplicationPlistFolder = globals.fs.path.join(
        '/',
        'Application',
        'Android Studio.app',
        'Contents',
      );
      globals.fs.directory(studioInApplicationPlistFolder).createSync(recursive: true);

      final String plistFilePath = globals.fs.path.join(studioInApplicationPlistFolder, 'Info.plist');
      when(plistUtils.parseFile(plistFilePath)).thenReturn(macStudioInfoPlist);
      final AndroidStudio studio = AndroidStudio.fromMacOSBundle(
        globals.fs.directory(studioInApplicationPlistFolder)?.parent?.path,
      );
      expect(studio, isNotNull);
      expect(studio.pluginsPath, equals(globals.fs.path.join(
        homeMac,
        'Library',
        'Application Support',
        'AndroidStudio3.3',
      )));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      FileSystemUtils: () => fsUtils,
      ProcessManager: () => FakeProcessManager.any(),
      // Custom home paths are not supported on macOS nor Windows yet,
      // so we force the platform to fake Linux here.
      Platform: () => platform,
      PlistParser: () => plistUtils,
    });

    testUsingContext('extracts custom paths for Android Studio downloaded by JetBrainsToolbox on Mac', () {
      final String jetbrainsStudioInApplicationPlistFolder = globals.fs.path.join(
        homeMac,
        'Application',
        'JetBrains Toolbox',
        'Android Studio.app',
        'Contents',
      );
      globals.fs.directory(jetbrainsStudioInApplicationPlistFolder).createSync(recursive: true);
      const Map<String, dynamic> jetbrainsInfoPlist = <String, dynamic>{
        'CFBundleLongVersionString': '3.3',
        'CFBundleShortVersionString': '3.3',
        'CFBundleVersion': '3.3',
        'JetBrainsToolboxApp': '$homeMac/Library/Application Support/JetBrains/Toolbox/apps/AndroidStudio/ch-0/183.5256920/Android Studio 3.3.app',
      };
      final String jetbrainsPlistFilePath = globals.fs.path.join(
        jetbrainsStudioInApplicationPlistFolder,
        'Info.plist',
      );
      when(plistUtils.parseFile(jetbrainsPlistFilePath)).thenReturn(jetbrainsInfoPlist);

      final String studioInApplicationPlistFolder = globals.fs.path.join(
        globals.fs.path.join(homeMac,'Library','Application Support'),
        'JetBrains',
        'Toolbox',
        'apps',
        'AndroidStudio',
        'ch-0',
        '183.5256920',
        globals.fs.path.join('Android Studio 3.3.app', 'Contents'),
      );
      globals.fs.directory(studioInApplicationPlistFolder).createSync(recursive: true);
      final String studioPlistFilePath = globals.fs.path.join(
        studioInApplicationPlistFolder,
        'Info.plist',
      );
      when(plistUtils.parseFile(studioPlistFilePath)).thenReturn(macStudioInfoPlist);

      final AndroidStudio studio = AndroidStudio.fromMacOSBundle(
        globals.fs.directory(jetbrainsStudioInApplicationPlistFolder)?.parent?.path,
      );
      expect(studio, isNotNull);
      expect(studio.pluginsPath, equals(globals.fs.path.join(
        homeMac,
        'Library',
        'Application Support',
        'AndroidStudio3.3',
      )));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      FileSystemUtils: () => fsUtils,
      ProcessManager: () => FakeProcessManager.any(),
      // Custom home paths are not supported on macOS nor Windows yet,
      // so we force the platform to fake Linux here.
      Platform: () => platform,
      PlistParser: () => plistUtils,
    });
  });

  FileSystem windowsFileSystem;

  setUp(() {
    windowsFileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
  });

  testUsingContext('Can discover Android Studio 4.1 location on Windows', () {
    windowsFileSystem.file('C:\\Users\\Dash\\AppData\\Local\\Google\\AndroidStudio4.1\\.home')
      ..createSync(recursive: true)
      ..writeAsStringSync('C:\\Program Files\\AndroidStudio');
    windowsFileSystem
      .directory('C:\\Program Files\\AndroidStudio')
      .createSync(recursive: true);

    final AndroidStudio studio = AndroidStudio.allInstalled().single;

    expect(studio.version, Version(4, 1, 0));
    expect(studio.studioAppName, 'Android Studio 4.1');
  }, overrides: <Type, Generator>{
    Platform: () => windowsPlatform,
    FileSystem: () => windowsFileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });
}
