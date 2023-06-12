// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:http_parser/http_parser.dart';

import 'message.dart';
import 'util.dart';

/// The response returned by a [Handler].
class Response extends Message {
  /// The HTTP status code of the response.
  final int statusCode;

  /// The date and time after which the response's data should be considered
  /// stale.
  ///
  /// This is parsed from the Expires header in [headers]. If [headers] doesn't
  /// have an Expires header, this will be `null`.
  DateTime? get expires {
    if (_expiresCache != null) return _expiresCache;
    if (!headers.containsKey('expires')) return null;
    _expiresCache = parseHttpDate(headers['expires']!);
    return _expiresCache;
  }

  DateTime? _expiresCache;

  /// The date and time the source of the response's data was last modified.
  ///
  /// This is parsed from the Last-Modified header in [headers]. If [headers]
  /// doesn't have a Last-Modified header, this will be `null`.
  DateTime? get lastModified {
    if (_lastModifiedCache != null) return _lastModifiedCache;
    if (!headers.containsKey('last-modified')) return null;
    _lastModifiedCache = parseHttpDate(headers['last-modified']!);
    return _lastModifiedCache;
  }

  DateTime? _lastModifiedCache;

  /// Constructs a 200 OK response.
  ///
  /// This indicates that the request has succeeded.
  ///
  /// {@template shelf_response_body_and_encoding_param}
  /// [body] is the response body. It may be either a [String], a [List<int>], a
  /// [Stream<List<int>>], or `null` to indicate no body.
  ///
  /// If the body is a [String], [encoding] is used to encode it to a
  /// [Stream<List<int>>]. It defaults to UTF-8. If it's a [String], a
  /// [List<int>], or `null`, the Content-Length header is set automatically
  /// unless a Transfer-Encoding header is set. Otherwise, it's a
  /// [Stream<List<int>>] and no Transfer-Encoding header is set, the adapter
  /// will set the Transfer-Encoding header to "chunked" and apply the chunked
  /// encoding to the body.
  ///
  /// If [encoding] is passed, the "encoding" field of the Content-Type header
  /// in [headers] will be set appropriately. If there is no existing
  /// Content-Type header, it will be set to "application/octet-stream".
  /// [headers] must contain values that are either `String` or `List<String>`.
  /// An empty list will cause the header to be omitted.
  /// {@endtemplate}
  Response.ok(
    Object? body, {
    Map<String, /* String | List<String> */ Object>? headers,
    Encoding? encoding,
    Map<String, Object>? context,
  }) : this(200,
            body: body, headers: headers, encoding: encoding, context: context);

  /// Constructs a 301 Moved Permanently response.
  ///
  /// This indicates that the requested resource has moved permanently to a new
  /// URI. [location] is that URI; it can be either a [String] or a [Uri]. It's
  /// automatically set as the Location header in [headers].
  ///
  /// {@macro shelf_response_body_and_encoding_param}
  Response.movedPermanently(
    Object location, {
    Object? body,
    Map<String, /* String | List<String> */ Object>? headers,
    Encoding? encoding,
    Map<String, Object>? context,
  }) : this._redirect(301, location, body, headers, encoding, context: context);

  /// Constructs a 302 Found response.
  ///
  /// This indicates that the requested resource has moved temporarily to a new
  /// URI. [location] is that URI; it can be either a [String] or a [Uri]. It's
  /// automatically set as the Location header in [headers].
  ///
  /// {@macro shelf_response_body_and_encoding_param}
  Response.found(
    Object location, {
    Object? body,
    Map<String, /* String | List<String> */ Object>? headers,
    Encoding? encoding,
    Map<String, Object>? context,
  }) : this._redirect(
          302,
          location,
          body,
          headers,
          encoding,
          context: context,
        );

  /// Constructs a 303 See Other response.
  ///
  /// This indicates that the response to the request should be retrieved using
  /// a GET request to a new URI. [location] is that URI; it can be either a
  /// [String] or a [Uri]. It's automatically set as the Location header in
  /// [headers].
  ///
  /// {@macro shelf_response_body_and_encoding_param}
  Response.seeOther(
    Object location, {
    Object? body,
    Map<String, /* String | List<String> */ Object>? headers,
    Encoding? encoding,
    Map<String, Object>? context,
  }) : this._redirect(303, location, body, headers, encoding, context: context);

  /// Constructs a helper constructor for redirect responses.
  Response._redirect(
    int statusCode,
    Object location,
    Object? body,
    Map<String, /* String | List<String> */ Object>? headers,
    Encoding? encoding, {
    Map<String, Object>? context,
  }) : this(
          statusCode,
          body: body,
          encoding: encoding,
          headers: addHeader(headers, 'location', _locationToString(location)),
          context: context,
        );

  /// Constructs a 304 Not Modified response.
  ///
  /// This is used to respond to a conditional GET request that provided
  /// information used to determine whether the requested resource has changed
  /// since the last request. It indicates that the resource has not changed and
  /// the old value should be used.
  ///
  /// [headers] must contain values that are either `String` or `List<String>`.
  /// An empty list will cause the header to be omitted.
  ///
  /// If [headers] contains a value for `content-length` it will be removed.
  Response.notModified({
    Map<String, /* String | List<String> */ Object>? headers,
    Map<String, Object>? context,
  }) : this(
          304,
          headers: removeHeader(
              addHeader(headers, 'date', formatHttpDate(DateTime.now())),
              'content-length'),
          context: context,
        );

  /// Constructs a 400 Bad Request response.
  ///
  /// This indicates that the server has received a malformed request.
  ///
  /// {@macro shelf_response_body_and_encoding_param}
  Response.badRequest({
    Object? body,
    Map<String, /* String | List<String> */ Object>? headers,
    Encoding? encoding,
    Map<String, Object>? context,
  }) : this(
          400,
          headers: body == null ? _adjustErrorHeaders(headers) : headers,
          body: body ?? 'Bad Request',
          context: context,
          encoding: encoding,
        );

  /// Constructs a 401 Unauthorized response.
  ///
  /// This indicates indicates that the client request has not been completed
  /// because it lacks valid authentication credentials.
  ///
  /// {@macro shelf_response_body_and_encoding_param}
  Response.unauthorized(
    Object? body, {
    Map<String, /* String | List<String> */ Object>? headers,
    Encoding? encoding,
    Map<String, Object>? context,
  }) : this(
          401,
          headers: body == null ? _adjustErrorHeaders(headers) : headers,
          body: body ?? 'Unauthorized',
          context: context,
          encoding: encoding,
        );

  /// Constructs a 403 Forbidden response.
  ///
  /// This indicates that the server is refusing to fulfill the request.
  ///
  /// {@macro shelf_response_body_and_encoding_param}
  Response.forbidden(
    Object? body, {
    Map<String, /* String | List<String> */ Object>? headers,
    Encoding? encoding,
    Map<String, Object>? context,
  }) : this(
          403,
          headers: body == null ? _adjustErrorHeaders(headers) : headers,
          body: body ?? 'Forbidden',
          context: context,
          encoding: encoding,
        );

  /// Constructs a 404 Not Found response.
  ///
  /// This indicates that the server didn't find any resource matching the
  /// requested URI.
  ///
  /// {@macro shelf_response_body_and_encoding_param}
  Response.notFound(
    Object? body, {
    Map<String, /* String | List<String> */ Object>? headers,
    Encoding? encoding,
    Map<String, Object>? context,
  }) : this(
          404,
          headers: body == null ? _adjustErrorHeaders(headers) : headers,
          body: body ?? 'Not Found',
          context: context,
          encoding: encoding,
        );

  /// Constructs a 500 Internal Server Error response.
  ///
  /// This indicates that the server had an internal error that prevented it
  /// from fulfilling the request.
  ///
  /// {@macro shelf_response_body_and_encoding_param}
  Response.internalServerError({
    Object? body,
    Map<String, /* String | List<String> */ Object>? headers,
    Encoding? encoding,
    Map<String, Object>? context,
  }) : this(
          500,
          headers: body == null ? _adjustErrorHeaders(headers) : headers,
          body: body ?? 'Internal Server Error',
          context: context,
          encoding: encoding,
        );

  /// Constructs an HTTP response with the given [statusCode].
  ///
  /// [statusCode] must be greater than or equal to 100.
  ///
  /// {@macro shelf_response_body_and_encoding_param}
  Response(
    this.statusCode, {
    Object? body,
    Map<String, /* String | List<String> */ Object>? headers,
    Encoding? encoding,
    Map<String, Object>? context,
  }) : super(body, encoding: encoding, headers: headers, context: context) {
    if (statusCode < 100) {
      throw ArgumentError('Invalid status code: $statusCode.');
    }
  }

  /// Creates a new [Response] by copying existing values and applying specified
  /// changes.
  ///
  /// New key-value pairs in [context] and [headers] will be added to the copied
  /// [Response].
  ///
  /// If [context] or [headers] includes a key that already exists, the
  /// key-value pair will replace the corresponding entry in the copied
  /// [Response]. If [context] or [headers] contains a `null` value the
  /// corresponding `key` will be removed if it exists, otherwise the `null`
  /// value will be ignored.
  /// For [headers] a value which is an empty list will also cause the
  /// corresponding key to be removed.
  ///
  /// All other context and header values from the [Response] will be included
  /// in the copied [Response] unchanged.
  ///
  /// [body] is the response body. It may be either a [String], a [List<int>], a
  /// [Stream<List<int>>], or `<int>[]` (empty list) to indicate no body.
  @override
  Response change({
    Map<String, /* String | List<String> */ Object?>? headers,
    Map<String, Object?>? context,
    Object? body,
  }) {
    final headersAll = updateHeaders(this.headersAll, headers);
    final newContext = updateMap(this.context, context);

    body ??= extractBody(this);

    return Response(
      statusCode,
      body: body,
      headers: headersAll,
      context: newContext,
    );
  }
}

/// Adds content-type information to [headers].
///
/// Returns a new map without modifying [headers]. This is used to add
/// content-type information when creating a 500 response with a default body.
Map<String, Object> _adjustErrorHeaders(
    Map<String, /* String | List<String> */ Object>? headers) {
  if (headers == null || headers['content-type'] == null) {
    return addHeader(headers, 'content-type', 'text/plain');
  }

  final contentTypeValue =
      expandHeaderValue(headers['content-type']!).join(',');
  var contentType =
      MediaType.parse(contentTypeValue).change(mimeType: 'text/plain');
  return addHeader(headers, 'content-type', contentType.toString());
}

/// Converts [location], which may be a [String] or a [Uri], to a [String].
///
/// Throws an [ArgumentError] if [location] isn't a [String] or a [Uri].
String _locationToString(Object location) {
  if (location is String) return location;
  if (location is Uri) return location.toString();

  throw ArgumentError(
    'Response location must be a String or Uri, was "$location".',
  );
}
