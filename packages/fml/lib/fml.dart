// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class Node {
}

class Text extends Node {
  String data;
}

class Attribute {
  String name;
  String value;
}

class Element extends Node {
  String tagName;
  List<Attribute> attributes;
}

const int _lowerA = 0x61;
const int _lowerZ = 0x7A;
const int _upperA = 0x41;
const int _upperZ = 0x5A;
const int _zero = 0x30;
const int _nine = 0x39;
const int _dash = 0x2D;
const int _underbar = 0x5F;
const int _dot = 0x2E;
const int _lessThan = 0x3C;
const int _equals = 0x3D;
const int _greaterThan = 0x3E;
const int _solidus = 0x2F;
const int _ampersand = 0x26;
const int _exclamationMark = 0x21;
const int _singleQuote = 0x27;
const int _doubleQuote = 0x22;
const int _space = 0x20;
const int _newline = 0x0A;
const int _carriageReturn = 0x0D;
const int _replacementRune = 0xFFFD;

bool _isTokenizerTagName(int rune) {
  if (rune >= _lowerA && rune <= _lowerZ)
    return true;
  if (rune >= _upperA && rune <= _upperZ)
    return true;
  if (rune >= _zero && rune <= _nine)
    return true;
  return rune == _dash || rune == _underbar || rune == _dot;
}

bool _isTokenizerWhitespace(int rune) {
  return rune == _space || rune == _newline;
}

enum _State {
  data,
  characterReferenceInData,
  characterReferenceInAttributeValue,
  tagOpen,
  closeTag,
  tagName,
  beforeAttributeName,
  attributeName,
  afterAttributeName,
  beforeAttributeValue,
  attributeValueDoubleQuoted,
  attributeValueSingleQuoted,
  attributeValueUnquoted,
  voidTag,
  commentStart1,
  commentStart2,
  comment,
  commentEnd1,
  commentEnd2,
}

enum _TokenType {
  text,
  startTag,
  endTag
}

abstract class ParserSink {
  void pushText(Text text);
  void pushElement(Element element);
  void popElement();
}

class Parser {
  Parser(this._sink) {
    assert(_sink != null);
  }

  ParserSink _sink;
  _State _state = _State.data;
  _TokenType _tokenType = _TokenType.text;
  bool _isSelfClosing = false;
  final List<int> _buffer = <int>[];
  final List<int> _attributeBuffer = <int>[];
  List<Attribute> _attributes = <Attribute>[];

  void _consumeRune(int rune) {
    switch (_state) {
    case _State.data:
      assert(_tokenType == _TokenType.text);
      if (rune == _ampersand) {
        // Handle character reference.
      } else if (rune == _lessThan) {
        if (_buffer.isNotEmpty)
          _emitToken();
        _state = _State.tagOpen;
      } else {
        _buffer.add(rune);
      }
      break;
    case _State.characterReferenceInData:
      break;
    case _State.characterReferenceInAttributeValue:
      break;
    case _State.tagOpen:
      if (rune == _exclamationMark) {
        _state = _State.commentStart1;
      } else if (rune == _solidus) {
        _state = _State.closeTag;
      } else if (_isTokenizerTagName(rune)) {
        _buffer.add(rune);
        _tokenType = _TokenType.startTag;
        _isSelfClosing = false;
        _state = _State.tagName;
      } else {
        _buffer.add(_lessThan);
        _state = _State.data;
        _consumeRune(rune);
      }
      break;
    case _State.closeTag:
      if (_isTokenizerTagName(rune)) {
        _buffer.add(rune);
        _tokenType = _TokenType.endTag;
        _isSelfClosing = false;
        _state = _State.tagName;
      } else if (rune == _greaterThan) {
        _buffer.add(_lessThan);
        _buffer.add(_solidus);
        _buffer.add(_greaterThan);
        _state = _State.data;
      } else {
        _buffer.add(_lessThan);
        _buffer.add(_solidus);
        _state = _State.data;
        _consumeRune(rune);
      }
      break;
    case _State.tagName:
      if (_isTokenizerWhitespace(rune)) {
        _state = _State.beforeAttributeName;
      } else if (rune == _solidus) {
        _state = _State.voidTag;
      } else if (rune == _greaterThan) {
        _emitToken();
      } else {
        _buffer.add(rune);
      }
      break;
    case _State.beforeAttributeName:
      if (_isTokenizerWhitespace(rune)) {
        // Stay in this state.
      } else if (rune == _solidus) {
        _state = _State.voidTag;
      } else if (rune == _greaterThan) {
        _emitToken();
      } else {
        assert(_attributeBuffer.isEmpty);
        _attributeBuffer.add(rune);
        _state = _State.attributeName;
      }
      break;
    case _State.attributeName:
      if (_isTokenizerWhitespace(rune)) {
        _emitAttributeName();
        // Stay in this state.
      } else if (rune == _solidus) {
        _emitAttributeName();
        _state = _State.voidTag;
      } else if (rune == _equals) {
        _emitAttributeName();
        _state = _State.beforeAttributeValue;
      } else if (rune == _greaterThan) {
        _emitAttributeName();
        _emitToken();
      } else {
        _attributeBuffer.add(rune);
      }
      break;
    case _State.afterAttributeName:
      if (_isTokenizerWhitespace(rune)) {
        // Stay in this state.
      } else if (rune == _solidus) {
        _state = _State.voidTag;
      } else if (rune == _equals) {
        _state = _State.beforeAttributeValue;
      } else if (rune == _greaterThan) {
        _emitToken();
      } else {
        assert(_attributeBuffer.isEmpty);
        _attributeBuffer.add(rune);
        _state = _State.attributeName;
      }
      break;
    case _State.beforeAttributeValue:
      if (_isTokenizerWhitespace(rune)) {
        // Stay in this state.
      } else if (rune == _doubleQuote) {
        assert(_attributeBuffer.isEmpty);
        _state = _State.attributeValueDoubleQuoted;
      } else if (rune == _ampersand) {
        assert(_attributeBuffer.isEmpty);
        _state = _State.attributeValueUnquoted;
        _consumeRune(rune);
      } else if (rune == _singleQuote) {
        assert(_attributeBuffer.isEmpty);
        _state = _State.attributeValueSingleQuoted;
      } else if (rune == _greaterThan) {
        _emitToken();
      } else {
        assert(_attributeBuffer.isEmpty);
        _attributeBuffer.add(rune);
        _state = _State.attributeValueUnquoted;
      }
      break;
    case _State.attributeValueDoubleQuoted:
      if (rune == _doubleQuote) {
        _emitAttributeValue();
        _state = _State.beforeAttributeName;
      } else if (rune == _ampersand) {
        // Handle entities.
      } else {
        _attributeBuffer.add(rune);
        // Stay in this state.
      }
      break;
    case _State.attributeValueSingleQuoted:
      if (rune == _singleQuote) {
        _emitAttributeValue();
        _state = _State.beforeAttributeName;
      } else if (rune == _ampersand) {
        // Handle entities.
      } else {
        _attributeBuffer.add(rune);
        // Stay in this state.
      }
      break;
    case _State.attributeValueUnquoted:
      if (_isTokenizerWhitespace(rune)) {
        _emitAttributeValue();
        _state = _State.beforeAttributeName;
      } else if (rune == _ampersand) {
        // Handle entities.
      } else if (rune == _greaterThan) {
        _emitAttributeValue();
        _emitToken();
      } else {
        _attributeBuffer.add(rune);
        // Stay in this state.
      }
      break;
    case _State.voidTag:
      if (rune == _greaterThan) {
        _isSelfClosing = true;
        _emitToken();
      } else {
        _state = _State.beforeAttributeName;
        _consumeRune(rune);
      }
      break;
    case _State.commentStart1:
      if (rune == _dash) {
        _state = _State.commentStart2;
      } else {
        _buffer.add(_lessThan);
        _buffer.add(_exclamationMark);
        _state = _State.data;
        _consumeRune(rune);
      }
      break;
    case _State.commentStart2:
      if (rune == _dash) {
        _state = _State.comment;
      } else {
        _buffer.add(_lessThan);
        _buffer.add(_exclamationMark);
        _buffer.add(_dash);
        _state = _State.data;
        _consumeRune(rune);
      }
      break;
    case _State.comment:
      if (rune == _dash) {
        _state = _State.commentEnd1;
      } else {
        // Stay in this state.
      }
      break;
    case _State.commentEnd1:
      if (rune == _dash) {
        _state = _State.commentEnd2;
      } else {
        _state = _State.comment;
      }
      break;
    case _State.commentEnd2:
      if (rune == _dash) {
        // Stay in this state.
      } else if (rune == _greaterThan) {
        _state = _State.commentEnd2;
      } else {
        _state = _State.comment;
      }
      break;
    }
  }

  bool _lastRuneWasCarriageReturn = false;

  void add(String content) {
    for (int rune in content.runes) {
      if (rune == _carriageReturn) {
        _lastRuneWasCarriageReturn = true;
        rune = _newline;
      } else {
        if (rune == 0) {
          rune = _replacementRune;
        } else if (rune == _newline && _lastRuneWasCarriageReturn) {
          _lastRuneWasCarriageReturn = false;
          continue;
        }
        _lastRuneWasCarriageReturn = false;
      }
      _consumeRune(rune);
    }
  }

  void finish() {
    _flushPendingText();
    _emitEOF();
  }

  void _emitAttributeName() {
    Attribute attribute = new Attribute()
      ..name = new String.fromCharCodes(_attributeBuffer);
    _attributes.add(attribute);
    _attributeBuffer.clear();
  }

  void _emitAttributeValue() {
    _attributes.last.value = new String.fromCharCodes(_attributeBuffer);
    _attributeBuffer.clear();
  }

  String _pendingData;
  final List<String> _openElements = <String>[];

  void _emitToken() {
    switch (_tokenType) {
    case _TokenType.text:
      assert(_buffer.isNotEmpty);
      String data = new String.fromCharCodes(_buffer);
      _buffer.clear();
      _pendingData = _pendingData == null ? data : _pendingData + data;
      break;
    case _TokenType.startTag:
      _flushPendingText();
      Element element = new Element()
        ..tagName = new String.fromCharCodes(_buffer)
        ..attributes = _attributes;
      _buffer.clear();
      _attributes = <Attribute>[];
      _openElements.add(element.tagName);
      _sink.pushElement(element);
      if (_isSelfClosing)
        _sink.popElement();
      break;
    case _TokenType.endTag:
      _flushPendingText();
      String tagName = new String.fromCharCodes(_buffer);
      _buffer.clear();
      _attributes = <Attribute>[];
      int index = _openElements.lastIndexOf(tagName);
      if (index != -1) {
        _openElements.length = index;
        while (index-- >= 0)
          _sink.popElement();
      }
      break;
    }
    _tokenType = _TokenType.text;
    _state = _State.data;
  }

  void _flushPendingText() {
    if (_pendingData != null) {
      Text text = new Text()..data = _pendingData;
      _pendingData = null;
      _sink.pushText(text);
    }
  }

  void _emitEOF() {
    int index = _openElements.length;
    _openElements.clear();
    while (index-- >= 0)
      _sink.popElement();
  }
}
