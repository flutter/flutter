// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'src/link.dart';
import 'src/shims/dart_ui.dart' as ui;
import 'src/third_party/platform_detect/browser.dart';

const Set<String> _safariTargetTopSchemes = <String>{
  'mailto',
  'tel',
  'sms',
};
String? _getUrlScheme(String url) => Uri.tryParse(url)?.scheme;

bool _isSafariTargetTopScheme(String url) =>
    _safariTargetTopSchemes.contains(_getUrlScheme(url));

/// The web implementation of [UrlLauncherPlatform].
///
/// This class implements the `package:url_launcher` functionality for the web.
class UrlLauncherPlugin extends UrlLauncherPlatform {
  /// A constructor that allows tests to override the window object used by the plugin.
  UrlLauncherPlugin({@visibleForTesting html.Window? debugWindow})
      : _window = debugWindow ?? html.window {
    _isSafari = navigatorIsSafari(_window.navigator);
  }

  final html.Window _window;
  bool _isSafari = false;

  // The set of schemes that can be handled by the plugin
  static final Set<String> _supportedSchemes = <String>{
    'http',
    'https',
  }.union(_safariTargetTopSchemes);

  /// Registers this class as the default instance of [UrlLauncherPlatform].
  static void registerWith(Registrar registrar) {
    UrlLauncherPlatform.instance = UrlLauncherPlugin();
    ui.platformViewRegistry
        .registerViewFactory(linkViewType, linkViewFactory, isVisible: false);
  }

  @override
  LinkDelegate get linkDelegate {
    return (LinkInfo linkInfo) => WebLinkDelegate(linkInfo);
  }

  /// Opens the given [url] in the specified [webOnlyWindowName].
  ///
  /// Returns the newly created window.
  @visibleForTesting
  html.WindowBase openNewWindow(String url, {String? webOnlyWindowName}) {
    // We need to open mailto, tel and sms urls on the _top window context on safari browsers.
    // See https://github.com/flutter/flutter/issues/51461 for reference.
    final String target = webOnlyWindowName ??
        ((_isSafari && _isSafariTargetTopScheme(url)) ? '_top' : '');
    // ignore: unsafe_html
    return _window.open(url, target);
  }

  @override
  Future<bool> canLaunch(String url) {
    return Future<bool>.value(_supportedSchemes.contains(_getUrlScheme(url)));
  }

  @override
  Future<bool> launch(
    String url, {
    bool useSafariVC = false,
    bool useWebView = false,
    bool enableJavaScript = false,
    bool enableDomStorage = false,
    bool universalLinksOnly = false,
    Map<String, String> headers = const <String, String>{},
    String? webOnlyWindowName,
  }) {
    return Future<bool>.value(
        openNewWindow(url, webOnlyWindowName: webOnlyWindowName) != null);
  }
}
