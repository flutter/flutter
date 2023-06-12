// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'base_request.dart';
import 'base_response.dart';
import 'byte_stream.dart';
import 'utils.dart';

/// An HTTP response where the response body is received asynchronously after
/// the headers have been received.
class StreamedResponse extends BaseResponse {
  /// The stream from which the response body data can be read.
  ///
  /// This should always be a single-subscription stream.
  final ByteStream stream;

  /// Creates a new streaming response.
  ///
  /// [stream] should be a single-subscription stream.
  StreamedResponse(Stream<List<int>> stream, int statusCode,
      {int? contentLength,
      BaseRequest? request,
      Map<String, String> headers = const {},
      bool isRedirect = false,
      bool persistentConnection = true,
      String? reasonPhrase})
      : stream = toByteStream(stream),
        super(statusCode,
            contentLength: contentLength,
            request: request,
            headers: headers,
            isRedirect: isRedirect,
            persistentConnection: persistentConnection,
            reasonPhrase: reasonPhrase);
}
