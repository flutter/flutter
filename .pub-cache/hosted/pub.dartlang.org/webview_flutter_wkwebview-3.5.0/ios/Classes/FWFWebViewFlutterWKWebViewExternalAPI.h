// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>
#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * App and package facing native API provided by the `webview_flutter_wkwebview` plugin.
 *
 * This class follows the convention of breaking changes of the Dart API, which means that any
 * changes to the class that are not backwards compatible will only be made with a major version
 * change of the plugin. Native code other than this external API does not follow breaking change
 * conventions, so app or plugin clients should not use any other native APIs.
 */
@interface FWFWebViewFlutterWKWebViewExternalAPI : NSObject
/**
 * Retrieves the `WKWebView` that is associated with `identifier`.
 *
 * See the Dart method `WebKitWebViewController.webViewIdentifier` to get the identifier of an
 * underlying `WKWebView`.
 *
 * @param identifier The associated identifier of the `WebView`.
 * @param registry The plugin registry the `FLTWebViewFlutterPlugin` should belong to. If
 *        the registry doesn't contain an attached instance of `FLTWebViewFlutterPlugin`,
 *        this method returns nil.
 * @return The `WKWebView` associated with `identifier` or nil if a `WKWebView` instance associated
 * with `identifier` could not be found.
 */
+ (nullable WKWebView *)webViewForIdentifier:(long)identifier
                          withPluginRegistry:(id<FlutterPluginRegistry>)registry;
@end

NS_ASSUME_NONNULL_END
