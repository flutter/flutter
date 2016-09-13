// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:http_parser/http_parser.dart';

import 'base_request.dart';
import 'byte_stream.dart';
import 'utils.dart';

/// An HTTP request where the entire request body is known in advance.
class Request extends BaseRequest {
  /// The size of the request body, in bytes. This is calculated from
  /// [bodyBytes].
  ///
  /// The content length cannot be set for [Request], since it's automatically
  /// calculated from [bodyBytes].
  int get contentLength => bodyBytes.length;

  set contentLength(int value) {
    throw new UnsupportedError("Cannot set the contentLength property of "
        "non-streaming Request objects.");
  }

  /// The default encoding to use when converting between [bodyBytes] and
  /// [body]. This is only used if [encoding] hasn't been manually set and if
  /// the content-type header has no encoding information.
  Encoding _defaultEncoding;

  /// The encoding used for the request. This encoding is used when converting
  /// between [bodyBytes] and [body].
  ///
  /// If the request has a `Content-Type` header and that header has a `charset`
  /// parameter, that parameter's value is used as the encoding. Otherwise, if
  /// [encoding] has been set manually, that encoding is used. If that hasn't
  /// been set either, this defaults to [UTF8].
  ///
  /// If the `charset` parameter's value is not a known [Encoding], reading this
  /// will throw a [FormatException].
  ///
  /// If the request has a `Content-Type` header, setting this will set the
  /// charset parameter on that header.
  Encoding get encoding {
    if (_contentType == null ||
        !_contentType.parameters.containsKey('charset')) {
      return _defaultEncoding;
    }
    return requiredEncodingForCharset(_contentType.parameters['charset']);
  }

  set encoding(Encoding value) {
    _checkFinalized();
    _defaultEncoding = value;
    var contentType = _contentType;
    if (contentType == null) return;
    _contentType = contentType.change(parameters: {'charset': value.name});
  }

  // TODO(nweiz): make this return a read-only view
  /// The bytes comprising the body of the request. This is converted to and
  /// from [body] using [encoding].
  ///
  /// This list should only be set, not be modified in place.
  Uint8List get bodyBytes => _bodyBytes;
  Uint8List _bodyBytes;

  set bodyBytes(List<int> value) {
    _checkFinalized();
    _bodyBytes = toUint8List(value);
  }

  /// The body of the request as a string. This is converted to and from
  /// [bodyBytes] using [encoding].
  ///
  /// When this is set, if the request does not yet have a `Content-Type`
  /// header, one will be added with the type `text/plain`. Then the `charset`
  /// parameter of the `Content-Type` header (whether new or pre-existing) will
  /// be set to [encoding] if it wasn't already set.
  String get body => encoding.decode(bodyBytes);

  set body(String value) {
    bodyBytes = encoding.encode(value);
    var contentType = _contentType;
    if (contentType == null) {
      _contentType = new MediaType("text", "plain", {'charset': encoding.name});
    } else if (!contentType.parameters.containsKey('charset')) {
      _contentType = contentType.change(parameters: {'charset': encoding.name});
    }
  }

  /// The form-encoded fields in the body of the request as a map from field
  /// names to values. The form-encoded body is converted to and from
  /// [bodyBytes] using [encoding] (in the same way as [body]).
  ///
  /// If the request doesn't have a `Content-Type` header of
  /// `application/x-www-form-urlencoded`, reading this will throw a
  /// [StateError].
  ///
  /// If the request has a `Content-Type` header with a type other than
  /// `application/x-www-form-urlencoded`, setting this will throw a
  /// [StateError]. Otherwise, the content type will be set to
  /// `application/x-www-form-urlencoded`.
  ///
  /// This map should only be set, not modified in place.
  Map<String, String> get bodyFields {
    var contentType = _contentType;
    if (contentType == null ||
        contentType.mimeType != "application/x-www-form-urlencoded") {
      throw new StateError('Cannot access the body fields of a Request without '
          'content-type "application/x-www-form-urlencoded".');
    }

    return Uri.splitQueryString(body, encoding: encoding);
  }

  set bodyFields(Map<String, String> fields) {
    var contentType = _contentType;
    if (contentType == null) {
      _contentType = new MediaType("application", "x-www-form-urlencoded");
    } else if (contentType.mimeType != "application/x-www-form-urlencoded") {
      throw new StateError('Cannot set the body fields of a Request with '
          'content-type "${contentType.mimeType}".');
    }

    this.body = mapToQuery(fields, encoding: encoding);
  }

  /// Creates a new HTTP request.
  Request(String method, Uri url)
    : _defaultEncoding = UTF8,
      _bodyBytes = new Uint8List(0),
      super(method, url);

  /// Freezes all mutable fields and returns a single-subscription [ByteStream]
  /// containing the request body.
  ByteStream finalize() {
    super.finalize();
    return new ByteStream.fromBytes(bodyBytes);
  }

  /// The `Content-Type` header of the request (if it exists) as a
  /// [MediaType].
  MediaType get _contentType {
    var contentType = headers['content-type'];
    if (contentType == null) return null;
    return new MediaType.parse(contentType);
  }

  set _contentType(MediaType value) {
    headers['content-type'] = value.toString();
  }

  /// Throw an error if this request has been finalized.
  void _checkFinalized() {
    if (!finalized) return;
    throw new StateError("Can't modify a finalized Request.");
  }
}
