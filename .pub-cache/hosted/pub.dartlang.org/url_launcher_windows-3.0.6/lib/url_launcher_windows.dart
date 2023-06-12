// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'src/messages.g.dart';

/// An implementation of [UrlLauncherPlatform] for Windows.
class UrlLauncherWindows extends UrlLauncherPlatform {
  /// Creates a new plugin implementation instance.
  UrlLauncherWindows({
    @visibleForTesting UrlLauncherApi? api,
  }) : _hostApi = api ?? UrlLauncherApi();

  final UrlLauncherApi _hostApi;

  /// Registers this class as the default instance of [UrlLauncherPlatform].
  static void registerWith() {
    UrlLauncherPlatform.instance = UrlLauncherWindows();
  }

  @override
  final LinkDelegate? linkDelegate = null;

  @override
  Future<bool> canLaunch(String url) {
    return _hostApi.canLaunchUrl(url);
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
    await _hostApi.launchUrl(url);
    // Failure is handled via a PlatformException from `launchUrl`.
    return true;
  }
}
