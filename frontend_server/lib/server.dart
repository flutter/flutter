// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library frontend_server;

import 'dart:async';
import 'dart:convert';
import 'dart:io' hide FileSystemEntity;

import 'package:args/args.dart';
// front_end/src imports below that require lint `ignore_for_file`
// are a temporary state of things until frontend team builds better api
// that would replace api used below. This api was made private in
// an effort to discourage further use.
// ignore_for_file: implementation_imports
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/file_system.dart' show FileSystemEntity;
import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/binary/limited_ast_to_binary.dart';
import 'package:kernel/kernel.dart' show Program, loadProgramFromBytes;
import 'package:kernel/target/flutter.dart';
import 'package:kernel/target/targets.dart';
import 'package:path/path.dart' as path;
import 'package:usage/uuid/uuid.dart';
import 'package:vm/incremental_compiler.dart' show IncrementalCompiler;
import 'package:vm/kernel_front_end.dart' show compileToKernel;

import 'package:flutter_kernel_transformers/track_widget_constructor_locations.dart';

ArgParser _argParser = new ArgParser(allowTrailingOptions: true)
  ..addFlag('train',
      help: 'Run through sample command line to produce snapshot',
      negatable: false)
  ..addFlag('incremental',
      help: 'Run compiler in incremental mode', defaultsTo: false)
  ..addOption('sdk-root',
      help: 'Path to sdk root',
      defaultsTo: '../../out/android_debug/flutter_patched_sdk')
  ..addFlag('aot',
      help: 'Run compiler in AOT mode (enables whole-program transformations)',
      defaultsTo: false)
  ..addFlag('strong',
      help: 'Run compiler in strong mode (uses strong mode semantics)',
      defaultsTo: false)
  ..addFlag('link-platform',
      help:
          'When in batch mode, link platform kernel file into result kernel file.'
          ' Intended use is to satisfy different loading strategies implemented'
          ' by gen_snapshot(which needs platform embedded) vs'
          ' Flutter engine(which does not)',
      defaultsTo: true)
  ..addOption('output-dill',
      help: 'Output path for the generated dill',
      defaultsTo: null)
  ..addOption('output-incremental-dill',
      help: 'Output path for the generated incremental dill',
      defaultsTo: null)
  ..addOption('depfile',
      help: 'Path to output Ninja depfile. Only used in batch mode.')
  ..addOption('packages',
      help: '.packages file to use for compilation',
      defaultsTo: null)
  ..addFlag('track-widget-creation',
      help: 'Run a kernel transformer to track creation locations for widgets.',
      defaultsTo: false);

String _usage = '''
Usage: server [options] [input.dart]

If input dart source code is provided on the command line, then the server
compiles it, generates dill file and exits.
If no input dart source is provided on the command line, server waits for
instructions from stdin.

Instructions:
- compile <input.dart>
- recompile [<input.dart>] <boundary-key>
<path/to/updated/file1.dart>
<path/to/updated/file2.dart>
...
<boundary-key>
- accept
- quit

Output:
- result <boundary-key>
<compiler output>
<boundary-key> [<output.dill>]

Options:
${_argParser.usage}
''';

enum _State { READY_FOR_INSTRUCTION, RECOMPILE_LIST }

/// Actions that every compiler should implement.
abstract class CompilerInterface {
  /// Compile given Dart program identified by `filename` with given list of
  /// `options`. When `generator` parameter is omitted, new instance of
  /// `IncrementalKernelGenerator` is created by this method. Main use for this
  /// parameter is for mocking in tests.
  Future<Null> compile(
    String filename,
    ArgResults options, {
    IncrementalCompiler generator,
  });

  /// Assuming some Dart program was previously compiled, recompile it again
  /// taking into account some changed(invalidated) sources.
  Future<Null> recompileDelta({String filename});

  /// Accept results of previous compilation so that next recompilation cycle
  /// won't recompile sources that were previously reported as changed.
  void acceptLastDelta();

  /// This let's compiler know that source file identifed by `uri` was changed.
  void invalidate(Uri uri);

  /// Resets incremental compiler accept/reject status so that next time
  /// recompile is requested, complete kernel file is produced.
  void resetIncrementalCompiler();
}

/// Class that for test mocking purposes encapsulates creation of [BinaryPrinter].
class BinaryPrinterFactory {
  /// Creates new [BinaryPrinter] to write to [targetSink].
  BinaryPrinter newBinaryPrinter(IOSink targetSink) {
    return new LimitedBinaryPrinter(targetSink, (_) => true /* predicate */,
        false /* excludeUriToSource */);
  }
}

class _FrontendCompiler implements CompilerInterface {
  _FrontendCompiler(this._outputStream, {this.printerFactory, this.trackWidgetCreation}) {
    _outputStream ??= stdout;
    printerFactory ??= new BinaryPrinterFactory();
    if (trackWidgetCreation) {
      widgetCreatorTracker = new WidgetCreatorTracker();
    }
  }

  StringSink _outputStream;
  BinaryPrinterFactory printerFactory;

  CompilerOptions _compilerOptions;
  Uri _entryPoint;
  ArgResults _options;

  IncrementalCompiler _generator;
  String _kernelBinaryFilename;
  String _kernelBinaryFilenameIncremental;
  String _kernelBinaryFilenameFull;
  final bool trackWidgetCreation;
  WidgetCreatorTracker widgetCreatorTracker;

  void setEntrypointFilename(String filename) {
    final Uri filenameUri = Uri.base.resolveUri(new Uri.file(filename));
    _kernelBinaryFilenameFull = _options['output-dill'] ?? '$filename.dill';
    _kernelBinaryFilenameIncremental =
    _options['output-incremental-dill'] ??
        _options['output-dill'] != null
        ? '${_options["output-dill"]}.incremental.dill'
        : '$filename.incremental.dill';
    _kernelBinaryFilename = _kernelBinaryFilenameFull;
    _entryPoint = filenameUri;
  }

  @override
  Future<Null> compile(
    String filename,
    ArgResults options, {
    IncrementalCompiler generator,
  }) async {
    _options = options;
    setEntrypointFilename(filename);
    final String boundaryKey = new Uuid().generateV4();
    _outputStream.writeln('result $boundaryKey');
    final Uri sdkRoot = _ensureFolderPath(options['sdk-root']);
    final CompilerOptions compilerOptions = new CompilerOptions()
      ..sdkRoot = sdkRoot
      ..packagesFileUri = options['packages'] != null ? Uri.base.resolveUri(new Uri.file(options['packages'])) : null
      ..strongMode = options['strong']
      ..target = new FlutterTarget(new TargetFlags(strongMode: options['strong']))
      ..reportMessages = true;

    Program program;
    if (options['incremental']) {
      _compilerOptions = compilerOptions;
      _generator = generator ?? _createGenerator(new Uri.file(_kernelBinaryFilenameFull));
      await invalidateIfBootstrapping();
      program = await _runWithPrintRedirection(() => _generator.compile());
    } else {
      if (options['link-platform']) {
        // TODO(aam): Remove linkedDependencies once platform is directly embedded
        // into VM snapshot and http://dartbug.com/30111 is fixed.
        final String platformKernelDill =
            options['strong'] ? 'platform_strong.dill' : 'platform.dill';
        compilerOptions.linkedDependencies = <Uri>[
          sdkRoot.resolve(platformKernelDill)
        ];
      }
      program = await _runWithPrintRedirection(() =>
          compileToKernel(_entryPoint, compilerOptions, aot: options['aot']));
    }
    runFlutterSpecificKernelTransforms(program);
    if (program != null) {
      final IOSink sink = new File(_kernelBinaryFilename).openWrite();
      final BinaryPrinter printer = printerFactory.newBinaryPrinter(sink);
      printer.writeProgramFile(program);
      await sink.close();
      _outputStream.writeln('$boundaryKey $_kernelBinaryFilename');

      final String depfile = options['depfile'];
      if (depfile != null) {
        await _writeDepfile(program, _kernelBinaryFilename, depfile);
      }

      _kernelBinaryFilename = _kernelBinaryFilenameIncremental;
    } else
      _outputStream.writeln(boundaryKey);
    return null;
  }

  Future<Null> invalidateIfBootstrapping() async {
    if (_kernelBinaryFilename != _kernelBinaryFilenameFull)
      return null;

    try {
      final File f = new File(_kernelBinaryFilenameFull);
      if (!f.existsSync())
        return null;

      final Program program = loadProgramFromBytes(f.readAsBytesSync());
      for (Uri uri in program.uriToSource.keys) {
        if ('$uri' == '')
          continue;

        final List<int> oldBytes = program.uriToSource[uri].source;
        final FileSystemEntity entity = _compilerOptions.fileSystem.entityForUri(uri);
        if (!await entity.exists()) {
          _generator.invalidate(uri);
          continue;
        }
        final List<int> newBytes = await entity.readAsBytes();
        if (oldBytes.length != newBytes.length) {
          _generator.invalidate(uri);
          continue;
        }
        for (int i = 0; i < oldBytes.length; ++i) {
          if (oldBytes[i] != newBytes[i]) {
            _generator.invalidate(uri);
            continue;
          }
        }
      }
    } catch(e) {
      // If there's a failure in the above block we might not have invalidated
      // correctly. Create a new generator that doesn't bootstrap to avoid missing
      // any changes.
      _generator = _createGenerator(null);
    }
  }

  void runFlutterSpecificKernelTransforms(Program program) {
    if (program == null) {
      return;
    }

    if (trackWidgetCreation) {
      widgetCreatorTracker.transform(program);
    }
  }

  @override
  Future<Null> recompileDelta({String filename}) async {
    final String boundaryKey = new Uuid().generateV4();
    _outputStream.writeln('result $boundaryKey');
    await invalidateIfBootstrapping();
    if (filename != null) {
      setEntrypointFilename(filename);
    }
    final Program deltaProgram = await _generator.compile(entryPoint: _entryPoint);
    runFlutterSpecificKernelTransforms(deltaProgram);
    final IOSink sink = new File(_kernelBinaryFilename).openWrite();
    final BinaryPrinter printer = printerFactory.newBinaryPrinter(sink);
    printer.writeProgramFile(deltaProgram);
    await sink.close();
    _outputStream.writeln('$boundaryKey $_kernelBinaryFilename');
    _kernelBinaryFilename = _kernelBinaryFilenameIncremental;
    return null;
  }

  @override
  void acceptLastDelta() {
    _generator.accept();
  }

  @override
  void invalidate(Uri uri) {
    _generator.invalidate(uri);
  }

  @override
  void resetIncrementalCompiler() {
    _generator = _createGenerator(new Uri.file(_kernelBinaryFilenameFull));
    _kernelBinaryFilename = _kernelBinaryFilenameFull;
  }

  IncrementalCompiler _createGenerator(Uri bootstrapDill) {
    return new IncrementalCompiler(_compilerOptions, _entryPoint,
        bootstrapDill: bootstrapDill);
  }

  Uri _ensureFolderPath(String path) {
    String uriPath = new Uri.file(path).toString();
    if (!uriPath.endsWith('/')) {
      uriPath = '$uriPath/';
    }
    return Uri.base.resolve(uriPath);
  }


  /// Runs the given function [f] in a Zone that redirects all prints into
  /// [_outputStream].
  Future<T> _runWithPrintRedirection<T>(Future<T> f()) {
    return runZoned(() => new Future<T>(f),
        zoneSpecification: new ZoneSpecification(
            print: (Zone self, ZoneDelegate parent, Zone zone, String line) =>
                _outputStream.writeln(line)));
  }
}

String _escapePath(String path) {
  return path.replaceAll(r'\', r'\\').replaceAll(r' ', r'\ ');
}

// https://ninja-build.org/manual.html#_depfile
Future<void> _writeDepfile(Program program, String output, String depfile) async {
  final IOSink file = new File(depfile).openWrite();
  file.write(_escapePath(output));
  file.write(':');
  for (Uri dep in program.uriToSource.keys) {
    file.write(' ');
    file.write(_escapePath(dep.toFilePath()));
  }
  file.write('\n');
  await file.close();
}

/// Entry point for this module, that creates `_FrontendCompiler` instance and
/// processes user input.
/// `compiler` is an optional parameter so it can be replaced with mocked
/// version for testing.
Future<int> starter(
  List<String> args, {
  CompilerInterface compiler,
  Stream<List<int>> input,
  StringSink output,
  IncrementalCompiler generator,
  BinaryPrinterFactory binaryPrinterFactory,
}) async {
  ArgResults options;
  try {
    options = _argParser.parse(args);
  } catch (error) {
    print('ERROR: $error\n');
    print(_usage);
    return 1;
  }

  if (options['train']) {
    final String sdkRoot = options['sdk-root'];
    final Directory temp = Directory.systemTemp.createTempSync('train_frontend_server');
    try {
      final String outputTrainingDill = path.join(temp.path, 'app.dill');
      options =
          _argParser.parse(<String>['--incremental', '--sdk-root=$sdkRoot',
          '--output-dill=$outputTrainingDill'
          ]);
      compiler ??=
      new _FrontendCompiler(output, printerFactory: binaryPrinterFactory);

      await compiler.compile(
          Platform.script.toFilePath(), options, generator: generator);
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

  compiler ??= new _FrontendCompiler(
    output,
    printerFactory: binaryPrinterFactory,
    trackWidgetCreation: options['track-widget-creation'],
  );
  input ??= stdin;

  if (options.rest.isNotEmpty) {
    await compiler.compile(options.rest[0], options, generator: generator);
    return 0;
  }

  _State state = _State.READY_FOR_INSTRUCTION;
  String boundaryKey;
  String recompileFilename;
  input
      .transform(UTF8.decoder)
      .transform(const LineSplitter())
      .listen((String string) async {
    switch (state) {
      case _State.READY_FOR_INSTRUCTION:
        const String COMPILE_INSTRUCTION_SPACE = 'compile ';
        const String RECOMPILE_INSTRUCTION_SPACE = 'recompile ';
        if (string.startsWith(COMPILE_INSTRUCTION_SPACE)) {
          final String filename =
              string.substring(COMPILE_INSTRUCTION_SPACE.length);
          await compiler.compile(filename, options, generator: generator);
        } else if (string.startsWith(RECOMPILE_INSTRUCTION_SPACE)) {
          // 'recompile [<filename>] <boundarykey>'
          //   where <boundarykey> can't have spaces
          final String remainder = string.substring(RECOMPILE_INSTRUCTION_SPACE.length);
          final int spaceDelim = remainder.lastIndexOf(' ');
          if (spaceDelim > -1) {
            recompileFilename = remainder.substring(0, spaceDelim);
            boundaryKey = remainder.substring(spaceDelim + 1);
          } else {
            boundaryKey = remainder;
          }
          state = _State.RECOMPILE_LIST;
        } else if (string == 'accept') {
          compiler.acceptLastDelta();
        } else if (string == 'reset') {
          compiler.resetIncrementalCompiler();
        } else if (string == 'quit') {
          exit(0);
        }
        break;
      case _State.RECOMPILE_LIST:
        if (string == boundaryKey) {
          compiler.recompileDelta(filename: recompileFilename);
          state = _State.READY_FOR_INSTRUCTION;
        } else
          compiler.invalidate(Uri.base.resolve(string));
        break;
    }
  });
  return 0;
}
