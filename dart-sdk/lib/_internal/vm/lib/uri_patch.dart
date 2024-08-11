// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

typedef Uri _UriBaseClosure();

Uri _unsupportedUriBase() {
  throw new UnsupportedError("'Uri.base' is not supported");
}

// _uriBaseClosure can be overwritten by the embedder to supply a different
// value for Uri.base.
@pragma("vm:entry-point")
_UriBaseClosure _uriBaseClosure = _unsupportedUriBase;

@patch
class Uri {
  @patch
  static Uri get base => _uriBaseClosure();
}

/// VM implementation of Uri.
@patch
class _Uri {
  static final bool _isWindowsCached = _isWindowsPlatform;

  @pragma("vm:external-name", "Uri_isWindowsPlatform")
  external static bool get _isWindowsPlatform;

  @patch
  static bool get _isWindows => _isWindowsCached;

  @patch
  static String _uriEncode(List<int> canonicalTable, String text,
      Encoding encoding, bool spaceToPlus) {
    // First check if the text will be changed by encoding.
    int i = 0;
    if (identical(encoding, utf8) ||
        identical(encoding, latin1) ||
        identical(encoding, ascii)) {
      // Encoding is compatible with the original string.
      // Find first character that needs encoding.
      for (; i < text.length; i++) {
        var char = text.codeUnitAt(i);
        if (char >= 128 ||
            canonicalTable[char >> 4] & (1 << (char & 0x0f)) == 0) {
          break;
        }
      }
    }
    if (i == text.length) return text;

    // Encode the string into bytes then generate an ASCII only string
    // by percent encoding selected bytes.
    StringBuffer result = new StringBuffer();
    for (int j = 0; j < i; j++) {
      result.writeCharCode(text.codeUnitAt(j));
    }

    // TODO(lrn): Is there a way to only encode from index i and forwards.
    var bytes = encoding.encode(text);
    for (; i < bytes.length; i++) {
      int byte = bytes[i];
      if (byte < 128 &&
          ((canonicalTable[byte >> 4] & (1 << (byte & 0x0f))) != 0)) {
        result.writeCharCode(byte);
      } else if (spaceToPlus && byte == _SPACE) {
        result.writeCharCode(_PLUS);
      } else {
        const String hexDigits = '0123456789ABCDEF';
        result
          ..writeCharCode(_PERCENT)
          ..writeCharCode(hexDigits.codeUnitAt(byte >> 4))
          ..writeCharCode(hexDigits.codeUnitAt(byte & 0x0f));
      }
    }
    return result.toString();
  }

  @patch
  static String _makeQueryFromParameters(
      Map<String, dynamic /*String?|Iterable<String>*/ > queryParameters) {
    return _makeQueryFromParametersDefault(queryParameters);
  }
}
