// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/host_validator.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:platform/platform.dart';

import '../../src/common.dart';

void main() {
  group('host validator', () {
    test('all the hosts are available on windows', () async {
      final Client mockClient = MockClient((_) async {
        return Response('', 200);
      });
      final HostValidator hostValidator = HostValidator(
        platform: FakePlatform(operatingSystem: 'windows'),
        httpClient: mockClient,
      );

      final ValidationResult validatorResult = await hostValidator.validate();
      expect(validatorResult.messages..removeWhere(
              // remove every information message
              (ValidationMessage msg) => !msg.isHint && !msg.isError),
          hasLength(0));
    });

    test('all the hosts are not available on macOS', () async {
      final Client mockClient = MockClient((_) async {
        throw Exception('No internet connection');
      });
      final HostValidator hostValidator = HostValidator(
        platform: FakePlatform(operatingSystem: 'macos'),
        httpClient: mockClient,
      );

      final ValidationResult validatorResult = await hostValidator.validate();
      expect(validatorResult.messages.toList()..removeWhere(
              // remove every information message
              (ValidationMessage msg) => !msg.isHint && !msg.isError),
          equals(validatorResult.messages));
    });

    test('one host is not available on linux', () async {
      bool firstResponseWithException = false;
      final Client mockClient = MockClient((_) async {
        if (firstResponseWithException) {
          return Response('', 200);
        } else {
          firstResponseWithException = true;
          throw Exception('No internet connection');
        }
      });
      final HostValidator hostValidator = HostValidator(
        platform: FakePlatform(operatingSystem: 'linux'),
        httpClient: mockClient,
      );

      final ValidationResult validatorResult = await hostValidator.validate();
      expect(validatorResult.messages..removeWhere(
              // remove every information message
              (ValidationMessage msg) => !msg.isHint && !msg.isError),
          hasLength(1));
    });
  });
}
