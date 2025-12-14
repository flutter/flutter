// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_proxy/shelf_proxy.dart';

import '../base/logger.dart';
import '../web/devfs_proxy.dart';

const _kLogEntryPrefix = '[proxyMiddleware]';

const Set<String> _kCookieAttributes = <String>{
  'path',
  'domain',
  'expires',
  'max-age',
  'secure',
  'httponly',
  'samesite',
  'partitioned',
};

List<String> splitSetCookieHeader(String headerValue) {
  if (headerValue.isEmpty) {
    return <String>[];
  }

  final cookies = <String>[];
  final currentCookie = StringBuffer();
  final List<String> parts = headerValue.split(', ');

  for (var i = 0; i < parts.length; i++) {
    final String part = parts[i];

    if (currentCookie.isEmpty) {
      currentCookie.write(part);
    } else if (_isNewCookie(part)) {
      cookies.add(currentCookie.toString());
      currentCookie.clear();
      currentCookie.write(part);
    } else {
      currentCookie.write(', $part');
    }
  }

  if (currentCookie.isNotEmpty) {
    cookies.add(currentCookie.toString());
  }

  return cookies;
}

bool _isNewCookie(String part) {
  final int equalsIndex = part.indexOf('=');
  if (equalsIndex <= 0) {
    return false;
  }

  final String beforeEquals = part.substring(0, equalsIndex);
  final int lastSemicolon = beforeEquals.lastIndexOf(';');
  final int lastSpace = beforeEquals.lastIndexOf(' ');
  final int tokenStart = (lastSemicolon > lastSpace ? lastSemicolon : lastSpace) + 1;
  final String token = beforeEquals.substring(tokenStart).trim().toLowerCase();

  if (token.isEmpty || _kCookieAttributes.contains(token)) {
    return false;
  }

  return RegExp(r'^[a-zA-Z0-9_\-]+$').hasMatch(token);
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
      shelf.Response proxyResponse = await handler(proxyBackendRequest);
      logger.printStatus('$_kLogEntryPrefix Matched "$requestPath". Requesting "$finalTargetUrl"');
      logger.printTrace('$_kLogEntryPrefix Matched with proxy rule: $rule');
      if (proxyResponse.statusCode == 404) {
        logger.printTrace('$_kLogEntryPrefix "$finalTargetUrl" responded with status 404');
        return innerHandler(request);
      }
      proxyResponse = _fixSetCookieHeaders(proxyResponse);
      return proxyResponse;
    } on Exception catch (e) {
      logger.printError('$_kLogEntryPrefix Error for $finalTargetUrl: $e. Allowing fall-through.');
      return innerHandler(request);
    }
  }
  return innerHandler(request);
}

shelf.Response _fixSetCookieHeaders(shelf.Response response) {
  final String? setCookieHeader = response.headers['set-cookie'];
  if (setCookieHeader == null) {
    return response;
  }

  final List<String> cookies = splitSetCookieHeader(setCookieHeader);
  if (cookies.length <= 1) {
    return response;
  }

  final newHeaders = Map<String, Object>.from(response.headers);
  newHeaders['set-cookie'] = cookies;
  return response.change(headers: newHeaders);
}

/// Creates a [shelf.Middleware] that proxies requests based on a list of [ProxyRule]s.
shelf.Middleware proxyMiddleware(List<ProxyRule> effectiveProxy, Logger logger) {
  return (shelf.Handler innerHandler) {
    return (shelf.Request request) async {
      return _applyProxyRules(request, effectiveProxy, innerHandler, logger);
    };
  };
}
