// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';

void main(List<String> args) {
  final ArgParser parser = ArgParser()
    ..addOption('input')
    ..addOption('output');

  final ArgResults parsedArgs = parser.parse(args);

  final String inputFilePath = parsedArgs['input'] as String;
  final String outputFilePath = parsedArgs['output'] as String;

  final String input = File(inputFilePath).readAsStringSync();
  File(outputFilePath)
    ..createSync(recursive: true)
    ..writeAsStringSync(input.toUpperCase());
}
