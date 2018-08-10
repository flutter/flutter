library frontend_server;

import 'dart:io';

import 'package:frontend_server/server.dart';

void main(List<String> args) async {
  final int exitCode = await starter(args);
  if (exitCode != 0) {
    exit(exitCode);
  }
}
