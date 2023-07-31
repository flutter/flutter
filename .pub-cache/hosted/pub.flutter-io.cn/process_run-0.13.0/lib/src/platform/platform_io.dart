import 'dart:io';

import 'package:process_run/src/shell_context_common.dart';
import 'package:process_run/src/shell_context_io.dart';

bool get platformIoIsWindows => Platform.isWindows;

/// Global shell context
ShellContext shellContext = ShellContextIo();

void clearShellContext() {
  throw StateError('clearShellContext Not supported');
}
