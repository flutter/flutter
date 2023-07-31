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

import '../../async_core.dart';
import '../common/request_client.dart';
import '../common/webdriver_handler.dart';

class TargetLocator {
  final WebDriver _driver;
  final AsyncRequestClient _client;
  final WebDriverHandler _handler;

  TargetLocator(this._driver, this._client, this._handler);

  /// Changes focus to another frame on the page.
  /// If [frame] is a:
  ///   [int]: select by its zero-based index
  ///   [WebElement]: select the frame for a previously found frame or iframe
  ///       element.
  ///   [String]: same as above, but only CSS id is provided. Note that this
  ///       is not element id or frame id.
  ///   not provided: selects the first frame on the page or the main document.
  ///
  ///   Throws [NoSuchFrameException] if the specified frame can't be found.
  Future<void> frame([/* int | WebElement | String */ frame]) async {
    if (frame is int?) {
      await _client.send(_handler.frame.buildSwitchByIdRequest(frame),
          _handler.frame.parseSwitchByIdResponse);
    } else if (frame is WebElement) {
      await _client.send(_handler.frame.buildSwitchByElementRequest(frame.id),
          _handler.frame.parseSwitchByElementResponse);
    } else if (frame is String) {
      final frameId = (await _driver.findElement(By.id(frame))).id;
      await _client.send(_handler.frame.buildSwitchByElementRequest(frameId),
          _handler.frame.parseSwitchByElementResponse);
    } else {
      throw 'Unsupported frame "$frame" with type ${frame.runtimeType}';
    }
  }

  /// Changes focus to the parent frame of the current one.
  Future<void> parentFrame() => _client.send(
      _handler.frame.buildSwitchToParentRequest(),
      _handler.frame.parseSwitchToParentResponse);

  /// Switches the focus of void commands for this driver to the window with the
  /// given name/handle.
  ///
  /// Throws [NoSuchWindowException] if the specified window can't be found.
  Future<void> window(Window window) => window.setAsActive();

  /// Switches to the currently active modal dialog for this particular driver
  /// instance.
  ///
  /// Throws [NoSuchAlertException] if there is not currently an alert.
  Alert get alert => Alert(_client, _handler);

  @override
  String toString() => '$_driver.switchTo';

  @override
  int get hashCode => _driver.hashCode;

  @override
  bool operator ==(other) => other is TargetLocator && other._driver == _driver;
}
