// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:devtools_shared/devtools_server.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:sse/server/sse_handler.dart';

import '../constants.dart';
import '../dds_impl.dart';
import 'client.dart';

/// Returns a [Handler] which handles serving DevTools and the DevTools server
/// API.
///
/// [buildDir] is the path to the pre-compiled DevTools instance to be served.
///
/// [notFoundHandler] is a [Handler] to which requests that could not be handled
/// by the DevTools handler are forwarded (e.g., a proxy to the VM service).
///
/// If [dds] is null, DevTools is not being served by a DDS instance and is
/// served by a standalone server (see `package:dds/devtools_server.dart`).
FutureOr<Handler> defaultHandler({
  DartDevelopmentServiceImpl? dds,
  required String buildDir,
  ClientManager? clientManager,
  Handler? notFoundHandler,
}) {
  // When served through DDS, the app root is /devtools/.
  // This variable is used in base href and must start and end with `/`.
  var appRoot = dds != null ? '/devtools/' : '/';
  if (dds?.authCodesEnabled ?? false) {
    appRoot = '/${dds!.authCode}$appRoot';
  }

  const defaultDocument = 'index.html';
  final indexFile = File(path.join(buildDir, defaultDocument));

  // Serves the static web assets for DevTools.
  final devtoolsStaticAssetHandler = createStaticHandler(
    buildDir,
    defaultDocument: defaultDocument,
  );

  /// A wrapper around [devtoolsStaticAssetHandler] that handles serving
  /// index.html up for / and non-file requests like /memory, /inspector, etc.
  /// with the correct base href for the DevTools root.
  final devtoolsAssetHandler = (Request request) {
    // To avoid hard-coding a set of page names here (or needing access to one
    // from DevTools, assume any single-segment path with no extension is a
    // DevTools page that needs to serve up index.html).
    final pathSegments = request.url.pathSegments;
    final isValidRootPage = pathSegments.isEmpty ||
        (pathSegments.length == 1 && !pathSegments[0].contains('.'));
    if (isValidRootPage) {
      return _serveStaticFile(
        request,
        indexFile,
        'text/html',
        baseHref: appRoot,
      );
    }

    return devtoolsStaticAssetHandler(request);
  };

  // Support DevTools client-server interface via SSE.
  // Note: the handler path needs to match the full *original* path, not the
  // current request URL (we remove '/devtools' in the initial router but we
  // need to include it here).
  final devToolsSseHandlerPath = '${appRoot}api/sse';
  final devToolsApiHandler = SseHandler(
    Uri.parse(devToolsSseHandlerPath),
    keepAlive: sseKeepAlive,
  );

  clientManager ??= ClientManager(requestNotificationPermissions: false);

  devToolsApiHandler.connections.rest.listen(
    (sseConnection) => clientManager!.acceptClient(
      sseConnection,
      enableLogging: dds?.shouldLogRequests ?? false,
    ),
  );

  final devtoolsHandler = (Request request) {
    // If the request isn't of the form api/<method> assume it's a request for
    // DevTools assets.
    if (request.url.pathSegments.length < 2 ||
        request.url.pathSegments.first != 'api') {
      return devtoolsAssetHandler(request);
    }
    final method = request.url.pathSegments[1];
    if (method == 'ping') {
      // Note: we have an 'OK' body response, otherwise the response has an
      // incorrect status code (204 instead of 200).
      return Response.ok('OK');
    }
    if (method == 'sse') {
      return devToolsApiHandler.handler(request);
    }
    if (!ServerApi.canHandle(request)) {
      return Response.notFound('$method is not a valid API');
    }
    return ServerApi.handle(request);
  };

  return (Request request) {
    if (notFoundHandler != null) {
      final pathSegments = request.url.pathSegments;
      if (pathSegments.isEmpty || pathSegments.first != 'devtools') {
        return notFoundHandler(request);
      }
      // Forward all requests to /devtools/* to the DevTools handler.
      request = request.change(path: 'devtools');
    }
    return devtoolsHandler(request);
  };
}

/// Serves [file] for all requests.
///
/// If [baseHref] is provided, any existing `<base href="">` tag will be
/// rewritten with this path.
Future<Response> _serveStaticFile(
  Request request,
  File file,
  String contentType, {
  String? baseHref,
}) async {
  final headers = {HttpHeaders.contentTypeHeader: contentType};
  var contents = file.readAsStringSync();

  if (baseHref != null) {
    assert(baseHref.startsWith('/'));
    assert(baseHref.endsWith('/'));
    // Replace the base href to match where the app is being served from.
    final baseHrefPattern = RegExp(r'<base href="\/"\s?\/?>');
    contents = contents.replaceFirst(
      baseHrefPattern,
      '<base href="${htmlEscape.convert(baseHref)}">',
    );
  }

  return Response.ok(contents, headers: headers);
}
