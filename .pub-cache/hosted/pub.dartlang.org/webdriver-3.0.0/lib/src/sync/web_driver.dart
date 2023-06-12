// Copyright 2017 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:convert' show base64;

import '../../async_core.dart' as async_core;
import '../common/by.dart';
import '../common/request.dart';
import '../common/request_client.dart';
import '../common/spec.dart';
import '../common/utils.dart';
import '../common/webdriver_handler.dart';
import 'common.dart';

// ignore: uri_does_not_exist
import 'common_stub.dart'
// ignore: uri_does_not_exist
    if (dart.library.io) 'common_io.dart';
import 'cookies.dart';
import 'keyboard.dart';
import 'logs.dart';
import 'mouse.dart';
import 'target_locator.dart';
import 'timeouts.dart';
import 'web_element.dart';
import 'window.dart';

/// Interacts with WebDriver.
class WebDriver implements SearchContext {
  final SyncRequestClient _client;

  final WebDriverHandler _handler;

  final Map<String, dynamic> capabilities;

  final WebDriverSpec spec;

  final String id;

  final Uri uri;

  WebDriver(this.uri, this.id, this.capabilities, this._client, this.spec)
      : _handler = getHandler(spec);

  /// Produces a [async_core.WebDriver] with the same session ID. Allows
  /// backwards compatibility with other frameworks.
  async_core.WebDriver get asyncDriver => createAsyncWebDriver(this);

  @override
  async_core.SearchContext get asyncContext => asyncDriver;

  /// Preferred method for registering listeners. Listeners are expected to
  /// return a Future. Use new Future.value() for synchronous listeners.
  void addEventListener(SyncWebDriverListener listener) {
    _client.addEventListener(listener);
  }

  /// The current url.
  String get currentUrl => _client.send(_handler.core.buildCurrentUrlRequest(),
      _handler.core.parseCurrentUrlResponse);

  /// Navigates to the specified url
  void get(/* Uri | String */ url) {
    _client.send(
        _handler.navigation.buildNavigateToRequest(
          (url is Uri) ? url.toString() : url as String,
        ),
        _handler.navigation.parseNavigateToResponse);
  }

  ///  Navigates forwards in the browser history, if possible.
  void forward() {
    _client.send(_handler.navigation.buildForwardRequest(),
        _handler.navigation.parseForwardResponse);
  }

  /// Navigates backwards in the browser history, if possible.
  void back() {
    _client.send(_handler.navigation.buildBackRequest(),
        _handler.navigation.parseBackResponse);
  }

  /// Refreshes the current page.
  void refresh() {
    _client.send(_handler.navigation.buildRefreshRequest(),
        _handler.navigation.parseRefreshResponse);
  }

  /// The title of the current page.
  String get title => _client.send(
      _handler.core.buildTitleRequest(), _handler.core.parseTitleResponse);

  /// Search for multiple elements within the entire current page.
  @override
  List<WebElement> findElements(By by) {
    final ids = _client.send(
        _handler.elementFinder.buildFindElementsRequest(by),
        _handler.elementFinder.parseFindElementsResponse);

    final elements = <WebElement>[];
    var i = 0;
    for (final id in ids) {
      elements.add(WebElement(this, _client, _handler, id, this, by, i++));
    }

    return elements;
  }

  /// Search for an element within the entire current page.
  /// Throws [NoSuchElementException] if a matching element is not found.
  @override
  WebElement findElement(By by) => WebElement(
      this,
      _client,
      _handler,
      _client.send(_handler.elementFinder.buildFindElementRequest(by),
          _handler.elementFinder.parseFindElementResponse),
      this,
      by);

  /// Search for an element by xpath within the entire current page.
  /// Throws [NoSuchElementException] if a matching element is not found.
  WebElement findElementByXpath(String by) => findElement(By.xpath(by));

  /// An artist's rendition of the current page's source.
  String get pageSource => _client.send(_handler.core.buildPageSourceRequest(),
      _handler.core.parsePageSourceResponse);

  /// Quits the browser.
  void quit({bool closeSession = true}) {
    if (closeSession) {
      _client.send(_handler.core.buildDeleteSessionRequest(),
          _handler.core.parseDeleteSessionResponse);
    }
  }

  /// Closes the current window.
  ///
  /// This is rather confusing and will be removed.
  /// Should replace all usages with [window.close()] or [quit()].
  @deprecated
  void close() {
    window.close();
  }

  /// Handles for all of the currently displayed tabs/windows.
  List<Window> get windows => _client.send(
      _handler.window.buildGetWindowsRequest(),
      (response) => _handler.window
          .parseGetWindowsResponse(response)
          .map<Window>((w) => Window(_client, _handler, w))
          .toList());

  /// Handle for the active tab/window.
  Window get window => _client.send(
      _handler.window.buildGetActiveWindowRequest(),
      (response) => Window(_client, _handler,
          _handler.window.parseGetActiveWindowResponse(response)));

  /// The currently focused element, or the body element if no element has
  /// focus.
  WebElement? get activeElement {
    final id = _client.send(
        _handler.elementFinder.buildFindActiveElementRequest(),
        _handler.elementFinder.parseFindActiveElementResponse);
    if (id != null) {
      return WebElement(this, _client, _handler, id, this, 'activeElement');
    }
    return null;
  }

  /// Changes focus to specified targets.
  ///
  /// Available targets are window, frame, and the current alert.
  TargetLocator get switchTo => TargetLocator(this, _client, _handler);

  Cookies get cookies => Cookies(_client, _handler);

  /// [logs.get(logType)] will give list of logs captured in browser.
  ///
  /// Note that for W3C/Firefox, this is not supported and will produce empty
  /// list of logs, as the spec for this in W3C is not agreed on and Firefox
  /// refuses to support non-spec features. See
  /// https://github.com/w3c/webdriver/issues/406.
  Logs get logs => Logs(_client, _handler);

  Timeouts get timeouts => Timeouts(_client, _handler);

  Keyboard get keyboard => Keyboard(_client, _handler);

  Mouse get mouse => Mouse(_client, _handler);

  /// Take a screenshot of the current page as PNG and return it as
  /// base64-encoded string.
  String captureScreenshotAsBase64() => _client.send(
      _handler.core.buildScreenshotRequest(),
      _handler.core.parseScreenshotResponse);

  /// Take a screenshot of the specified element as PNG and return it as
  /// base64-encoded string.
  String captureElementScreenshotAsBase64(WebElement element) => _client.send(
      _handler.core.buildElementScreenshotRequest(element.id),
      _handler.core.parseScreenshotResponse);

  /// Take a screenshot of the current page as PNG as list of uint8.
  List<int> captureScreenshotAsList() {
    final base64Encoded = captureScreenshotAsBase64();
    return base64.decode(base64Encoded);
  }

  /// Take a screenshot of the specified element as PNG as list of uint8.
  List<int> captureElementScreenshotAsList(WebElement element) {
    final base64Encoded = captureElementScreenshotAsBase64(element);
    return base64.decode(base64Encoded);
  }

  /// Inject a snippet of JavaScript into the page for execution in the context
  /// of the currently selected frame. The executed script is assumed to be
  /// asynchronous and must signal that is done by invoking the provided
  /// callback, which is always provided as the final argument to the function.
  /// The value to this callback will be returned to the client.
  ///
  /// Asynchronous script commands may not span page loads. If an unload event
  /// is fired while waiting for a script result, an error will be thrown.
  ///
  /// The script argument defines the script to execute in the form of a
  /// function body. The function will be invoked with the provided args array
  /// and the values may be accessed via the arguments object in the order
  /// specified. The final argument will always be a callback function that must
  /// be invoked to signal that the script has finished.
  ///
  /// Arguments may be any JSON-able object. WebElements will be converted to
  /// the corresponding DOM element. Likewise, any DOM Elements in the script
  /// result will be converted to WebElements.
  dynamic executeAsync(String script, List args) => _client.send(
      _handler.core.buildExecuteAsyncRequest(script, args),
      (response) => _handler.core.parseExecuteAsyncResponse(
          response,
          (elementId) => WebElement(
              this, _client, _handler, elementId, this, 'javascript')));

  /// Inject a snippet of JavaScript into the page for execution in the context
  /// of the currently selected frame. The executed script is assumed to be
  /// synchronous and the result of evaluating the script is returned.
  ///
  /// The script argument defines the script to execute in the form of a
  /// function body. The value returned by that function will be returned to the
  /// client. The function will be invoked with the provided args array and the
  /// values may be accessed via the arguments object in the order specified.
  ///
  /// Arguments may be any JSON-able object. WebElements will be converted to
  /// the corresponding DOM element. Likewise, any DOM Elements in the script
  /// result will be converted to WebElements.
  dynamic execute(String script, List args) => _client.send(
      _handler.core.buildExecuteRequest(script, args),
      (response) => _handler.core.parseExecuteResponse(
          response,
          (elementId) => WebElement(
              this, _client, _handler, elementId, this, 'javascript')));

  /// Performs post request on command to the WebDriver server.
  ///
  /// For use by supporting WebDriver packages.
  dynamic postRequest(String command, [params]) => _client.send(
      _handler.buildGeneralRequest(HttpMethod.httpPost, command, params),
      (response) => _handler.parseGeneralResponse(
          response, (elementId) => getElement(elementId, this)));

  /// Performs get request on command to the WebDriver server.
  ///
  /// For use by supporting WebDriver packages.
  dynamic getRequest(String command) => _client.send(
      _handler.buildGeneralRequest(HttpMethod.httpGet, command),
      (response) => _handler.parseGeneralResponse(
          response, (elementId) => getElement(elementId, this)));

  /// Performs delete request on command to the WebDriver server.
  ///
  /// For use by supporting WebDriver packages.
  dynamic deleteRequest(String command) => _client.send(
        _handler.buildGeneralRequest(HttpMethod.httpDelete, command),
        (response) => _handler.parseGeneralResponse(
          response,
          (elementId) => getElement(elementId, this),
        ),
      );

  WebElement getElement(
    String elementId, [
    SearchContext? context,
    locator,
    int? index,
  ]) =>
      WebElement(
        this,
        _client,
        _handler,
        elementId,
        context,
        locator,
        index,
      );

  @override
  WebDriver get driver => this;

  @override
  String toString() => '$_handler.webdriver($_client)';
}
