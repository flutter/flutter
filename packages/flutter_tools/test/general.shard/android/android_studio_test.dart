// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';

const String homeLinux = '/home/me';
const String homeMac = '/Users/me';

const Map<String, Object> macStudioInfoPlist = <String, Object>{
  'CFBundleGetInfoString': 'Android Studio 3.3, build AI-182.5107.16.33.5199772. Copyright JetBrains s.r.o., (c) 2000-2018',
  'CFBundleShortVersionString': '3.3',
  'CFBundleVersion': 'AI-182.5107.16.33.5199772',
  'JVMOptions': <String, Object>{
    'Properties': <String, Object>{
      'idea.paths.selector': 'AndroidStudio3.3',
      'idea.platform.prefix': 'AndroidStudio',
    },
  },
};

const Map<String, Object> macStudioInfoPlist4_1 = <String, Object>{
  'CFBundleGetInfoString': 'Android Studio 4.1, build AI-201.8743.12.41.6858069. Copyright JetBrains s.r.o., (c) 2000-2020',
  'CFBundleShortVersionString': '4.1',
  'CFBundleVersion': 'AI-201.8743.12.41.6858069',
  'JVMOptions': <String, Object>{
    'Properties': <String, Object>{
      'idea.vendor.name' : 'Google',
      'idea.paths.selector': 'AndroidStudio4.1',
      'idea.platform.prefix': 'AndroidStudio',
    },
  },
};

const Map<String, Object> macStudioInfoPlist2020_3 = <String, Object>{
  'CFBundleGetInfoString': 'Android Studio 2020.3, build AI-203.7717.56.2031.7583922. Copyright JetBrains s.r.o., (c) 2000-2021',
  'CFBundleShortVersionString': '2020.3',
  'CFBundleVersion': 'AI-203.7717.56.2031.7583922',
  'JVMOptions': <String, Object>{
    'Properties': <String, Object>{
      'idea.vendor.name' : 'Google',
      'idea.paths.selector': 'AndroidStudio2020.3',
      'idea.platform.prefix': 'AndroidStudio',
    },
  },
};

const Map<String, Object> macStudioInfoPlist2022_1 = <String, Object>{
  'CFBundleGetInfoString': 'Android Studio 2022.1, build AI-221.6008.13.2211.9477386. Copyright JetBrains s.r.o., (c) 2000-2023',
  'CFBundleShortVersionString': '2022.1',
  'CFBundleVersion': 'AI-221.6008.13.2211.9477386',
  'JVMOptions': <String, Object>{
    'Properties': <String, Object>{
      'idea.vendor.name' : 'Google',
      'idea.paths.selector': 'AndroidStudio2022.1',
      'idea.platform.prefix': 'AndroidStudio',
    },
  },
};

const Map<String, Object> macStudioInfoPlistEAP = <String, Object>{
  'CFBundleGetInfoString': 'Android Studio EAP AI-212.5712.43.2112.8233820, build AI-212.5712.43.2112.8233820. Copyright JetBrains s.r.o., (c) 2000-2022',
  'CFBundleShortVersionString': 'EAP AI-212.5712.43.2112.8233820',
  'CFBundleVersion': 'AI-212.5712.43.2112.8233820',
  'JVMOptions': <String, Object>{
    'Properties': <String, Object>{
      'idea.vendor.name' : 'Google',
      'idea.paths.selector': 'AndroidStudio2021.2',
      'idea.platform.prefix': 'AndroidStudio',
    },
  },
};

final Platform linuxPlatform = FakePlatform(
  environment: <String, String>{'HOME': homeLinux},
);

final Platform windowsPlatform = FakePlatform(
  operatingSystem: 'windows',
  environment: <String, String>{
    'LOCALAPPDATA': r'C:\Users\Dash\AppData\Local',
  }
);

Platform macPlatform() {
  return FakePlatform(
    operatingSystem: 'macos',
    environment: <String, String>{'HOME': homeMac},
  );
}

void main() {
  late FileSystem fileSystem;

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
      AndroidStudio.fromHomeDot(globals.fs.directory(studioHome))!;
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
    late FileSystemUtils fsUtils;
    late Platform platform;
    late FakePlistUtils plistUtils;
    late FakeProcessManager processManager;

    setUp(() {
      plistUtils = FakePlistUtils();
      platform = macPlatform();
      fsUtils = FileSystemUtils(
        fileSystem: fileSystem,
        platform: platform,
      );
      processManager = FakeProcessManager.empty();
    });

    testUsingContext('Can discover Android Studio >=4.1 location on Mac', () {
      final String studioInApplicationPlistFolder = globals.fs.path.join(
        '/',
        'Application',
        'Android Studio.app',
        'Contents',
      );
      globals.fs.directory(studioInApplicationPlistFolder).createSync(recursive: true);

      final String plistFilePath = globals.fs.path.join(studioInApplicationPlistFolder, 'Info.plist');
      plistUtils.fileContents[plistFilePath] = macStudioInfoPlist4_1;
      processManager.addCommand(FakeCommand(
          command: <String>[
            globals.fs.path.join(studioInApplicationPlistFolder, 'jre', 'jdk', 'Contents', 'Home', 'bin', 'java'),
            '-version',
          ],
          stderr: '123',
        )
      );
      final AndroidStudio studio = AndroidStudio.fromMacOSBundle(
        globals.fs.directory(studioInApplicationPlistFolder).parent.path,
      )!;

      expect(studio, isNotNull);
      expect(studio.pluginsPath, equals(globals.fs.path.join(
        homeMac,
        'Library',
        'Application Support',
        'Google',
        'AndroidStudio4.1',
      )));
      expect(studio.validationMessages, <String>['Java version 123']);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      FileSystemUtils: () => fsUtils,
      ProcessManager: () => processManager,
      // Custom home paths are not supported on macOS nor Windows yet,
      // so we force the platform to fake Linux here.
      Platform: () => platform,
      PlistParser: () => plistUtils,
    });

    testUsingContext('Can discover Android Studio >=2020.3 location on Mac', () {
      final String studioInApplicationPlistFolder = globals.fs.path.join(
        '/',
        'Application',
        'Android Studio.app',
        'Contents',
      );
      globals.fs.directory(studioInApplicationPlistFolder).createSync(recursive: true);

      final String plistFilePath = globals.fs.path.join(studioInApplicationPlistFolder, 'Info.plist');
      plistUtils.fileContents[plistFilePath] = macStudioInfoPlist2020_3;
      processManager.addCommand(FakeCommand(
          command: <String>[
            globals.fs.path.join(studioInApplicationPlistFolder, 'jre', 'Contents', 'Home', 'bin', 'java'),
            '-version',
          ],
          stderr: '123',
        )
      );
      final AndroidStudio studio = AndroidStudio.fromMacOSBundle(
        globals.fs.directory(studioInApplicationPlistFolder).parent.path,
      )!;

      expect(studio, isNotNull);
      expect(studio.pluginsPath, equals(globals.fs.path.join(
        homeMac,
        'Library',
        'Application Support',
        'Google',
        'AndroidStudio2020.3',
      )));
      expect(studio.validationMessages, <String>['Java version 123']);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      FileSystemUtils: () => fsUtils,
      ProcessManager: () => processManager,
      // Custom home paths are not supported on macOS nor Windows yet,
      // so we force the platform to fake Linux here.
      Platform: () => platform,
      PlistParser: () => plistUtils,
    });

    testUsingContext('Can discover Android Studio <4.1 location on Mac', () {
      final String studioInApplicationPlistFolder = globals.fs.path.join(
        '/',
        'Application',
        'Android Studio.app',
        'Contents',
      );
      globals.fs.directory(studioInApplicationPlistFolder).createSync(recursive: true);

      final String plistFilePath = globals.fs.path.join(studioInApplicationPlistFolder, 'Info.plist');
      plistUtils.fileContents[plistFilePath] = macStudioInfoPlist;
      processManager.addCommand(FakeCommand(
          command: <String>[
            globals.fs.path.join(studioInApplicationPlistFolder, 'jre', 'jdk', 'Contents', 'Home', 'bin', 'java'),
            '-version',
          ],
          stderr: '123',
        )
      );
      final AndroidStudio studio = AndroidStudio.fromMacOSBundle(
        globals.fs.directory(studioInApplicationPlistFolder).parent.path,
      )!;

      expect(studio, isNotNull);
      expect(studio.pluginsPath, equals(globals.fs.path.join(
        homeMac,
        'Library',
        'Application Support',
        'AndroidStudio3.3',
      )));
      expect(studio.validationMessages, <String>['Java version 123']);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      FileSystemUtils: () => fsUtils,
      ProcessManager: () => processManager,
      // Custom home paths are not supported on macOS nor Windows yet,
      // so we force the platform to fake Linux here.
      Platform: () => platform,
      PlistParser: () => plistUtils,
    });

    testUsingContext('Can discover Android Studio EAP location on Mac', () {
      final String studioInApplicationPlistFolder = globals.fs.path.join(
        '/',
        'Application',
        'Android Studio with suffix.app',
        'Contents',
      );
      globals.fs.directory(studioInApplicationPlistFolder).createSync(recursive: true);

      final String plistFilePath = globals.fs.path.join(studioInApplicationPlistFolder, 'Info.plist');
      plistUtils.fileContents[plistFilePath] = macStudioInfoPlistEAP;
      processManager.addCommand(FakeCommand(
          command: <String>[
            globals.fs.path.join(studioInApplicationPlistFolder, 'jre', 'Contents', 'Home', 'bin', 'java'),
            '-version',
          ],
          stderr: '123',
        )
      );
      final AndroidStudio studio = AndroidStudio.fromMacOSBundle(
        globals.fs.directory(studioInApplicationPlistFolder).parent.path,
      )!;

      expect(studio, isNotNull);
      expect(studio.pluginsPath, equals(globals.fs.path.join(
        homeMac,
        'Library',
        'Application Support',
        'AndroidStudio2021.2',
      )));
      expect(studio.validationMessages, <String>['Java version 123']);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      FileSystemUtils: () => fsUtils,
      ProcessManager: () => processManager,
      // Custom home paths are not supported on macOS nor Windows yet,
      // so we force the platform to fake Linux here.
      Platform: () => platform,
      PlistParser: () => plistUtils,
    });

    testUsingContext('Does not discover Android Studio with JetBrainsToolboxApp wrapper', () {
      final String applicationPlistFolder = globals.fs.path.join(
        '/',
        'Applications',
        'Android Studio.app',
        'Contents',
      );
      globals.fs.directory(applicationPlistFolder).createSync(recursive: true);

      final String applicationsPlistFilePath = globals.fs.path.join(applicationPlistFolder, 'Info.plist');
      const Map<String, Object> jetbrainsInfoPlist = <String, Object>{
        'JetBrainsToolboxApp': 'ignored',
      };
      plistUtils.fileContents[applicationsPlistFilePath] = jetbrainsInfoPlist;

      final String homeDirectoryPlistFolder = globals.fs.path.join(
        globals.fsUtils.homeDirPath!,
        'Applications',
        'Android Studio.app',
        'Contents',
      );
      globals.fs.directory(homeDirectoryPlistFolder).createSync(recursive: true);

      final String homeDirectoryPlistFilePath = globals.fs.path.join(homeDirectoryPlistFolder, 'Info.plist');
      plistUtils.fileContents[homeDirectoryPlistFilePath] = macStudioInfoPlist2020_3;

      expect(AndroidStudio.allInstalled().length, 1);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      FileSystemUtils: () => fsUtils,
      ProcessManager: () => FakeProcessManager.any(),
      // Custom home paths are not supported on macOS nor Windows yet,
      // so we force the platform to fake Linux here.
      Platform: () => platform,
      PlistParser: () => plistUtils,
    });

    testUsingContext('Can discover installation from Spotlight query', () {
      // One in expected location.
      final String studioInApplication = fileSystem.path.join(
        '/',
        'Application',
        'Android Studio.app',
      );
      final String studioInApplicationPlistFolder = fileSystem.path.join(
        studioInApplication,
        'Contents',
      );
      fileSystem.directory(studioInApplicationPlistFolder).createSync(recursive: true);
      final String plistFilePath = fileSystem.path.join(studioInApplicationPlistFolder, 'Info.plist');
      plistUtils.fileContents[plistFilePath] = macStudioInfoPlist4_1;

      // Two in random location only Spotlight knows about.
      final String randomLocation1 = fileSystem.path.join(
        '/',
        'random',
        'Android Studio Preview.app',
      );
      final String randomLocation1PlistFolder = fileSystem.path.join(
        randomLocation1,
        'Contents',
      );
      fileSystem.directory(randomLocation1PlistFolder).createSync(recursive: true);
      final String randomLocation1PlistPath = fileSystem.path.join(randomLocation1PlistFolder, 'Info.plist');
      plistUtils.fileContents[randomLocation1PlistPath] = macStudioInfoPlist4_1;

      final String randomLocation2 = fileSystem.path.join(
        '/',
        'random',
        'Android Studio with Blaze.app',
      );
      final String randomLocation2PlistFolder = fileSystem.path.join(
        randomLocation2,
        'Contents',
      );
      fileSystem.directory(randomLocation2PlistFolder).createSync(recursive: true);
      final String randomLocation2PlistPath = fileSystem.path.join(randomLocation2PlistFolder, 'Info.plist');
      plistUtils.fileContents[randomLocation2PlistPath] = macStudioInfoPlist4_1;
      final String javaBin = fileSystem.path.join('jre', 'jdk', 'Contents', 'Home', 'bin', 'java');

      // Spotlight finds the one known and two random installations.
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: const <String>[
            'mdfind',
            'kMDItemCFBundleIdentifier="com.google.android.studio*"',
          ],
          stdout: '$randomLocation1\n$randomLocation2\n$studioInApplication',
        ),
        FakeCommand(
          command: <String>[
            fileSystem.path.join(randomLocation1, 'Contents', javaBin),
            '-version',
          ],
        ),
        FakeCommand(
          command: <String>[
            fileSystem.path.join(randomLocation2, 'Contents', javaBin),
            '-version',
          ],
        ),
        FakeCommand(
          command: <String>[
            fileSystem.path.join(studioInApplicationPlistFolder, javaBin),
            '-version',
          ],
        ),
      ]);

      // Results are de-duplicated, only 3 installed.
      expect(AndroidStudio.allInstalled().length, 3);
      expect(processManager, hasNoRemainingExpectations);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      FileSystemUtils: () => fsUtils,
      ProcessManager: () => processManager,
      // Custom home paths are not supported on macOS nor Windows yet,
      // so we force the platform to fake Linux here.
      Platform: () => platform,
      PlistParser: () => plistUtils,
    });

    testUsingContext('finds latest valid install', () {
      final String applicationPlistFolder = globals.fs.path.join(
        '/',
        'Applications',
        'Android Studio.app',
        'Contents',
      );
      globals.fs.directory(applicationPlistFolder).createSync(recursive: true);

      final String applicationsPlistFilePath = globals.fs.path.join(applicationPlistFolder, 'Info.plist');
      plistUtils.fileContents[applicationsPlistFilePath] = macStudioInfoPlist;

      final String homeDirectoryPlistFolder = globals.fs.path.join(
        globals.fsUtils.homeDirPath!,
        'Applications',
        'Android Studio.app',
        'Contents',
      );
      globals.fs.directory(homeDirectoryPlistFolder).createSync(recursive: true);

      final String homeDirectoryPlistFilePath = globals.fs.path.join(homeDirectoryPlistFolder, 'Info.plist');
      plistUtils.fileContents[homeDirectoryPlistFilePath] = macStudioInfoPlist4_1;

      expect(AndroidStudio.allInstalled().length, 2);
      expect(AndroidStudio.latestValid()!.version, Version(4, 1, 0));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      FileSystemUtils: () => fsUtils,
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => platform,
      PlistParser: () => plistUtils,
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
      plistUtils.fileContents[plistFilePath] = macStudioInfoPlist;
      final AndroidStudio studio = AndroidStudio.fromMacOSBundle(
        globals.fs.directory(studioInApplicationPlistFolder).parent.path,
      )!;
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

    testUsingContext('Can find Android Studio 2020.3 bundled Java version on Mac', () {
      final String studioInApplicationPlistFolder = globals.fs.path.join(
        '/',
        'Application',
        'Android Studio.app',
        'Contents',
      );
      globals.fs.directory(studioInApplicationPlistFolder).createSync(recursive: true);

      final String plistFilePath = globals.fs.path.join(studioInApplicationPlistFolder, 'Info.plist');
      plistUtils.fileContents[plistFilePath] = macStudioInfoPlist2020_3;
      processManager.addCommand(FakeCommand(
        command: <String>[
          globals.fs.path.join(studioInApplicationPlistFolder, 'jre', 'Contents', 'Home', 'bin', 'java'),
          '-version',
        ],
        stderr: '123',
      )
      );
      final AndroidStudio studio = AndroidStudio.fromMacOSBundle(
        globals.fs.directory(studioInApplicationPlistFolder).parent.path,
      )!;

      expect(studio.javaPath, equals(globals.fs.path.join(
        studioInApplicationPlistFolder,
        'jre',
        'Contents',
        'Home',
      )));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      FileSystemUtils: () => fsUtils,
      ProcessManager: () => processManager,
      // Custom home paths are not supported on macOS nor Windows yet,
      // so we force the platform to fake Linux here.
      Platform: () => platform,
      PlistParser: () => plistUtils,
    });

    testUsingContext('Can find Android Studio 2022.1 bundled Java version on Mac', () {
      final String studioInApplicationPlistFolder = globals.fs.path.join(
        '/',
        'Application',
        'Android Studio.app',
        'Contents',
      );
      globals.fs.directory(studioInApplicationPlistFolder).createSync(recursive: true);

      final String plistFilePath = globals.fs.path.join(studioInApplicationPlistFolder, 'Info.plist');
      plistUtils.fileContents[plistFilePath] = macStudioInfoPlist2022_1;
      processManager.addCommand(FakeCommand(
        command: <String>[
          globals.fs.path.join(studioInApplicationPlistFolder, 'jbr', 'Contents', 'Home', 'bin', 'java'),
          '-version',
        ],
        stderr: '123',
      )
      );
      final AndroidStudio studio = AndroidStudio.fromMacOSBundle(
        globals.fs.directory(studioInApplicationPlistFolder).parent.path,
      )!;

      expect(studio.javaPath, equals(globals.fs.path.join(
        studioInApplicationPlistFolder,
        'jbr',
        'Contents',
        'Home',
      )));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      FileSystemUtils: () => fsUtils,
      ProcessManager: () => processManager,
      // Custom home paths are not supported on macOS nor Windows yet,
      // so we force the platform to fake Linux here.
      Platform: () => platform,
      PlistParser: () => plistUtils,
    });
  });

  late FileSystem windowsFileSystem;

  setUp(() {
    windowsFileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
  });

  testUsingContext('Can discover Android Studio 4.1 location on Windows', () {
    windowsFileSystem.file(r'C:\Users\Dash\AppData\Local\Google\AndroidStudio4.1\.home')
      ..createSync(recursive: true)
      ..writeAsStringSync(r'C:\Program Files\AndroidStudio');
    windowsFileSystem.directory(r'C:\Program Files\AndroidStudio')
      .createSync(recursive: true);

    final AndroidStudio studio = AndroidStudio.allInstalled().single;

    expect(studio.version, Version(4, 1, 0));
    expect(studio.studioAppName, 'Android Studio');
  }, overrides: <Type, Generator>{
    Platform: () => windowsPlatform,
    FileSystem: () => windowsFileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Can discover Android Studio 4.2 location on Windows', () {
    windowsFileSystem.file(r'C:\Users\Dash\AppData\Local\Google\AndroidStudio4.2\.home')
      ..createSync(recursive: true)
      ..writeAsStringSync(r'C:\Program Files\AndroidStudio');
    windowsFileSystem.directory(r'C:\Program Files\AndroidStudio')
      .createSync(recursive: true);

    final AndroidStudio studio = AndroidStudio.allInstalled().single;

    expect(studio.version, Version(4, 2, 0));
    expect(studio.studioAppName, 'Android Studio');
  }, overrides: <Type, Generator>{
    Platform: () => windowsPlatform,
    FileSystem: () => windowsFileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Can discover Android Studio 2020.3 location on Windows', () {
    windowsFileSystem.file(r'C:\Users\Dash\AppData\Local\Google\AndroidStudio2020.3\.home')
      ..createSync(recursive: true)
      ..writeAsStringSync(r'C:\Program Files\AndroidStudio');
    windowsFileSystem.directory(r'C:\Program Files\AndroidStudio')
      .createSync(recursive: true);

    final AndroidStudio studio = AndroidStudio.allInstalled().single;

    expect(studio.version, Version(2020, 3, 0));
    expect(studio.studioAppName, 'Android Studio');
  }, overrides: <Type, Generator>{
    Platform: () => windowsPlatform,
    FileSystem: () => windowsFileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Does not discover Android Studio 4.1 location on Windows if LOCALAPPDATA is null', () {
    windowsFileSystem.file(r'C:\Users\Dash\AppData\Local\Google\AndroidStudio4.1\.home')
      ..createSync(recursive: true)
      ..writeAsStringSync(r'C:\Program Files\AndroidStudio');
    windowsFileSystem.directory(r'C:\Program Files\AndroidStudio')
      .createSync(recursive: true);

    expect(AndroidStudio.allInstalled(), isEmpty);
  }, overrides: <Type, Generator>{
    Platform: () => FakePlatform(
      operatingSystem: 'windows',
      environment: <String, String>{}, // Does not include LOCALAPPDATA
    ),
    FileSystem: () => windowsFileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Does not discover Android Studio 4.2 location on Windows if LOCALAPPDATA is null', () {
    windowsFileSystem.file(r'C:\Users\Dash\AppData\Local\Google\AndroidStudio4.2\.home')
      ..createSync(recursive: true)
      ..writeAsStringSync(r'C:\Program Files\AndroidStudio');
    windowsFileSystem.directory(r'C:\Program Files\AndroidStudio')
      .createSync(recursive: true);

    expect(AndroidStudio.allInstalled(), isEmpty);
  }, overrides: <Type, Generator>{
    Platform: () => FakePlatform(
      operatingSystem: 'windows',
      environment: <String, String>{}, // Does not include LOCALAPPDATA
    ),
    FileSystem: () => windowsFileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Does not discover Android Studio 2020.3 location on Windows if LOCALAPPDATA is null', () {
    windowsFileSystem.file(r'C:\Users\Dash\AppData\Local\Google\AndroidStudio2020.3\.home')
      ..createSync(recursive: true)
      ..writeAsStringSync(r'C:\Program Files\AndroidStudio');
    windowsFileSystem.directory(r'C:\Program Files\AndroidStudio')
      .createSync(recursive: true);

    expect(AndroidStudio.allInstalled(), isEmpty);
  }, overrides: <Type, Generator>{
    Platform: () => FakePlatform(
      operatingSystem: 'windows',
      environment: <String, String>{}, // Does not include LOCALAPPDATA
    ),
    FileSystem: () => windowsFileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Can find Android Studio 2020.3 bundled Java version on Windows', () {
    windowsFileSystem.file(r'C:\Users\Dash\AppData\Local\Google\AndroidStudio2020.3\.home')
      ..createSync(recursive: true)
      ..writeAsStringSync(r'C:\Program Files\AndroidStudio');
    windowsFileSystem.directory(r'C:\Program Files\AndroidStudio')
        .createSync(recursive: true);

    final AndroidStudio studio = AndroidStudio.allInstalled().single;

    expect(studio.javaPath, equals(r'C:\Program Files\AndroidStudio\jre'));
  }, overrides: <Type, Generator>{
    Platform: () => windowsPlatform,
    FileSystem: () => windowsFileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Can find Android Studio 2022.1 bundled Java version on Windows', () {
    windowsFileSystem.file(r'C:\Users\Dash\AppData\Local\Google\AndroidStudio2022.1\.home')
      ..createSync(recursive: true)
      ..writeAsStringSync(r'C:\Program Files\AndroidStudio');
    windowsFileSystem.directory(r'C:\Program Files\AndroidStudio')
        .createSync(recursive: true);

    final AndroidStudio studio = AndroidStudio.allInstalled().single;

    expect(studio.javaPath, equals(r'C:\Program Files\AndroidStudio\jbr'));
  }, overrides: <Type, Generator>{
    Platform: () => windowsPlatform,
    FileSystem: () => windowsFileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  group('Installation detection on Linux', () {
    late FileSystemUtils fsUtils;

    setUp(() {
      fsUtils = FileSystemUtils(
        fileSystem: fileSystem,
        platform: linuxPlatform,
      );
    });

    testUsingContext('Discover Android Studio <4.1', () {
      const String studioHomeFilePath =
          '$homeLinux/.AndroidStudio4.0/system/.home';
      const String studioInstallPath = '$homeLinux/AndroidStudio';

      globals.fs.file(studioHomeFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync(studioInstallPath);

      globals.fs.directory(studioInstallPath).createSync();

      final AndroidStudio studio = AndroidStudio.allInstalled().single;

      expect(studio.version, Version(4, 0, 0));
      expect(studio.studioAppName, 'AndroidStudio');
      expect(
        studio.pluginsPath,
        '/home/me/.AndroidStudio4.0/config/plugins',
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      FileSystemUtils: () => fsUtils,
      Platform: () => linuxPlatform,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('Discover Android Studio >=4.1', () {
      const String studioHomeFilePath =
          '$homeLinux/.cache/Google/AndroidStudio4.1/.home';
      const String studioInstallPath = '$homeLinux/AndroidStudio';

      globals.fs.file(studioHomeFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync(studioInstallPath);

      globals.fs.directory(studioInstallPath).createSync();

      final AndroidStudio studio = AndroidStudio.allInstalled().single;

      expect(studio.version, Version(4, 1, 0));
      expect(studio.studioAppName, 'AndroidStudio');
      expect(
        studio.pluginsPath,
        '/home/me/.local/share/Google/AndroidStudio4.1',
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      FileSystemUtils: () => fsUtils,
      Platform: () => linuxPlatform,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('Discover when installed with Toolbox', () {
      const String studioHomeFilePath =
          '$homeLinux/.cache/Google/AndroidStudio4.1/.home';
      const String studioInstallPath =
          '$homeLinux/.local/share/JetBrains/Toolbox/apps/AndroidStudio/ch-0/201.7042882';
      const String pluginsInstallPath = '$studioInstallPath.plugins';

      globals.fs.file(studioHomeFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync(studioInstallPath);

      globals.fs.directory(studioInstallPath).createSync(recursive: true);
      globals.fs.directory(pluginsInstallPath).createSync();

      final AndroidStudio studio = AndroidStudio.allInstalled().single;

      expect(studio.version, Version(4, 1, 0));
      expect(studio.studioAppName, 'AndroidStudio');
      expect(
        studio.pluginsPath,
        pluginsInstallPath,
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      FileSystemUtils: () => fsUtils,
      Platform: () => linuxPlatform,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('Can find Android Studio 2020.3 bundled Java version on Linux', () {
      const String studioHomeFilePath = '$homeLinux/.cache/Google/AndroidStudio2020.3/.home';
      const String studioInstallPath = '$homeLinux/AndroidStudio';

      globals.fs.file(studioHomeFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync(studioInstallPath);

      globals.fs.directory(studioInstallPath).createSync();

      final AndroidStudio studio = AndroidStudio.allInstalled().single;

      expect(studio.javaPath, equals('$studioInstallPath/jre'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      FileSystemUtils: () => fsUtils,
      Platform: () => linuxPlatform,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('Can find Android Studio 2022.1 bundled Java version on Linux', () {
      const String studioHomeFilePath =
          '$homeLinux/.cache/Google/AndroidStudio2022.1/.home';
      const String studioInstallPath = '$homeLinux/AndroidStudio';

      globals.fs.file(studioHomeFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync(studioInstallPath);

      globals.fs.directory(studioInstallPath).createSync();

      final AndroidStudio studio = AndroidStudio.allInstalled().single;

      expect(studio.javaPath, equals('$studioInstallPath/jbr'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      FileSystemUtils: () => fsUtils,
      Platform: () => linuxPlatform,
      ProcessManager: () => FakeProcessManager.any(),
    });
<<<<<<< HEAD
=======
  });

  group('latestValid', () {
    late Platform platform;
    late FileSystem fileSystem;

    setUp(() {
      platform = FakePlatform(
        operatingSystem: 'windows',
        environment: <String, String>{
          'LOCALAPPDATA': r'C:\Users\Dash\AppData\Local',
        }
      );
      fileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
    });

    testUsingContext('choses the install with the latest version', () {
      const List<String> versions = <String> [
        '4.0',
        '2022.0',
        '3.1',
      ];

      for (final String version in versions) {
        fileSystem.file('C:\\Users\\Dash\\AppData\\Local\\Google\\AndroidStudio$version\\.home')
          ..createSync(recursive: true)
          ..writeAsStringSync('C:\\Program Files\\AndroidStudio$version');
        fileSystem.directory('C:\\Program Files\\AndroidStudio$version')
          .createSync(recursive: true);
      }

      expect(AndroidStudio.allInstalled().length, 3);
      expect(AndroidStudio.latestValid()!.version, Version(2022, 0, 0));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      Platform: () => platform,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('prefers installs with known versions over installs with unknown versions', () {
      const List<String> versions = <String> [
        '3.0',
        'unknown',
      ];

      for (final String version in versions) {
        fileSystem.file('C:\\Users\\Dash\\AppData\\Local\\Google\\AndroidStudio$version\\.home')
          ..createSync(recursive: true)
          ..writeAsStringSync('C:\\Program Files\\AndroidStudio$version');
        fileSystem.directory('C:\\Program Files\\AndroidStudio$version')
          .createSync(recursive: true);
      }

      expect(AndroidStudio.allInstalled().length, 2);
      expect(AndroidStudio.latestValid()!.version, Version(3, 0, 0));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      Platform: () => platform,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('choses install with lexicographically greatest directory if no installs have known versions', () {
      const List<String> versions = <String> [
        'Apple',
        'Zucchini',
        'Banana',
      ];

      for (final String version in versions) {
        fileSystem.file('C:\\Users\\Dash\\AppData\\Local\\Google\\AndroidStudio$version\\.home')
          ..createSync(recursive: true)
          ..writeAsStringSync('C:\\Program Files\\AndroidStudio$version');
        fileSystem.directory('C:\\Program Files\\AndroidStudio$version')
          .createSync(recursive: true);
      }

      expect(AndroidStudio.allInstalled().length, 3);
      expect(AndroidStudio.latestValid()!.directory, r'C:\Program Files\AndroidStudioZucchini');
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      Platform: () => platform,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('choses install with lexicographically greatest directory if all installs have the same version', () {
      fileSystem.file(r'C:\Users\Dash\AppData\Local\Google\AndroidStudioPreview4.0\.home')
        ..createSync(recursive: true)
        ..writeAsStringSync(r'C:\Program Files\AndroidStudioPreview4.0');
      fileSystem.directory(r'C:\Program Files\AndroidStudioPreview4.0')
        .createSync(recursive: true);

      fileSystem.file(r'C:\Users\Dash\AppData\Local\Google\AndroidStudio4.0\.home')
        ..createSync(recursive: true)
        ..writeAsStringSync(r'C:\Program Files\AndroidStudio4.0');
      fileSystem.directory(r'C:\Program Files\AndroidStudio4.0')
        .createSync(recursive: true);

      expect(AndroidStudio.allInstalled().length, 2);
      expect(AndroidStudio.latestValid()!.directory, contains('Preview'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      Platform: () => platform,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('always chooses the install configured by --android-studio-dir, even if the install is invalid', () {
      const String configuredAndroidStudioDir = r'C:\Users\Dash\Desktop\android-studio';
      globals.config.setValue('android-studio-dir', configuredAndroidStudioDir);

      // The directory exists, but nothing is inside.
      fileSystem.directory(configuredAndroidStudioDir).createSync(recursive: true);
      (globals.processManager as FakeProcessManager).excludedExecutables.add(
        fileSystem.path.join(configuredAndroidStudioDir, 'jre', 'bin', 'java'),
      );

      const List<String> validVersions = <String> [
        '4.0',
        '2.0',
        '3.1',
      ];

      for (final String version in validVersions) {
        fileSystem.file('C:\\Users\\Dash\\AppData\\Local\\Google\\AndroidStudio$version\\.home')
          ..createSync(recursive: true)
          ..writeAsStringSync('C:\\Program Files\\AndroidStudio$version');
        fileSystem.directory('C:\\Program Files\\AndroidStudio$version')
          .createSync(recursive: true);
      }

      const List<String> validJavaPaths = <String>[
        r'C:\Program Files\AndroidStudio4.0\jre\bin\java',
        r'C:\Program Files\AndroidStudio2.0\jre\bin\java',
        r'C:\Program Files\AndroidStudio3.1\jre\bin\java',
      ];

      for (final String javaPath in validJavaPaths) {
        (globals.processManager as FakeProcessManager).addCommand(FakeCommand(
          command: <String>[
            globals.fs.path.join(javaPath),
            '-version',
          ],
        ));
      }

      expect(AndroidStudio.allInstalled().length, 4);
      final AndroidStudio chosenInstall = AndroidStudio.latestValid()!;
      expect(chosenInstall.directory, configuredAndroidStudioDir);
      expect(chosenInstall.isValid, false);
    }, overrides: <Type, Generator>{
      Config: () => Config.test(),
      FileSystem: () => fileSystem,
      Platform: () => platform,
      ProcessManager: () => FakeProcessManager.empty(),
    });

    testUsingContext('throws a ToolExit if --android-studio-dir is configured but the directory does not exist', () async {
      const String configuredAndroidStudioDir = r'C:\Users\Dash\Desktop\android-studio';
      globals.config.setValue('android-studio-dir', configuredAndroidStudioDir);

      expect(fileSystem.directory(configuredAndroidStudioDir).existsSync(), false);
      expect(() => AndroidStudio.latestValid(), throwsA(
        (dynamic e) => e is ToolExit &&
          e.message!.startsWith('Could not find the Android Studio installation at the manually configured path')
        )
      );
    }, overrides: <Type, Generator>{
      Config: () => Config.test(),
      FileSystem: () => fileSystem,
      Platform: () => platform,
      ProcessManager: () => FakeProcessManager.any(),
    });
>>>>>>> d3d8effc686d73e0114d71abdcccef63fa1f25d2
  });
}

class FakePlistUtils extends Fake implements PlistParser {
  final Map<String, Map<String, Object>> fileContents = <String, Map<String, Object>>{};

  @override
  Map<String, Object> parseFile(String plistFilePath) {
    return fileContents[plistFilePath]!;
  }
}
