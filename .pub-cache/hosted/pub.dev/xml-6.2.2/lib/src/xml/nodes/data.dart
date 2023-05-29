import '../mixins/has_parent.dart';
import 'node.dart';

/// Abstract XML data node.
abstract class XmlData extends XmlNode with XmlHasParent<XmlNode> {
  /// Create a data section with `text`.
  XmlData(this.text);

  // The textual value of this node.
  @override
  String text;
}
