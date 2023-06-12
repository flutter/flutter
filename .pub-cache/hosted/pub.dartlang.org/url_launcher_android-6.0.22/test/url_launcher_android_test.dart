// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_android/url_launcher_android.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel =
      MethodChannel('plugins.flutter.io/url_launcher_android');
  late List<MethodCall> log;

  setUp(() {
    log = <MethodCall>[];
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);

      // Return null explicitly instead of relying on the implicit null
      // returned by the method channel if no return statement is specified.
      return null;
    });
  });

  test('registers instance', () {
    UrlLauncherAndroid.registerWith();
    expect(UrlLauncherPlatform.instance, isA<UrlLauncherAndroid>());
  });

  group('canLaunch', () {
    test('calls through', () async {
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        return true;
      });
      final UrlLauncherAndroid launcher = UrlLauncherAndroid();
      final bool canLaunch = await launcher.canLaunch('http://example.com/');
      expect(
        log,
        <Matcher>[
          isMethodCall('canLaunch', arguments: <String, Object>{
            'url': 'http://example.com/',
          })
        ],
      );
      expect(canLaunch, true);
    });

    test('returns false if platform returns null', () async {
      final UrlLauncherAndroid launcher = UrlLauncherAndroid();
      final bool canLaunch = await launcher.canLaunch('http://example.com/');

      expect(canLaunch, false);
    });

    test('checks a generic URL if an http URL returns false', () async {
      const String specificUrl = 'http://example.com/';
      const String genericUrl = 'http://flutter.dev';
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        return methodCall.arguments['url'] != specificUrl;
      });

      final UrlLauncherAndroid launcher = UrlLauncherAndroid();
      final bool canLaunch = await launcher.canLaunch(specificUrl);

      expect(canLaunch, true);
      expect(log.length, 2);
      expect(log[1].arguments['url'], genericUrl);
    });

    test('checks a generic URL if an https URL returns false', () async {
      const String specificUrl = 'https://example.com/';
      const String genericUrl = 'https://flutter.dev';
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        return methodCall.arguments['url'] != specificUrl;
      });

      final UrlLauncherAndroid launcher = UrlLauncherAndroid();
      final bool canLaunch = await launcher.canLaunch(specificUrl);

      expect(canLaunch, true);
      expect(log.length, 2);
      expect(log[1].arguments['url'], genericUrl);
    });

    test('does not a generic URL if a non-web URL returns false', () async {
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        return false;
      });

      final UrlLauncherAndroid launcher = UrlLauncherAndroid();
      final bool canLaunch = await launcher.canLaunch('sms:12345');

      expect(canLaunch, false);
      expect(log.length, 1);
    });
  });

  group('launch', () {
    test('calls through', () async {
      final UrlLauncherAndroid launcher = UrlLauncherAndroid();
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
            'useWebView': false,
            'enableJavaScript': false,
            'enableDomStorage': false,
            'universalLinksOnly': false,
            'headers': <String, String>{},
          })
        ],
      );
    });

    test('passes headers', () async {
      final UrlLauncherAndroid launcher = UrlLauncherAndroid();
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
            'useWebView': false,
            'enableJavaScript': false,
            'enableDomStorage': false,
            'universalLinksOnly': false,
            'headers': <String, String>{'key': 'value'},
          })
        ],
      );
    });

    test('handles universal links only', () async {
      final UrlLauncherAndroid launcher = UrlLauncherAndroid();
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
            'useWebView': false,
            'enableJavaScript': false,
            'enableDomStorage': false,
            'universalLinksOnly': true,
            'headers': <String, String>{},
          })
        ],
      );
    });

    test('handles force WebView', () async {
      final UrlLauncherAndroid launcher = UrlLauncherAndroid();
      await launcher.launch(
        'http://example.com/',
        useSafariVC: true,
        useWebView: true,
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
            'useWebView': true,
            'enableJavaScript': false,
            'enableDomStorage': false,
            'universalLinksOnly': false,
            'headers': <String, String>{},
          })
        ],
      );
    });

    test('handles force WebView with javascript', () async {
      final UrlLauncherAndroid launcher = UrlLauncherAndroid();
      await launcher.launch(
        'http://example.com/',
        useSafariVC: true,
        useWebView: true,
        enableJavaScript: true,
        enableDomStorage: false,
        universalLinksOnly: false,
        headers: const <String, String>{},
      );
      expect(
        log,
        <Matcher>[
          isMethodCall('launch', arguments: <String, Object>{
            'url': 'http://example.com/',
            'useWebView': true,
            'enableJavaScript': true,
            'enableDomStorage': false,
            'universalLinksOnly': false,
            'headers': <String, String>{},
          })
        ],
      );
    });

    test('handles force WebView with DOM storage', () async {
      final UrlLauncherAndroid launcher = UrlLauncherAndroid();
      await launcher.launch(
        'http://example.com/',
        useSafariVC: true,
        useWebView: true,
        enableJavaScript: false,
        enableDomStorage: true,
        universalLinksOnly: false,
        headers: const <String, String>{},
      );
      expect(
        log,
        <Matcher>[
          isMethodCall('launch', arguments: <String, Object>{
            'url': 'http://example.com/',
            'useWebView': true,
            'enableJavaScript': false,
            'enableDomStorage': true,
            'universalLinksOnly': false,
            'headers': <String, String>{},
          })
        ],
      );
    });

    test('returns false if platform returns null', () async {
      final UrlLauncherAndroid launcher = UrlLauncherAndroid();
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

  group('closeWebView', () {
    test('calls through', () async {
      final UrlLauncherAndroid launcher = UrlLauncherAndroid();
      await launcher.closeWebView();
      expect(
        log,
        <Matcher>[isMethodCall('closeWebView', arguments: null)],
      );
    });
  });
}
