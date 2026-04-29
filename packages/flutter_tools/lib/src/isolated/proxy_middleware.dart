// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_proxy/shelf_proxy.dart';

import '../base/logger.dart';
import '../web/devfs_proxy.dart';

const _kLogEntryPrefix = '[proxyMiddleware]';

/// Creates a new [shelf.Request] by proxying an [originalRequest] to a [finalTargetUrl].
///
/// The new request will have the same method, body, and context as the
/// [originalRequest], but its URL will be set to [finalTargetUrl]. The
/// original headers are kept; any entries in [extraHeaders] are merged on
/// top, overriding the original on key collisions.
shelf.Request proxyRequest(
  shelf.Request originalRequest,
  Uri finalTargetUrl, {
  Map<String, String> extraHeaders = const <String, String>{},
}) {
  final Map<String, String> mergedHeaders = extraHeaders.isEmpty
      ? originalRequest.headers
      : <String, String>{...originalRequest.headers, ...extraHeaders};
  return shelf.Request(
    originalRequest.method,
    finalTargetUrl,
    headers: mergedHeaders,
    body: originalRequest.read(),
    context: originalRequest.context,
  );
}

/// Iterates through the provided [effectiveProxy] rules for each incoming [shelf.Request].
///
/// If a rule's pattern matches the request's path, the request is
/// rewritten and forwarded to the target URI defined in the matching [ProxyRule].
/// Otherwise, the request is passed to the next handler in the Shelf stack.
Future<shelf.Response> _applyProxyRules(
  shelf.Request request,
  List<ProxyRule> effectiveProxy,
  shelf.Handler innerHandler,
  Logger logger,
) async {
  final String requestPath = request.requestedUri.path;
  for (final rule in effectiveProxy) {
    if (!rule.matches(requestPath)) {
      continue;
    }
    final shelf.Handler handler = proxyHandler(rule.targetUri, proxyName: 'flutter_tools');
    final Uri finalTargetUrl = rule.finalTargetUri(request.requestedUri);
    try {
      final shelf.Request proxyBackendRequest = proxyRequest(
        request,
        finalTargetUrl,
        extraHeaders: rule.headers,
      );
      final shelf.Response proxyResponse = await handler(proxyBackendRequest);
      logger.printStatus('$_kLogEntryPrefix Matched "$requestPath". Requesting "$finalTargetUrl"');
      logger.printTrace('$_kLogEntryPrefix Matched with proxy rule: $rule');
      return proxyResponse;
    } on Exception catch (e) {
      logger.printError('$_kLogEntryPrefix Error for $finalTargetUrl: $e. Allowing fall-through.');
      return innerHandler(request);
    }
  }
  return innerHandler(request);
}

/// Creates a [shelf.Middleware] that proxies requests based on a list of [ProxyRule]s.
shelf.Middleware proxyMiddleware(List<ProxyRule> effectiveProxy, Logger logger) {
  return (shelf.Handler innerHandler) {
    return (shelf.Request request) async {
      return _applyProxyRules(request, effectiveProxy, innerHandler, logger);
    };
  };
}
