// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/http_host_validator.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

import '../../src/common.dart';

void main() {
  group('host validator', () {
    const String macOs = 'macos';
    const List<String> osTested = <String>['windows', 'macos', macOs];
    final Future<ValidationResult> Function(Client mockClient, String os) runHostTest
      = (Client mockClient, String os) async {
        final HttpHostValidator hostValidator = HttpHostValidator(
          platform: FakePlatform(operatingSystem: os),
          httpClient: mockClient,
        );

        return await hostValidator.validate();
    };

    bool firstResponseWithException = true;
    final Client mockClientOk = MockClient((_) async { return Response('', 200); });
    final Client mockClientError = MockClient((_) { throw const HttpException('No internet connection'); });
    final Client mockClientFirstOkRestError = MockClient((_) async {
      if (firstResponseWithException) {
        firstResponseWithException = false;
        return Response('', 200);
      } else {
        throw const HttpException('No internet connection');
      }
    });

    for(final String os in osTested) {
      testWithoutContext('$os platform all hosts are available', () async {
        final ValidationResult result = await runHostTest(mockClientOk, os);
        expect(
          result.messages.where((ValidationMessage message) => message.isHint || message.isError),
          hasLength(0)
        );
      });

      testWithoutContext('$os platform all hosts are not available', () async {
        final ValidationResult result = await runHostTest(mockClientError, os);
        expect(
          result.messages.where((ValidationMessage message) => message.isHint || message.isError),
          equals(result.messages)
        );
      });

      testWithoutContext('$os platform has only one host available', () async {
        firstResponseWithException = true;
        final ValidationResult result = await runHostTest(mockClientFirstOkRestError, os);
        expect(
          result.messages.where((ValidationMessage message) => message.isHint || message.isError),
          hasLength(os == macOs ? 3 : 2)
        );
      });
    }
  });
}
