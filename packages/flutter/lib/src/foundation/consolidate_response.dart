// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import '_consolidate_response_io.dart'
  if (dart.library.html) '_consolidate_response_web.dart' as consolidate_reponse;

/// Signature for getting notified when chunks of bytes are received while
/// consolidating the bytes of an [HttpClientResponse] into a [Uint8List].
///
/// The `cumulative` parameter will contain the total number of bytes received
/// thus far. If the response has been gzipped, this number will be the number
/// of compressed bytes that have been received _across the wire_.
///
/// The `total` parameter will contain the _expected_ total number of bytes to
/// be received across the wire (extracted from the value of the
/// `Content-Length` HTTP response header), or null if the size of the response
/// body is not known in advance (this is common for HTTP chunked transfer
/// encoding, which itself is common when a large amount of data is being
/// returned to the client and the total size of the response may not be known
/// until the request has been fully processed).
///
/// This is used in [consolidateHttpClientResponseBytes].
typedef BytesReceivedCallback = void Function(int cumulative, int total);

/// Efficiently converts the response body of an [HttpClientResponse] into a
/// [Uint8List].
///
/// [response] must be of type [HttpClientResponse] from `dart:io`.
/// This function is not supported on Flutter for web applications.
///
/// The future returned will forward any error emitted by `response`.
///
///
/// The `onBytesReceived` callback, if specified, will be invoked for every
/// chunk of bytes that is received while consolidating the response bytes.
/// If the callback throws an error, processing of the response will halt, and
/// the returned future will complete with the error that was thrown by the
/// callback. For more information on how to interpret the parameters to the
/// callback, see the documentation on [BytesReceivedCallback].
///
/// If the `response` is gzipped and the `autoUncompress` parameter is true,
/// this will automatically un-compress the bytes in the returned list if it
/// hasn't already been done via [HttpClient.autoUncompress]. To get compressed
/// bytes from this method (assuming the response is sending compressed bytes),
/// set both [HttpClient.autoUncompress] to false and the `autoUncompress`
/// parameter to false.
Future<Uint8List> consolidateHttpClientResponseBytes(
  Object response, {
  bool autoUncompress = true,
  BytesReceivedCallback onBytesReceived,
}) => consolidate_reponse.consolidateHttpClientResponseBytes(
  response,
  autoUncompress: true,
  onBytesReceived: onBytesReceived,
);
