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

class Timeouts {
  final AsyncRequestClient _client;
  final WebDriverHandler _handler;

  Timeouts(this._client, this._handler);

  /// Sets the script timeout.
  Future<void> setScriptTimeout(Duration duration) => _client.send(
      _handler.timeouts.buildSetScriptTimeoutRequest(duration),
      _handler.timeouts.parseSetScriptTimeoutResponse);

  /// Sets the implicit timeout.
  Future<void> setImplicitTimeout(Duration duration) => _client.send(
      _handler.timeouts.buildSetImplicitTimeoutRequest(duration),
      _handler.timeouts.parseSetImplicitTimeoutResponse);

  /// Sets the page load timeout.
  Future<void> setPageLoadTimeout(Duration duration) => _client.send(
      _handler.timeouts.buildSetPageLoadTimeoutRequest(duration),
      _handler.timeouts.parseSetPageLoadTimeoutResponse);

  @override
  String toString() => '$_handler.timeouts($_client)';

  @override
  int get hashCode => _client.hashCode;

  @override
  bool operator ==(other) =>
      other is Timeouts &&
      _handler == other._handler &&
      _client == other._client;
}
