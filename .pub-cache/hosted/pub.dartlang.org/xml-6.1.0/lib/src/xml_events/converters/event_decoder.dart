import 'dart:convert'
    show Converter, StringConversionSink, StringConversionSinkBase;

import 'package:petitparser/petitparser.dart';

import '../../xml/entities/default_mapping.dart';
import '../../xml/entities/entity_mapping.dart';
import '../../xml/exceptions/parser_exception.dart';
import '../annotations/annotator.dart';
import '../event.dart';
import '../parser.dart';
import '../utils/conversion_sink.dart';

extension XmlEventDecoderExtension on Stream<String> {
  /// Converts a [String] to a sequence of [XmlEvent] objects.
  Stream<List<XmlEvent>> toXmlEvents({
    XmlEntityMapping? entityMapping,
    bool validateNesting = false,
    bool validateDocument = false,
    bool withLocation = false,
    bool withParent = false,
  }) =>
      transform(XmlEventDecoder(
        entityMapping: entityMapping,
        validateNesting: validateNesting,
        validateDocument: validateDocument,
        withLocation: withLocation,
        withParent: withParent,
      ));
}

/// A converter that decodes a [String] to a sequence of [XmlEvent] objects.
class XmlEventDecoder extends Converter<String, List<XmlEvent>> {
  XmlEventDecoder({
    XmlEntityMapping? entityMapping,
    this.validateNesting = false,
    this.validateDocument = false,
    this.withLocation = false,
    this.withParent = false,
  }) : entityMapping = entityMapping ?? defaultEntityMapping;

  final XmlEntityMapping entityMapping;
  final bool validateNesting;
  final bool validateDocument;
  final bool withLocation;
  final bool withParent;

  @override
  List<XmlEvent> convert(String input, [int start = 0, int? end]) {
    end = RangeError.checkValidRange(start, end, input.length);
    final list = <XmlEvent>[];
    final sink = ConversionSink<List<XmlEvent>>(list.addAll);
    startChunkedConversion(sink)
      ..add(input)
      ..close();
    return list;
  }

  @override
  StringConversionSink startChunkedConversion(Sink<List<XmlEvent>> sink) =>
      _XmlEventDecoderSink(
          sink,
          entityMapping,
          XmlAnnotator(
            validateNesting: validateNesting,
            validateDocument: validateDocument,
            withBuffer: false,
            withLocation: withLocation,
            withParent: withParent,
          ));
}

class _XmlEventDecoderSink extends StringConversionSinkBase {
  _XmlEventDecoderSink(
      this.sink, XmlEntityMapping entityMapping, this.annotator)
      : eventParser = eventParserCache[entityMapping];

  final Sink<List<XmlEvent>> sink;
  final Parser<XmlEvent> eventParser;
  final XmlAnnotator annotator;

  String carry = '';
  int offset = 0;

  @override
  void addSlice(String str, int start, int end, bool isLast) {
    end = RangeError.checkValidRange(start, end, str.length);
    if (start == end) {
      return;
    }
    final result = <XmlEvent>[];
    Result<XmlEvent> previous =
        Failure<XmlEvent>(carry + str.substring(start, end), 0, '');
    for (;;) {
      final current = eventParser.parseOn(previous);
      if (current.isSuccess) {
        final event = current.value;
        annotator.annotate(
          event,
          start: offset + previous.position,
          stop: offset + current.position,
        );
        result.add(event);
        previous = current;
      } else {
        carry = previous.buffer.substring(previous.position);
        offset += previous.position;
        break;
      }
    }
    if (result.isNotEmpty) {
      sink.add(result);
    }
    if (isLast) {
      close();
    }
  }

  @override
  void close() {
    if (carry.isNotEmpty) {
      final context = eventParser.parseOn(Failure<XmlEvent>(carry, 0, ''));
      if (context.isFailure) {
        throw XmlParserException(context.message,
            position: offset + context.position);
      }
    }
    annotator.close(position: offset);
    sink.close();
  }
}
