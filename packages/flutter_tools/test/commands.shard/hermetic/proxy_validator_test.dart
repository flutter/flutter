// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/proxy_validator.dart';

import '../../src/common.dart';

void main() {
  testWithoutContext('ProxyValidator does not show if HTTP_PROXY is not set', () {
    final Platform platform = FakePlatform(environment: <String, String>{});

    expect(ProxyValidator(platform: platform).shouldShow, isFalse);
  });

  testWithoutContext('ProxyValidator does not show if HTTP_PROXY is only whitespace', () {
    final Platform platform = FakePlatform(environment: <String, String>{'HTTP_PROXY': ' '});

    expect(ProxyValidator(platform: platform).shouldShow, isFalse);
  });

  testWithoutContext('ProxyValidator shows when HTTP_PROXY is set', () {
    final Platform platform = FakePlatform(environment: <String, String>{'HTTP_PROXY': 'fakeproxy.local'});

    expect(ProxyValidator(platform: platform).shouldShow, isTrue);
  });

  testWithoutContext('ProxyValidator shows when http_proxy is set', () {
    final Platform platform = FakePlatform(environment: <String, String>{'http_proxy': 'fakeproxy.local'});

    expect(ProxyValidator(platform: platform).shouldShow, isTrue);
  });

  testWithoutContext('ProxyValidator reports success when NO_PROXY is configured correctly', () async {
    final Platform platform = FakePlatform(
      environment: <String, String>{
        'HTTP_PROXY': 'fakeproxy.local',
        'NO_PROXY': 'localhost,127.0.0.1',
      },
    );
    final ValidationResult results = await ProxyValidator(platform: platform).validate();

    expect(results.messages, const <ValidationMessage>[
      ValidationMessage('HTTP_PROXY is set'),
      ValidationMessage('NO_PROXY is localhost,127.0.0.1'),
      ValidationMessage('NO_PROXY contains 127.0.0.1'),
      ValidationMessage('NO_PROXY contains localhost'),
    ]);
  });

  testWithoutContext('ProxyValidator reports success when no_proxy is configured correctly', () async {
    final Platform platform = FakePlatform(
      environment: <String, String>{
        'http_proxy': 'fakeproxy.local',
        'no_proxy': 'localhost,127.0.0.1',
      },
    );
    final ValidationResult results = await ProxyValidator(platform: platform).validate();

    expect(results.messages, const <ValidationMessage>[
      ValidationMessage('HTTP_PROXY is set'),
      ValidationMessage('NO_PROXY is localhost,127.0.0.1'),
      ValidationMessage('NO_PROXY contains 127.0.0.1'),
      ValidationMessage('NO_PROXY contains localhost'),
    ]);
  });

  testWithoutContext('ProxyValidator reports issues when NO_PROXY is missing localhost', () async {
    final Platform platform = FakePlatform(
      environment: <String, String>{
        'HTTP_PROXY': 'fakeproxy.local',
        'NO_PROXY': '127.0.0.1',
      },
    );
    final ValidationResult results = await ProxyValidator(platform: platform).validate();

    expect(results.messages, const <ValidationMessage>[
      ValidationMessage('HTTP_PROXY is set'),
      ValidationMessage('NO_PROXY is 127.0.0.1'),
      ValidationMessage('NO_PROXY contains 127.0.0.1'),
      ValidationMessage.hint('NO_PROXY does not contain localhost'),
    ]);
  });

  testWithoutContext('ProxyValidator reports issues when NO_PROXY is missing 127.0.0.1', () async {
    final Platform platform =  FakePlatform(environment: <String, String>{
      'HTTP_PROXY': 'fakeproxy.local',
      'NO_PROXY': 'localhost',
    });
    final ValidationResult results = await ProxyValidator(platform: platform).validate();

    expect(results.messages, const <ValidationMessage>[
      ValidationMessage('HTTP_PROXY is set'),
      ValidationMessage('NO_PROXY is localhost'),
      ValidationMessage.hint('NO_PROXY does not contain 127.0.0.1'),
      ValidationMessage('NO_PROXY contains localhost'),
    ]);
  });
}
