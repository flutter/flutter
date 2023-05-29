import 'dart:async';

import '../event.dart';
import '../events/cdata.dart';
import '../events/comment.dart';
import '../events/declaration.dart';
import '../events/doctype.dart';
import '../events/end_element.dart';
import '../events/processing.dart';
import '../events/start_element.dart';
import '../events/text.dart';
import '../visitor.dart';

typedef EventHandler<T> = void Function(T event);

extension XmlEachEventStreamExtension on Stream<XmlEvent> {
  /// Executes the provided callbacks on each event of this stream as a side
  /// effect.
  ///
  /// Returns the unmodified stream of events. Note that this does not start
  /// processing the events unless somebody subscribes to the stream.
  Stream<XmlEvent> tapEachEvent({
    EventHandler<XmlCDATAEvent>? onCDATA,
    EventHandler<XmlCommentEvent>? onComment,
    EventHandler<XmlDeclarationEvent>? onDeclaration,
    EventHandler<XmlDoctypeEvent>? onDoctype,
    EventHandler<XmlEndElementEvent>? onEndElement,
    EventHandler<XmlProcessingEvent>? onProcessing,
    EventHandler<XmlStartElementEvent>? onStartElement,
    EventHandler<XmlTextEvent>? onText,
  }) {
    final handler = XmlEventHandler(
      onCDATA: onCDATA,
      onComment: onComment,
      onDeclaration: onDeclaration,
      onDoctype: onDoctype,
      onEndElement: onEndElement,
      onProcessing: onProcessing,
      onStartElement: onStartElement,
      onText: onText,
    );
    return map((event) {
      handler.visit(event);
      return event;
    });
  }

  /// Executes the provided callbacks on each event of this stream.
  ///
  /// Completes the returned [Future] when all events of this stream have been
  /// processed.
  Future<void> forEachEvent({
    EventHandler<XmlCDATAEvent>? onCDATA,
    EventHandler<XmlCommentEvent>? onComment,
    EventHandler<XmlDeclarationEvent>? onDeclaration,
    EventHandler<XmlDoctypeEvent>? onDoctype,
    EventHandler<XmlEndElementEvent>? onEndElement,
    EventHandler<XmlProcessingEvent>? onProcessing,
    EventHandler<XmlStartElementEvent>? onStartElement,
    EventHandler<XmlTextEvent>? onText,
  }) =>
      tapEachEvent(
        onCDATA: onCDATA,
        onComment: onComment,
        onDeclaration: onDeclaration,
        onDoctype: onDoctype,
        onEndElement: onEndElement,
        onProcessing: onProcessing,
        onStartElement: onStartElement,
        onText: onText,
      ).drain();
}

extension XmlEachEventStreamListExtension on Stream<List<XmlEvent>> {
  /// Executes the provided callbacks on each event of this stream as a side
  /// effect.
  ///
  /// Returns the unmodified stream of events. Note that this does not start
  /// processing the events unless somebody subscribes to the stream.
  Stream<List<XmlEvent>> tapEachEvent({
    EventHandler<XmlCDATAEvent>? onCDATA,
    EventHandler<XmlCommentEvent>? onComment,
    EventHandler<XmlDeclarationEvent>? onDeclaration,
    EventHandler<XmlDoctypeEvent>? onDoctype,
    EventHandler<XmlEndElementEvent>? onEndElement,
    EventHandler<XmlProcessingEvent>? onProcessing,
    EventHandler<XmlStartElementEvent>? onStartElement,
    EventHandler<XmlTextEvent>? onText,
  }) {
    final handler = XmlEventHandler(
      onCDATA: onCDATA,
      onComment: onComment,
      onDeclaration: onDeclaration,
      onDoctype: onDoctype,
      onEndElement: onEndElement,
      onProcessing: onProcessing,
      onStartElement: onStartElement,
      onText: onText,
    );
    return map((eventList) {
      eventList.forEach(handler.visit);
      return eventList;
    });
  }

  /// Executes the provided callbacks on each event of this stream.
  ///
  /// Completes the returned [Future] when all events of this stream have been
  /// processed.
  Future<void> forEachEvent({
    EventHandler<XmlCDATAEvent>? onCDATA,
    EventHandler<XmlCommentEvent>? onComment,
    EventHandler<XmlDeclarationEvent>? onDeclaration,
    EventHandler<XmlDoctypeEvent>? onDoctype,
    EventHandler<XmlEndElementEvent>? onEndElement,
    EventHandler<XmlProcessingEvent>? onProcessing,
    EventHandler<XmlStartElementEvent>? onStartElement,
    EventHandler<XmlTextEvent>? onText,
  }) =>
      tapEachEvent(
        onCDATA: onCDATA,
        onComment: onComment,
        onDeclaration: onDeclaration,
        onDoctype: onDoctype,
        onEndElement: onEndElement,
        onProcessing: onProcessing,
        onStartElement: onStartElement,
        onText: onText,
      ).drain();
}

class XmlEventHandler with XmlEventVisitor {
  const XmlEventHandler({
    this.onCDATA,
    this.onComment,
    this.onDeclaration,
    this.onDoctype,
    this.onEndElement,
    this.onProcessing,
    this.onStartElement,
    this.onText,
  });

  final EventHandler<XmlCDATAEvent>? onCDATA;
  final EventHandler<XmlCommentEvent>? onComment;
  final EventHandler<XmlDeclarationEvent>? onDeclaration;
  final EventHandler<XmlDoctypeEvent>? onDoctype;
  final EventHandler<XmlEndElementEvent>? onEndElement;
  final EventHandler<XmlProcessingEvent>? onProcessing;
  final EventHandler<XmlStartElementEvent>? onStartElement;
  final EventHandler<XmlTextEvent>? onText;

  @override
  void visitCDATAEvent(XmlCDATAEvent event) => onCDATA?.call(event);

  @override
  void visitCommentEvent(XmlCommentEvent event) => onComment?.call(event);

  @override
  void visitDeclarationEvent(XmlDeclarationEvent event) =>
      onDeclaration?.call(event);

  @override
  void visitDoctypeEvent(XmlDoctypeEvent event) => onDoctype?.call(event);

  @override
  void visitEndElementEvent(XmlEndElementEvent event) =>
      onEndElement?.call(event);

  @override
  void visitProcessingEvent(XmlProcessingEvent event) =>
      onProcessing?.call(event);

  @override
  void visitStartElementEvent(XmlStartElementEvent event) =>
      onStartElement?.call(event);

  @override
  void visitTextEvent(XmlTextEvent event) => onText?.call(event);
}
