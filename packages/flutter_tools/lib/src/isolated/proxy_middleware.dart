// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_proxy/shelf_proxy.dart';

import '../base/logger.dart';
import '../web/devfs_proxy.dart';

const _kLogEntryPrefix = '[proxyMiddleware]';

/// A regex that splits a merged `Set-Cookie` header value into individual cookies.
///
/// HTTP clients that use a [Map<String, String>] for headers (such as
/// `package:http`) merge multiple `Set-Cookie` headers into a single
/// comma-separated value. This regex splits them back into individual cookie
/// strings by matching commas that are followed by a valid HTTP token character
/// and `=`, which indicates the start of a new `<cookie-name>=<cookie-value>`
/// pair rather than a comma within an attribute value such as an `Expires` date.
///
/// See https://datatracker.ietf.org/doc/html/rfc6265#section-4.1.1
final _kSetCookieSplitter = RegExp(
  r"[ \t]*,[ \t]*(?=[!#$%&'*+\-.0-9A-Z^_`a-z|~]+=)",
);

/// Fixes merged `Set-Cookie` response headers caused by HTTP clients that
/// represent headers as a flat [Map<String, String>].
///
/// When multiple `Set-Cookie` headers are present in a response, some HTTP
/// clients join them with commas into a single header value. Browsers require
/// each `Set-Cookie` to be a separate header, so merging them causes cookies
/// to be dropped or incorrectly parsed.
///
/// This function detects merged cookies using [_kSetCookieSplitter] and returns
/// a new [shelf.Response] with the `set-cookie` header expanded to a list of
/// individual cookie strings.
shelf.Response _fixSetCookieHeaders(shelf.Response response) {
  final String? mergedCookies = response.headers['set-cookie'];
  if (mergedCookies == null || !mergedCookies.contains(',')) {
    return response;
  }
  final List<String> splitCookies = mergedCookies.split(_kSetCookieSplitter);
  if (splitCookies.length <= 1) {
    return response;
  }
  return response.change(headers: <String, Object>{'set-cookie': splitCookies});
}

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
      final shelf.Request proxyBackendRequest = proxyRequest(request, finalTargetUrl);
      final shelf.Response proxyResponse = await handler(proxyBackendRequest);
      logger.printStatus('$_kLogEntryPrefix Matched "$requestPath". Requesting "$finalTargetUrl"');
      logger.printTrace('$_kLogEntryPrefix Matched with proxy rule: $rule');
      return _fixSetCookieHeaders(proxyResponse);
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
