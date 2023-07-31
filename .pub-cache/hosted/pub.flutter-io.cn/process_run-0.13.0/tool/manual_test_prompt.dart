import 'dart:async';
import 'dart:io';

import 'package:process_run/shell_run.dart';

Future main() async {
  stdout.writeln('Enter 6 times some text');
  await run('dart example/echo.dart --stdin', stdin: sharedStdIn);
  await run('dart example/echo.dart --stdin', stdin: sharedStdIn);
  print(await prompt('Enter your name'));
  print(await prompt(null));
  print(await promptConfirm('Action'));
  print(await promptConfirm(null));
  await promptTerminate();
}
