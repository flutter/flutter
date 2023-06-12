// Copyright 2015 Google Inc. All Rights Reserved.
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

import 'dart:async';
import 'dart:convert';

import '../../sync_core.dart' as sync_core;
import '../common/by.dart';
import '../common/command_event.dart';
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
import 'stepper.dart' show Stepper;
import 'target_locator.dart';
import 'timeouts.dart';
import 'web_element.dart';
import 'window.dart';

class WebDriver implements SearchContext {
  final WebDriverSpec spec;
  final Map<String, dynamic> capabilities;
  final String id;
  final Uri uri;
  Stepper? stepper;

  /// If true, WebDriver actions are recorded as [WebDriverCommandEvent]s.
  bool notifyListeners = true;

  final _commandListeners = <AsyncWebDriverListener>[];

  final WebDriverHandler _handler;

  final AsyncRequestClient _client;

  WebDriver(this.uri, this.id, this.capabilities, this._client, this.spec)
      : _handler = getHandler(spec);

  /// Produces a [sync_core.WebDriver] with the same session ID. Allows
  /// forwards compatibility with other frameworks.
  sync_core.WebDriver get syncDriver => createSyncWebDriver(this);

  /// Preferred method for registering listeners. Listeners are expected to
  /// return a Future. Use new Future.value() for synchronous listeners.
  void addEventListener(AsyncWebDriverListener listener) {
    _commandListeners.add(listener);
    _client.addEventListener(listener);
  }

  /// The current url.
  Future<String> get currentUrl => _client.send(
      _handler.core.buildCurrentUrlRequest(),
      _handler.core.parseCurrentUrlResponse);

  /// Navigates to the specified url
  Future<void> get(/* Uri | String */ url) => _client.send(
      _handler.navigation.buildNavigateToRequest(
        (url is Uri) ? url.toString() : url as String,
      ),
      _handler.navigation.parseNavigateToResponse);

  ///  Navigates forwards in the browser history, if possible.
  Future<void> forward() => _client.send(
      _handler.navigation.buildForwardRequest(),
      _handler.navigation.parseForwardResponse);

  /// Navigates backwards in the browser history, if possible.
  Future<void> back() => _client.send(_handler.navigation.buildBackRequest(),
      _handler.navigation.parseBackResponse);

  /// Refreshes the current page.
  Future<void> refresh() => _client.send(
      _handler.navigation.buildRefreshRequest(),
      _handler.navigation.parseRefreshResponse);

  /// The title of the current page.
  Future<String> get title => _client.send(
      _handler.core.buildTitleRequest(), _handler.core.parseTitleResponse);

  /// Search for multiple elements within the entire current page.
  @override
  Stream<WebElement> findElements(By by) async* {
    final ids = await _client.send(
        _handler.elementFinder.buildFindElementsRequest(by),
        _handler.elementFinder.parseFindElementsResponse);
    var i = 0;

    for (var id in ids) {
      yield getElement(id, this, by, i);
      i++;
    }
  }

  /// Search for an element within the entire current page.
  /// Throws [NoSuchElementException] if a matching element is not found.
  @override
  Future<WebElement> findElement(By by) => _client.send(
      _handler.elementFinder.buildFindElementRequest(by),
      (response) => getElement(
          _handler.elementFinder.parseFindElementResponse(response), this, by));

  /// An artist's rendition of the current page's source.
  Future<String> get pageSource => _client.send(
      _handler.core.buildPageSourceRequest(),
      _handler.core.parsePageSourceResponse);

  /// Quits the browser.
  Future<void> quit({bool closeSession = true}) => closeSession
      ? _client.send(_handler.core.buildDeleteSessionRequest(),
          _handler.core.parseDeleteSessionResponse)
      : Future.value();

  /// Closes the current window.
  ///
  /// This is rather confusing and will be removed.
  /// Should replace all usages with [window.close()] or [quit()].
  @deprecated
  Future<void> close() async => (await window).close();

  /// Handles for all of the currently displayed tabs/windows.
  Stream<Window> get windows async* {
    final windows = await _client.send(
        _handler.window.buildGetWindowsRequest(),
        (response) => _handler.window
            .parseGetWindowsResponse(response)
            .map<Window>((w) => Window(_client, _handler, w)));
    for (final window in windows) {
      yield window;
    }
  }

  /// Handle for the active tab/window.
  Future<Window> get window => _client.send(
      _handler.window.buildGetActiveWindowRequest(),
      (response) => Window(_client, _handler,
          _handler.window.parseGetActiveWindowResponse(response)));

  /// The currently focused element, or the body element if no element has
  /// focus.
  Future<WebElement?> get activeElement async {
    final id = await _client.send(
        _handler.elementFinder.buildFindActiveElementRequest(),
        _handler.elementFinder.parseFindActiveElementResponse);
    if (id != null) {
      return getElement(id, this, 'activeElement');
    }
    return null;
  }

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
  Future<String> captureScreenshotAsBase64() => _client.send(
      _handler.core.buildScreenshotRequest(),
      _handler.core.parseScreenshotResponse);

  /// Take a screenshot of the specified element as PNG and return it as
  /// base64-encoded string.
  Future<String> captureElementScreenshotAsBase64(WebElement element) =>
      _client.send(_handler.core.buildElementScreenshotRequest(element.id),
          _handler.core.parseScreenshotResponse);

  /// Take a screenshot of the current page as PNG as list of uint8.
  Future<List<int>> captureScreenshotAsList() async {
    var base64Encoded = captureScreenshotAsBase64();
    return base64.decode(await base64Encoded);
  }

  /// Take a screenshot of the specified element as PNG as list of uint8.
  Future<List<int>> captureElementScreenshotAsList(WebElement element) async {
    var base64Encoded = captureElementScreenshotAsBase64(element);
    return base64.decode(await base64Encoded);
  }

  /// Take a screenshot of the current page as PNG as stream of uint8.
  ///
  /// Don't use this method. Prefer [captureScreenshotAsBase64] or
  /// [captureScreenshotAsList]. Returning the data as Stream<int> can be very
  /// slow.
  @Deprecated('Use captureScreenshotAsBase64 or captureScreenshotAsList!')
  Stream<int> captureScreenshot() async* {
    yield* Stream.fromIterable(await captureScreenshotAsList());
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
  Future<dynamic> executeAsync(String script, List args) => _client.send(
      _handler.core.buildExecuteAsyncRequest(script, args),
      (response) => _handler.core.parseExecuteAsyncResponse(
          response, (elementId) => getElement(elementId, this, 'javascript')));

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
  Future<dynamic> execute(String script, List args) => _client.send(
        _handler.core.buildExecuteRequest(script, args),
        (response) => _handler.core.parseExecuteResponse(
          response,
          (elementId) => getElement(elementId, this, 'javascript'),
        ),
      );

  Future<dynamic> postRequest(String command, [params]) => _client.send(
        _handler.buildGeneralRequest(HttpMethod.httpPost, command, params),
        (response) => _handler.parseGeneralResponse(
          response,
          (elementId) => getElement(elementId, this),
        ),
      );

  Future<dynamic> getRequest(String command) => _client.send(
        _handler.buildGeneralRequest(HttpMethod.httpGet, command),
        (response) => _handler.parseGeneralResponse(
          response,
          (elementId) => getElement(elementId, this),
        ),
      );

  Future<dynamic> deleteRequest(String command) => _client.send(
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
      WebElement(this, _client, _handler, elementId, context, locator, index);

  @override
  WebDriver get driver => this;

  @override
  String toString() => '$_handler.webdriver($_client)';
}
