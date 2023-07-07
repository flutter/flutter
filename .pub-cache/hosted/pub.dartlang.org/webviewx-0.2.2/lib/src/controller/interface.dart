import 'package:webviewx/src/utils/source_type.dart';
import 'package:webviewx/src/utils/webview_content_model.dart';

/// Interface for controller
abstract class WebViewXController<T> {
  /// Cross-platform webview connector
  ///
  /// At runtime, this will be WebViewController, JsObject or other concrete
  /// controller implementation
  late T connector;

  /// Boolean getter which reveals if the gestures are ignored right now
  bool get ignoresAllGestures;

  /// Function to set ignoring gestures
  void setIgnoreAllGestures(bool value);

  /// Returns true if the webview's current content is HTML
  bool get isCurrentContentHTML;

  /// Returns true if the webview's current content is URL
  bool get isCurrentContentURL;

  /// Returns true if the webview's current content is URL, and if
  /// [SourceType] is [SourceType.urlBypass], which means it should
  /// use the bypass to fetch the web page content.
  bool get isCurrentContentURLBypass;

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
  Future<void> loadContent(
    String content,
    SourceType sourceType, {
    Map<String, String>? headers,
    Object? body,
    bool fromAssets = false,
  });

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
  Future<dynamic> callJsMethod(
    String name,
    List<dynamic> params,
  );

  /// This function allows you to evaluate 'raw' javascript (e.g: 2+2)
  /// If you need to call a function you should use the method above ([callJsMethod])
  ///
  /// The [inGlobalContext] param should be set to true if you wish to eval your code
  /// in the 'window' context, instead of doing it inside the corresponding iframe's 'window'
  ///
  /// For more info, check Mozilla documentation on 'window'
  Future<dynamic> evalRawJavascript(
    String rawJavascript, {
    bool inGlobalContext = false,
  });

  /// Returns the current content
  Future<WebViewContent> getContent();

  /// Returns a Future that completes with the value true, if you can go
  /// back in the history stack.
  Future<bool> canGoBack();

  /// Go back in the history stack.
  Future<void> goBack();

  /// Returns a Future that completes with the value true, if you can go
  /// forward in the history stack.
  Future<bool> canGoForward();

  /// Go forward in the history stack.
  Future<void> goForward();

  /// Reload the current content.
  Future<void> reload();

  /// Get scroll position on X axis
  Future<int> getScrollX();

  /// Get scroll position on Y axis
  Future<int> getScrollY();

  /// Scrolls by `x` on X axis and by `y` on Y axis
  Future<void> scrollBy(int x, int y);

  /// Scrolls exactly to the position `(x, y)`
  Future<void> scrollTo(int x, int y);

  /// Retrieves the inner page title
  Future<String?> getTitle();

  /// Clears cache
  Future<void> clearCache();

  /// Dispose resources
  void dispose();
}
