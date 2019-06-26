// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tool_api/doctor.dart';
import 'package:flutter_tool_api/extension.dart';
import 'package:test/test.dart';

void main() {
  group('Request', () {
    test('can serialize to json', () {
      final Request request = Request(0, 'hello', <String, Object>{'foo': 2});

      expect(request.toJson(), <String, Object>{
        'id': 0,
        'method': 'hello',
        'arguments': <String, Object>{
          'foo': 2,
        },
      });
    });
  });

  group('Response', () {
    test('can serialize to json without error', () {
      final Response request = Response(0, <String, Object>{'foo': 2});

      expect(request.toJson(), <String, Object>{
        'id': 0,
        'body': <String, Object>{
          'foo': 2,
        },
        'error': null,
      });
    });

    test('can serialize to json with error', () {
      final Response request = Response(0, null, <String, Object>{'foo': 2});

      expect(request.hasError, true);
      expect(request.toJson(), <String, Object>{
        'id': 0,
        'body': null,
        'error': <String, Object>{
          'foo': 2,
        },
      });
    });
  });

  group('ExtensionShim', () {
    ExtensionShim extensionShim;
    TestExtension testExtension;

    setUp(() {
      testExtension = TestExtension();
      extensionShim = ExtensionShim(<ToolExtension>[
        testExtension,
      ]);
    });

    test('handles nonsense method', () async {
      final Response response = await extensionShim.sendRequest('test', 'foobar');

      expect(response.hasError, true);
    });

    test('handles nonsense extensionName', () async {
      final Response response = await extensionShim.sendRequest('not defined', 'foobar');

      expect(response.hasError, true);
    });

    test('can send response to extension', () async {
      final TestDomain testDoctorDomain = testExtension.testDomain;
      expect(testDoctorDomain.received, false);

      final Response response = await extensionShim.sendRequest('test', 'example.bar');

      expect(response.hasError, false);
      expect(testDoctorDomain.received, true);
    });

    test('can handle error from extension', () async {
      final TestDomain testDoctorDomain = testExtension.testDomain;
      expect(testDoctorDomain.received, false);

      testDoctorDomain.domainHandler = (Map<String, Object> arguments) async {
        throw Exception('Something went wrong');
      };

      final Response response = await extensionShim.sendRequest('test', 'example.bar');

      expect(response.hasError, true);
      expect(testDoctorDomain.received, true);
    });

    test('can receive data from extension', () async {
      final TestDomain testDoctorDomain = testExtension.testDomain;
      expect(testDoctorDomain.received, false);

      testDoctorDomain.domainHandler = (Map<String, Object> arguments) async {
        return FakeSerializable(<String, Object>{'foo': 'bar'});
      };

      final Response response = await extensionShim.sendRequest('test', 'example.bar');

      expect(response.hasError, false);
      expect(response.body, <String, Object>{'foo': 'bar'});
      expect(testDoctorDomain.received, true);
    });
  });
}

class TestExtension extends ToolExtension {
  TestExtension() {
    registerMethod('example.bar', testDomain.example);
  }

  final TestDomain testDomain = TestDomain();

  @override
  String get name => 'test';
}

class TestDomain extends Domain {
  bool received = false;
  DomainHandler domainHandler = (Map<String, Object> arguments) async => FakeSerializable(<String, Object>{});

  Future<FakeSerializable> example(Map<String, Object> arguments) async {
    received = true;
    return domainHandler(arguments);
  }
}

class FakeSerializable extends Serializable {
  FakeSerializable(this.value);

  final Map<String, Object> value;

  @override
  Object toJson() => value;
}
