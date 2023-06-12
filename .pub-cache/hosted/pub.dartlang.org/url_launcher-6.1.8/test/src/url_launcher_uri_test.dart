// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/src/types.dart';
import 'package:url_launcher/src/url_launcher_uri.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../mocks/mock_url_launcher_platform.dart';

void main() {
  final MockUrlLauncher mock = MockUrlLauncher();
  UrlLauncherPlatform.instance = mock;

  test('closeInAppWebView', () async {
    await closeInAppWebView();
    expect(mock.closeWebViewCalled, isTrue);
  });

  group('canLaunchUrl', () {
    test('handles returning true', () async {
      final Uri url = Uri.parse('https://flutter.dev');
      mock
        ..setCanLaunchExpectations(url.toString())
        ..setResponse(true);

      final bool result = await canLaunchUrl(url);

      expect(result, isTrue);
    });

    test('handles returning false', () async {
      final Uri url = Uri.parse('https://flutter.dev');
      mock
        ..setCanLaunchExpectations(url.toString())
        ..setResponse(false);

      final bool result = await canLaunchUrl(url);

      expect(result, isFalse);
    });
  });

  group('launchUrl', () {
    test('default behavior with web URL', () async {
      final Uri url = Uri.parse('https://flutter.dev');
      mock
        ..setLaunchExpectations(
          url: url.toString(),
          launchMode: PreferredLaunchMode.platformDefault,
          enableJavaScript: true,
          enableDomStorage: true,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(await launchUrl(url), isTrue);
    });

    test('default behavior with non-web URL', () async {
      final Uri url = Uri.parse('customscheme:foo');
      mock
        ..setLaunchExpectations(
          url: url.toString(),
          launchMode: PreferredLaunchMode.platformDefault,
          enableJavaScript: true,
          enableDomStorage: true,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(await launchUrl(url), isTrue);
    });

    test('explicit default launch mode with web URL', () async {
      final Uri url = Uri.parse('https://flutter.dev');
      mock
        ..setLaunchExpectations(
          url: url.toString(),
          launchMode: PreferredLaunchMode.platformDefault,
          enableJavaScript: true,
          enableDomStorage: true,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(await launchUrl(url), isTrue);
    });

    test('explicit default launch mode with non-web URL', () async {
      final Uri url = Uri.parse('customscheme:foo');
      mock
        ..setLaunchExpectations(
          url: url.toString(),
          launchMode: PreferredLaunchMode.platformDefault,
          enableJavaScript: true,
          enableDomStorage: true,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(await launchUrl(url), isTrue);
    });

    test('in-app webview', () async {
      final Uri url = Uri.parse('https://flutter.dev');
      mock
        ..setLaunchExpectations(
          url: url.toString(),
          launchMode: PreferredLaunchMode.inAppWebView,
          enableJavaScript: true,
          enableDomStorage: true,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(await launchUrl(url, mode: LaunchMode.inAppWebView), isTrue);
    });

    test('external browser', () async {
      final Uri url = Uri.parse('https://flutter.dev');
      mock
        ..setLaunchExpectations(
          url: url.toString(),
          launchMode: PreferredLaunchMode.externalApplication,
          enableJavaScript: true,
          enableDomStorage: true,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(
          await launchUrl(url, mode: LaunchMode.externalApplication), isTrue);
    });

    test('external non-browser only', () async {
      final Uri url = Uri.parse('https://flutter.dev');
      mock
        ..setLaunchExpectations(
          url: url.toString(),
          launchMode: PreferredLaunchMode.externalNonBrowserApplication,
          enableJavaScript: true,
          enableDomStorage: true,
          universalLinksOnly: true,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(
          await launchUrl(url, mode: LaunchMode.externalNonBrowserApplication),
          isTrue);
    });

    test('in-app webview without javascript', () async {
      final Uri url = Uri.parse('https://flutter.dev');
      mock
        ..setLaunchExpectations(
          url: url.toString(),
          launchMode: PreferredLaunchMode.inAppWebView,
          enableJavaScript: false,
          enableDomStorage: true,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(
          await launchUrl(url,
              mode: LaunchMode.inAppWebView,
              webViewConfiguration:
                  const WebViewConfiguration(enableJavaScript: false)),
          isTrue);
    });

    test('in-app webview without DOM storage', () async {
      final Uri url = Uri.parse('https://flutter.dev');
      mock
        ..setLaunchExpectations(
          url: url.toString(),
          launchMode: PreferredLaunchMode.inAppWebView,
          enableJavaScript: true,
          enableDomStorage: false,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(
          await launchUrl(url,
              mode: LaunchMode.inAppWebView,
              webViewConfiguration:
                  const WebViewConfiguration(enableDomStorage: false)),
          isTrue);
    });

    test('in-app webview with headers', () async {
      final Uri url = Uri.parse('https://flutter.dev');
      mock
        ..setLaunchExpectations(
          url: url.toString(),
          launchMode: PreferredLaunchMode.inAppWebView,
          enableJavaScript: true,
          enableDomStorage: true,
          universalLinksOnly: false,
          headers: <String, String>{'key': 'value'},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(
          await launchUrl(url,
              mode: LaunchMode.inAppWebView,
              webViewConfiguration: const WebViewConfiguration(
                  headers: <String, String>{'key': 'value'})),
          isTrue);
    });

    test('cannot launch a non-web URL in a webview', () async {
      expect(
          () async => launchUrl(Uri(scheme: 'tel', path: '555-555-5555'),
              mode: LaunchMode.inAppWebView),
          throwsA(isA<ArgumentError>()));
    });

    test('non-web URL with default options', () async {
      final Uri emailLaunchUrl = Uri(
        scheme: 'mailto',
        path: 'smith@example.com',
        queryParameters: <String, String>{'subject': 'Hello'},
      );
      mock
        ..setLaunchExpectations(
          url: emailLaunchUrl.toString(),
          launchMode: PreferredLaunchMode.platformDefault,
          enableJavaScript: true,
          enableDomStorage: true,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(await launchUrl(emailLaunchUrl), isTrue);
    });
  });
}
