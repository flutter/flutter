import '../../common/by.dart';
import '../../common/request.dart';
import '../../common/webdriver_handler.dart';
import 'utils.dart';

class W3cElementFinder extends ElementFinder {
  /// Here we massage [By] instances into viable W3C /element requests.
  ///
  /// In principle, W3C spec implementations should be nearly the same as
  /// the existing JSON wire spec. In practice compliance is uneven.
  Map<String, String> _byToJson(By by) {
    String using;
    String value;

    switch (by.using) {
      case 'id': // This doesn't exist in the W3C spec.
        using = 'css selector';
        value = '#${by.value}';
        break;
      case 'name': // This doesn't exist in the W3C spec.
        using = 'css selector';
        value = '[name=${by.value}]';
        break;
      case 'tag name': // This is in the W3C spec, but not in geckodriver.
        using = 'css selector';
        value = by.value;
        break;
      case 'class name': // This doesn't exist in the W3C spec.
        using = 'css selector';
        value = '.${by.value}';
        break;
      // xpath, css selector, link text, partial link text, seem fine.
      default:
        using = by.using;
        value = by.value;
    }

    return {'using': using, 'value': value};
  }

  @override
  WebDriverRequest buildFindElementsRequest(By by, [String? contextElementId]) {
    var uri = '${elementPrefix(contextElementId)}elements';
    return WebDriverRequest.postRequest(uri, _byToJson(by));
  }

  @override
  List<String> parseFindElementsResponse(WebDriverResponse response) =>
      (parseW3cResponse(response) as List)
          .map<String>((e) => e[w3cElementStr] as String)
          .toList();

  @override
  WebDriverRequest buildFindElementRequest(By by, [String? contextElementId]) {
    var uri = '${elementPrefix(contextElementId)}element';
    return WebDriverRequest.postRequest(uri, _byToJson(by));
  }

  @override
  String? parseFindActiveElementResponse(WebDriverResponse response) =>
      parseW3cResponse(response)[w3cElementStr] as String;

  @override
  WebDriverRequest buildFindActiveElementRequest() =>
      WebDriverRequest.getRequest('element/active');

  @override
  String? parseFindElementResponseCore(WebDriverResponse response) =>
      (parseW3cResponse(response) ?? {})[w3cElementStr] as String?;
}
