library frontend_server;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

// front_end/src imports below that require lint `ignore_for_file`
// are a temporary state of things until frontend team builds better api
// that would replace api used below. This api was made private in
// an effort to discourage further use.
// ignore_for_file: implementation_imports
import 'package:front_end/src/api_prototype/byte_store.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart';

import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/binary/limited_ast_to_binary.dart';
import 'package:kernel/target/flutter.dart';
import 'package:kernel/target/targets.dart';
import 'package:usage/uuid/uuid.dart';
import 'package:vm/kernel_front_end.dart' show compileToKernel;

ArgParser _argParser = new ArgParser(allowTrailingOptions: true)
  ..addFlag('train',
      help: 'Run through sample command line to produce snapshot',
      negatable: false)
  ..addFlag('incremental',
      help: 'Run compiler in incremental mode', defaultsTo: false)
  ..addOption('sdk-root',
      help: 'Path to sdk root',
      defaultsTo: '../../out/android_debug/flutter_patched_sdk')
  ..addOption('byte-store',
      help: 'Path to file byte store used to keep incremental compiler state.'
          ' If omitted, then memory byte store is used.',
      defaultsTo: null)
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
      defaultsTo: true);

String _usage = '''
Usage: server [options] [input.dart]

If input dart source code is provided on the command line, then the server
compiles it, generates dill file and exits.
If no input dart source is provided on the command line, server waits for
instructions from stdin.

Instructions:
- compile <input.dart>
- recompile <boundary-key>
<path/to/updated/file1.dart>
<path/to/updated/file2.dart>
...
<boundary-key>
- accept
- reject
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
    IncrementalKernelGenerator generator,
  });

  /// Assuming some Dart program was previously compiled, recompile it again
  /// taking into account some changed(invalidated) sources.
  Future<Null> recompileDelta();

  /// Accept results of previous compilation so that next recompilation cycle
  /// won't recompile sources that were previously reported as changed.
  void acceptLastDelta();

  /// Reject results of previous compilation. Next recompilation cycle will
  /// recompile sources indicated as changed.
  void rejectLastDelta();

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
  _FrontendCompiler(this._outputStream, {this.printerFactory}) {
    _outputStream ??= stdout;
    printerFactory ??= new BinaryPrinterFactory();
  }

  StringSink _outputStream;
  BinaryPrinterFactory printerFactory;

  IncrementalKernelGenerator _generator;
  String _kernelBinaryFilename;

  @override
  Future<Null> compile(
    String filename,
    ArgResults options, {
    IncrementalKernelGenerator generator,
  }) async {
    final Uri filenameUri = Uri.base.resolveUri(new Uri.file(filename));
    _kernelBinaryFilename = '$filename.dill';
    final String boundaryKey = new Uuid().generateV4();
    _outputStream.writeln('result $boundaryKey');
    final Uri sdkRoot = _ensureFolderPath(options['sdk-root']);
    final String byteStorePath = options['byte-store'];
    final CompilerOptions compilerOptions = new CompilerOptions()
      ..byteStore = byteStorePath != null
          ? new FileByteStore(byteStorePath)
          : new MemoryByteStore()
      ..sdkRoot = sdkRoot
      ..strongMode = options['strong']
      ..target = new FlutterTarget(new TargetFlags(strongMode: options['strong']))
      ..reportMessages = true;

    Program program;
    if (options['incremental']) {
      _generator = generator != null
          ? generator
          : await IncrementalKernelGenerator.newInstance(
              compilerOptions, filenameUri,
              useMinimalGenerator: true);
      final DeltaProgram deltaProgram =
          await _runWithPrintRedirection(() => _generator.computeDelta());
      program = deltaProgram.newProgram;
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
          compileToKernel(filenameUri, compilerOptions, aot: options['aot']));
    }
    if (program != null) {
      final IOSink sink = new File(_kernelBinaryFilename).openWrite();
      final BinaryPrinter printer = printerFactory.newBinaryPrinter(sink);
      printer.writeProgramFile(program);
      await sink.close();
      _outputStream.writeln('$boundaryKey $_kernelBinaryFilename');
    } else
      _outputStream.writeln(boundaryKey);
    return null;
  }

  @override
  Future<Null> recompileDelta() async {
    final String boundaryKey = new Uuid().generateV4();
    _outputStream.writeln('result $boundaryKey');
    final DeltaProgram deltaProgram = await _generator.computeDelta();
    final IOSink sink = new File(_kernelBinaryFilename).openWrite();
    final BinaryPrinter printer = printerFactory.newBinaryPrinter(sink);
    printer.writeProgramFile(deltaProgram.newProgram);
    await sink.close();
    _outputStream.writeln('$boundaryKey $_kernelBinaryFilename');
    return null;
  }

  @override
  void acceptLastDelta() {
    _generator.acceptLastDelta();
  }

  @override
  void rejectLastDelta() {
    _generator.rejectLastDelta();
  }

  @override
  void invalidate(Uri uri) {
    _generator.invalidate(uri);
  }

  @override
  void resetIncrementalCompiler() {
    _generator.reset();
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

/// Entry point for this module, that creates `_FrontendCompiler` instance and
/// processes user input.
/// `compiler` is an optional parameter so it can be replaced with mocked
/// version for testing.
Future<int> starter(
  List<String> args, {
  CompilerInterface compiler,
  Stream<List<int>> input,
  StringSink output,
  IncrementalKernelGenerator generator,
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
    options = _argParser.parse(<String>['--incremental', '--sdk-root=$sdkRoot']);
    compiler ??= new _FrontendCompiler(output, printerFactory: binaryPrinterFactory);
    await compiler.compile(Platform.script.toFilePath(), options, generator: generator);
    compiler.acceptLastDelta();
    await compiler.recompileDelta();
    compiler.acceptLastDelta();
    await compiler.recompileDelta();
    compiler.acceptLastDelta();
    await compiler.recompileDelta();
    compiler.acceptLastDelta();
    return 0;
  }

  compiler ??=
      new _FrontendCompiler(output, printerFactory: binaryPrinterFactory);
  input ??= stdin;

  // Has to be a directory, that won't have any of the compiled application
  // sources, so that no relative paths could show up in the kernel file.
  Directory.current = Directory.systemTemp;
  final Directory workingDirectory = new Directory('flutter_frontend_server');
  workingDirectory.createSync();
  Directory.current = workingDirectory;

  if (options.rest.isNotEmpty) {
    await compiler.compile(options.rest[0], options, generator: generator);
    return 0;
  }

  _State state = _State.READY_FOR_INSTRUCTION;
  String boundaryKey;
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
          boundaryKey = string.substring(RECOMPILE_INSTRUCTION_SPACE.length);
          state = _State.RECOMPILE_LIST;
        } else if (string == 'accept') {
          compiler.acceptLastDelta();
        } else if (string == 'reject') {
          compiler.rejectLastDelta();
        } else if (string == 'reset') {
          compiler.resetIncrementalCompiler();
        } else if (string == 'quit') {
          exit(0);
        }
        break;
      case _State.RECOMPILE_LIST:
        if (string == boundaryKey) {
          compiler.recompileDelta();
          state = _State.READY_FOR_INSTRUCTION;
        } else
          compiler.invalidate(Uri.base.resolve(string));
        break;
    }
  });
  return 0;
}
