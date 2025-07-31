// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/isolated/proxy_middleware.dart';
import 'package:flutter_tools/src/web/devfs_proxy.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../src/testbed.dart';

void main() {
  late TestBed testbed;
  setUp(() {
    testbed = TestBed();
  });

  group('ProxyRule.fromYaml', () {
    test(
      'should create PrefixProxyRule with prefix and no replacement',
      () => testbed.run(() {
        final yaml =
            loadYaml('''
          target: http://localhost:8080
          prefix: /api
        ''')
                as YamlMap;
        final ProxyRule? rule = ProxyRule.fromYaml(yaml);

        expect(rule, isA<PrefixProxyRule>());
        expect((rule! as PrefixProxyRule).prefix, '/api');
        expect(rule.target, 'http://localhost:8080');
      }),
    );

    test(
      'should create PrefixProxyRule with prefix and replacement',
      () => testbed.run(() {
        final yaml =
            loadYaml('''
          target: http://localhost:8080
          prefix: /api
          replace: /new_api
        ''')
                as YamlMap;
        final ProxyRule? rule = ProxyRule.fromYaml(yaml);

        expect(rule, isA<PrefixProxyRule>());
        expect((rule! as PrefixProxyRule).prefix, '/api');
        expect(rule.target, 'http://localhost:8080');
        expect(rule.replace('/api/users'), '/new_api/users');
        expect(rule.replace('/api/'), '/new_api/');
        expect(rule.replace('/other'), '/other');
      }),
    );

    test(
      'should create RegexProxyRule with regex and no replacement',
      () => testbed.run(() {
        final yaml =
            loadYaml(r'''
          target: http://localhost:8081
          regex: ^/users/(\d+)
        ''')
                as YamlMap;
        final ProxyRule? rule = ProxyRule.fromYaml(yaml);

        expect(rule, isA<RegexProxyRule>());
        expect((rule! as RegexProxyRule).pattern.pattern, r'^/users/(\d+)');
        expect(rule.target, 'http://localhost:8081');
      }),
    );

    test(
      'should create RegexProxyRule with regex and replacement using capturing groups',
      () => testbed.run(() {
        final yaml =
            loadYaml(r'''
          target: http://localhost:8081/user-service
          regex: ^/users/(\d+)/profile(.*)
          replace: /user-info/$1/details$2
        ''')
                as YamlMap;
        final ProxyRule? rule = ProxyRule.fromYaml(yaml);
        expect(rule, isA<RegexProxyRule>());
        expect(rule!.replace('/users/456/profile/summary'), '/user-info/456/details/summary');
        expect(rule.replace('/users/789/profile'), '/user-info/789/details');
        expect(rule.replace('/other/path'), '/other/path');
      }),
    );

    test(
      'should create RegexProxyRule with regex and empty replacement',
      () => testbed.run(() {
        final yaml =
            loadYaml(r'''
          target: http://localhost:8081/user-service
          regex: ^/users/\d+/profile
          replace: ''
        ''')
                as YamlMap;
        final ProxyRule? rule = ProxyRule.fromYaml(yaml);
        expect(rule, isA<RegexProxyRule>());
        expect(rule!.replace('/users/456/profile'), '');
        expect(rule.replace('/users/789/profile/summary'), '/summary');
      }),
    );

    test(
      'should handle invalid regex key gracefully and fall back to RegexProxyRule using escaped string',
      () => testbed.run(() {
        final yaml =
            loadYaml('''
          target: http://localhost:8082
          regex: ^/invalid(
        ''')
                as YamlMap;
        final ProxyRule? rule = ProxyRule.fromYaml(yaml, logger: globals.logger);

        expect(rule, isA<RegexProxyRule>());
        expect((rule! as RegexProxyRule).pattern.pattern, r'\^/invalid\(');
        expect(rule.target, 'http://localhost:8082');
      }),
    );

    test(
      'should return null if target is missing',
      () => testbed.run(() {
        final yaml =
            loadYaml('''
          prefix: /api
        ''')
                as YamlMap;
        final ProxyRule? rule = ProxyRule.fromYaml(yaml, logger: globals.logger);

        expect(rule, isNull);
      }),
    );

    test(
      'should return null if neither prefix nor regex is provided',
      () => testbed.run(() {
        final yaml =
            loadYaml('''
          target: http://localhost:8080
        ''')
                as YamlMap;
        final ProxyRule? rule = ProxyRule.fromYaml(yaml, logger: globals.logger);

        expect(rule, isNull);
      }),
    );
  });

  group('RegexProxyRule', () {
    final ruleNoReplacement = RegexProxyRule(
      pattern: RegExp(r'^/users/(\d+)'),
      target: 'http://example.com',
    );

    final ruleWithCapturingGroupReplacement = RegexProxyRule(
      pattern: RegExp(r'^/api/v1/users/(\d+)(.*)'),
      target: 'http://backend.com',
      replacement: r'/$1/profile$2',
    );

    final rulePrefixRemovalReplacement = RegexProxyRule(
      pattern: RegExp(r'^/old_path'),
      target: 'http://legacy.com',
      replacement: '/new_path',
    );
    final ruleMiddlePattern = RegexProxyRule(
      pattern: RegExp(r'/test_static'),
      target: 'http://static.com',
      replacement: '/assets',
    );

    final ruleExactMatch = RegexProxyRule(
      pattern: RegExp(r'^/exact_match_only$'),
      target: 'http://exact.com',
      replacement: '/found',
    );
    final ruleZeroGroup = RegexProxyRule(
      pattern: RegExp(r'^/prefix/(.*)'),
      target: 'http://test.com',
      replacement: r'/all$0',
    );

    test('matches should return true for matching regex', () {
      expect(ruleNoReplacement.matches('/users/123'), isTrue);
      expect(
        ruleWithCapturingGroupReplacement.matches('/api/v1/users/456/profile/details'),
        isTrue,
      );
      expect(rulePrefixRemovalReplacement.matches('/old_path/resource'), isTrue);
      expect(ruleMiddlePattern.matches('hello/test_static/image.png'), isTrue);
      expect(ruleExactMatch.matches('/exact_match_only'), isTrue);
      expect(ruleZeroGroup.matches('/prefix/prefix'), isTrue);
    });

    test('matches should return false for non-matching regex', () {
      expect(ruleWithCapturingGroupReplacement.matches('/api/v2/users/123'), isFalse);
      expect(rulePrefixRemovalReplacement.matches('/hello/old_path/resource'), isFalse);
      expect(ruleExactMatch.matches('/exact_match_only/suffix'), isFalse);
    });

    test('replace should apply replacement with capturing groups correctly', () {
      expect(
        ruleWithCapturingGroupReplacement.replace('/api/v1/users/789/profile/summary'),
        '/789/profile/profile/summary',
      );
      expect(ruleWithCapturingGroupReplacement.replace('/api/v1/users/100'), '/100/profile');
    });

    test('replace should apply prefix removal replacement', () {
      expect(
        rulePrefixRemovalReplacement.replace('/old_path/resource/data'),
        '/new_path/resource/data',
      );
      expect(rulePrefixRemovalReplacement.replace('/old_path'), '/new_path');
    });

    test('replace should match exactly', () {
      final rule = RegexProxyRule(
        pattern: RegExp(r'/temp1'),
        target: 'http://legacy.com',
        replacement: '/temp2/',
      );
      expect(rule.replace('/temp1/careful/double/slashes'), '/temp2//careful/double/slashes');
      expect(
        rulePrefixRemovalReplacement.replace('/old_pathname/resource/data'),
        '/new_pathname/resource/data',
      );
    });

    test('replace should replace all occurences', () {
      expect(ruleMiddlePattern.replace('/test_static/test_static/data'), '/assets/assets/data');
    });

    test('replace should handle regex with no capturing groups in pattern', () {
      expect(
        ruleMiddlePattern.replace('hello/test_static/document.pdf'),
        'hello/assets/document.pdf',
      );
    });

    test(r'replace should handle $0 (entire match)', () {
      expect(ruleZeroGroup.replace('/prefix/something/else'), '/all/prefix/something/else');
    });

    test('replace should handle non-matching path gracefully', () {
      expect(ruleWithCapturingGroupReplacement.replace('/non/matching/path'), '/non/matching/path');
    });

    test('toString provides useful debug information', () {
      expect(
        ruleNoReplacement.toString(),
        r'{pattern: ^/users/(\d+), target: http://example.com, replace: null}',
      );
      expect(
        rulePrefixRemovalReplacement.toString(),
        '{pattern: ^/old_path, target: http://legacy.com, replace: /new_path}',
      );
    });
  });

  group('PrefixProxyRule', () {
    final ruleNoReplacement = PrefixProxyRule(prefix: '/assets/', target: 'http://cdn.example.com');

    final ruleWithReplacement = PrefixProxyRule(
      prefix: '/old-assets/',
      target: 'http://cdn.example.com',
      replacement: '/new-assets/',
    );

    final ruleEmptyReplacement = PrefixProxyRule(
      prefix: '/remove-me/',
      target: 'http://cdn.example.com',
      replacement: '',
    );
    final ruleSlashReplacement = PrefixProxyRule(
      prefix: '/remove-me-too',
      target: 'http://cdn.example.com',
      replacement: '/',
    );

    test('matches should return true for matching prefix', () {
      expect(ruleNoReplacement.matches('/assets/image.png'), isTrue);
      expect(ruleWithReplacement.matches('/old-assets/script.js'), isTrue);
      expect(ruleEmptyReplacement.matches('/remove-me/now'), isTrue);
      expect(ruleSlashReplacement.matches('/remove-me-too-please'), isTrue);
      expect(ruleSlashReplacement.matches('/remove-me-too/please'), isTrue);
    });

    test('matches should return false for non-matching prefix', () {
      expect(ruleNoReplacement.matches('/data/assets/image.png'), isFalse);
      expect(ruleWithReplacement.matches('/old/assets/script.js'), isFalse);
      expect(ruleWithReplacement.matches('/old-assets-prefix/script.js'), isFalse);
      expect(ruleSlashReplacement.matches('remove-me-too/please'), isFalse);
    });

    test('replace should apply replacement for matching prefix', () {
      expect(ruleWithReplacement.replace('/old-assets/style.css'), '/new-assets/style.css');
      expect(ruleWithReplacement.replace('/old-assets/'), '/new-assets/');
    });

    test('replace should handle empty replacement string', () {
      expect(ruleEmptyReplacement.replace('/remove-me/file.txt'), 'file.txt');
      expect(ruleEmptyReplacement.replace('/remove-me/'), '');
    });

    test('replace should handle slash replacement string', () {
      expect(ruleSlashReplacement.replace('/remove-me-too'), '/');
    });

    test('replace should only replace first occurence', () {
      expect(
        ruleWithReplacement.replace('/old-assets/old-assets/style.css'),
        '/new-assets/old-assets/style.css',
      );
      expect(ruleSlashReplacement.replace('/remove-me-too/remove-me-too/'), '//remove-me-too/');
    });

    test('replace should return original path for non-matching prefix', () {
      expect(ruleWithReplacement.replace('/other-path/file.txt'), '/other-path/file.txt');
    });
    test('toString provides useful debug information', () {
      expect(
        ruleNoReplacement.toString(),
        '{prefix: /assets/, target: http://cdn.example.com, replace: null}',
      );
      expect(
        ruleWithReplacement.toString(),
        '{prefix: /old-assets/, target: http://cdn.example.com, replace: /new-assets/}',
      );
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

  group('proxyMiddleware', () {
    test('should call inner handler if no rule matches', () async {
      final rules = <ProxyRule>[
        RegexProxyRule(pattern: RegExp(r'^/other_api'), target: 'http://mock-backend.com'),
      ];

      final Middleware middleware = proxyMiddleware(rules);

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
  });
}
