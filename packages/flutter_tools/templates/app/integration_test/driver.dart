// This file is provided as a convenience for running integration tests via the
// flutter drive command.
//
// flutter drive -t integration_test/app_test.dart --driver integration_test/driver.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

Future<void> main() async {
  final FlutterDriver driver = await FlutterDriver.connect();
  final String data = await driver.requestData(null);
  await driver.close();
  final Map<String, dynamic> result = jsonDecode(data);
  exit(result['result'] == 'true' ? 0 : 1);
}
