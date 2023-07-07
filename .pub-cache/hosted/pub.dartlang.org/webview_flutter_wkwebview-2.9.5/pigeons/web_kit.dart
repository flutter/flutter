// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/common/web_kit.pigeon.dart',
    dartTestOut: 'test/src/common/test_web_kit.pigeon.dart',
    dartOptions: DartOptions(copyrightHeader: <String>[
      'Copyright 2013 The Flutter Authors. All rights reserved.',
      'Use of this source code is governed by a BSD-style license that can be',
      'found in the LICENSE file.',
    ]),
    objcHeaderOut: 'ios/Classes/FWFGeneratedWebKitApis.h',
    objcSourceOut: 'ios/Classes/FWFGeneratedWebKitApis.m',
    objcOptions: ObjcOptions(
      header: 'ios/Classes/FWFGeneratedWebKitApis.h',
      prefix: 'FWF',
      copyrightHeader: <String>[
        'Copyright 2013 The Flutter Authors. All rights reserved.',
        'Use of this source code is governed by a BSD-style license that can be',
        'found in the LICENSE file.',
      ],
    ),
  ),
)

/// Mirror of NSKeyValueObservingOptions.
///
/// See https://developer.apple.com/documentation/foundation/nskeyvalueobservingoptions?language=objc.
enum NSKeyValueObservingOptionsEnum {
  newValue,
  oldValue,
  initialValue,
  priorNotification,
}

// TODO(bparrishMines): Enums need be wrapped in a data class because thay can't
// be used as primitive arguments. See https://github.com/flutter/flutter/issues/87307
class NSKeyValueObservingOptionsEnumData {
  late NSKeyValueObservingOptionsEnum value;
}

/// Mirror of NSKeyValueChange.
///
/// See https://developer.apple.com/documentation/foundation/nskeyvaluechange?language=objc.
enum NSKeyValueChangeEnum {
  setting,
  insertion,
  removal,
  replacement,
}

// TODO(bparrishMines): Enums need be wrapped in a data class because thay can't
// be used as primitive arguments. See https://github.com/flutter/flutter/issues/87307
class NSKeyValueChangeEnumData {
  late NSKeyValueChangeEnum value;
}

/// Mirror of NSKeyValueChangeKey.
///
/// See https://developer.apple.com/documentation/foundation/nskeyvaluechangekey?language=objc.
enum NSKeyValueChangeKeyEnum {
  indexes,
  kind,
  newValue,
  notificationIsPrior,
  oldValue,
}

// TODO(bparrishMines): Enums need be wrapped in a data class because thay can't
// be used as primitive arguments. See https://github.com/flutter/flutter/issues/87307
class NSKeyValueChangeKeyEnumData {
  late NSKeyValueChangeKeyEnum value;
}

/// Mirror of WKUserScriptInjectionTime.
///
/// See https://developer.apple.com/documentation/webkit/wkuserscriptinjectiontime?language=objc.
enum WKUserScriptInjectionTimeEnum {
  atDocumentStart,
  atDocumentEnd,
}

// TODO(bparrishMines): Enums need be wrapped in a data class because thay can't
// be used as primitive arguments. See https://github.com/flutter/flutter/issues/87307
class WKUserScriptInjectionTimeEnumData {
  late WKUserScriptInjectionTimeEnum value;
}

/// Mirror of WKAudiovisualMediaTypes.
///
/// See [WKAudiovisualMediaTypes](https://developer.apple.com/documentation/webkit/wkaudiovisualmediatypes?language=objc).
enum WKAudiovisualMediaTypeEnum {
  none,
  audio,
  video,
  all,
}

// TODO(bparrishMines): Enums need be wrapped in a data class because thay can't
// be used as primitive arguments. See https://github.com/flutter/flutter/issues/87307
class WKAudiovisualMediaTypeEnumData {
  late WKAudiovisualMediaTypeEnum value;
}

/// Mirror of WKWebsiteDataTypes.
///
/// See https://developer.apple.com/documentation/webkit/wkwebsitedatarecord/data_store_record_types?language=objc.
enum WKWebsiteDataTypeEnum {
  cookies,
  memoryCache,
  diskCache,
  offlineWebApplicationCache,
  localStorage,
  sessionStorage,
  webSQLDatabases,
  indexedDBDatabases,
}

// TODO(bparrishMines): Enums need be wrapped in a data class because thay can't
// be used as primitive arguments. See https://github.com/flutter/flutter/issues/87307
class WKWebsiteDataTypeEnumData {
  late WKWebsiteDataTypeEnum value;
}

/// Mirror of WKNavigationActionPolicy.
///
/// See https://developer.apple.com/documentation/webkit/wknavigationactionpolicy?language=objc.
enum WKNavigationActionPolicyEnum {
  allow,
  cancel,
}

// TODO(bparrishMines): Enums need be wrapped in a data class because thay can't
// be used as primitive arguments. See https://github.com/flutter/flutter/issues/87307
class WKNavigationActionPolicyEnumData {
  late WKNavigationActionPolicyEnum value;
}

/// Mirror of NSHTTPCookiePropertyKey.
///
/// See https://developer.apple.com/documentation/foundation/nshttpcookiepropertykey.
enum NSHttpCookiePropertyKeyEnum {
  comment,
  commentUrl,
  discard,
  domain,
  expires,
  maximumAge,
  name,
  originUrl,
  path,
  port,
  sameSitePolicy,
  secure,
  value,
  version,
}

// TODO(bparrishMines): Enums need be wrapped in a data class because thay can't
// be used as primitive arguments. See https://github.com/flutter/flutter/issues/87307
class NSHttpCookiePropertyKeyEnumData {
  late NSHttpCookiePropertyKeyEnum value;
}

/// Mirror of NSURLRequest.
///
/// See https://developer.apple.com/documentation/foundation/nsurlrequest?language=objc.
class NSUrlRequestData {
  late String url;
  late String? httpMethod;
  late Uint8List? httpBody;
  late Map<String?, String?> allHttpHeaderFields;
}

/// Mirror of WKUserScript.
///
/// See https://developer.apple.com/documentation/webkit/wkuserscript?language=objc.
class WKUserScriptData {
  late String source;
  late WKUserScriptInjectionTimeEnumData? injectionTime;
  late bool isMainFrameOnly;
}

/// Mirror of WKNavigationAction.
///
/// See https://developer.apple.com/documentation/webkit/wknavigationaction.
class WKNavigationActionData {
  late NSUrlRequestData request;
  late WKFrameInfoData targetFrame;
}

/// Mirror of WKFrameInfo.
///
/// See https://developer.apple.com/documentation/webkit/wkframeinfo?language=objc.
class WKFrameInfoData {
  late bool isMainFrame;
}

/// Mirror of NSError.
///
/// See https://developer.apple.com/documentation/foundation/nserror?language=objc.
class NSErrorData {
  late int code;
  late String domain;
  late String localizedDescription;
}

/// Mirror of WKScriptMessage.
///
/// See https://developer.apple.com/documentation/webkit/wkscriptmessage?language=objc.
class WKScriptMessageData {
  late String name;
  late Object? body;
}

/// Mirror of NSHttpCookieData.
///
/// See https://developer.apple.com/documentation/foundation/nshttpcookie?language=objc.
class NSHttpCookieData {
  // TODO(bparrishMines): Change to a map when Objective-C data classes conform
  // to `NSCopying`. See https://github.com/flutter/flutter/issues/103383.
  // `NSDictionary`s are unable to use data classes as keys because they don't
  // conform to `NSCopying`. This splits the map of properties into a list of
  // keys and values with the ordered maintained.
  late List<NSHttpCookiePropertyKeyEnumData?> propertyKeys;
  late List<Object?> propertyValues;
}

/// Mirror of WKWebsiteDataStore.
///
/// See https://developer.apple.com/documentation/webkit/wkwebsitedatastore?language=objc.
@HostApi(dartHostTestHandler: 'TestWKWebsiteDataStoreHostApi')
abstract class WKWebsiteDataStoreHostApi {
  @ObjCSelector(
    'createFromWebViewConfigurationWithIdentifier:configurationIdentifier:',
  )
  void createFromWebViewConfiguration(
    int identifier,
    int configurationIdentifier,
  );

  @ObjCSelector('createDefaultDataStoreWithIdentifier:')
  void createDefaultDataStore(int identifier);

  @ObjCSelector(
    'removeDataFromDataStoreWithIdentifier:ofTypes:modifiedSince:',
  )
  @async
  bool removeDataOfTypes(
    int identifier,
    List<WKWebsiteDataTypeEnumData> dataTypes,
    double modificationTimeInSecondsSinceEpoch,
  );
}

/// Mirror of UIView.
///
/// See https://developer.apple.com/documentation/uikit/uiview?language=objc.
@HostApi(dartHostTestHandler: 'TestUIViewHostApi')
abstract class UIViewHostApi {
  @ObjCSelector('setBackgroundColorForViewWithIdentifier:toValue:')
  void setBackgroundColor(int identifier, int? value);

  @ObjCSelector('setOpaqueForViewWithIdentifier:isOpaque:')
  void setOpaque(int identifier, bool opaque);
}

/// Mirror of UIScrollView.
///
/// See https://developer.apple.com/documentation/uikit/uiscrollview?language=objc.
@HostApi(dartHostTestHandler: 'TestUIScrollViewHostApi')
abstract class UIScrollViewHostApi {
  @ObjCSelector('createFromWebViewWithIdentifier:webViewIdentifier:')
  void createFromWebView(int identifier, int webViewIdentifier);

  @ObjCSelector('contentOffsetForScrollViewWithIdentifier:')
  List<double?> getContentOffset(int identifier);

  @ObjCSelector('scrollByForScrollViewWithIdentifier:x:y:')
  void scrollBy(int identifier, double x, double y);

  @ObjCSelector('setContentOffsetForScrollViewWithIdentifier:toX:y:')
  void setContentOffset(int identifier, double x, double y);
}

/// Mirror of WKWebViewConfiguration.
///
/// See https://developer.apple.com/documentation/webkit/wkwebviewconfiguration?language=objc.
@HostApi(dartHostTestHandler: 'TestWKWebViewConfigurationHostApi')
abstract class WKWebViewConfigurationHostApi {
  @ObjCSelector('createWithIdentifier:')
  void create(int identifier);

  @ObjCSelector('createFromWebViewWithIdentifier:webViewIdentifier:')
  void createFromWebView(int identifier, int webViewIdentifier);

  @ObjCSelector(
    'setAllowsInlineMediaPlaybackForConfigurationWithIdentifier:isAllowed:',
  )
  void setAllowsInlineMediaPlayback(int identifier, bool allow);

  @ObjCSelector(
    'setMediaTypesRequiresUserActionForConfigurationWithIdentifier:forTypes:',
  )
  void setMediaTypesRequiringUserActionForPlayback(
    int identifier,
    List<WKAudiovisualMediaTypeEnumData> types,
  );
}

/// Handles callbacks from an WKWebViewConfiguration instance.
///
/// See https://developer.apple.com/documentation/webkit/wkwebviewconfiguration?language=objc.
@FlutterApi()
abstract class WKWebViewConfigurationFlutterApi {
  @ObjCSelector('createWithIdentifier:')
  void create(int identifier);
}

/// Mirror of WKUserContentController.
///
/// See https://developer.apple.com/documentation/webkit/wkusercontentcontroller?language=objc.
@HostApi(dartHostTestHandler: 'TestWKUserContentControllerHostApi')
abstract class WKUserContentControllerHostApi {
  @ObjCSelector(
    'createFromWebViewConfigurationWithIdentifier:configurationIdentifier:',
  )
  void createFromWebViewConfiguration(
    int identifier,
    int configurationIdentifier,
  );

  @ObjCSelector(
    'addScriptMessageHandlerForControllerWithIdentifier:handlerIdentifier:ofName:',
  )
  void addScriptMessageHandler(
    int identifier,
    int handlerIdentifier,
    String name,
  );

  @ObjCSelector('removeScriptMessageHandlerForControllerWithIdentifier:name:')
  void removeScriptMessageHandler(int identifier, String name);

  @ObjCSelector('removeAllScriptMessageHandlersForControllerWithIdentifier:')
  void removeAllScriptMessageHandlers(int identifier);

  @ObjCSelector('addUserScriptForControllerWithIdentifier:userScript:')
  void addUserScript(int identifier, WKUserScriptData userScript);

  @ObjCSelector('removeAllUserScriptsForControllerWithIdentifier:')
  void removeAllUserScripts(int identifier);
}

/// Mirror of WKUserPreferences.
///
/// See https://developer.apple.com/documentation/webkit/wkpreferences?language=objc.
@HostApi(dartHostTestHandler: 'TestWKPreferencesHostApi')
abstract class WKPreferencesHostApi {
  @ObjCSelector(
    'createFromWebViewConfigurationWithIdentifier:configurationIdentifier:',
  )
  void createFromWebViewConfiguration(
    int identifier,
    int configurationIdentifier,
  );

  @ObjCSelector('setJavaScriptEnabledForPreferencesWithIdentifier:isEnabled:')
  void setJavaScriptEnabled(int identifier, bool enabled);
}

/// Mirror of WKScriptMessageHandler.
///
/// See https://developer.apple.com/documentation/webkit/wkscriptmessagehandler?language=objc.
@HostApi(dartHostTestHandler: 'TestWKScriptMessageHandlerHostApi')
abstract class WKScriptMessageHandlerHostApi {
  @ObjCSelector('createWithIdentifier:')
  void create(int identifier);
}

/// Handles callbacks from an WKScriptMessageHandler instance.
///
/// See https://developer.apple.com/documentation/webkit/wkscriptmessagehandler?language=objc.
@FlutterApi()
abstract class WKScriptMessageHandlerFlutterApi {
  @ObjCSelector(
    'didReceiveScriptMessageForHandlerWithIdentifier:userContentControllerIdentifier:message:',
  )
  void didReceiveScriptMessage(
    int identifier,
    int userContentControllerIdentifier,
    WKScriptMessageData message,
  );
}

/// Mirror of WKNavigationDelegate.
///
/// See https://developer.apple.com/documentation/webkit/wknavigationdelegate?language=objc.
@HostApi(dartHostTestHandler: 'TestWKNavigationDelegateHostApi')
abstract class WKNavigationDelegateHostApi {
  @ObjCSelector('createWithIdentifier:')
  void create(int identifier);
}

/// Handles callbacks from an WKNavigationDelegate instance.
///
/// See https://developer.apple.com/documentation/webkit/wknavigationdelegate?language=objc.
@FlutterApi()
abstract class WKNavigationDelegateFlutterApi {
  @ObjCSelector(
    'didFinishNavigationForDelegateWithIdentifier:webViewIdentifier:URL:',
  )
  void didFinishNavigation(
    int identifier,
    int webViewIdentifier,
    String? url,
  );

  @ObjCSelector(
    'didStartProvisionalNavigationForDelegateWithIdentifier:webViewIdentifier:URL:',
  )
  void didStartProvisionalNavigation(
    int identifier,
    int webViewIdentifier,
    String? url,
  );

  @ObjCSelector(
    'decidePolicyForNavigationActionForDelegateWithIdentifier:webViewIdentifier:navigationAction:',
  )
  @async
  WKNavigationActionPolicyEnumData decidePolicyForNavigationAction(
    int identifier,
    int webViewIdentifier,
    WKNavigationActionData navigationAction,
  );

  @ObjCSelector(
    'didFailNavigationForDelegateWithIdentifier:webViewIdentifier:error:',
  )
  void didFailNavigation(
    int identifier,
    int webViewIdentifier,
    NSErrorData error,
  );

  @ObjCSelector(
    'didFailProvisionalNavigationForDelegateWithIdentifier:webViewIdentifier:error:',
  )
  void didFailProvisionalNavigation(
    int identifier,
    int webViewIdentifier,
    NSErrorData error,
  );

  @ObjCSelector(
    'webViewWebContentProcessDidTerminateForDelegateWithIdentifier:webViewIdentifier:',
  )
  void webViewWebContentProcessDidTerminate(
    int identifier,
    int webViewIdentifier,
  );
}

/// Mirror of NSObject.
///
/// See https://developer.apple.com/documentation/objectivec/nsobject.
@HostApi(dartHostTestHandler: 'TestNSObjectHostApi')
abstract class NSObjectHostApi {
  @ObjCSelector('disposeObjectWithIdentifier:')
  void dispose(int identifier);

  @ObjCSelector(
    'addObserverForObjectWithIdentifier:observerIdentifier:keyPath:options:',
  )
  void addObserver(
    int identifier,
    int observerIdentifier,
    String keyPath,
    List<NSKeyValueObservingOptionsEnumData> options,
  );

  @ObjCSelector(
    'removeObserverForObjectWithIdentifier:observerIdentifier:keyPath:',
  )
  void removeObserver(int identifier, int observerIdentifier, String keyPath);
}

/// Handles callbacks from an NSObject instance.
///
/// See https://developer.apple.com/documentation/objectivec/nsobject.
@FlutterApi()
abstract class NSObjectFlutterApi {
  @ObjCSelector(
    'observeValueForObjectWithIdentifier:keyPath:objectIdentifier:changeKeys:changeValues:',
  )
  void observeValue(
    int identifier,
    String keyPath,
    int objectIdentifier,
    // TODO(bparrishMines): Change to a map when Objective-C data classes conform
    // to `NSCopying`. See https://github.com/flutter/flutter/issues/103383.
    // `NSDictionary`s are unable to use data classes as keys because they don't
    // conform to `NSCopying`. This splits the map of properties into a list of
    // keys and values with the ordered maintained.
    List<NSKeyValueChangeKeyEnumData?> changeKeys,
    List<Object?> changeValues,
  );

  @ObjCSelector('disposeObjectWithIdentifier:')
  void dispose(int identifier);
}

/// Mirror of WKWebView.
///
/// See https://developer.apple.com/documentation/webkit/wkwebview?language=objc.
@HostApi(dartHostTestHandler: 'TestWKWebViewHostApi')
abstract class WKWebViewHostApi {
  @ObjCSelector('createWithIdentifier:configurationIdentifier:')
  void create(int identifier, int configurationIdentifier);

  @ObjCSelector('setUIDelegateForWebViewWithIdentifier:delegateIdentifier:')
  void setUIDelegate(int identifier, int? uiDelegateIdentifier);

  @ObjCSelector(
    'setNavigationDelegateForWebViewWithIdentifier:delegateIdentifier:',
  )
  void setNavigationDelegate(int identifier, int? navigationDelegateIdentifier);

  @ObjCSelector('URLForWebViewWithIdentifier:')
  String? getUrl(int identifier);

  @ObjCSelector('estimatedProgressForWebViewWithIdentifier:')
  double getEstimatedProgress(int identifier);

  @ObjCSelector('loadRequestForWebViewWithIdentifier:request:')
  void loadRequest(int identifier, NSUrlRequestData request);

  @ObjCSelector('loadHTMLForWebViewWithIdentifier:HTMLString:baseURL:')
  void loadHtmlString(int identifier, String string, String? baseUrl);

  @ObjCSelector('loadFileForWebViewWithIdentifier:fileURL:readAccessURL:')
  void loadFileUrl(int identifier, String url, String readAccessUrl);

  @ObjCSelector('loadAssetForWebViewWithIdentifier:assetKey:')
  void loadFlutterAsset(int identifier, String key);

  @ObjCSelector('canGoBackForWebViewWithIdentifier:')
  bool canGoBack(int identifier);

  @ObjCSelector('canGoForwardForWebViewWithIdentifier:')
  bool canGoForward(int identifier);

  @ObjCSelector('goBackForWebViewWithIdentifier:')
  void goBack(int identifier);

  @ObjCSelector('goForwardForWebViewWithIdentifier:')
  void goForward(int identifier);

  @ObjCSelector('reloadWebViewWithIdentifier:')
  void reload(int identifier);

  @ObjCSelector('titleForWebViewWithIdentifier:')
  String? getTitle(int identifier);

  @ObjCSelector('setAllowsBackForwardForWebViewWithIdentifier:isAllowed:')
  void setAllowsBackForwardNavigationGestures(int identifier, bool allow);

  @ObjCSelector('setUserAgentForWebViewWithIdentifier:userAgent:')
  void setCustomUserAgent(int identifier, String? userAgent);

  @ObjCSelector('evaluateJavaScriptForWebViewWithIdentifier:javaScriptString:')
  @async
  Object? evaluateJavaScript(int identifier, String javaScriptString);
}

/// Mirror of WKUIDelegate.
///
/// See https://developer.apple.com/documentation/webkit/wkuidelegate?language=objc.
@HostApi(dartHostTestHandler: 'TestWKUIDelegateHostApi')
abstract class WKUIDelegateHostApi {
  @ObjCSelector('createWithIdentifier:')
  void create(int identifier);
}

/// Handles callbacks from an WKUIDelegate instance.
///
/// See https://developer.apple.com/documentation/webkit/wkuidelegate?language=objc.
@FlutterApi()
abstract class WKUIDelegateFlutterApi {
  @ObjCSelector(
    'onCreateWebViewForDelegateWithIdentifier:webViewIdentifier:configurationIdentifier:navigationAction:',
  )
  void onCreateWebView(
    int identifier,
    int webViewIdentifier,
    int configurationIdentifier,
    WKNavigationActionData navigationAction,
  );
}

/// Mirror of WKHttpCookieStore.
///
/// See https://developer.apple.com/documentation/webkit/wkhttpcookiestore?language=objc.
@HostApi(dartHostTestHandler: 'TestWKHttpCookieStoreHostApi')
abstract class WKHttpCookieStoreHostApi {
  @ObjCSelector('createFromWebsiteDataStoreWithIdentifier:dataStoreIdentifier:')
  void createFromWebsiteDataStore(
    int identifier,
    int websiteDataStoreIdentifier,
  );

  @ObjCSelector('setCookieForStoreWithIdentifier:cookie:')
  @async
  void setCookie(int identifier, NSHttpCookieData cookie);
}
