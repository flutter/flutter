// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show HttpServer;
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/isolated/proxy_middleware.dart';
import 'package:flutter_tools/src/web/devfs_proxy.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  late BufferLogger logger;
  setUp(() {
    logger = BufferLogger.test();
  });

  group('ProxyRule', () {
    test('fromYaml returns null for invalid YAML', () {
      final yaml = YamlMap.wrap(<String, String>{'unknown': 'rule'});
      final ProxyRule? rule = ProxyRule.fromYaml(yaml, logger);
      expect(rule, isNull);
      expect(logger.errorText, contains('Invalid proxy rule in YAML'));
    });

    test('fromYaml returns PrefixProxyRule', () {
      final yaml = YamlMap.wrap(<String, String>{
        'prefix': '/api',
        'target': 'http://localhost:8080',
      });
      final ProxyRule? rule = ProxyRule.fromYaml(yaml, logger);
      expect(rule, isA<PrefixProxyRule>());
    });

    test('fromYaml returns RegexProxyRule', () {
      final yaml = YamlMap.wrap(<String, String>{
        'regex': '/api/(.*)',
        'target': 'http://localhost:8080',
      });
      final ProxyRule? rule = ProxyRule.fromYaml(yaml, logger);
      expect(rule, isA<RegexProxyRule>());
    });
  });

  group('RegexProxyRule', () {
    test('canHandle returns true for valid regex', () {
      final yaml = YamlMap.wrap(<String, String>{
        'regex': '/api/(.*)',
        'target': 'http://localhost:8080',
      });
      expect(RegexProxyRule.canHandle(yaml), isTrue);
    });

    test('canHandle returns false for missing regex', () {
      final yaml = YamlMap.wrap(<String, String>{'target': 'http://localhost:8080'});
      expect(RegexProxyRule.canHandle(yaml), isFalse);
    });

    test('canHandle returns false for empty regex', () {
      final yaml = YamlMap.wrap(<String, String>{'regex': '', 'target': 'http://localhost:8080'});
      expect(RegexProxyRule.canHandle(yaml), isFalse);
    });

    test('fromYaml creates a RegexProxyRule', () {
      final yaml = YamlMap.wrap(<String, String>{
        'regex': '^/api/(.*)',
        'target': 'http://localhost:8080',
        'replace': r'/$1',
      });
      final RegexProxyRule? rule = RegexProxyRule.fromYaml(yaml, logger);
      expect(rule, isNotNull);
      expect(rule.toString(), r'{regex: ^/api/(.*), target: http://localhost:8080, replace: /$1}');
    });

    test('fromYaml logs warning for invalid regex format', () {
      final yaml = YamlMap.wrap(<String, String>{
        'regex': '[invalid',
        'target': 'http://localhost:8080',
      });
      final RegexProxyRule? rule = RegexProxyRule.fromYaml(yaml, logger);
      expect(rule, isNotNull);
      expect(logger.warningText, contains('Invalid regex pattern'));
      expect(rule.toString(), r'{regex: \[invalid, target: http://localhost:8080, replace: null}');
    });

    test('fromYaml returns null if target is missing', () {
      final yaml = YamlMap.wrap(<String, String>{'regex': '/api/(.*)'});
      final RegexProxyRule? rule = RegexProxyRule.fromYaml(yaml, logger);
      expect(rule, isNull);
      expect(logger.errorText, contains('Invalid target for regex'));
    });

    test('matches returns true when regex matches path', () {
      final rule = RegexProxyRule(
        pattern: RegExp(r'^/api/v1/users/(.*)'),
        target: 'http://localhost:8080',
      );
      expect(rule.matches('/api/v1/users/123'), isTrue);
      expect(rule.matches('/api/v1/users/'), isTrue);
    });

    test('matches returns false when regex does not match path', () {
      final rule = RegexProxyRule(
        pattern: RegExp(r'^/api/v1/users/(.*)'),
        target: 'http://localhost:8080',
      );
      expect(rule.matches('/auth/login'), isFalse);
    });

    test('replace correctly replaces with capture groups', () {
      final rule = RegexProxyRule(
        pattern: RegExp(r'/users/(\d+)/profile'),
        target: 'http://localhost:8080',
        replacement: r'/api/v1/user/$1',
      );
      expect(rule.replace('/users/123/profile'), '/api/v1/user/123');
    });

    test('replace correctly replaces without capture groups', () {
      final rule = RegexProxyRule(
        pattern: RegExp(r'/oldpath'),
        target: 'http://localhost:8080',
        replacement: '/newpath',
      );
      expect(rule.replace('/oldpath/resource'), '/newpath/resource');
    });

    test('replace returns original path for no replacement', () {
      final rule = RegexProxyRule(
        pattern: RegExp(r'/users/(\d+)'),
        target: 'http://localhost:8080',
      );
      expect(rule.replace('/users/123'), '/users/123');
    });

    test('replace should replace all occurences', () {
      final rule = RegexProxyRule(
        pattern: RegExp(r'/users/(\d+)/profile'),
        target: 'http://localhost:8080',
        replacement: r'/api/v1/user/$1',
      );
      expect(
        rule.replace('/users/456/profile/users/123/profile'),
        '/api/v1/user/456/api/v1/user/123',
      );
    });

    test(r'replace should handle $0 (entire match)', () {
      final rule = RegexProxyRule(
        pattern: RegExp(r'^/prefix/(.*)'),
        target: 'http://localhost:8080',
        replacement: r'/all$0',
      );
      expect(rule.replace('/prefix/something/else'), '/all/prefix/something/else');
    });

    test('replace should handle non-matching path gracefully', () {
      final rule = RegexProxyRule(
        pattern: RegExp(r'^/api/v1/users/(\d+)(.*)'),
        target: 'http://localhost:8080',
        replacement: r'/$1/profile$2',
      );
      expect(rule.replace('/non/matching/path'), '/non/matching/path');
    });

    test('getTargetUri returns correct Uri', () {
      final rule = RegexProxyRule(
        pattern: RegExp(r'^/api/v1/users/(.*)'),
        target: 'http://localhost:8080/users/',
        replacement: r'$1',
      );
      final Uri targetUri = rule.targetUri;
      expect(targetUri.toString(), 'http://localhost:8080/users/');
      expect(targetUri.scheme, 'http');
      expect(targetUri.host, 'localhost');
      expect(targetUri.port, 8080);
      expect(targetUri.path, '/users/');
    });
  });

  group('PrefixProxyRule', () {
    test('canHandle returns true for valid prefix', () {
      final yaml = YamlMap.wrap(<String, String>{
        'prefix': '/api',
        'target': 'http://localhost:8080',
      });
      expect(PrefixProxyRule.canHandle(yaml), isTrue);
    });

    test('canHandle returns false for missing prefix', () {
      final yaml = YamlMap.wrap(<String, String>{'target': 'http://localhost:8080'});
      expect(PrefixProxyRule.canHandle(yaml), isFalse);
    });

    test('canHandle returns false for empty prefix', () {
      final yaml = YamlMap.wrap(<String, String>{'prefix': '', 'target': 'http://localhost:8080'});
      expect(PrefixProxyRule.canHandle(yaml), isFalse);
    });

    test('fromYaml creates a PrefixProxyRule', () {
      final yaml = YamlMap.wrap(<String, String>{
        'prefix': '/old_path',
        'target': 'http://localhost:8080/new_path',
        'replace': '/new_prefix',
      });
      final PrefixProxyRule? rule = PrefixProxyRule.fromYaml(yaml, logger);
      expect(rule, isNotNull);
      expect(
        rule.toString(),
        '{prefix: ^/old_path, target: http://localhost:8080/new_path, replace: /new_prefix}',
      );
    });

    test('fromYaml returns null if target is missing', () {
      final yaml = YamlMap.wrap(<String, String>{'prefix': '/api'});
      final PrefixProxyRule? rule = PrefixProxyRule.fromYaml(yaml, logger);
      expect(rule, isNull);
      expect(logger.errorText, contains('Invalid target for prefix'));
    });

    test('matches returns true when path starts with prefix', () {
      final rule = PrefixProxyRule(prefix: '/api/v1', target: 'http://localhost:8080');
      expect(rule.matches('/api/v1/users'), isTrue);
      expect(rule.matches('/api/v1'), isTrue);
    });

    test('matches returns false when path does not start with prefix', () {
      final rule = PrefixProxyRule(prefix: '/api/v1', target: 'http://localhost:8080');
      expect(rule.matches('/auth/login/api/v1'), isFalse);
      expect(rule.matches('/api'), isFalse);
    });

    test('replace correctly replaces the prefix', () {
      final rule = PrefixProxyRule(
        prefix: '/api/',
        target: 'http://localhost:8080',
        replacement: '/',
      );
      expect(rule.replace('/api/users/123'), '/users/123');
    });

    test('replace returns original path if no replacement', () {
      final rule = PrefixProxyRule(prefix: '/api/', target: 'http://localhost:8080');
      expect(rule.replace('/api/users/123'), '/api/users/123');
    });

    test('replace matches exactly', () {
      final rule = PrefixProxyRule(
        prefix: '/api',
        target: 'http://localhost:8080',
        replacement: '/',
      );
      expect(rule.replace('/api/users/123'), '//users/123');
    });

    test('replace removes pattern if empty string', () {
      final rule = PrefixProxyRule(
        prefix: '/api/users',
        target: 'http://localhost:8080',
        replacement: '',
      );
      expect(rule.replace('/api/users/123'), '/123');
    });

    test('replace replaces first occurence', () {
      final rule = PrefixProxyRule(
        prefix: '/api/users',
        target: 'http://localhost:8080',
        replacement: '/product',
      );
      expect(rule.replace('/api/users/api/users/123'), '/product/api/users/123');
    });

    test('replace returns original path for non-matching pattern', () {
      final rule = PrefixProxyRule(
        prefix: '/api/users',
        target: 'http://localhost:8080',
        replacement: '/product',
      );
      expect(rule.replace('/source/123'), '/source/123');
    });

    test('getTargetUri returns correct Uri', () {
      final rule = PrefixProxyRule(prefix: '/api/users', target: 'http://localhost:8080');
      final Uri targetUri = rule.targetUri;
      expect(targetUri.toString(), 'http://localhost:8080');
      expect(targetUri.scheme, 'http');
      expect(targetUri.host, 'localhost');
      expect(targetUri.port, 8080);
    });
  });

  group('proxyRequest', () {
    test('should correctly proxy all request elements', () async {
      final Uri originalUrl = Uri.parse('http://original.example.com/path');
      final Uri finalTargetUrl = Uri.parse('http://target.example.com/newpath');
      const originalBody = 'Hello, Shelf Proxy!';
      final originalHeaders = <String, String>{
        'Content-Type': 'text/plain',
        'X-Custom-Header': 'value',
        'content-length': 'ignored',
      };
      final originalContext = <String, Object>{'user': 'testuser', 'auth': true};

      final originalRequest = Request(
        'POST',
        originalUrl,
        headers: originalHeaders,
        body: originalBody,
        context: originalContext,
      );
      final Request proxiedRequest = proxyRequest(originalRequest, finalTargetUrl);

      final expectedHeadersFiltered = Map<String, String>.fromEntries(
        originalHeaders.entries.where(
          (MapEntry<String, String> entry) => entry.key.toLowerCase() != 'content-length',
        ),
      );

      for (final MapEntry<String, String> entry in expectedHeadersFiltered.entries) {
        expect(proxiedRequest.headers, containsPair(entry.key, entry.value));
      }

      expect(proxiedRequest.method, 'POST');
      expect(proxiedRequest.url.toString(), 'newpath');
      expect(proxiedRequest.context, originalContext);

      final String proxiedBody = await proxiedRequest.readAsString();
      expect(proxiedBody, originalBody);
    });

    test('should handle an empty request body', () async {
      final Uri originalUrl = Uri.parse('http://original.example.com/empty');
      final Uri finalTargetUrl = Uri.parse('http://target.example.com/empty-new');

      final originalRequest = Request('GET', originalUrl);

      final Request proxiedRequest = proxyRequest(originalRequest, finalTargetUrl);

      expect(proxiedRequest.method, 'GET');
      expect(proxiedRequest.url.toString(), 'empty-new');
      expect(await proxiedRequest.readAsString(), '');
    });

    test('should handle different HTTP methods', () async {
      final Uri originalUrl = Uri.parse('http://original.example.com/data');
      final Uri finalTargetUrl = Uri.parse('http://target.example.com/api/data');
      final methods = <String>['PUT', 'DELETE', 'PATCH', 'GET'];

      for (final method in methods) {
        final originalRequest = Request(
          method,
          originalUrl,
          body: method == 'PUT' || method == 'PATCH' ? '{"key": "value"}' : null,
        );

        final Request proxiedRequest = proxyRequest(originalRequest, finalTargetUrl);
        expect(proxiedRequest.method, method, reason: 'Method "$method" should be preserved');

        if (method == 'PUT' || method == 'PATCH') {
          expect(await proxiedRequest.readAsString(), '{"key": "value"}');
        } else {
          expect(await proxiedRequest.readAsString(), '');
        }
      }
    });
  });

  group('getFinalTargetUri', () {
    test('should add query parameters if original request does have one', () {
      final rule = RegexProxyRule(pattern: RegExp(r'^/api'), target: 'http://mock-backend.com');
      final originalRequest = Request('GET', Uri.parse('http://localhost:8000/api?foo=bar&a=b'));
      final Uri target = rule.finalTargetUri(originalRequest.requestedUri);
      expect('$target', 'http://mock-backend.com/api?foo=bar&a=b');
    });
    test('should not add empty query if original request does not have one', () {
      final rule = RegexProxyRule(pattern: RegExp(r'^/api'), target: 'http://mock-backend.com');
      final originalRequest = Request('GET', Uri.parse('http://localhost:8000/api'));
      final Uri target = rule.finalTargetUri(originalRequest.requestedUri);
      expect('$target', 'http://mock-backend.com/api');
    });
  });

  group('proxyMiddleware', () {
    test('should call inner handler if no rule matches', () async {
      final rules = <ProxyRule>[
        RegexProxyRule(pattern: RegExp(r'^/other_api'), target: 'http://mock-backend.com'),
      ];

      final Middleware middleware = proxyMiddleware(rules, logger);

      var innerHandlerCalled = false;
      FutureOr<Response> innerHandler(Request request) {
        innerHandlerCalled = true;
        return Response.ok('Inner Handler Response');
      }

      final request = Request('GET', Uri.parse('http://localhost:8080/non_matching_path'));
      final Response response = await middleware(innerHandler)(request);

      expect(innerHandlerCalled, isTrue);
      expect(response.statusCode, 200);
      expect(await response.readAsString(), 'Inner Handler Response');
    });

    test(
      'should forward 404 response from backend instead of falling back to inner handler',
      () async {
        HttpServer? mockServer;
        try {
          mockServer = await shelf_io.serve(
            (Request request) => Response.notFound(
              '{"error": "Not found"}',
              headers: {'content-type': 'application/json'},
            ),
            'localhost',
            0,
          );
          final int port = mockServer.port;

          final rules = <ProxyRule>[
            PrefixProxyRule(prefix: '/api/', target: 'http://localhost:$port/'),
          ];

          final Middleware middleware = proxyMiddleware(rules, logger);

          var innerHandlerCalled = false;
          FutureOr<Response> innerHandler(Request request) {
            innerHandlerCalled = true;
            return Response.ok('<!DOCTYPE html><html>index.html</html>');
          }

          final request = Request('GET', Uri.parse('http://localhost:8080/api/missing'));
          final Response response = await middleware(innerHandler)(request);

          expect(innerHandlerCalled, isFalse);
          expect(response.statusCode, 404);
          expect(await response.readAsString(), '{"error": "Not found"}');
        } finally {
          await mockServer?.close();
        }
      },
    );
  });
}
