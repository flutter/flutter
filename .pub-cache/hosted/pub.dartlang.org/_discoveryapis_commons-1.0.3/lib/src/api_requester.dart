// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'multipart_media_uploader.dart';
import 'request_impl.dart';
import 'requests.dart' as client_requests;
import 'resumable_media_uploader.dart';
import 'utils.dart';

/// Base class for all API clients, offering generic methods for
/// HTTP Requests to the API
class ApiRequester {
  final http.Client _httpClient;
  final String _rootUrl;
  final String _basePath;
  final Map<String, String> _requestHeaders;

  ApiRequester(
    this._httpClient,
    this._rootUrl,
    this._basePath,
    this._requestHeaders,
  ) : assert(_rootUrl.endsWith('/'));

  /// Sends a HTTPRequest using [method] (usually GET or POST) to [requestUrl]
  /// using the specified [queryParams]. Optionally include a
  /// [body] and/or [uploadMedia] in the request.
  ///
  /// If [uploadMedia] was specified [downloadOptions] must be
  /// [client_requests.DownloadOptions.Metadata] or `null`.
  ///
  /// If [downloadOptions] is [client_requests.DownloadOptions.Metadata] the
  /// result will be decoded as JSON.
  ///
  /// If [downloadOptions] is `null` the result will be a Future completing with
  /// `null`.
  ///
  /// Otherwise the result will be downloaded as a [client_requests.Media]
  Future request(
    String requestUrl,
    String method, {
    String? body,
    Map<String, List<String>>? queryParams,
    client_requests.Media? uploadMedia,
    client_requests.UploadOptions? uploadOptions,
    client_requests.DownloadOptions? downloadOptions =
        client_requests.DownloadOptions.metadata,
  }) async {
    if (uploadMedia != null &&
        downloadOptions != client_requests.DownloadOptions.metadata) {
      throw ArgumentError(
        'When uploading a [Media] you cannot download a '
        '[Media] at the same time!',
      );
    }
    client_requests.ByteRange? downloadRange;
    if (downloadOptions is client_requests.PartialDownloadOptions &&
        !downloadOptions.isFullDownload) {
      downloadRange = downloadOptions.range;
    }
    queryParams = queryParams?.cast<String, List<String>>();

    var response = await _request(requestUrl, method, body, queryParams,
        uploadMedia, uploadOptions, downloadOptions, downloadRange);

    response = await validateResponse(response);

    if (downloadOptions == null) {
      // If no download options are given, the response is of no interest
      // and we will drain the stream.
      return response.stream.drain();
    } else if (downloadOptions == client_requests.DownloadOptions.metadata) {
      // Downloading JSON Metadata
      final stringStream = _decodeStreamAsText(response);
      if (stringStream == null) {
        throw client_requests.ApiRequestError(
          'Unable to read response with content-type '
          "${response.headers['content-type']}.",
        );
      }

      final bodyString = await stringStream.join();
      if (bodyString.isEmpty) return null;
      return json.decode(bodyString);
    }

    // Downloading Media.
    final contentType = response.headers['content-type'];
    if (contentType == null) {
      throw client_requests.ApiRequestError(
          "No 'content-type' header in media response.");
    }

    int? contentLength;
    if (response.headers['content-length'] != null) {
      contentLength = int.tryParse(response.headers['content-length']!);
    }

    if (downloadRange != null) {
      if (contentLength != downloadRange.length) {
        throw client_requests.ApiRequestError(
          'Content length of response does not match requested range length.',
        );
      }
      final contentRange = response.headers['content-range'];
      final expected = 'bytes ${downloadRange.start}-${downloadRange.end}/';
      if (contentRange == null || !contentRange.startsWith(expected)) {
        throw client_requests.ApiRequestError(
          'Attempting partial '
          "download but got invalid 'Content-Range' header "
          '(was: $contentRange, expected: $expected).',
        );
      }
    }

    return client_requests.Media(response.stream, contentLength,
        contentType: contentType);
  }

  Future<http.StreamedResponse> _request(
    String requestUrl,
    String method,
    String? body,
    Map<String, List<String>>? queryParams,
    client_requests.Media? uploadMedia,
    client_requests.UploadOptions? uploadOptions,
    client_requests.DownloadOptions? downloadOptions,
    client_requests.ByteRange? downloadRange,
  ) {
    final downloadAsMedia = downloadOptions != null &&
        downloadOptions != client_requests.DownloadOptions.metadata;

    queryParams ??= {};

    if (uploadMedia != null) {
      if (uploadOptions is client_requests.ResumableUploadOptions) {
        queryParams['uploadType'] = const ['resumable'];
      } else if (body == null) {
        queryParams['uploadType'] = const ['media'];
      } else {
        queryParams['uploadType'] = const ['multipart'];
      }
    }

    if (downloadAsMedia) {
      queryParams['alt'] = const ['media'];
    } else if (downloadOptions != null) {
      queryParams['alt'] = const ['json'];
    }

    String path;
    if (requestUrl.startsWith('/')) {
      path = '$_rootUrl${requestUrl.substring(1)}';
    } else {
      path = '$_rootUrl$_basePath$requestUrl';
    }

    var containsQueryParameter = path.contains('?');
    void addQueryParameter(String name, String value) {
      name = escapeVariable(name);
      value = escapeVariable(value);
      if (containsQueryParameter) {
        path = '$path&$name=$value';
      } else {
        path = '$path?$name=$value';
      }
      containsQueryParameter = true;
    }

    queryParams.forEach((String key, List<String> values) {
      for (var value in values) {
        addQueryParameter(key, value);
      }
    });

    final uri = Uri.parse(path);

    Future<http.StreamedResponse> simpleUpload() {
      final bodyStream = uploadMedia!.stream;
      final request = RequestImpl(method, uri, bodyStream);
      request.headers.addAll({
        ..._requestHeaders,
        'content-type': uploadMedia.contentType,
        'content-length': '${uploadMedia.length}'
      });
      return _httpClient.send(request);
    }

    Future<http.StreamedResponse> simpleRequest() {
      var length = 0;
      final bodyController = StreamController<List<int>>();
      if (body != null) {
        final bytes = utf8.encode(body);
        bodyController.add(bytes);
        length = bytes.length;
      }
      bodyController.close();

      final headers = {
        ..._requestHeaders,
        'content-type': contentTypeJsonUtf8,
        'content-length': '$length',
        if (downloadRange != null)
          'range': 'bytes=${downloadRange.start}-${downloadRange.end}',
      };

      // Filter out headers forbidden in the browser (in calling in browser).
      // If we don't do this, the browser will complain that we're attempting
      // to set a header that we're not allowed to set.
      headers.removeWhere((key, value) => _forbiddenHeaders.contains(key));

      final request = RequestImpl(method, uri, bodyController.stream);
      request.headers.addAll(headers);
      return _httpClient.send(request);
    }

    if (uploadMedia != null) {
      // Three upload types:
      // 1. Resumable: Upload of data + metadata with multiple requests.
      // 2. Simple: Upload of media.
      // 3. Multipart: Upload of data + metadata.

      if (uploadOptions is client_requests.ResumableUploadOptions) {
        final helper = ResumableMediaUploader(
          _httpClient,
          uploadMedia,
          body,
          uri,
          method,
          uploadOptions,
          _requestHeaders,
        );
        return helper.upload();
      }

      if (uploadMedia.length == null) {
        throw ArgumentError(
          'For non-resumable uploads you need to specify the length of the '
          'media to upload.',
        );
      }

      if (body == null) {
        return simpleUpload();
      } else {
        final uploader = MultipartMediaUploader(
          _httpClient,
          uploadMedia,
          body,
          uri,
          method,
          _requestHeaders,
        );
        return uploader.upload();
      }
    }
    return simpleRequest();
  }
}

Future<http.StreamedResponse> validateResponse(
  http.StreamedResponse response,
) async {
  final statusCode = response.statusCode;

  // TODO: We assume that status codes between [200..400] are OK.
  // Can we assume this?
  if (statusCode < 200 || statusCode >= 400) {
    // Some error happened, try to decode the response and fetch the error.
    final stringStream = _decodeStreamAsText(response);
    if (stringStream != null) {
      var jsonResponse = await stringStream.transform(json.decoder).first;
      if (jsonResponse is List && jsonResponse.length == 1) {
        jsonResponse = jsonResponse.first;
      }

      if (jsonResponse is Map && jsonResponse['error'] is Map) {
        final error = jsonResponse['error'] as Map;
        final codeValue = error['code'];
        final message = error['message'] as String?;

        final code =
            codeValue is String ? int.tryParse(codeValue) : codeValue as int?;

        var errors = <client_requests.ApiRequestErrorDetail>[];
        if (error.containsKey('errors') && error['errors'] is List) {
          errors = (error['errors'] as List)
              .map((e) =>
                  client_requests.ApiRequestErrorDetail.fromJson(e as Map))
              .toList();
        }
        throw client_requests.DetailedApiRequestError(code, message,
            errors: errors, jsonResponse: jsonResponse as Map<String, dynamic>);
      }
    }
    throw client_requests.DetailedApiRequestError(
        statusCode, 'No error details. HTTP status was: $statusCode.');
  }

  return response;
}

Stream<String>? _decodeStreamAsText(http.StreamedResponse response) {
  // TODO: Correctly handle the response content-types, using correct
  // decoder.
  // Currently we assume that the api endpoint is responding with json
  // encoded in UTF8.
  if (isJson(response.headers['content-type'])) {
    return response.stream.transform(const Utf8Decoder(allowMalformed: true));
  } else {
    return null;
  }
}

/// List of headers that is forbidden in current execution context.
///
/// In a browser context we're not allowed to set `user-agent` and
/// `content-length` headers.
const _forbiddenHeaders = bool.fromEnvironment('dart.library.html')
    ? <String>{'user-agent', 'content-length'}
    : <String>{};
