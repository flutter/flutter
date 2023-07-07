// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:url_launcher_windows/url_launcher_windows.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$UrlLauncherWindows', () {
    const MethodChannel channel =
        MethodChannel('plugins.flutter.io/url_launcher_windows');
    final List<MethodCall> log = <MethodCall>[];
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);

      // Return null explicitly instead of relying on the implicit null
      // returned by the method channel if no return statement is specified.
      return null;
    });

    test('registers instance', () {
      UrlLauncherWindows.registerWith();
      expect(UrlLauncherPlatform.instance, isA<UrlLauncherWindows>());
    });

    tearDown(() {
      log.clear();
    });

    test('canLaunch', () async {
      final UrlLauncherWindows launcher = UrlLauncherWindows();
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
      final UrlLauncherWindows launcher = UrlLauncherWindows();
      final bool canLaunch = await launcher.canLaunch('http://example.com/');

      expect(canLaunch, false);
    });

    test('launch', () async {
      final UrlLauncherWindows launcher = UrlLauncherWindows();
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
      final UrlLauncherWindows launcher = UrlLauncherWindows();
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
      final UrlLauncherWindows launcher = UrlLauncherWindows();
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
      final UrlLauncherWindows launcher = UrlLauncherWindows();
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
