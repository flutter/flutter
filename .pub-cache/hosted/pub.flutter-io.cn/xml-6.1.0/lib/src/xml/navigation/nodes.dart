import '../nodes/node.dart';

extension XmlNodesExtension on XmlNode {
  /// Return a lazy [Iterable] of the direct descendants of this [XmlNode]
  /// (attributes, children) in document order.
  Iterable<XmlNode> get nodes => [attributes, children].expand((each) => each);
}
