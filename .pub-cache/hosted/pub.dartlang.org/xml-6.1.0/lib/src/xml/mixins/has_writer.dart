import '../entities/entity_mapping.dart';
import '../nodes/attribute.dart';
import '../nodes/node.dart';
import '../utils/functions.dart';
import '../visitors/pretty_writer.dart';
import '../visitors/writer.dart';
import 'has_visitor.dart';

/// Mixin to serialize XML to a [StringBuffer].
mixin XmlHasWriter implements XmlHasVisitor {
  /// Return an XML string of this object.
  ///
  /// If [pretty] is set to `true` the output is nicely reformatted, otherwise
  /// the tree is emitted verbatim.
  ///
  /// The [entityMapping] defines how character entities are encoded into the
  /// resulting output.
  ///
  /// The remaining options are used for pretty printing only:
  ///
  /// - The option [indent] defines the indention of nodes, by default nodes
  ///   are indented with 2 spaces.
  /// - The option [newLine] defines the printing of new lines, by default
  ///   the standard new-line `'\n'` character is used.
  /// - The option [level] customizes the initial indention level, by default
  ///   this is `0`.
  /// - If the predicate [preserveWhitespace] returns `true`, the whitespace
  ///   characters within the node and its children are preserved by switching
  ///   to non-pretty mode. By default all whitespace is normalized.
  /// - If the predicate [indentAttribute] returns `true`, the attribute
  ///   will be begin on a new line. Has no effect within elements where
  ///   whitespace are preserved.
  /// - If the [sortAttributes] is provided, attributes are on-the-fly sorted
  ///   using the provided [Comparator].
  /// - If the predicate [spaceBeforeSelfClose] returns `true`, self-closing
  ///   elements will be closed with a space before the slash ('<example />')
  ///
  String toXmlString({
    bool pretty = false,
    XmlEntityMapping? entityMapping,
    int? level,
    String? indent,
    String? newLine,
    Predicate<XmlNode>? preserveWhitespace,
    Predicate<XmlAttribute>? indentAttribute,
    Comparator<XmlAttribute>? sortAttributes,
    Predicate<XmlNode>? spaceBeforeSelfClose,
  }) {
    final buffer = StringBuffer();
    final writer = pretty
        ? XmlPrettyWriter(
            buffer,
            entityMapping: entityMapping,
            level: level,
            indent: indent,
            newLine: newLine,
            preserveWhitespace: preserveWhitespace,
            indentAttribute: indentAttribute,
            sortAttributes: sortAttributes,
            spaceBeforeSelfClose: spaceBeforeSelfClose,
          )
        : XmlWriter(buffer, entityMapping: entityMapping);
    writer.visit(this);
    return buffer.toString();
  }

  @override
  String toString() => toXmlString();
}
