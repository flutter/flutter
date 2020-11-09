// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Hide the original utf8 [Codec] so that we can export our own implementation
// which adds additional error handling.
import 'dart:convert' hide utf8;
import 'dart:convert' as cnv show utf8, Utf8Decoder;

import 'base/common.dart';
export 'dart:convert' hide utf8, Utf8Codec, Utf8Decoder;

/// A [Codec] which reports malformed bytes when decoding.
///
/// Occasionally people end up in a situation where we try to decode bytes
/// that aren't UTF-8 and we're not quite sure how this is happening.
/// This tells people to report a bug when they see this.
class Utf8Codec extends Encoding {
  const Utf8Codec();

  @override
  Converter<List<int>, String> get decoder => const Utf8Decoder();

  @override
  Converter<String, List<int>> get encoder => cnv.utf8.encoder;

  @override
  String get name => cnv.utf8.name;
}

const Encoding utf8 = Utf8Codec();

class Utf8Decoder extends cnv.Utf8Decoder {
  const Utf8Decoder({this.reportErrors = true}) : super(allowMalformed: true);

  final bool reportErrors;

  @override
  String convert(List<int> codeUnits, [ int start = 0, int end ]) {
    final String result = super.convert(codeUnits, start, end);
    // Finding a unicode replacement character indicates that the input
    // was malformed.
    if (reportErrors && result.contains('\u{FFFD}')) {
      throwToolExit(
        'Bad UTF-8 encoding found while decoding string: $result. '
        'The Flutter team would greatly appreciate if you could file a bug explaining '
        'exactly what you were doing when this happened:\n'
        'https://github.com/flutter/flutter/issues/new/choose\n'
        'The source bytes were:\n$codeUnits\n\n');
    }
    return result;
  }
}
