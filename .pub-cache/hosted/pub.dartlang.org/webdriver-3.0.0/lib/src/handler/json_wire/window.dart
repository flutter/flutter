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

class JsonWireWindowHandler extends WindowHandler {
  @override
  WebDriverRequest buildGetWindowsRequest() =>
      WebDriverRequest.getRequest('window_handles');

  @override
  List<String> parseGetWindowsResponse(WebDriverResponse response) =>
      (parseJsonWireResponse(response) as List).cast<String>();

  @override
  WebDriverRequest buildGetActiveWindowRequest() =>
      WebDriverRequest.getRequest('window_handle');

  @override
  String parseGetActiveWindowResponse(WebDriverResponse response) =>
      parseJsonWireResponse(response) as String;

  @override
  WebDriverRequest buildSetActiveRequest(String windowId) =>
      WebDriverRequest.postRequest('window', {'name': windowId});

  @override
  void parseSetActiveResponse(WebDriverResponse response) {
    parseJsonWireResponse(response);
  }

  @override
  WebDriverRequest buildLocationRequest() =>
      WebDriverRequest.getRequest('window/current/position');

  @override
  Point<int> parseLocationResponse(WebDriverResponse response) {
    final point = parseJsonWireResponse(response);
    return Point(
      (point['x'] as num).toInt(),
      (point['y'] as num).toInt(),
    );
  }

  @override
  WebDriverRequest buildSizeRequest() =>
      WebDriverRequest.getRequest('window/current/size');

  @override
  Rectangle<int> parseSizeResponse(WebDriverResponse response) {
    final size = parseJsonWireResponse(response);
    return Rectangle<int>(
      0,
      0,
      (size['width'] as num).toInt(),
      (size['height'] as num).toInt(),
    );
  }

  @override
  WebDriverRequest buildRectRequest() {
    throw UnsupportedError('Get Window Rect is not supported in JsonWire.');
  }

  @override
  Rectangle<int> parseRectResponse(WebDriverResponse response) {
    throw UnsupportedError('Get Window Rect is not supported in JsonWire.');
  }

  @override
  WebDriverRequest buildSetLocationRequest(Point<int> location) =>
      WebDriverRequest.postRequest('window/current/position',
          {'x': location.x.toInt(), 'y': location.y.toInt()});

  @override
  void parseSetLocationResponse(WebDriverResponse response) {
    parseJsonWireResponse(response);
  }

  @override
  WebDriverRequest buildSetSizeRequest(Rectangle<int> size) =>
      WebDriverRequest.postRequest('window/current/size',
          {'width': size.width.toInt(), 'height': size.height.toInt()});

  @override
  void parseSetSizeResponse(WebDriverResponse response) {
    parseJsonWireResponse(response);
  }

  @override
  WebDriverRequest buildSetRectRequest(Rectangle<int> rect) {
    throw UnsupportedError('Set Window Rect is not supported in JsonWire.');
  }

  @override
  void parseSetRectResponse(WebDriverResponse response) {
    throw UnsupportedError('Set Window Rect is not supported in JsonWire.');
  }

  @override
  WebDriverRequest buildMaximizeRequest() =>
      WebDriverRequest.postRequest('window/current/maximize');

  @override
  void parseMaximizeResponse(WebDriverResponse response) {
    parseJsonWireResponse(response);
  }

  @override
  WebDriverRequest buildMinimizeRequest() => throw 'Unsupported in JsonWire';

  @override
  void parseMinimizeResponse(WebDriverResponse response) =>
      throw 'Unsupported in JsonWire';

  @override
  WebDriverRequest buildCloseRequest() =>
      WebDriverRequest.deleteRequest('window');

  @override
  void parseCloseResponse(WebDriverResponse response) {
    parseJsonWireResponse(response);
  }

  @override
  WebDriverRequest buildInnerSizeRequest() =>
      WebDriverRequest.postRequest('execute', {
        'script':
            'return { width: window.innerWidth, height: window.innerHeight };',
        'args': []
      });

  @override
  Rectangle<int> parseInnerSizeResponse(WebDriverResponse response) {
    final size = parseJsonWireResponse(response);
    return Rectangle(0, 0, size['width'] as int, size['height'] as int);
  }
}
