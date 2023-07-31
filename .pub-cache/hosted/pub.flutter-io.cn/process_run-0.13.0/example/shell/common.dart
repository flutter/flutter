import 'package:process_run/shell.dart';

var ds = 'dart run bin/shell.dart';

var env = ShellEnvironment()..aliases['ds'] = 'dart run bin/shell.dart';
var shell = Shell(environment: env);
var commonAliases = {
  'ds': 'dart run bin/shell.dart',
  'write': 'dart run example/echo.dart --write-line',
  'prompt': 'dart run example/echo.dart --write-line --stdin'
};
