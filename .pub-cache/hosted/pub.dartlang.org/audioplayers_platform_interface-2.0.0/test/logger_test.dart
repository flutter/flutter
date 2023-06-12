import 'dart:async';

import 'package:audioplayers_platform_interface/api/log_level.dart';
import 'package:audioplayers_platform_interface/logger_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final _channelLogs = <String>[];
  const MethodChannel('xyz.luan/audioplayers.global')
      .setMockMethodCallHandler((MethodCall methodCall) async {
    _channelLogs.add('${methodCall.method} ${methodCall.arguments}');
    return 1;
  });

  final _print = OverridePrint();
  final _logger = GlobalPlatformInterface.instance;

  group('Logger', () {
    setUp(_print.clear);
    setUp(_channelLogs.clear);

    test(
      'when set to INFO everything is logged',
      _print.overridePrint(() {
        _logger.changeLogLevel(LogLevel.info);
        expect(_channelLogs, ['changeLogLevel {value: LogLevel.info}']);

        _logger.log(LogLevel.info, 'info');
        _logger.log(LogLevel.error, 'error');

        expect(_print.log, ['info', 'error']);
      }),
    );

    test(
      'when set to ERROR only errors are logged',
      _print.overridePrint(() {
        _logger.changeLogLevel(LogLevel.error);
        expect(_channelLogs, ['changeLogLevel {value: LogLevel.error}']);

        _logger.log(LogLevel.info, 'info');
        _logger.log(LogLevel.error, 'error');

        expect(_print.log, ['error']);
      }),
    );

    test(
      'when set to NONE nothing is logged',
      _print.overridePrint(() {
        _logger.changeLogLevel(LogLevel.none);
        expect(_channelLogs, ['changeLogLevel {value: LogLevel.none}']);

        _logger.log(LogLevel.info, 'info');
        _logger.log(LogLevel.error, 'error');

        expect(_print.log, <String>[]);
      }),
    );
  });
}

class OverridePrint {
  final log = <String>[];

  void clear() => log.clear();

  void Function() overridePrint(void Function() testFn) {
    return () {
      final spec = ZoneSpecification(
        print: (_, __, ___, String msg) {
          // Add to log instead of printing to stdout
          log.add(msg);
        },
      );
      return Zone.current.fork(specification: spec).run<void>(testFn);
    };
  }
}
