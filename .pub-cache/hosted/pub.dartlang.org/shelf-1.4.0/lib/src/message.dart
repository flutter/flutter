// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:http_parser/http_parser.dart';

import 'body.dart';
import 'headers.dart';
import 'shelf_unmodifiable_map.dart';
import 'util.dart';

Body extractBody(Message message) => message._body;

/// The default set of headers for a message created with no body and no
/// explicit headers.
final _defaultHeaders = Headers.from({
  'content-length': ['0'],
});

/// Represents logic shared between [Request] and [Response].
abstract class Message {
  final Headers _headers;

  /// The HTTP headers with case-insensitive keys.
  ///
  /// If a header occurs more than once in the query string, they are mapped to
  /// by concatenating them with a comma.
  ///
  /// The returned map is unmodifiable.
  Map<String, String> get headers => _headers.singleValues;

  /// The HTTP headers with multiple values with case-insensitive keys.
  ///
  /// If a header occurs only once, its value is a singleton list.
  /// If a header occurs with no value, the empty string is used as the value
  /// for that occurrence.
  ///
  /// The returned map and the lists it contains are unmodifiable.
  Map<String, List<String>> get headersAll => _headers;

  /// Extra context that can be used by for middleware and handlers.
  ///
  /// For requests, this is used to pass data to inner middleware and handlers;
  /// for responses, it's used to pass data to outer middleware and handlers.
  ///
  /// Context properties that are used by a particular package should begin with
  /// that package's name followed by a period. For example, if [logRequests]
  /// wanted to take a prefix, its property name would be `"shelf.prefix"`,
  /// since it's in the `shelf` package.
  ///
  /// The value is immutable.
  final Map<String, Object> context;

  /// The streaming body of the message.
  ///
  /// This can be read via [read] or [readAsString].
  final Body _body;

  /// If `true`, the stream returned by [read] won't emit any bytes.
  ///
  /// This may have false negatives, but it won't have false positives.
  bool get isEmpty => _body.contentLength == 0;

  /// Creates a new [Message].
  ///
  /// [body] is the response body. It may be either a [String], a [List<int>], a
  /// [Stream<List<int>>], or `null` to indicate no body. If it's a [String],
  /// [encoding] is used to encode it to a [Stream<List<int>>]. It defaults to
  /// UTF-8.
  ///
  /// If [headers] is `null`, it is treated as empty.
  ///
  /// If [encoding] is passed, the "encoding" field of the Content-Type header
  /// in [headers] will be set appropriately. If there is no existing
  /// Content-Type header, it will be set to "application/octet-stream".
  Message(
    Object? body, {
    Encoding? encoding,
    Map<String, /* String | List<String> */ Object>? headers,
    Map<String, Object>? context,
  }) : this._withBody(Body(body, encoding), headers, context);

  Message._withBody(
      Body body, Map<String, Object>? headers, Map<String, Object>? context)
      : this._withHeadersAll(
          body,
          Headers.from(_adjustHeaders(expandToHeadersAll(headers), body)),
          context,
        );

  Message._withHeadersAll(
      Body body, Headers headers, Map<String, Object>? context)
      : _body = body,
        _headers = headers,
        context = ShelfUnmodifiableMap(context, ignoreKeyCase: false);

  /// The contents of the content-length field in [headers].
  ///
  /// If not set, `null`.
  int? get contentLength {
    if (_contentLengthCache != null) return _contentLengthCache;
    if (!headers.containsKey('content-length')) return null;
    _contentLengthCache = int.parse(headers['content-length']!);
    return _contentLengthCache;
  }

  int? _contentLengthCache;

  /// The MIME type of the message.
  ///
  /// This is parsed from the Content-Type header in [headers]. It contains only
  /// the MIME type, without any Content-Type parameters.
  ///
  /// If [headers] doesn't have a Content-Type header, this will be `null`.
  String? get mimeType {
    var contentType = _contentType;
    if (contentType == null) return null;
    return contentType.mimeType;
  }

  /// The encoding of the message body.
  ///
  /// This is parsed from the "charset" parameter of the Content-Type header in
  /// [headers].
  ///
  /// If [headers] doesn't have a Content-Type header or it specifies an
  /// encoding that `dart:convert` doesn't support, this will be `null`.
  Encoding? get encoding {
    var contentType = _contentType;
    if (contentType == null) return null;
    if (!contentType.parameters.containsKey('charset')) return null;
    return Encoding.getByName(contentType.parameters['charset']);
  }

  /// The parsed version of the Content-Type header in [headers].
  ///
  /// This is cached for efficient access.
  MediaType? get _contentType {
    if (_contentTypeCache != null) return _contentTypeCache;
    final contentTypeValue = headers['content-type'];
    if (contentTypeValue == null) return null;
    return _contentTypeCache = MediaType.parse(contentTypeValue);
  }

  MediaType? _contentTypeCache;

  /// Returns a [Stream] representing the body.
  ///
  /// Can only be called once.
  Stream<List<int>> read() => _body.read();

  /// Returns a [Future] containing the body as a String.
  ///
  /// If [encoding] is passed, that's used to decode the body.
  /// Otherwise the encoding is taken from the Content-Type header. If that
  /// doesn't exist or doesn't have a "charset" parameter, UTF-8 is used.
  ///
  /// This calls [read] internally, which can only be called once.
  Future<String> readAsString([Encoding? encoding]) {
    encoding ??= this.encoding ?? utf8;
    return encoding.decodeStream(read());
  }

  /// Creates a new [Message] by copying existing values and applying specified
  /// changes.
  Message change(
      {Map<String, String> headers, Map<String, Object> context, Object? body});
}

/// Adds information about [encoding] to [headers].
///
/// Returns a new map without modifying [headers].
Map<String, List<String>> _adjustHeaders(
  Map<String, List<String>>? headers,
  Body body,
) {
  var sameEncoding = _sameEncoding(headers, body);
  if (sameEncoding) {
    if (body.contentLength == null ||
        findHeader(headers, 'content-length') == '${body.contentLength}') {
      return headers ?? Headers.empty();
    } else if (body.contentLength == 0 &&
        (headers == null || headers.isEmpty)) {
      return _defaultHeaders;
    }
  }

  var newHeaders = headers == null
      ? CaseInsensitiveMap<List<String>>()
      : CaseInsensitiveMap<List<String>>.from(headers);

  if (!sameEncoding) {
    if (newHeaders['content-type'] == null) {
      newHeaders['content-type'] = [
        'application/octet-stream; charset=${body.encoding!.name}'
      ];
    } else {
      final contentType =
          MediaType.parse(joinHeaderValues(newHeaders['content-type'])!)
              .change(parameters: {'charset': body.encoding!.name});
      newHeaders['content-type'] = [contentType.toString()];
    }
  }

  final explicitOverrideOfZeroLength =
      body.contentLength == 0 && findHeader(headers, 'content-length') != null;

  if (body.contentLength != null && !explicitOverrideOfZeroLength) {
    final coding = joinHeaderValues(newHeaders['transfer-encoding']);
    if (coding == null || equalsIgnoreAsciiCase(coding, 'identity')) {
      newHeaders['content-length'] = [body.contentLength.toString()];
    }
  }

  return newHeaders;
}

/// Returns whether [headers] declares the same encoding as [body].
bool _sameEncoding(Map<String, List<String>?>? headers, Body body) {
  if (body.encoding == null) return true;

  var contentType = findHeader(headers, 'content-type');
  if (contentType == null) return false;

  var charset = MediaType.parse(contentType).parameters['charset'];
  return Encoding.getByName(charset) == body.encoding;
}
