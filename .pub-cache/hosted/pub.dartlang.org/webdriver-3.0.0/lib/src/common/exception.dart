/// Base exception for anything unexpected happened in Web Driver requests.
class WebDriverException implements Exception {
  /// Either the status value returned in the JSON response (preferred) or the
  /// HTTP status code.
  final int? statusCode;

  /// A message describing the error.
  final String? message;

  const WebDriverException(this.statusCode, this.message);

  @override
  String toString() =>
      '$runtimeType ($statusCode): ' +
      (message?.isEmpty != false ? '<no message>' : message!);

  @override
  bool operator ==(other) =>
      other is WebDriverException &&
      other.runtimeType == runtimeType &&
      other.statusCode == statusCode &&
      other.message == message;

  @override
  int get hashCode => statusCode! + message.hashCode;
}

class InvalidArgumentException extends WebDriverException {
  const InvalidArgumentException(int? statusCode, String? message)
      : super(statusCode, message);
}

class InvalidRequestException extends WebDriverException {
  const InvalidRequestException(int? statusCode, String? message)
      : super(statusCode, message);
}

class InvalidResponseException extends WebDriverException {
  const InvalidResponseException(int? statusCode, String? message)
      : super(statusCode, message);
}

class UnknownException extends WebDriverException {
  const UnknownException(int? statusCode, String? message)
      : super(statusCode, message);
}

class NoSuchDriverException extends WebDriverException {
  const NoSuchDriverException(int? statusCode, String? message)
      : super(statusCode, message);
}

class NoSuchElementException extends WebDriverException {
  const NoSuchElementException(int? statusCode, String? message)
      : super(statusCode, message);
}

class NoSuchFrameException extends WebDriverException {
  const NoSuchFrameException(int? statusCode, String? message)
      : super(statusCode, message);
}

class UnknownCommandException extends WebDriverException {
  const UnknownCommandException(int? statusCode, String? message)
      : super(statusCode, message);
}

class StaleElementReferenceException extends WebDriverException {
  const StaleElementReferenceException(int? statusCode, String? message)
      : super(statusCode, message);
}

class ElementNotVisibleException extends WebDriverException {
  const ElementNotVisibleException(int? statusCode, String? message)
      : super(statusCode, message);
}

class InvalidElementStateException extends WebDriverException {
  const InvalidElementStateException(int? statusCode, String? message)
      : super(statusCode, message);
}

class ElementIsNotSelectableException extends WebDriverException {
  const ElementIsNotSelectableException(int? statusCode, String? message)
      : super(statusCode, message);
}

class JavaScriptException extends WebDriverException {
  const JavaScriptException(int? statusCode, String? message)
      : super(statusCode, message);
}

class XPathLookupException extends WebDriverException {
  const XPathLookupException(int? statusCode, String? message)
      : super(statusCode, message);
}

class TimeoutException extends WebDriverException {
  const TimeoutException(int? statusCode, String? message)
      : super(statusCode, message);
}

class NoSuchWindowException extends WebDriverException {
  const NoSuchWindowException(int? statusCode, String? message)
      : super(statusCode, message);
}

class InvalidCookieDomainException extends WebDriverException {
  const InvalidCookieDomainException(int? statusCode, String? message)
      : super(statusCode, message);
}

class UnableToSetCookieException extends WebDriverException {
  const UnableToSetCookieException(int? statusCode, String? message)
      : super(statusCode, message);
}

class UnexpectedAlertOpenException extends WebDriverException {
  const UnexpectedAlertOpenException(int? statusCode, String? message)
      : super(statusCode, message);
}

class NoSuchAlertException extends WebDriverException {
  const NoSuchAlertException(int? statusCode, String? message)
      : super(statusCode, message);
}

class ScriptTimeoutException extends WebDriverException {
  const ScriptTimeoutException(int? statusCode, String? message)
      : super(statusCode, message);
}

class InvalidElementCoordinatesException extends WebDriverException {
  const InvalidElementCoordinatesException(int? statusCode, String? message)
      : super(statusCode, message);
}

class IMENotAvailableException extends WebDriverException {
  const IMENotAvailableException(int? statusCode, String? message)
      : super(statusCode, message);
}

class IMEEngineActivationFailedException extends WebDriverException {
  const IMEEngineActivationFailedException(int? statusCode, String? message)
      : super(statusCode, message);
}

class InvalidSelectorException extends WebDriverException {
  const InvalidSelectorException(int? statusCode, String? message)
      : super(statusCode, message);
}

class SessionNotCreatedException extends WebDriverException {
  const SessionNotCreatedException(int? statusCode, String? message)
      : super(statusCode, message);
}

class MoveTargetOutOfBoundsException extends WebDriverException {
  const MoveTargetOutOfBoundsException(int? statusCode, String? message)
      : super(statusCode, message);
}

/// The Element Click command could not be completed because the element
/// receiving the events is obscuring the element that was requested clicked.
class ElementClickInterceptedException extends WebDriverException {
  const ElementClickInterceptedException(int statusCode, String? message)
      : super(statusCode, message);
}

/// A command could not be completed because the element is not pointer- or
/// keyboard interactable.
class ElementNotInteractableException extends WebDriverException {
  const ElementNotInteractableException(int statusCode, String? message)
      : super(statusCode, message);
}

/// Navigation caused the user agent to hit a certificate warning, which is
/// usually the result of an expired or invalid TLS certificate.
class InsecureCertificateException extends WebDriverException {
  const InsecureCertificateException(int statusCode, String? message)
      : super(statusCode, message);
}

/// Occurs if the given session id is not in the list of active sessions,
/// meaning the session either does not exist or that it’s not active.
class InvalidSessionIdException extends WebDriverException {
  const InvalidSessionIdException(int statusCode, String? message)
      : super(statusCode, message);
}

/// No cookie matching the given path name was found amongst the associated
/// cookies of the current browsing context’s active document.
class NoSuchCookieException extends WebDriverException {
  const NoSuchCookieException(int statusCode, String? message)
      : super(statusCode, message);
}

/// A screen capture was made impossible.
class UnableToCaptureScreenException extends WebDriverException {
  const UnableToCaptureScreenException(int statusCode, String? message)
      : super(statusCode, message);
}

/// The requested command matched a known URL but did not match an method for
/// that URL.
class UnknownMethodException extends WebDriverException {
  const UnknownMethodException(int statusCode, String? message)
      : super(statusCode, message);
}

/// Indicates that a command that should have executed properly cannot be
/// supported for some reason.
class UnsupportedOperationException extends WebDriverException {
  const UnsupportedOperationException(int statusCode, String? message)
      : super(statusCode, message);
}

/// Temporary method to emulate the original json wire exception parsing logic.
WebDriverException getExceptionFromJsonWireResponse(
    {int? httpStatusCode, String? httpReasonPhrase, dynamic jsonResp}) {
  if (jsonResp is Map) {
    var status = jsonResp['status'] as int?;
    var message = jsonResp['value']['message'] as String?;

    switch (status) {
      case 0:
        throw StateError('Not a WebDriverError Status: 0 Message: $message');
      case 6: // NoSuchDriver
        return NoSuchDriverException(status, message);
      case 7: // NoSuchElement
        return NoSuchElementException(status, message);
      case 8: // NoSuchFrame
        return NoSuchFrameException(status, message);
      case 9: // UnknownCommand
        return UnknownCommandException(status, message);
      case 10: // StaleElementReferenceException
        return StaleElementReferenceException(status, message);
      case 11: // ElementNotVisible
        return ElementNotVisibleException(status, message);
      case 12: // InvalidElementState
        return InvalidElementStateException(status, message);
      case 15: // ElementIsNotSelectable
        return ElementIsNotSelectableException(status, message);
      case 17: // JavaScriptError
        return JavaScriptException(status, message);
      case 19: // XPathLookupError
        return XPathLookupException(status, message);
      case 21: // Timeout
        return TimeoutException(status, message);
      case 23: // NoSuchWindow
        return NoSuchWindowException(status, message);
      case 24: // InvalidCookieDomain
        return InvalidCookieDomainException(status, message);
      case 25: // UnableToSetCookie
        return UnableToSetCookieException(status, message);
      case 26: // UnexpectedAlertOpen
        return UnexpectedAlertOpenException(status, message);
      case 27: // NoSuchAlert
        return NoSuchAlertException(status, message);
      case 28: // ScriptTimeout
        return ScriptTimeoutException(status, message);
      case 29: // InvalidElementCoordinates
        return InvalidElementCoordinatesException(status, message);
      case 30: // IMENotAvailable
        return IMENotAvailableException(status, message);
      case 31: // IMEEngineActivationFailed
        return IMEEngineActivationFailedException(status, message);
      case 32: // InvalidSelector
        return InvalidSelectorException(status, message);
      case 33: // SessionNotCreatedException
        return SessionNotCreatedException(status, message);
      case 34: // MoveTargetOutOfBounds
        return MoveTargetOutOfBoundsException(status, message);
      case 13: // UnknownError
      default: // new error?
        return UnknownException(status, message);
    }
  }
  if (jsonResp != null) {
    return InvalidRequestException(httpStatusCode, jsonResp as String);
  }
  return InvalidRequestException(httpStatusCode, httpReasonPhrase);
}

/// Temporary method to emulate the original w3c exception parsing logic.
WebDriverException getExceptionFromW3cResponse({
  int? httpStatusCode,
  String? httpReasonPhrase,
  dynamic jsonResp,
}) {
  if (jsonResp is Map && jsonResp.keys.contains('value')) {
    final value = jsonResp['value'];

    switch (value['error']) {
      case 'invalid argument':
        return InvalidArgumentException(
          httpStatusCode,
          value['message'] as String?,
        );
      case 'no such element':
        return NoSuchElementException(
          httpStatusCode,
          value['message'] as String?,
        );
      default:
        return WebDriverException(httpStatusCode, value['message'] as String?);
    }
  }

  return InvalidResponseException(httpStatusCode, jsonResp.toString());
}
