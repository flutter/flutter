import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';

Future<List<FileSystemEntity>> dirContents(Directory dir, {bool recursive = false, RegExp matcher}) {
  final List<FileSystemEntity> files = <FileSystemEntity>[];
  final Completer<void> completer = Completer<void>();
  final Stream<FileSystemEntity> lister = dir.list(recursive: recursive);
  lister.listen((FileSystemEntity file) {
    if (matcher == null || matcher.hasMatch(file.uri.pathSegments.last)) {
      files.add(file);
    }
  },
      // should also register onError
      onDone: () => completer.complete(files));
  return completer.future;
}

Future<void> main(List<String> args) async {
  List<FileSystemEntity> files = await dirContents(Directory('.'), matcher: RegExp(r'.*\.dart'));
}
