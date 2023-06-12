import 'constants.dart';
import 'html_input_stream.dart';

// TODO(jmesserly): I converted StopIteration to StateError("No more elements").
// Seems strange to throw this from outside of an iterator though.
/// String-like object with an associated position and various extra methods
/// If the position is ever greater than the string length then an exception is
/// raised.
class EncodingBytes {
  final String _bytes;
  int __position = -1;

  EncodingBytes(this._bytes);

  int get _length => _bytes.length;

  String _next() {
    final p = __position = __position + 1;
    if (p >= _length) {
      throw StateError('No more elements');
    } else if (p < 0) {
      throw RangeError(p);
    }
    return _bytes[p];
  }

  String _previous() {
    var p = __position;
    if (p >= _length) {
      throw StateError('No more elements');
    } else if (p < 0) {
      throw RangeError(p);
    }
    __position = p = p - 1;
    return _bytes[p];
  }

  set _position(int value) {
    if (__position >= _length) {
      throw StateError('No more elements');
    }
    __position = value;
  }

  int get _position {
    if (__position >= _length) {
      throw StateError('No more elements');
    }
    if (__position >= 0) {
      return __position;
    } else {
      return 0;
    }
  }

  String get _currentByte => _bytes[_position];

  /// Skip past a list of characters. Defaults to skipping [isWhitespace].
  String? _skipChars([_CharPredicate? skipChars]) {
    skipChars ??= isWhitespace;
    var p = _position; // use property for the error-checking
    while (p < _length) {
      final c = _bytes[p];
      if (!skipChars(c)) {
        __position = p;
        return c;
      }
      p += 1;
    }
    __position = p;
    return null;
  }

  String? _skipUntil(_CharPredicate untilChars) {
    var p = _position;
    while (p < _length) {
      final c = _bytes[p];
      if (untilChars(c)) {
        __position = p;
        return c;
      }
      p += 1;
    }
    return null;
  }

  /// Look for a sequence of bytes at the start of a string. If the bytes
  /// are found return true and advance the position to the byte after the
  /// match. Otherwise return false and leave the position alone.
  bool _matchBytes(String bytes) {
    final p = _position;
    if (_bytes.length < p + bytes.length) {
      return false;
    }
    final data = _bytes.substring(p, p + bytes.length);
    if (data == bytes) {
      _position += bytes.length;
      return true;
    }
    return false;
  }

  /// Look for the next sequence of bytes matching a given sequence. If
  /// a match is found advance the position to the last byte of the match
  bool _jumpTo(String bytes) {
    final newPosition = _bytes.indexOf(bytes, _position);
    if (newPosition >= 0) {
      __position = newPosition + bytes.length - 1;
      return true;
    } else {
      throw StateError('No more elements');
    }
  }

  String _slice(int start, [int? end]) {
    end ??= _length;
    if (end < 0) end += _length;
    return _bytes.substring(start, end);
  }
}

typedef _MethodHandler = bool Function();

class _DispatchEntry {
  final String pattern;
  final _MethodHandler handler;

  _DispatchEntry(this.pattern, this.handler);
}

/// Mini parser for detecting character encoding from meta elements.
class EncodingParser {
  final EncodingBytes _data;
  String? _encoding;

  /// [bytes] - the data to work on for encoding detection.
  EncodingParser(List<int> bytes)
      // Note: this is intentionally interpreting bytes as codepoints.
      : _data = EncodingBytes(String.fromCharCodes(bytes).toLowerCase());

  String? getEncoding() {
    final methodDispatch = [
      _DispatchEntry('<!--', _handleComment),
      _DispatchEntry('<meta', _handleMeta),
      _DispatchEntry('</', _handlePossibleEndTag),
      _DispatchEntry('<!', _handleOther),
      _DispatchEntry('<?', _handleOther),
      _DispatchEntry('<', _handlePossibleStartTag),
    ];

    try {
      for (;;) {
        for (var dispatch in methodDispatch) {
          if (_data._matchBytes(dispatch.pattern)) {
            final keepParsing = dispatch.handler();
            if (keepParsing) break;

            // We found an encoding. Stop.
            return _encoding;
          }
        }
        _data._position += 1;
      }
    } on StateError catch (_) {
      // Catch this here to match behavior of Python's StopIteration
      // TODO(jmesserly): refactor to not use exceptions
    }
    return _encoding;
  }

  /// Skip over comments.
  bool _handleComment() => _data._jumpTo('-->');

  bool _handleMeta() {
    if (!isWhitespace(_data._currentByte)) {
      // if we have <meta not followed by a space so just keep going
      return true;
    }
    // We have a valid meta element we want to search for attributes
    while (true) {
      // Try to find the next attribute after the current position
      final attr = _getAttribute();
      if (attr == null) return true;

      if (attr[0] == 'charset') {
        final tentativeEncoding = attr[1];
        final codec = codecName(tentativeEncoding);
        if (codec != null) {
          _encoding = codec;
          return false;
        }
      } else if (attr[0] == 'content') {
        final contentParser = ContentAttrParser(EncodingBytes(attr[1]));
        final tentativeEncoding = contentParser.parse();
        final codec = codecName(tentativeEncoding);
        if (codec != null) {
          _encoding = codec;
          return false;
        }
      }
    }
  }

  bool _handlePossibleStartTag() => _handlePossibleTag(false);

  bool _handlePossibleEndTag() {
    _data._next();
    return _handlePossibleTag(true);
  }

  bool _handlePossibleTag(bool endTag) {
    if (!isLetter(_data._currentByte)) {
      //If the next byte is not an ascii letter either ignore this
      //fragment (possible start tag case) or treat it according to
      //handleOther
      if (endTag) {
        _data._previous();
        _handleOther();
      }
      return true;
    }

    final c = _data._skipUntil(_isSpaceOrAngleBracket);
    if (c == '<') {
      // return to the first step in the overall "two step" algorithm
      // reprocessing the < byte
      _data._previous();
    } else {
      //Read all attributes
      var attr = _getAttribute();
      while (attr != null) {
        attr = _getAttribute();
      }
    }
    return true;
  }

  bool _handleOther() => _data._jumpTo('>');

  /// Return a name,value pair for the next attribute in the stream,
  /// if one is found, or null
  List<String>? _getAttribute() {
    // Step 1 (skip chars)
    var c = _data._skipChars((x) => x == '/' || isWhitespace(x));
    // Step 2
    if (c == '>' || c == null) {
      return null;
    }
    // Step 3
    final attrName = <String>[];
    final attrValue = <String>[];
    // Step 4 attribute name
    while (true) {
      if (c == null) {
        return null;
      } else if (c == '=' && attrName.isNotEmpty) {
        break;
      } else if (isWhitespace(c)) {
        // Step 6!
        c = _data._skipChars();
        c = _data._next();
        break;
      } else if (c == '/' || c == '>') {
        return [attrName.join(), ''];
      } else if (isLetter(c)) {
        attrName.add(c.toLowerCase());
      } else {
        attrName.add(c);
      }
      // Step 5
      c = _data._next();
    }
    // Step 7
    if (c != '=') {
      _data._previous();
      return [attrName.join(), ''];
    }
    // Step 8
    _data._next();
    // Step 9
    c = _data._skipChars();
    // Step 10
    if (c == "'" || c == '"') {
      // 10.1
      final quoteChar = c;
      while (true) {
        // 10.2
        c = _data._next();
        if (c == quoteChar) {
          // 10.3
          _data._next();
          return [attrName.join(), attrValue.join()];
        } else if (isLetter(c)) {
          // 10.4
          attrValue.add(c.toLowerCase());
        } else {
          // 10.5
          attrValue.add(c);
        }
      }
    } else if (c == '>') {
      return [attrName.join(), ''];
    } else if (c == null) {
      return null;
    } else if (isLetter(c)) {
      attrValue.add(c.toLowerCase());
    } else {
      attrValue.add(c);
    }
    // Step 11
    while (true) {
      c = _data._next();
      if (_isSpaceOrAngleBracket(c)) {
        return [attrName.join(), attrValue.join()];
      } else if (isLetter(c)) {
        attrValue.add(c.toLowerCase());
      } else {
        attrValue.add(c);
      }
    }
  }
}

class ContentAttrParser {
  final EncodingBytes data;

  ContentAttrParser(this.data);

  String? parse() {
    try {
      // Check if the attr name is charset
      // otherwise return
      data._jumpTo('charset');
      data._position += 1;
      data._skipChars();
      if (data._currentByte != '=') {
        // If there is no = sign keep looking for attrs
        return null;
      }
      data._position += 1;
      data._skipChars();
      // Look for an encoding between matching quote marks
      if (data._currentByte == '"' || data._currentByte == "'") {
        final quoteMark = data._currentByte;
        data._position += 1;
        final oldPosition = data._position;
        if (data._jumpTo(quoteMark)) {
          return data._slice(oldPosition, data._position);
        } else {
          return null;
        }
      } else {
        // Unquoted value
        final oldPosition = data._position;
        try {
          data._skipUntil(isWhitespace);
          return data._slice(oldPosition, data._position);
        } on StateError catch (_) {
          //Return the whole remaining value
          return data._slice(oldPosition);
        }
      }
    } on StateError catch (_) {
      return null;
    }
  }
}

bool _isSpaceOrAngleBracket(String char) {
  return char == '>' || char == '<' || isWhitespace(char);
}

typedef _CharPredicate = bool Function(String char);
