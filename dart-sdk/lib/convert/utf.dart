// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.convert;

/// The Unicode Replacement character `U+FFFD` (�).
const int unicodeReplacementCharacterRune = 0xFFFD;

/// The Unicode Byte Order Marker (BOM) character `U+FEFF`.
const int unicodeBomCharacterRune = 0xFEFF;

/// An instance of the default implementation of the [Utf8Codec].
///
/// This instance provides a convenient access to the most common UTF-8
/// use cases.
///
/// Examples:
/// ```dart
/// var encoded = utf8.encode("Îñţérñåţîöñåļîžåţîờñ");
/// var decoded = utf8.decode([0x62, 0x6c, 0xc3, 0xa5, 0x62, 0xc3, 0xa6,
///                            0x72, 0x67, 0x72, 0xc3, 0xb8, 0x64]);
/// ```
const Utf8Codec utf8 = Utf8Codec();

/// A [Utf8Codec] encodes strings to utf-8 code units (bytes) and decodes
/// UTF-8 code units to strings.
final class Utf8Codec extends Encoding {
  final bool _allowMalformed;

  /// Instantiates a new [Utf8Codec].
  ///
  /// The optional [allowMalformed] argument defines how [decoder] (and [decode])
  /// deal with invalid or unterminated character sequences.
  ///
  /// If it is `true` (and not overridden at the method invocation) [decode] and
  /// the [decoder] replace invalid (or unterminated) octet
  /// sequences with the Unicode Replacement character `U+FFFD` (�). Otherwise
  /// they throw a [FormatException].
  const Utf8Codec({bool allowMalformed = false})
      : _allowMalformed = allowMalformed;

  /// The name of this codec is "utf-8".
  String get name => "utf-8";

  /// Decodes the UTF-8 [codeUnits] (a list of unsigned 8-bit integers) to the
  /// corresponding string.
  ///
  /// If the [codeUnits] start with the encoding of a
  /// [unicodeBomCharacterRune], that character is discarded.
  ///
  /// If [allowMalformed] is `true`, the decoder replaces invalid (or
  /// unterminated) character sequences with the Unicode Replacement character
  /// `U+FFFD` (�). Otherwise it throws a [FormatException].
  ///
  /// If [allowMalformed] is not given, it defaults to the `allowMalformed` that
  /// was used to instantiate `this`.
  String decode(List<int> codeUnits, {bool? allowMalformed}) {
    // Switch between const objects to avoid allocation.
    Utf8Decoder decoder = allowMalformed ?? _allowMalformed
        ? const Utf8Decoder(allowMalformed: true)
        : const Utf8Decoder(allowMalformed: false);
    return decoder.convert(codeUnits);
  }

  /// Encodes the [string] as UTF-8.
  Uint8List encode(String string) {
    return const Utf8Encoder().convert(string);
  }

  Utf8Encoder get encoder => const Utf8Encoder();
  Utf8Decoder get decoder {
    // Switch between const objects to avoid allocation.
    return _allowMalformed
        ? const Utf8Decoder(allowMalformed: true)
        : const Utf8Decoder(allowMalformed: false);
  }
}

/// This class converts strings to their UTF-8 code units (a list of
/// unsigned 8-bit integers).
///
/// Example:
/// ```dart
/// final utf8Encoder = utf8.encoder;
/// const sample = 'Îñţérñåţîöñåļîžåţîờñ';
/// final encodedSample = utf8Encoder.convert(sample);
/// print(encodedSample);
/// ```
final class Utf8Encoder extends Converter<String, List<int>> {
  const Utf8Encoder();

  /// Converts [string] to its UTF-8 code units (a list of
  /// unsigned 8-bit integers).
  ///
  /// If [start] and [end] are provided, only the substring
  /// `string.substring(start, end)` is converted.
  ///
  /// Any unpaired surrogate character (`U+D800`-`U+DFFF`) in the input string
  /// is encoded as a Unicode Replacement character `U+FFFD` (�).
  Uint8List convert(String string, [int start = 0, int? end]) {
    var stringLength = string.length;
    end = RangeError.checkValidRange(start, end, stringLength);
    var length = end - start;
    if (length == 0) return Uint8List(0);
    // Create a new encoder with a length that is guaranteed to be big enough.
    // A single code unit uses at most 3 bytes, a surrogate pair at most 4.
    var encoder = _Utf8Encoder.withBufferSize(length * 3);
    var endPosition = encoder._fillBuffer(string, start, end);
    assert(endPosition >= end - 1);
    if (endPosition != end) {
      // Encoding skipped the last code unit.
      // That can only happen if the last code unit is a leadsurrogate.
      // Force encoding of the lead surrogate by itself.
      var lastCodeUnit = string.codeUnitAt(end - 1);
      assert(_isLeadSurrogate(lastCodeUnit));
      // Write a replacement character to represent the unpaired surrogate.
      encoder._writeReplacementCharacter();
    }
    return encoder._buffer.sublist(0, encoder._bufferIndex);
  }

  /// Starts a chunked conversion.
  ///
  /// The converter works more efficiently if the given [sink] is a
  /// [ByteConversionSink].
  StringConversionSink startChunkedConversion(Sink<List<int>> sink) {
    return _Utf8EncoderSink(
        sink is ByteConversionSink ? sink : ByteConversionSink.from(sink));
  }

  // Override the base-classes bind, to provide a better type.
  Stream<List<int>> bind(Stream<String> stream) => super.bind(stream);
}

/// This class encodes Strings to UTF-8 code units (unsigned 8 bit integers).
// TODO(floitsch): make this class public.
class _Utf8Encoder {
  int _carry = 0;
  int _bufferIndex = 0;
  final Uint8List _buffer;

  static const _DEFAULT_BYTE_BUFFER_SIZE = 1024;

  _Utf8Encoder() : this.withBufferSize(_DEFAULT_BYTE_BUFFER_SIZE);

  _Utf8Encoder.withBufferSize(int bufferSize)
      : _buffer = _createBuffer(bufferSize);

  /// Allow an implementation to pick the most efficient way of storing bytes.
  static Uint8List _createBuffer(int size) => Uint8List(size);

  /// Write a replacement character (U+FFFD). Used for unpaired surrogates.
  void _writeReplacementCharacter() {
    _buffer[_bufferIndex++] = 0xEF;
    _buffer[_bufferIndex++] = 0xBF;
    _buffer[_bufferIndex++] = 0xBD;
  }

  /// Tries to combine the given [leadingSurrogate] with the [nextCodeUnit] and
  /// writes it to [_buffer].
  ///
  /// Returns true if the [nextCodeUnit] was combined with the
  /// [leadingSurrogate]. If it wasn't, then nextCodeUnit was not a trailing
  /// surrogate and has not been written yet.
  ///
  /// It is safe to pass 0 for [nextCodeUnit], in which case a replacement
  /// character is written to represent the unpaired lead surrogate.
  bool _writeSurrogate(int leadingSurrogate, int nextCodeUnit) {
    if (_isTailSurrogate(nextCodeUnit)) {
      var rune = _combineSurrogatePair(leadingSurrogate, nextCodeUnit);
      // If the rune is encoded with 2 code-units then it must be encoded
      // with 4 bytes in UTF-8.
      assert(rune > _THREE_BYTE_LIMIT);
      assert(rune <= _FOUR_BYTE_LIMIT);
      _buffer[_bufferIndex++] = 0xF0 | (rune >> 18);
      _buffer[_bufferIndex++] = 0x80 | ((rune >> 12) & 0x3f);
      _buffer[_bufferIndex++] = 0x80 | ((rune >> 6) & 0x3f);
      _buffer[_bufferIndex++] = 0x80 | (rune & 0x3f);
      return true;
    } else {
      // Unpaired lead surrogate.
      _writeReplacementCharacter();
      return false;
    }
  }

  /// Fills the [_buffer] with as many characters as possible.
  ///
  /// Does not encode any trailing lead-surrogate. This must be done by the
  /// caller.
  ///
  /// Returns the position in the string. The returned index points to the
  /// first code unit that hasn't been encoded.
  int _fillBuffer(String str, int start, int end) {
    if (start != end && _isLeadSurrogate(str.codeUnitAt(end - 1))) {
      // Don't handle a trailing lead-surrogate in this loop. The caller has
      // to deal with those.
      end--;
    }
    int stringIndex;
    for (stringIndex = start; stringIndex < end; stringIndex++) {
      var codeUnit = str.codeUnitAt(stringIndex);
      // ASCII has the same representation in UTF-8 and UTF-16.
      if (codeUnit <= _ONE_BYTE_LIMIT) {
        if (_bufferIndex >= _buffer.length) break;
        _buffer[_bufferIndex++] = codeUnit;
      } else if (_isLeadSurrogate(codeUnit)) {
        if (_bufferIndex + 4 > _buffer.length) break;
        // Note that it is safe to read the next code unit. We decremented
        // [end] above when the last valid code unit was a leading surrogate.
        var nextCodeUnit = str.codeUnitAt(stringIndex + 1);
        var wasCombined = _writeSurrogate(codeUnit, nextCodeUnit);
        if (wasCombined) stringIndex++;
      } else if (_isTailSurrogate(codeUnit)) {
        if (_bufferIndex + 3 > _buffer.length) break;
        // Unpaired tail surrogate.
        _writeReplacementCharacter();
      } else {
        var rune = codeUnit;
        if (rune <= _TWO_BYTE_LIMIT) {
          if (_bufferIndex + 1 >= _buffer.length) break;
          _buffer[_bufferIndex++] = 0xC0 | (rune >> 6);
          _buffer[_bufferIndex++] = 0x80 | (rune & 0x3f);
        } else {
          assert(rune <= _THREE_BYTE_LIMIT);
          if (_bufferIndex + 2 >= _buffer.length) break;
          _buffer[_bufferIndex++] = 0xE0 | (rune >> 12);
          _buffer[_bufferIndex++] = 0x80 | ((rune >> 6) & 0x3f);
          _buffer[_bufferIndex++] = 0x80 | (rune & 0x3f);
        }
      }
    }
    return stringIndex;
  }
}

/// This class encodes chunked strings to UTF-8 code units (unsigned 8-bit
/// integers).
class _Utf8EncoderSink extends _Utf8Encoder with StringConversionSink {
  final ByteConversionSink _sink;

  _Utf8EncoderSink(this._sink);

  void close() {
    if (_carry != 0) {
      // addSlice will call close again, but then the carry must be equal to 0.
      addSlice("", 0, 0, true);
      return;
    }
    _sink.close();
  }

  void addSlice(String str, int start, int end, bool isLast) {
    _bufferIndex = 0;

    if (start == end && !isLast) {
      return;
    }

    if (_carry != 0) {
      var nextCodeUnit = 0;
      if (start != end) {
        nextCodeUnit = str.codeUnitAt(start);
      } else {
        assert(isLast);
      }
      var wasCombined = _writeSurrogate(_carry, nextCodeUnit);
      // Either we got a non-empty string, or we must not have been combined.
      assert(!wasCombined || start != end);
      if (wasCombined) start++;
      _carry = 0;
    }
    do {
      start = _fillBuffer(str, start, end);
      var isLastSlice = isLast && (start == end);
      if (start == end - 1 && _isLeadSurrogate(str.codeUnitAt(start))) {
        if (isLast && _bufferIndex < _buffer.length - 3) {
          // There is still space for the replacement character to represent
          // the last incomplete surrogate.
          _writeReplacementCharacter();
        } else {
          // Otherwise store it in the carry. If isLast is true, then
          // close will flush the last carry.
          _carry = str.codeUnitAt(start);
        }
        start++;
      }
      _sink.addSlice(_buffer, 0, _bufferIndex, isLastSlice);
      _bufferIndex = 0;
    } while (start < end);
    if (isLast) close();
  }

  // TODO(floitsch): implement asUtf8Sink. Slightly complicated because it
  // needs to deal with malformed input.
}

/// This class converts UTF-8 code units (lists of unsigned 8-bit integers)
/// to a string.
///
/// Example:
/// ```dart
/// final utf8Decoder = utf8.decoder;
/// const encodedBytes = [
///   195, 142, 195, 177, 197, 163, 195, 169, 114, 195, 177, 195, 165, 197,
///   163, 195, 174, 195, 182, 195, 177, 195, 165, 196, 188, 195, 174, 197,
///   190, 195, 165, 197, 163, 195, 174, 225, 187, 157, 195, 177];
///
/// final decodedBytes = utf8Decoder.convert(encodedBytes);
/// print(decodedBytes); // Îñţérñåţîöñåļîžåţîờñ
/// ```
/// Throws a [FormatException] if the encoded input contains
/// invalid UTF-8 byte sequences and [allowMalformed] is `false` (the default).
///
/// If [allowMalformed] is `true`, invalid byte sequences are converted into
/// one or more Unicode replacement characters, U+FFFD ('�').
///
/// Example with `allowMalformed` set to true:
/// ```dart
/// const utf8Decoder = Utf8Decoder(allowMalformed: true);
/// const encodedBytes = [0xFF];
/// final decodedBytes = utf8Decoder.convert(encodedBytes);
/// print(decodedBytes); // �
/// ```
final class Utf8Decoder extends Converter<List<int>, String> {
  final bool _allowMalformed;

  /// Instantiates a new [Utf8Decoder].
  ///
  /// The optional [allowMalformed] argument defines how [convert] deals
  /// with invalid or unterminated character sequences.
  ///
  /// If it is `true`, [convert] replaces invalid (or unterminated) character
  /// sequences with the Unicode Replacement character `U+FFFD` (�). Otherwise
  /// it throws a [FormatException].
  const Utf8Decoder({bool allowMalformed = false})
      : _allowMalformed = allowMalformed;

  /// Converts the UTF-8 [codeUnits] (a list of unsigned 8-bit integers) to the
  /// corresponding string.
  ///
  /// Uses the code units from [start] to, but not including, [end].
  /// If [end] is omitted, it defaults to `codeUnits.length`.
  ///
  /// If the [codeUnits] start with the encoding of a
  /// [unicodeBomCharacterRune], that character is discarded.
  String convert(List<int> codeUnits, [int start = 0, int? end]) =>
      _Utf8Decoder(_allowMalformed).convertSingle(codeUnits, start, end);

  /// Starts a chunked conversion.
  ///
  /// The converter works more efficiently if the given [sink] is a
  /// [StringConversionSink].
  ByteConversionSink startChunkedConversion(Sink<String> sink) {
    StringConversionSink stringSink;
    if (sink is StringConversionSink) {
      stringSink = sink;
    } else {
      stringSink = StringConversionSink.from(sink);
    }
    return stringSink.asUtf8Sink(_allowMalformed);
  }

  // Override the base-classes bind, to provide a better type.
  Stream<String> bind(Stream<List<int>> stream) => super.bind(stream);

  external Converter<List<int>, T> fuse<T>(Converter<String, T> next);
}

// UTF-8 constants.
const int _ONE_BYTE_LIMIT = 0x7f; // 7 bits
const int _TWO_BYTE_LIMIT = 0x7ff; // 11 bits
const int _THREE_BYTE_LIMIT = 0xffff; // 16 bits
const int _FOUR_BYTE_LIMIT = 0x10ffff; // 21 bits, truncated to Unicode max.

// UTF-16 constants.
const int _SURROGATE_TAG_MASK = 0xFC00;
const int _SURROGATE_VALUE_MASK = 0x3FF;
const int _LEAD_SURROGATE_MIN = 0xD800;
const int _TAIL_SURROGATE_MIN = 0xDC00;

bool _isLeadSurrogate(int codeUnit) =>
    (codeUnit & _SURROGATE_TAG_MASK) == _LEAD_SURROGATE_MIN;
bool _isTailSurrogate(int codeUnit) =>
    (codeUnit & _SURROGATE_TAG_MASK) == _TAIL_SURROGATE_MIN;
int _combineSurrogatePair(int lead, int tail) =>
    0x10000 + ((lead & _SURROGATE_VALUE_MASK) << 10) |
    (tail & _SURROGATE_VALUE_MASK);

class _Utf8Decoder {
  /// Decode malformed UTF-8 as replacement characters (instead of throwing)?
  final bool allowMalformed;

  /// Decoder DFA state.
  int _state;

  /// Partially decoded character. Meaning depends on state. Not used when in
  /// the initial/accept state. When in an error state, contains the index into
  /// the input of the error.
  int _charOrIndex = 0;

  // State machine for UTF-8 decoding, based on this decoder by Björn Höhrmann:
  // https://bjoern.hoehrmann.de/utf-8/decoder/dfa/
  //
  // One iteration in the state machine proceeds as:
  //
  // type = typeTable[byte];
  // char = (state != accept)
  //     ? (byte & 0x3F) | (char << 6)
  //     : byte & (shiftedByteMask >> type);
  // state = transitionTable[state + type];
  //
  // After each iteration, if state == accept, char is output as a character.

  // Mask to and on the type read from the table.
  static const int typeMask = 0x1F;
  // Mask shifted right by byte type to mask first byte of sequence.
  static const int shiftedByteMask = 0xF0FE;

  // Byte types.
  // 'A' = ASCII, 00-7F
  // 'B' = 2-byte, C2-DF
  // 'C' = 3-byte, E1-EC, EE
  // 'D' = 3-byte (possibly surrogate), ED
  // 'E' = Illegal, C0-C1, F5+
  // 'F' = Low extension, 80-8F
  // 'G' = Mid extension, 90-9F
  // 'H' = High extension, A0-BA, BC-BE
  // 'I' = Second byte of BOM, BB
  // 'J' = Third byte of BOM, BF
  // 'K' = 3-byte (possibly overlong), E0
  // 'L' = First byte of BOM, EF
  // 'M' = 4-byte (possibly out-of-range), F4
  // 'N' = 4-byte, F1-F3
  // 'O' = 4-byte (possibly overlong), F0
  static const String typeTable = ""
      "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" // 00-1F
      "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" // 20-3F
      "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" // 40-5F
      "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" // 60-7F
      "FFFFFFFFFFFFFFFFGGGGGGGGGGGGGGGG" // 80-9F
      "HHHHHHHHHHHHHHHHHHHHHHHHHHHIHHHJ" // A0-BF
      "EEBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB" // C0-DF
      "KCCCCCCCCCCCCDCLONNNMEEEEEEEEEEE" // E0-FF
      ;

  // States (offsets into transition table).
  static const int IA = 0x00; // Initial / Accept
  static const int BB = 0x10; // Before BOM
  static const int AB = 0x20; // After BOM
  static const int X1 = 0x30; // Expecting one extension byte
  static const int X2 = 0x3A; // Expecting two extension bytes
  static const int X3 = 0x44; // Expecting three extension bytes
  static const int TO = 0x4E; // Possibly overlong 3-byte
  static const int TS = 0x58; // Possibly surrogate
  static const int QO = 0x62; // Possibly overlong 4-byte
  static const int QR = 0x6C; // Possibly out-of-range 4-byte
  static const int B1 = 0x76; // One byte into BOM
  static const int B2 = 0x80; // Two bytes into BOM
  static const int E1 = 0x41; // Error: Missing extension byte
  static const int E2 = 0x43; // Error: Unexpected extension byte
  static const int E3 = 0x45; // Error: Invalid byte
  static const int E4 = 0x47; // Error: Overlong encoding
  static const int E5 = 0x49; // Error: Out of range
  static const int E6 = 0x4B; // Error: Surrogate
  static const int E7 = 0x4D; // Error: Unfinished

  // Character equivalents for states.
  static const String _IA = '\u0000';
  static const String _BB = '\u0010';
  static const String _AB = '\u0020';
  static const String _X1 = '\u0030';
  static const String _X2 = '\u003A';
  static const String _X3 = '\u0044';
  static const String _TO = '\u004E';
  static const String _TS = '\u0058';
  static const String _QO = '\u0062';
  static const String _QR = '\u006C';
  static const String _B1 = '\u0076';
  static const String _B2 = '\u0080';
  static const String _E1 = '\u0041';
  static const String _E2 = '\u0043';
  static const String _E3 = '\u0045';
  static const String _E4 = '\u0047';
  static const String _E5 = '\u0049';
  static const String _E6 = '\u004B';
  static const String _E7 = '\u004D';

  // Transition table of the state machine. Maps state and byte type
  // to next state.
  static const String transitionTable = " "
      // A   B   C   D   E   F   G   H   I   J   K   L   M   N   O
      "$_IA$_X1$_X2$_TS$_E3$_E2$_E2$_E2$_E2$_E2$_TO$_X2$_QR$_X3$_QO " // IA
      "$_IA$_X1$_X2$_TS$_E3$_E2$_E2$_E2$_E2$_E2$_TO$_B1$_QR$_X3$_QO " // BB
      "$_IA$_X1$_X2$_TS$_E3$_E2$_E2$_E2$_E2$_E2$_TO$_X2$_QR$_X3$_QO " // AB
      "$_E1$_E1$_E1$_E1$_E1$_IA$_IA$_IA$_IA$_IA" // Overlap 5 E1s        X1
      "$_E1$_E1$_E1$_E1$_E1$_X1$_X1$_X1$_X1$_X1" // Overlap 5 E1s        X2
      "$_E1$_E1$_E1$_E1$_E1$_X2$_X2$_X2$_X2$_X2" // Overlap 5 E1s        X3
      "$_E1$_E1$_E1$_E1$_E1$_E4$_E4$_X1$_X1$_X1" // Overlap 5 E1s        TO
      "$_E1$_E1$_E1$_E1$_E1$_X1$_X1$_E6$_E6$_E6" // Overlap 5 E1s        TS
      "$_E1$_E1$_E1$_E1$_E1$_E4$_X2$_X2$_X2$_X2" // Overlap 5 E1s        QO
      "$_E1$_E1$_E1$_E1$_E1$_X2$_E5$_E5$_E5$_E5" // Overlap 5 E1s        QR
      "$_E1$_E1$_E1$_E1$_E1$_X1$_X1$_X1$_B2$_X1" // Overlap 5 E1s        B1
      "$_E1$_E1$_E1$_E1$_E1$_IA$_IA$_IA$_IA$_AB$_E1$_E1$_E1$_E1$_E1" //  B2
      ;

  // Aliases for states.
  static const int initial = IA;
  static const int accept = IA;
  static const int beforeBom = BB;
  static const int afterBom = AB;
  static const int errorMissingExtension = E1;
  static const int errorUnexpectedExtension = E2;
  static const int errorInvalid = E3;
  static const int errorOverlong = E4;
  static const int errorOutOfRange = E5;
  static const int errorSurrogate = E6;
  static const int errorUnfinished = E7;

  @pragma("vm:prefer-inline")
  static bool isErrorState(int state) => (state & 1) != 0;

  static String errorDescription(int state) {
    switch (state) {
      case errorMissingExtension:
        return "Missing extension byte";
      case errorUnexpectedExtension:
        return "Unexpected extension byte";
      case errorInvalid:
        return "Invalid UTF-8 byte";
      case errorOverlong:
        return "Overlong encoding";
      case errorOutOfRange:
        return "Out of unicode range";
      case errorSurrogate:
        return "Encoded surrogate";
      case errorUnfinished:
        return "Unfinished UTF-8 octet sequence";
      default:
        return "";
    }
  }

  external _Utf8Decoder(bool allowMalformed);

  external String convertSingle(List<int> codeUnits, int start, int? maybeEnd);

  external String convertChunked(List<int> codeUnits, int start, int? maybeEnd);

  String convertGeneral(
      List<int> codeUnits, int start, int? maybeEnd, bool single) {
    int end = RangeError.checkValidRange(start, maybeEnd, codeUnits.length);

    if (start == end) return "";

    // Have bytes as Uint8List.
    Uint8List bytes;
    int errorOffset;
    if (codeUnits is Uint8List) {
      bytes = codeUnits;
      errorOffset = 0;
    } else {
      bytes = _makeUint8List(codeUnits, start, end);
      errorOffset = start;
      end -= start;
      start = 0;
    }

    String result = decodeGeneral(bytes, start, end, single);
    if (isErrorState(_state)) {
      String message = errorDescription(_state);
      _state = initial; // Ready for more input.
      throw FormatException(message, codeUnits, errorOffset + _charOrIndex);
    }
    return result;
  }

  /// Flushes this decoder as if closed.
  ///
  /// This method throws if the input was partial and the decoder was
  /// constructed with `allowMalformed` set to `false`.
  void flush(StringSink sink) {
    final int state = _state;
    _state = initial;
    if (state <= afterBom) {
      return;
    }
    // Unfinished sequence.
    if (allowMalformed) {
      sink.writeCharCode(unicodeReplacementCharacterRune);
    } else {
      throw FormatException(errorDescription(errorUnfinished), null, null);
    }
  }

  String decodeGeneral(Uint8List bytes, int start, int end, bool single) {
    final String typeTable = _Utf8Decoder.typeTable;
    final String transitionTable = _Utf8Decoder.transitionTable;
    int state = _state;
    int char = _charOrIndex;
    final StringBuffer buffer = StringBuffer();
    int i = start;
    int byte = bytes[i++];
    loop:
    while (true) {
      multibyte:
      while (true) {
        int type = typeTable.codeUnitAt(byte) & typeMask;
        char = (state <= afterBom)
            ? byte & (shiftedByteMask >> type)
            : (byte & 0x3F) | (char << 6);
        state = transitionTable.codeUnitAt(state + type);
        if (state == accept) {
          buffer.writeCharCode(char);
          if (i == end) break loop;
          break multibyte;
        } else if (isErrorState(state)) {
          if (allowMalformed) {
            switch (state) {
              case errorInvalid:
              case errorUnexpectedExtension:
                // A single byte that can't start a sequence.
                buffer.writeCharCode(unicodeReplacementCharacterRune);
                break;
              case errorMissingExtension:
                // Unfinished sequence followed by a byte that can start a
                // sequence.
                buffer.writeCharCode(unicodeReplacementCharacterRune);
                // Re-parse offending byte.
                i -= 1;
                break;
              default:
                // Unfinished sequence followed by a byte that can't start a
                // sequence.
                buffer.writeCharCode(unicodeReplacementCharacterRune);
                buffer.writeCharCode(unicodeReplacementCharacterRune);
                break;
            }
            state = initial;
          } else {
            _state = state;
            _charOrIndex = i - 1;
            return "";
          }
        }
        if (i == end) break loop;
        byte = bytes[i++];
      }

      final int markStart = i;
      byte = bytes[i++];
      if (byte < 128) {
        int markEnd = end;
        while (i < end) {
          byte = bytes[i++];
          if (byte >= 128) {
            markEnd = i - 1;
            break;
          }
        }
        assert(markStart < markEnd);
        if (markEnd - markStart < 20) {
          for (int m = markStart; m < markEnd; m++) {
            buffer.writeCharCode(bytes[m]);
          }
        } else {
          buffer.write(String.fromCharCodes(bytes, markStart, markEnd));
        }
        if (markEnd == end) break loop;
      }
    }

    if (single && state > afterBom) {
      // Unfinished sequence.
      if (allowMalformed) {
        buffer.writeCharCode(unicodeReplacementCharacterRune);
      } else {
        _state = errorUnfinished;
        _charOrIndex = end;
        return "";
      }
    }
    _state = state;
    _charOrIndex = char;
    return buffer.toString();
  }

  static Uint8List _makeUint8List(List<int> codeUnits, int start, int end) {
    final int length = end - start;
    final Uint8List bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      int b = codeUnits[start + i];
      if ((b & ~0xFF) != 0) {
        // Replace invalid byte values by FF, which is also invalid.
        b = 0xFF;
      }
      bytes[i] = b;
    }
    return bytes;
  }
}
