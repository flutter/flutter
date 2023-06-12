import '../../common/by.dart';
import '../../common/request.dart';
import '../../common/webdriver_handler.dart';
import 'utils.dart';

class JsonWireElementFinder extends ElementFinder {
  /// Converts [By] instances into JSON params.
  Map<String, String> _byToJson(By by) =>
      {'using': by.using, 'value': by.value};

  @override
  WebDriverRequest buildFindElementsRequest(By by, [String? contextElementId]) {
    var uri = contextElementId == null
        ? 'elements'
        : 'element/$contextElementId/elements';
    return WebDriverRequest.postRequest(uri, _byToJson(by));
  }

  @override
  List<String> parseFindElementsResponse(WebDriverResponse response) =>
      (parseJsonWireResponse(response) as List)
          .map((e) => e[jsonWireElementStr])
          .toList()
          .cast<String>();

  @override
  WebDriverRequest buildFindElementRequest(By by, [String? contextElementId]) {
    var uri = contextElementId == null
        ? 'element'
        : 'element/$contextElementId/element';
    return WebDriverRequest.postRequest(uri, _byToJson(by));
  }

  @override
  String? parseFindActiveElementResponse(WebDriverResponse response) =>
      (parseJsonWireResponse(response) as Map)[jsonWireElementStr] as String?;

  @override
  WebDriverRequest buildFindActiveElementRequest() =>
      WebDriverRequest.getRequest('element/active');

  @override
  String? parseFindElementResponseCore(WebDriverResponse response) =>
      (parseJsonWireResponse(response) ?? {})[jsonWireElementStr] as String?;
}
