// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(a14n): remove this import once Flutter 3.1 or later reaches stable (including flutter/flutter#105648)
// ignore: unnecessary_import
import 'dart:ui' show Brightness;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/src/legacy_api.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../mocks/mock_url_launcher_platform.dart';

void main() {
  final MockUrlLauncher mock = MockUrlLauncher();
  UrlLauncherPlatform.instance = mock;

  test('closeWebView default behavior', () async {
    await closeWebView();
    expect(mock.closeWebViewCalled, isTrue);
  });

  group('canLaunch', () {
    test('returns true', () async {
      mock
        ..setCanLaunchExpectations('foo')
        ..setResponse(true);

      final bool result = await canLaunch('foo');

      expect(result, isTrue);
    });

    test('returns false', () async {
      mock
        ..setCanLaunchExpectations('foo')
        ..setResponse(false);

      final bool result = await canLaunch('foo');

      expect(result, isFalse);
    });
  });
  group('launch', () {
    test('default behavior', () async {
      mock
        ..setLaunchExpectations(
          url: 'http://flutter.dev/',
          useSafariVC: true,
          useWebView: false,
          enableJavaScript: false,
          enableDomStorage: false,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(await launch('http://flutter.dev/'), isTrue);
    });

    test('with headers', () async {
      mock
        ..setLaunchExpectations(
          url: 'http://flutter.dev/',
          useSafariVC: true,
          useWebView: false,
          enableJavaScript: false,
          enableDomStorage: false,
          universalLinksOnly: false,
          headers: <String, String>{'key': 'value'},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(
          await launch(
            'http://flutter.dev/',
            headers: <String, String>{'key': 'value'},
          ),
          isTrue);
    });

    test('force SafariVC', () async {
      mock
        ..setLaunchExpectations(
          url: 'http://flutter.dev/',
          useSafariVC: true,
          useWebView: false,
          enableJavaScript: false,
          enableDomStorage: false,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(await launch('http://flutter.dev/', forceSafariVC: true), isTrue);
    });

    test('universal links only', () async {
      mock
        ..setLaunchExpectations(
          url: 'http://flutter.dev/',
          useSafariVC: false,
          useWebView: false,
          enableJavaScript: false,
          enableDomStorage: false,
          universalLinksOnly: true,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(
          await launch('http://flutter.dev/',
              forceSafariVC: false, universalLinksOnly: true),
          isTrue);
    });

    test('force WebView', () async {
      mock
        ..setLaunchExpectations(
          url: 'http://flutter.dev/',
          useSafariVC: true,
          useWebView: true,
          enableJavaScript: false,
          enableDomStorage: false,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(await launch('http://flutter.dev/', forceWebView: true), isTrue);
    });

    test('force WebView enable javascript', () async {
      mock
        ..setLaunchExpectations(
          url: 'http://flutter.dev/',
          useSafariVC: true,
          useWebView: true,
          enableJavaScript: true,
          enableDomStorage: false,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(
          await launch('http://flutter.dev/',
              forceWebView: true, enableJavaScript: true),
          isTrue);
    });

    test('force WebView enable DOM storage', () async {
      mock
        ..setLaunchExpectations(
          url: 'http://flutter.dev/',
          useSafariVC: true,
          useWebView: true,
          enableJavaScript: false,
          enableDomStorage: true,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(
          await launch('http://flutter.dev/',
              forceWebView: true, enableDomStorage: true),
          isTrue);
    });

    test('force SafariVC to false', () async {
      mock
        ..setLaunchExpectations(
          url: 'http://flutter.dev/',
          useSafariVC: false,
          useWebView: false,
          enableJavaScript: false,
          enableDomStorage: false,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(await launch('http://flutter.dev/', forceSafariVC: false), isTrue);
    });

    test('cannot launch a non-web in webview', () async {
      expect(() async => await launch('tel:555-555-5555', forceWebView: true),
          throwsA(isA<PlatformException>()));
    });

    test('send e-mail', () async {
      mock
        ..setLaunchExpectations(
          url: 'mailto:gmail-noreply@google.com?subject=Hello',
          useSafariVC: false,
          useWebView: false,
          enableJavaScript: false,
          enableDomStorage: false,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(await launch('mailto:gmail-noreply@google.com?subject=Hello'),
          isTrue);
    });

    test('cannot send e-mail with forceSafariVC: true', () async {
      expect(
          () async => await launch(
              'mailto:gmail-noreply@google.com?subject=Hello',
              forceSafariVC: true),
          throwsA(isA<PlatformException>()));
    });

    test('cannot send e-mail with forceWebView: true', () async {
      expect(
          () async => await launch(
              'mailto:gmail-noreply@google.com?subject=Hello',
              forceWebView: true),
          throwsA(isA<PlatformException>()));
    });

    test('controls system UI when changing statusBarBrightness', () async {
      mock
        ..setLaunchExpectations(
          url: 'http://flutter.dev/',
          useSafariVC: true,
          useWebView: false,
          enableJavaScript: false,
          enableDomStorage: false,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);

      final TestWidgetsFlutterBinding binding =
          _anonymize(TestWidgetsFlutterBinding.ensureInitialized())!
              as TestWidgetsFlutterBinding;
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      binding.renderView.automaticSystemUiAdjustment = true;
      final Future<bool> launchResult =
          launch('http://flutter.dev/', statusBarBrightness: Brightness.dark);

      // Should take over control of the automaticSystemUiAdjustment while it's
      // pending, then restore it back to normal after the launch finishes.
      expect(binding.renderView.automaticSystemUiAdjustment, isFalse);
      await launchResult;
      expect(binding.renderView.automaticSystemUiAdjustment, isTrue);
    });

    test('sets automaticSystemUiAdjustment to not be null', () async {
      mock
        ..setLaunchExpectations(
          url: 'http://flutter.dev/',
          useSafariVC: true,
          useWebView: false,
          enableJavaScript: false,
          enableDomStorage: false,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);

      final TestWidgetsFlutterBinding binding =
          _anonymize(TestWidgetsFlutterBinding.ensureInitialized())!
              as TestWidgetsFlutterBinding;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(binding.renderView.automaticSystemUiAdjustment, true);
      final Future<bool> launchResult =
          launch('http://flutter.dev/', statusBarBrightness: Brightness.dark);

      // The automaticSystemUiAdjustment should be set before the launch
      // and equal to true after the launch result is complete.
      expect(binding.renderView.automaticSystemUiAdjustment, true);
      await launchResult;
      expect(binding.renderView.automaticSystemUiAdjustment, true);
    });

    test('open non-parseable url', () async {
      mock
        ..setLaunchExpectations(
          url:
              'rdp://full%20address=s:mypc:3389&audiomode=i:2&disable%20themes=i:1',
          useSafariVC: false,
          useWebView: false,
          enableJavaScript: false,
          enableDomStorage: false,
          universalLinksOnly: false,
          headers: <String, String>{},
          webOnlyWindowName: null,
        )
        ..setResponse(true);
      expect(
          await launch(
              'rdp://full%20address=s:mypc:3389&audiomode=i:2&disable%20themes=i:1'),
          isTrue);
    });

    test('cannot open non-parseable url with forceSafariVC: true', () async {
      expect(
          () async => await launch(
              'rdp://full%20address=s:mypc:3389&audiomode=i:2&disable%20themes=i:1',
              forceSafariVC: true),
          throwsA(isA<PlatformException>()));
    });

    test('cannot open non-parseable url with forceWebView: true', () async {
      expect(
          () async => await launch(
              'rdp://full%20address=s:mypc:3389&audiomode=i:2&disable%20themes=i:1',
              forceWebView: true),
          throwsA(isA<PlatformException>()));
    });
  });
}

/// This removes the type information from a value so that it can be cast
/// to another type even if that cast is redundant.
///
/// We use this so that APIs whose type have become more descriptive can still
/// be used on the stable branch where they require a cast.
// TODO(ianh): Remove this once we roll stable in late 2021.
Object? _anonymize<T>(T? value) => value;
