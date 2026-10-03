// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/ios/migrations/status_bar_appearance_migration.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';

void main() {
  late File infoPlist;
  late BufferLogger logger;
  late FakeXcode xcode;

  setUp(() {
    infoPlist = MemoryFileSystem.test().file('Info.plist');
    logger = BufferLogger.test();
    xcode = FakeXcode();
  });

  StatusBarAppearanceMigration migration({
    EnvironmentType environmentType = EnvironmentType.physical,
  }) => StatusBarAppearanceMigration(
    infoPlist,
    logger,
    xcode: xcode,
    environmentType: environmentType,
  );

  testWithoutContext('skips missing Info.plist without querying the SDK', () async {
    await migration().migrate();

    expect(infoPlist.existsSync(), isFalse);
    expect(xcode.queriedEnvironments, isEmpty);
    expect(logger.statusText, isEmpty);
  });

  for (final MapEntry<String, String> entry in <String, String>{
    'missing key': '',
    'true value': '<key>UIViewControllerBasedStatusBarAppearance</key><true/>',
    'string value': '<key>UIViewControllerBasedStatusBarAppearance</key><string>false</string>',
    'commented-out key': '<!-- <key>UIViewControllerBasedStatusBarAppearance</key><false/> -->',
    'nested key':
        '<key>Nested</key><dict>'
        '<key>UIViewControllerBasedStatusBarAppearance</key><false/>'
        '</dict>',
    'duplicate keys':
        '<key>UIViewControllerBasedStatusBarAppearance</key><false/>'
        '<key>UIViewControllerBasedStatusBarAppearance</key><true/>',
  }.entries) {
    testWithoutContext('leaves ${entry.key} unchanged without querying the SDK', () async {
      final contents = '<plist version="1.0"><dict>${entry.value}</dict></plist>';
      infoPlist.writeAsStringSync(contents);

      await migration().migrate();

      expect(infoPlist.readAsStringSync(), contents);
      expect(xcode.queriedEnvironments, isEmpty);
      expect(logger.statusText, isEmpty);
    });
  }

  testWithoutContext('skips malformed XML without querying the SDK', () async {
    const contents =
        '<plist><dict>'
        '<key>UIViewControllerBasedStatusBarAppearance</key><false/>';
    infoPlist.writeAsStringSync(contents);

    await migration().migrate();

    expect(infoPlist.readAsStringSync(), contents);
    expect(xcode.queriedEnvironments, isEmpty);
    expect(logger.traceText, contains('Unable to parse Info.plist'));
    expect(logger.statusText, isEmpty);
  });

  testWithoutContext('skips non-UTF8 Info.plist without querying the SDK', () async {
    const contents = <int>[0xff, 0xfe, 0x3c, 0x00];
    infoPlist.writeAsBytesSync(contents);

    await migration().migrate();

    expect(infoPlist.readAsBytesSync(), contents);
    expect(xcode.queriedEnvironments, isEmpty);
    expect(logger.traceText, contains('Unable to read Info.plist'));
    expect(logger.statusText, isEmpty);
  });

  for (final sdkVersion in <Version?>[null, Version(26, 5, 0)]) {
    testWithoutContext('does not migrate with SDK version $sdkVersion', () async {
      const contents =
          '<plist><dict>'
          '<key>UIViewControllerBasedStatusBarAppearance</key><false/>'
          '</dict></plist>';
      infoPlist.writeAsStringSync(contents);
      xcode.sdkVersion = sdkVersion;

      await migration().migrate();

      expect(infoPlist.readAsStringSync(), contents);
      expect(xcode.queriedEnvironments, <EnvironmentType>[EnvironmentType.physical]);
      expect(logger.statusText, isEmpty);
    });
  }

  for (final EnvironmentType environmentType in EnvironmentType.values) {
    testWithoutContext('queries the $environmentType SDK before migrating', () async {
      const contents =
          '<plist><dict>'
          '<key>UIViewControllerBasedStatusBarAppearance</key><false/>'
          '</dict></plist>';
      infoPlist.writeAsStringSync(contents);

      await migration(environmentType: environmentType).migrate();

      expect(infoPlist.readAsStringSync(), contents.replaceFirst('<false/>', '<true/>'));
      expect(xcode.queriedEnvironments, <EnvironmentType>[environmentType]);
      expect(logger.statusText, contains('view controller-based status bar appearance'));
    });
  }

  testWithoutContext(
    'only replaces the top-level boolean and preserves the UIStatusBarHidden setting',
    () async {
      const contents = '''
<?xml version='1.0' encoding='UTF-8'?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version='1.0'>
<dict>
  <!-- <key>UIViewControllerBasedStatusBarAppearance</key><false/> -->
  <key>Nested</key><dict>
    <key>UIViewControllerBasedStatusBarAppearance</key><false/>
  </dict>
  <key>UIStatusBarHidden</key>
  <true/>
  <key>UIViewControllerBasedStatusBarAppearance</key>
  <!-- Keep this comment. -->
  <false />
  <key>Unrelated</key><string>A &amp; B</string>
</dict>
</plist>''';
      infoPlist.writeAsStringSync(contents);
      xcode.sdkVersion = Version(27, 1, 0);

      await migration().migrate();

      expect(infoPlist.readAsStringSync(), contents.replaceFirst('<false />', '<true/>'));
    },
  );

  testWithoutContext('migrates a boolean with an explicit closing tag', () async {
    const contents =
        '<plist><dict>'
        '<key>UIViewControllerBasedStatusBarAppearance</key><false></false>'
        '</dict></plist>';
    infoPlist.writeAsStringSync(contents);

    await migration().migrate();

    expect(infoPlist.readAsStringSync(), contents.replaceFirst('<false></false>', '<true/>'));
  });

  testWithoutContext('does not migrate or query the SDK again after updating the plist', () async {
    infoPlist.writeAsStringSync(
      '<plist><dict>'
      '<key>UIViewControllerBasedStatusBarAppearance</key><false/>'
      '</dict></plist>',
    );
    final StatusBarAppearanceMigration migrator = migration();
    await migrator.migrate();
    final String contents = infoPlist.readAsStringSync();
    logger.clear();

    await migrator.migrate();

    expect(infoPlist.readAsStringSync(), contents);
    expect(xcode.queriedEnvironments, <EnvironmentType>[EnvironmentType.physical]);
    expect(logger.statusText, isEmpty);
  });
}

class FakeXcode extends Fake implements Xcode {
  Version? sdkVersion = Version(27, 0, 0);
  final queriedEnvironments = <EnvironmentType>[];

  @override
  Future<Version?> sdkPlatformVersion(EnvironmentType environmentType) async {
    queriedEnvironments.add(environmentType);
    return sdkVersion;
  }
}
