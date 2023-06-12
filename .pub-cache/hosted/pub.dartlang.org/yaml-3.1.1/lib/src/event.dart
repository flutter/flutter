// Copyright (c) 2014, the Dart project authors.
// Copyright (c) 2006, Kirill Simonov.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'package:source_span/source_span.dart';

import 'style.dart';
import 'yaml_document.dart';

/// An event emitted by a [Parser].
class Event {
  final EventType type;
  final FileSpan span;

  Event(this.type, this.span);

  @override
  String toString() => type.toString();
}

/// An event indicating the beginning of a YAML document.
class DocumentStartEvent implements Event {
  @override
  EventType get type => EventType.documentStart;
  @override
  final FileSpan span;

  /// The document's `%YAML` directive, or `null` if there was none.
  final VersionDirective? versionDirective;

  /// The document's `%TAG` directives, if any.
  final List<TagDirective> tagDirectives;

  /// Whether the document started implicitly (that is, without an explicit
  /// `===` sequence).
  final bool isImplicit;

  DocumentStartEvent(this.span,
      {this.versionDirective,
      List<TagDirective>? tagDirectives,
      this.isImplicit = true})
      : tagDirectives = tagDirectives ?? [];

  @override
  String toString() => 'DOCUMENT_START';
}

/// An event indicating the end of a YAML document.
class DocumentEndEvent implements Event {
  @override
  EventType get type => EventType.documentEnd;
  @override
  final FileSpan span;

  /// Whether the document ended implicitly (that is, without an explicit
  /// `...` sequence).
  final bool isImplicit;

  DocumentEndEvent(this.span, {this.isImplicit = true});

  @override
  String toString() => 'DOCUMENT_END';
}

/// An event indicating that an alias was referenced.
class AliasEvent implements Event {
  @override
  EventType get type => EventType.alias;
  @override
  final FileSpan span;

  /// The alias name.
  final String name;

  AliasEvent(this.span, this.name);

  @override
  String toString() => 'ALIAS $name';
}

/// An event that can have associated anchor and tag properties.
abstract class _ValueEvent implements Event {
  /// The name of the value's anchor, or `null` if it wasn't anchored.
  String? get anchor;

  /// The text of the value's tag, or `null` if it wasn't tagged.
  String? get tag;

  @override
  String toString() {
    var buffer = StringBuffer('$type');
    if (anchor != null) buffer.write(' &$anchor');
    if (tag != null) buffer.write(' $tag');
    return buffer.toString();
  }
}

/// An event indicating a single scalar value.
class ScalarEvent extends _ValueEvent {
  @override
  EventType get type => EventType.scalar;
  @override
  final FileSpan span;
  @override
  final String? anchor;
  @override
  final String? tag;

  /// The contents of the scalar.
  final String value;

  /// The style of the scalar in the original source.
  final ScalarStyle style;

  ScalarEvent(this.span, this.value, this.style, {this.anchor, this.tag});

  @override
  String toString() => '${super.toString()} "$value"';
}

/// An event indicating the beginning of a sequence.
class SequenceStartEvent extends _ValueEvent {
  @override
  EventType get type => EventType.sequenceStart;
  @override
  final FileSpan span;
  @override
  final String? anchor;
  @override
  final String? tag;

  /// The style of the collection in the original source.
  final CollectionStyle style;

  SequenceStartEvent(this.span, this.style, {this.anchor, this.tag});
}

/// An event indicating the beginning of a mapping.
class MappingStartEvent extends _ValueEvent {
  @override
  EventType get type => EventType.mappingStart;
  @override
  final FileSpan span;
  @override
  final String? anchor;
  @override
  final String? tag;

  /// The style of the collection in the original source.
  final CollectionStyle style;

  MappingStartEvent(this.span, this.style, {this.anchor, this.tag});
}

/// The types of [Event] objects.
enum EventType {
  streamStart,
  streamEnd,
  documentStart,
  documentEnd,
  alias,
  scalar,
  sequenceStart,
  sequenceEnd,
  mappingStart,
  mappingEnd
}
