/// This library contains token types used by the html5 tokenizer.
library token;

import 'dart:collection';
import 'package:source_span/source_span.dart';

/// An html5 token.
abstract class Token {
  FileSpan? span;

  int get kind;
}

abstract class TagToken extends Token {
  String? name;

  bool selfClosing;

  TagToken(this.name, this.selfClosing);
}

class StartTagToken extends TagToken {
  /// The tag's attributes. A map from the name to the value, where the name
  /// can be a [String] or `AttributeName`.
  LinkedHashMap<Object, String> data;

  /// The attribute spans if requested. Otherwise null.
  List<TagAttribute>? attributeSpans;

  bool selfClosingAcknowledged;

  /// The namespace. This is filled in later during tree building.
  String? namespace;

  StartTagToken(String? name,
      {LinkedHashMap<Object, String>? data,
      bool selfClosing = false,
      this.selfClosingAcknowledged = false,
      this.namespace})
      : data = data ?? LinkedHashMap(),
        super(name, selfClosing);

  @override
  int get kind => TokenKind.startTag;
}

class EndTagToken extends TagToken {
  EndTagToken(String? name, {bool selfClosing = false})
      : super(name, selfClosing);

  @override
  int get kind => TokenKind.endTag;
}

abstract class StringToken extends Token {
  StringBuffer? _buffer;

  String? _string;
  String get data {
    if (_string == null) {
      _string = _buffer.toString();
      _buffer = null;
    }
    return _string!;
  }

  StringToken(this._string) : _buffer = _string == null ? StringBuffer() : null;

  StringToken add(String data) {
    _buffer!.write(data);
    return this;
  }
}

class ParseErrorToken extends StringToken {
  /// Extra information that goes along with the error message.
  Map? messageParams;

  ParseErrorToken(String data, {this.messageParams}) : super(data);

  @override
  int get kind => TokenKind.parseError;
}

class CharactersToken extends StringToken {
  CharactersToken([String? data]) : super(data);

  @override
  int get kind => TokenKind.characters;

  /// Replaces the token's [data]. This should only be used to wholly replace
  /// data, not to append data.
  void replaceData(String newData) {
    _string = newData;
    _buffer = null;
  }
}

class SpaceCharactersToken extends StringToken {
  SpaceCharactersToken([String? data]) : super(data);

  @override
  int get kind => TokenKind.spaceCharacters;
}

class CommentToken extends StringToken {
  CommentToken([String? data]) : super(data);

  @override
  int get kind => TokenKind.comment;
}

class DoctypeToken extends Token {
  String? publicId;
  String? systemId;
  String? name = '';
  bool correct;

  DoctypeToken({this.publicId, this.systemId, this.correct = false});

  @override
  int get kind => TokenKind.doctype;
}

/// These are used by the tokenizer to build up the attribute map.
/// They're also used by [StartTagToken.attributeSpans] if attribute spans are
/// requested.
class TagAttribute {
  String? name;
  late String value;

  // The spans of the attribute. This is not used unless we are computing an
  // attribute span on demand.
  late int start;
  late int end;
  int? startValue;
  late int endValue;

  TagAttribute();
}

class TokenKind {
  static const int spaceCharacters = 0;
  static const int characters = 1;
  static const int startTag = 2;
  static const int endTag = 3;
  static const int comment = 4;
  static const int doctype = 5;
  static const int parseError = 6;
}
