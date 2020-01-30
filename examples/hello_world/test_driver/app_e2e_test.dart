import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

Future<void> main() async {
  final FlutterDriver driver = await FlutterDriver.connect();
  final String result =
      await driver.requestData(null, timeout: const Duration(seconds: 10));
  await driver.close();
  print('result $result');
  exit(result == 'pass' ? 0 : 1);
}
