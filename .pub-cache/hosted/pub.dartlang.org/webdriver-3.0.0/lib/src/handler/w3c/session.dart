import '../../common/capabilities.dart';
import '../../common/request.dart';
import '../../common/session.dart';
import '../../common/spec.dart';
import '../../common/webdriver_handler.dart';
import 'utils.dart';

class W3cSessionHandler extends SessionHandler {
  @override
  WebDriverRequest buildCreateRequest({Map<String, dynamic>? desired}) {
    desired ??= Capabilities.empty;
    return WebDriverRequest.postRequest('session', {
      'capabilities': {'alwaysMatch': desired}
    });
  }

  @override
  SessionInfo parseCreateResponse(WebDriverResponse response) {
    final session = parseW3cResponse(response);
    return SessionInfo(
      session['sessionId'] as String,
      WebDriverSpec.W3c,
      session['capabilities'] as Map<String, dynamic>,
    );
  }

  /// Requesting existing session info is not supported in W3c.
  @override
  WebDriverRequest buildInfoRequest(String id) =>
      WebDriverRequest.nullRequest(id);

  @override
  SessionInfo parseInfoResponse(
    WebDriverResponse response, [
    String? sessionId,
  ]) =>
      SessionInfo(response.body!, WebDriverSpec.W3c, Capabilities.empty);
}
