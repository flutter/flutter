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

import '../common/cookie.dart';
import '../common/request_client.dart';
import '../common/webdriver_handler.dart';

class Cookies {
  final AsyncRequestClient _client;
  final WebDriverHandler _handler;

  Cookies(this._client, this._handler);

  /// Sets a cookie.
  Future<void> add(Cookie cookie) => _client.send(
      _handler.cookies.buildAddCookieRequest(cookie),
      _handler.cookies.parseAddCookieResponse);

  /// Deletes the cookie with the given [name].
  Future<void> delete(String name) => _client.send(
      _handler.cookies.buildDeleteCookieRequest(name),
      _handler.cookies.parseDeleteCookieResponse);

  /// Deletes all cookies visible to the current page.
  Future<void> deleteAll() => _client.send(
      _handler.cookies.buildDeleteAllCookiesRequest(),
      _handler.cookies.parseDeleteAllCookiesResponse);

  /// Retrieve all cookies visible to the current page.
  Stream<Cookie> get all async* {
    final cookies = await _client.send(
        _handler.cookies.buildGetAllCookiesRequest(),
        _handler.cookies.parseGetAllCookiesResponse);
    for (var cookie in cookies) {
      yield cookie;
    }
  }

  /// Retrieves cookie with the given name.
  Future<Cookie> getCookie(String name) => _client.send(
      _handler.cookies.buildGetCookieRequest(name),
      (response) => _handler.cookies.parseGetCookieResponse(response, name));

  @override
  String toString() => '$_handler.cookies($_client)';

  @override
  int get hashCode => _client.hashCode;

  @override
  bool operator ==(other) =>
      other is Cookies &&
      _handler == other._handler &&
      _client == other._client;
}
