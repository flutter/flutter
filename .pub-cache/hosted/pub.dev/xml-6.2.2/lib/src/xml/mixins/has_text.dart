import '../exceptions/type_exception.dart';
import '../navigation/descendants.dart';
import '../nodes/cdata.dart';
import '../nodes/data.dart';
import '../nodes/node.dart';
import '../nodes/text.dart';
import 'has_children.dart';

/// Mixin for nodes with text.
mixin XmlHasText implements XmlChildrenBase {
  /// Return the concatenated text of this node and all its descendants, for
  /// [XmlData] nodes return the textual value of the node.
  String get text => innerText;

  /// Return the concatenated text of this node and all its descendants.
  String get innerText => XmlDescendantsIterable(this as XmlNode)
      .where((node) => node is XmlText || node is XmlCDATA)
      .map((node) => node.text)
      .join();

  /// Replaces the children of this node with text contents.
  set innerText(String value) {
    XmlNodeTypeException.checkHasChildren(this as XmlNode);
    children.clear();
    if (value.isNotEmpty) {
      children.add(XmlText(value));
    }
  }
}
