import 'package:petitparser/petitparser.dart' show Parser, Result, Failure;

import '../xml/entities/entity_mapping.dart';
import '../xml/exceptions/parser_exception.dart';
import 'annotations/annotator.dart';
import 'event.dart';
import 'parser.dart';

class XmlEventIterator extends Iterator<XmlEvent> {
  XmlEventIterator(
      String input, XmlEntityMapping entityMapping, this._annotator)
      : _eventParser = eventParserCache[entityMapping],
        _context = Failure<XmlEvent>(input, 0, '');

  final Parser<XmlEvent> _eventParser;
  final XmlAnnotator _annotator;

  Result<XmlEvent>? _context;
  XmlEvent? _current;

  @override
  XmlEvent get current => _current!;

  @override
  bool moveNext() {
    final context = _context;
    if (context != null) {
      final result = _eventParser.parseOn(context);
      if (result.isSuccess) {
        _context = result;
        _current = result.value;
        _annotator.annotate(
          result.value,
          buffer: context.buffer,
          start: context.position,
          stop: result.position,
        );
        return true;
      } else if (context.position < context.buffer.length) {
        // In case of an error, skip one character and throw an exception.
        _context = context.failure(result.message, context.position + 1);
        throw XmlParserException(result.message,
            buffer: result.buffer, position: result.position);
      } else {
        // In case of reaching the end, terminate the iterator.
        _context = null;
        _annotator.close(
          buffer: context.buffer,
          position: context.position,
        );
        return false;
      }
    }
    return false;
  }
}
