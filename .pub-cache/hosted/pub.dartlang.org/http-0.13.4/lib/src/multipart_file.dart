// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:http_parser/http_parser.dart';

import 'byte_stream.dart';
import 'multipart_file_stub.dart' if (dart.library.io) 'multipart_file_io.dart';
import 'multipart_request.dart';
import 'utils.dart';

/// A file to be uploaded as part of a [MultipartRequest].
///
/// This doesn't need to correspond to a physical file.
class MultipartFile {
  /// The name of the form field for the file.
  final String field;

  /// The size of the file in bytes.
  ///
  /// This must be known in advance, even if this file is created from a
  /// [ByteStream].
  final int length;

  /// The basename of the file.
  ///
  /// May be `null`.
  final String? filename;

  /// The content-type of the file.
  ///
  /// Defaults to `application/octet-stream`.
  final MediaType contentType;

  /// The stream that will emit the file's contents.
  final ByteStream _stream;

  /// Whether [finalize] has been called.
  bool get isFinalized => _isFinalized;
  bool _isFinalized = false;

  /// Creates a new [MultipartFile] from a chunked [Stream] of bytes.
  ///
  /// The length of the file in bytes must be known in advance. If it's not,
  /// read the data from the stream and use [MultipartFile.fromBytes] instead.
  ///
  /// [contentType] currently defaults to `application/octet-stream`, but in the
  /// future may be inferred from [filename].
  MultipartFile(this.field, Stream<List<int>> stream, this.length,
      {this.filename, MediaType? contentType})
      : _stream = toByteStream(stream),
        contentType = contentType ?? MediaType('application', 'octet-stream');

  /// Creates a new [MultipartFile] from a byte array.
  ///
  /// [contentType] currently defaults to `application/octet-stream`, but in the
  /// future may be inferred from [filename].
  factory MultipartFile.fromBytes(String field, List<int> value,
      {String? filename, MediaType? contentType}) {
    var stream = ByteStream.fromBytes(value);
    return MultipartFile(field, stream, value.length,
        filename: filename, contentType: contentType);
  }

  /// Creates a new [MultipartFile] from a string.
  ///
  /// The encoding to use when translating [value] into bytes is taken from
  /// [contentType] if it has a charset set. Otherwise, it defaults to UTF-8.
  /// [contentType] currently defaults to `text/plain; charset=utf-8`, but in
  /// the future may be inferred from [filename].
  factory MultipartFile.fromString(String field, String value,
      {String? filename, MediaType? contentType}) {
    contentType ??= MediaType('text', 'plain');
    var encoding = encodingForCharset(contentType.parameters['charset'], utf8);
    contentType = contentType.change(parameters: {'charset': encoding.name});

    return MultipartFile.fromBytes(field, encoding.encode(value),
        filename: filename, contentType: contentType);
  }

  // TODO(nweiz): Infer the content-type from the filename.
  /// Creates a new [MultipartFile] from a path to a file on disk.
  ///
  /// [filename] defaults to the basename of [filePath]. [contentType] currently
  /// defaults to `application/octet-stream`, but in the future may be inferred
  /// from [filename].
  ///
  /// Throws an [UnsupportedError] if `dart:io` isn't supported in this
  /// environment.
  static Future<MultipartFile> fromPath(String field, String filePath,
          {String? filename, MediaType? contentType}) =>
      multipartFileFromPath(field, filePath,
          filename: filename, contentType: contentType);

  // Finalizes the file in preparation for it being sent as part of a
  // [MultipartRequest]. This returns a [ByteStream] that should emit the body
  // of the file. The stream may be closed to indicate an empty file.
  ByteStream finalize() {
    if (isFinalized) {
      throw StateError("Can't finalize a finalized MultipartFile.");
    }
    _isFinalized = true;
    return _stream;
  }
}
