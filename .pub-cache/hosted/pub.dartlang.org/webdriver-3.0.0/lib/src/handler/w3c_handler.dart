import 'dart:convert';

import '../common/log.dart';
import '../common/request.dart';
import '../common/webdriver_handler.dart';
import 'w3c/alert.dart';
import 'w3c/cookies.dart';
import 'w3c/core.dart';
import 'w3c/element.dart';
import 'w3c/element_finder.dart';
import 'w3c/frame.dart';
import 'w3c/keyboard.dart';
import 'w3c/mouse.dart';
import 'w3c/navigation.dart';
import 'w3c/session.dart';
import 'w3c/timeouts.dart';
import 'w3c/utils.dart';
import 'w3c/window.dart';

class W3cWebDriverHandler extends WebDriverHandler {
  @override
  final SessionHandler session = W3cSessionHandler();

  @override
  final CoreHandler core = W3cCoreHandler();

  @override
  final KeyboardHandler keyboard = W3cKeyboardHandler();

  @override
  final MouseHandler mouse = W3cMouseHandler();

  @override
  final ElementFinder elementFinder = W3cElementFinder();

  @override
  final ElementHandler element = W3cElementHandler();

  @override
  final AlertHandler alert = W3cAlertHandler();

  @override
  final NavigationHandler navigation = W3cNavigationHandler();

  @override
  final WindowHandler window = W3cWindowHandler();

  @override
  final FrameHandler frame = W3cFrameHandler();

  @override
  final CookiesHandler cookies = W3cCookiesHandler();

  @override
  TimeoutsHandler timeouts = W3cTimeoutsHandler();

  @override
  LogsHandler get logs => W3cLogsHandler();

  @override
  WebDriverRequest buildGeneralRequest(HttpMethod method, String uri,
          [params]) =>
      WebDriverRequest(
          method, uri, params == null ? null : json.encode(serialize(params)));

  @override
  dynamic parseGeneralResponse(
          WebDriverResponse response, dynamic Function(String) createElement) =>
      deserialize(parseW3cResponse(response), createElement);

  @override
  String toString() => 'W3C';
}

class W3cLogsHandler extends LogsHandler {
  @override
  WebDriverRequest buildGetLogsRequest(String logType) =>
      WebDriverRequest.postRequest('log', {'type': logType});

  @override
  List<LogEntry> parseGetLogsResponse(WebDriverResponse response) =>
      (parseW3cResponse(response) as List)
          .map<LogEntry>((e) => LogEntry.fromMap(e as Map))
          .toList();
}
