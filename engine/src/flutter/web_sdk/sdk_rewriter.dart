// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

final ArgParser argParser = ArgParser()
  ..addOption('output-dir')
  ..addOption('input-dir')
  ..addFlag('ui', defaultsTo: false)
  ..addFlag('engine', defaultsTo: false)
  ..addMultiOption('input')
  ..addOption('stamp');

const List<List<String>> uiPatterns = <List<String>>[
  <String>['library ui;', 'library dart.ui;'],
  <String>['part of ui;', 'part of dart.ui;'],
  <String>[
    r'''
import 'src/engine.dart' as engine;
''',
    r'''
import 'dart:_engine' as engine;
'''
  ],
  <String>[
    r'''
export 'src/engine.dart'
''',
    r'''
export 'dart:_engine'
''',
  ],
];

const List<List<String>> enginePatterns = <List<String>>[
  <String>['library engine;', 'library dart._engine;'],
  <String>['part of engine;', 'part of dart._engine;'],
  <String>[
    r'''
import '../ui.dart' as ui;
''',
    r'''
import 'dart:ui' as ui;
'''
  ],
  <String>[
    'import \'package:js/js.dart\'',
    'import \'dart:_js_annotations\'',
  ],
];

const List<List<String>> sharedPatterns = <List<String>>[
  <String>["import 'package:meta/meta.dart';", ''],
  <String>['@required', ''],
  <String>['@protected', ''],
  <String>['@mustCallSuper', ''],
  <String>['@immutable', ''],
  <String>['@visibleForTesting', '']
];

// Rewrites the "package"-style web ui library into a dart:ui implementation.
// So far this only requires a replace of the library declarations.
void main(List<String> arguments) {
  final ArgResults results = argParser.parse(arguments);
  final Directory directory = Directory(results['output-dir']);
  final String inputDirectoryPath = results['input-dir'];
  for (String inputFilePath in results['input']) {
    final File inputFile = File(inputFilePath);
    final File outputFile = File(path.join(
        directory.path, inputFile.path.substring(inputDirectoryPath.length)))
      ..createSync(recursive: true);
    String source = inputFile.readAsStringSync();
    final List<List<String>> replacementPatterns = <List<String>>[];
    replacementPatterns.addAll(sharedPatterns);
    if (results['ui']) {
      replacementPatterns.addAll(uiPatterns);
    } else if (results['engine']) {
      replacementPatterns.addAll(enginePatterns);
    }
    for (List<String> patterns in replacementPatterns) {
      source = source.replaceAll(patterns.first, patterns.last);
    }
    outputFile.writeAsStringSync(source);
    if (results['stamp'] != null) {
      File(results['stamp']).writeAsStringSync("stamp");
    }
  }
}
