// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/summary/idl.dart';
import 'package:args/args.dart';

main(List<String> args) {
  ArgParser argParser = ArgParser()..addFlag('raw');
  ArgResults argResults = argParser.parse(args);
  if (argResults.rest.length != 1) {
    print(argParser.usage);
    exitCode = 1;
    return;
  }

  String path = argResults.rest[0];
  List<int> bytes = File(path).readAsBytesSync();
  AnalysisDriverExceptionContext context =
      AnalysisDriverExceptionContext.fromBuffer(bytes);

  print(context.path);
  print('');
  print('');
  print('');

  print(context.exception);
  print('');
  print('');
  print('');

  print(context.stackTrace);
  print('');
  print('');
  print('');

  for (var file in context.files) {
    print("=" * 40);
    print(file.path);
    print("-" * 40);
    print(file.content);
    print('');
    print('');
    print('');
  }
}
