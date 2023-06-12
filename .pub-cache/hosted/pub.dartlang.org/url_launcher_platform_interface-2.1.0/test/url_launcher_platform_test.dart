// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class CapturingUrlLauncher extends UrlLauncherPlatform {
  String? url;
  bool? useSafariVC;
  bool? useWebView;
  bool? enableJavaScript;
  bool? enableDomStorage;
  bool? universalLinksOnly;
  Map<String, String> headers = <String, String>{};
  String? webOnlyWindowName;

  @override
  final LinkDelegate? linkDelegate = null;

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    this.url = url;
    this.useSafariVC = useSafariVC;
    this.useWebView = useWebView;
    this.enableJavaScript = enableJavaScript;
    this.enableDomStorage = enableDomStorage;
    this.universalLinksOnly = universalLinksOnly;
    this.headers = headers;
    this.webOnlyWindowName = webOnlyWindowName;

    return true;
  }
}

void main() {
  test('launchUrl calls through to launch with default options for web URL',
      () async {
    final CapturingUrlLauncher launcher = CapturingUrlLauncher();

    await launcher.launchUrl('https://flutter.dev', const LaunchOptions());

    expect(launcher.url, 'https://flutter.dev');
    expect(launcher.useSafariVC, true);
    expect(launcher.useWebView, true);
    expect(launcher.enableJavaScript, true);
    expect(launcher.enableDomStorage, true);
    expect(launcher.universalLinksOnly, false);
    expect(launcher.headers, isEmpty);
    expect(launcher.webOnlyWindowName, null);
  });

  test('launchUrl calls through to launch with default options for non-web URL',
      () async {
    final CapturingUrlLauncher launcher = CapturingUrlLauncher();

    await launcher.launchUrl('tel:123456789', const LaunchOptions());

    expect(launcher.url, 'tel:123456789');
    expect(launcher.useSafariVC, false);
    expect(launcher.useWebView, false);
    expect(launcher.enableJavaScript, true);
    expect(launcher.enableDomStorage, true);
    expect(launcher.universalLinksOnly, false);
    expect(launcher.headers, isEmpty);
    expect(launcher.webOnlyWindowName, null);
  });

  test('launchUrl calls through to launch with universal links', () async {
    final CapturingUrlLauncher launcher = CapturingUrlLauncher();

    await launcher.launchUrl(
        'https://flutter.dev',
        const LaunchOptions(
            mode: PreferredLaunchMode.externalNonBrowserApplication));

    expect(launcher.url, 'https://flutter.dev');
    expect(launcher.useSafariVC, false);
    expect(launcher.useWebView, false);
    expect(launcher.enableJavaScript, true);
    expect(launcher.enableDomStorage, true);
    expect(launcher.universalLinksOnly, true);
    expect(launcher.headers, isEmpty);
    expect(launcher.webOnlyWindowName, null);
  });

  test('launchUrl calls through to launch with all non-default options',
      () async {
    final CapturingUrlLauncher launcher = CapturingUrlLauncher();

    await launcher.launchUrl(
        'https://flutter.dev',
        const LaunchOptions(
          mode: PreferredLaunchMode.externalApplication,
          webViewConfiguration: InAppWebViewConfiguration(
              enableJavaScript: false,
              enableDomStorage: false,
              headers: <String, String>{'foo': 'bar'}),
          webOnlyWindowName: 'a_name',
        ));

    expect(launcher.url, 'https://flutter.dev');
    expect(launcher.useSafariVC, false);
    expect(launcher.useWebView, false);
    expect(launcher.enableJavaScript, false);
    expect(launcher.enableDomStorage, false);
    expect(launcher.universalLinksOnly, false);
    expect(launcher.headers['foo'], 'bar');
    expect(launcher.webOnlyWindowName, 'a_name');
  });
}
