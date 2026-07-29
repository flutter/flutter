// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Hide the original utf8 [Codec] so that we can export our own implementation
// which adds additional error handling.
import 'dart:convert' hide utf8;
import 'dart:convert' as cnv show Utf8Decoder, utf8;

import 'package:meta/meta.dart';

import 'base/common.dart';

export 'dart:convert' hide Utf8Codec, Utf8Decoder, utf8;

/// The original utf8 encoding for testing overrides only.
///
/// Attempting to use the flutter tool utf8 decoder will surface an analyzer
/// warning that overrides cannot change the default value of a named
/// parameter.
@visibleForTesting
const Encoding utf8ForTesting = cnv.utf8;

/// A [Codec] which permits malformed UTF-8 bytes when decoding.
///
/// This decoder is used for displaying application logs and tool output
/// where invalid UTF-8 is expected (e.g., from external devices, network
/// APIs, or debugging output). Invalid UTF-8 sequences will be decoded
/// to replacement characters (U+FFFD) without warnings.
///
/// For critical tool data parsing (configs, manifests), use the strict
/// [utf8] decoder instead, which will warn about malformed bytes.
const Encoding utf8AllowMalformed = Utf8Codec(reportErrors: false);

/// A [Codec] which reports malformed bytes when decoding.
///
/// Occasionally people end up in a situation where we try to decode bytes
/// that aren't UTF-8 and we're not quite sure how this is happening.
/// This prints a warning when they see this, but continues execution
/// to avoid disrupting the developer workflow.
class Utf8Codec extends Encoding {
  const Utf8Codec({this.reportErrors = true});

  final bool reportErrors;

  @override
  Converter<List<int>, String> get decoder =>
      reportErrors ? const Utf8Decoder() : const Utf8Decoder(reportErrors: false);

  @override
  Converter<String, List<int>> get encoder => cnv.utf8.encoder;

  @override
  String get name => cnv.utf8.name;
}

/// A strict UTF-8 decoder for critical tool data parsing.
///
/// This decoder reports warnings when encountering invalid UTF-8 sequences
/// (replacement character U+FFFD). It should be used for parsing tool-critical
/// data such as configuration files, manifests, and build metadata.
///
/// For displaying application logs and external tool output with potential
/// encoding issues, use [utf8AllowMalformed] instead.
const Encoding utf8 = Utf8Codec();

class Utf8Decoder extends Converter<List<int>, String> {
  const Utf8Decoder({this.reportErrors = true});

  static const _systemDecoder = cnv.Utf8Decoder(allowMalformed: true);

  final bool reportErrors;

  @override
  String convert(List<int> input, [int start = 0, int? end]) {
    final String result = _systemDecoder.convert(input, start, end);
    // Finding a Unicode replacement character indicates that the input
    // was malformed.
    if (reportErrors && result.contains('\u{FFFD}')) {
      throwToolExit(
        'Bad UTF-8 encoding (U+FFFD; REPLACEMENT CHARACTER) found while decoding string: $result. '
        'The Flutter team would greatly appreciate if you could file a bug explaining '
        'exactly what you were doing when this happened:\n'
        'https://github.com/flutter/flutter/issues/new/choose\n'
        'The source bytes were:\n$input\n\n',
      );
    }
    return result;
  }

  @override
  ByteConversionSink startChunkedConversion(Sink<String> sink) =>
      _systemDecoder.startChunkedConversion(sink);

  @override
  Stream<String> bind(Stream<List<int>> stream) => _systemDecoder.bind(stream);

  @override
  Converter<List<int>, T> fuse<T>(Converter<String, T> other) => _systemDecoder.fuse(other);
}
