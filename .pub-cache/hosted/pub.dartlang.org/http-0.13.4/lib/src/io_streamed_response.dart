// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'base_request.dart';
import 'streamed_response.dart';

/// An HTTP response where the response body is received asynchronously after
/// the headers have been received.
class IOStreamedResponse extends StreamedResponse {
  final HttpClientResponse? _inner;

  /// Creates a new streaming response.
  ///
  /// [stream] should be a single-subscription stream.
  ///
  /// If [inner] is not provided, [detachSocket] will throw.
  IOStreamedResponse(Stream<List<int>> stream, int statusCode,
      {int? contentLength,
      BaseRequest? request,
      Map<String, String> headers = const {},
      bool isRedirect = false,
      bool persistentConnection = true,
      String? reasonPhrase,
      HttpClientResponse? inner})
      : _inner = inner,
        super(stream, statusCode,
            contentLength: contentLength,
            request: request,
            headers: headers,
            isRedirect: isRedirect,
            persistentConnection: persistentConnection,
            reasonPhrase: reasonPhrase);

  /// Detaches the underlying socket from the HTTP server.
  ///
  /// Will throw if `inner` was not set or `null` when `this` was created.
  Future<Socket> detachSocket() async => _inner!.detachSocket();
}
