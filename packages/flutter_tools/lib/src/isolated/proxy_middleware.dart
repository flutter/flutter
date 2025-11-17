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
/// The new request will have the same method, headers, body, and context as the
/// [originalRequest], but its URL will be set to [finalTargetUrl].
shelf.Request proxyRequest(shelf.Request originalRequest, Uri finalTargetUrl) {
  return shelf.Request(
    originalRequest.method,
    finalTargetUrl,
    headers: originalRequest.headers,
    body: originalRequest.read(),
    context: originalRequest.context,
  );
}

/// Rewrites the request path based on the specified rule by:
/// 1. Getting the base target URI from the rule.
/// 2. Replacing the request path according to the rule's replacement logic.
/// 3. Resolving the final target URL by combining the target URI, the rewritten
///    request path and the request query
Uri getFinalTargetUri(shelf.Request request, ProxyRule rule) {
  final String rewrittenPath = rule.replace(request.requestedUri.path);
  final Uri targetUri = rule.getTargetUri();
  return targetUri.resolveUri(Uri(path: rewrittenPath, query: request.requestedUri.query));
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
    final Uri targetUri = rule.getTargetUri();
    final Uri finalTargetUrl = getFinalTargetUri(request, rule);
    try {
      final shelf.Request proxyBackendRequest = proxyRequest(request, finalTargetUrl);
      final shelf.Response proxyResponse = await proxyHandler(targetUri)(proxyBackendRequest);
      logger.printStatus('$_kLogEntryPrefix Matched "$requestPath". Requesting "$finalTargetUrl"');
      logger.printTrace('$_kLogEntryPrefix Matched with proxy rule: $rule');
      if (proxyResponse.statusCode == 404) {
        logger.printTrace('$_kLogEntryPrefix "$finalTargetUrl" responded with status 404');
        return innerHandler(request);
      }
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
