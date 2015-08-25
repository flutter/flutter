#!mojo mojo:dart_content_handler

library test;

import 'dart:async';
import 'dart:mojo.internal';

import 'package:mojo_services/tracing/tracing.mojom.dart' as tracing;

part 'src/part0.dart';

main(List args) {
  // Hang around for a sec and then close the shell handle.
  new Timer(new Duration(milliseconds: 1000), () {
    print('PASS');
    MojoHandleNatives.close(args[0]);
  });
}
