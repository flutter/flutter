import 'dart:math';

import '../../common/request.dart';
import '../../common/webdriver_handler.dart';

import 'utils.dart';

class W3cElementHandler extends ElementHandler {
  @override
  WebDriverRequest buildClickRequest(String elementId) =>
      WebDriverRequest.postRequest('${elementPrefix(elementId)}click');

  @override
  void parseClickResponse(WebDriverResponse response) {
    parseW3cResponse(response);
  }

  @override
  WebDriverRequest buildSendKeysRequest(String elementId, String keysToSend) =>
      WebDriverRequest.postRequest('${elementPrefix(elementId)}value', {
        'text': keysToSend, // What geckodriver really wants.
        'value': keysToSend // Actual W3C spec.
      });

  @override
  void parseSendKeysResponse(WebDriverResponse response) {
    parseW3cResponse(response);
  }

  @override
  WebDriverRequest buildClearRequest(String elementId) =>
      WebDriverRequest.postRequest('${elementPrefix(elementId)}clear');

  @override
  void parseClearResponse(WebDriverResponse response) {
    parseW3cResponse(response);
  }

  @override
  WebDriverRequest buildSelectedRequest(String elementId) =>
      WebDriverRequest.getRequest('${elementPrefix(elementId)}selected');

  @override
  bool parseSelectedResponse(WebDriverResponse response) =>
      parseW3cResponse(response) as bool;

  @override
  WebDriverRequest buildEnabledRequest(String elementId) =>
      WebDriverRequest.getRequest('${elementPrefix(elementId)}enabled');

  @override
  bool parseEnabledResponse(WebDriverResponse response) =>
      parseW3cResponse(response) as bool;

  @override
  WebDriverRequest buildDisplayedRequest(String elementId) =>
      WebDriverRequest.getRequest('${elementPrefix(elementId)}displayed');

  @override
  bool parseDisplayedResponse(WebDriverResponse response) =>
      parseW3cResponse(response) as bool;

  @override
  WebDriverRequest buildLocationRequest(String elementId) =>
      _buildRectRequest(elementId);

  @override
  Point<int> parseLocationResponse(WebDriverResponse response) =>
      _parseRectResponse(response).topLeft;

  @override
  WebDriverRequest buildSizeRequest(String elementId) =>
      _buildRectRequest(elementId);

  @override
  Rectangle<int> parseSizeResponse(WebDriverResponse response) {
    final rect = _parseRectResponse(response);
    return Rectangle(0, 0, rect.width, rect.height);
  }

  WebDriverRequest _buildRectRequest(String elementId) =>
      WebDriverRequest.getRequest('${elementPrefix(elementId)}rect');

  Rectangle<int> _parseRectResponse(WebDriverResponse response) {
    final rect = parseW3cResponse(response);
    return Rectangle(
      (rect['x'] as num).toInt(),
      (rect['y'] as num).toInt(),
      (rect['width'] as num).toInt(),
      (rect['height'] as num).toInt(),
    );
  }

  @override
  WebDriverRequest buildNameRequest(String elementId) =>
      WebDriverRequest.getRequest('${elementPrefix(elementId)}name');

  @override
  String parseNameResponse(WebDriverResponse response) =>
      parseW3cResponse(response) as String;

  @override
  WebDriverRequest buildTextRequest(String elementId) =>
      WebDriverRequest.getRequest('${elementPrefix(elementId)}text');

  @override
  String parseTextResponse(WebDriverResponse response) =>
      parseW3cResponse(response) as String;

  @override
  WebDriverRequest buildAttributeRequest(String elementId, String name) =>
      WebDriverRequest.getRequest('${elementPrefix(elementId)}attribute/$name');

  @override
  String? parseAttributeResponse(WebDriverResponse response) =>
      parseW3cResponse(response)?.toString();

  @override
  @deprecated
  WebDriverRequest buildSeleniumAttributeRequest(
          String elementId, String name) =>
      WebDriverRequest.getRequest('${elementPrefix(elementId)}attribute/$name');

  @override
  @deprecated
  String? parseSeleniumAttributeResponse(WebDriverResponse response) =>
      parseW3cResponse(response)?.toString();

  @override
  WebDriverRequest buildCssPropertyRequest(String elementId, String name) =>
      WebDriverRequest.getRequest('${elementPrefix(elementId)}css/$name');

  @override
  String? parseCssPropertyResponse(WebDriverResponse response) =>
      parseW3cResponse(response)?.toString();

  @override
  WebDriverRequest buildPropertyRequest(String elementId, String name) =>
      WebDriverRequest.getRequest('${elementPrefix(elementId)}property/$name');

  @override
  String? parsePropertyResponse(WebDriverResponse response) =>
      parseW3cResponse(response)?.toString();
}
