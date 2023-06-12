// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/src/types.dart';
import 'package:url_launcher/src/url_launcher_string.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../mocks/mock_url_launcher_platform.dart';

void main() {
  final MockUrlLauncher mock = MockUrlLauncher();
  UrlLauncherPlatform.instance = mock;

  group('canLaunchUrlString', () {
    test('handles returning true', () async {
      const String urlString = 'https://flutter.dev';
      mock
        ..setCanLaunchExpectations(urlString)
        ..setResponse(true);

      final bool result = await canLaunchUrlString(urlString);

      expect(result, isTrue);
    });

    test('handles returning false', () async {
      const String urlString = 'https://flutter.dev';
      mock
        ..setCanLaunchExpectations(urlString)
        ..setResponse(false);

      final bool result = await canLaunchUrlString(urlString);

      expect(result, isFalse);
    });
  });

  group('launchUrlString', () {
    test('default behavior with web URL', () async {
      const String urlString = 'https://flutter.dev';
      mock
        ..setLaunchExpectations(
          url: urlString,
          launchMode: PreferredLaunchMode.platformDefault,
          enableJavaScript: true,
          enableDomStorage: true,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(await launchUrlString(urlString), isTrue);
    });

    test('default behavior with non-web URL', () async {
      const String urlString = 'customscheme:foo';
      mock
        ..setLaunchExpectations(
          url: urlString,
          launchMode: PreferredLaunchMode.platformDefault,
          enableJavaScript: true,
          enableDomStorage: true,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(await launchUrlString(urlString), isTrue);
    });

    test('explicit default launch mode with web URL', () async {
      const String urlString = 'https://flutter.dev';
      mock
        ..setLaunchExpectations(
          url: urlString,
          launchMode: PreferredLaunchMode.platformDefault,
          enableJavaScript: true,
          enableDomStorage: true,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(await launchUrlString(urlString), isTrue);
    });

    test('explicit default launch mode with non-web URL', () async {
      const String urlString = 'customscheme:foo';
      mock
        ..setLaunchExpectations(
          url: urlString,
          launchMode: PreferredLaunchMode.platformDefault,
          enableJavaScript: true,
          enableDomStorage: true,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(await launchUrlString(urlString), isTrue);
    });

    test('in-app webview', () async {
      const String urlString = 'https://flutter.dev';
      mock
        ..setLaunchExpectations(
          url: urlString,
          launchMode: PreferredLaunchMode.inAppWebView,
          enableJavaScript: true,
          enableDomStorage: true,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(await launchUrlString(urlString, mode: LaunchMode.inAppWebView),
          isTrue);
    });

    test('external browser', () async {
      const String urlString = 'https://flutter.dev';
      mock
        ..setLaunchExpectations(
          url: urlString,
          launchMode: PreferredLaunchMode.externalApplication,
          enableJavaScript: true,
          enableDomStorage: true,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(
          await launchUrlString(urlString,
              mode: LaunchMode.externalApplication),
          isTrue);
    });

    test('external non-browser only', () async {
      const String urlString = 'https://flutter.dev';
      mock
        ..setLaunchExpectations(
          url: urlString,
          launchMode: PreferredLaunchMode.externalNonBrowserApplication,
          enableJavaScript: true,
          enableDomStorage: true,
          universalLinksOnly: true,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(
          await launchUrlString(urlString,
              mode: LaunchMode.externalNonBrowserApplication),
          isTrue);
    });

    test('in-app webview without javascript', () async {
      const String urlString = 'https://flutter.dev';
      mock
        ..setLaunchExpectations(
          url: urlString,
          launchMode: PreferredLaunchMode.inAppWebView,
          enableJavaScript: false,
          enableDomStorage: true,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(
          await launchUrlString(urlString,
              mode: LaunchMode.inAppWebView,
              webViewConfiguration:
                  const WebViewConfiguration(enableJavaScript: false)),
          isTrue);
    });

    test('in-app webview without DOM storage', () async {
      const String urlString = 'https://flutter.dev';
      mock
        ..setLaunchExpectations(
          url: urlString,
          launchMode: PreferredLaunchMode.inAppWebView,
          enableJavaScript: true,
          enableDomStorage: false,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(
          await launchUrlString(urlString,
              mode: LaunchMode.inAppWebView,
              webViewConfiguration:
                  const WebViewConfiguration(enableDomStorage: false)),
          isTrue);
    });

    test('in-app webview with headers', () async {
      const String urlString = 'https://flutter.dev';
      mock
        ..setLaunchExpectations(
          url: urlString,
          launchMode: PreferredLaunchMode.inAppWebView,
          enableJavaScript: true,
          enableDomStorage: true,
          universalLinksOnly: false,
          headers: <String, String>{'key': 'value'},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(
          await launchUrlString(urlString,
              mode: LaunchMode.inAppWebView,
              webViewConfiguration: const WebViewConfiguration(
                  headers: <String, String>{'key': 'value'})),
          isTrue);
    });

    test('cannot launch a non-web URL in a webview', () async {
      expect(
          () async => launchUrlString('tel:555-555-5555',
              mode: LaunchMode.inAppWebView),
          throwsA(isA<ArgumentError>()));
    });

    test('non-web URL with default options', () async {
      const String emailLaunchUrlString =
          'mailto:smith@example.com?subject=Hello';
      mock
        ..setLaunchExpectations(
          url: emailLaunchUrlString,
          launchMode: PreferredLaunchMode.platformDefault,
          enableJavaScript: true,
          enableDomStorage: true,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(await launchUrlString(emailLaunchUrlString), isTrue);
    });

    test('allows non-parsable url', () async {
      // Not a valid Dart [Uri], but a valid URL on at least some platforms.
      const String urlString =
          'rdp://full%20address=s:mypc:3389&audiomode=i:2&disable%20themes=i:1';
      mock
        ..setLaunchExpectations(
          url: urlString,
          launchMode: PreferredLaunchMode.platformDefault,
          enableJavaScript: true,
          enableDomStorage: true,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(await launchUrlString(urlString), isTrue);
    });
  });
}
