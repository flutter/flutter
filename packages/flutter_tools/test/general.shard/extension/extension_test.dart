// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/extension/extension.dart';
import '../src/common.dart';

void main() {
  test('Request can serialize to json', () {
    const Request request = Request(0, 'hello', <String, Object>{'foo': 2});

    expect(request.toJson(), <String, Object>{
      'id': 0,
      'method': 'hello',
      'arguments': <String, Object>{
        'foo': 2,
      },
    });
  });

  test('Response can serialize to json without error', () {
    const Response request = Response(0, <String, Object>{'foo': 2});

    expect(request.toJson(), <String, Object>{
      'id': 0,
      'body': <String, Object>{
        'foo': 2,
      },
      'error': null,
    });
  });

  test('Response can serialize to json with error', () {
    const Response request = Response(0, null, <String, Object>{'foo': 2});

    expect(request.hasError, true);
    expect(request.toJson(), <String, Object>{
      'id': 0,
      'body': null,
      'error': <String, Object>{
        'foo': 2,
      },
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
