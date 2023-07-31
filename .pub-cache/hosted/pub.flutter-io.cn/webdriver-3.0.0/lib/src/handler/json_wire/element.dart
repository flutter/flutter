import 'dart:math';

import '../../common/request.dart';
import '../../common/webdriver_handler.dart';

import 'utils.dart';

class JsonWireElementHandler extends ElementHandler {
  @override
  WebDriverRequest buildClickRequest(String elementId) =>
      WebDriverRequest.postRequest('${elementPrefix(elementId)}click');

  @override
  void parseClickResponse(WebDriverResponse response) {
    parseJsonWireResponse(response);
  }

  @override
  WebDriverRequest buildSendKeysRequest(String elementId, String keysToSend) =>
      WebDriverRequest.postRequest('${elementPrefix(elementId)}value', {
        'value': [keysToSend]
      });

  @override
  void parseSendKeysResponse(WebDriverResponse response) {
    parseJsonWireResponse(response);
  }

  @override
  WebDriverRequest buildClearRequest(String elementId) =>
      WebDriverRequest.postRequest('${elementPrefix(elementId)}clear');

  @override
  void parseClearResponse(WebDriverResponse response) {
    parseJsonWireResponse(response);
  }

  @override
  WebDriverRequest buildSelectedRequest(String elementId) =>
      WebDriverRequest.getRequest('${elementPrefix(elementId)}selected');

  @override
  bool parseSelectedResponse(WebDriverResponse response) =>
      parseJsonWireResponse(response) as bool;

  @override
  WebDriverRequest buildEnabledRequest(String elementId) =>
      WebDriverRequest.getRequest('${elementPrefix(elementId)}enabled');

  @override
  bool parseEnabledResponse(WebDriverResponse response) =>
      parseJsonWireResponse(response) as bool;

  @override
  WebDriverRequest buildDisplayedRequest(String elementId) =>
      WebDriverRequest.getRequest('${elementPrefix(elementId)}displayed');

  @override
  bool parseDisplayedResponse(WebDriverResponse response) =>
      parseJsonWireResponse(response) as bool;

  @override
  WebDriverRequest buildLocationRequest(String elementId) =>
      WebDriverRequest.getRequest('${elementPrefix(elementId)}location');

  @override
  Point<int> parseLocationResponse(WebDriverResponse response) {
    final point = parseJsonWireResponse(response);
    return Point((point['x'] as num).toInt(), (point['y'] as num).toInt());
  }

  @override
  WebDriverRequest buildSizeRequest(String elementId) =>
      WebDriverRequest.getRequest('${elementPrefix(elementId)}size');

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
  WebDriverRequest buildNameRequest(String elementId) =>
      WebDriverRequest.getRequest('${elementPrefix(elementId)}name');

  @override
  String parseNameResponse(WebDriverResponse response) =>
      parseJsonWireResponse(response) as String;

  @override
  WebDriverRequest buildTextRequest(String elementId) =>
      WebDriverRequest.getRequest('${elementPrefix(elementId)}text');

  @override
  String parseTextResponse(WebDriverResponse response) =>
      parseJsonWireResponse(response) as String;

  @override
  WebDriverRequest buildAttributeRequest(String elementId, String name) =>
      WebDriverRequest.postRequest('execute', {
        'script': '''
    var attr = arguments[0].attributes["$name"];
    if(attr) {
      return attr.value;
    }

    return null;
    ''',
        'args': [
          {jsonWireElementStr: elementId}
        ]
      });

  @override
  String? parseAttributeResponse(WebDriverResponse response) =>
      parseJsonWireResponse(response)?.toString();

  @override
  @deprecated
  WebDriverRequest buildSeleniumAttributeRequest(
          String elementId, String name) =>
      WebDriverRequest.getRequest('${elementPrefix(elementId)}attribute/$name');

  @override
  @deprecated
  String? parseSeleniumAttributeResponse(WebDriverResponse response) =>
      parseJsonWireResponse(response)?.toString();

  @override
  WebDriverRequest buildCssPropertyRequest(String elementId, String name) =>
      WebDriverRequest.postRequest('execute', {
        'script':
            'return window.getComputedStyle(arguments[0]).${_cssPropName(name)};',
        'args': [
          {jsonWireElementStr: elementId}
        ]
      });

  @override
  String? parseCssPropertyResponse(WebDriverResponse response) =>
      parseJsonWireResponse(response)?.toString();

  @override
  WebDriverRequest buildPropertyRequest(String elementId, String name) =>
      WebDriverRequest.postRequest('execute', {
        'script': 'return arguments[0]["$name"];',
        'args': [
          {jsonWireElementStr: elementId}
        ]
      });

  @override
  String? parsePropertyResponse(WebDriverResponse response) =>
      parseJsonWireResponse(response)?.toString();

  /// Convert hyphenated-properties to camelCase.
  String _cssPropName(String name) => name.splitMapJoin(RegExp(r'-(\w)'),
      onMatch: (m) => m.group(1)!.toUpperCase(), onNonMatch: (m) => m);
}
