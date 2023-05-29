// Copyright (c) 2014, the Dart project authors.
// Copyright (c) 2006, Kirill Simonov.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'package:source_span/source_span.dart';

import 'style.dart';

/// A token emitted by a [Scanner].
class Token {
  final TokenType type;
  final FileSpan span;

  Token(this.type, this.span);

  @override
  String toString() => type.toString();
}

/// A token representing a `%YAML` directive.
class VersionDirectiveToken implements Token {
  @override
  TokenType get type => TokenType.versionDirective;
  @override
  final FileSpan span;

  /// The declared major version of the document.
  final int major;

  /// The declared minor version of the document.
  final int minor;

  VersionDirectiveToken(this.span, this.major, this.minor);

  @override
  String toString() => 'VERSION_DIRECTIVE $major.$minor';
}

/// A token representing a `%TAG` directive.
class TagDirectiveToken implements Token {
  @override
  TokenType get type => TokenType.tagDirective;
  @override
  final FileSpan span;

  /// The tag handle used in the document.
  final String handle;

  /// The tag prefix that the handle maps to.
  final String prefix;

  TagDirectiveToken(this.span, this.handle, this.prefix);

  @override
  String toString() => 'TAG_DIRECTIVE $handle $prefix';
}

/// A token representing an anchor (`&foo`).
class AnchorToken implements Token {
  @override
  TokenType get type => TokenType.anchor;
  @override
  final FileSpan span;

  final String name;

  AnchorToken(this.span, this.name);

  @override
  String toString() => 'ANCHOR $name';
}

/// A token representing an alias (`*foo`).
class AliasToken implements Token {
  @override
  TokenType get type => TokenType.alias;
  @override
  final FileSpan span;

  final String name;

  AliasToken(this.span, this.name);

  @override
  String toString() => 'ALIAS $name';
}

/// A token representing a tag (`!foo`).
class TagToken implements Token {
  @override
  TokenType get type => TokenType.tag;
  @override
  final FileSpan span;

  /// The tag handle for named tags.
  final String? handle;

  /// The tag suffix.
  final String suffix;

  TagToken(this.span, this.handle, this.suffix);

  @override
  String toString() => 'TAG $handle $suffix';
}

/// A scalar value.
class ScalarToken implements Token {
  @override
  TokenType get type => TokenType.scalar;
  @override
  final FileSpan span;

  /// The unparsed contents of the value..
  final String value;

  /// The style of the scalar in the original source.
  final ScalarStyle style;

  ScalarToken(this.span, this.value, this.style);

  @override
  String toString() => 'SCALAR $style "$value"';
}

/// The types of [Token] objects.
enum TokenType {
  streamStart,
  streamEnd,

  versionDirective,
  tagDirective,
  documentStart,
  documentEnd,

  blockSequenceStart,
  blockMappingStart,
  blockEnd,

  flowSequenceStart,
  flowSequenceEnd,
  flowMappingStart,
  flowMappingEnd,

  blockEntry,
  flowEntry,
  key,
  value,

  alias,
  anchor,
  tag,
  scalar
}
