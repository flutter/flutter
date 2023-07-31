import 'dart:async';

import 'package:process_run/shell_run.dart';
import 'package:process_run/src/prompt.dart';

Future main() async {
  print(await prompt('Enter your name'));
  print(await promptConfirm('Action'));
  await promptTerminate();
}
