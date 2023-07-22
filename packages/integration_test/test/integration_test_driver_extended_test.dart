// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test_driver_extended.dart';
import 'package:webdriver/sync_io.dart';

void main() {
  group('integrationDriver', () {
    late FakeFlutterWebConnection fakeConnection;
    late WebFlutterDriver driver;
    late bool called;
    late int exitCode;

    setUpAll(() {
      fakeConnection = FakeFlutterWebConnection();
      driver = WebFlutterDriver.connectedTo(fakeConnection);
      exitFn = (int code) => exitCode = code;
    });

    setUp(() {
      called = false;
      exitCode = -1;
    });

    test('write response data when all test pass', () async {
      fakeConnection.fakeResponse = '''
{
  "isError": false,
  "response": {
    "message": "{\\"result\\": \\"true\\", \\"data\\": {\\"reports\\": \\"passed\\"}}"
  }
}
''';

      await integrationDriver(
        driver: driver,
        responseDataCallback: (_) {
          called = true;
        },
      );
      expect(called, true);
      expect(exitCode, 0);
    });
    test(
        'write response data when test fail and writeResponseOnFailure is true',
        () async {
      fakeConnection.fakeResponse = '''
{
  "isError": false,
  "response": {
    "message": "{\\"result\\": \\"false\\", \\"failureDetails\\": [],\\"data\\": {\\"reports\\": \\"failed\\"}}"
  }
}
''';

      await integrationDriver(
        driver: driver,
        responseDataCallback: (_) {
          called = true;
        },
        writeResponseOnFailure: true,
      );
      expect(called, true);
      expect(exitCode, 1);
    });
    test(
        'do not write response data when test fail and writeResponseOnFailure is false',
        () async {
      fakeConnection.fakeResponse = '''
{
  "isError": false,
  "response": {
    "message": "{\\"result\\": \\"false\\", \\"failureDetails\\": [],\\"data\\": {\\"reports\\": \\"failed\\"}}"
  }
}
''';

      await integrationDriver(
        driver: driver,
        responseDataCallback: (_) {
          called = true;
        },
        writeResponseOnFailure: false,
      );
      expect(called, false);
      expect(exitCode, 1);
    });
  });
}

class FakeFlutterWebConnection implements FlutterWebConnection {
  @override
  bool supportsTimelineAction = false;

  @override
  Future<void> close() async {}

  @override
  Stream<LogEntry> get logs => throw UnimplementedError();

  @override
  Future<List<int>> screenshot() {
    throw UnimplementedError();
  }

  Object? fakeResponse;
  Error? communicationError;

  @override
  Future<Object?> sendCommand(String script, Duration? duration) async {
    if (communicationError != null) {
      throw communicationError!;
    }
    return fakeResponse;
  }
}
