import 'dart:io';
import 'dart:async';
import 'dart:core';

import 'package:logging/logging.dart';

import 'flutter_fuchsia.dart';

Future<Null> main(List<String> args) async {
  // Sets up a basic logger to see what's happening.
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('[${rec.level.name}] -- ${rec.time}: ${rec.message}');
  });
  List<FlutterView> views =
      await getFlutterViews('192.168.42.62', '../../', 'release-x86-64');
  print(views);

  // Program hangs here, so force an exit.
  exit(0);
}
