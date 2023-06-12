// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A Shelf adapter for handling [HttpRequest] objects from `dart:io`'s
/// [HttpServer].
///
/// One can provide an instance of [HttpServer] as the `requests` parameter in
/// [serveRequests].
///
/// This adapter supports request hijacking; see [Request.hijack].
///
/// [Request]s passed to a [Handler] will contain the [Request.context] key
/// `"shelf.io.connection_info"` containing the [HttpConnectionInfo] object from
/// the underlying [HttpRequest].
///
/// When creating [Response] instances for this adapter, you can set the
/// `"shelf.io.buffer_output"` key in [Response.context]. If `true`,
/// (the default), streamed responses will be buffered to improve performance.
/// If `false`, all chunks will be pushed over the wire as they're received.
/// See [HttpResponse.bufferOutput] for more information.
import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http_parser/http_parser.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:stream_channel/stream_channel.dart';

import 'shelf.dart';
import 'src/util.dart';

export 'src/io_server.dart' show IOServer;

/// Starts an [HttpServer] that listens on the specified [address] and
/// [port] and sends requests to [handler].
///
/// If a [securityContext] is provided an HTTPS server will be started.
///
/// See the documentation for [HttpServer.bind] and [HttpServer.bindSecure]
/// for more details on [address], [port], [backlog], and [shared].
///
/// {@template shelf_io_header_defaults}
/// Every response will get a "date" header and an "X-Powered-By" header.
/// If the either header is present in the `Response`, it will not be
/// overwritten.
/// Pass [poweredByHeader] to set the default content for "X-Powered-By",
/// pass `null` to omit this header.
/// {@endtemplate}
Future<HttpServer> serve(
  Handler handler,
  Object address,
  int port, {
  SecurityContext? securityContext,
  int? backlog,
  bool shared = false,
  String? poweredByHeader = 'Dart with package:shelf',
}) async {
  backlog ??= 0;
  var server = await (securityContext == null
      ? HttpServer.bind(address, port, backlog: backlog, shared: shared)
      : HttpServer.bindSecure(
          address,
          port,
          securityContext,
          backlog: backlog,
          shared: shared,
        ));
  serveRequests(server, handler, poweredByHeader: poweredByHeader);
  return server;
}

/// Serve a [Stream] of [HttpRequest]s.
///
/// [HttpServer] implements [Stream<HttpRequest>] so it can be passed directly
/// to [serveRequests].
///
/// Errors thrown by [handler] while serving a request will be printed to the
/// console and cause a 500 response with no body. Errors thrown asynchronously
/// by [handler] will be printed to the console or, if there's an active error
/// zone, passed to that zone.
///
/// {@macro shelf_io_header_defaults}
void serveRequests(
  Stream<HttpRequest> requests,
  Handler handler, {
  String? poweredByHeader = 'Dart with package:shelf',
}) {
  catchTopLevelErrors(() {
    requests.listen((request) =>
        handleRequest(request, handler, poweredByHeader: poweredByHeader));
  }, (error, stackTrace) {
    _logTopLevelError('Asynchronous error\n$error', stackTrace);
  });
}

/// Uses [handler] to handle [request].
///
/// Returns a [Future] which completes when the request has been handled.
///
/// {@macro shelf_io_header_defaults}
Future<void> handleRequest(
  HttpRequest request,
  Handler handler, {
  String? poweredByHeader = 'Dart with package:shelf',
}) async {
  Request shelfRequest;
  try {
    shelfRequest = _fromHttpRequest(request);
  } on ArgumentError catch (error, stackTrace) {
    if (error.name == 'method' || error.name == 'requestedUri') {
      // TODO: use a reduced log level when using package:logging
      _logTopLevelError('Error parsing request.\n$error', stackTrace);
      final response = Response(
        400,
        body: 'Bad Request',
        headers: {HttpHeaders.contentTypeHeader: 'text/plain'},
      );
      await _writeResponse(response, request.response, poweredByHeader);
    } else {
      _logTopLevelError('Error parsing request.\n$error', stackTrace);
      final response = Response.internalServerError();
      await _writeResponse(response, request.response, poweredByHeader);
    }
    return;
  } catch (error, stackTrace) {
    _logTopLevelError('Error parsing request.\n$error', stackTrace);
    final response = Response.internalServerError();
    await _writeResponse(response, request.response, poweredByHeader);
    return;
  }

  // TODO(nweiz): abstract out hijack handling to make it easier to implement an
  // adapter.
  Response? response;
  try {
    response = await handler(shelfRequest);
  } on HijackException catch (error, stackTrace) {
    // A HijackException should bypass the response-writing logic entirely.
    if (!shelfRequest.canHijack) return;

    // If the request wasn't hijacked, we shouldn't be seeing this exception.
    response = _logError(
      shelfRequest,
      "Caught HijackException, but the request wasn't hijacked.",
      stackTrace,
    );
  } catch (error, stackTrace) {
    response = _logError(
      shelfRequest,
      'Error thrown by handler.\n$error',
      stackTrace,
    );
  }

  if ((response as dynamic) == null) {
    // Handle nulls flowing from opt-out code
    await _writeResponse(
        _logError(
            shelfRequest, 'null response from handler.', StackTrace.current),
        request.response,
        poweredByHeader);
    return;
  }
  if (shelfRequest.canHijack) {
    await _writeResponse(response, request.response, poweredByHeader);
    return;
  }

  var message = StringBuffer()
    ..writeln('Got a response for hijacked request '
        '${shelfRequest.method} ${shelfRequest.requestedUri}:')
    ..writeln(response.statusCode);
  response.headers.forEach((key, value) => message.writeln('$key: $value'));
  throw Exception(message.toString().trim());
}

/// Creates a new [Request] from the provided [HttpRequest].
Request _fromHttpRequest(HttpRequest request) {
  var headers = <String, List<String>>{};
  request.headers.forEach((k, v) {
    headers[k] = v;
  });

  // Remove the Transfer-Encoding header per the adapter requirements.
  headers.remove(HttpHeaders.transferEncodingHeader);

  void onHijack(void Function(StreamChannel<List<int>>) callback) {
    request.response
        .detachSocket(writeHeaders: false)
        .then((socket) => callback(StreamChannel(socket, socket)));
  }

  return Request(
    request.method,
    request.requestedUri,
    protocolVersion: request.protocolVersion,
    headers: headers,
    body: request,
    onHijack: onHijack,
    context: {'shelf.io.connection_info': request.connectionInfo!},
  );
}

Future<void> _writeResponse(
    Response response, HttpResponse httpResponse, String? poweredByHeader) {
  if (response.context.containsKey('shelf.io.buffer_output')) {
    httpResponse.bufferOutput =
        response.context['shelf.io.buffer_output'] as bool;
  }

  httpResponse.statusCode = response.statusCode;

  // An adapter must not add or modify the `Transfer-Encoding` parameter, but
  // the Dart SDK sets it by default. Set this before we fill in
  // [response.headers] so that the user or Shelf can explicitly override it if
  // necessary.
  httpResponse.headers.chunkedTransferEncoding = false;

  response.headersAll.forEach((header, value) {
    httpResponse.headers.set(header, value);
  });

  var coding = response.headers['transfer-encoding'];
  if (coding != null && !equalsIgnoreAsciiCase(coding, 'identity')) {
    // If the response is already in a chunked encoding, de-chunk it because
    // otherwise `dart:io` will try to add another layer of chunking.
    //
    // TODO(nweiz): Do this more cleanly when sdk#27886 is fixed.
    response = response.change(
      body: chunkedCoding.decoder.bind(response.read()),
    );
    httpResponse.headers.set(HttpHeaders.transferEncodingHeader, 'chunked');
  } else if (response.statusCode >= 200 &&
      response.statusCode != 204 &&
      response.statusCode != 304 &&
      response.contentLength == null &&
      response.mimeType != 'multipart/byteranges') {
    // If the response isn't chunked yet and there's no other way to tell its
    // length, enable `dart:io`'s chunked encoding.
    httpResponse.headers.set(HttpHeaders.transferEncodingHeader, 'chunked');
  }

  if (poweredByHeader != null &&
      !response.headers.containsKey(_xPoweredByResponseHeader)) {
    httpResponse.headers.set(_xPoweredByResponseHeader, poweredByHeader);
  }

  if (!response.headers.containsKey(HttpHeaders.dateHeader)) {
    httpResponse.headers.date = DateTime.now().toUtc();
  }

  return httpResponse
      .addStream(response.read())
      .then((_) => httpResponse.close());
}

/// Common header to advertise the server technology being used.
///
/// See https://webtechsurvey.com/response-header/x-powered-by
const _xPoweredByResponseHeader = 'X-Powered-By';

// TODO(kevmoo) A developer mode is needed to include error info in response
// TODO(kevmoo) Make error output plugable. stderr, logging, etc
Response _logError(Request request, String message, StackTrace stackTrace) {
  // Add information about the request itself.
  var buffer = StringBuffer();
  buffer.write('${request.method} ${request.requestedUri.path}');
  if (request.requestedUri.query.isNotEmpty) {
    buffer.write('?${request.requestedUri.query}');
  }
  buffer.writeln();
  buffer.write(message);

  _logTopLevelError(buffer.toString(), stackTrace);
  return Response.internalServerError();
}

void _logTopLevelError(String message, StackTrace stackTrace) {
  final chain = Chain.forTrace(stackTrace)
      .foldFrames((frame) => frame.isCore || frame.package == 'shelf')
      .terse;

  stderr.writeln('ERROR - ${DateTime.now()}');
  stderr.writeln(message);
  stderr.writeln(chain);
}
