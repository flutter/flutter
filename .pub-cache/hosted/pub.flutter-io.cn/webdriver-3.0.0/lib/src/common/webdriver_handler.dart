import 'dart:math';

import '../../async_core.dart';
import 'request.dart';
import 'session.dart';

/// Handler for spec related request building and response parsing.
///
/// For each type of request to WebDriver, there should be two sync methods,
///
///   1. WebDriverRequest buildSomeActionRequest(parameters)
///   2. ResponseType parseSomeActionResponse(WebDriverResponse)
///
/// So that spec related logic can be packed into such handlers without
/// concerning about how the requests are sent in low level.
///
/// Groups of such methods be packed into sub handlers like KeyboardHandler,
/// MouseHandler.
abstract class WebDriverHandler {
  SessionHandler get session;

  CoreHandler get core;

  KeyboardHandler get keyboard;

  MouseHandler get mouse;

  ElementFinder get elementFinder;

  ElementHandler get element;

  AlertHandler get alert;

  NavigationHandler get navigation;

  WindowHandler get window;

  FrameHandler get frame;

  CookiesHandler get cookies;

  TimeoutsHandler get timeouts;

  LogsHandler get logs;

  /// Builds general request to send to web driver server.
  WebDriverRequest buildGeneralRequest(HttpMethod method, String uri, [params]);

  /// Parses general response got from web driver server.
  dynamic parseGeneralResponse(
      WebDriverResponse response, dynamic Function(String) createElement);
}

abstract class SessionHandler {
  /// Builds request for 'Create Session'.
  WebDriverRequest buildCreateRequest({Map<String, dynamic>? desired});

  /// Parses response for 'Create Session'.
  SessionInfo parseCreateResponse(WebDriverResponse response);

  /// Builds request for 'Get Session Info'.
  WebDriverRequest buildInfoRequest(String id);

  /// Parses response for 'Get Session Info'.
  SessionInfo parseInfoResponse(WebDriverResponse response,
      [String? sessionId]);
}

abstract class CoreHandler {
  /// Builds request for 'Get Current URL'.
  WebDriverRequest buildCurrentUrlRequest();

  /// Parses response for 'Get Current URL'.
  String parseCurrentUrlResponse(WebDriverResponse response);

  /// Builds request for 'Get Title'.
  WebDriverRequest buildTitleRequest();

  /// Parses response for 'Get Title'.
  String parseTitleResponse(WebDriverResponse response);

  /// Builds request for 'Get Page Source'.
  WebDriverRequest buildPageSourceRequest();

  /// Parses response for 'Get Page Source'.
  String parsePageSourceResponse(WebDriverResponse response);

  /// Builds request for 'Take Screenshot'.
  WebDriverRequest buildScreenshotRequest();

  /// Builds request for 'Take Screenshot of Element'.
  WebDriverRequest buildElementScreenshotRequest(String elementId);

  /// Parses response for 'Take Screenshot' to get a base64 encoded image.
  String parseScreenshotResponse(WebDriverResponse response);

  /// Builds request for 'Execute Async Script'.
  WebDriverRequest buildExecuteAsyncRequest(String script, List args);

  /// Parses response for 'Execute Async Script'.
  dynamic parseExecuteAsyncResponse(
      WebDriverResponse response, dynamic Function(String) createElement);

  /// Builds request for 'Execute Script'.
  WebDriverRequest buildExecuteRequest(String script, List args);

  /// Parses response for 'Execute Script'.
  dynamic parseExecuteResponse(
      WebDriverResponse response, dynamic Function(String) createElement);

  /// Builds request for 'Delete Session'.
  WebDriverRequest buildDeleteSessionRequest();

  /// Parses response for 'Delete Session'.
  void parseDeleteSessionResponse(WebDriverResponse response);
}

abstract class ElementHandler {
  /// Builds request for 'Element Click'
  WebDriverRequest buildClickRequest(String elementId);

  /// Parses response for 'Element Click'.
  void parseClickResponse(WebDriverResponse response);

  /// Builds request for 'Element Send Keys'
  WebDriverRequest buildSendKeysRequest(String elementId, String keysToSend);

  /// Parses response for 'Element Send Keys'.
  void parseSendKeysResponse(WebDriverResponse response);

  /// Builds request for 'Element Clear'
  WebDriverRequest buildClearRequest(String elementId);

  /// Parses response for 'Element Clear'.
  void parseClearResponse(WebDriverResponse response);

  /// Builds request for 'Is Element Selected'.
  WebDriverRequest buildSelectedRequest(String elementId);

  /// Parses response for 'Is Element Selected'.
  bool parseSelectedResponse(WebDriverResponse response);

  /// Builds request for 'Is Element Enabled'.
  WebDriverRequest buildEnabledRequest(String elementId);

  /// Parses response for 'Is Element Enabled'.
  bool parseEnabledResponse(WebDriverResponse response);

  /// Builds request for 'Is Element Displayed'.
  WebDriverRequest buildDisplayedRequest(String elementId);

  /// Parses response for 'Is Element Displayed'.
  bool parseDisplayedResponse(WebDriverResponse response);

  /// Builds request for 'Element Location'.
  WebDriverRequest buildLocationRequest(String elementId);

  /// Parses response for 'Element Location'.
  Point<int> parseLocationResponse(WebDriverResponse response);

  /// Builds request for 'Element Size'.
  WebDriverRequest buildSizeRequest(String elementId);

  /// Parses response for 'Element Size'.
  ///
  /// This will be the rectangle moved to (0, 0).
  Rectangle<int> parseSizeResponse(WebDriverResponse response);

  /// Builds request for 'Element Name'.
  WebDriverRequest buildNameRequest(String elementId);

  /// Parses response for 'Element Name'.
  String parseNameResponse(WebDriverResponse response);

  /// Builds request for 'Element Text'.
  WebDriverRequest buildTextRequest(String elementId);

  /// Parses response for 'Element Text'.
  String parseTextResponse(WebDriverResponse response);

  /// Builds request for 'Element Attribute'.
  WebDriverRequest buildAttributeRequest(String elementId, String name);

  /// Parses response for 'Element Attribute'.
  String? parseAttributeResponse(WebDriverResponse response);

  /// Builds request for 'Selenium Element Attribute'.
  ///
  /// This is deprecated, only used to support old pageloader.
  @deprecated
  WebDriverRequest buildSeleniumAttributeRequest(String elementId, String name);

  /// Parses response for 'Element Attribute'.
  ///
  /// This is deprecated, only used to support old pageloader.
  @deprecated
  String? parseSeleniumAttributeResponse(WebDriverResponse response);

  /// Builds request for 'Element Property'.
  WebDriverRequest buildPropertyRequest(String elementId, String name);

  /// Parses response for 'Element Property'.
  String? parsePropertyResponse(WebDriverResponse response);

  /// Builds request for 'Element CSS Value'.
  WebDriverRequest buildCssPropertyRequest(String elementId, String name);

  /// Parses response for 'Element CSS Value'.
  String? parseCssPropertyResponse(WebDriverResponse response);
}

abstract class ElementFinder {
  /// Builds request for finding elements.
  WebDriverRequest buildFindElementsRequest(By by, [String? contextId]);

  /// Parses response got for finding elements to get [List] of element id.
  List<String> parseFindElementsResponse(WebDriverResponse response);

  /// Builds request for finding a single element.
  WebDriverRequest buildFindElementRequest(By by, [String? contextId]);

  /// Parses response got for finding element to get the element id or `null`
  /// if the element does not exist.
  String? parseFindElementResponseCore(WebDriverResponse response);

  /// Parses response got for finding element to get the element id.
  String parseFindElementResponse(WebDriverResponse response) =>
      parseFindElementResponseCore(response)!;

  /// Builds request for finding the current active element.
  WebDriverRequest buildFindActiveElementRequest();

  /// Parses response got for finding current active element to get the element
  /// id.
  String? parseFindActiveElementResponse(WebDriverResponse response);
}

abstract class KeyboardHandler {
  /// Builds request for sending chord.
  WebDriverRequest buildSendChordRequest(Iterable<String> chordToSend);

  /// Parses response got after sending chord.
  void parseSendChordResponse(WebDriverResponse response);

  /// Builds request for sending keys.
  WebDriverRequest buildSendKeysRequest(String keysToSend);

  /// Parses response got after sending keys.
  void parseSendKeysResponse(WebDriverResponse response);
}

abstract class MouseHandler {
  /// Builds request for 'Mouse Click'.
  WebDriverRequest buildClickRequest(
      [MouseButton button = MouseButton.primary]);

  /// Parses response for 'Mouse Click'.
  void parseClickResponse(WebDriverResponse response);

  /// Builds request for 'Mouse Down'.
  WebDriverRequest buildDownRequest([MouseButton button = MouseButton.primary]);

  /// Parses response for 'Mouse Down'.
  void parseDownResponse(WebDriverResponse response);

  /// Builds request for 'Mouse Up'.
  WebDriverRequest buildUpRequest([MouseButton button = MouseButton.primary]);

  /// Parses response for 'Mouse Up'.
  void parseUpResponse(WebDriverResponse response);

  /// Builds request for 'Mouse Double Click'.
  WebDriverRequest buildDoubleClickRequest();

  /// Parses response for 'Mouse Double Click'.
  void parseDoubleClickResponse(WebDriverResponse response);

  /// Builds request for 'Mouse Move To'.
  WebDriverRequest buildMoveToRequest(
      {String? elementId, int? xOffset, int? yOffset, bool absolute = false});

  /// Parses response for 'Mouse Move To'.
  void parseMoveToResponse(WebDriverResponse response);
}

abstract class AlertHandler {
  /// Builds request for 'Get Alert Text'.
  WebDriverRequest buildGetTextRequest();

  /// Parses response for 'Get Alert Text'.
  String parseGetTextResponse(WebDriverResponse response);

  /// Builds request for 'Accept Alert'.
  WebDriverRequest buildAcceptRequest();

  /// Parses response for 'Accept Alert'.
  void parseAcceptResponse(WebDriverResponse response);

  /// Builds request for 'Dismiss Alert'.
  WebDriverRequest buildDismissRequest();

  /// Parses response for 'Dismiss Alert'.
  void parseDismissResponse(WebDriverResponse response);

  /// Builds request for 'Send Alert Text'.
  WebDriverRequest buildSendTextRequest(String keysToSend);

  /// Parses response for 'Send Alert Text'.
  void parseSendTextResponse(WebDriverResponse response);
}

abstract class NavigationHandler {
  /// Builds request for 'Navigate To'.
  WebDriverRequest buildNavigateToRequest(String url);

  /// Parses response for 'Navigate To'.
  void parseNavigateToResponse(WebDriverResponse response);

  /// Builds request for 'Forward'.
  WebDriverRequest buildForwardRequest();

  /// Parses response for 'Forward'.
  void parseForwardResponse(WebDriverResponse response);

  /// Builds request for 'Back'.
  WebDriverRequest buildBackRequest();

  /// Parses response for 'Back'.
  void parseBackResponse(WebDriverResponse response);

  /// Builds request for 'Refresh'.
  WebDriverRequest buildRefreshRequest();

  /// Parses response for 'Refresh'.
  void parseRefreshResponse(WebDriverResponse response);
}

/// Handler for Window related functions.
///
/// Please note that except the top 3 APIs, all others are about the currently
/// active window.
abstract class WindowHandler {
  /// Builds request for 'Get Window Handles'.
  WebDriverRequest buildGetWindowsRequest();

  /// Parses response for 'Get Window Handles' to get window ids.
  List<String> parseGetWindowsResponse(WebDriverResponse response);

  /// Builds request for 'Get Window Handle'.
  WebDriverRequest buildGetActiveWindowRequest();

  /// Parses response for 'Get Window Handle' to get window id.
  String parseGetActiveWindowResponse(WebDriverResponse response);

  /// Builds request for 'Set Window Active'.
  WebDriverRequest buildSetActiveRequest(String windowId);

  /// Parses response for 'Set Window Active'.
  void parseSetActiveResponse(WebDriverResponse response);

  /// Builds request for 'Window Location'.
  WebDriverRequest buildLocationRequest();

  /// Parses response for 'Window Location'.
  Point<int> parseLocationResponse(WebDriverResponse response);

  /// Builds request for 'Window Size'.
  WebDriverRequest buildSizeRequest();

  /// Parses response for 'Window Size'.
  ///
  /// This will be the rectangle moved to (0, 0).
  Rectangle<int> parseSizeResponse(WebDriverResponse response);

  /// Builds request for 'Window Rect'.
  WebDriverRequest buildRectRequest();

  /// Parses response for 'Window Rect'.
  Rectangle<int> parseRectResponse(WebDriverResponse response);

  /// Builds request for 'Set Window Location'.
  WebDriverRequest buildSetLocationRequest(Point<int> location);

  /// Parses response for 'Set Window Location'.
  void parseSetLocationResponse(WebDriverResponse response);

  /// Builds request for 'Set Window Size'.
  WebDriverRequest buildSetSizeRequest(Rectangle<int> size);

  /// Parses response for 'Set Window Size'.
  void parseSetSizeResponse(WebDriverResponse response);

  /// Builds request for 'Set Window Rect'.
  WebDriverRequest buildSetRectRequest(Rectangle<int> rect);

  /// Parses response for 'Set Window Rect'.
  void parseSetRectResponse(WebDriverResponse response);

  /// Builds request for 'Maximize Window'.
  WebDriverRequest buildMaximizeRequest();

  /// Parses response for 'Maximize Window'.
  void parseMaximizeResponse(WebDriverResponse response);

  /// Builds request for 'Minimize Window'.
  ///
  /// Unsupported in JsonWire.
  WebDriverRequest buildMinimizeRequest();

  /// Parses response for 'Minimize Window'.
  ///
  /// Unsupported in JsonWire.
  void parseMinimizeResponse(WebDriverResponse response);

  /// Builds request for 'Close Window'.
  WebDriverRequest buildCloseRequest();

  /// Parses response for 'Close Window'.
  void parseCloseResponse(WebDriverResponse response);

  /// Builds request for 'Inner Size'.
  WebDriverRequest buildInnerSizeRequest();

  /// Parses response for 'Inner Size'.
  Rectangle<int> parseInnerSizeResponse(WebDriverResponse response);
}

abstract class FrameHandler {
  /// Builds request for 'Switch To Frame' with id.
  WebDriverRequest buildSwitchByIdRequest([int? id]);

  /// Parses response for 'Switch To Frame' with id.
  void parseSwitchByIdResponse(WebDriverResponse response);

  /// Builds request for 'Switch To Frame' with element.
  WebDriverRequest buildSwitchByElementRequest(String elementId);

  /// Parses response for 'Switch To Frame' with element.
  void parseSwitchByElementResponse(WebDriverResponse response);

  /// Builds request for 'Switch To Parent Frame'.
  WebDriverRequest buildSwitchToParentRequest();

  /// Parses response for 'Switch To Parent Frame'.
  void parseSwitchToParentResponse(WebDriverResponse response);
}

abstract class CookiesHandler {
  /// Builds request for 'Add Cookie'.
  WebDriverRequest buildAddCookieRequest(Cookie cookie);

  /// Parses response for 'Add Cookie'.
  void parseAddCookieResponse(WebDriverResponse response);

  /// Builds request for 'Delete Cookie'.
  WebDriverRequest buildDeleteCookieRequest(String name);

  /// Parses response for 'Delete Cookie'.
  void parseDeleteCookieResponse(WebDriverResponse response);

  /// Builds request for 'Delete All Cookies'.
  WebDriverRequest buildDeleteAllCookiesRequest();

  /// Parses response for 'Delete All Cookies'.
  void parseDeleteAllCookiesResponse(WebDriverResponse response);

  /// Builds request for 'Get Named Cookie'.
  WebDriverRequest buildGetCookieRequest(String name);

  /// Parses response for 'Get Named Cookie'.
  ///
  /// Also passing in [name] to work around missing this API in JsonWire.
  Cookie parseGetCookieResponse(WebDriverResponse response, String name);

  /// Builds request for 'Get All Cookies'.
  WebDriverRequest buildGetAllCookiesRequest();

  /// Parses response for 'Get All Cookies'.
  List<Cookie> parseGetAllCookiesResponse(WebDriverResponse response);
}

/// Handler for Timeouts.
///
/// We can potentially add support for getting timeouts (available in W3C).
/// But currently it's not requested.
abstract class TimeoutsHandler {
  /// Builds request for 'Set Script Timeout'.
  WebDriverRequest buildSetScriptTimeoutRequest(Duration timeout);

  /// Parses response for 'Set Script Timeout'.
  void parseSetScriptTimeoutResponse(WebDriverResponse response);

  /// Builds request for 'Set Implicit Timeout'.
  WebDriverRequest buildSetImplicitTimeoutRequest(Duration timeout);

  /// Parses response for 'Set Implicit Timeout'.
  void parseSetImplicitTimeoutResponse(WebDriverResponse response);

  /// Builds request for 'Set Page Load Timeout'.
  WebDriverRequest buildSetPageLoadTimeoutRequest(Duration timeout);

  /// Parses response for 'Set Page Load Timeout'.
  void parseSetPageLoadTimeoutResponse(WebDriverResponse response);
}

/// Handler for retrieving logs.
abstract class LogsHandler {
  /// Builds request for 'Get Logs'.
  WebDriverRequest buildGetLogsRequest(String logType);

  /// Parses response for 'Get Logs'.
  List<LogEntry> parseGetLogsResponse(WebDriverResponse response);
}
