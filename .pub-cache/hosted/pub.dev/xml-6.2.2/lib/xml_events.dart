/// Dart XML Events is an event based library to asynchronously parse XML
/// documents and to convert them to other representations.
import 'src/xml/entities/default_mapping.dart';
import 'src/xml/entities/entity_mapping.dart';
import 'src/xml/exceptions/tag_exception.dart';
import 'src/xml_events/event.dart';
import 'src/xml_events/iterable.dart';

export 'src/xml/enums/attribute_type.dart' show XmlAttributeType;
export 'src/xml/enums/node_type.dart' show XmlNodeType;
export 'src/xml_events/codec/event_codec.dart' show XmlEventCodec;
export 'src/xml_events/codec/node_codec.dart' show XmlNodeCodec;
export 'src/xml_events/converters/event_decoder.dart'
    show XmlEventDecoderExtension, XmlEventDecoder;
export 'src/xml_events/converters/event_encoder.dart'
    show XmlEventEncoderExtension, XmlEventEncoder;
export 'src/xml_events/converters/node_decoder.dart'
    show XmlNodeDecoderExtension, XmlNodeDecoder;
export 'src/xml_events/converters/node_encoder.dart'
    show XmlNodeEncoderExtension, XmlNodeEncoder;
export 'src/xml_events/event.dart' show XmlEvent;
export 'src/xml_events/events/cdata.dart' show XmlCDATAEvent;
export 'src/xml_events/events/comment.dart' show XmlCommentEvent;
export 'src/xml_events/events/declaration.dart' show XmlDeclarationEvent;
export 'src/xml_events/events/doctype.dart' show XmlDoctypeEvent;
export 'src/xml_events/events/end_element.dart' show XmlEndElementEvent;
export 'src/xml_events/events/processing.dart' show XmlProcessingEvent;
export 'src/xml_events/events/start_element.dart' show XmlStartElementEvent;
export 'src/xml_events/events/text.dart' show XmlTextEvent;
export 'src/xml_events/streams/each_event.dart'
    show XmlEachEventStreamExtension, XmlEachEventStreamListExtension;
export 'src/xml_events/streams/flatten.dart' show XmlFlattenStreamExtension;
export 'src/xml_events/streams/normalizer.dart'
    show XmlNormalizeEventsExtension, XmlNormalizeEvents;
export 'src/xml_events/streams/subtree_selector.dart'
    show XmlSubtreeSelectorExtension, XmlSubtreeSelector;
export 'src/xml_events/streams/with_parent.dart'
    show XmlWithParentEventsExtension, XmlWithParentEvents;
export 'src/xml_events/utils/event_attribute.dart' show XmlEventAttribute;
export 'src/xml_events/visitor.dart' show XmlEventVisitor;

/// Returns an [Iterable] of [XmlEvent] instances over the provided [String].
///
/// Iteration can throw an [XmlException], if the input is malformed and cannot
/// be properly parsed. In case of an error iteration can be resumed and the
/// parsing is retried at the next possible input position.
///
/// If [validateNesting] is `true`, the parser validates the nesting of tags and
/// throws an [XmlTagException] if there is a mismatch or tags are not closed.
/// Again, in case of an error iteration can be resumed with the next event.
///
/// If [validateDocument] is `true`, the parser validates that the root elements
/// of the input follow the requirements of an XML document. This means the
/// document consists of an optional declaration, an optional doctype, and a
/// single root element.
///
/// Furthermore, the following annotations can be enabled if needed:
///
/// - If [withBuffer] is `true`, each event is annotated with the input buffer.
///   Note that this can come at a high memory cost, if the events are retained.
/// - If [withLocation] is `true`, each event is annotated with the starting
///   and stopping position (exclusive) of the event in the input buffer.
/// - If [withParent] is `true`, each event is annotated with its logical
///   parent event; this enables lookup of namespace URIs and other traversals.
///
/// Iteration is lazy, meaning that none of the `input` is parsed and none of
/// the events are created unless requested. This technique is also called
/// pull-parsing.
///
/// The iterator terminates when the complete `input` is consumed.
///
/// For example, to print all trimmed non-empty text elements one would write:
///
///    parseEvents(bookstoreXml)
///        .whereType<XmlTextEvent>()
///        .map((event) => event.text.trim())
///        .where((text) => text.isNotEmpty)
///        .forEach(print);
///
Iterable<XmlEvent> parseEvents(
  String input, {
  XmlEntityMapping? entityMapping,
  bool validateNesting = false,
  bool validateDocument = false,
  bool withBuffer = false,
  bool withLocation = false,
  bool withParent = false,
}) =>
    XmlEventIterable(
      input,
      entityMapping: entityMapping ?? defaultEntityMapping,
      validateNesting: validateNesting,
      validateDocument: validateDocument,
      withBuffer: withBuffer,
      withLocation: withLocation,
      withParent: withParent,
    );
