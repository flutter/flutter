// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/ios/ios_workflow.dart';
import 'package:test/test.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mockito/mockito.dart';
import 'src/context.dart';

void main() {
  group('ApkManifestData', () {
    testUsingContext('parse sdk', () {
      final ApkManifestData data = ApkManifestData.parseFromAaptBadging(_aaptData);
      expect(data, isNotNull);
      expect(data.packageName, 'io.flutter.gallery');
      expect(data.launchableActivityName, 'io.flutter.app.FlutterActivity');
      expect(data.data['application']['label'], 'Flutter Gallery');
    });
  });

  group('BuildableIOSApp', () {
    testUsingContext('check isSwift', () {
      final BuildableIOSApp buildableIOSApp = new BuildableIOSApp(
        projectBundleId: 'blah',
        appDirectory: 'not/important',
        buildSettings: _swiftBuildSettings,
      );
      expect(buildableIOSApp.isSwift, true);
    });
  });

  group('PrebuiltIOSApp', () {
    final Map<Type, Generator> overrides = <Type, Generator>{
      FileSystem: () => new MemoryFileSystem(),
      IOSWorkflow: () => new MockIosWorkFlow()
    };
    testUsingContext('Error on non-existing file', () {
      final PrebuiltIOSApp iosApp =
          new IOSApp.fromPrebuiltApp('not_existing.ipa');
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
          new IOSApp.fromPrebuiltApp('regular_folder');
      expect(iosApp, isNull);
      final BufferLogger logger = context[Logger];
      expect(
          logger.errorText, 'Folder "regular_folder" is not an app bundle.\n');
    }, overrides: overrides);

    testUsingContext('Error on no info.plist', () {
      fs.directory('bundle.app').createSync();
      final PrebuiltIOSApp iosApp = new IOSApp.fromPrebuiltApp('bundle.app');
      expect(iosApp, isNull);
      final BufferLogger logger = context[Logger];
      expect(
        logger.errorText,
        'Invalid prebuilt iOS app. Info.plist does not contain bundle identifier\n',
      );
    }, overrides: overrides);
    testUsingContext('Error on bad info.plist', () {
      fs.directory('bundle.app').createSync();
      fs.file('bundle.app/Info.plist').writeAsStringSync(badPlistData);
      final PrebuiltIOSApp iosApp = new IOSApp.fromPrebuiltApp('bundle.app');
      expect(iosApp, isNull);
      final BufferLogger logger = context[Logger];
      expect(
        logger.errorText,
        contains('Invalid prebuilt iOS app. Info.plist does not contain bundle identifier\n'),
      );
    }, overrides: overrides);
    testUsingContext('Success with app bundle', () {
      fs.directory('bundle.app').createSync();
      fs.file('bundle.app/Info.plist').writeAsStringSync(plistData);
      final PrebuiltIOSApp iosApp = new IOSApp.fromPrebuiltApp('bundle.app');
      final BufferLogger logger = context[Logger];
      expect(logger.errorText, isEmpty);
      expect(iosApp.bundleDir.path, 'bundle.app');
      expect(iosApp.id, 'fooBundleId');
      expect(iosApp.bundleName, 'bundle.app');
    }, overrides: overrides);
    testUsingContext('Bad ipa zip-file, no payload dir', () {
      fs.file('app.ipa').createSync();
      when(os.unzip(fs.file('app.ipa'), any)).thenAnswer((Invocation _) {});
      final PrebuiltIOSApp iosApp = new IOSApp.fromPrebuiltApp('app.ipa');
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
      final PrebuiltIOSApp iosApp = new IOSApp.fromPrebuiltApp('app.ipa');
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
      final PrebuiltIOSApp iosApp = new IOSApp.fromPrebuiltApp('app.ipa');
      final BufferLogger logger = context[Logger];
      expect(logger.errorText, isEmpty);
      expect(iosApp.bundleDir.path, endsWith('bundle.app'));
      expect(iosApp.id, 'fooBundleId');
      expect(iosApp.bundleName, 'bundle.app');
    }, overrides: overrides);
  });
}

const String _aaptData = '''
package: name='io.flutter.gallery' versionCode='1' versionName='0.0.1' platformBuildVersionName='NMR1'
sdkVersion:'14'
targetSdkVersion:'21'
uses-permission: name='android.permission.INTERNET'
application-label:'Flutter Gallery'
application-icon-160:'res/mipmap-mdpi-v4/ic_launcher.png'
application-icon-240:'res/mipmap-hdpi-v4/ic_launcher.png'
application-icon-320:'res/mipmap-xhdpi-v4/ic_launcher.png'
application-icon-480:'res/mipmap-xxhdpi-v4/ic_launcher.png'
application-icon-640:'res/mipmap-xxxhdpi-v4/ic_launcher.png'
application: label='Flutter Gallery' icon='res/mipmap-mdpi-v4/ic_launcher.png'
application-debuggable
launchable-activity: name='io.flutter.app.FlutterActivity'  label='' icon=''
feature-group: label=''
  uses-feature: name='android.hardware.screen.portrait'
  uses-implied-feature: name='android.hardware.screen.portrait' reason='one or more activities have specified a portrait orientation'
  uses-feature: name='android.hardware.touchscreen'
  uses-implied-feature: name='android.hardware.touchscreen' reason='default feature for all apps'
main
supports-screens: 'small' 'normal' 'large' 'xlarge'
supports-any-density: 'true'
locales: '--_--'
densities: '160' '240' '320' '480' '640'
native-code: 'armeabi-v7a'
''';

final Map<String, String> _swiftBuildSettings = <String, String>{
  'ARCHS': 'arm64',
  'ASSETCATALOG_COMPILER_APPICON_NAME': 'AppIcon',
  'CLANG_ENABLE_MODULES': 'YES',
  'ENABLE_BITCODE': 'NO',
  'INFOPLIST_FILE': 'Runner/Info.plist',
  'PRODUCT_BUNDLE_IDENTIFIER': 'com.example.test',
  'PRODUCT_NAME': 'blah',
  'SWIFT_OBJC_BRIDGING_HEADER': 'Runner/Runner-Bridging-Header.h',
  'SWIFT_OPTIMIZATION_LEVEL': '-Onone',
  'SWIFT_VERSION': '3.0',
};

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
