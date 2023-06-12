// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_ios/src/messages.g.dart';
import 'package:url_launcher_ios/url_launcher_ios.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UrlLauncherIOS', () {
    late _FakeUrlLauncherApi api;

    setUp(() {
      api = _FakeUrlLauncherApi();
    });

    test('registers instance', () {
      UrlLauncherIOS.registerWith();
      expect(UrlLauncherPlatform.instance, isA<UrlLauncherIOS>());
    });

    test('canLaunch success', () async {
      final UrlLauncherIOS launcher = UrlLauncherIOS(api: api);
      expect(await launcher.canLaunch('http://example.com/'), true);
    });

    test('canLaunch failure', () async {
      final UrlLauncherIOS launcher = UrlLauncherIOS(api: api);
      expect(await launcher.canLaunch('unknown://scheme'), false);
    });

    test('canLaunch invalid URL passes the PlatformException through',
        () async {
      final UrlLauncherIOS launcher = UrlLauncherIOS(api: api);
      expectLater(launcher.canLaunch('invalid://u r l'),
          throwsA(isA<PlatformException>()));
    });

    test('launch success', () async {
      final UrlLauncherIOS launcher = UrlLauncherIOS(api: api);
      expect(
          await launcher.launch(
            'http://example.com/',
            useSafariVC: false,
            useWebView: false,
            enableJavaScript: false,
            enableDomStorage: false,
            universalLinksOnly: false,
            headers: const <String, String>{},
          ),
          true);
      expect(api.passedUniversalLinksOnly, false);
    });

    test('launch failure', () async {
      final UrlLauncherIOS launcher = UrlLauncherIOS(api: api);
      expect(
          await launcher.launch(
            'unknown://scheme',
            useSafariVC: false,
            useWebView: false,
            enableJavaScript: false,
            enableDomStorage: false,
            universalLinksOnly: false,
            headers: const <String, String>{},
          ),
          false);
      expect(api.passedUniversalLinksOnly, false);
    });

    test('launch invalid URL passes the PlatformException through', () async {
      final UrlLauncherIOS launcher = UrlLauncherIOS(api: api);
      expectLater(
          launcher.launch(
            'invalid://u r l',
            useSafariVC: false,
            useWebView: false,
            enableJavaScript: false,
            enableDomStorage: false,
            universalLinksOnly: false,
            headers: const <String, String>{},
          ),
          throwsA(isA<PlatformException>()));
    });

    test('launch force SafariVC', () async {
      final UrlLauncherIOS launcher = UrlLauncherIOS(api: api);
      expect(
          await launcher.launch(
            'http://example.com/',
            useSafariVC: true,
            useWebView: false,
            enableJavaScript: false,
            enableDomStorage: false,
            universalLinksOnly: false,
            headers: const <String, String>{},
          ),
          true);
      expect(api.usedSafariViewController, true);
    });

    test('launch universal links only', () async {
      final UrlLauncherIOS launcher = UrlLauncherIOS(api: api);
      expect(
          await launcher.launch(
            'http://example.com/',
            useSafariVC: false,
            useWebView: false,
            enableJavaScript: false,
            enableDomStorage: false,
            universalLinksOnly: true,
            headers: const <String, String>{},
          ),
          true);
      expect(api.passedUniversalLinksOnly, true);
    });

    test('launch force SafariVC to false', () async {
      final UrlLauncherIOS launcher = UrlLauncherIOS(api: api);
      expect(
          await launcher.launch(
            'http://example.com/',
            useSafariVC: false,
            useWebView: false,
            enableJavaScript: false,
            enableDomStorage: false,
            universalLinksOnly: false,
            headers: const <String, String>{},
          ),
          true);
      expect(api.usedSafariViewController, false);
    });

    test('closeWebView default behavior', () async {
      final UrlLauncherIOS launcher = UrlLauncherIOS(api: api);
      await launcher.closeWebView();
      expect(api.closed, true);
    });
  });
}

/// A fake implementation of the host API that reacts to specific schemes.
///
/// See _isLaunchable for the behaviors.
class _FakeUrlLauncherApi implements UrlLauncherApi {
  bool? passedUniversalLinksOnly;
  bool? usedSafariViewController;
  bool? closed;

  @override
  Future<bool> canLaunchUrl(String url) async {
    return _isLaunchable(url);
  }

  @override
  Future<bool> launchUrl(String url, bool universalLinksOnly) async {
    passedUniversalLinksOnly = universalLinksOnly;
    usedSafariViewController = false;
    return _isLaunchable(url);
  }

  @override
  Future<bool> openUrlInSafariViewController(String url) async {
    usedSafariViewController = true;
    return _isLaunchable(url);
  }

  @override
  Future<void> closeSafariViewController() async {
    closed = true;
  }

  bool _isLaunchable(String url) {
    final String scheme = url.split(':')[0];
    switch (scheme) {
      case 'http':
      case 'https':
        return true;
      case 'invalid':
        throw PlatformException(code: 'argument_error');
      default:
        return false;
    }
  }
}
