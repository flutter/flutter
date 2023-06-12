// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_macos/src/messages.g.dart';
import 'package:url_launcher_macos/url_launcher_macos.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

void main() {
  group('UrlLauncherMacOS', () {
    late _FakeUrlLauncherApi api;

    setUp(() {
      api = _FakeUrlLauncherApi();
    });

    test('registers instance', () {
      UrlLauncherMacOS.registerWith();
      expect(UrlLauncherPlatform.instance, isA<UrlLauncherMacOS>());
    });

    group('canLaunch', () {
      test('success', () async {
        final UrlLauncherMacOS launcher = UrlLauncherMacOS(api: api);
        expect(await launcher.canLaunch('http://example.com/'), true);
      });

      test('failure', () async {
        final UrlLauncherMacOS launcher = UrlLauncherMacOS(api: api);
        expect(await launcher.canLaunch('unknown://scheme'), false);
      });

      test('invalid URL returns a PlatformException', () async {
        final UrlLauncherMacOS launcher = UrlLauncherMacOS(api: api);
        expectLater(launcher.canLaunch('invalid://u r l'),
            throwsA(isA<PlatformException>()));
      });

      test('passes unexpected PlatformExceptions through', () async {
        final UrlLauncherMacOS launcher = UrlLauncherMacOS(api: api);
        expectLater(launcher.canLaunch('unexpectedthrow://someexception'),
            throwsA(isA<PlatformException>()));
      });
    });

    group('launch', () {
      test('success', () async {
        final UrlLauncherMacOS launcher = UrlLauncherMacOS(api: api);
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
      });

      test('failure', () async {
        final UrlLauncherMacOS launcher = UrlLauncherMacOS(api: api);
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
      });

      test('invalid URL returns a PlatformException', () async {
        final UrlLauncherMacOS launcher = UrlLauncherMacOS(api: api);
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

      test('passes unexpected PlatformExceptions through', () async {
        final UrlLauncherMacOS launcher = UrlLauncherMacOS(api: api);
        expectLater(
            launcher.launch(
              'unexpectedthrow://someexception',
              useSafariVC: false,
              useWebView: false,
              enableJavaScript: false,
              enableDomStorage: false,
              universalLinksOnly: false,
              headers: const <String, String>{},
            ),
            throwsA(isA<PlatformException>()));
      });
    });
  });
}

/// A fake implementation of the host API that reacts to specific schemes.
///
/// See _isLaunchable for the behaviors.
class _FakeUrlLauncherApi implements UrlLauncherApi {
  @override
  Future<UrlLauncherBoolResult> canLaunchUrl(String url) async {
    return _isLaunchable(url);
  }

  @override
  Future<UrlLauncherBoolResult> launchUrl(String url) async {
    return _isLaunchable(url);
  }

  UrlLauncherBoolResult _isLaunchable(String url) {
    final String scheme = url.split(':')[0];
    switch (scheme) {
      case 'http':
      case 'https':
        return UrlLauncherBoolResult(value: true);
      case 'invalid':
        return UrlLauncherBoolResult(
            value: false, error: UrlLauncherError.invalidUrl);
      case 'unexpectedthrow':
        throw PlatformException(code: 'argument_error');
      default:
        return UrlLauncherBoolResult(value: false);
    }
  }
}
