// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// Parses the specified URL string and delegates handling of it to the
/// underlying platform.
///
/// The returned future completes with a [PlatformException] on invalid URLs and
/// schemes which cannot be handled, that is when [canLaunch] would complete
/// with false.
///
/// By default when [forceSafariVC] is unset, the launcher
/// opens web URLs in the Safari View Controller, anything else is opened
/// using the default handler on the platform. If set to true, it opens the
/// URL in the Safari View Controller. If false, the URL is opened in the
/// default browser of the phone. Note that to work with universal links on iOS,
/// this must be set to false to let the platform's system handle the URL.
/// Set this to false if you want to use the cookies/context of the main browser
/// of the app (such as SSO flows). This setting will nullify [universalLinksOnly]
/// and will always launch a web content in the built-in Safari View Controller regardless
/// if the url is a universal link or not.
///
/// [universalLinksOnly] is only used in iOS with iOS version >= 10.0. This setting is only validated
/// when [forceSafariVC] is set to false. The default value of this setting is false.
/// By default (when unset), the launcher will either launch the url in a browser (when the
/// url is not a universal link), or launch the respective native app content (when
/// the url is a universal link). When set to true, the launcher will only launch
/// the content if the url is a universal link and the respective app for the universal
/// link is installed on the user's device; otherwise throw a [PlatformException].
///
/// [forceWebView] is an Android only setting. If null or false, the URL is
/// always launched with the default browser on device. If set to true, the URL
/// is launched in a WebView. Unlike iOS, browser context is shared across
/// WebViews.
/// [enableJavaScript] is an Android only setting. If true, WebView enable
/// javascript.
/// [enableDomStorage] is an Android only setting. If true, WebView enable
/// DOM storage.
/// [headers] is an Android only setting that adds headers to the WebView.
/// When not using a WebView, the header information is passed to the browser,
/// some Android browsers do not support the [Browser.EXTRA_HEADERS](https://developer.android.com/reference/android/provider/Browser#EXTRA_HEADERS)
/// intent extra and the header information will be lost.
/// [webOnlyWindowName] is an Web only setting . _blank opens the new url in new tab ,
/// _self opens the new url in current tab.
/// Default behaviour is to open the url in new tab.
///
/// Note that if any of the above are set to true but the URL is not a web URL,
/// this will throw a [PlatformException].
///
/// [statusBarBrightness] Sets the status bar brightness of the application
/// after opening a link on iOS. Does nothing if no value is passed. This does
/// not handle resetting the previous status bar style.
///
/// Returns true if launch url is successful; false is only returned when [universalLinksOnly]
/// is set to true and the universal link failed to launch.
@Deprecated('Use launchUrl instead')
Future<bool> launch(
  String urlString, {
  bool? forceSafariVC,
  bool forceWebView = false,
  bool enableJavaScript = false,
  bool enableDomStorage = false,
  bool universalLinksOnly = false,
  Map<String, String> headers = const <String, String>{},
  Brightness? statusBarBrightness,
  String? webOnlyWindowName,
}) async {
  final Uri? url = Uri.tryParse(urlString.trimLeft());
  final bool isWebURL =
      url != null && (url.scheme == 'http' || url.scheme == 'https');

  if ((forceSafariVC ?? false || forceWebView) && !isWebURL) {
    throw PlatformException(
        code: 'NOT_A_WEB_SCHEME',
        message: 'To use webview or safariVC, you need to pass '
            'in a web URL. This $urlString is not a web URL.');
  }

  /// [true] so that ui is automatically computed if [statusBarBrightness] is set.
  bool previousAutomaticSystemUiAdjustment = true;
  if (statusBarBrightness != null &&
      defaultTargetPlatform == TargetPlatform.iOS &&
      _ambiguate(WidgetsBinding.instance) != null) {
    previousAutomaticSystemUiAdjustment = _ambiguate(WidgetsBinding.instance)!
        .renderView
        .automaticSystemUiAdjustment;
    _ambiguate(WidgetsBinding.instance)!
        .renderView
        .automaticSystemUiAdjustment = false;
    SystemChrome.setSystemUIOverlayStyle(statusBarBrightness == Brightness.light
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light);
  }

  final bool result = await UrlLauncherPlatform.instance.launch(
    urlString,
    useSafariVC: forceSafariVC ?? isWebURL,
    useWebView: forceWebView,
    enableJavaScript: enableJavaScript,
    enableDomStorage: enableDomStorage,
    universalLinksOnly: universalLinksOnly,
    headers: headers,
    webOnlyWindowName: webOnlyWindowName,
  );

  if (statusBarBrightness != null &&
      _ambiguate(WidgetsBinding.instance) != null) {
    _ambiguate(WidgetsBinding.instance)!
        .renderView
        .automaticSystemUiAdjustment = previousAutomaticSystemUiAdjustment;
  }

  return result;
}

/// Checks whether the specified URL can be handled by some app installed on the
/// device.
///
/// On some systems, such as recent versions of Android and iOS, this will
/// always return false unless the application has been configuration to allow
/// querying the system for launch support. See
/// [the README](https://pub.dev/packages/url_launcher#configuration) for
/// details.
@Deprecated('Use canLaunchUrl instead')
Future<bool> canLaunch(String urlString) async {
  return await UrlLauncherPlatform.instance.canLaunch(urlString);
}

/// Closes the current WebView, if one was previously opened via a call to [launch].
///
/// If [launch] was never called, then this call will not have any effect.
///
/// On Android systems, if [launch] was called without `forceWebView` being set to `true`
/// Or on IOS systems, if [launch] was called without `forceSafariVC` being set to `true`,
/// this call will not do anything either, simply because there is no
/// WebView/SafariViewController available to be closed.
@Deprecated('Use closeInAppWebView instead')
Future<void> closeWebView() async {
  return await UrlLauncherPlatform.instance.closeWebView();
}

/// This allows a value of type T or T? to be treated as a value of type T?.
///
/// We use this so that APIs that have become non-nullable can still be used
/// with `!` and `?` on the stable branch.
// TODO(ianh): Remove this once we roll stable in late 2021.
T? _ambiguate<T>(T? value) => value;
