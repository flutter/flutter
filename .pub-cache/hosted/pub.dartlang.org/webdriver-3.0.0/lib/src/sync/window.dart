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

import '../common/request_client.dart';
import '../common/webdriver_handler.dart';

/// Handle to window.
///
/// Upon use, the window will automatically be set as active.
class Window {
  final SyncRequestClient _client;
  final WebDriverHandler _handler;
  final String id;

  Window(this._client, this._handler, this.id);

  /// Sets the window as active.
  void setAsActive() {
    _client.send(_handler.window.buildSetActiveRequest(id),
        _handler.window.parseSetActiveResponse);
  }

  /// The location of the window.
  Point<int> get location => _client.send(
      _handler.window.buildLocationRequest(),
      _handler.window.parseLocationResponse);

  /// The outer size of the window.
  Rectangle<int> get size => _client.send(
      _handler.window.buildSizeRequest(), _handler.window.parseSizeResponse);

  /// The inner size of the window.
  Rectangle<int> get innerSize => _client.send(
      _handler.window.buildInnerSizeRequest(),
      _handler.window.parseInnerSizeResponse);

  /// The location and size of the window.
  Rectangle<int> get rect {
    try {
      return _client.send(_handler.window.buildRectRequest(),
          _handler.window.parseRectResponse);
    } on UnsupportedError {
      // JsonWire cannot implement this API in one call.
      // Delegate to other methods.
      final location = this.location;
      final size = this.size;
      return Rectangle<int>(location.x, location.y, size.width, size.height);
    }
  }

  /// Sets the window location.
  ///
  /// TODO(jingbian): Remove this, prefer setter.
  void setLocation(Point<int> point) {
    location = point;
  }

  /// Sets the window location.
  set location(Point<int> value) {
    _client.send(_handler.window.buildSetLocationRequest(value),
        _handler.window.parseSetLocationResponse);
  }

  /// Sets the window size.
  ///
  /// TODO(jingbian): Remove this, prefer setter.
  void setSize(Rectangle<int> size) {
    this.size = size;
  }

  /// Sets the window size.
  set size(Rectangle<int> value) {
    _client.send(_handler.window.buildSetSizeRequest(value),
        _handler.window.parseSetSizeResponse);
  }

  /// The location and size of the window.
  set rect(Rectangle<int> value) {
    try {
      _client.send(_handler.window.buildSetRectRequest(value),
          _handler.window.parseSetRectResponse);
      return;
    } on UnsupportedError {
      // JsonWire cannot implement this API in one call.
      // Delegate to other methods.
      location = value.topLeft;
      size = Rectangle(0, 0, value.width, value.height);
    }
  }

  /// Maximizes the window.
  void maximize() {
    _client.send(_handler.window.buildMaximizeRequest(),
        _handler.window.parseMaximizeResponse);
  }

  /// Minimizes the window.
  ///
  /// Unsupported in JsonWire WebDriver.
  void minimize() {
    _client.send(_handler.window.buildMinimizeRequest(),
        _handler.window.parseMinimizeResponse);
  }

  /// Closes the window.
  void close() {
    _client.send(_handler.window.buildCloseRequest(),
        _handler.window.parseCloseResponse);
  }

  @override
  int get hashCode => id.hashCode + _client.hashCode;

  @override
  bool operator ==(other) =>
      other is Window &&
      other._client == _client &&
      other._handler == _handler &&
      other.id == id;

  @override
  String toString() => '$_handler.windows($_client)[$id]';
}
