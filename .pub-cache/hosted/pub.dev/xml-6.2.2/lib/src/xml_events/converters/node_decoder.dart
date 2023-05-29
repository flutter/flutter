import 'dart:convert' show ChunkedConversionSink;

import 'package:meta/meta.dart';

import '../../xml/exceptions/tag_exception.dart';
import '../../xml/navigation/parent.dart';
import '../../xml/nodes/attribute.dart';
import '../../xml/nodes/cdata.dart';
import '../../xml/nodes/comment.dart';
import '../../xml/nodes/declaration.dart';
import '../../xml/nodes/doctype.dart';
import '../../xml/nodes/element.dart';
import '../../xml/nodes/node.dart';
import '../../xml/nodes/processing.dart';
import '../../xml/nodes/text.dart';
import '../../xml/utils/name.dart';
import '../event.dart';
import '../events/cdata.dart';
import '../events/comment.dart';
import '../events/declaration.dart';
import '../events/doctype.dart';
import '../events/end_element.dart';
import '../events/processing.dart';
import '../events/start_element.dart';
import '../events/text.dart';
import '../utils/conversion_sink.dart';
import '../utils/event_attribute.dart';
import '../utils/list_converter.dart';
import '../visitor.dart';

extension XmlNodeDecoderExtension on Stream<List<XmlEvent>> {
  /// Converts a sequence of [XmlEvent] objects to [XmlNode] objects.
  Stream<List<XmlNode>> toXmlNodes() => transform(const XmlNodeDecoder());
}

/// A converter that decodes a sequence of [XmlEvent] objects to a forest of
/// [XmlNode] objects.
class XmlNodeDecoder extends XmlListConverter<XmlEvent, XmlNode> {
  const XmlNodeDecoder();

  @override
  ChunkedConversionSink<List<XmlEvent>> startChunkedConversion(
          Sink<List<XmlNode>> sink) =>
      _XmlNodeDecoderSink(sink);

  // Internal helper to efficiently convert an [Iterable] of [XmlEvent] to a
  // list of [XmlNodes].
  @internal
  List<XmlNode> convertIterable(Iterable<XmlEvent> events) {
    final result = <XmlNode>[];
    final sink =
        _XmlNodeDecoderSink(ConversionSink<List<XmlNode>>(result.addAll));
    events.forEach(sink.visit);
    return result;
  }
}

class _XmlNodeDecoderSink extends ChunkedConversionSink<List<XmlEvent>>
    with XmlEventVisitor {
  _XmlNodeDecoderSink(this.sink);

  final Sink<List<XmlNode>> sink;
  XmlElement? parent;

  @override
  void add(List<XmlEvent> chunk) => chunk.forEach(visit);

  @override
  void visitCDATAEvent(XmlCDATAEvent event) =>
      commit(XmlCDATA(event.text), event);

  @override
  void visitCommentEvent(XmlCommentEvent event) =>
      commit(XmlComment(event.text), event);

  @override
  void visitDeclarationEvent(XmlDeclarationEvent event) =>
      commit(XmlDeclaration(convertAttributes(event.attributes)), event);

  @override
  void visitDoctypeEvent(XmlDoctypeEvent event) => commit(
      XmlDoctype(event.name, event.externalId, event.internalSubset), event);

  @override
  void visitEndElementEvent(XmlEndElementEvent event) {
    if (parent == null) {
      throw XmlTagException.unexpectedClosingTag(event.name);
    }
    final element = parent!;
    XmlTagException.checkClosingTag(element.name.qualified, event.name);
    element.isSelfClosing = element.children.isNotEmpty;
    parent = element.parentElement;

    if (parent == null) {
      commit(element, event.parent);
    }
  }

  @override
  void visitProcessingEvent(XmlProcessingEvent event) =>
      commit(XmlProcessing(event.target, event.text), event);

  @override
  void visitStartElementEvent(XmlStartElementEvent event) {
    final element = XmlElement(
      XmlName.fromString(event.name),
      convertAttributes(event.attributes),
    );
    if (event.isSelfClosing) {
      commit(element, event);
    } else {
      if (parent != null) {
        parent!.children.add(element);
      }
      parent = element;
    }
  }

  @override
  void visitTextEvent(XmlTextEvent event) => commit(XmlText(event.text), event);

  @override
  void close() {
    if (parent != null) {
      throw XmlTagException.missingClosingTag(parent!.name.qualified);
    }
    sink.close();
  }

  void commit(XmlNode node, XmlEvent? event) {
    if (parent == null) {
      // If we have information about a parent event, create hidden
      // [XmlElement] nodes to make sure namespace resolution works
      // as expected.
      for (var outerElement = node, outerEvent = event?.parent;
          outerEvent != null;
          outerEvent = outerEvent.parent) {
        outerElement = XmlElement(
          XmlName.fromString(outerEvent.name),
          convertAttributes(outerEvent.attributes),
          [outerElement],
          outerEvent.isSelfClosing,
        );
      }
      sink.add(<XmlNode>[node]);
    } else {
      parent!.children.add(node);
    }
  }

  Iterable<XmlAttribute> convertAttributes(
          Iterable<XmlEventAttribute> attributes) =>
      attributes.map((attribute) => XmlAttribute(
          XmlName.fromString(attribute.name),
          attribute.value,
          attribute.attributeType));
}
