import 'dart:convert';

import '../../common/exception.dart';
import '../../common/request.dart';
import '../../common/web_element.dart';

// Source: https://www.w3.org/TR/webdriver/#elements
const String w3cElementStr = 'element-6066-11e4-a52e-4f735466cecf';

dynamic parseW3cResponse(WebDriverResponse response) {
  final statusCode = response.statusCode!;
  Map responseBody;
  try {
    responseBody = json.decode(response.body!) as Map;
  } catch (e) {
    final rawBody = response.body == null || response.body!.isEmpty
        ? '<empty response>'
        : response.body;
    throw WebDriverException(
        statusCode, 'Error parsing response body: $rawBody');
  }

  if (statusCode < 200 || statusCode > 299) {
    final value = responseBody['value'] as Map;
    final message = value['message'] as String?;

    // See https://www.w3.org/TR/webdriver/#handling-errors
    switch (value['error']) {
      case 'element click intercepted':
        throw ElementClickInterceptedException(statusCode, message);

      case 'element not interactable':
        throw ElementNotInteractableException(statusCode, message);

      case 'insecure certificate':
        throw InsecureCertificateException(statusCode, message);

      case 'invalid argument':
        throw InvalidArgumentException(statusCode, message);

      case 'invalid cookie domain':
        throw InvalidCookieDomainException(statusCode, message);

      case 'invalid element state':
        throw InvalidElementStateException(statusCode, message);

      case 'invalid selector':
        throw InvalidSelectorException(statusCode, message);

      case 'invalid session id':
        throw InvalidSessionIdException(statusCode, message);

      case 'javascript error':
        throw JavaScriptException(statusCode, message);

      case 'move target out of bounds':
        throw MoveTargetOutOfBoundsException(statusCode, message);

      case 'no such alert':
        throw NoSuchAlertException(statusCode, message);

      case 'no such cookie':
        throw NoSuchCookieException(statusCode, message);

      case 'no such element':
        throw NoSuchElementException(statusCode, message);

      case 'no such frame':
        throw NoSuchFrameException(statusCode, message);

      case 'no such window':
        throw NoSuchWindowException(statusCode, message);

      case 'script timeout':
        throw ScriptTimeoutException(statusCode, message);

      case 'session not created':
        throw SessionNotCreatedException(statusCode, message);

      case 'stale element reference':
        throw StaleElementReferenceException(statusCode, message);

      case 'timeout':
        throw TimeoutException(statusCode, message);

      case 'unable to set cookie':
        throw UnableToSetCookieException(statusCode, message);

      case 'unable to capture screen':
        throw UnableToCaptureScreenException(statusCode, message);

      case 'unexpected alert open':
        throw UnexpectedAlertOpenException(statusCode, message);

      case 'unknown command':
        throw UnknownCommandException(statusCode, message);

      case 'unknown error':
        throw UnknownException(statusCode, message);

      case 'unknown method':
        throw UnknownMethodException(statusCode, message);

      case 'unsupported operation':
        throw UnsupportedOperationException(statusCode, message);

      default:
        throw WebDriverException(statusCode, message);
    }
  }

  return responseBody['value'];
}

/// Prefix to represent element in webdriver uri.
///
/// When [elementId] is null, it means root element.
String elementPrefix(String? elementId) =>
    elementId == null ? '' : 'element/$elementId/';

dynamic deserialize(result, dynamic Function(String) createElement) {
  if (result is Map) {
    if (result.containsKey(w3cElementStr)) {
      return createElement(result[w3cElementStr] as String);
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
    return {w3cElementStr: obj.id};
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
