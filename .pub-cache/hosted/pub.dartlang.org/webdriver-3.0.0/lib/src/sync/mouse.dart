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

import '../common/mouse.dart';
import '../common/request_client.dart';
import '../common/webdriver_handler.dart';
import '../handler/json_wire_handler.dart';
import '../handler/w3c_handler.dart';

import 'web_element.dart';

class Mouse {
  final SyncRequestClient _client;
  final WebDriverHandler _handler;

  Mouse(this._client, this._handler);

  /// Click any mouse button (at the coordinates set by the last moveTo).
  void click([MouseButton button = MouseButton.primary]) {
    _client.send(_handler.mouse.buildClickRequest(button),
        _handler.mouse.parseClickResponse);
  }

  /// Click and hold any mouse button (at the coordinates set by the last
  /// moveTo command).
  void down([MouseButton button = MouseButton.primary]) {
    _client.send(_handler.mouse.buildDownRequest(button),
        _handler.mouse.parseDownResponse);
  }

  /// Releases the mouse button previously held (where the mouse is
  /// currently at).
  void up([MouseButton button = MouseButton.primary]) {
    _client.send(
        _handler.mouse.buildUpRequest(button), _handler.mouse.parseUpResponse);
  }

  /// Double-clicks at the current mouse coordinates (set by moveTo).
  void doubleClick() {
    _client.send(_handler.mouse.buildDoubleClickRequest(),
        _handler.mouse.parseDoubleClickResponse);
  }

  /// Move the mouse.
  ///
  /// If [absolute] is set to true, will move the mouse to the offset relative
  /// to web page's top left corner. This is only supported in W3C webdriver.
  ///
  /// If [element] is specified and [xOffset] and [yOffset] are not, will move
  /// the mouse to the center of the [element].
  ///
  /// If [xOffset] and [yOffset] are specified, will move the mouse that
  /// distance from its current location.
  ///
  /// If all three are specified, the behavior will be different
  /// for W3C and JsonWire. For W3C, it will use [element] center as the
  /// origin, while for JsonWire, it will use [element] top left corner.
  /// To get a consistent behavior across browsers, you can try
  /// [moveToElementCenter] and [moveToElementTopLeft] to specify the origin you
  /// would like to use.
  ///
  /// All other combinations of parameters are illegal.
  ///
  /// Special notes for W3C, if the destination is out of the current viewport,
  /// an 'MoveTargetOutOfBounds' exception will be thrown.
  void moveTo(
      {WebElement? element,
      int? xOffset,
      int? yOffset,
      bool absolute = false}) {
    _client.send(
        _handler.mouse.buildMoveToRequest(
            elementId: element?.id,
            xOffset: xOffset,
            yOffset: yOffset,
            absolute: absolute),
        _handler.mouse.parseMoveToResponse);
  }

  /// Moves to [element], with an offset of [xOffset] and [yOffset] based on the
  /// center of [element].
  void moveToElementCenter(WebElement element, {int? xOffset, int? yOffset}) {
    if (_handler is JsonWireWebDriverHandler) {
      final size = element.size;
      moveTo(
          element: element,
          xOffset: (xOffset ?? 0) + size.width ~/ 2,
          yOffset: (yOffset ?? 0) + size.height ~/ 2);
    } else {
      moveTo(element: element, xOffset: xOffset, yOffset: yOffset);
    }
  }

  /// Moves to [element], with an offset of [xOffset] and [yOffset] based on the
  /// top left corner of [element].
  void moveToElementTopLeft(WebElement element, {int? xOffset, int? yOffset}) {
    if (_handler is W3cWebDriverHandler) {
      final size = element.size;
      moveTo(
          element: element,
          xOffset: (xOffset ?? 0) - size.width ~/ 2,
          yOffset: (yOffset ?? 0) - size.height ~/ 2);
    } else {
      moveTo(element: element, xOffset: xOffset, yOffset: yOffset);
    }
  }

  /// Moves the mouse away to hide its effect, like hover over element.
  ///
  /// For W3C, the mouse cannot move out of the screen, the workaround would be
  /// to move to somewhere on edge where it's not on any element. You can
  /// configure the location with [w3cXOffset] and [w3cYOffset]. By default,
  /// it's at (100, 0).
  void hide({int w3cXOffset = 100, int w3cYOffset = 0}) =>
      _handler is W3cWebDriverHandler
          ? moveTo(xOffset: w3cXOffset, yOffset: w3cYOffset, absolute: true)
          : moveTo(xOffset: -10000, yOffset: -10000);

  @override
  String toString() => '$_handler.mouse($_client)';

  @override
  int get hashCode => _client.hashCode;

  @override
  bool operator ==(other) =>
      other is Mouse && _handler == other._handler && _client == other._client;
}
