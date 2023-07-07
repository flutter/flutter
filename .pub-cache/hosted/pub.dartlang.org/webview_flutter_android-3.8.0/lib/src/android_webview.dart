// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show BinaryMessenger;

import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;

import 'android_webview.g.dart';
import 'android_webview_api_impls.dart';
import 'instance_manager.dart';

export 'android_webview_api_impls.dart' show FileChooserMode;

/// Root of the Java class hierarchy.
///
/// See https://docs.oracle.com/javase/8/docs/api/java/lang/Object.html.
class JavaObject with Copyable {
  /// Constructs a [JavaObject] without creating the associated Java object.
  ///
  /// This should only be used by subclasses created by this library or to
  /// create copies.
  @protected
  JavaObject.detached({
    BinaryMessenger? binaryMessenger,
    InstanceManager? instanceManager,
  }) : _api = JavaObjectHostApiImpl(
          binaryMessenger: binaryMessenger,
          instanceManager: instanceManager,
        );

  /// Global instance of [InstanceManager].
  static final InstanceManager globalInstanceManager = _initInstanceManager();

  static InstanceManager _initInstanceManager() {
    WidgetsFlutterBinding.ensureInitialized();
    // Clears the native `InstanceManager` on initial use of the Dart one.
    InstanceManagerHostApi().clear();
    return InstanceManager(
      onWeakReferenceRemoved: (int identifier) {
        JavaObjectHostApiImpl().dispose(identifier);
      },
    );
  }

  /// Pigeon Host Api implementation for [JavaObject].
  final JavaObjectHostApiImpl _api;

  /// Release the reference to a native Java instance.
  static void dispose(JavaObject instance) {
    instance._api.instanceManager.removeWeakReference(instance);
  }

  @override
  JavaObject copy() {
    return JavaObject.detached();
  }
}

/// A callback interface used by the host application to set the Geolocation
/// permission state for an origin.
///
/// See https://developer.android.com/reference/android/webkit/GeolocationPermissions.Callback.
@immutable
class GeolocationPermissionsCallback extends JavaObject {
  /// Instantiates a [GeolocationPermissionsCallback] without creating and
  /// attaching to an instance of the associated native class.
  ///
  /// This should only be used outside of tests by subclasses created by this
  /// library or to create a copy.
  @protected
  GeolocationPermissionsCallback.detached({
    super.binaryMessenger,
    super.instanceManager,
  })  : _geolocationPermissionsCallbackApi =
            GeolocationPermissionsCallbackHostApiImpl(
          binaryMessenger: binaryMessenger,
          instanceManager: instanceManager,
        ),
        super.detached();

  final GeolocationPermissionsCallbackHostApiImpl
      _geolocationPermissionsCallbackApi;

  /// Sets the Geolocation permission state for the supplied origin.
  ///
  /// [origin]: The origin for which permissions are set.
  ///
  /// [allow]: Whether or not the origin should be allowed to use the Geolocation API.
  ///
  /// [retain]: Whether the permission should be retained beyond the lifetime of
  /// a page currently being displayed by a WebView.
  Future<void> invoke(String origin, bool allow, bool retain) {
    return _geolocationPermissionsCallbackApi.invokeFromInstances(
      this,
      origin,
      allow,
      retain,
    );
  }

  @override
  GeolocationPermissionsCallback copy() {
    return GeolocationPermissionsCallback.detached(
      binaryMessenger: _geolocationPermissionsCallbackApi.binaryMessenger,
      instanceManager: _geolocationPermissionsCallbackApi.instanceManager,
    );
  }
}

/// An Android View that displays web pages.
///
/// **Basic usage**
/// In most cases, we recommend using a standard web browser, like Chrome, to
/// deliver content to the user. To learn more about web browsers, read the
/// guide on invoking a browser with
/// [url_launcher](https://pub.dev/packages/url_launcher).
///
/// WebView objects allow you to display web content as part of your widget
/// layout, but lack some of the features of fully-developed browsers. A WebView
/// is useful when you need increased control over the UI and advanced
/// configuration options that will allow you to embed web pages in a
/// specially-designed environment for your app.
///
/// To learn more about WebView and alternatives for serving web content, read
/// the documentation on
/// [Web-based content](https://developer.android.com/guide/webapps).
///
/// When a [WebView] is no longer needed [release] must be called.
class WebView extends JavaObject {
  /// Constructs a new WebView.
  ///
  /// Due to changes in Flutter 3.0 the [useHybridComposition] doesn't have
  /// any effect and should not be exposed publicly. More info here:
  /// https://github.com/flutter/flutter/issues/108106
  WebView({
    @visibleForTesting super.binaryMessenger,
    @visibleForTesting super.instanceManager,
  }) : super.detached() {
    api.createFromInstance(this);
  }

  /// Constructs a [WebView] without creating the associated Java object.
  ///
  /// This should only be used by subclasses created by this library or to
  /// create copies.
  @protected
  WebView.detached({
    super.binaryMessenger,
    super.instanceManager,
  }) : super.detached();

  /// Pigeon Host Api implementation for [WebView].
  @visibleForTesting
  static WebViewHostApiImpl api = WebViewHostApiImpl();

  /// The [WebSettings] object used to control the settings for this WebView.
  late final WebSettings settings = WebSettings(this);

  /// Enables debugging of web contents (HTML / CSS / JavaScript) loaded into any WebViews of this application.
  ///
  /// This flag can be enabled in order to facilitate debugging of web layouts
  /// and JavaScript code running inside WebViews. Please refer to [WebView]
  /// documentation for the debugging guide. The default is false.
  static Future<void> setWebContentsDebuggingEnabled(bool enabled) {
    return api.setWebContentsDebuggingEnabled(enabled);
  }

  /// Loads the given data into this WebView using a 'data' scheme URL.
  ///
  /// Note that JavaScript's same origin policy means that script running in a
  /// page loaded using this method will be unable to access content loaded
  /// using any scheme other than 'data', including 'http(s)'. To avoid this
  /// restriction, use [loadDataWithBaseURL()] with an appropriate base URL.
  ///
  /// The [encoding] parameter specifies whether the data is base64 or URL
  /// encoded. If the data is base64 encoded, the value of the encoding
  /// parameter must be `'base64'`. HTML can be encoded with
  /// `base64.encode(bytes)` like so:
  /// ```dart
  /// import 'dart:convert';
  ///
  /// final unencodedHtml = '''
  ///   <html><body>'%28' is the code for '('</body></html>
  /// ''';
  /// final encodedHtml = base64.encode(utf8.encode(unencodedHtml));
  /// print(encodedHtml);
  /// ```
  ///
  /// The [mimeType] parameter specifies the format of the data. If WebView
  /// can't handle the specified MIME type, it will download the data. If
  /// `null`, defaults to 'text/html'.
  Future<void> loadData({
    required String data,
    String? mimeType,
    String? encoding,
  }) {
    return api.loadDataFromInstance(
      this,
      data,
      mimeType,
      encoding,
    );
  }

  /// Loads the given data into this WebView.
  ///
  /// The [baseUrl] is used as base URL for the content. It is used  both to
  /// resolve relative URLs and when applying JavaScript's same origin policy.
  ///
  /// The [historyUrl] is used for the history entry.
  ///
  /// The [mimeType] parameter specifies the format of the data. If WebView
  /// can't handle the specified MIME type, it will download the data. If
  /// `null`, defaults to 'text/html'.
  ///
  /// Note that content specified in this way can access local device files (via
  /// 'file' scheme URLs) only if baseUrl specifies a scheme other than 'http',
  /// 'https', 'ftp', 'ftps', 'about' or 'javascript'.
  ///
  /// If the base URL uses the data scheme, this method is equivalent to calling
  /// [loadData] and the [historyUrl] is ignored, and the data will be treated
  /// as part of a data: URL, including the requirement that the content be
  /// URL-encoded or base64 encoded. If the base URL uses any other scheme, then
  /// the data will be loaded into the WebView as a plain string (i.e. not part
  /// of a data URL) and any URL-encoded entities in the string will not be
  /// decoded.
  ///
  /// Note that the [baseUrl] is sent in the 'Referer' HTTP header when
  /// requesting subresources (images, etc.) of the page loaded using this
  /// method.
  ///
  /// If a valid HTTP or HTTPS base URL is not specified in [baseUrl], then
  /// content loaded using this method will have a `window.origin` value of
  /// `"null"`. This must not be considered to be a trusted origin by the
  /// application or by any JavaScript code running inside the WebView (for
  /// example, event sources in DOM event handlers or web messages), because
  /// malicious content can also create frames with a null origin. If you need
  /// to identify the main frame's origin in a trustworthy way, you should use a
  /// valid HTTP or HTTPS base URL to set the origin.
  Future<void> loadDataWithBaseUrl({
    String? baseUrl,
    required String data,
    String? mimeType,
    String? encoding,
    String? historyUrl,
  }) {
    return api.loadDataWithBaseUrlFromInstance(
      this,
      baseUrl,
      data,
      mimeType,
      encoding,
      historyUrl,
    );
  }

  /// Loads the given URL with additional HTTP headers, specified as a map from name to value.
  ///
  /// Note that if this map contains any of the headers that are set by default
  /// by this WebView, such as those controlling caching, accept types or the
  /// User-Agent, their values may be overridden by this WebView's defaults.
  ///
  /// Also see compatibility note on [evaluateJavascript].
  Future<void> loadUrl(String url, Map<String, String> headers) {
    return api.loadUrlFromInstance(this, url, headers);
  }

  /// Loads the URL with postData using "POST" method into this WebView.
  ///
  /// If url is not a network URL, it will be loaded with [loadUrl] instead, ignoring the postData param.
  Future<void> postUrl(String url, Uint8List data) {
    return api.postUrlFromInstance(this, url, data);
  }

  /// Gets the URL for the current page.
  ///
  /// This is not always the same as the URL passed to
  /// [WebViewClient.onPageStarted] because although the load for that URL has
  /// begun, the current page may not have changed.
  ///
  /// Returns null if no page has been loaded.
  Future<String?> getUrl() {
    return api.getUrlFromInstance(this);
  }

  /// Whether this WebView has a back history item.
  Future<bool> canGoBack() {
    return api.canGoBackFromInstance(this);
  }

  /// Whether this WebView has a forward history item.
  Future<bool> canGoForward() {
    return api.canGoForwardFromInstance(this);
  }

  /// Goes back in the history of this WebView.
  Future<void> goBack() {
    return api.goBackFromInstance(this);
  }

  /// Goes forward in the history of this WebView.
  Future<void> goForward() {
    return api.goForwardFromInstance(this);
  }

  /// Reloads the current URL.
  Future<void> reload() {
    return api.reloadFromInstance(this);
  }

  /// Clears the resource cache.
  ///
  /// Note that the cache is per-application, so this will clear the cache for
  /// all WebViews used.
  Future<void> clearCache(bool includeDiskFiles) {
    return api.clearCacheFromInstance(this, includeDiskFiles);
  }

  // TODO(bparrishMines): Update documentation once addJavascriptInterface is added.
  /// Asynchronously evaluates JavaScript in the context of the currently displayed page.
  ///
  /// If non-null, the returned value will be any result returned from that
  /// execution.
  ///
  /// Compatibility note. Applications targeting Android versions N or later,
  /// JavaScript state from an empty WebView is no longer persisted across
  /// navigations like [loadUrl]. For example, global variables and functions
  /// defined before calling [loadUrl]) will not exist in the loaded page.
  Future<String?> evaluateJavascript(String javascriptString) {
    return api.evaluateJavascriptFromInstance(
      this,
      javascriptString,
    );
  }

  // TODO(bparrishMines): Update documentation when WebViewClient.onReceivedTitle is added.
  /// Gets the title for the current page.
  ///
  /// Returns null if no page has been loaded.
  Future<String?> getTitle() {
    return api.getTitleFromInstance(this);
  }

  // TODO(bparrishMines): Update documentation when onScrollChanged is added.
  /// Set the scrolled position of your view.
  Future<void> scrollTo(int x, int y) {
    return api.scrollToFromInstance(this, x, y);
  }

  // TODO(bparrishMines): Update documentation when onScrollChanged is added.
  /// Move the scrolled position of your view.
  Future<void> scrollBy(int x, int y) {
    return api.scrollByFromInstance(this, x, y);
  }

  /// Return the scrolled left position of this view.
  ///
  /// This is the left edge of the displayed part of your view. You do not
  /// need to draw any pixels farther left, since those are outside of the frame
  /// of your view on screen.
  Future<int> getScrollX() {
    return api.getScrollXFromInstance(this);
  }

  /// Return the scrolled top position of this view.
  ///
  /// This is the top edge of the displayed part of your view. You do not need
  /// to draw any pixels above it, since those are outside of the frame of your
  /// view on screen.
  Future<int> getScrollY() {
    return api.getScrollYFromInstance(this);
  }

  /// Returns the X and Y scroll position of this view.
  Future<Offset> getScrollPosition() {
    return api.getScrollPositionFromInstance(this);
  }

  /// Sets the [WebViewClient] that will receive various notifications and requests.
  ///
  /// This will replace the current handler.
  Future<void> setWebViewClient(WebViewClient webViewClient) {
    return api.setWebViewClientFromInstance(this, webViewClient);
  }

  /// Injects the supplied [JavascriptChannel] into this WebView.
  ///
  /// The object is injected into all frames of the web page, including all the
  /// iframes, using the supplied name. This allows the object's methods to
  /// be accessed from JavaScript.
  ///
  /// Note that injected objects will not appear in JavaScript until the page is
  /// next (re)loaded. JavaScript should be enabled before injecting the object.
  /// For example:
  ///
  /// ```dart
  /// webview.settings.setJavaScriptEnabled(true);
  /// webView.addJavascriptChannel(JavScriptChannel("injectedObject"));
  /// webView.loadUrl("about:blank", <String, String>{});
  /// webView.loadUrl("javascript:injectedObject.postMessage("Hello, World!")", <String, String>{});
  /// ```
  ///
  /// **Important**
  /// * Because the object is exposed to all the frames, any frame could obtain
  /// the object name and call methods on it. There is no way to tell the
  /// calling frame's origin from the app side, so the app must not assume that
  /// the caller is trustworthy unless the app can guarantee that no third party
  /// content is ever loaded into the WebView even inside an iframe.
  Future<void> addJavaScriptChannel(JavaScriptChannel javaScriptChannel) {
    JavaScriptChannel.api.createFromInstance(javaScriptChannel);
    return api.addJavaScriptChannelFromInstance(this, javaScriptChannel);
  }

  /// Removes a previously injected [JavaScriptChannel] from this WebView.
  ///
  /// Note that the removal will not be reflected in JavaScript until the page
  /// is next (re)loaded. See [addJavaScriptChannel].
  Future<void> removeJavaScriptChannel(JavaScriptChannel javaScriptChannel) {
    JavaScriptChannel.api.createFromInstance(javaScriptChannel);
    return api.removeJavaScriptChannelFromInstance(this, javaScriptChannel);
  }

  /// Registers the interface to be used when content can not be handled by the rendering engine, and should be downloaded instead.
  ///
  /// This will replace the current handler.
  Future<void> setDownloadListener(DownloadListener? listener) {
    return api.setDownloadListenerFromInstance(this, listener);
  }

  /// Sets the chrome handler.
  ///
  /// This is an implementation of [WebChromeClient] for use in handling
  /// JavaScript dialogs, favicons, titles, and the progress. This will replace
  /// the current handler.
  Future<void> setWebChromeClient(WebChromeClient? client) {
    return api.setWebChromeClientFromInstance(this, client);
  }

  /// Sets the background color of this WebView.
  Future<void> setBackgroundColor(Color color) {
    return api.setBackgroundColorFromInstance(this, color.value);
  }

  @override
  WebView copy() {
    return WebView.detached(
      binaryMessenger: _api.binaryMessenger,
      instanceManager: _api.instanceManager,
    );
  }
}

/// Manages cookies globally for all webviews.
///
/// See https://developer.android.com/reference/android/webkit/CookieManager.
class CookieManager extends JavaObject {
  /// Instantiates a [CookieManager] without creating and attaching to an
  /// instance of the associated native class.
  ///
  /// This should only be used outside of tests by subclasses created by this
  /// library or to create a copy for an [InstanceManager].
  @protected
  CookieManager.detached({super.binaryMessenger, super.instanceManager})
      : _cookieManagerApi = CookieManagerHostApiImpl(
          binaryMessenger: binaryMessenger,
          instanceManager: instanceManager,
        ),
        super.detached();

  static final CookieManager _instance =
      CookieManagerHostApiImpl().attachInstanceFromInstances(
    CookieManager.detached(),
  );

  final CookieManagerHostApiImpl _cookieManagerApi;

  /// Access a static field synchronously.
  static CookieManager get instance {
    AndroidWebViewFlutterApis.instance.ensureSetUp();
    return _instance;
  }

  /// Sets a single cookie (key-value pair) for the given URL. Any existing
  /// cookie with the same host, path and name will be replaced with the new
  /// cookie. The cookie being set will be ignored if it is expired. To set
  /// multiple cookies, your application should invoke this method multiple
  /// times.
  ///
  /// The value parameter must follow the format of the Set-Cookie HTTP
  /// response header defined by RFC6265bis. This is a key-value pair of the
  /// form "key=value", optionally followed by a list of cookie attributes
  /// delimited with semicolons (ex. "key=value; Max-Age=123"). Please consult
  /// the RFC specification for a list of valid attributes.
  ///
  /// Note: if specifying a value containing the "Secure" attribute, url must
  /// use the "https://" scheme.
  ///
  /// Params:
  /// url – the URL for which the cookie is to be set
  /// value – the cookie as a string, using the format of the 'Set-Cookie' HTTP response header
  Future<void> setCookie(String url, String value) {
    return _cookieManagerApi.setCookieFromInstances(this, url, value);
  }

  /// Removes all cookies.
  ///
  /// The returned future resolves to true if any cookies were removed.
  Future<bool> removeAllCookies() {
    return _cookieManagerApi.removeAllCookiesFromInstances(this);
  }

  /// Sets whether the WebView should allow third party cookies to be set.
  ///
  /// Apps that target `Build.VERSION_CODES.KITKAT` or below default to allowing
  /// third party cookies. Apps targeting `Build.VERSION_CODES.LOLLIPOP` or
  /// later default to disallowing third party cookies.
  Future<void> setAcceptThirdPartyCookies(WebView webView, bool accept) {
    return _cookieManagerApi.setAcceptThirdPartyCookiesFromInstances(
      this,
      webView,
      accept,
    );
  }

  @override
  CookieManager copy() {
    return CookieManager.detached(
      binaryMessenger: _cookieManagerApi.binaryMessenger,
      instanceManager: _cookieManagerApi.instanceManager,
    );
  }
}

/// Manages settings state for a [WebView].
///
/// When a WebView is first created, it obtains a set of default settings. These
/// default settings will be returned from any getter call. A WebSettings object
/// obtained from [WebView.settings] is tied to the life of the WebView. If a
/// WebView has been destroyed, any method call on [WebSettings] will throw an
/// Exception.
class WebSettings extends JavaObject {
  /// Constructs a [WebSettings].
  ///
  /// This constructor is only used for testing. An instance should be obtained
  /// with [WebView.settings].
  @visibleForTesting
  WebSettings(
    WebView webView, {
    @visibleForTesting super.binaryMessenger,
    @visibleForTesting super.instanceManager,
  }) : super.detached() {
    api.createFromInstance(this, webView);
  }

  /// Constructs a [WebSettings] without creating the associated Java object.
  ///
  /// This should only be used by subclasses created by this library or to
  /// create copies.
  @protected
  WebSettings.detached({
    super.binaryMessenger,
    super.instanceManager,
  }) : super.detached();

  /// Pigeon Host Api implementation for [WebSettings].
  @visibleForTesting
  static WebSettingsHostApiImpl api = WebSettingsHostApiImpl();

  /// Sets whether the DOM storage API is enabled.
  ///
  /// The default value is false.
  Future<void> setDomStorageEnabled(bool flag) {
    return api.setDomStorageEnabledFromInstance(this, flag);
  }

  /// Tells JavaScript to open windows automatically.
  ///
  /// This applies to the JavaScript function `window.open()`. The default is
  /// false.
  Future<void> setJavaScriptCanOpenWindowsAutomatically(bool flag) {
    return api.setJavaScriptCanOpenWindowsAutomaticallyFromInstance(
      this,
      flag,
    );
  }

  // TODO(bparrishMines): Update documentation when WebChromeClient.onCreateWindow is added.
  /// Sets whether the WebView should supports multiple windows.
  ///
  /// The default is false.
  Future<void> setSupportMultipleWindows(bool support) {
    return api.setSupportMultipleWindowsFromInstance(this, support);
  }

  /// Tells the WebView to enable JavaScript execution.
  ///
  /// The default is false.
  Future<void> setJavaScriptEnabled(bool flag) {
    return api.setJavaScriptEnabledFromInstance(this, flag);
  }

  /// Sets the WebView's user-agent string.
  ///
  /// If the string is empty, the system default value will be used. Note that
  /// starting from KITKAT Android version, changing the user-agent while
  /// loading a web page causes WebView to initiate loading once again.
  Future<void> setUserAgentString(String? userAgentString) {
    return api.setUserAgentStringFromInstance(this, userAgentString);
  }

  /// Sets whether the WebView requires a user gesture to play media.
  ///
  /// The default is true.
  Future<void> setMediaPlaybackRequiresUserGesture(bool require) {
    return api.setMediaPlaybackRequiresUserGestureFromInstance(this, require);
  }

  // TODO(bparrishMines): Update documentation when WebView.zoomIn and WebView.zoomOut are added.
  /// Sets whether the WebView should support zooming using its on-screen zoom controls and gestures.
  ///
  /// The particular zoom mechanisms that should be used can be set with
  /// [setBuiltInZoomControls].
  ///
  /// The default is true.
  Future<void> setSupportZoom(bool support) {
    return api.setSupportZoomFromInstance(this, support);
  }

  /// Sets whether the WebView loads pages in overview mode, that is, zooms out the content to fit on screen by width.
  ///
  /// This setting is taken into account when the content width is greater than
  /// the width of the WebView control, for example, when [setUseWideViewPort]
  /// is enabled.
  ///
  /// The default is false.
  Future<void> setLoadWithOverviewMode(bool overview) {
    return api.setLoadWithOverviewModeFromInstance(this, overview);
  }

  /// Sets whether the WebView should enable support for the "viewport" HTML meta tag or should use a wide viewport.
  ///
  /// When the value of the setting is false, the layout width is always set to
  /// the width of the WebView control in device-independent (CSS) pixels. When
  /// the value is true and the page contains the viewport meta tag, the value
  /// of the width specified in the tag is used. If the page does not contain
  /// the tag or does not provide a width, then a wide viewport will be used.
  Future<void> setUseWideViewPort(bool use) {
    return api.setUseWideViewPortFromInstance(this, use);
  }

  // TODO(bparrishMines): Update documentation when ZoomButtonsController is added.
  /// Sets whether the WebView should display on-screen zoom controls when using the built-in zoom mechanisms.
  ///
  /// See [setBuiltInZoomControls]. The default is true. However, on-screen zoom
  /// controls are deprecated in Android so it's recommended to set this to
  /// false.
  Future<void> setDisplayZoomControls(bool enabled) {
    return api.setDisplayZoomControlsFromInstance(this, enabled);
  }

  // TODO(bparrishMines): Update documentation when ZoomButtonsController is added.
  /// Sets whether the WebView should use its built-in zoom mechanisms.
  ///
  /// The built-in zoom mechanisms comprise on-screen zoom controls, which are
  /// displayed over the WebView's content, and the use of a pinch gesture to
  /// control zooming. Whether or not these on-screen controls are displayed can
  /// be set with [setDisplayZoomControls]. The default is false.
  ///
  /// The built-in mechanisms are the only currently supported zoom mechanisms,
  /// so it is recommended that this setting is always enabled. However,
  /// on-screen zoom controls are deprecated in Android so it's recommended to
  /// disable [setDisplayZoomControls].
  Future<void> setBuiltInZoomControls(bool enabled) {
    return api.setBuiltInZoomControlsFromInstance(this, enabled);
  }

  /// Enables or disables file access within WebView.
  ///
  /// This enables or disables file system access only. Assets and resources are
  /// still accessible using file:///android_asset and file:///android_res. The
  /// default value is true for apps targeting Build.VERSION_CODES.Q and below,
  /// and false when targeting Build.VERSION_CODES.R and above.
  Future<void> setAllowFileAccess(bool enabled) {
    return api.setAllowFileAccessFromInstance(this, enabled);
  }

  /// Sets the text zoom of the page in percent.
  ///
  /// The default is 100. See https://developer.android.com/reference/android/webkit/WebSettings#setTextZoom(int)
  Future<void> setTextZoom(int textZoom) {
    return api.setSetTextZoomFromInstance(this, textZoom);
  }

  @override
  WebSettings copy() {
    return WebSettings.detached(
      binaryMessenger: _api.binaryMessenger,
      instanceManager: _api.instanceManager,
    );
  }
}

/// Exposes a channel to receive calls from javaScript.
///
/// See [WebView.addJavaScriptChannel].
class JavaScriptChannel extends JavaObject {
  /// Constructs a [JavaScriptChannel].
  JavaScriptChannel(
    this.channelName, {
    required this.postMessage,
    @visibleForTesting super.binaryMessenger,
    @visibleForTesting super.instanceManager,
  }) : super.detached() {
    AndroidWebViewFlutterApis.instance.ensureSetUp();
    api.createFromInstance(this);
  }

  /// Constructs a [JavaScriptChannel] without creating the associated Java
  /// object.
  ///
  /// This should only be used by subclasses created by this library or to
  /// create copies.
  @protected
  JavaScriptChannel.detached(
    this.channelName, {
    required this.postMessage,
    super.binaryMessenger,
    super.instanceManager,
  }) : super.detached();

  /// Pigeon Host Api implementation for [JavaScriptChannel].
  @visibleForTesting
  static JavaScriptChannelHostApiImpl api = JavaScriptChannelHostApiImpl();

  /// Used to identify this object to receive messages from javaScript.
  final String channelName;

  /// Callback method when javaScript calls `postMessage` on the object instance passed.
  final void Function(String message) postMessage;

  @override
  JavaScriptChannel copy() {
    return JavaScriptChannel.detached(
      channelName,
      postMessage: postMessage,
      binaryMessenger: _api.binaryMessenger,
      instanceManager: _api.instanceManager,
    );
  }
}

/// Receive various notifications and requests for [WebView].
class WebViewClient extends JavaObject {
  /// Constructs a [WebViewClient].
  WebViewClient({
    this.onPageStarted,
    this.onPageFinished,
    this.onReceivedRequestError,
    @Deprecated('Only called on Android version < 23.') this.onReceivedError,
    this.requestLoading,
    this.urlLoading,
    this.doUpdateVisitedHistory,
    @visibleForTesting super.binaryMessenger,
    @visibleForTesting super.instanceManager,
  }) : super.detached() {
    AndroidWebViewFlutterApis.instance.ensureSetUp();
    api.createFromInstance(this);
  }

  /// Constructs a [WebViewClient] without creating the associated Java object.
  ///
  /// This should only be used by subclasses created by this library or to
  /// create copies.
  @protected
  WebViewClient.detached({
    this.onPageStarted,
    this.onPageFinished,
    this.onReceivedRequestError,
    @Deprecated('Only called on Android version < 23.') this.onReceivedError,
    this.requestLoading,
    this.urlLoading,
    this.doUpdateVisitedHistory,
    super.binaryMessenger,
    super.instanceManager,
  }) : super.detached();

  /// User authentication failed on server.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_AUTHENTICATION
  static const int errorAuthentication = -4;

  /// Malformed URL.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_BAD_URL
  static const int errorBadUrl = -12;

  /// Failed to connect to the server.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_CONNECT
  static const int errorConnect = -6;

  /// Failed to perform SSL handshake.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_FAILED_SSL_HANDSHAKE
  static const int errorFailedSslHandshake = -11;

  /// Generic file error.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_FILE
  static const int errorFile = -13;

  /// File not found.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_FILE_NOT_FOUND
  static const int errorFileNotFound = -14;

  /// Server or proxy hostname lookup failed.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_HOST_LOOKUP
  static const int errorHostLookup = -2;

  /// Failed to read or write to the server.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_IO
  static const int errorIO = -7;

  /// User authentication failed on proxy.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_PROXY_AUTHENTICATION
  static const int errorProxyAuthentication = -5;

  /// Too many redirects.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_REDIRECT_LOOP
  static const int errorRedirectLoop = -9;

  /// Connection timed out.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_TIMEOUT
  static const int errorTimeout = -8;

  /// Too many requests during this load.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_TOO_MANY_REQUESTS
  static const int errorTooManyRequests = -15;

  /// Generic error.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_UNKNOWN
  static const int errorUnknown = -1;

  /// Resource load was canceled by Safe Browsing.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_UNSAFE_RESOURCE
  static const int errorUnsafeResource = -16;

  /// Unsupported authentication scheme (not basic or digest).
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_UNSUPPORTED_AUTH_SCHEME
  static const int errorUnsupportedAuthScheme = -3;

  /// Unsupported URI scheme.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_UNSUPPORTED_SCHEME
  static const int errorUnsupportedScheme = -10;

  /// Pigeon Host Api implementation for [WebViewClient].
  @visibleForTesting
  static WebViewClientHostApiImpl api = WebViewClientHostApiImpl();

  /// Notify the host application that a page has started loading.
  ///
  /// This method is called once for each main frame load so a page with iframes
  /// or framesets will call onPageStarted one time for the main frame. This
  /// also means that [onPageStarted] will not be called when the contents of an
  /// embedded frame changes, i.e. clicking a link whose target is an iframe, it
  /// will also not be called for fragment navigations (navigations to
  /// #fragment_id).
  final void Function(WebView webView, String url)? onPageStarted;

  // TODO(bparrishMines): Update documentation when WebView.postVisualStateCallback is added.
  /// Notify the host application that a page has finished loading.
  ///
  /// This method is called only for main frame. Receiving an [onPageFinished]
  /// callback does not guarantee that the next frame drawn by WebView will
  /// reflect the state of the DOM at this point.
  final void Function(WebView webView, String url)? onPageFinished;

  /// Report web resource loading error to the host application.
  ///
  /// These errors usually indicate inability to connect to the server. Note
  /// that unlike the deprecated version of the callback, the new version will
  /// be called for any resource (iframe, image, etc.), not just for the main
  /// page. Thus, it is recommended to perform minimum required work in this
  /// callback.
  final void Function(
    WebView webView,
    WebResourceRequest request,
    WebResourceError error,
  )? onReceivedRequestError;

  /// Report an error to the host application.
  ///
  /// These errors are unrecoverable (i.e. the main resource is unavailable).
  /// The errorCode parameter corresponds to one of the error* constants.
  @Deprecated('Only called on Android version < 23.')
  final void Function(
    WebView webView,
    int errorCode,
    String description,
    String failingUrl,
  )? onReceivedError;

  /// When the current [WebView] wants to load a URL.
  ///
  /// The value set by [setSynchronousReturnValueForShouldOverrideUrlLoading]
  /// indicates whether the [WebView] loaded the request.
  final void Function(WebView webView, WebResourceRequest request)?
      requestLoading;

  /// When the current [WebView] wants to load a URL.
  ///
  /// The value set by [setSynchronousReturnValueForShouldOverrideUrlLoading]
  /// indicates whether the [WebView] loaded the URL.
  final void Function(WebView webView, String url)? urlLoading;

  /// Notify the host application to update its visited links database.
  final void Function(WebView webView, String url, bool isReload)?
      doUpdateVisitedHistory;

  /// Sets the required synchronous return value for the Java method,
  /// `WebViewClient.shouldOverrideUrlLoading(...)`.
  ///
  /// The Java method, `WebViewClient.shouldOverrideUrlLoading(...)`, requires
  /// a boolean to be returned and this method sets the returned value for all
  /// calls to the Java method.
  ///
  /// Setting this to true causes the current [WebView] to abort loading any URL
  /// received by [requestLoading] or [urlLoading], while setting this to false
  /// causes the [WebView] to continue loading a URL as usual.
  ///
  /// Defaults to false.
  Future<void> setSynchronousReturnValueForShouldOverrideUrlLoading(
    bool value,
  ) {
    return api.setShouldOverrideUrlLoadingReturnValueFromInstance(this, value);
  }

  @override
  WebViewClient copy() {
    return WebViewClient.detached(
      onPageStarted: onPageStarted,
      onPageFinished: onPageFinished,
      onReceivedRequestError: onReceivedRequestError,
      onReceivedError: onReceivedError,
      requestLoading: requestLoading,
      urlLoading: urlLoading,
      doUpdateVisitedHistory: doUpdateVisitedHistory,
      binaryMessenger: _api.binaryMessenger,
      instanceManager: _api.instanceManager,
    );
  }
}

/// The interface to be used when content can not be handled by the rendering
/// engine for [WebView], and should be downloaded instead.
class DownloadListener extends JavaObject {
  /// Constructs a [DownloadListener].
  DownloadListener({
    required this.onDownloadStart,
    @visibleForTesting super.binaryMessenger,
    @visibleForTesting super.instanceManager,
  }) : super.detached() {
    AndroidWebViewFlutterApis.instance.ensureSetUp();
    api.createFromInstance(this);
  }

  /// Constructs a [DownloadListener] without creating the associated Java
  /// object.
  ///
  /// This should only be used by subclasses created by this library or to
  /// create copies.
  @protected
  DownloadListener.detached({
    required this.onDownloadStart,
    super.binaryMessenger,
    super.instanceManager,
  }) : super.detached();

  /// Pigeon Host Api implementation for [DownloadListener].
  @visibleForTesting
  static DownloadListenerHostApiImpl api = DownloadListenerHostApiImpl();

  /// Notify the host application that a file should be downloaded.
  final void Function(
    String url,
    String userAgent,
    String contentDisposition,
    String mimetype,
    int contentLength,
  ) onDownloadStart;

  @override
  DownloadListener copy() {
    return DownloadListener.detached(
      onDownloadStart: onDownloadStart,
      binaryMessenger: _api.binaryMessenger,
      instanceManager: _api.instanceManager,
    );
  }
}

/// Responsible for request the Geolocation API.
typedef GeolocationPermissionsShowPrompt = Future<void> Function(
  String origin,
  GeolocationPermissionsCallback callback,
);

/// Responsible for request the Geolocation API is Cancel.
typedef GeolocationPermissionsHidePrompt = void Function(
  WebChromeClient instance,
);

/// Handles JavaScript dialogs, favicons, titles, and the progress for [WebView].
class WebChromeClient extends JavaObject {
  /// Constructs a [WebChromeClient].
  WebChromeClient({
    this.onProgressChanged,
    this.onShowFileChooser,
    this.onPermissionRequest,
    this.onGeolocationPermissionsShowPrompt,
    this.onGeolocationPermissionsHidePrompt,
    @visibleForTesting super.binaryMessenger,
    @visibleForTesting super.instanceManager,
  }) : super.detached() {
    AndroidWebViewFlutterApis.instance.ensureSetUp();
    api.createFromInstance(this);
  }

  /// Constructs a [WebChromeClient] without creating the associated Java
  /// object.
  ///
  /// This should only be used by subclasses created by this library or to
  /// create copies.
  @protected
  WebChromeClient.detached({
    this.onProgressChanged,
    this.onShowFileChooser,
    this.onPermissionRequest,
    this.onGeolocationPermissionsShowPrompt,
    this.onGeolocationPermissionsHidePrompt,
    super.binaryMessenger,
    super.instanceManager,
  }) : super.detached();

  /// Pigeon Host Api implementation for [WebChromeClient].
  @visibleForTesting
  static WebChromeClientHostApiImpl api = WebChromeClientHostApiImpl();

  /// Notify the host application that a file should be downloaded.
  final void Function(WebView webView, int progress)? onProgressChanged;

  /// Indicates the client should show a file chooser.
  ///
  /// To handle the request for a file chooser with this callback, passing true
  /// to [setSynchronousReturnValueForOnShowFileChooser] is required. Otherwise,
  /// the returned list of strings will be ignored and the client will use the
  /// default handling of a file chooser request.
  ///
  /// Only invoked on Android versions 21+.
  final Future<List<String>> Function(
    WebView webView,
    FileChooserParams params,
  )? onShowFileChooser;

  /// Notify the host application that web content is requesting permission to
  /// access the specified resources and the permission currently isn't granted
  /// or denied.
  ///
  /// Only invoked on Android versions 21+.
  final void Function(
    WebChromeClient instance,
    PermissionRequest request,
  )? onPermissionRequest;

  /// Indicates the client should handle geolocation permissions.
  final GeolocationPermissionsShowPrompt? onGeolocationPermissionsShowPrompt;

  /// Notify the host application that a request for Geolocation permissions,
  /// made with a previous call to [onGeolocationPermissionsShowPrompt] has been
  /// canceled.
  final void Function(
    WebChromeClient instance,
  )? onGeolocationPermissionsHidePrompt;

  /// Sets the required synchronous return value for the Java method,
  /// `WebChromeClient.onShowFileChooser(...)`.
  ///
  /// The Java method, `WebChromeClient.onShowFileChooser(...)`, requires
  /// a boolean to be returned and this method sets the returned value for all
  /// calls to the Java method.
  ///
  /// Setting this to true indicates that all file chooser requests should be
  /// handled by [onShowFileChooser] and the returned list of Strings will be
  /// returned to the WebView. Otherwise, the client will use the default
  /// handling and the returned value in [onShowFileChooser] will be ignored.
  ///
  /// Requires [onShowFileChooser] to be nonnull.
  ///
  /// Defaults to false.
  Future<void> setSynchronousReturnValueForOnShowFileChooser(
    bool value,
  ) {
    if (value && onShowFileChooser == null) {
      throw StateError(
        'Setting this to true requires `onShowFileChooser` to be nonnull.',
      );
    }
    return api.setSynchronousReturnValueForOnShowFileChooserFromInstance(
      this,
      value,
    );
  }

  @override
  WebChromeClient copy() {
    return WebChromeClient.detached(
      onProgressChanged: onProgressChanged,
      onShowFileChooser: onShowFileChooser,
      onGeolocationPermissionsShowPrompt: onGeolocationPermissionsShowPrompt,
      onGeolocationPermissionsHidePrompt: onGeolocationPermissionsHidePrompt,
      binaryMessenger: _api.binaryMessenger,
      instanceManager: _api.instanceManager,
    );
  }
}

/// This class defines a permission request and is used when web content
/// requests access to protected resources.
///
/// Only supported on Android versions >= 21.
///
/// See https://developer.android.com/reference/android/webkit/PermissionRequest.
class PermissionRequest extends JavaObject {
  /// Instantiates a [PermissionRequest] without creating and attaching to an
  /// instance of the associated native class.
  ///
  /// This should only be used outside of tests by subclasses created by this
  /// library or to create a copy for an [InstanceManager].
  @protected
  PermissionRequest.detached({
    required this.resources,
    required super.binaryMessenger,
    required super.instanceManager,
  })  : _permissionRequestApi = PermissionRequestHostApiImpl(
          binaryMessenger: binaryMessenger,
          instanceManager: instanceManager,
        ),
        super.detached();

  /// Resource belongs to audio capture device, like microphone.
  ///
  /// See https://developer.android.com/reference/android/webkit/PermissionRequest#RESOURCE_AUDIO_CAPTURE.
  static const String audioCapture = 'android.webkit.resource.AUDIO_CAPTURE';

  /// Resource will allow sysex messages to be sent to or received from MIDI
  /// devices.
  ///
  /// See https://developer.android.com/reference/android/webkit/PermissionRequest#RESOURCE_MIDI_SYSEX.
  static const String midiSysex = 'android.webkit.resource.MIDI_SYSEX';

  /// Resource belongs to video capture device, like camera.
  ///
  /// See https://developer.android.com/reference/android/webkit/PermissionRequest#RESOURCE_VIDEO_CAPTURE.
  static const String videoCapture = 'android.webkit.resource.VIDEO_CAPTURE';

  /// Resource belongs to protected media identifier.
  ///
  /// See https://developer.android.com/reference/android/webkit/PermissionRequest#RESOURCE_VIDEO_CAPTURE.
  static const String protectedMediaId =
      'android.webkit.resource.PROTECTED_MEDIA_ID';

  final PermissionRequestHostApiImpl _permissionRequestApi;

  /// Resources the web page is trying to access.
  final List<String> resources;

  /// Call this method to get the resources the web page is trying to access.
  Future<void> grant(List<String> resources) {
    return _permissionRequestApi.grantFromInstances(this, resources);
  }

  /// Call this method to grant origin the permission to access the given
  /// resources.
  Future<void> deny() {
    return _permissionRequestApi.denyFromInstances(this);
  }

  @override
  PermissionRequest copy() {
    return PermissionRequest.detached(
      resources: resources,
      binaryMessenger: _permissionRequestApi.binaryMessenger,
      instanceManager: _permissionRequestApi.instanceManager,
    );
  }
}

/// Parameters received when a [WebChromeClient] should show a file chooser.
///
/// See https://developer.android.com/reference/android/webkit/WebChromeClient.FileChooserParams.
class FileChooserParams extends JavaObject {
  /// Constructs a [FileChooserParams] without creating the associated Java
  /// object.
  ///
  /// This should only be used by subclasses created by this library or to
  /// create copies.
  @protected
  FileChooserParams.detached({
    required this.isCaptureEnabled,
    required this.acceptTypes,
    required this.filenameHint,
    required this.mode,
    super.binaryMessenger,
    super.instanceManager,
  }) : super.detached();

  /// Preference for a live media captured value (e.g. Camera, Microphone).
  final bool isCaptureEnabled;

  /// A list of acceptable MIME types.
  final List<String> acceptTypes;

  /// The file name of a default selection if specified, or null.
  final String? filenameHint;

  /// Mode of how to select files for a file chooser.
  final FileChooserMode mode;

  @override
  FileChooserParams copy() {
    return FileChooserParams.detached(
      isCaptureEnabled: isCaptureEnabled,
      acceptTypes: acceptTypes,
      filenameHint: filenameHint,
      mode: mode,
      binaryMessenger: _api.binaryMessenger,
      instanceManager: _api.instanceManager,
    );
  }
}

/// Encompasses parameters to the [WebViewClient.requestLoading] method.
class WebResourceRequest {
  /// Constructs a [WebResourceRequest].
  WebResourceRequest({
    required this.url,
    required this.isForMainFrame,
    required this.isRedirect,
    required this.hasGesture,
    required this.method,
    required this.requestHeaders,
  });

  /// The URL for which the resource request was made.
  final String url;

  /// Whether the request was made in order to fetch the main frame's document.
  final bool isForMainFrame;

  /// Whether the request was a result of a server-side redirect.
  ///
  /// Only supported on Android version >= 24.
  final bool? isRedirect;

  /// Whether a gesture (such as a click) was associated with the request.
  final bool hasGesture;

  /// The method associated with the request, for example "GET".
  final String method;

  /// The headers associated with the request.
  final Map<String, String> requestHeaders;
}

/// Encapsulates information about errors occurred during loading of web resources.
///
/// See [WebViewClient.onReceivedRequestError].
class WebResourceError {
  /// Constructs a [WebResourceError].
  WebResourceError({
    required this.errorCode,
    required this.description,
  });

  /// The integer code of the error (e.g. [WebViewClient.errorAuthentication].
  final int errorCode;

  /// Describes the error.
  final String description;
}

/// Manages Flutter assets that are part of Android's app bundle.
class FlutterAssetManager {
  /// Constructs the [FlutterAssetManager].
  const FlutterAssetManager();

  /// Pigeon Host Api implementation for [FlutterAssetManager].
  @visibleForTesting
  static FlutterAssetManagerHostApi api = FlutterAssetManagerHostApi();

  /// Lists all assets at the given path.
  ///
  /// The assets are returned as a `List<String>`. The `List<String>` only
  /// contains files which are direct childs
  Future<List<String?>> list(String path) => api.list(path);

  /// Gets the relative file path to the Flutter asset with the given name.
  Future<String> getAssetFilePathByName(String name) =>
      api.getAssetFilePathByName(name);
}

/// Manages the JavaScript storage APIs provided by the [WebView].
///
/// Wraps [WebStorage](https://developer.android.com/reference/android/webkit/WebStorage).
class WebStorage extends JavaObject {
  /// Constructs a [WebStorage].
  ///
  /// This constructor is only used for testing. An instance should be obtained
  /// with [WebStorage.instance].
  @visibleForTesting
  WebStorage({
    @visibleForTesting super.binaryMessenger,
    @visibleForTesting super.instanceManager,
  }) : super.detached() {
    AndroidWebViewFlutterApis.instance.ensureSetUp();
    api.createFromInstance(this);
  }

  /// Constructs a [WebStorage] without creating the associated Java object.
  ///
  /// This should only be used by subclasses created by this library or to
  /// create copies.
  @protected
  WebStorage.detached({
    super.binaryMessenger,
    super.instanceManager,
  }) : super.detached();

  /// Pigeon Host Api implementation for [WebStorage].
  @visibleForTesting
  static WebStorageHostApiImpl api = WebStorageHostApiImpl();

  /// The singleton instance of this class.
  static WebStorage instance = WebStorage();

  /// Clears all storage currently being used by the JavaScript storage APIs.
  Future<void> deleteAllData() {
    return api.deleteAllDataFromInstance(this);
  }

  @override
  WebStorage copy() {
    return WebStorage.detached(
      binaryMessenger: _api.binaryMessenger,
      instanceManager: _api.instanceManager,
    );
  }
}
