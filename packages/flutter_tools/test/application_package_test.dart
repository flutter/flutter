// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/application_package.dart';
import 'package:test/test.dart';

import 'src/context.dart';

void main() {
  group('ApkManifestData', () {
    testUsingContext('parse sdk', () {
      final ApkManifestData data = ApkManifestData.parseFromAaptBadging(_aaptData);
      expect(data, isNotNull);
      expect(data.packageName, 'io.flutter.gallery');
      expect(data.launchableActivityName, 'io.flutter.app.FlutterActivity');
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
