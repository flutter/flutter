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

import 'dart:math';

import '../../common/request.dart';
import '../../common/webdriver_handler.dart';
import 'utils.dart';

class W3cWindowHandler extends WindowHandler {
  @override
  WebDriverRequest buildGetWindowsRequest() =>
      WebDriverRequest.getRequest('window/handles');

  @override
  List<String> parseGetWindowsResponse(WebDriverResponse response) =>
      (parseW3cResponse(response) as List).cast<String>();

  @override
  WebDriverRequest buildGetActiveWindowRequest() =>
      WebDriverRequest.getRequest('window');

  @override
  String parseGetActiveWindowResponse(WebDriverResponse response) =>
      parseW3cResponse(response) as String;

  @override
  WebDriverRequest buildSetActiveRequest(String windowId) =>
      WebDriverRequest.postRequest('window', {'handle': windowId});

  @override
  void parseSetActiveResponse(WebDriverResponse response) {
    parseW3cResponse(response);
  }

  @override
  WebDriverRequest buildLocationRequest() => buildRectRequest();

  @override
  Point<int> parseLocationResponse(WebDriverResponse response) =>
      parseRectResponse(response).topLeft;

  @override
  WebDriverRequest buildSizeRequest() => buildRectRequest();

  @override
  Rectangle<int> parseSizeResponse(WebDriverResponse response) {
    final rect = parseRectResponse(response);
    return Rectangle(0, 0, rect.width, rect.height);
  }

  @override
  WebDriverRequest buildRectRequest() =>
      WebDriverRequest.getRequest('window/rect');

  @override
  Rectangle<int> parseRectResponse(WebDriverResponse response) {
    final rect = parseW3cResponse(response);
    return Rectangle(
      (rect['x'] as num).toInt(),
      (rect['y'] as num).toInt(),
      (rect['width'] as num).toInt(),
      (rect['height'] as num).toInt(),
    );
  }

  @override
  WebDriverRequest buildSetLocationRequest(Point<int> location) =>
      WebDriverRequest.postRequest('window/rect', {
        'x': location.x,
        'y': location.y,
      });

  @override
  void parseSetLocationResponse(WebDriverResponse response) {
    parseW3cResponse(response);
  }

  @override
  WebDriverRequest buildSetSizeRequest(Rectangle<int> size) =>
      WebDriverRequest.postRequest(
          'window/rect', {'width': size.width, 'height': size.height});

  @override
  void parseSetSizeResponse(WebDriverResponse response) {
    parseW3cResponse(response);
  }

  @override
  WebDriverRequest buildSetRectRequest(Rectangle<int> rect) =>
      WebDriverRequest.postRequest('window/rect', {
        'x': rect.left,
        'y': rect.top,
        'width': rect.width,
        'height': rect.height
      });

  @override
  void parseSetRectResponse(WebDriverResponse response) {
    parseW3cResponse(response);
  }

  @override
  WebDriverRequest buildMaximizeRequest() =>
      WebDriverRequest.postRequest('window/maximize');

  @override
  void parseMaximizeResponse(WebDriverResponse response) {
    parseW3cResponse(response);
  }

  @override
  WebDriverRequest buildMinimizeRequest() =>
      WebDriverRequest.postRequest('window/minimize');

  @override
  void parseMinimizeResponse(WebDriverResponse response) {
    parseW3cResponse(response);
  }

  @override
  WebDriverRequest buildCloseRequest() =>
      WebDriverRequest.deleteRequest('window');

  @override
  void parseCloseResponse(WebDriverResponse response) {
    parseW3cResponse(response);
  }

  @override
  WebDriverRequest buildInnerSizeRequest() =>
      WebDriverRequest.postRequest('execute/sync', {
        'script':
            'return { width: window.innerWidth, height: window.innerHeight };',
        'args': []
      });

  @override
  Rectangle<int> parseInnerSizeResponse(WebDriverResponse response) {
    final size = parseW3cResponse(response);
    return Rectangle(0, 0, size['width'] as int, size['height'] as int);
  }
}
