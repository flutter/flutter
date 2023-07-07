import 'dart:async' show Future;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webviewx/src/utils/logger.dart';
import 'package:webviewx/src/utils/source_type.dart';
import 'package:webviewx/src/utils/utils.dart';
import 'package:webviewx/src/utils/web_history.dart';

import 'package:webviewx/src/controller/interface.dart' as i;

/// Web implementation
class WebViewXController extends ChangeNotifier
    implements i.WebViewXController<js.JsObject> {
  /// JsObject connector
  @override
  late js.JsObject connector;

  // Boolean value notifier used to toggle ignoring gestures on the webview
  final ValueNotifier<bool> _ignoreAllGesturesNotifier;

  // Stack-based custom history
  // First entry is the current url, last entry is the initial url
  final HistoryStack<WebViewContent> _history;

  /// INTERNAL
  WebViewContent get value => _history.currentEntry;

  /// Constructor
  WebViewXController({
    required String initialContent,
    required SourceType initialSourceType,
    required bool ignoreAllGestures,
  })  : _ignoreAllGesturesNotifier = ValueNotifier(ignoreAllGestures),
        _history = HistoryStack<WebViewContent>(
          initialEntry: WebViewContent(
            source: initialContent,
            sourceType: initialSourceType,
          ),
        );

  /// Boolean getter which reveals if the gestures are ignored right now
  @override
  bool get ignoresAllGestures => _ignoreAllGesturesNotifier.value;

  /// Function to set ignoring gestures
  @override
  void setIgnoreAllGestures(bool value) {
    _ignoreAllGesturesNotifier.value = value;
  }

  /// Returns true if the webview's current content is HTML
  @override
  bool get isCurrentContentHTML => value.sourceType == SourceType.html;

  /// Returns true if the webview's current content is URL
  @override
  bool get isCurrentContentURL => value.sourceType == SourceType.url;

  /// Returns true if the webview's current content is URL, and if
  /// [SourceType] is [SourceType.urlBypass], which means it should
  /// use the proxy bypass to fetch the web page content.
  @override
  bool get isCurrentContentURLBypass =>
      value.sourceType == SourceType.urlBypass;

  /// Set webview content to the specified `content`.
  /// Example: https://flutter.dev/
  /// Example2: '<html><head></head> <body> <p> Hi </p> </body></html>
  ///
  /// If `fromAssets` param is set to true,
  /// `content` param must be a String path to an asset
  /// Example: `assets/some_url.txt`
  ///
  /// `headers` are optional HTTP headers.
  ///
  /// `body` is only used on the WEB version, when clicking on a submit button in a form
  ///
  @override
  Future<void> loadContent(
    String content,
    SourceType sourceType, {
    Map<String, String>? headers,
    Object? body,
    bool fromAssets = false,
  }) async {
    WebViewContent newContent;

    if (fromAssets) {
      final _contentFromAssets = await rootBundle.loadString(content);

      newContent = WebViewContent(
        source: _contentFromAssets,
        sourceType: sourceType,
        headers: headers,
        webPostRequestBody: body,
      );
    } else {
      newContent = WebViewContent(
        source: content,
        sourceType: sourceType,
        headers: headers,
        webPostRequestBody: body,
      );
    }

    webRegisterNewHistoryEntry(newContent);
    _notifyWidget();
  }

  /// This function allows you to call Javascript functions defined inside the webview.
  ///
  /// Suppose we have a defined a function (using [EmbeddedJsContent]) as follows:
  ///
  /// ```javascript
  /// function someFunction(param) {
  ///   return 'This is a ' + param;
  /// }
  /// ```
  /// Example call:
  ///
  /// ```dart
  /// var resultFromJs = await callJsMethod('someFunction', ['test'])
  /// print(resultFromJs); // prints "This is a test"
  /// ```
  @override
  Future<dynamic> callJsMethod(
    String name,
    List<dynamic> params,
  ) {
    final result = connector.callMethod(name, params);
    return Future<dynamic>.value(result);
  }

  /// This function allows you to evaluate 'raw' javascript (e.g: 2+2)
  /// If you need to call a function you should use the method above ([callJsMethod])
  ///
  /// The [inGlobalContext] param should be set to true if you wish to eval your code
  /// in the 'window' context, instead of doing it inside the corresponding iframe's 'window'
  ///
  /// For more info, check Mozilla documentation on 'window'
  @override
  Future<dynamic> evalRawJavascript(
    String rawJavascript, {
    bool inGlobalContext = false,
  }) {
    final result = (inGlobalContext ? js.context : connector).callMethod(
      'eval',
      [rawJavascript],
    );
    return Future<dynamic>.value(result);
  }

  /// Returns the current content
  @override
  Future<WebViewContent> getContent() {
    return Future.value(value);
  }

  /// Returns a Future that completes with the value true, if you can go
  /// back in the history stack.
  @override
  Future<bool> canGoBack() {
    return Future.value(_history.canGoBack);
  }

  /// Go back in the history stack.
  @override
  Future<void> goBack() async {
    _history.moveBack();
    log('Current history: ${_history.toString()}');

    _notifyWidget();
  }

  /// Returns a Future that completes with the value true, if you can go
  /// forward in the history stack.
  @override
  Future<bool> canGoForward() {
    return Future.value(_history.canGoForward);
  }

  /// Go forward in the history stack.
  @override
  Future<void> goForward() async {
    _history.moveForward();
    log('Current history: ${_history.toString()}');

    _notifyWidget();
  }

  /// Reload the current content.
  @override
  Future<void> reload() async {
    _notifyWidget();
  }

  /// Get scroll position on X axis
  @override
  Future<int> getScrollX() {
    return Future.value(int.tryParse(connector["scrollX"].toString()));
  }

  /// Get scroll position on Y axis
  @override
  Future<int> getScrollY() {
    return Future.value(int.tryParse(connector["scrollY"].toString()));
  }

  /// Scrolls by `x` on X axis and by `y` on Y axis
  @override
  Future<void> scrollBy(int x, int y) {
    return callJsMethod('scrollBy', [x, y]);
  }

  /// Scrolls exactly to the position `(x, y)`
  @override
  Future<void> scrollTo(int x, int y) {
    return callJsMethod('scrollTo', [x, y]);
  }

  /// Retrieves the inner page title
  @override
  Future<String?> getTitle() {
    return Future.value(connector["document"]["title"].toString());
  }

  /// Clears cache
  @override
  Future<void> clearCache() {
    connector["localStorage"].callMethod("clear", []);
    evalRawJavascript(
      'caches.keys().then((keyList) => Promise.all(keyList.map((key) => caches.delete(key))))',
    );
    return reload();
  }

  /// INTERNAL
  /// WEB-ONLY
  ///
  /// This is called internally by the web.dart view class, to add a new
  /// iframe navigation history entry.
  ///
  /// This, and all history-related stuff is needed because the history on web
  /// is basically reimplemented by me from scratch using the [HistoryEntry] class.
  /// This had to be done because I couldn't intercept iframe's navigation events and
  /// current url.
  void webRegisterNewHistoryEntry(WebViewContent content) {
    _history.addEntry(content);
  }

  /// INTERNAL
  void addIgnoreGesturesListener(void Function() cb) {
    _ignoreAllGesturesNotifier.addListener(cb);
  }

  /// INTERNAL
  void removeIgnoreGesturesListener(void Function() cb) {
    _ignoreAllGesturesNotifier.removeListener(cb);
  }

  void _notifyWidget() {
    notifyListeners();
  }

  /// Dispose resources
  @override
  void dispose() {
    _ignoreAllGesturesNotifier.dispose();
    super.dispose();
  }
}
