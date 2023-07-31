library process_run.src.shell_utils_io;

import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/src/shell_utils.dart';

/// Convenient way to display a command
String executableArgumentsToString(
    String? executable, List<String>? arguments) {
  final sb = StringBuffer();
  if (Platform.isWindows && (basename(executable!) == executable)) {
    var ext = extension(executable);
    switch (ext) {
      case '.exe':
      case '.bat':
      case '.cmd':
      case '.com':
        executable = executable.substring(0, executable.length - 4);
    }
  }
  sb.write(executable);
  if (arguments is List && arguments!.isNotEmpty) {
    sb.write(' ${argumentsToString(arguments)}');
  }
  return sb.toString();
}
