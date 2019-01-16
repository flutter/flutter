// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' hide utf8;
import 'dart:convert' as cnv show utf8;

import 'base/common.dart';
export 'dart:convert' hide utf8, Utf8Codec, Utf8Decoder;

/// A [Codec] which reports malformed bytes when decoding.
// Created to solve https://github.com/flutter/flutter/issues/15646.
class Utf8Codec extends Encoding {
  const Utf8Codec();

  @override
  Converter<List<int>, String> get decoder => const Utf8Decoder();

  @override
  Converter<String, List<int>> get encoder => cnv.utf8.encoder;

  @override
  String get name => cnv.utf8.name;
}

Encoding get utf8 => const Utf8Codec();

class Utf8Decoder extends Converter<List<int>, String> {
  const Utf8Decoder({this.reportErrors = true});

  final bool reportErrors;

  @override
  String convert(List<int> input) {
    final String result = cnv.utf8.decode(input, allowMalformed: true);
    // Finding a unicode replacement character indicates that the input
    // was malformed.
    if (reportErrors && result.contains('\u{FFFD}')) {
      throwToolExit(
        'Bad UTF-8 encoding found while decoding string: $result. '
        'The Flutter team would greatly appreciate if you could file a bug or leave a'
        'comment on the issue https://github.com/flutter/flutter/issues/15646.\n'
        'The source bytes were:\n$input\n\n');
    }
    return result;
  }
}