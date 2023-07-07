// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'types.dart';

/// Converts an (app-facing) [WebViewConfiguration] to a (platform interface)
/// [InAppWebViewConfiguration].
InAppWebViewConfiguration convertConfiguration(WebViewConfiguration config) {
  return InAppWebViewConfiguration(
    enableJavaScript: config.enableJavaScript,
    enableDomStorage: config.enableDomStorage,
    headers: config.headers,
  );
}

/// Converts an (app-facing) [LaunchMode] to a (platform interface)
/// [PreferredLaunchMode].
PreferredLaunchMode convertLaunchMode(LaunchMode mode) {
  switch (mode) {
    case LaunchMode.platformDefault:
      return PreferredLaunchMode.platformDefault;
    case LaunchMode.inAppWebView:
      return PreferredLaunchMode.inAppWebView;
    case LaunchMode.externalApplication:
      return PreferredLaunchMode.externalApplication;
    case LaunchMode.externalNonBrowserApplication:
      return PreferredLaunchMode.externalNonBrowserApplication;
  }
}
