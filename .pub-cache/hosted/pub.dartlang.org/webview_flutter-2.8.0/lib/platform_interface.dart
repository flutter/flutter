// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Re-export the classes from the webview_flutter_platform_interface through
/// the `platform_interface.dart` file so we don't accidentally break any
/// non-endorsed existing implementations of the interface.
export 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart'
    show
        AutoMediaPlaybackPolicy,
        CreationParams,
        JavascriptChannel,
        JavascriptChannelRegistry,
        JavascriptMessage,
        JavascriptMode,
        JavascriptMessageHandler,
        WebViewPlatform,
        WebViewPlatformCallbacksHandler,
        WebViewPlatformController,
        WebViewPlatformCreatedCallback,
        WebSetting,
        WebSettings,
        WebResourceError,
        WebResourceErrorType,
        WebViewCookie,
        WebViewRequest,
        WebViewRequestMethod;
