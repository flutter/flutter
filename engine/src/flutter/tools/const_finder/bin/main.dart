// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:const_finder/const_finder.dart';

void main(List<String> args) {
  final ArgParser parser = ArgParser();
  parser
    ..addSeparator('Finds constant instances of a specified class from the\n'
        'specified package, and outputs JSON like the following:')
    ..addSeparator('''
  {
    "constantInstances": [
      {
        "codePoint": 59470,
        "fontFamily": "MaterialIcons",
        "fontPackage": null,
        "matchTextDirection": false
      }
    ],
    "nonConstantInstances": [
      {
        "file": "file:///Path/to/hello_world/lib/file.dart",
        "line": 19,
        "column": 11
      }
    ]
  }''')
    ..addSeparator('Where the "constantInstances" is a list of objects containing\n'
        'the properties passed to the const constructor of the class, and\n'
        '"nonConstantInstances" is a list of source locations of non-constant\n'
        'creation of the specified class. Non-constant creation cannot be\n'
        'statically evaluated by this tool, and callers may wish to treat them\n'
        'as errors. The non-constant creation may include entries that are not\n'
        'reachable at runtime.')
    ..addSeparator('Required arguments:')
    ..addOption('kernel-file',
        valueHelp: 'path/to/main.dill',
        help: 'The path to a kernel file to parse, which was created from the '
            'main-package-uri library.')
    ..addOption('class-library-uri',
        help: 'The package: URI of the class to find.',
        valueHelp: 'package:flutter/src/widgets/icon_data.dart')
    ..addOption('class-name',
        help: 'The class name for the class to find.', valueHelp: 'IconData')
    ..addSeparator('Optional arguments:')
    ..addFlag('pretty',
        defaultsTo: false,
        negatable: false,
        help: 'Pretty print JSON output (defaults to false).')
    ..addFlag('help',
        abbr: 'h',
        defaultsTo: false,
        negatable: false,
        help: 'Print usage and exit');

  final ArgResults argResults = parser.parse(args);
  T getArg<T>(String name) => argResults[name] as T;

  if (getArg<bool>('help')) {
    stdout.writeln(parser.usage);
    exit(0);
  }

  final ConstFinder finder = ConstFinder(
    kernelFilePath: getArg<String>('kernel-file'),
    classLibraryUri: getArg<String>('class-library-uri'),
    className: getArg<String>('class-name'),
  );

  final JsonEncoder encoder = getArg<bool>('pretty')
      ? const JsonEncoder.withIndent('  ')
      : const JsonEncoder();

  stdout.writeln(encoder.convert(finder.findInstances()));
}
