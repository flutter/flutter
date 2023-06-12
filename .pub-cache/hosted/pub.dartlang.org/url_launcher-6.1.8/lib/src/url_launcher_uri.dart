// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../url_launcher_string.dart';
import 'type_conversion.dart';

/// Passes [url] to the underlying platform for handling.
///
/// [mode] support varies significantly by platform:
///   - [LaunchMode.platformDefault] is supported on all platforms:
///     - On iOS and Android, this treats web URLs as
///       [LaunchMode.inAppWebView], and all other URLs as
///       [LaunchMode.externalApplication].
///     - On Windows, macOS, and Linux this behaves like
///       [LaunchMode.externalApplication].
///     - On web, this uses `webOnlyWindowName` for web URLs, and behaves like
///       [LaunchMode.externalApplication] for any other content.
///   - [LaunchMode.inAppWebView] is currently only supported on iOS and
///     Android. If a non-web URL is passed with this mode, an [ArgumentError]
///     will be thrown.
///   - [LaunchMode.externalApplication] is supported on all platforms.
///     On iOS, this should be used in cases where sharing the cookies of the
///     user's browser is important, such as SSO flows, since Safari View
///     Controller does not share the browser's context.
///   - [LaunchMode.externalNonBrowserApplication] is supported on iOS 10+.
///     This setting is used to require universal links to open in a non-browser
///     application.
///
/// For web, [webOnlyWindowName] specifies a target for the launch. This
/// supports the standard special link target names. For example:
///  - "_blank" opens the new URL in a new tab.
///  - "_self" opens the new URL in the current tab.
/// Default behaviour when unset is to open the url in a new tab.
///
/// Returns true if the URL was launched successful, otherwise either returns
/// false or throws a [PlatformException] depending on the failure.
Future<bool> launchUrl(
  Uri url, {
  LaunchMode mode = LaunchMode.platformDefault,
  WebViewConfiguration webViewConfiguration = const WebViewConfiguration(),
  String? webOnlyWindowName,
}) async {
  if (mode == LaunchMode.inAppWebView &&
      !(url.scheme == 'https' || url.scheme == 'http')) {
    throw ArgumentError.value(url, 'url',
        'To use an in-app web view, you must provide an http(s) URL.');
  }
  return UrlLauncherPlatform.instance.launchUrl(
    url.toString(),
    LaunchOptions(
      mode: convertLaunchMode(mode),
      webViewConfiguration: convertConfiguration(webViewConfiguration),
      webOnlyWindowName: webOnlyWindowName,
    ),
  );
}

/// Checks whether the specified URL can be handled by some app installed on the
/// device.
///
/// Returns true if it is possible to verify that there is a handler available.
/// A false return value can indicate either that there is no handler available,
/// or that the application does not have permission to check. For example:
/// - On recent versions of Android and iOS, this will always return false
///   unless the application has been configuration to allow
///   querying the system for launch support. See
///   [the README](https://pub.dev/packages/url_launcher#configuration) for
///   details.
/// - On web, this will always return false except for a few specific schemes
///   that are always assumed to be supported (such as http(s)), as web pages
///   are never allowed to query installed applications.
Future<bool> canLaunchUrl(Uri url) async {
  return UrlLauncherPlatform.instance.canLaunch(url.toString());
}

/// Closes the current in-app web view, if one was previously opened by
/// [launchUrl].
///
/// If [launchUrl] was never called with [LaunchMode.inAppWebView], then this
/// call will have no effect.
Future<void> closeInAppWebView() async {
  return UrlLauncherPlatform.instance.closeWebView();
}
