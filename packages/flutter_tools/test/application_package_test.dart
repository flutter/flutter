// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/ios/ios_workflow.dart';

import 'src/common.dart';
import 'src/context.dart';

final Generator _kNoColorTerminalPlatform = () => FakePlatform.fromPlatform(const LocalPlatform())..stdoutSupportsAnsi = false;
final Map<Type, Generator> noColorTerminalOverride = <Type, Generator>{
  Platform: _kNoColorTerminalPlatform,
};

void main() {
  group('ApkManifestData', () {
    test('Select explicity enabled activity', () {
      final ApkManifestData data = ApkManifestData.parseFromXmlDump(_aaptDataWithExplicitEnabledActivity);
      expect(data, isNotNull);
      expect(data.packageName, 'io.flutter.examples.hello_world');
      expect(data.launchableActivityName, 'io.flutter.examples.hello_world.MainActivity2');
    });
    test('Select default enabled activity', () {
      final ApkManifestData data = ApkManifestData.parseFromXmlDump(_aaptDataWithDefaultEnabledActivity);
      expect(data, isNotNull);
      expect(data.packageName, 'io.flutter.examples.hello_world');
      expect(data.launchableActivityName, 'io.flutter.examples.hello_world.MainActivity2');
    });
    testUsingContext('Error on no enabled activity', () {
      final ApkManifestData data = ApkManifestData.parseFromXmlDump(_aaptDataWithNoEnabledActivity);
      expect(data, isNull);
      final BufferLogger logger = context[Logger];
      expect(
          logger.errorText, 'Error running io.flutter.examples.hello_world. Default activity not found\n');
    }, overrides: noColorTerminalOverride);
  });

  group('PrebuiltIOSApp', () {
    final Map<Type, Generator> overrides = <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
      IOSWorkflow: () => MockIosWorkFlow(),
      Platform: _kNoColorTerminalPlatform,
    };
    testUsingContext('Error on non-existing file', () {
      final PrebuiltIOSApp iosApp =
          IOSApp.fromPrebuiltApp(fs.file('not_existing.ipa'));
      expect(iosApp, isNull);
      final BufferLogger logger = context[Logger];
      expect(
        logger.errorText,
        'File "not_existing.ipa" does not exist. Use an app bundle or an ipa.\n',
      );
    }, overrides: overrides);
    testUsingContext('Error on non-app-bundle folder', () {
      fs.directory('regular_folder').createSync();
      final PrebuiltIOSApp iosApp =
          IOSApp.fromPrebuiltApp(fs.file('regular_folder'));
      expect(iosApp, isNull);
      final BufferLogger logger = context[Logger];
      expect(
          logger.errorText, 'Folder "regular_folder" is not an app bundle.\n');
    }, overrides: overrides);
    testUsingContext('Error on no info.plist', () {
      fs.directory('bundle.app').createSync();
      final PrebuiltIOSApp iosApp = IOSApp.fromPrebuiltApp(fs.file('bundle.app'));
      expect(iosApp, isNull);
      final BufferLogger logger = context[Logger];
      expect(
        logger.errorText,
        'Invalid prebuilt iOS app. Does not contain Info.plist.\n',
      );
    }, overrides: overrides);
    testUsingContext('Error on bad info.plist', () {
      fs.directory('bundle.app').createSync();
      fs.file('bundle.app/Info.plist').writeAsStringSync(badPlistData);
      final PrebuiltIOSApp iosApp = IOSApp.fromPrebuiltApp(fs.file('bundle.app'));
      expect(iosApp, isNull);
      final BufferLogger logger = context[Logger];
      expect(
        logger.errorText,
        contains(
            'Invalid prebuilt iOS app. Info.plist does not contain bundle identifier\n'),
      );
    }, overrides: overrides);
    testUsingContext('Success with app bundle', () {
      fs.directory('bundle.app').createSync();
      fs.file('bundle.app/Info.plist').writeAsStringSync(plistData);
      final PrebuiltIOSApp iosApp = IOSApp.fromPrebuiltApp(fs.file('bundle.app'));
      final BufferLogger logger = context[Logger];
      expect(logger.errorText, isEmpty);
      expect(iosApp.bundleDir.path, 'bundle.app');
      expect(iosApp.id, 'fooBundleId');
      expect(iosApp.bundleName, 'bundle.app');
    }, overrides: overrides);
    testUsingContext('Bad ipa zip-file, no payload dir', () {
      fs.file('app.ipa').createSync();
      when(os.unzip(fs.file('app.ipa'), any)).thenAnswer((Invocation _) {});
      final PrebuiltIOSApp iosApp = IOSApp.fromPrebuiltApp(fs.file('app.ipa'));
      expect(iosApp, isNull);
      final BufferLogger logger = context[Logger];
      expect(
        logger.errorText,
        'Invalid prebuilt iOS ipa. Does not contain a "Payload" directory.\n',
      );
    }, overrides: overrides);
    testUsingContext('Bad ipa zip-file, two app bundles', () {
      fs.file('app.ipa').createSync();
      when(os.unzip(any, any)).thenAnswer((Invocation invocation) {
        final File zipFile = invocation.positionalArguments[0];
        if (zipFile.path != 'app.ipa') {
          return null;
        }
        final Directory targetDirectory = invocation.positionalArguments[1];
        final String bundlePath1 =
            fs.path.join(targetDirectory.path, 'Payload', 'bundle1.app');
        final String bundlePath2 =
            fs.path.join(targetDirectory.path, 'Payload', 'bundle2.app');
        fs.directory(bundlePath1).createSync(recursive: true);
        fs.directory(bundlePath2).createSync(recursive: true);
      });
      final PrebuiltIOSApp iosApp = IOSApp.fromPrebuiltApp(fs.file('app.ipa'));
      expect(iosApp, isNull);
      final BufferLogger logger = context[Logger];
      expect(logger.errorText,
          'Invalid prebuilt iOS ipa. Does not contain a single app bundle.\n');
    }, overrides: overrides);
    testUsingContext('Success with ipa', () {
      fs.file('app.ipa').createSync();
      when(os.unzip(any, any)).thenAnswer((Invocation invocation) {
        final File zipFile = invocation.positionalArguments[0];
        if (zipFile.path != 'app.ipa') {
          return null;
        }
        final Directory targetDirectory = invocation.positionalArguments[1];
        final Directory bundleAppDir = fs.directory(
            fs.path.join(targetDirectory.path, 'Payload', 'bundle.app'));
        bundleAppDir.createSync(recursive: true);
        fs
            .file(fs.path.join(bundleAppDir.path, 'Info.plist'))
            .writeAsStringSync(plistData);
      });
      final PrebuiltIOSApp iosApp = IOSApp.fromPrebuiltApp(fs.file('app.ipa'));
      final BufferLogger logger = context[Logger];
      expect(logger.errorText, isEmpty);
      expect(iosApp.bundleDir.path, endsWith('bundle.app'));
      expect(iosApp.id, 'fooBundleId');
      expect(iosApp.bundleName, 'bundle.app');
    }, overrides: overrides);
  });
}

const String _aaptDataWithExplicitEnabledActivity =
'''N: android=http://schemas.android.com/apk/res/android
  E: manifest (line=7)
    A: android:versionCode(0x0101021b)=(type 0x10)0x1
    A: android:versionName(0x0101021c)="0.0.1" (Raw: "0.0.1")
    A: package="io.flutter.examples.hello_world" (Raw: "io.flutter.examples.hello_world")
    E: uses-sdk (line=12)
      A: android:minSdkVersion(0x0101020c)=(type 0x10)0x10
      A: android:targetSdkVersion(0x01010270)=(type 0x10)0x1b
    E: uses-permission (line=21)
      A: android:name(0x01010003)="android.permission.INTERNET" (Raw: "android.permission.INTERNET")
    E: application (line=29)
      A: android:label(0x01010001)="hello_world" (Raw: "hello_world")
      A: android:icon(0x01010002)=@0x7f010000
      A: android:name(0x01010003)="io.flutter.app.FlutterApplication" (Raw: "io.flutter.app.FlutterApplication")
      A: android:debuggable(0x0101000f)=(type 0x12)0xffffffff
      E: activity (line=34)
        A: android:theme(0x01010000)=@0x1030009
        A: android:name(0x01010003)="io.flutter.examples.hello_world.MainActivity" (Raw: "io.flutter.examples.hello_world.MainActivity")
        A: android:enabled(0x0101000e)=(type 0x12)0x0
        A: android:launchMode(0x0101001d)=(type 0x10)0x1
        A: android:configChanges(0x0101001f)=(type 0x11)0x400035b4
        A: android:windowSoftInputMode(0x0101022b)=(type 0x11)0x10
        A: android:hardwareAccelerated(0x010102d3)=(type 0x12)0xffffffff
        E: intent-filter (line=42)
          E: action (line=43)
            A: android:name(0x01010003)="android.intent.action.MAIN" (Raw: "android.intent.action.MAIN")
          E: category (line=45)
            A: android:name(0x01010003)="android.intent.category.LAUNCHER" (Raw: "android.intent.category.LAUNCHER")
      E: activity (line=48)
        A: android:theme(0x01010000)=@0x1030009
        A: android:label(0x01010001)="app2" (Raw: "app2")
        A: android:name(0x01010003)="io.flutter.examples.hello_world.MainActivity2" (Raw: "io.flutter.examples.hello_world.MainActivity2")
        A: android:enabled(0x0101000e)=(type 0x12)0xffffffff
        E: intent-filter (line=53)
          E: action (line=54)
            A: android:name(0x01010003)="android.intent.action.MAIN" (Raw: "android.intent.action.MAIN")
          E: category (line=56)
            A: android:name(0x01010003)="android.intent.category.LAUNCHER" (Raw: "android.intent.category.LAUNCHER")''';


const String _aaptDataWithDefaultEnabledActivity =
'''N: android=http://schemas.android.com/apk/res/android
  E: manifest (line=7)
    A: android:versionCode(0x0101021b)=(type 0x10)0x1
    A: android:versionName(0x0101021c)="0.0.1" (Raw: "0.0.1")
    A: package="io.flutter.examples.hello_world" (Raw: "io.flutter.examples.hello_world")
    E: uses-sdk (line=12)
      A: android:minSdkVersion(0x0101020c)=(type 0x10)0x10
      A: android:targetSdkVersion(0x01010270)=(type 0x10)0x1b
    E: uses-permission (line=21)
      A: android:name(0x01010003)="android.permission.INTERNET" (Raw: "android.permission.INTERNET")
    E: application (line=29)
      A: android:label(0x01010001)="hello_world" (Raw: "hello_world")
      A: android:icon(0x01010002)=@0x7f010000
      A: android:name(0x01010003)="io.flutter.app.FlutterApplication" (Raw: "io.flutter.app.FlutterApplication")
      A: android:debuggable(0x0101000f)=(type 0x12)0xffffffff
      E: activity (line=34)
        A: android:theme(0x01010000)=@0x1030009
        A: android:name(0x01010003)="io.flutter.examples.hello_world.MainActivity" (Raw: "io.flutter.examples.hello_world.MainActivity")
        A: android:enabled(0x0101000e)=(type 0x12)0x0
        A: android:launchMode(0x0101001d)=(type 0x10)0x1
        A: android:configChanges(0x0101001f)=(type 0x11)0x400035b4
        A: android:windowSoftInputMode(0x0101022b)=(type 0x11)0x10
        A: android:hardwareAccelerated(0x010102d3)=(type 0x12)0xffffffff
        E: intent-filter (line=42)
          E: action (line=43)
            A: android:name(0x01010003)="android.intent.action.MAIN" (Raw: "android.intent.action.MAIN")
          E: category (line=45)
            A: android:name(0x01010003)="android.intent.category.LAUNCHER" (Raw: "android.intent.category.LAUNCHER")
      E: activity (line=48)
        A: android:theme(0x01010000)=@0x1030009
        A: android:label(0x01010001)="app2" (Raw: "app2")
        A: android:name(0x01010003)="io.flutter.examples.hello_world.MainActivity2" (Raw: "io.flutter.examples.hello_world.MainActivity2")
        E: intent-filter (line=53)
          E: action (line=54)
            A: android:name(0x01010003)="android.intent.action.MAIN" (Raw: "android.intent.action.MAIN")
          E: category (line=56)
            A: android:name(0x01010003)="android.intent.category.LAUNCHER" (Raw: "android.intent.category.LAUNCHER")''';


const String _aaptDataWithNoEnabledActivity =
'''N: android=http://schemas.android.com/apk/res/android
  E: manifest (line=7)
    A: android:versionCode(0x0101021b)=(type 0x10)0x1
    A: android:versionName(0x0101021c)="0.0.1" (Raw: "0.0.1")
    A: package="io.flutter.examples.hello_world" (Raw: "io.flutter.examples.hello_world")
    E: uses-sdk (line=12)
      A: android:minSdkVersion(0x0101020c)=(type 0x10)0x10
      A: android:targetSdkVersion(0x01010270)=(type 0x10)0x1b
    E: uses-permission (line=21)
      A: android:name(0x01010003)="android.permission.INTERNET" (Raw: "android.permission.INTERNET")
    E: application (line=29)
      A: android:label(0x01010001)="hello_world" (Raw: "hello_world")
      A: android:icon(0x01010002)=@0x7f010000
      A: android:name(0x01010003)="io.flutter.app.FlutterApplication" (Raw: "io.flutter.app.FlutterApplication")
      A: android:debuggable(0x0101000f)=(type 0x12)0xffffffff
      E: activity (line=34)
        A: android:theme(0x01010000)=@0x1030009
        A: android:name(0x01010003)="io.flutter.examples.hello_world.MainActivity" (Raw: "io.flutter.examples.hello_world.MainActivity")
        A: android:enabled(0x0101000e)=(type 0x12)0x0
        A: android:launchMode(0x0101001d)=(type 0x10)0x1
        A: android:configChanges(0x0101001f)=(type 0x11)0x400035b4
        A: android:windowSoftInputMode(0x0101022b)=(type 0x11)0x10
        A: android:hardwareAccelerated(0x010102d3)=(type 0x12)0xffffffff
        E: intent-filter (line=42)
          E: action (line=43)
            A: android:name(0x01010003)="android.intent.action.MAIN" (Raw: "android.intent.action.MAIN")
          E: category (line=45)
            A: android:name(0x01010003)="android.intent.category.LAUNCHER" (Raw: "android.intent.category.LAUNCHER")''';


class MockIosWorkFlow extends Mock implements IOSWorkflow {
  @override
  String getPlistValueFromFile(String path, String key) {
    final File file = fs.file(path);
    if (!file.existsSync()) {
      return null;
    }
    return json.decode(file.readAsStringSync())[key];
  }
}

// Contains no bundle identifier.
const String badPlistData = '''
{}
''';

const String plistData = '''
{"CFBundleIdentifier": "fooBundleId"}
''';
