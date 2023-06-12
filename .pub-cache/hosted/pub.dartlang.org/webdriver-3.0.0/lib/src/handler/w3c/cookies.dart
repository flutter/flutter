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

import '../../common/cookie.dart';
import '../../common/request.dart';
import '../../common/webdriver_handler.dart';
import 'utils.dart';

class W3cCookiesHandler extends CookiesHandler {
  @override
  WebDriverRequest buildAddCookieRequest(Cookie cookie) =>
      WebDriverRequest.postRequest('cookie', {'cookie': _serialize(cookie)});

  @override
  void parseAddCookieResponse(WebDriverResponse response) {
    parseW3cResponse(response);
  }

  @override
  WebDriverRequest buildDeleteCookieRequest(String name) =>
      WebDriverRequest.deleteRequest('cookie/$name');

  @override
  void parseDeleteCookieResponse(WebDriverResponse response) {
    parseW3cResponse(response);
  }

  @override
  WebDriverRequest buildDeleteAllCookiesRequest() =>
      WebDriverRequest.deleteRequest('cookie');

  @override
  void parseDeleteAllCookiesResponse(WebDriverResponse response) {
    parseW3cResponse(response);
  }

  @override
  WebDriverRequest buildGetCookieRequest(String name) =>
      WebDriverRequest.getRequest('cookie/$name');

  @override
  Cookie parseGetCookieResponse(WebDriverResponse response, String name) =>
      _deserialize(parseW3cResponse(response));

  @override
  WebDriverRequest buildGetAllCookiesRequest() =>
      WebDriverRequest.getRequest('cookie');

  @override
  List<Cookie> parseGetAllCookiesResponse(WebDriverResponse response) =>
      (parseW3cResponse(response) as List).map<Cookie>(_deserialize).toList();

  /// Serializes the cookie to json object according to the spec.
  ///
  /// The spec is serializing a cookie the same we do in [Cookie.toJson].
  Map<String, dynamic> _serialize(Cookie cookie) => cookie.toJson();

  /// Deserializes the json object to get the cookie according to the spec.
  ///
  /// The spec is deserializing the same we do in [Cookie.fromJson].
  Cookie _deserialize(dynamic content) =>
      Cookie.fromJson(content as Map<String, dynamic>);
}
