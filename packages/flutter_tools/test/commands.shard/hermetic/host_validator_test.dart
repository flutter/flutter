// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/host_validator.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

import '../../src/common.dart';

void main() {
  group('host validator', () {
    const List<String> osTested = <String>['windows', 'macos', 'linux'];
    final Future<ValidationResult> Function(Client mockClient, String os) runHostTest
      = (Client mockClient, String os) async {
        final HostValidator hostValidator = HostValidator(
          platform: FakePlatform(operatingSystem: os),
          httpClient: mockClient,
        );

        return await hostValidator.validate();
    };

    final Future<List<ValidationResult>> Function(Client mockClient, List<String> osList) runAllTestCases
      = (Client mockClient, List<String> osList) async {
        final Iterable<Future<ValidationResult>> validatorResultsFutures =
          osList.map((String os) => runHostTest(mockClient, os));

        return (await Future.wait(validatorResultsFutures)).toList();
    };

    test('all the hosts are available', () async {
      final Client mockClient = MockClient((_) async {
        return Response('', 200);
      });

      final List<ValidationResult> validatorResults = await runAllTestCases(mockClient, osTested);

      // check that for each platform scenario the tests return expected values
      for(final ValidationResult result in validatorResults) {
        expect(result.messages..removeWhere(
                (ValidationMessage message) => !message.isHint && !message.isError
        ), hasLength(0));
      }
    });

    test('all the hosts are not available', () async {
      final Client mockClient = MockClient((_) async {
        throw Exception('No internet connection');
      });

      final List<ValidationResult> validatorResults = await runAllTestCases(mockClient, osTested);

      // check that for each platform scenario the tests return expected values
      for(final ValidationResult result in validatorResults) {
        expect(result.messages..removeWhere(
                (ValidationMessage message) => !message.isHint && !message.isError
        ), equals(result.messages));
      }
    });

    test('one host is not available', () async {
      bool firstResponseWithException = false;
      final Client mockClient = MockClient((_) async {
        if (firstResponseWithException) {
          return Response('', 200);
        } else {
          firstResponseWithException = true;
          throw Exception('No internet connection');
        }
      });

      final List<ValidationResult> validatorResults = await runAllTestCases(mockClient, osTested);

      for(final ValidationResult result in validatorResults) {
        expect(result.messages..removeWhere(
                (ValidationMessage message) => !message.isHint && !message.isError
        ), hasLength(1));
      }
    });
  });
}
