import '../../common/mouse.dart';
import '../../common/request.dart';
import '../../common/webdriver_handler.dart';
import 'utils.dart';

class W3cMouseHandler extends MouseHandler {
  @override
  WebDriverRequest buildClickRequest(
          [MouseButton button = MouseButton.primary]) =>
      WebDriverRequest.postRequest('actions', {
        'actions': [
          {
            'type': 'pointer',
            'id': 'mouses',
            'actions': [
              {'type': 'pointerDown', 'button': button.value},
              {'type': 'pointerUp', 'button': button.value}
            ]
          }
        ]
      });

  @override
  void parseClickResponse(WebDriverResponse response) {
    parseW3cResponse(response);
  }

  @override
  WebDriverRequest buildDownRequest(
          [MouseButton button = MouseButton.primary]) =>
      WebDriverRequest.postRequest('actions', {
        'actions': [
          {
            'type': 'pointer',
            'id': 'mouses',
            'actions': [
              {'type': 'pointerDown', 'button': button.value}
            ]
          }
        ]
      });

  @override
  void parseDownResponse(WebDriverResponse response) {
    parseW3cResponse(response);
  }

  @override
  WebDriverRequest buildUpRequest([MouseButton button = MouseButton.primary]) =>
      WebDriverRequest.postRequest('actions', {
        'actions': [
          {
            'type': 'pointer',
            'id': 'mouses',
            'actions': [
              {'type': 'pointerUp', 'button': button.value}
            ]
          }
        ]
      });

  @override
  void parseUpResponse(WebDriverResponse response) {
    parseW3cResponse(response);
  }

  @override
  WebDriverRequest buildDoubleClickRequest() =>
      WebDriverRequest.postRequest('actions', {
        'actions': [
          {
            'type': 'pointer',
            'id': 'mouses',
            'actions': [
              {'type': 'pointerDown', 'button': MouseButton.primary.value},
              {'type': 'pointerUp', 'button': MouseButton.primary.value},
              {'type': 'pointerDown', 'button': MouseButton.primary.value},
              {'type': 'pointerUp', 'button': MouseButton.primary.value}
            ]
          }
        ]
      });

  @override
  void parseDoubleClickResponse(WebDriverResponse response) {
    parseW3cResponse(response);
  }

  @override
  WebDriverRequest buildMoveToRequest(
          {String? elementId,
          int? xOffset,
          int? yOffset,
          bool absolute = false}) =>
      WebDriverRequest.postRequest('actions', {
        'actions': [
          {
            'type': 'pointer',
            'id': 'mouses',
            'actions': [
              {
                'type': 'pointerMove',
                'origin': absolute
                    ? 'viewport'
                    : (elementId != null
                        ? {w3cElementStr: elementId}
                        : 'pointer'),
                'x': xOffset ?? 0,
                'y': yOffset ?? 0
              }
            ]
          }
        ]
      });

  @override
  void parseMoveToResponse(WebDriverResponse response) {
    parseW3cResponse(response);
  }
}
