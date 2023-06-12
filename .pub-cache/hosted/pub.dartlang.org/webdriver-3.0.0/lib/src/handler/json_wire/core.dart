import '../../common/request.dart';
import '../../common/webdriver_handler.dart';
import 'utils.dart';

class JsonWireCoreHandler extends CoreHandler {
  @override
  WebDriverRequest buildCurrentUrlRequest() =>
      WebDriverRequest.getRequest('url');

  @override
  String parseCurrentUrlResponse(WebDriverResponse response) =>
      parseJsonWireResponse(response) as String;

  @override
  WebDriverRequest buildTitleRequest() => WebDriverRequest.getRequest('title');

  @override
  String parseTitleResponse(WebDriverResponse response) =>
      parseJsonWireResponse(response) as String;

  @override
  WebDriverRequest buildPageSourceRequest() =>
      WebDriverRequest.getRequest('source');

  @override
  String parsePageSourceResponse(WebDriverResponse response) =>
      parseJsonWireResponse(response) as String;

  @override
  WebDriverRequest buildScreenshotRequest() =>
      WebDriverRequest.getRequest('screenshot');

  @override
  WebDriverRequest buildElementScreenshotRequest(String elementId) =>
      WebDriverRequest.getRequest('${elementPrefix(elementId)}screenshot');

  @override
  String parseScreenshotResponse(WebDriverResponse response) =>
      parseJsonWireResponse(response) as String;

  @override
  WebDriverRequest buildExecuteAsyncRequest(String script, List args) =>
      WebDriverRequest.postRequest(
          'execute_async', {'script': script, 'args': serialize(args)});

  @override
  dynamic parseExecuteAsyncResponse(
          WebDriverResponse response, dynamic Function(String) createElement) =>
      deserialize(parseJsonWireResponse(response), createElement);

  @override
  WebDriverRequest buildExecuteRequest(String script, List args) =>
      WebDriverRequest.postRequest(
          'execute', {'script': script, 'args': serialize(args)});

  @override
  dynamic parseExecuteResponse(
          WebDriverResponse response, dynamic Function(String) createElement) =>
      deserialize(parseJsonWireResponse(response), createElement);

  @override
  WebDriverRequest buildDeleteSessionRequest() =>
      WebDriverRequest.deleteRequest('');

  @override
  void parseDeleteSessionResponse(WebDriverResponse response) {
    parseJsonWireResponse(response);
  }
}
