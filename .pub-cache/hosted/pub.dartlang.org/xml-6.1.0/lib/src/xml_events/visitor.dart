import 'event.dart';
import 'events/cdata.dart';
import 'events/comment.dart';
import 'events/declaration.dart';
import 'events/doctype.dart';
import 'events/end_element.dart';
import 'events/processing.dart';
import 'events/start_element.dart';
import 'events/text.dart';

/// Basic visitor over [XmlEvent] nodes.
mixin XmlEventVisitor {
  /// Helper to dispatch the provided [event] onto this visitor.
  void visit(XmlEvent event) => event.accept(this);

  /// Visit an [XmlCDATAEvent] event.
  void visitCDATAEvent(XmlCDATAEvent event);

  /// Visit an [XmlCommentEvent] event.
  void visitCommentEvent(XmlCommentEvent event);

  /// Visit an [XmlDeclarationEvent] event.
  void visitDeclarationEvent(XmlDeclarationEvent event);

  /// Visit an [XmlDoctypeEvent] event.
  void visitDoctypeEvent(XmlDoctypeEvent event);

  /// Visit an [XmlEndElementEvent] event.
  void visitEndElementEvent(XmlEndElementEvent event);

  /// Visit an [XmlCommentEvent] event.
  void visitProcessingEvent(XmlProcessingEvent event);

  /// Visit an [XmlCommentEvent] event.
  void visitStartElementEvent(XmlStartElementEvent event);

  /// Visit an [XmlCommentEvent] event.
  void visitTextEvent(XmlTextEvent event);
}
