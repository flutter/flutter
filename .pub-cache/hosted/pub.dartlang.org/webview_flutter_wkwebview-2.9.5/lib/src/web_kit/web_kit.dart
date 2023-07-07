// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../common/instance_manager.dart';
import '../foundation/foundation.dart';
import '../ui_kit/ui_kit.dart';
import 'web_kit_api_impls.dart';

/// Times at which to inject script content into a webpage.
///
/// Wraps [WKUserScriptInjectionTime](https://developer.apple.com/documentation/webkit/wkuserscriptinjectiontime?language=objc).
enum WKUserScriptInjectionTime {
  /// Inject the script after the creation of the webpage’s document element, but before loading any other content.
  ///
  /// See https://developer.apple.com/documentation/webkit/wkuserscriptinjectiontime/wkuserscriptinjectiontimeatdocumentstart?language=objc.
  atDocumentStart,

  /// Inject the script after the document finishes loading, but before loading any other subresources.
  ///
  /// See https://developer.apple.com/documentation/webkit/wkuserscriptinjectiontime/wkuserscriptinjectiontimeatdocumentend?language=objc.
  atDocumentEnd,
}

/// The media types that require a user gesture to begin playing.
///
/// Wraps [WKAudiovisualMediaTypes](https://developer.apple.com/documentation/webkit/wkaudiovisualmediatypes?language=objc).
enum WKAudiovisualMediaType {
  /// No media types require a user gesture to begin playing.
  ///
  /// See https://developer.apple.com/documentation/webkit/wkaudiovisualmediatypes/wkaudiovisualmediatypenone?language=objc.
  none,

  /// Media types that contain audio require a user gesture to begin playing.
  ///
  /// See https://developer.apple.com/documentation/webkit/wkaudiovisualmediatypes/wkaudiovisualmediatypeaudio?language=objc.
  audio,

  /// Media types that contain video require a user gesture to begin playing.
  ///
  /// See https://developer.apple.com/documentation/webkit/wkaudiovisualmediatypes/wkaudiovisualmediatypevideo?language=objc.
  video,

  /// All media types require a user gesture to begin playing.
  ///
  /// See https://developer.apple.com/documentation/webkit/wkaudiovisualmediatypes/wkaudiovisualmediatypeall?language=objc.
  all,
}

/// Types of data that websites store.
///
/// See https://developer.apple.com/documentation/webkit/wkwebsitedatarecord/data_store_record_types?language=objc.
enum WKWebsiteDataType {
  /// Cookies.
  cookies,

  /// In-memory caches.
  memoryCache,

  /// On-disk caches.
  diskCache,

  /// HTML offline web app caches.
  offlineWebApplicationCache,

  /// HTML local storage.
  localStorage,

  /// HTML session storage.
  sessionStorage,

  /// WebSQL databases.
  webSQLDatabases,

  /// IndexedDB databases.
  indexedDBDatabases,
}

/// Indicate whether to allow or cancel navigation to a webpage.
///
/// Wraps [WKNavigationActionPolicy](https://developer.apple.com/documentation/webkit/wknavigationactionpolicy?language=objc).
enum WKNavigationActionPolicy {
  /// Allow navigation to continue.
  ///
  /// See https://developer.apple.com/documentation/webkit/wknavigationactionpolicy/wknavigationactionpolicyallow?language=objc.
  allow,

  /// Cancel navigation.
  ///
  /// See https://developer.apple.com/documentation/webkit/wknavigationactionpolicy/wknavigationactionpolicycancel?language=objc.
  cancel,
}

/// Possible error values that WebKit APIs can return.
///
/// See https://developer.apple.com/documentation/webkit/wkerrorcode.
class WKErrorCode {
  WKErrorCode._();

  /// Indicates an unknown issue occurred.
  ///
  /// See https://developer.apple.com/documentation/webkit/wkerrorcode/wkerrorunknown.
  static const int unknown = 1;

  /// Indicates the web process that contains the content is no longer running.
  ///
  /// See https://developer.apple.com/documentation/webkit/wkerrorcode/wkerrorwebcontentprocessterminated.
  static const int webContentProcessTerminated = 2;

  /// Indicates the web view was invalidated.
  ///
  /// See https://developer.apple.com/documentation/webkit/wkerrorcode/wkerrorwebviewinvalidated.
  static const int webViewInvalidated = 3;

  /// Indicates a JavaScript exception occurred.
  ///
  /// See https://developer.apple.com/documentation/webkit/wkerrorcode/wkerrorjavascriptexceptionoccurred.
  static const int javaScriptExceptionOccurred = 4;

  /// Indicates the result of JavaScript execution could not be returned.
  ///
  /// See https://developer.apple.com/documentation/webkit/wkerrorcode/wkerrorjavascriptresulttypeisunsupported.
  static const int javaScriptResultTypeIsUnsupported = 5;
}

/// A record of the data that a particular website stores persistently.
///
/// Wraps [WKWebsiteDataRecord](https://developer.apple.com/documentation/webkit/wkwebsitedatarecord?language=objc).
@immutable
class WKWebsiteDataRecord {
  /// Constructs a [WKWebsiteDataRecord].
  const WKWebsiteDataRecord({required this.displayName});

  /// Identifying information that you display to users.
  final String displayName;
}

/// An object that contains information about an action that causes navigation to occur.
///
/// Wraps [WKNavigationAction](https://developer.apple.com/documentation/webkit/wknavigationaction?language=objc).
@immutable
class WKNavigationAction {
  /// Constructs a [WKNavigationAction].
  const WKNavigationAction({required this.request, required this.targetFrame});

  /// The URL request object associated with the navigation action.
  final NSUrlRequest request;

  /// The frame in which to display the new content.
  final WKFrameInfo targetFrame;
}

/// An object that contains information about a frame on a webpage.
///
/// An instance of this class is a transient, data-only object; it does not
/// uniquely identify a frame across multiple delegate method calls.
///
/// Wraps [WKFrameInfo](https://developer.apple.com/documentation/webkit/wkframeinfo?language=objc).
@immutable
class WKFrameInfo {
  /// Construct a [WKFrameInfo].
  const WKFrameInfo({required this.isMainFrame});

  /// Indicates whether the frame is the web site's main frame or a subframe.
  final bool isMainFrame;
}

/// A script that the web view injects into a webpage.
///
/// Wraps [WKUserScript](https://developer.apple.com/documentation/webkit/wkuserscript?language=objc).
@immutable
class WKUserScript {
  /// Constructs a [UserScript].
  const WKUserScript(
    this.source,
    this.injectionTime, {
    required this.isMainFrameOnly,
  });

  /// The script’s source code.
  final String source;

  /// The time at which to inject the script into the webpage.
  final WKUserScriptInjectionTime injectionTime;

  /// Indicates whether to inject the script into the main frame or all frames.
  final bool isMainFrameOnly;
}

/// An object that encapsulates a message sent by JavaScript code from a webpage.
///
/// Wraps [WKScriptMessage](https://developer.apple.com/documentation/webkit/wkscriptmessage?language=objc).
@immutable
class WKScriptMessage {
  /// Constructs a [WKScriptMessage].
  const WKScriptMessage({required this.name, this.body});

  /// The name of the message handler to which the message is sent.
  final String name;

  /// The body of the message.
  ///
  /// Allowed types are [num], [String], [List], [Map], and `null`.
  final Object? body;
}

/// Encapsulates the standard behaviors to apply to websites.
///
/// Wraps [WKPreferences](https://developer.apple.com/documentation/webkit/wkpreferences?language=objc).
@immutable
class WKPreferences extends NSObject {
  /// Constructs a [WKPreferences] that is owned by [configuration].
  factory WKPreferences.fromWebViewConfiguration(
    WKWebViewConfiguration configuration, {
    BinaryMessenger? binaryMessenger,
    InstanceManager? instanceManager,
  }) {
    final WKPreferences preferences = WKPreferences.detached(
      binaryMessenger: binaryMessenger,
      instanceManager: instanceManager,
    );
    preferences._preferencesApi.createFromWebViewConfigurationForInstances(
      preferences,
      configuration,
    );
    return preferences;
  }

  /// Constructs a [WKPreferences] without creating the associated
  /// Objective-C object.
  ///
  /// This should only be used by subclasses created by this library or to
  /// create copies.
  WKPreferences.detached({
    super.observeValue,
    super.binaryMessenger,
    super.instanceManager,
  })  : _preferencesApi = WKPreferencesHostApiImpl(
          binaryMessenger: binaryMessenger,
          instanceManager: instanceManager,
        ),
        super.detached();

  final WKPreferencesHostApiImpl _preferencesApi;

  // TODO(bparrishMines): Deprecated for iOS 14.0+. Add support for alternative.
  /// Sets whether JavaScript is enabled.
  ///
  /// The default value is true.
  Future<void> setJavaScriptEnabled(bool enabled) {
    return _preferencesApi.setJavaScriptEnabledForInstances(this, enabled);
  }

  @override
  WKPreferences copy() {
    return WKPreferences.detached(
      observeValue: observeValue,
      binaryMessenger: _preferencesApi.binaryMessenger,
      instanceManager: _preferencesApi.instanceManager,
    );
  }
}

/// Manages cookies, disk and memory caches, and other types of data for a web view.
///
/// Wraps [WKWebsiteDataStore](https://developer.apple.com/documentation/webkit/wkwebsitedatastore?language=objc).
@immutable
class WKWebsiteDataStore extends NSObject {
  /// Constructs a [WKWebsiteDataStore] without creating the associated
  /// Objective-C object.
  ///
  /// This should only be used by subclasses created by this library or to
  /// create copies.
  WKWebsiteDataStore.detached({
    super.observeValue,
    super.binaryMessenger,
    super.instanceManager,
  })  : _websiteDataStoreApi = WKWebsiteDataStoreHostApiImpl(
          binaryMessenger: binaryMessenger,
          instanceManager: instanceManager,
        ),
        super.detached();

  factory WKWebsiteDataStore._defaultDataStore() {
    final WKWebsiteDataStore websiteDataStore = WKWebsiteDataStore.detached();
    websiteDataStore._websiteDataStoreApi.createDefaultDataStoreForInstances(
      websiteDataStore,
    );
    return websiteDataStore;
  }

  /// Constructs a [WKWebsiteDataStore] that is owned by [configuration].
  factory WKWebsiteDataStore.fromWebViewConfiguration(
    WKWebViewConfiguration configuration, {
    BinaryMessenger? binaryMessenger,
    InstanceManager? instanceManager,
  }) {
    final WKWebsiteDataStore websiteDataStore = WKWebsiteDataStore.detached(
      binaryMessenger: binaryMessenger,
      instanceManager: instanceManager,
    );
    websiteDataStore._websiteDataStoreApi
        .createFromWebViewConfigurationForInstances(
      websiteDataStore,
      configuration,
    );
    return websiteDataStore;
  }

  /// Default data store that stores data persistently to disk.
  static final WKWebsiteDataStore defaultDataStore =
      WKWebsiteDataStore._defaultDataStore();

  final WKWebsiteDataStoreHostApiImpl _websiteDataStoreApi;

  /// Manages the HTTP cookies associated with a particular web view.
  late final WKHttpCookieStore httpCookieStore =
      WKHttpCookieStore.fromWebsiteDataStore(this);

  /// Removes website data that changed after the specified date.
  ///
  /// Returns whether any data was removed.
  Future<bool> removeDataOfTypes(
    Set<WKWebsiteDataType> dataTypes,
    DateTime since,
  ) {
    return _websiteDataStoreApi.removeDataOfTypesForInstances(
      this,
      dataTypes,
      secondsModifiedSinceEpoch: since.millisecondsSinceEpoch / 1000,
    );
  }

  @override
  WKWebsiteDataStore copy() {
    return WKWebsiteDataStore.detached(
      observeValue: observeValue,
      binaryMessenger: _websiteDataStoreApi.binaryMessenger,
      instanceManager: _websiteDataStoreApi.instanceManager,
    );
  }
}

/// An object that manages the HTTP cookies associated with a particular web view.
///
/// Wraps [WKHTTPCookieStore](https://developer.apple.com/documentation/webkit/wkhttpcookiestore?language=objc).
@immutable
class WKHttpCookieStore extends NSObject {
  /// Constructs a [WKHttpCookieStore] without creating the associated
  /// Objective-C object.
  ///
  /// This should only be used by subclasses created by this library or to
  /// create copies.
  WKHttpCookieStore.detached({
    super.observeValue,
    super.binaryMessenger,
    super.instanceManager,
  })  : _httpCookieStoreApi = WKHttpCookieStoreHostApiImpl(
          binaryMessenger: binaryMessenger,
          instanceManager: instanceManager,
        ),
        super.detached();

  /// Constructs a [WKHttpCookieStore] that is owned by [dataStore].
  factory WKHttpCookieStore.fromWebsiteDataStore(
    WKWebsiteDataStore dataStore, {
    BinaryMessenger? binaryMessenger,
    InstanceManager? instanceManager,
  }) {
    final WKHttpCookieStore cookieStore = WKHttpCookieStore.detached(
      binaryMessenger: binaryMessenger,
      instanceManager: instanceManager,
    );
    cookieStore._httpCookieStoreApi.createFromWebsiteDataStoreForInstances(
      cookieStore,
      dataStore,
    );
    return cookieStore;
  }

  final WKHttpCookieStoreHostApiImpl _httpCookieStoreApi;

  /// Adds a cookie to the cookie store.
  Future<void> setCookie(NSHttpCookie cookie) {
    return _httpCookieStoreApi.setCookieForInstances(this, cookie);
  }

  @override
  WKHttpCookieStore copy() {
    return WKHttpCookieStore.detached(
      observeValue: observeValue,
      binaryMessenger: _httpCookieStoreApi.binaryMessenger,
      instanceManager: _httpCookieStoreApi.instanceManager,
    );
  }
}

/// An interface for receiving messages from JavaScript code running in a webpage.
///
/// Wraps [WKScriptMessageHandler](https://developer.apple.com/documentation/webkit/wkscriptmessagehandler?language=objc).
@immutable
class WKScriptMessageHandler extends NSObject {
  /// Constructs a [WKScriptMessageHandler].
  WKScriptMessageHandler({
    required this.didReceiveScriptMessage,
    super.observeValue,
    super.binaryMessenger,
    super.instanceManager,
  })  : _scriptMessageHandlerApi = WKScriptMessageHandlerHostApiImpl(
          binaryMessenger: binaryMessenger,
          instanceManager: instanceManager,
        ),
        super.detached() {
    // Ensures FlutterApis for the WebKit library are set up.
    WebKitFlutterApis.instance.ensureSetUp();
    _scriptMessageHandlerApi.createForInstances(this);
  }

  /// Constructs a [WKScriptMessageHandler] without creating the associated
  /// Objective-C object.
  ///
  /// This should only be used by subclasses created by this library or to
  /// create copies.
  WKScriptMessageHandler.detached({
    required this.didReceiveScriptMessage,
    super.observeValue,
    super.binaryMessenger,
    super.instanceManager,
  })  : _scriptMessageHandlerApi = WKScriptMessageHandlerHostApiImpl(
          binaryMessenger: binaryMessenger,
          instanceManager: instanceManager,
        ),
        super.detached();

  final WKScriptMessageHandlerHostApiImpl _scriptMessageHandlerApi;

  /// Tells the handler that a webpage sent a script message.
  ///
  /// Use this method to respond to a message sent from the webpage’s
  /// JavaScript code. Use the [message] parameter to get the message contents and
  /// to determine the originating web view.
  ///
  /// {@macro webview_flutter_wkwebview.foundation.callbacks}
  final void Function(
    WKUserContentController userContentController,
    WKScriptMessage message,
  ) didReceiveScriptMessage;

  @override
  WKScriptMessageHandler copy() {
    return WKScriptMessageHandler.detached(
      didReceiveScriptMessage: didReceiveScriptMessage,
      observeValue: observeValue,
      binaryMessenger: _scriptMessageHandlerApi.binaryMessenger,
      instanceManager: _scriptMessageHandlerApi.instanceManager,
    );
  }
}

/// Manages interactions between JavaScript code and your web view.
///
/// Use this object to do the following:
///
/// * Inject JavaScript code into webpages running in your web view.
/// * Install custom JavaScript functions that call through to your app’s native
///   code.
///
/// Wraps [WKUserContentController](https://developer.apple.com/documentation/webkit/wkusercontentcontroller?language=objc).
@immutable
class WKUserContentController extends NSObject {
  /// Constructs a [WKUserContentController] that is owned by [configuration].
  factory WKUserContentController.fromWebViewConfiguration(
    WKWebViewConfiguration configuration, {
    BinaryMessenger? binaryMessenger,
    InstanceManager? instanceManager,
  }) {
    final WKUserContentController userContentController =
        WKUserContentController.detached(
      binaryMessenger: binaryMessenger,
      instanceManager: instanceManager,
    );
    userContentController._userContentControllerApi
        .createFromWebViewConfigurationForInstances(
      userContentController,
      configuration,
    );
    return userContentController;
  }

  /// Constructs a [WKUserContentController] without creating the associated
  /// Objective-C object.
  ///
  /// This should only be used outside of tests by subclasses created by this
  /// library or to create a copy for an InstanceManager.
  WKUserContentController.detached({
    super.observeValue,
    super.binaryMessenger,
    super.instanceManager,
  })  : _userContentControllerApi = WKUserContentControllerHostApiImpl(
          binaryMessenger: binaryMessenger,
          instanceManager: instanceManager,
        ),
        super.detached();

  final WKUserContentControllerHostApiImpl _userContentControllerApi;

  /// Installs a message handler that you can call from your JavaScript code.
  ///
  /// This name of the parameter must be unique within the user content
  /// controller and must not be an empty string. The user content controller
  /// uses this parameter to define a JavaScript function for your message
  /// handler in the page’s main content world. The name of this function is
  /// `window.webkit.messageHandlers.<name>.postMessage(<messageBody>)`, where
  /// `<name>` corresponds to the value of this parameter. For example, if you
  /// specify the string `MyFunction`, the user content controller defines the `
  /// `window.webkit.messageHandlers.MyFunction.postMessage()` function in
  /// JavaScript.
  Future<void> addScriptMessageHandler(
    WKScriptMessageHandler handler,
    String name,
  ) {
    assert(name.isNotEmpty);
    return _userContentControllerApi.addScriptMessageHandlerForInstances(
      this,
      handler,
      name,
    );
  }

  /// Uninstalls the custom message handler with the specified name from your JavaScript code.
  ///
  /// If no message handler with this name exists in the user content
  /// controller, this method does nothing.
  ///
  /// Use this method to remove a message handler that you previously installed
  /// using the [addScriptMessageHandler] method. This method removes the
  /// message handler from the page content world. If you installed the message
  /// handler in a different content world, this method doesn’t remove it.
  Future<void> removeScriptMessageHandler(String name) {
    return _userContentControllerApi.removeScriptMessageHandlerForInstances(
      this,
      name,
    );
  }

  /// Uninstalls all custom message handlers associated with the user content
  /// controller.
  ///
  /// Only supported on iOS version 14+.
  Future<void> removeAllScriptMessageHandlers() {
    return _userContentControllerApi.removeAllScriptMessageHandlersForInstances(
      this,
    );
  }

  /// Injects the specified script into the webpage’s content.
  Future<void> addUserScript(WKUserScript userScript) {
    return _userContentControllerApi.addUserScriptForInstances(
        this, userScript);
  }

  /// Removes all user scripts from the web view.
  Future<void> removeAllUserScripts() {
    return _userContentControllerApi.removeAllUserScriptsForInstances(this);
  }

  @override
  WKUserContentController copy() {
    return WKUserContentController.detached(
      observeValue: observeValue,
      binaryMessenger: _userContentControllerApi.binaryMessenger,
      instanceManager: _userContentControllerApi.instanceManager,
    );
  }
}

/// A collection of properties that you use to initialize a web view.
///
/// Wraps [WKWebViewConfiguration](https://developer.apple.com/documentation/webkit/wkwebviewconfiguration?language=objc).
@immutable
class WKWebViewConfiguration extends NSObject {
  /// Constructs a [WKWebViewConfiguration].
  WKWebViewConfiguration({
    super.observeValue,
    super.binaryMessenger,
    super.instanceManager,
  })  : _webViewConfigurationApi = WKWebViewConfigurationHostApiImpl(
          binaryMessenger: binaryMessenger,
          instanceManager: instanceManager,
        ),
        super.detached() {
    // Ensures FlutterApis for the WebKit library are set up.
    WebKitFlutterApis.instance.ensureSetUp();
    _webViewConfigurationApi.createForInstances(this);
  }

  /// A WKWebViewConfiguration that is owned by webView.
  @visibleForTesting
  factory WKWebViewConfiguration.fromWebView(
    WKWebView webView, {
    BinaryMessenger? binaryMessenger,
    InstanceManager? instanceManager,
  }) {
    final WKWebViewConfiguration configuration =
        WKWebViewConfiguration.detached(
      binaryMessenger: binaryMessenger,
      instanceManager: instanceManager,
    );
    configuration._webViewConfigurationApi.createFromWebViewForInstances(
      configuration,
      webView,
    );
    return configuration;
  }

  /// Constructs a [WKWebViewConfiguration] without creating the associated
  /// Objective-C object.
  ///
  /// This should only be used outside of tests by subclasses created by this
  /// library or to create a copy for an InstanceManager.
  WKWebViewConfiguration.detached({
    super.observeValue,
    super.binaryMessenger,
    super.instanceManager,
  })  : _webViewConfigurationApi = WKWebViewConfigurationHostApiImpl(
          binaryMessenger: binaryMessenger,
          instanceManager: instanceManager,
        ),
        super.detached();

  late final WKWebViewConfigurationHostApiImpl _webViewConfigurationApi;

  /// Coordinates interactions between your app’s code and the webpage’s scripts and other content.
  late final WKUserContentController userContentController =
      WKUserContentController.fromWebViewConfiguration(
    this,
    binaryMessenger: _webViewConfigurationApi.binaryMessenger,
    instanceManager: _webViewConfigurationApi.instanceManager,
  );

  /// Manages the preference-related settings for the web view.
  late final WKPreferences preferences = WKPreferences.fromWebViewConfiguration(
    this,
    binaryMessenger: _webViewConfigurationApi.binaryMessenger,
    instanceManager: _webViewConfigurationApi.instanceManager,
  );

  /// Used to get and set the site’s cookies and to track the cached data objects.
  ///
  /// Represents [WKWebViewConfiguration.webSiteDataStore](https://developer.apple.com/documentation/webkit/wkwebviewconfiguration/1395661-websitedatastore?language=objc).
  late final WKWebsiteDataStore websiteDataStore =
      WKWebsiteDataStore.fromWebViewConfiguration(
    this,
    binaryMessenger: _webViewConfigurationApi.binaryMessenger,
    instanceManager: _webViewConfigurationApi.instanceManager,
  );

  /// Indicates whether HTML5 videos play inline or use the native full-screen controller.
  ///
  /// Sets [WKWebViewConfiguration.allowsInlineMediaPlayback](https://developer.apple.com/documentation/webkit/wkwebviewconfiguration/1614793-allowsinlinemediaplayback?language=objc).
  Future<void> setAllowsInlineMediaPlayback(bool allow) {
    return _webViewConfigurationApi.setAllowsInlineMediaPlaybackForInstances(
      this,
      allow,
    );
  }

  /// The media types that require a user gesture to begin playing.
  ///
  /// Use [WKAudiovisualMediaType.none] to indicate that no user gestures are
  /// required to begin playing media.
  ///
  /// Sets [WKWebViewConfiguration.mediaTypesRequiringUserActionForPlayback](https://developer.apple.com/documentation/webkit/wkwebviewconfiguration/1851524-mediatypesrequiringuseractionfor?language=objc).
  Future<void> setMediaTypesRequiringUserActionForPlayback(
    Set<WKAudiovisualMediaType> types,
  ) {
    assert(types.isNotEmpty);
    return _webViewConfigurationApi
        .setMediaTypesRequiringUserActionForPlaybackForInstances(
      this,
      types,
    );
  }

  @override
  WKWebViewConfiguration copy() {
    return WKWebViewConfiguration.detached(
      observeValue: observeValue,
      binaryMessenger: _webViewConfigurationApi.binaryMessenger,
      instanceManager: _webViewConfigurationApi.instanceManager,
    );
  }
}

/// The methods for presenting native user interface elements on behalf of a webpage.
///
/// Wraps [WKUIDelegate](https://developer.apple.com/documentation/webkit/wkuidelegate?language=objc).
@immutable
class WKUIDelegate extends NSObject {
  /// Constructs a [WKUIDelegate].
  WKUIDelegate({
    this.onCreateWebView,
    super.observeValue,
    super.binaryMessenger,
    super.instanceManager,
  })  : _uiDelegateApi = WKUIDelegateHostApiImpl(
          binaryMessenger: binaryMessenger,
          instanceManager: instanceManager,
        ),
        super.detached() {
    // Ensures FlutterApis for the WebKit library are set up.
    WebKitFlutterApis.instance.ensureSetUp();
    _uiDelegateApi.createForInstances(this);
  }

  /// Constructs a [WKUIDelegate] without creating the associated Objective-C
  /// object.
  ///
  /// This should only be used by subclasses created by this library or to
  /// create copies.
  WKUIDelegate.detached({
    this.onCreateWebView,
    super.observeValue,
    super.binaryMessenger,
    super.instanceManager,
  })  : _uiDelegateApi = WKUIDelegateHostApiImpl(
          binaryMessenger: binaryMessenger,
          instanceManager: instanceManager,
        ),
        super.detached();

  final WKUIDelegateHostApiImpl _uiDelegateApi;

  /// Indicates a new [WKWebView] was requested to be created with [configuration].
  ///
  /// {@macro webview_flutter_wkwebview.foundation.callbacks}
  final void Function(
    WKWebView webView,
    WKWebViewConfiguration configuration,
    WKNavigationAction navigationAction,
  )? onCreateWebView;

  @override
  WKUIDelegate copy() {
    return WKUIDelegate.detached(
      onCreateWebView: onCreateWebView,
      observeValue: observeValue,
      binaryMessenger: _uiDelegateApi.binaryMessenger,
      instanceManager: _uiDelegateApi.instanceManager,
    );
  }
}

/// Methods for handling navigation changes and tracking navigation requests.
///
/// Set the methods of the [WKNavigationDelegate] in the object you use to
/// coordinate changes in your web view’s main frame.
///
/// Wraps [WKNavigationDelegate](https://developer.apple.com/documentation/webkit/wknavigationdelegate?language=objc).
@immutable
class WKNavigationDelegate extends NSObject {
  /// Constructs a [WKNavigationDelegate].
  WKNavigationDelegate({
    this.didFinishNavigation,
    this.didStartProvisionalNavigation,
    this.decidePolicyForNavigationAction,
    this.didFailNavigation,
    this.didFailProvisionalNavigation,
    this.webViewWebContentProcessDidTerminate,
    super.observeValue,
    super.binaryMessenger,
    super.instanceManager,
  })  : _navigationDelegateApi = WKNavigationDelegateHostApiImpl(
          binaryMessenger: binaryMessenger,
          instanceManager: instanceManager,
        ),
        super.detached() {
    // Ensures FlutterApis for the WebKit library are set up.
    WebKitFlutterApis.instance.ensureSetUp();
    _navigationDelegateApi.createForInstances(this);
  }

  /// Constructs a [WKNavigationDelegate] without creating the associated
  /// Objective-C object.
  ///
  /// This should only be used outside of tests by subclasses created by this
  /// library or to create a copy for an InstanceManager.
  WKNavigationDelegate.detached({
    this.didFinishNavigation,
    this.didStartProvisionalNavigation,
    this.decidePolicyForNavigationAction,
    this.didFailNavigation,
    this.didFailProvisionalNavigation,
    this.webViewWebContentProcessDidTerminate,
    super.observeValue,
    super.binaryMessenger,
    super.instanceManager,
  })  : _navigationDelegateApi = WKNavigationDelegateHostApiImpl(
          binaryMessenger: binaryMessenger,
          instanceManager: instanceManager,
        ),
        super.detached();

  final WKNavigationDelegateHostApiImpl _navigationDelegateApi;

  /// Called when navigation is complete.
  ///
  /// {@macro webview_flutter_wkwebview.foundation.callbacks}
  final void Function(WKWebView webView, String? url)? didFinishNavigation;

  /// Called when navigation from the main frame has started.
  ///
  /// {@macro webview_flutter_wkwebview.foundation.callbacks}
  final void Function(WKWebView webView, String? url)?
      didStartProvisionalNavigation;

  /// Called when permission is needed to navigate to new content.
  ///
  /// {@macro webview_flutter_wkwebview.foundation.callbacks}
  final Future<WKNavigationActionPolicy> Function(
    WKWebView webView,
    WKNavigationAction navigationAction,
  )? decidePolicyForNavigationAction;

  /// Called when an error occurred during navigation.
  ///
  /// {@macro webview_flutter_wkwebview.foundation.callbacks}
  final void Function(WKWebView webView, NSError error)? didFailNavigation;

  /// Called when an error occurred during the early navigation process.
  ///
  /// {@macro webview_flutter_wkwebview.foundation.callbacks}
  final void Function(WKWebView webView, NSError error)?
      didFailProvisionalNavigation;

  /// Called when the web view’s content process was terminated.
  ///
  /// {@macro webview_flutter_wkwebview.foundation.callbacks}
  final void Function(WKWebView webView)? webViewWebContentProcessDidTerminate;

  @override
  WKNavigationDelegate copy() {
    return WKNavigationDelegate.detached(
      didFinishNavigation: didFinishNavigation,
      didStartProvisionalNavigation: didStartProvisionalNavigation,
      decidePolicyForNavigationAction: decidePolicyForNavigationAction,
      didFailNavigation: didFailNavigation,
      didFailProvisionalNavigation: didFailProvisionalNavigation,
      webViewWebContentProcessDidTerminate:
          webViewWebContentProcessDidTerminate,
      observeValue: observeValue,
      binaryMessenger: _navigationDelegateApi.binaryMessenger,
      instanceManager: _navigationDelegateApi.instanceManager,
    );
  }
}

/// Object that displays interactive web content, such as for an in-app browser.
///
/// Wraps [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview?language=objc).
@immutable
class WKWebView extends UIView {
  /// Constructs a [WKWebView].
  ///
  /// [configuration] contains the configuration details for the web view. This
  /// method saves a copy of your configuration object. Changes you make to your
  /// original object after calling this method have no effect on the web view’s
  /// configuration. For a list of configuration options and their default
  /// values, see [WKWebViewConfiguration]. If you didn’t create your web view
  /// using the `configuration` parameter, this value uses a default
  /// configuration object.
  WKWebView(
    WKWebViewConfiguration configuration, {
    super.observeValue,
    super.binaryMessenger,
    super.instanceManager,
  })  : _webViewApi = WKWebViewHostApiImpl(
          binaryMessenger: binaryMessenger,
          instanceManager: instanceManager,
        ),
        super.detached() {
    // Ensures FlutterApis for the WebKit library are set up.
    WebKitFlutterApis.instance.ensureSetUp();
    _webViewApi.createForInstances(this, configuration);
  }

  /// Constructs a [WKWebView] without creating the associated Objective-C
  /// object.
  ///
  /// This should only be used outside of tests by subclasses created by this
  /// library or to create a copy for an InstanceManager.
  WKWebView.detached({
    super.observeValue,
    super.binaryMessenger,
    super.instanceManager,
  })  : _webViewApi = WKWebViewHostApiImpl(
          binaryMessenger: binaryMessenger,
          instanceManager: instanceManager,
        ),
        super.detached();

  final WKWebViewHostApiImpl _webViewApi;

  /// Contains the configuration details for the web view.
  ///
  /// Use the object in this property to obtain information about your web
  /// view’s configuration. Because this property returns a copy of the
  /// configuration object, changes you make to that object don’t affect the web
  /// view’s configuration.
  ///
  /// If you didn’t create your web view with a [WKWebViewConfiguration] this
  /// property contains a default configuration object.
  late final WKWebViewConfiguration configuration =
      WKWebViewConfiguration.fromWebView(
    this,
    binaryMessenger: _webViewApi.binaryMessenger,
    instanceManager: _webViewApi.instanceManager,
  );

  /// The scrollable view associated with the web view.
  late final UIScrollView scrollView = UIScrollView.fromWebView(
    this,
    binaryMessenger: _webViewApi.binaryMessenger,
    instanceManager: _webViewApi.instanceManager,
  );

  /// Used to integrate custom user interface elements into web view interactions.
  ///
  /// Sets [WKWebView.UIDelegate](https://developer.apple.com/documentation/webkit/wkwebview/1415009-uidelegate?language=objc).
  Future<void> setUIDelegate(WKUIDelegate? delegate) {
    return _webViewApi.setUIDelegateForInstances(this, delegate);
  }

  /// The object you use to manage navigation behavior for the web view.
  ///
  /// Sets [WKWebView.navigationDelegate](https://developer.apple.com/documentation/webkit/wkwebview/1414971-navigationdelegate?language=objc).
  Future<void> setNavigationDelegate(WKNavigationDelegate? delegate) {
    return _webViewApi.setNavigationDelegateForInstances(this, delegate);
  }

  /// The URL for the current webpage.
  ///
  /// Represents [WKWebView.URL](https://developer.apple.com/documentation/webkit/wkwebview/1415005-url?language=objc).
  Future<String?> getUrl() {
    return _webViewApi.getUrlForInstances(this);
  }

  /// An estimate of what fraction of the current navigation has been loaded.
  ///
  /// This value ranges from 0.0 to 1.0.
  ///
  /// Represents [WKWebView.estimatedProgress](https://developer.apple.com/documentation/webkit/wkwebview/1415007-estimatedprogress?language=objc).
  Future<double> getEstimatedProgress() {
    return _webViewApi.getEstimatedProgressForInstances(this);
  }

  /// Loads the web content referenced by the specified URL request object and navigates to it.
  ///
  /// Use this method to load a page from a local or network-based URL. For
  /// example, you might use it to navigate to a network-based webpage.
  Future<void> loadRequest(NSUrlRequest request) {
    return _webViewApi.loadRequestForInstances(this, request);
  }

  /// Loads the contents of the specified HTML string and navigates to it.
  Future<void> loadHtmlString(String string, {String? baseUrl}) {
    return _webViewApi.loadHtmlStringForInstances(this, string, baseUrl);
  }

  /// Loads the web content from the specified file and navigates to it.
  Future<void> loadFileUrl(String url, {required String readAccessUrl}) {
    return _webViewApi.loadFileUrlForInstances(this, url, readAccessUrl);
  }

  /// Loads the Flutter asset specified in the pubspec.yaml file.
  ///
  /// This method is not a part of WebKit and is only a Flutter specific helper
  /// method.
  Future<void> loadFlutterAsset(String key) {
    return _webViewApi.loadFlutterAssetForInstances(this, key);
  }

  /// Indicates whether there is a valid back item in the back-forward list.
  Future<bool> canGoBack() {
    return _webViewApi.canGoBackForInstances(this);
  }

  /// Indicates whether there is a valid forward item in the back-forward list.
  Future<bool> canGoForward() {
    return _webViewApi.canGoForwardForInstances(this);
  }

  /// Navigates to the back item in the back-forward list.
  Future<void> goBack() {
    return _webViewApi.goBackForInstances(this);
  }

  /// Navigates to the forward item in the back-forward list.
  Future<void> goForward() {
    return _webViewApi.goForwardForInstances(this);
  }

  /// Reloads the current webpage.
  Future<void> reload() {
    return _webViewApi.reloadForInstances(this);
  }

  /// The page title.
  ///
  /// Represents [WKWebView.title](https://developer.apple.com/documentation/webkit/wkwebview/1415015-title?language=objc).
  Future<String?> getTitle() {
    return _webViewApi.getTitleForInstances(this);
  }

  /// Indicates whether horizontal swipe gestures trigger page navigation.
  ///
  /// The default value is false.
  ///
  /// Sets [WKWebView.allowsBackForwardNavigationGestures](https://developer.apple.com/documentation/webkit/wkwebview/1414995-allowsbackforwardnavigationgestu?language=objc).
  Future<void> setAllowsBackForwardNavigationGestures(bool allow) {
    return _webViewApi.setAllowsBackForwardNavigationGesturesForInstances(
      this,
      allow,
    );
  }

  /// The custom user agent string.
  ///
  /// The default value of this property is null.
  ///
  /// Sets [WKWebView.customUserAgent](https://developer.apple.com/documentation/webkit/wkwebview/1414950-customuseragent?language=objc).
  Future<void> setCustomUserAgent(String? userAgent) {
    return _webViewApi.setCustomUserAgentForInstances(this, userAgent);
  }

  /// Evaluates the specified JavaScript string.
  ///
  /// Throws a `PlatformException` if an error occurs or return value is not
  /// supported.
  Future<Object?> evaluateJavaScript(String javaScriptString) {
    return _webViewApi.evaluateJavaScriptForInstances(
      this,
      javaScriptString,
    );
  }

  @override
  WKWebView copy() {
    return WKWebView.detached(
      observeValue: observeValue,
      binaryMessenger: _webViewApi.binaryMessenger,
      instanceManager: _webViewApi.instanceManager,
    );
  }
}
