// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart' show BaseRequest, Client, StreamedResponse;
import 'package:http_parser/http_parser.dart';

import 'access_token.dart';
import 'exceptions.dart';
import 'http_client_base.dart';
import 'known_uris.dart';

/// Due to differences of clock speed, network latency, etc. we
/// will shorten expiry dates by 20 seconds.
const maxExpectedTimeDiffInSeconds = 20;

AccessToken parseAccessToken(Map<String, dynamic> jsonMap) {
  final tokenType = jsonMap['token_type'];
  final accessToken = jsonMap['access_token'];
  final expiresIn = jsonMap['expires_in'];

  if (accessToken is! String || expiresIn is! int || tokenType != 'Bearer') {
    throw ServerRequestFailedException(
      'Failed to exchange authorization code. Invalid server response.',
      responseContent: jsonMap,
    );
  }

  return AccessToken('Bearer', accessToken, expiryDate(expiresIn));
}

/// Constructs a [DateTime] which is [seconds] seconds from now with
/// an offset of [maxExpectedTimeDiffInSeconds]. Result is UTC time.
DateTime expiryDate(int seconds) => DateTime.now()
    .toUtc()
    .add(Duration(seconds: seconds - maxExpectedTimeDiffInSeconds));

/// Constant for the 'application/x-www-form-urlencoded' content type
const _contentTypeUrlEncoded =
    'application/x-www-form-urlencoded; charset=utf-8';

Future<Map<String, dynamic>> _readJsonMapFromResponse(
  StreamedResponse response,
) async {
  await _expectJsonResponse(response);

  Object? jsonValue;

  final bytes = await response.stream.toBytes();

  late String string;
  try {
    string = utf8.decode(bytes);
  } on FormatException catch (e) {
    throw ServerRequestFailedException(
      'The response was not valid UTF-8. '
      '$e',
      statusCode: response.statusCode,
      responseContent: bytes,
    );
  }

  try {
    jsonValue = jsonDecode(string);
  } on FormatException catch (e) {
    throw ServerRequestFailedException(
      'Could not decode the response as JSON. '
      '$e',
      statusCode: response.statusCode,
      responseContent: string,
    );
  }

  if (jsonValue is! Map<String, dynamic>) {
    throw ServerRequestFailedException(
      'The returned JSON response was not a Map.',
      statusCode: response.statusCode,
      responseContent: jsonValue,
    );
  }

  return jsonValue;
}

extension ClientExtensions on Client {
  Future<Map<String, dynamic>> requestJson(
    BaseRequest request,
    String errorHeader,
  ) async {
    final response = await send(request);
    final jsonMap = await _readJsonMapFromResponse(response);

    if (response.statusCode != 200) {
      final error = _errorStringFromJsonResponse(jsonMap);
      final message = [
        errorHeader,
        if (error != null) error,
      ].join(' ');
      throw ServerRequestFailedException(
        message,
        statusCode: response.statusCode,
        responseContent: jsonMap,
      );
    }

    return jsonMap;
  }

  Future<Map<String, dynamic>> oauthTokenRequest(
    Map<String, String> postValues,
  ) async {
    final body = Stream<List<int>>.value(
      ascii.encode(
        postValues.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&'),
      ),
    );
    final request = RequestImpl('POST', googleOauth2TokenEndpoint, body)
      ..headers['content-type'] = _contentTypeUrlEncoded;

    return requestJson(request, 'Failed to obtain access credentials.');
  }
}

/// Returns an error string for [json] if it contains error data in keys
/// `error` and `error_description`.
///
/// Otherwise, returns `null`.
String? _errorStringFromJsonResponse(Map<String, dynamic> json) {
  final error = json['error'];
  final values = [
    if (error != null) 'Error: $error',
    json['error_description'],
  ].where((element) => element != null).join(' ');
  if (values.isEmpty) return null;
  return values;
}

Future<void> _expectJsonResponse(StreamedResponse response) async {
  final contentType = response.headers['content-type'];

  if (!_isJson(contentType)) {
    String? body;
    try {
      body = await response.stream.bytesToString();
    } catch (_) {
      /// We're already going to throw below
    }

    final message = contentType == null
        ? 'Server responded without a content type header.'
        : 'Server responded with invalid content type: $contentType. ';

    throw ServerRequestFailedException(
      '$message Expected a JSON response.',
      statusCode: response.statusCode,
      responseContent: body,
    );
  }
}

/// Follows https://mimesniff.spec.whatwg.org/#json-mime-type
bool _isJson(String? contentType) {
  if (contentType == null) return false;
  final mediaType = MediaType.parse(contentType);
  if (mediaType.mimeType == 'application/json') return true;
  if (mediaType.mimeType == 'text/json') return true;
  return mediaType.subtype.endsWith('+json');
}
