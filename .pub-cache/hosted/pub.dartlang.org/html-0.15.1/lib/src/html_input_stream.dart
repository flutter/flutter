import 'dart:collection';
import 'dart:convert' show ascii, utf8;

import 'package:source_span/source_span.dart';

import 'constants.dart';
import 'encoding_parser.dart';
import 'utils.dart';

/// Provides a unicode stream of characters to the HtmlTokenizer.
///
/// This class takes care of character encoding and removing or replacing
/// incorrect byte-sequences and also provides column and line tracking.
class HtmlInputStream {
  /// Number of bytes to use when looking for a meta element with
  /// encoding information.
  static const int numBytesMeta = 512;

  /// Encoding to use if no other information can be found.
  static const String defaultEncoding = 'utf-8';

  /// The name of the character encoding.
  String? charEncodingName;

  /// True if we are certain about [charEncodingName], false for tenative.
  bool charEncodingCertain = true;

  final bool generateSpans;

  /// Location where the contents of the stream were found.
  final String? sourceUrl;

  List<int>? _rawBytes;

  /// Raw UTF-16 codes, used if a Dart String is passed in.
  List<int>? _rawChars;

  var errors = Queue<String>();

  SourceFile? fileInfo;

  var _chars = <int>[];

  var _offset = 0;

  /// Initialise an HtmlInputStream.
  ///
  /// HtmlInputStream(source, [encoding]) -> Normalized stream from source
  /// for use by html5lib.
  ///
  /// [source] can be either a [String] or a [List<int>] containing the raw
  /// bytes.
  ///
  /// The optional encoding parameter must be a string that indicates
  /// the encoding.  If specified, that encoding will be used,
  /// regardless of any BOM or later declaration (such as in a meta
  /// element)
  ///
  /// [parseMeta] - Look for a <meta> element containing encoding information
  HtmlInputStream(source,
      [String? encoding,
      bool parseMeta = true,
      this.generateSpans = false,
      this.sourceUrl])
      : charEncodingName = codecName(encoding) {
    if (source is String) {
      _rawChars = source.codeUnits;
      charEncodingName = 'utf-8';
      charEncodingCertain = true;
    } else if (source is List<int>) {
      _rawBytes = source;
    } else {
      throw ArgumentError.value(
          source, 'source', 'Must be a String or List<int>.');
    }

    // Detect encoding iff no explicit "transport level" encoding is supplied
    if (charEncodingName == null) {
      detectEncoding(parseMeta);
    }

    reset();
  }

  void reset() {
    errors = Queue<String>();

    _offset = 0;
    _chars = <int>[];

    final rawChars = _rawChars ??= _decodeBytes(charEncodingName!, _rawBytes!);

    var skipNewline = false;
    var wasSurrogatePair = false;
    for (var i = 0; i < rawChars.length; i++) {
      var c = rawChars[i];
      if (skipNewline) {
        skipNewline = false;
        if (c == newLine) continue;
      }

      final isSurrogatePair = _isSurrogatePair(rawChars, i);
      if (!isSurrogatePair && !wasSurrogatePair) {
        if (_invalidUnicode(c)) {
          errors.add('invalid-codepoint');

          if (0xD800 <= c && c <= 0xDFFF) {
            c = 0xFFFD;
          }
        }
      }
      wasSurrogatePair = isSurrogatePair;

      if (c == returnCode) {
        skipNewline = true;
        c = newLine;
      }

      _chars.add(c);
    }

    // Free decoded characters if they aren't needed anymore.
    if (_rawBytes != null) _rawChars = null;

    // TODO(sigmund): Don't parse the file at all if spans aren't being
    // generated.
    fileInfo = SourceFile.decoded(_chars, url: sourceUrl);
  }

  void detectEncoding([bool parseMeta = true]) {
    // First look for a BOM
    // This will also read past the BOM if present
    charEncodingName = detectBOM();
    charEncodingCertain = true;

    // If there is no BOM need to look for meta elements with encoding
    // information
    if (charEncodingName == null && parseMeta) {
      charEncodingName = detectEncodingMeta();
      charEncodingCertain = false;
    }
    // If all else fails use the default encoding
    if (charEncodingName == null) {
      charEncodingCertain = false;
      charEncodingName = defaultEncoding;
    }

    // Substitute for equivalent encodings:
    if (charEncodingName!.toLowerCase() == 'iso-8859-1') {
      charEncodingName = 'windows-1252';
    }
  }

  void changeEncoding(String? newEncoding) {
    if (_rawBytes == null) {
      // We should never get here -- if encoding is certain we won't try to
      // change it.
      throw StateError('cannot change encoding when parsing a String.');
    }

    newEncoding = codecName(newEncoding);
    if (const ['utf-16', 'utf-16-be', 'utf-16-le'].contains(newEncoding)) {
      newEncoding = 'utf-8';
    }
    if (newEncoding == null) {
      return;
    } else if (newEncoding == charEncodingName) {
      charEncodingCertain = true;
    } else {
      charEncodingName = newEncoding;
      charEncodingCertain = true;
      _rawChars = null;
      reset();
      throw ReparseException(
          'Encoding changed from $charEncodingName to $newEncoding');
    }
  }

  /// Attempts to detect at BOM at the start of the stream. If
  /// an encoding can be determined from the BOM return the name of the
  /// encoding otherwise return null.
  String? detectBOM() {
    // Try detecting the BOM using bytes from the string
    if (_hasUtf8Bom(_rawBytes!)) {
      return 'utf-8';
    }
    return null;
  }

  /// Report the encoding declared by the meta element.
  String? detectEncodingMeta() {
    final parser = EncodingParser(slice(_rawBytes!, 0, numBytesMeta));
    var encoding = parser.getEncoding();

    if (const ['utf-16', 'utf-16-be', 'utf-16-le'].contains(encoding)) {
      encoding = 'utf-8';
    }

    return encoding;
  }

  /// Returns the current offset in the stream, i.e. the number of codepoints
  /// since the start of the file.
  int get position => _offset;

  /// Read one character from the stream or queue if available. Return
  /// EOF when EOF is reached.
  String? char() {
    if (_offset >= _chars.length) return eof;
    return _isSurrogatePair(_chars, _offset)
        ? String.fromCharCodes([_chars[_offset++], _chars[_offset++]])
        : String.fromCharCode(_chars[_offset++]);
  }

  String? peekChar() {
    if (_offset >= _chars.length) return eof;
    return _isSurrogatePair(_chars, _offset)
        ? String.fromCharCodes([_chars[_offset], _chars[_offset + 1]])
        : String.fromCharCode(_chars[_offset]);
  }

  // Whether the current and next chars indicate a surrogate pair.
  bool _isSurrogatePair(List<int> chars, int i) {
    return i + 1 < chars.length &&
        _isLeadSurrogate(chars[i]) &&
        _isTrailSurrogate(chars[i + 1]);
  }

  // Is then code (a 16-bit unsigned integer) a UTF-16 lead surrogate.
  bool _isLeadSurrogate(int code) => (code & 0xFC00) == 0xD800;

  // Is then code (a 16-bit unsigned integer) a UTF-16 trail surrogate.
  bool _isTrailSurrogate(int code) => (code & 0xFC00) == 0xDC00;

  /// Returns a string of characters from the stream up to but not
  /// including any character in 'characters' or EOF.
  String charsUntil(String characters, [bool opposite = false]) {
    final start = _offset;
    String? c;
    while ((c = peekChar()) != null && characters.contains(c!) == opposite) {
      _offset += c.codeUnits.length;
    }

    return String.fromCharCodes(_chars.sublist(start, _offset));
  }

  void unget(String? ch) {
    // Only one character is allowed to be ungotten at once - it must
    // be consumed again before any further call to unget
    if (ch != null) {
      _offset -= ch.length;
      assert(peekChar() == ch);
    }
  }
}

// TODO(jmesserly): the Python code used a regex to check for this. But
// Dart doesn't let you create a regexp with invalid characters.
bool _invalidUnicode(int c) {
  if (0x0001 <= c && c <= 0x0008) return true;
  if (0x000E <= c && c <= 0x001F) return true;
  if (0x007F <= c && c <= 0x009F) return true;
  if (0xD800 <= c && c <= 0xDFFF) return true;
  if (0xFDD0 <= c && c <= 0xFDEF) return true;
  switch (c) {
    case 0x000B:
    case 0xFFFE:
    case 0xFFFF:
    case 0x01FFFE:
    case 0x01FFFF:
    case 0x02FFFE:
    case 0x02FFFF:
    case 0x03FFFE:
    case 0x03FFFF:
    case 0x04FFFE:
    case 0x04FFFF:
    case 0x05FFFE:
    case 0x05FFFF:
    case 0x06FFFE:
    case 0x06FFFF:
    case 0x07FFFE:
    case 0x07FFFF:
    case 0x08FFFE:
    case 0x08FFFF:
    case 0x09FFFE:
    case 0x09FFFF:
    case 0x0AFFFE:
    case 0x0AFFFF:
    case 0x0BFFFE:
    case 0x0BFFFF:
    case 0x0CFFFE:
    case 0x0CFFFF:
    case 0x0DFFFE:
    case 0x0DFFFF:
    case 0x0EFFFE:
    case 0x0EFFFF:
    case 0x0FFFFE:
    case 0x0FFFFF:
    case 0x10FFFE:
    case 0x10FFFF:
      return true;
  }
  return false;
}

/// Return the python codec name corresponding to an encoding or null if the
/// string doesn't correspond to a valid encoding.
String? codecName(String? encoding) {
  final asciiPunctuation = RegExp(
      '[\u0009-\u000D\u0020-\u002F\u003A-\u0040\u005B-\u0060\u007B-\u007E]');

  if (encoding == null) return null;
  final canonicalName = encoding.replaceAll(asciiPunctuation, '').toLowerCase();
  return encodings[canonicalName];
}

/// Returns true if the [bytes] starts with a UTF-8 byte order mark.
/// Since UTF-8 doesn't have byte order, it's somewhat of a misnomer, but it is
/// used in HTML to detect the UTF-
bool _hasUtf8Bom(List<int> bytes, [int offset = 0, int? length]) {
  final end = length != null ? offset + length : bytes.length;
  return (offset + 3) <= end &&
      bytes[offset] == 0xEF &&
      bytes[offset + 1] == 0xBB &&
      bytes[offset + 2] == 0xBF;
}

/// Decodes the [bytes] with the provided [encoding] and returns a list for
/// the codepoints. Supports the major unicode encodings as well as ascii and
/// and windows-1252 encodings.
List<int> _decodeBytes(String encoding, List<int> bytes) {
  switch (encoding) {
    case 'ascii':
      return ascii.decode(bytes).codeUnits;

    case 'utf-8':
      // NOTE: To match the behavior of the other decode functions, we eat the
      // UTF-8 BOM here. This is the default behavior of `utf8.decode`.
      return utf8.decode(bytes).codeUnits;

    default:
      throw ArgumentError('Encoding $encoding not supported');
  }
}
