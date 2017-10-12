library frontend_server;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:front_end/compilation_message.dart';

import 'package:front_end/byte_store.dart';
import 'package:front_end/compiler_options.dart';
import 'package:front_end/incremental_kernel_generator.dart';
import 'package:front_end/kernel_generator.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/binary/limited_ast_to_binary.dart';
import 'package:kernel/target/flutter.dart';
import 'package:kernel/target/targets.dart';
import 'package:usage/uuid/uuid.dart';

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
  ..addFlag('link-platform',
      help: 'When in batch mode, link platform kernel file into result kernel file.'
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
  Future<Null> compile(String filename, ArgResults options, {
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
    return new LimitedBinaryPrinter(
      targetSink,
      (_) => true /* predicate */,
      false /* excludeUriToSource */);  }
}

class _FrontendCompiler implements CompilerInterface {
  _FrontendCompiler(this._outputStream, { this.printerFactory }) {
    _outputStream ??= stdout;
    printerFactory ??= new BinaryPrinterFactory();
  }

  StringSink _outputStream;
  BinaryPrinterFactory printerFactory;

  IncrementalKernelGenerator _generator;
  String _filename;
  String _kernelBinaryFilename;

  @override
  Future<Null> compile(String filename, ArgResults options, {
    IncrementalKernelGenerator generator,
  }) async {
    _filename = filename;
    _kernelBinaryFilename = "$filename.dill";
    final String boundaryKey = new Uuid().generateV4();
    _outputStream.writeln("result $boundaryKey");
    final Uri sdkRoot = _ensureFolderPath(options['sdk-root']);
    final String byteStorePath = options['byte-store'];
    final CompilerOptions compilerOptions = new CompilerOptions()
      ..byteStore = byteStorePath != null
          ? new FileByteStore(byteStorePath)
          : new MemoryByteStore()
      ..sdkRoot = sdkRoot
      ..strongMode = false
      ..target = new FlutterTarget(new TargetFlags())
      ..onError = (CompilationMessage message) {
        final StringBuffer outputMessage = new StringBuffer()
          ..write(_severityName(message.severity))
          ..write(': ');
        if (message.span != null) {
          outputMessage.writeln(message.span.message(message.message));
        } else {
          outputMessage.writeln(message.message);
        }
        if (message.tip != null) {
          outputMessage.writeln(message.tip);
        }
        _outputStream.write(outputMessage);
      };
    Program program;
    if (options['incremental']) {
      _generator = generator != null
        ? generator
        : await IncrementalKernelGenerator.newInstance(
          compilerOptions, Uri.base.resolve(_filename)
        );
      final DeltaProgram deltaProgram = await _generator.computeDelta();
      program = deltaProgram.newProgram;
    } else {
      if (options['link-platform']) {
        // TODO(aam): Remove linkedDependencies once platform is directly embedded
        // into VM snapshot and http://dartbug.com/30111 is fixed.
        compilerOptions.linkedDependencies = <Uri>[
          sdkRoot.resolve('platform.dill')
        ];
      }
      program = await kernelForProgram(Uri.base.resolve(_filename), compilerOptions);
    }
    if (program != null) {
      final IOSink sink = new File(_kernelBinaryFilename).openWrite();
      final BinaryPrinter printer = printerFactory.newBinaryPrinter(sink);
      printer.writeProgramFile(program);
      _outputStream.writeln("$boundaryKey $_kernelBinaryFilename");
      await sink.close();
    } else
      _outputStream.writeln(boundaryKey);
    return null;
  }

  @override
  Future<Null> recompileDelta() async {
    final String boundaryKey = new Uuid().generateV4();
    _outputStream.writeln("result $boundaryKey");
    final DeltaProgram deltaProgram = await _generator.computeDelta();
    final IOSink sink = new File(_kernelBinaryFilename).openWrite();
    final BinaryPrinter printer = printerFactory.newBinaryPrinter(sink);
    printer.writeProgramFile(deltaProgram.newProgram);
    _outputStream.writeln("$boundaryKey $_kernelBinaryFilename");
    await sink.close();
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
    // This is a URI, not a file path, so the forward slash is correct even
    // on Windows.
    if (!path.endsWith('/'))
      path = '$path/';
    return Uri.base.resolve(path);
  }

  static String _severityName(Severity severity) {
    switch (severity) {
      case Severity.error:
        return "Error";
      case Severity.internalProblem:
        return "Internal problem";
      case Severity.nit:
        return "Nit";
      case Severity.warning:
        return "Warning";
      default:
        return severity.toString();
    }
  }
}

/// Entry point for this module, that creates `_FrontendCompiler` instance and
/// processes user input.
/// `compiler` is an optional parameter so it can be replaced with mocked
/// version for testing.
Future<int> starter(List<String> args, {
  CompilerInterface compiler,
  Stream<List<int>> input, StringSink output,
  IncrementalKernelGenerator generator,
  BinaryPrinterFactory binaryPrinterFactory,
}) async {
  final ArgResults options = _argParser.parse(args);
  if (options['train'])
    return 0;

  compiler ??= new _FrontendCompiler(output, printerFactory: binaryPrinterFactory);
  input ??= stdin;

  if (options.rest.isNotEmpty) {
    await compiler.compile(options.rest[0], options, generator: generator);
    return 0;
  }

  _State state = _State.READY_FOR_INSTRUCTION;
  String boundaryKey;
  input
    .transform(UTF8.decoder)
    .transform(new LineSplitter())
    .listen((String string) async {
    switch (state) {
      case _State.READY_FOR_INSTRUCTION:
        const String COMPILE_INSTRUCTION_SPACE = 'compile ';
        const String RECOMPILE_INSTRUCTION_SPACE = 'recompile ';
        if (string.startsWith(COMPILE_INSTRUCTION_SPACE)) {
          final String filename = string.substring(COMPILE_INSTRUCTION_SPACE.length);
          await compiler.compile(filename, options, generator: generator);
        } else if (string.startsWith(RECOMPILE_INSTRUCTION_SPACE)) {
          boundaryKey = string.substring(RECOMPILE_INSTRUCTION_SPACE.length);
          state = _State.RECOMPILE_LIST;
        } else if (string == 'accept')
          compiler.acceptLastDelta();
        else if (string == 'reject')
          compiler.rejectLastDelta();
        else if (string == 'reset')
          compiler.resetIncrementalCompiler();
        else if (string == 'quit')
          exit(0);
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
