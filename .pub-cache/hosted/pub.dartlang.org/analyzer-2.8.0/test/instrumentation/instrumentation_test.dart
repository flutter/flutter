// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveTests(InstrumentationServiceTest);
  defineReflectiveTests(MulticastInstrumentationServerTest);
}

@reflectiveTest
class InstrumentationServiceTest {
  void assertNormal(
      TestInstrumentationLogger logger, String tag, String message) {
    String sent = logger.logged.toString();
    if (!sent.endsWith(':$tag:$message\n')) {
      fail('Expected "...:$tag:$message", found "$sent"');
    }
  }

  void test_logError_withColon() {
    TestInstrumentationLogger logger = TestInstrumentationLogger();
    InstrumentationService service = InstrumentationLogAdapter(logger);
    service.logError('Error:message');
    assertNormal(logger, InstrumentationLogAdapter.TAG_ERROR, 'Error::message');
  }

  void test_logError_withLeadingColon() {
    TestInstrumentationLogger logger = TestInstrumentationLogger();
    InstrumentationService service = InstrumentationLogAdapter(logger);
    service.logError(':a:bb');
    assertNormal(logger, InstrumentationLogAdapter.TAG_ERROR, '::a::bb');
  }

  void test_logError_withoutColon() {
    TestInstrumentationLogger logger = TestInstrumentationLogger();
    InstrumentationService service = InstrumentationLogAdapter(logger);
    String message = 'Error message';
    service.logError(message);
    assertNormal(logger, InstrumentationLogAdapter.TAG_ERROR, message);
  }

  void test_logException_noTrace() {
    TestInstrumentationLogger logger = TestInstrumentationLogger();
    InstrumentationService service = InstrumentationLogAdapter(logger);
    String message = 'exceptionMessage';
    service.logException(message);
    assertNormal(
        logger, InstrumentationLogAdapter.TAG_EXCEPTION, '$message:null');
  }

  void test_logLogEntry() {
    TestInstrumentationLogger logger = TestInstrumentationLogger();
    InstrumentationService service = InstrumentationLogAdapter(logger);
    String level = 'level';
    DateTime time = DateTime(2001);
    String message = 'message';
    String exception = 'exception';
    String stackTraceText = 'stackTrace';
    StackTrace stackTrace = StackTrace.fromString(stackTraceText);
    service.logLogEntry(level, time, message, exception, stackTrace);
    assertNormal(logger, InstrumentationLogAdapter.TAG_LOG_ENTRY,
        '$level:${time.millisecondsSinceEpoch}:$message:$exception:$stackTraceText');
  }

  void test_logNotification() {
    TestInstrumentationLogger logger = TestInstrumentationLogger();
    InstrumentationService service = InstrumentationLogAdapter(logger);
    String message = 'notificationText';
    service.logNotification(message);
    assertNormal(logger, InstrumentationLogAdapter.TAG_NOTIFICATION, message);
  }

  void test_logPluginError() {
    TestInstrumentationLogger logger = TestInstrumentationLogger();
    InstrumentationService service = InstrumentationLogAdapter(logger);
    PluginData plugin = PluginData('path', 'name', 'version');
    String code = 'code';
    String message = 'exceptionMessage';
    String stackTraceText = 'stackTrace';
    service.logPluginError(plugin, code, message, stackTraceText);
    assertNormal(logger, InstrumentationLogAdapter.TAG_PLUGIN_ERROR,
        '$code:$message:$stackTraceText:path:name:version');
  }

  void test_logPluginException_noTrace() {
    TestInstrumentationLogger logger = TestInstrumentationLogger();
    InstrumentationService service = InstrumentationLogAdapter(logger);
    PluginData plugin = PluginData('path', 'name', 'version');
    String message = 'exceptionMessage';
    service.logPluginException(plugin, message, null);
    assertNormal(logger, InstrumentationLogAdapter.TAG_PLUGIN_EXCEPTION,
        '$message:null:path:name:version');
  }

  void test_logPluginException_withTrace() {
    TestInstrumentationLogger logger = TestInstrumentationLogger();
    InstrumentationService service = InstrumentationLogAdapter(logger);
    PluginData plugin = PluginData('path', 'name', 'version');
    String message = 'exceptionMessage';
    String stackTraceText = 'stackTrace';
    StackTrace stackTrace = StackTrace.fromString(stackTraceText);
    service.logPluginException(plugin, message, stackTrace);
    assertNormal(logger, InstrumentationLogAdapter.TAG_PLUGIN_EXCEPTION,
        '$message:$stackTraceText:path:name:version');
  }

  void test_logPluginNotification() {
    TestInstrumentationLogger logger = TestInstrumentationLogger();
    InstrumentationService service = InstrumentationLogAdapter(logger);
    String notification = 'notification';
    service.logPluginNotification('path', notification);
    assertNormal(logger, InstrumentationLogAdapter.TAG_PLUGIN_NOTIFICATION,
        '$notification:path::');
  }

  void test_logPluginRequest() {
    TestInstrumentationLogger logger = TestInstrumentationLogger();
    InstrumentationService service = InstrumentationLogAdapter(logger);
    String request = 'request';
    service.logPluginRequest('path', request);
    assertNormal(logger, InstrumentationLogAdapter.TAG_PLUGIN_REQUEST,
        '$request:path::');
  }

  void test_logPluginResponse() {
    TestInstrumentationLogger logger = TestInstrumentationLogger();
    InstrumentationService service = InstrumentationLogAdapter(logger);
    String response = 'response';
    service.logPluginResponse('path', response);
    assertNormal(logger, InstrumentationLogAdapter.TAG_PLUGIN_RESPONSE,
        '$response:path::');
  }

  void test_logPluginTimeout() {
    TestInstrumentationLogger logger = TestInstrumentationLogger();
    InstrumentationService service = InstrumentationLogAdapter(logger);
    PluginData plugin = PluginData('path', 'name', 'version');
    String request = 'request';
    service.logPluginTimeout(plugin, request);
    assertNormal(logger, InstrumentationLogAdapter.TAG_PLUGIN_TIMEOUT,
        '$request:path:name:version');
  }

  void test_logRequest() {
    TestInstrumentationLogger logger = TestInstrumentationLogger();
    InstrumentationService service = InstrumentationLogAdapter(logger);
    String message = 'requestText';
    service.logRequest(message);
    assertNormal(logger, InstrumentationLogAdapter.TAG_REQUEST, message);
  }

  void test_logResponse() {
    TestInstrumentationLogger logger = TestInstrumentationLogger();
    InstrumentationService service = InstrumentationLogAdapter(logger);
    String message = 'responseText';
    service.logResponse(message);
    assertNormal(logger, InstrumentationLogAdapter.TAG_RESPONSE, message);
  }

  void test_logVersion() {
    TestInstrumentationLogger logger = TestInstrumentationLogger();
    InstrumentationService service = InstrumentationLogAdapter(logger);
    service.logVersion('myUuid', 'someClientId', 'someClientVersion',
        'aServerVersion', 'anSdkVersion');
    expect(
        logger.logged.toString(),
        endsWith(
            ':myUuid:someClientId:someClientVersion:aServerVersion:anSdkVersion\n'));
  }
}

@reflectiveTest
class MulticastInstrumentationServerTest {
  TestInstrumentationLogger loggerA = TestInstrumentationLogger();
  TestInstrumentationLogger loggerB = TestInstrumentationLogger();
  late final MulticastInstrumentationService logger;

  void setUp() {
    logger = MulticastInstrumentationService([
      InstrumentationLogAdapter(loggerA),
      InstrumentationLogAdapter(loggerB)
    ]);
  }

  void test_log() {
    logger.logInfo('foo bar');
    _assertLogged(loggerA, 'foo bar');
    _assertLogged(loggerB, 'foo bar');
  }

  void _assertLogged(TestInstrumentationLogger logger, String message) {
    String sent = logger.logged.toString();
    if (!sent.endsWith('$message\n')) {
      fail('Expected "...$message", found "$sent"');
    }
  }
}

class TestInstrumentationLogger implements InstrumentationLogger {
  StringBuffer logged = StringBuffer();

  @override
  void log(String message) {
    logged.writeln(message);
  }

  @override
  Future<void> shutdown() async {}
}
