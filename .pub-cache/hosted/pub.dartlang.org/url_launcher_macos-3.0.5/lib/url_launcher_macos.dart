// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'src/messages.g.dart';

/// An implementation of [UrlLauncherPlatform] for macOS.
class UrlLauncherMacOS extends UrlLauncherPlatform {
  /// Creates a new plugin implementation instance.
  UrlLauncherMacOS({
    @visibleForTesting UrlLauncherApi? api,
  }) : _hostApi = api ?? UrlLauncherApi();

  final UrlLauncherApi _hostApi;

  /// Registers this class as the default instance of [UrlLauncherPlatform].
  static void registerWith() {
    UrlLauncherPlatform.instance = UrlLauncherMacOS();
  }

  @override
  final LinkDelegate? linkDelegate = null;

  @override
  Future<bool> canLaunch(String url) async {
    final UrlLauncherBoolResult result = await _hostApi.canLaunchUrl(url);
    switch (result.error) {
      case UrlLauncherError.invalidUrl:
        throw _getInvalidUrlException(url);
      case null:
    }
    return result.value;
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
    final UrlLauncherBoolResult result = await _hostApi.launchUrl(url);
    switch (result.error) {
      case UrlLauncherError.invalidUrl:
        throw _getInvalidUrlException(url);
      case null:
    }
    return result.value;
  }

  Exception _getInvalidUrlException(String url) {
    // TODO(stuartmorgan): Make this an actual ArgumentError. This should be
    // coordinated across all platforms as a breaking change to have them all
    // return the same thing; currently it throws a PlatformException to
    // preserve existing behavior.
    return PlatformException(
        code: 'argument_error',
        message: 'Unable to parse URL',
        details: 'Provided URL: $url');
  }
}
