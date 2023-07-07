// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

const MethodChannel _channel =
    MethodChannel('plugins.flutter.io/url_launcher_android');

/// An implementation of [UrlLauncherPlatform] for Android.
class UrlLauncherAndroid extends UrlLauncherPlatform {
  /// Registers this class as the default instance of [UrlLauncherPlatform].
  static void registerWith() {
    UrlLauncherPlatform.instance = UrlLauncherAndroid();
  }

  @override
  final LinkDelegate? linkDelegate = null;

  @override
  Future<bool> canLaunch(String url) async {
    final bool canLaunchSpecificUrl = await _canLaunchUrl(url);
    if (!canLaunchSpecificUrl) {
      final String scheme = _getUrlScheme(url);
      // canLaunch can return false when a custom application is registered to
      // handle a web URL, but the caller doesn't have permission to see what
      // that handler is. If that happens, try a web URL (with the same scheme
      // variant, to be safe) that should not have a custom handler. If that
      // returns true, then there is a browser, which means that there is
      // at least one handler for the original URL.
      if (scheme == 'http' || scheme == 'https') {
        return await _canLaunchUrl('$scheme://flutter.dev');
      }
    }
    return canLaunchSpecificUrl;
  }

  Future<bool> _canLaunchUrl(String url) {
    return _channel.invokeMethod<bool>(
      'canLaunch',
      <String, Object>{'url': url},
    ).then((bool? value) => value ?? false);
  }

  @override
  Future<void> closeWebView() {
    return _channel.invokeMethod<void>('closeWebView');
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
    return _channel.invokeMethod<bool>(
      'launch',
      <String, Object>{
        'url': url,
        'useWebView': useWebView,
        'enableJavaScript': enableJavaScript,
        'enableDomStorage': enableDomStorage,
        'universalLinksOnly': universalLinksOnly,
        'headers': headers,
      },
    ).then((bool? value) => value ?? false);
  }

  // Returns the part of [url] up to the first ':', or an empty string if there
  // is no ':'. This deliberately does not use [Uri] to extract the scheme
  // so that it works on strings that aren't actually valid URLs, since Android
  // is very lenient about what it accepts for launching.
  String _getUrlScheme(String url) {
    final int schemeEnd = url.indexOf(':');
    if (schemeEnd == -1) {
      return '';
    }
    return url.substring(0, schemeEnd);
  }
}
