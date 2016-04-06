// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library diagnostic_server;

import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

void handleSkiaPictureRequest(SendPort sendPort)
    native 'DiagnosticServer_HandleSkiaPictureRequest';

void diagnosticServerStart() {
  HttpServer.bind('127.0.0.1', 0).then((HttpServer server) {
    server.listen(dispatchRequest, cancelOnError: true);

    String ip = server.address.address.toString();
    String port = server.port.toString();
    print('Diagnostic server listening on http://$ip:$port');
  });
}

void sendError(HttpResponse response, String error) {
  response.statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
  response.headers.contentType = ContentType.TEXT;
  response.write(error);
}

void dispatchRequest(HttpRequest request) {
  HttpResponse response = request.response;

  try {
    if (request.uri.path == '/skp') {
      ReceivePort port = new ReceivePort();
      port.first.then((Object data) => onReceiveSkiaPicture(response, data));
      handleSkiaPictureRequest(port.sendPort);
      return;
    }

    sendError(response, 'Diagnostic server: unexpected request, uri=${request.uri}');
  } catch (e) {
    sendError(response, 'Diagnostic server: error processing request, uri=${request.uri}\n${e}');
  }

  response.close();
}

void onReceiveSkiaPicture(HttpResponse response, Object data) {
  if (data != null) {
    response.statusCode = HttpStatus.OK;
    response.headers.contentType = ContentType.BINARY;
    response.add(data);
  } else {
    sendError(response, 'Unable to capture Skia picture');
  }
  response.close();
}
