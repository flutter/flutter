// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class MockUrlLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  String? url;
  PreferredLaunchMode? launchMode;
  bool? useSafariVC;
  bool? useWebView;
  bool? enableJavaScript;
  bool? enableDomStorage;
  bool? universalLinksOnly;
  Map<String, String>? headers;
  String? webOnlyWindowName;

  bool? response;

  bool closeWebViewCalled = false;
  bool canLaunchCalled = false;
  bool launchCalled = false;

  // ignore: use_setters_to_change_properties
  void setCanLaunchExpectations(String url) {
    this.url = url;
  }

  void setLaunchExpectations({
    required String url,
    PreferredLaunchMode? launchMode,
    bool? useSafariVC,
    bool? useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    required String? webOnlyWindowName,
  }) {
    this.url = url;
    this.launchMode = launchMode;
    this.useSafariVC = useSafariVC;
    this.useWebView = useWebView;
    this.enableJavaScript = enableJavaScript;
    this.enableDomStorage = enableDomStorage;
    this.universalLinksOnly = universalLinksOnly;
    this.headers = headers;
    this.webOnlyWindowName = webOnlyWindowName;
  }

  // ignore: use_setters_to_change_properties
  void setResponse(bool response) {
    this.response = response;
  }

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async {
    expect(url, this.url);
    canLaunchCalled = true;
    return response!;
  }

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
    expect(url, this.url);
    expect(useSafariVC, this.useSafariVC);
    expect(useWebView, this.useWebView);
    expect(enableJavaScript, this.enableJavaScript);
    expect(enableDomStorage, this.enableDomStorage);
    expect(universalLinksOnly, this.universalLinksOnly);
    expect(headers, this.headers);
    expect(webOnlyWindowName, this.webOnlyWindowName);
    launchCalled = true;
    return response!;
  }

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    expect(url, this.url);
    expect(options.mode, launchMode);
    expect(options.webViewConfiguration.enableJavaScript, enableJavaScript);
    expect(options.webViewConfiguration.enableDomStorage, enableDomStorage);
    expect(options.webViewConfiguration.headers, headers);
    expect(options.webOnlyWindowName, webOnlyWindowName);
    launchCalled = true;
    return response!;
  }

  @override
  Future<void> closeWebView() async {
    closeWebViewCalled = true;
  }
}
