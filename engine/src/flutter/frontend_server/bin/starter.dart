library frontend_server;

import 'dart:async';
import 'dart:io';

import 'package:frontend_server/server.dart';

Future<Null> main(List<String> args) async {
  exit(await starter(args));
}
