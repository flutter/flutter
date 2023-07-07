// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_linux/url_launcher_linux.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$UrlLauncherLinux', () {
    const MethodChannel channel =
        MethodChannel('plugins.flutter.io/url_launcher_linux');
    final List<MethodCall> log = <MethodCall>[];
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);

      // Return null explicitly instead of relying on the implicit null
      // returned by the method channel if no return statement is specified.
      return null;
    });

    tearDown(() {
      log.clear();
    });

    test('registers instance', () {
      UrlLauncherLinux.registerWith();
      expect(UrlLauncherPlatform.instance, isA<UrlLauncherLinux>());
    });

    test('canLaunch', () async {
      final UrlLauncherLinux launcher = UrlLauncherLinux();
      await launcher.canLaunch('http://example.com/');
      expect(
        log,
        <Matcher>[
          isMethodCall('canLaunch', arguments: <String, Object>{
            'url': 'http://example.com/',
          })
        ],
      );
    });

    test('canLaunch should return false if platform returns null', () async {
      final UrlLauncherLinux launcher = UrlLauncherLinux();
      final bool canLaunch = await launcher.canLaunch('http://example.com/');

      expect(canLaunch, false);
    });

    test('launch', () async {
      final UrlLauncherLinux launcher = UrlLauncherLinux();
      await launcher.launch(
        'http://example.com/',
        useSafariVC: true,
        useWebView: false,
        enableJavaScript: false,
        enableDomStorage: false,
        universalLinksOnly: false,
        headers: const <String, String>{},
      );
      expect(
        log,
        <Matcher>[
          isMethodCall('launch', arguments: <String, Object>{
            'url': 'http://example.com/',
            'enableJavaScript': false,
            'enableDomStorage': false,
            'universalLinksOnly': false,
            'headers': <String, String>{},
          })
        ],
      );
    });

    test('launch with headers', () async {
      final UrlLauncherLinux launcher = UrlLauncherLinux();
      await launcher.launch(
        'http://example.com/',
        useSafariVC: true,
        useWebView: false,
        enableJavaScript: false,
        enableDomStorage: false,
        universalLinksOnly: false,
        headers: const <String, String>{'key': 'value'},
      );
      expect(
        log,
        <Matcher>[
          isMethodCall('launch', arguments: <String, Object>{
            'url': 'http://example.com/',
            'enableJavaScript': false,
            'enableDomStorage': false,
            'universalLinksOnly': false,
            'headers': <String, String>{'key': 'value'},
          })
        ],
      );
    });

    test('launch universal links only', () async {
      final UrlLauncherLinux launcher = UrlLauncherLinux();
      await launcher.launch(
        'http://example.com/',
        useSafariVC: false,
        useWebView: false,
        enableJavaScript: false,
        enableDomStorage: false,
        universalLinksOnly: true,
        headers: const <String, String>{},
      );
      expect(
        log,
        <Matcher>[
          isMethodCall('launch', arguments: <String, Object>{
            'url': 'http://example.com/',
            'enableJavaScript': false,
            'enableDomStorage': false,
            'universalLinksOnly': true,
            'headers': <String, String>{},
          })
        ],
      );
    });

    test('launch should return false if platform returns null', () async {
      final UrlLauncherLinux launcher = UrlLauncherLinux();
      final bool launched = await launcher.launch(
        'http://example.com/',
        useSafariVC: true,
        useWebView: false,
        enableJavaScript: false,
        enableDomStorage: false,
        universalLinksOnly: false,
        headers: const <String, String>{},
      );

      expect(launched, false);
    });
  });
}
