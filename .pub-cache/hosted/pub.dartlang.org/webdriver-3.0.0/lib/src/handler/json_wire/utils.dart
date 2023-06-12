import 'dart:convert';

import '../../common/exception.dart';
import '../../common/request.dart';
import '../../common/web_element.dart';

/// Magic constants -- identifiers indicating a value is an element.
/// Source: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol
const String jsonWireElementStr = 'ELEMENT';

dynamic parseJsonWireResponse(WebDriverResponse response,
    {bool valueOnly = true}) {
  Map<String, dynamic> responseBody;
  try {
    responseBody = json.decode(response.body!) as Map<String, dynamic>;
  } catch (e) {
    final rawBody = response.body == null || response.body!.isEmpty
        ? '<empty response>'
        : response.body;
    throw WebDriverException(
        response.statusCode, 'Error parsing response body: $rawBody');
  }

  if (response.statusCode! < 200 ||
      response.statusCode! > 299 ||
      (responseBody is Map &&
          responseBody['status'] != null &&
          responseBody['status'] != 0)) {
    final status = responseBody['status'] as int?;
    final message = responseBody['value']['message'] as String?;

    switch (status) {
      case 0:
        throw StateError('Not a WebDriverError Status: 0 Message: $message');
      case 6:
        throw NoSuchDriverException(status, message);
      case 7:
        throw NoSuchElementException(status, message);
      case 8:
        throw NoSuchFrameException(status, message);
      case 9:
        throw UnknownCommandException(status, message);
      case 10:
        throw StaleElementReferenceException(status, message);
      case 11:
        throw ElementNotVisibleException(status, message);
      case 12:
        throw InvalidElementStateException(status, message);
      case 15:
        throw ElementIsNotSelectableException(status, message);
      case 17:
        throw JavaScriptException(status, message);
      case 19:
        throw XPathLookupException(status, message);
      case 21:
        throw TimeoutException(status, message);
      case 23:
        throw NoSuchWindowException(status, message);
      case 24:
        throw InvalidCookieDomainException(status, message);
      case 25:
        throw UnableToSetCookieException(status, message);
      case 26:
        throw UnexpectedAlertOpenException(status, message);
      case 27:
        throw NoSuchAlertException(status, message);
      case 28:
        throw ScriptTimeoutException(status, message);
      case 29:
        throw InvalidElementCoordinatesException(status, message);
      case 30:
        throw IMENotAvailableException(status, message);
      case 31:
        throw IMEEngineActivationFailedException(status, message);
      case 32:
        throw InvalidSelectorException(status, message);
      case 33:
        throw SessionNotCreatedException(status, message);
      case 34:
        throw MoveTargetOutOfBoundsException(status, message);
      case 13:
        throw UnknownException(status, message);
      default:
        throw WebDriverException(status, message);
    }
  }

  if (valueOnly && responseBody is Map) {
    return responseBody['value'];
  }

  return responseBody;
}

/// Prefix to represent element in webdriver uri.
///
/// When [elementId] is null, it means root element.
String elementPrefix(String? elementId) =>
    elementId == null ? '' : 'element/$elementId/';

/// Deserializes json object returned by WebDriver server.
///
/// Mainly it handles the element object rebuild.
dynamic deserialize(result, dynamic Function(String) createElement) {
  if (result is Map) {
    if (result.containsKey(jsonWireElementStr)) {
      return createElement(result[jsonWireElementStr] as String);
    } else {
      final newResult = {};
      result.forEach((key, value) {
        newResult[key] = deserialize(value, createElement);
      });
      return newResult;
    }
  } else if (result is List) {
    return result.map((item) => deserialize(item, createElement)).toList();
  } else {
    return result;
  }
}

dynamic serialize(dynamic obj) {
  if (obj is WebElement) {
    return {jsonWireElementStr: obj.id};
  }

  if (obj is Map) {
    final newResult = <String, dynamic>{};
    for (final item in obj.entries) {
      newResult[item.key as String] = serialize(item.value);
    }

    return newResult;
  }

  if (obj is List) {
    return obj.map(serialize).toList();
  }

  return obj;
}
