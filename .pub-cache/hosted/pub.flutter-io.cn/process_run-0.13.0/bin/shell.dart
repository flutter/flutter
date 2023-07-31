#!/usr/bin/env dart

import 'dart:async';

import 'package:process_run/src/bin/shell/shell.dart' as shell;

///
/// write rest arguments as lines
///
Future main(List<String> arguments) async {
  return await shell.main(arguments);
}
