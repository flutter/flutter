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

import 'dart:math' show Point, Rectangle;

import '../../async_core.dart' as async_core;
import '../common/by.dart';
import '../common/request_client.dart';
import '../common/web_element.dart' as common;
import '../common/webdriver_handler.dart';
import 'common.dart';

// ignore: uri_does_not_exist
import 'common_stub.dart'
// ignore: uri_does_not_exist
    if (dart.library.io) 'common_io.dart';
import 'web_driver.dart';

/// WebDriver representation and interactions with an HTML element.
class WebElement extends common.WebElement implements SearchContext {
  @override
  final String id;

  /// Produces a compatible [async_core.WebElement]. Allows backwards
  /// compatibility with other frameworks.
  async_core.WebElement get asyncElement => createAsyncWebElement(this);

  @override
  async_core.SearchContext get asyncContext => asyncElement;

  /// The context from which this element was found.
  final SearchContext? context;

  @override
  final WebDriver driver;

  final SyncRequestClient _client;

  final WebDriverHandler _handler;

  /// How the element was located from the context.
  final dynamic /* String | Finder */ locator;

  /// The index of this element in the set of element founds. If the method
  /// used to find this element always returns one element, then this is null.
  final int? index;

  WebElement(
    this.driver,
    this._client,
    this._handler,
    this.id, [
    this.context,
    this.locator,
    this.index,
  ]);

  WebElement? get parent {
    final parentId = _parentId;
    if (parentId == null) {
      return null;
    }
    return WebElement(
      driver,
      _client,
      _handler,
      parentId,
    );
  }

  String? get _parentId => _client.send(
        _handler.element.buildPropertyRequest(id, 'parentElement'),
        _handler.elementFinder.parseFindElementResponseCore,
      );

  static final _parentCache = <String, String?>{};

  /// Gets a chain of parent elements, including the element itself.
  List<String> get parents {
    WebElement? p = this;
    final result = <String>[];
    while (p != null) {
      var id = p.id;
      if (_parentCache.containsKey(id)) {
        break;
      }
      result.add(id);
      _parentCache[id] = (p = p.parent)?.id;
    }

    if (p != null) {
      // Hit cache in the previous loop.
      String? id = p.id;
      while (id != null) {
        result.add(id);
        id = _parentCache[id];
      }
    }

    return result;
  }

  /// Click on this element.
  void click() {
    _client.send(_handler.element.buildClickRequest(id),
        _handler.element.parseClickResponse);
  }

  /// Send [keysToSend] to this element.
  void sendKeys(String keysToSend) {
    _client.send(_handler.element.buildSendKeysRequest(id, keysToSend),
        _handler.element.parseSendKeysResponse);
  }

  /// Clear the content of a text element.
  void clear() {
    _client.send(_handler.element.buildClearRequest(id),
        _handler.element.parseClearResponse);
  }

  /// Is this radio button/checkbox selected?
  bool get selected => _client.send(_handler.element.buildSelectedRequest(id),
      _handler.element.parseSelectedResponse);

  /// Is this form element enabled?
  bool get enabled => _client.send(_handler.element.buildEnabledRequest(id),
      _handler.element.parseEnabledResponse);

  /// Is this element visible in the page?
  bool get displayed => _client.send(_handler.element.buildDisplayedRequest(id),
      _handler.element.parseDisplayedResponse);

  /// The location of the element.
  ///
  /// This is assumed to be the upper left corner of the element, but its
  /// implementation is not well defined in the JSON spec.
  Point<int> get location => _client.send(
      _handler.element.buildLocationRequest(id),
      _handler.element.parseLocationResponse);

  /// The size of this element.
  Rectangle<int> get size => _client.send(_handler.element.buildSizeRequest(id),
      _handler.element.parseSizeResponse);

  /// The bounds of this element.
  Rectangle<int> get rect {
    final location = this.location;
    final size = this.size;
    return Rectangle<int>(location.x, location.y, size.width, size.height);
  }

  /// The tag name for this element.
  String get name => _client.send(_handler.element.buildNameRequest(id),
      _handler.element.parseNameResponse);

  ///  Visible text within this element.
  String get text => _client.send(_handler.element.buildTextRequest(id),
      _handler.element.parseTextResponse);

  ///Find an element nested within this element.
  ///
  /// Throws [NoSuchElementException] if matching element is not found.
  @override
  WebElement findElement(By by) => WebElement(
      driver,
      _client,
      _handler,
      _client.send(_handler.elementFinder.buildFindElementRequest(by, id),
          _handler.elementFinder.parseFindElementResponse),
      this,
      by);

  /// Find multiple elements nested within this element.
  @override
  List<WebElement> findElements(By by) {
    final ids = _client.send(
        _handler.elementFinder.buildFindElementsRequest(by, id),
        _handler.elementFinder.parseFindElementsResponse);

    final elements = <WebElement>[];
    var i = 0;
    for (final id in ids) {
      elements.add(WebElement(driver, _client, _handler, id, this, by, i++));
    }

    return elements;
  }

  /// Access to the HTML attributes of this tag.
  Attributes get attributes => Attributes((name) => _client.send(
      _handler.element.buildAttributeRequest(id, name),
      _handler.element.parseAttributeResponse));

  /// Access to the HTML properties of this tag.
  Attributes get properties => Attributes((name) => _client.send(
      _handler.element.buildPropertyRequest(id, name),
      _handler.element.parsePropertyResponse));

  /// Access to the cssProperties of this element.
  Attributes get cssProperties => Attributes((name) => _client.send(
      _handler.element.buildCssPropertyRequest(id, name),
      _handler.element.parseCssPropertyResponse));

  /// Are these two elements the same underlying element in the DOM.
  bool equals(WebElement other) =>
      other is WebElement && other.driver == driver && other.id == id;

  @override
  int get hashCode => driver.hashCode * 3 + id.hashCode;

  @override
  bool operator ==(other) =>
      other is WebElement && other.driver == driver && other.id == id;

  @override
  String toString() {
    final out = StringBuffer()..write(context);
    if (locator is By) {
      if (index == null) {
        out.write('.findElement(');
      } else {
        out.write('.findElements(');
      }
      out..write(locator)..write(')');
    } else {
      out..write('.')..write(locator);
    }
    if (index != null) {
      out..write('[')..write(index)..write(']');
    }
    return out.toString();
  }

  String toStringDeep() => "<$name>\n\nHTML:\n${properties['outerHTML']}";
}
