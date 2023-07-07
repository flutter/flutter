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
//    print("=" * 40);

    var path = file.path;
    if (path.isEmpty) continue;

//    if (path.startsWith(r'C:\Repo\MugalonPoker2\')) {
//      path=  path.substring(r'C:\Repo\MugalonPoker2\'.length);
//    }
//    var parts = path.split(r'\');
//    var newPath = '/Users/scheglov/tmp/analysis-driver-crash/dump/' + parts.join('/');

    var newPath = '/Users/scheglov/tmp/analysis-driver-crash/dump/'
        '${path.split(r'\').join('/')}';
    print(newPath);
    var file2 = File(newPath);
    file2.createSync(recursive: true);
    file2.writeAsStringSync(file.content);

//    print('${file.path}');
//    print("-" * 40);
//    print('${file.content}');
//    print('');
//    print('');
//    print('');
  }
}
