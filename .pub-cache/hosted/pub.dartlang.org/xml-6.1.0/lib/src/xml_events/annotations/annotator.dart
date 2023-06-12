import '../../xml/exceptions/parser_exception.dart';
import '../../xml/exceptions/tag_exception.dart';
import '../event.dart';
import '../events/declaration.dart';
import '../events/doctype.dart';
import '../events/end_element.dart';
import '../events/start_element.dart';

/// Annotates [XmlEvent] instances with metadata, such as the underlying buffer,
/// the position in said buffer, and the parent event. This class also has the
/// ability to validate the parent relationship.
class XmlAnnotator {
  XmlAnnotator({
    required this.validateNesting,
    required this.validateDocument,
    required this.withBuffer,
    required this.withLocation,
    required this.withParent,
  });

  final bool validateNesting;
  final bool validateDocument;
  final bool withBuffer;
  final bool withLocation;
  final bool withParent;

  final List<XmlEvent> _roots = [];
  final List<XmlStartElementEvent> _parents = [];

  void annotate(XmlEvent event, {String? buffer, int? start, int? stop}) {
    // Attach the buffer.
    if (withBuffer) {
      event.attachBuffer(buffer);
    }
    // Attach the buffer location.
    if (withLocation) {
      event.attachLocation(start, stop);
    }
    // Attach the parent event, and/or perform additional validation.
    if (withParent || validateNesting || validateDocument) {
      if (withParent && _parents.isNotEmpty) {
        event.attachParent(_parents.last);
      }
      if (validateDocument && _parents.isEmpty) {
        // Validate the document root events.
        if (event is XmlDeclarationEvent) {
          if (_roots.whereType<XmlDeclarationEvent>().isNotEmpty) {
            throw XmlParserException('Expected at most one XML declaration',
                buffer: buffer, position: start);
          } else if (_roots.isNotEmpty) {
            throw XmlParserException('Unexpected XML declaration',
                buffer: buffer, position: start);
          }
          _roots.add(event);
        } else if (event is XmlDoctypeEvent) {
          if (_roots.whereType<XmlDoctypeEvent>().isNotEmpty) {
            throw XmlParserException('Expected at most one doctype declaration',
                buffer: buffer, position: start);
          } else if (_roots.whereType<XmlStartElementEvent>().isNotEmpty) {
            throw XmlParserException('Unexpected doctype declaration',
                buffer: buffer, position: start);
          }
          _roots.add(event);
        } else if (event is XmlStartElementEvent) {
          if (_roots.whereType<XmlStartElementEvent>().isNotEmpty) {
            throw XmlParserException('Unexpected root element',
                buffer: buffer, position: start);
          }
          _roots.add(event);
        }
      }
      if (event is XmlStartElementEvent) {
        if (withParent) {
          for (final attribute in event.attributes) {
            attribute.attachParent(event);
          }
        }
        if (!event.isSelfClosing) {
          _parents.add(event);
        }
      } else if (event is XmlEndElementEvent) {
        // Validate the parent relationship.
        if (validateNesting) {
          if (_parents.isEmpty) {
            throw XmlTagException.unexpectedClosingTag(event.name,
                buffer: buffer, position: start);
          } else if (_parents.last.name != event.name) {
            throw XmlTagException.mismatchClosingTag(
                _parents.last.name, event.name,
                buffer: buffer, position: start);
          }
        }
        if (_parents.isNotEmpty) {
          _parents.removeLast();
        }
      }
    }
  }

  void close({String? buffer, int? position}) {
    // Validate the parent relationship.
    if (validateNesting && _parents.isNotEmpty) {
      throw XmlTagException.missingClosingTag(_parents.last.name,
          buffer: buffer, position: position);
    }
    // Validate the document root events.
    if (validateDocument && _roots.whereType<XmlStartElementEvent>().isEmpty) {
      throw XmlParserException('Expected a single root element',
          buffer: buffer, position: position);
    }
  }
}
