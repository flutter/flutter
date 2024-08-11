// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.convert;

/// An instance of the default implementation of the [Latin1Codec].
///
/// This instance provides a convenient access to the most common ISO Latin 1
/// use cases.
///
/// Examples:
/// ```dart
/// var encoded = latin1.encode("blåbærgrød");
/// var decoded = latin1.decode([0x62, 0x6c, 0xe5, 0x62, 0xe6,
///                              0x72, 0x67, 0x72, 0xf8, 0x64]);
/// ```
const Latin1Codec latin1 = Latin1Codec();

const int _latin1Mask = 0xFF;

/// A [Latin1Codec] encodes strings to ISO Latin-1 (aka ISO-8859-1) bytes
/// and decodes Latin-1 bytes to strings.
final class Latin1Codec extends Encoding {
  final bool _allowInvalid;

  /// Instantiates a new [Latin1Codec].
  ///
  /// If [allowInvalid] is true, the [decode] method and the converter
  /// returned by [decoder] will default to allowing invalid values. Invalid
  /// values are decoded into the Unicode Replacement character (U+FFFD).
  /// Calls to the [decode] method can override this default.
  ///
  /// Encoders will not accept invalid (non Latin-1) characters.
  const Latin1Codec({bool allowInvalid = false}) : _allowInvalid = allowInvalid;

  /// The name of this codec, "iso-8859-1".
  String get name => "iso-8859-1";

  Uint8List encode(String source) => encoder.convert(source);

  /// Decodes the Latin-1 [bytes] (a list of unsigned 8-bit integers) to the
  /// corresponding string.
  ///
  /// If [bytes] contains values that are not in the range 0 .. 255, the decoder
  /// will eventually throw a [FormatException].
  ///
  /// If [allowInvalid] is not provided, it defaults to the value used to create
  /// this [Latin1Codec].
  String decode(List<int> bytes, {bool? allowInvalid}) {
    if (allowInvalid ?? _allowInvalid) {
      return const Latin1Decoder(allowInvalid: true).convert(bytes);
    } else {
      return const Latin1Decoder(allowInvalid: false).convert(bytes);
    }
  }

  Latin1Encoder get encoder => const Latin1Encoder();

  Latin1Decoder get decoder => _allowInvalid
      ? const Latin1Decoder(allowInvalid: true)
      : const Latin1Decoder(allowInvalid: false);
}

/// This class converts strings of only ISO Latin-1 characters to bytes.
///
/// Example:
/// ```dart
/// final latin1Encoder = latin1.encoder;
///
/// const sample = 'àáâãäå';
/// final encoded = latin1Encoder.convert(sample);
/// print(encoded); // [224, 225, 226, 227, 228, 229]
/// ```
final class Latin1Encoder extends _UnicodeSubsetEncoder {
  const Latin1Encoder() : super(_latin1Mask);
}

/// This class converts Latin-1 bytes (lists of unsigned 8-bit integers)
/// to a string.
///
/// Example:
/// ```dart
/// final latin1Decoder = latin1.decoder;
///
/// const encodedBytes = [224, 225, 226, 227, 228, 229];
/// final decoded = latin1Decoder.convert(encodedBytes);
/// print(decoded); // àáâãäå
///
/// // Hexadecimal values as source
/// const hexBytes = [0xe0, 0xe1, 0xe2, 0xe3, 0xe4, 0xe5];
/// final decodedHexBytes = latin1Decoder.convert(hexBytes);
/// print(decodedHexBytes); // àáâãäå
/// ```
/// Throws a [FormatException] if the encoded input contains values that are
/// not in the range 0 .. 255 and [allowInvalid] is false ( the default ).
///
/// If [allowInvalid] is true, invalid bytes are converted
/// to Unicode Replacement character U+FFFD (�).
///
/// Example with `allowInvalid` set to true:
/// ```dart
/// const latin1Decoder = Latin1Decoder(allowInvalid: true);
/// const encodedBytes = [300];
/// final decoded = latin1Decoder.convert(encodedBytes);
/// print(decoded); // �
/// ```
final class Latin1Decoder extends _UnicodeSubsetDecoder {
  /// Instantiates a new [Latin1Decoder].
  ///
  /// The optional [allowInvalid] argument defines how [convert] deals
  /// with invalid bytes.
  ///
  /// If it is `true`, [convert] replaces invalid bytes with the Unicode
  /// Replacement character `U+FFFD` (�).
  /// Otherwise it throws a [FormatException].
  const Latin1Decoder({bool allowInvalid = false})
      : super(allowInvalid, _latin1Mask);

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
    // TODO(lrn): Use stringSink.asUtf16Sink() if it becomes available.
    if (!_allowInvalid) return _Latin1DecoderSink(stringSink);
    return _Latin1AllowInvalidDecoderSink(stringSink);
  }
}

class _Latin1DecoderSink extends ByteConversionSink {
  StringConversionSink? _sink;
  _Latin1DecoderSink(this._sink);

  void close() {
    _sink!.close();
    _sink = null;
  }

  void add(List<int> source) {
    addSlice(source, 0, source.length, false);
  }

  void _addSliceToSink(List<int> source, int start, int end, bool isLast) {
    // If _sink was a UTF-16 conversion sink, just add the slice directly with
    // _sink.addSlice(source, start, end, isLast).
    // The code below is an moderately stupid workaround until a real
    // solution can be made.
    _sink!.add(String.fromCharCodes(source, start, end));
    if (isLast) close();
  }

  void addSlice(List<int> source, int start, int end, bool isLast) {
    RangeError.checkValidRange(start, end, source.length);
    if (start == end) return;
    if (source is! Uint8List) {
      // List may contain value outside of the 0..255 range. If so, throw.
      // Technically, we could excuse Uint8ClampedList as well, but it unlikely
      // to be relevant.
      _checkValidLatin1(source, start, end);
    }
    _addSliceToSink(source, start, end, isLast);
  }

  static void _checkValidLatin1(List<int> source, int start, int end) {
    var mask = 0;
    for (var i = start; i < end; i++) {
      mask |= source[i];
    }
    if (mask >= 0 && mask <= _latin1Mask) {
      return;
    }
    _reportInvalidLatin1(source, start, end); // Always throws.
  }

  static void _reportInvalidLatin1(List<int> source, int start, int end) {
    // Find the index of the first non-Latin-1 character code.
    for (var i = start; i < end; i++) {
      var char = source[i];
      if (char < 0 || char > _latin1Mask) {
        throw FormatException(
            "Source contains non-Latin-1 characters.", source, i);
      }
    }
    // Unreachable - we only call the function if the loop above throws.
    assert(false);
  }
}

class _Latin1AllowInvalidDecoderSink extends _Latin1DecoderSink {
  _Latin1AllowInvalidDecoderSink(StringConversionSink sink) : super(sink);

  void addSlice(List<int> source, int start, int end, bool isLast) {
    RangeError.checkValidRange(start, end, source.length);
    for (var i = start; i < end; i++) {
      var char = source[i];
      if (char > _latin1Mask || char < 0) {
        if (i > start) _addSliceToSink(source, start, i, false);
        // Add UTF-8 encoding of U+FFFD.
        _addSliceToSink(const [0xFFFD], 0, 1, false);
        start = i + 1;
      }
    }
    if (start < end) {
      _addSliceToSink(source, start, end, isLast);
    }
    if (isLast) {
      close();
    }
  }
}
