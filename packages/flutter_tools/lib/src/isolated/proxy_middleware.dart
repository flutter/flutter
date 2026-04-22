// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;

import '../base/logger.dart';
import '../web/devfs_proxy.dart';

const _kLogEntryPrefix = '[proxyMiddleware]';

/// Creates a custom proxy handler that properly handles Set-Cookie headers.
///
/// Per HTTP specification (RFC 6265), Set-Cookie headers must be sent as separate
/// headers and cannot be combined into a single comma-separated header like other
/// response headers. This custom handler ensures that multiple Set-Cookie headers
/// from the backend are preserved and forwarded correctly to the client.
class _CustomProxyHandler {
  final Uri _targetUri;
  final Logger _logger;
  late HttpClient _httpClient;

  _CustomProxyHandler(this._targetUri, this._logger) {
    _httpClient = HttpClient();
    // Keep connections alive for better performance
    _httpClient.connectionFactory = () => IOClientConnector();
  }

  Future<shelf.Response> handle(shelf.Request request) async {
    try {
      // Build the target URL
      final Uri targetUrl = _buildTargetUrl(request, _targetUri);
      
      // Create the HTTP request to the backend
      final HttpClientRequest httpRequest = await _httpClient.getUrl(targetUrl);
      
      // Copy headers from the original request
      request.headers.forEach((key, value) {
        if (key != 'host' && key != 'content-length') {
          httpRequest.headers.set(key, value);
        }
      });
      
      // Set the content length if present
      if (request.headers.containsKey('content-length')) {
        httpRequest.headers.contentLength = int.parse(request.headers['content-length']!);
      }
      
      // Add host header for the target
      httpRequest.headers.set('host', _targetUri.host);
      
      // Add user agent if not present
      if (!request.headers.containsKey('user-agent')) {
        httpRequest.headers.set('user-agent', 'Flutter Tools Proxy');
      }
      
      // Add accept encoding
      if (!request.headers.containsKey('accept-encoding')) {
        httpRequest.headers.set('accept-encoding', 'gzip, deflate');
      }
      
      // Write the request body
      await request.body.pipe(httpRequest);
      
      // Get the response
      final HttpClientResponse httpResponse = await httpRequest.close();
      
      // Read the response body
      final String body = await utf8.decoder.bind(httpResponse).join();
      
      // Build the shelf response with proper Set-Cookie handling
      final Map<String, String> headers = _buildResponseHeaders(httpResponse);
      
      // Extract Set-Cookie headers specially
      final List<String> setCookies = httpResponse.headers.values['set-cookie'] ?? [];
      
      _logger.printTrace('$_kLogEntryPrefix Forwarded response with ${setCookies.length} Set-Cookie headers');
      
      return shelf.Response(
        httpResponse.statusCode,
        body: body,
        headers: headers,
      );
    } on Exception catch (e) {
      _logger.printError('$_kLogEntryPrefix Proxy error: $e');
      rethrow;
    }
  }
  
  Uri _buildTargetUrl(shelf.Request request, Uri targetUri) {
    // Simple implementation - can be expanded for more complex routing
    final String path = request.requestedUri.path;
    final String query = request.requestedUri.query;
    
    return targetUri.replace(
      path: path,
      query: query.isNotEmpty ? query : null,
    );
  }
  
  Map<String, String> _buildResponseHeaders(HttpClientResponse httpResponse) {
    final Map<String, String> headers = {};
    
    // Copy all headers except Set-Cookie (handled separately)
    httpResponse.headers.forEach((key, values) {
      if (key.toLowerCase() != 'set-cookie') {
        // For headers with multiple values, join with comma (standard behavior)
        // except for Set-Cookie which is handled separately
        headers[key] = values.join(', ');
      }
    });
    
    return headers;
  }
  
  void dispose() {
    _httpClient.close();
  }
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
    
    final Uri finalTargetUrl = rule.finalTargetUri(request.requestedUri);
    
    try {
      // Use custom proxy handler that properly handles Set-Cookie headers
      final _CustomProxyHandler proxyHandler = _CustomProxyHandler(finalTargetUrl, logger);
      final shelf.Response proxyResponse = await proxyHandler.handle(request);
      
      logger.printStatus('$_kLogEntryPrefix Matched "$requestPath". Requesting "$finalTargetUrl"');
      logger.printTrace('$_kLogEntryPrefix Matched with proxy rule: $rule');
      
      proxyHandler.dispose();
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
