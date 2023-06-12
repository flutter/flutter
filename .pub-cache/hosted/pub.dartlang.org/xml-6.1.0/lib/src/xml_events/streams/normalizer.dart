import 'dart:convert' show ChunkedConversionSink;

import '../event.dart';
import '../events/text.dart';
import '../utils/list_converter.dart';

extension XmlNormalizeEventsExtension on Stream<List<XmlEvent>> {
  /// Normalizes a sequence of [XmlEvent] objects by removing empty and
  /// combining adjacent text events.
  Stream<List<XmlEvent>> normalizeEvents() =>
      transform(const XmlNormalizeEvents());
}

/// A converter that normalizes sequences of [XmlEvent] objects, namely combines
/// adjacent and removes empty text events.
class XmlNormalizeEvents extends XmlListConverter<XmlEvent, XmlEvent> {
  const XmlNormalizeEvents();

  @override
  ChunkedConversionSink<List<XmlEvent>> startChunkedConversion(
          Sink<List<XmlEvent>> sink) =>
      _XmlNormalizeEventsSink(sink);
}

class _XmlNormalizeEventsSink extends ChunkedConversionSink<List<XmlEvent>> {
  _XmlNormalizeEventsSink(this.sink);

  final Sink<List<XmlEvent>> sink;
  final List<XmlEvent> buffer = <XmlEvent>[];

  @override
  void add(List<XmlEvent> chunk) {
    // Filter out empty text nodes.
    buffer.addAll(
        chunk.where((event) => !(event is XmlTextEvent && event.text.isEmpty)));
    // Merge adjacent text nodes.
    for (var i = 0; i < buffer.length - 1;) {
      final event1 = buffer[i], event2 = buffer[i + 1];
      if (event1 is XmlTextEvent && event2 is XmlTextEvent) {
        // Combine text nodes, decode the combined input.
        final event = event1 is XmlRawTextEvent && event2 is XmlRawTextEvent
            ? XmlRawTextEvent(event1.raw + event2.raw, event1.entityMapping)
            : XmlTextEvent(event1.text + event2.text);
        // Propagate annotations.
        event.attachBuffer(event1.buffer);
        event.attachLocation(event1.start, event2.stop);
        event.attachParent(event1.parent);
        // Update the buffer.
        buffer[i] = event;
        buffer.removeAt(i + 1);
      } else {
        i++;
      }
    }
    // Move to sink whatever is possible.
    if (buffer.isNotEmpty) {
      if (buffer.last is XmlTextEvent) {
        if (buffer.length > 1) {
          sink.add(buffer.sublist(0, buffer.length - 1));
          buffer.removeRange(0, buffer.length - 1);
        }
      } else {
        sink.add(buffer.toList(growable: false));
        buffer.clear();
      }
    }
  }

  @override
  void close() {
    if (buffer.isNotEmpty) {
      sink.add(buffer.toList(growable: false));
      buffer.clear();
    }
    sink.close();
  }
}
