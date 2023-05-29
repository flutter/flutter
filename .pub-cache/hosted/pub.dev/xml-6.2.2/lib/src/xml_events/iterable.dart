import '../xml/entities/entity_mapping.dart';
import 'annotations/annotator.dart';
import 'event.dart';
import 'iterator.dart';

class XmlEventIterable extends Iterable<XmlEvent> {
  XmlEventIterable(
    this.input, {
    required this.entityMapping,
    required this.validateNesting,
    required this.validateDocument,
    required this.withBuffer,
    required this.withLocation,
    required this.withParent,
  });

  final String input;
  final XmlEntityMapping entityMapping;
  final bool validateNesting;
  final bool validateDocument;
  final bool withBuffer;
  final bool withLocation;
  final bool withParent;

  @override
  Iterator<XmlEvent> get iterator => XmlEventIterator(
        input,
        entityMapping,
        XmlAnnotator(
          validateNesting: validateNesting,
          validateDocument: validateDocument,
          withBuffer: withBuffer,
          withLocation: withLocation,
          withParent: withParent,
        ),
      );
}
