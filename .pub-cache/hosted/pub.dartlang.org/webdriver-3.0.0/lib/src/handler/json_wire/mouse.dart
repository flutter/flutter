import '../../common/exception.dart';
import '../../common/mouse.dart';
import '../../common/request.dart';
import '../../common/webdriver_handler.dart';
import 'utils.dart';

class JsonWireMouseHandler extends MouseHandler {
  @override
  WebDriverRequest buildClickRequest(
          [MouseButton button = MouseButton.primary]) =>
      WebDriverRequest.postRequest('click', {'button': button.value});

  @override
  void parseClickResponse(WebDriverResponse response) {
    parseJsonWireResponse(response);
  }

  @override
  WebDriverRequest buildDownRequest(
          [MouseButton button = MouseButton.primary]) =>
      WebDriverRequest.postRequest('buttondown', {'button': button.value});

  @override
  void parseDownResponse(WebDriverResponse response) {
    parseJsonWireResponse(response);
  }

  @override
  WebDriverRequest buildUpRequest([MouseButton button = MouseButton.primary]) =>
      WebDriverRequest.postRequest('buttonup', {'button': button.value});

  @override
  void parseUpResponse(WebDriverResponse response) {
    parseJsonWireResponse(response);
  }

  @override
  WebDriverRequest buildDoubleClickRequest() =>
      WebDriverRequest.postRequest('doubleclick');

  @override
  void parseDoubleClickResponse(WebDriverResponse response) {
    parseJsonWireResponse(response);
  }

  @override
  WebDriverRequest buildMoveToRequest(
      {String? elementId, int? xOffset, int? yOffset, bool absolute = false}) {
    if (absolute) {
      throw const InvalidArgumentException(
          0, 'Move to an absolute location is only supported in W3C spec.');
    }

    final body = {};
    if (elementId != null) {
      body['element'] = elementId;
    }

    if (xOffset != null && yOffset != null) {
      body['xoffset'] = xOffset.floor();
      body['yoffset'] = yOffset.floor();
    }

    return WebDriverRequest.postRequest('moveto', body);
  }

  @override
  void parseMoveToResponse(WebDriverResponse response) {
    parseJsonWireResponse(response);
  }
}
