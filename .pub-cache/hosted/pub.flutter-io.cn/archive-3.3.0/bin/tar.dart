// Can't migrate until `package:args` is migrated.
// @dart=2.9
library archive.tar;

import 'package:archive/src/tar/tar_command.dart';

// tar --list <file>
// tar --extract <file> <dest>
// tar --create <source>
const usage = 'usage: tar [--list|--extract|--create] <file> [<dest>|<source>]';

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    fail(usage);
  }

  final command = arguments[0];
  if (command == '--list') {
    if (arguments.length < 2) {
      fail(usage);
    }
    listFiles(arguments[1]);
  } else if (command == '--extract') {
    if (arguments.length < 3) {
      fail(usage);
    }
    extractFiles(arguments[1], arguments[2]);
  } else if (command == '--create') {
    if (arguments.length < 2) {
      fail(usage);
    }
    createTarFile(arguments[1]);
  } else {
    fail(usage);
  }
}
