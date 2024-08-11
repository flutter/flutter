// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_foreign_helper' show JS;
import 'dart:_internal' show patch;
import 'dart:typed_data' show Uint8List;
import 'dart:_native_typed_data' show NativeUint8List;

@patch
class Utf8Decoder {
  @patch
  Converter<List<int>, T> fuse<T>(Converter<String, T> next) {
    return super.fuse(next);
  }
}

@patch
class _Utf8Decoder {
  // Always fall back to the Dart implementation for strings shorter than this
  // threshold, as there is a large, constant overhead for using TextDecoder.
  static const int _shortInputThreshold = 15;

  @patch
  _Utf8Decoder(this.allowMalformed) : _state = beforeBom;

  @patch
  String convertSingle(List<int> codeUnits, int start, int? maybeEnd) {
    return _convertGeneral(codeUnits, start, maybeEnd, true);
  }

  @patch
  String convertChunked(List<int> codeUnits, int start, int? maybeEnd) {
    return _convertGeneral(codeUnits, start, maybeEnd, false);
  }

  String _convertGeneral(
      List<int> codeUnits, int start, int? maybeEnd, bool single) {
    int end = RangeError.checkValidRange(start, maybeEnd, codeUnits.length);
    if (start == end) return "";

    final NativeUint8List bytes;
    final int errorOffset;
    if (JS<bool>('bool', '# instanceof Uint8Array', codeUnits)) {
      // JS 'cast' to avoid a downcast equivalent to the is-check we hand-coded.
      NativeUint8List casted =
          JS<NativeUint8List>('NativeUint8List', '#', codeUnits);
      bytes = casted;
      errorOffset = 0;
    } else {
      bytes = JS<NativeUint8List>(
          'NativeUint8List', '#', _makeNativeUint8List(codeUnits, start, end));
      errorOffset = start;
      end -= start;
      start = 0;
    }

    // Try the intercepted method. Try only for single conversions (chunked is
    // tricky). Try only for inputs that are long enough to to pay back the high
    // expense of using a TextDecoder.
    //
    // TODO(sra): It should be possible to use the intercepted code on chunked
    // conversions by rolling the state machine forward to a character boundary
    // and seeking to valid UTF-8 character boundary at the end.
    if (single && end - start >= _shortInputThreshold) {
      String? result =
          _convertInterceptedUint8List(allowMalformed, bytes, start, end);
      if (result != null) {
        if (!allowMalformed) return result;
        // In principle, TextDecoder should have provided the correct result
        // here, but some browsers deviate from the standard as to how many
        // replacement characters they produce for malformed inputs. Thus, we
        // fall back to the Dart implementation if the result contains any
        // replacement characters. We can't easily tell whether a replacement
        // character was encoded in the input, or inserted as the result of a
        // malformed input.
        //
        // TODO(43737): Remove test when all supported browsers are conformant.
        if (JS<int>('int', r'#.indexOf(#)', result, '\uFFFD') < 0) {
          return result;
        }
      }
    }

    String result = _decodeRecursive(bytes, start, end, single);
    if (isErrorState(_state)) {
      String message = errorDescription(_state);
      _state = initial; // Ready for more input.
      throw FormatException(message, codeUnits, errorOffset + _charOrIndex);
    }
    return result;
  }

  String _decodeRecursive(Uint8List bytes, int start, int end, bool single) {
    // Chunk long strings to avoid a pathological case of huge cons-strings from
    // repeated string concatenation in StringBuffer on JavaScript platforms.
    if (end - start > 1000) {
      int mid = (start + end) ~/ 2;
      String s1 = _decodeRecursive(bytes, start, mid, false);
      if (isErrorState(_state)) return s1;
      String s2 = _decodeRecursive(bytes, mid, end, single);
      return s1 + s2;
    }
    return decodeGeneral(bytes, start, end, single);
  }

  static Uint8List _makeNativeUint8List(
      List<int> codeUnits, int start, int end) {
    final int length = end - start;
    // Re-use a dedicated buffer to avoid allocating small buffers as this is
    // unreasonably expensive on some JavaScript engines.
    final Uint8List bytes =
        length <= _reusableBufferSize ? _reusableBuffer : Uint8List(length);

    for (int i = 0; i < length; i++) {
      int b = codeUnits[start + i];
      if ((b & 0xFF) != b) {
        // Replace invalid byte values by 0xFF, which is a valid byte value that
        // is an invalid UTF8 sequence.
        b = 0xFF;
      }
      JS('', '#[#] = #', bytes, i, b); //  bytes[i] = b;
    }
    return bytes;
  }

  static const _reusableBufferSize = 4096;
  static final Uint8List _reusableBuffer = Uint8List(_reusableBufferSize);

  static String? _convertInterceptedUint8List(
      bool allowMalformed, NativeUint8List codeUnits, int start, int end) {
    final decoder = allowMalformed ? _decoderNonfatal : _decoder;
    if (decoder == null) return null;
    if (0 == start && end == codeUnits.length) {
      return _useTextDecoder(decoder, codeUnits);
    }

    return _useTextDecoder(
        decoder,
        JS<NativeUint8List>(
            'NativeUint8List', '#.subarray(#, #)', codeUnits, start, end));
  }

  static String? _useTextDecoder(decoder, NativeUint8List codeUnits) {
    // If the input is malformed, catch the exception and return `null` to fall
    // back on unintercepted decoder. The fallback will either succeed in
    // decoding, or report the problem better than TextDecoder.
    try {
      return JS<String>('String', '#.decode(#)', decoder, codeUnits);
    } catch (e) {}
    return null;
  }

  // TextDecoder is not defined on some browsers and on the stand-alone d8 and
  // jsshell engines. Use a lazy initializer to do feature detection once.
  static final _decoder = () {
    try {
      return JS('', 'new TextDecoder("utf-8", {fatal: true})');
    } catch (e) {}
    return null;
  }();
  static final _decoderNonfatal = () {
    try {
      return JS('', 'new TextDecoder("utf-8", {fatal: false})');
    } catch (e) {}
    return null;
  }();
}
