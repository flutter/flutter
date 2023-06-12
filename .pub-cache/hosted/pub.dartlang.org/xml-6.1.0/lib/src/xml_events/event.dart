import '../xml/enums/node_type.dart';
import 'annotations/has_buffer.dart';
import 'annotations/has_location.dart';
import 'annotations/has_parent.dart';
import 'converters/event_encoder.dart';
import 'visitor.dart';

/// Immutable base class for all events.
abstract class XmlEvent with XmlHasParent, XmlHasLocation, XmlHasBuffer {
  /// Default constructor for an event.
  XmlEvent();

  /// Return the node type of this node.
  XmlNodeType get nodeType;

  /// Dispatch to the [visitor] based on event type.
  void accept(XmlEventVisitor visitor);

  @override
  String toString() => XmlEventEncoder().convert([this]);
}
