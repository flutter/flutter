import 'dart:convert' show ChunkedConversionSink;

import '../../xml/exceptions/tag_exception.dart';
import '../../xml/utils/functions.dart';
import '../event.dart';
import '../events/end_element.dart';
import '../events/start_element.dart';
import '../utils/list_converter.dart';

extension XmlSubtreeSelectorExtension on Stream<List<XmlEvent>> {
  /// From a sequence of [XmlEvent] objects filter the event sequences that
  /// form sub-trees for which [predicate] returns `true`.
  Stream<List<XmlEvent>> selectSubtreeEvents(
          Predicate<XmlStartElementEvent> predicate) =>
      transform(XmlSubtreeSelector(predicate));
}

/// A converter that selects [XmlEvent] objects that are part of a sub-tree
/// started by an [XmlStartElementEvent] satisfying the provided predicate.
class XmlSubtreeSelector extends XmlListConverter<XmlEvent, XmlEvent> {
  const XmlSubtreeSelector(this.predicate);

  final Predicate<XmlStartElementEvent> predicate;

  @override
  ChunkedConversionSink<List<XmlEvent>> startChunkedConversion(
          Sink<List<XmlEvent>> sink) =>
      _XmlSubtreeSelectorSink(sink, predicate);
}

class _XmlSubtreeSelectorSink extends ChunkedConversionSink<List<XmlEvent>> {
  _XmlSubtreeSelectorSink(this.sink, this.predicate);

  final Sink<List<XmlEvent>> sink;
  final Predicate<XmlStartElementEvent> predicate;
  final List<XmlStartElementEvent> stack = [];

  @override
  void add(List<XmlEvent> chunk) {
    final result = <XmlEvent>[];
    for (final event in chunk) {
      if (stack.isEmpty) {
        if (event is XmlStartElementEvent && predicate(event)) {
          if (!event.isSelfClosing) {
            stack.add(event);
          }
          result.add(event);
        }
      } else {
        if (event is XmlStartElementEvent && !event.isSelfClosing) {
          stack.add(event);
        } else if (event is XmlEndElementEvent) {
          XmlTagException.checkClosingTag(stack.last.name, event.name);
          stack.removeLast();
        }
        result.add(event);
      }
    }
    if (result.isNotEmpty) {
      sink.add(result);
    }
  }

  @override
  void close() {
    sink.close();
  }
}
