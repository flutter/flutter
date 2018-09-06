// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library flutter_frontend_server;

import 'dart:async';
import 'dart:io' hide FileSystemEntity;

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'package:flutter_kernel_transformers/track_widget_constructor_locations.dart';
import 'package:vm/incremental_compiler.dart';
import 'package:vm/frontend_server.dart' as frontend show FrontendCompiler,
    CompilerInterface, listenAndCompile, argParser, usage;

/// Wrapper around [FrontendCompiler] that adds [widgetCreatorTracker] kernel
/// transformation to the compilation.
class _FlutterFrontendCompiler implements frontend.CompilerInterface{
  final frontend.CompilerInterface _compiler;

  _FlutterFrontendCompiler(StringSink output, {bool trackWidgetCreation: false}):
      _compiler = new frontend.FrontendCompiler(output,
          transformer: trackWidgetCreation ? new WidgetCreatorTracker() : null);

  @override
  Future<bool> compile(String filename, ArgResults options, {IncrementalCompiler generator}) async {
    return _compiler.compile(filename, options, generator: generator);
  }

  @override
  Future<Null> recompileDelta({String filename}) async {
    return _compiler.recompileDelta(filename: filename);
  }

  @override
  void acceptLastDelta() {
    _compiler.acceptLastDelta();
  }

  @override
  Future<Null> rejectLastDelta() async {
    return _compiler.rejectLastDelta();
  }

  @override
  void invalidate(Uri uri) {
    _compiler.invalidate(uri);
  }

  @override
  Future<Null> compileExpression(
      String expression,
      List<String> definitions,
      List<String> typeDefinitions,
      String libraryUri,
      String klass,
      bool isStatic) {
    return _compiler.compileExpression(expression, definitions, typeDefinitions,
        libraryUri, klass, isStatic);
  }

  @override
  void reportError(String msg) {
    _compiler.reportError(msg);
  }

  @override
  void resetIncrementalCompiler() {
    _compiler.resetIncrementalCompiler();
  }
}

/// Entry point for this module, that creates `_FrontendCompiler` instance and
/// processes user input.
/// `compiler` is an optional parameter so it can be replaced with mocked
/// version for testing.
Future<int> starter(
    List<String> args, {
      _FlutterFrontendCompiler compiler,
      Stream<List<int>> input,
      StringSink output,
    }) async {
  ArgResults options;
  frontend.argParser
    ..addFlag('track-widget-creation',
      help: 'Run a kernel transformer to track creation locations for widgets.',
      defaultsTo: false);

  try {
    options = frontend.argParser.parse(args);
  } catch (error) {
    print('ERROR: $error\n');
    print(frontend.usage);
    return 1;
  }

  if (options['train']) {
    final String sdkRoot = options['sdk-root'];
    final Directory temp = Directory.systemTemp.createTempSync('train_frontend_server');
    try {
      final String outputTrainingDill = path.join(temp.path, 'app.dill');
      options = frontend.argParser.parse(<String>[
        '--incremental',
        '--sdk-root=$sdkRoot',
        '--output-dill=$outputTrainingDill',
        '--target=flutter']);
      compiler ??= new _FlutterFrontendCompiler(output, trackWidgetCreation: true);

      await compiler.compile(Platform.script.toFilePath(), options);
      compiler.acceptLastDelta();
      await compiler.recompileDelta();
      compiler.acceptLastDelta();
      compiler.resetIncrementalCompiler();
      await compiler.recompileDelta();
      compiler.acceptLastDelta();
      await compiler.recompileDelta();
      compiler.acceptLastDelta();
      return 0;
    } finally {
      temp.deleteSync(recursive: true);
    }
  }

  compiler ??= new _FlutterFrontendCompiler(output, trackWidgetCreation: options['track-widget-creation']);

  if (options.rest.isNotEmpty) {
    return await compiler.compile(options.rest[0], options) ? 0 : 254;
  }

  final Completer<int> completer = new Completer<int>();
  frontend.listenAndCompile(compiler, input ?? stdin, options, completer);
  return completer.future;
}
