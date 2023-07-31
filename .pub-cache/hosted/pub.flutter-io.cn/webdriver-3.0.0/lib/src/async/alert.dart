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

import '../common/request_client.dart';
import '../common/webdriver_handler.dart';

/// A JavaScript alert(), confirm(), or prompt() dialog
class Alert {
  final AsyncRequestClient _client;
  final WebDriverHandler _handler;

  Alert(this._client, this._handler);

  /// The text of the JavaScript alert(), confirm(), or prompt() dialog.
  Future<String> get text => _client.send(_handler.alert.buildGetTextRequest(),
      _handler.alert.parseGetTextResponse);

  /// Accepts the currently displayed alert (may not be the alert for which this
  /// object was created).
  ///
  ///  Throws [NoSuchAlertException] if there isn't currently an alert.
  Future<void> accept() => _client.send(
      _handler.alert.buildAcceptRequest(), _handler.alert.parseAcceptResponse);

  /// Dismisses the currently displayed alert (may not be the alert for which
  /// this object was created).
  ///
  ///  Throws [NoSuchAlertException] if there isn't currently an alert.
  Future<void> dismiss() => _client.send(_handler.alert.buildDismissRequest(),
      _handler.alert.parseDismissResponse);

  /// Sends keys to the currently displayed alert (may not be the alert for
  /// which this object was created).
  ///
  /// Throws [NoSuchAlertException] if there isn't currently an alert
  Future<void> sendKeys(String keysToSend) => _client.send(
      _handler.alert.buildSendTextRequest(keysToSend),
      _handler.alert.parseSendTextResponse);

  @override
  String toString() => '$_handler.switchTo.alert($_client)';

  @override
  int get hashCode => _client.hashCode;

  @override
  bool operator ==(other) =>
      other is Alert && _handler == other._handler && _client == other._client;
}
