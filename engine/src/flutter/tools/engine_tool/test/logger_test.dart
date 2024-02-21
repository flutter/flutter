// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:engine_tool/src/logger.dart';
import 'package:litetest/litetest.dart';
import 'package:logging/logging.dart' as log;

void main() {
  List<String> stringsFromLogs(List<log.LogRecord> logs) {
    return logs.map((log.LogRecord r) => r.message).toList();
  }

  test('Setting the level works', () {
    final Logger logger = Logger.test();
    logger.level = Logger.infoLevel;
    expect(logger.level, equals(Logger.infoLevel));
  });

  test('error messages are recorded at the default log level', () {
    final Logger logger = Logger.test();
    logger.error('Error');
    expect(stringsFromLogs(logger.testLogs), equals(<String>['Error\n']));
  });

  test('warning messages are recorded at the default log level', () {
    final Logger logger = Logger.test();
    logger.warning('Warning');
    expect(stringsFromLogs(logger.testLogs), equals(<String>['Warning\n']));
  });

  test('status messages are recorded at the default log level', () {
    final Logger logger = Logger.test();
    logger.status('Status');
    expect(stringsFromLogs(logger.testLogs), equals(<String>['Status\n']));
  });

  test('info messages are not recorded at the default log level', () {
    final Logger logger = Logger.test();
    logger.info('info');
    expect(stringsFromLogs(logger.testLogs), equals(<String>[]));
  });

  test('info messages are recorded at the infoLevel log level', () {
    final Logger logger = Logger.test();
    logger.level = Logger.infoLevel;
    logger.info('info');
    expect(stringsFromLogs(logger.testLogs), equals(<String>['info\n']));
  });

  test('indent indents the message', () {
    final Logger logger = Logger.test();
    logger.status('Status', indent: 1);
    expect(stringsFromLogs(logger.testLogs), equals(<String>[' Status\n']));
  });

  test('newlines in error() can be disabled', () {
    final Logger logger = Logger.test();
    logger.error('Error', newline: false);
    expect(stringsFromLogs(logger.testLogs), equals(<String>['Error']));
  });

  test('newlines in warning() can be disabled', () {
    final Logger logger = Logger.test();
    logger.warning('Warning', newline: false);
    expect(stringsFromLogs(logger.testLogs), equals(<String>['Warning']));
  });

  test('newlines in status() can be disabled', () {
    final Logger logger = Logger.test();
    logger.status('Status', newline: false);
    expect(stringsFromLogs(logger.testLogs), equals(<String>['Status']));
  });

  test('newlines in info() can be disabled', () {
    final Logger logger = Logger.test();
    logger.level = Logger.infoLevel;
    logger.info('info', newline: false);
    expect(stringsFromLogs(logger.testLogs), equals(<String>['info']));
  });
}
