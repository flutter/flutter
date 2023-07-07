import '../handler/json_wire/utils.dart' show jsonWireElementStr;
import '../handler/w3c/utils.dart' show w3cElementStr;

/// Common interface for web element, containing only the element id.
abstract class WebElement {
  String get id;

  Map<String, String> toJson() => {jsonWireElementStr: id, w3cElementStr: id};
}
