// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_proxy/shelf_proxy.dart';

import '../base/logger.dart';
import '../web/devfs_proxy.dart';

const _kLogEntryPrefix = '[proxyMiddleware]';

/// Known Set-Cookie attribute names (lowercase) that may appear before '='
/// in a cookie header value (e.g. "Max-Age=3600").
const Set<String> _kCookieAttributes = <String>{
  'domain',
  'expires',
  'httponly',
  'max-age',
  'partitioned',
  'path',
  'samesite',
  'secure',
};

/// Splits a merged Set-Cookie header value into individual cookie strings.
///
/// HTTP allows multiple Set-Cookie headers, but some libraries merge them into
/// a single comma-separated string. This is problematic because cookie values
/// and Expires dates can contain commas. This function re-splits them by
/// detecting where a new cookie name starts after a comma.
List<String> splitSetCookieHeader(String headerValue) {
  if (headerValue.isEmpty) {
    return <String>[];
  }

  final List<String> cookies = <String>[];
  final StringBuffer currentCookie = StringBuffer();

  for (final String part in headerValue.split(',')) {
    final String trimmedPart = part.trim();
    if (currentCookie.isEmpty) {
      currentCookie.write(trimmedPart);
    } else if (_isNewCookie(trimmedPart)) {
      cookies.add(currentCookie.toString());
      currentCookie.clear();
      currentCookie.write(trimmedPart);
    } else {
      currentCookie.write(', $trimmedPart');
    }
  }

  if (currentCookie.isNotEmpty) {
    cookies.add(currentCookie.toString());
  }

  return cookies;
}

/// Returns true if [part] looks like the start of a new cookie (name=value)
/// rather than a continuation of a previous cookie's attribute (e.g. an
/// Expires date that contains a comma).
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

  // RFC 6265 cookie-name is a token (RFC 2616 §2.2); allow all valid token characters.
  return RegExp(r"^[!#$%&'*+.^_`|~0-9a-zA-Z-]+$").hasMatch(token);
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

/// Fixes Set-Cookie headers that were incorrectly merged into a single value.
///
/// The shelf_proxy package merges multiple Set-Cookie headers into one
/// comma-separated string, but Set-Cookie cannot be safely combined this way
/// because cookie values and Expires dates can contain commas.
shelf.Response _fixSetCookieHeaders(shelf.Response response) {
  final String? setCookieHeader = response.headers['set-cookie'];
  if (setCookieHeader == null) {
    return response;
  }

  final List<String> cookies = splitSetCookieHeader(setCookieHeader);
  if (cookies.length <= 1) {
    return response;
  }

  return response.change(headers: <String, Object>{...response.headers, 'set-cookie': cookies});
}

/// Creates a [shelf.Middleware] that proxies requests based on a list of [ProxyRule]s.
shelf.Middleware proxyMiddleware(List<ProxyRule> effectiveProxy, Logger logger) {
  return (shelf.Handler innerHandler) {
    return (shelf.Request request) async {
      return _applyProxyRules(request, effectiveProxy, innerHandler, logger);
    };
  };
}
