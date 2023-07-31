import 'dart:async';

import 'package:process_run/cmd_run.dart';
import 'package:process_run/shell.dart';

Future main() async {
  print('dart: ${await which('dart')}');
  var dartBinVersion = await getDartBinVersion();
  print('dartBinVersion: $dartBinVersion');
  await Shell().run('dart --version');
}
