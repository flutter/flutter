import '../handler/infer_handler.dart';
import '../handler/json_wire_handler.dart';
import '../handler/w3c_handler.dart';
import 'spec.dart';
import 'webdriver_handler.dart';

WebDriverHandler getHandler(WebDriverSpec spec) {
  switch (spec) {
    case WebDriverSpec.JsonWire:
      return JsonWireWebDriverHandler();
    case WebDriverSpec.W3c:
      return W3cWebDriverHandler();
    case WebDriverSpec.Auto:
      return InferWebDriverHandler();
    default:
      throw UnsupportedError('Unexpected web driver spec: $spec.');
  }
}
