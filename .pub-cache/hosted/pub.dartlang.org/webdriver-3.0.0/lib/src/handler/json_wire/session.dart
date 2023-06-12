import '../../common/capabilities.dart';
import '../../common/request.dart';
import '../../common/session.dart';
import '../../common/spec.dart';
import '../../common/webdriver_handler.dart';
import 'utils.dart';

class JsonWireSessionHandler extends SessionHandler {
  @override
  WebDriverRequest buildCreateRequest({Map<String, dynamic>? desired}) {
    desired ??= Capabilities.empty;
    return WebDriverRequest.postRequest(
        'session', {'desiredCapabilities': desired});
  }

  @override
  SessionInfo parseCreateResponse(WebDriverResponse response) =>
      parseInfoResponse(response);

  @override
  WebDriverRequest buildInfoRequest(String id) =>
      WebDriverRequest.getRequest('session/$id');

  @override
  SessionInfo parseInfoResponse(WebDriverResponse response,
      [String? sessionId]) {
    final session = parseJsonWireResponse(response, valueOnly: false);
    return SessionInfo(
      session['sessionId'] as String,
      WebDriverSpec.JsonWire,
      session['value'] as Map<String, dynamic>?,
    );
  }
}
