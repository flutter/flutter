// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_proxy/shelf_proxy.dart';

import '../globals.dart' as globals;
import '../web/devfs_proxy.dart';

shelf.Request proxyRequest(shelf.Request originalRequest, Uri finalTargetUrl) {
  return shelf.Request(
    originalRequest.method,
    finalTargetUrl,
    headers: originalRequest.headers,
    body: originalRequest.read(),
    context: originalRequest.context,
  );
}

shelf.Middleware proxyMiddleware(List<ProxyRule> effectiveProxy) {
  return (shelf.Handler innerHandler) {
    return (shelf.Request request) async {
      final String requestPath = _normalizePath(request.url.path);
      for (final rule in effectiveProxy) {
        if (rule.matches(requestPath)) {
          final Uri targetBaseUri = Uri.parse(rule.target);
          final String rewrittenRequest = rule.replace(requestPath);
          final Uri finalTargetUrl = targetBaseUri.resolve(rewrittenRequest);
          try {
            final shelf.Request proxyBackendRequest = proxyRequest(request, finalTargetUrl);
            final shelf.Response proxyResponse = await proxyHandler(targetBaseUri)(
              proxyBackendRequest,
            );
            final internalRequest = proxyResponse.headers['sec-fetch-mode'] == 'no-cors';
            if (!internalRequest) {
              globals.logger.printStatus(
                '[PROXY] Matched "$requestPath". Requesting "$finalTargetUrl"',
              );
              globals.logger.printTrace('[PROXY] Matched with proxy rule: $rule');
            }
            if (proxyResponse.statusCode == 404) {
              if (!internalRequest) {
                globals.printTrace('"$finalTargetUrl" responded with status 404');
              }
              return innerHandler(request);
            }
            return proxyResponse;
          } on Exception catch (e) {
            globals.logger.printError(
              'Proxy error for $finalTargetUrl: $e. Allowing fall-through.',
            );

            return innerHandler(request);
          }
        }
      }

      return innerHandler(request);
    };
  };
}

String _normalizePath(String path) {
  if (!path.startsWith('/')) {
    path = '/$path';
  }
  return path;
}
