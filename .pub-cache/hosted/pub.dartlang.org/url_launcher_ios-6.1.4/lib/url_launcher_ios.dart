// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'src/messages.g.dart';

/// An implementation of [UrlLauncherPlatform] for iOS.
class UrlLauncherIOS extends UrlLauncherPlatform {
  /// Creates a new plugin implementation instance.
  UrlLauncherIOS({
    @visibleForTesting UrlLauncherApi? api,
  }) : _hostApi = api ?? UrlLauncherApi();

  final UrlLauncherApi _hostApi;

  /// Registers this class as the default instance of [UrlLauncherPlatform].
  static void registerWith() {
    UrlLauncherPlatform.instance = UrlLauncherIOS();
  }

  @override
  final LinkDelegate? linkDelegate = null;

  @override
  Future<bool> canLaunch(String url) {
    return _hostApi.canLaunchUrl(url);
  }

  @override
  Future<void> closeWebView() {
    return _hostApi.closeSafariViewController();
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
  }) {
    if (useSafariVC) {
      return _hostApi.openUrlInSafariViewController(url);
    } else {
      return _hostApi.launchUrl(url, universalLinksOnly);
    }
  }
}
