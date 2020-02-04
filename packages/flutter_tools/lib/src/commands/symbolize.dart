// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:native_stack_traces/native_stack_traces.dart';
import 'package:native_stack_traces/src/elf.dart'; // ignore: implementation_imports
import 'package:native_stack_traces/src/reader.dart'; // ignore: implementation_imports

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../convert.dart';
import '../runner/flutter_command.dart';

/// Support for symbolicating a Dart stack trace.
///
/// This command accepts either paths to an input file containing the
/// stack trace and an output file for the symbolicated trace to be
/// written, or it accepts a stack trace over stdin and outputs it
/// over stdout.
class SymbolizeCommand extends FlutterCommand {
  SymbolizeCommand({
    @required Stdio stdio,
    @required FileSystem fileSystem,
    DwarfSymbolicationService dwarfSymbolicationService = const DwarfSymbolicationService(),
  }) : _stdio = stdio,
       _fileSystem = fileSystem,
       _dwarfSymbolicationService = dwarfSymbolicationService {
    argParser.addOption(
      'debug-info',
      abbr: 'd',
      valueHelp: '/out/android/app.arm64.debug',
      help: 'A file path to the debug file generated for the version of the '
        ' application whose stack trace the tool will attempt to symbolicate.'
    );
    argParser.addOption(
      'input',
      abbr: 'i',
      valueHelp: '/crashes/stack_trace.err',
      help: 'A file path containing a Dart stack trace. Only supported when '
        'paired with the "--output" option.'
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      valueHelp: 'A file path for a symbolicated stack trace to be written to. '
        'Only supported when paired with the "--input" option.'
    );
  }

  final Stdio _stdio;
  final FileSystem _fileSystem;
  final DwarfSymbolicationService _dwarfSymbolicationService;

  @override
  String get description => 'symbolicate a stack trace from an AOT compiled flutter application.';

  @override
  String get name => 'symbolicate';

  @override
  bool get shouldUpdateCache => false;

  @override
  Future<void> validateCommand() {
    if (!argResults.wasParsed('debug-info')) {
      throwToolExit('"--debug-info" is required to symbolicate stack traces.');
    }
    if (!_fileSystem.isFileSync(stringArg('debug-info'))) {
      throwToolExit('${stringArg('debug-info')} does not exist.');
    }
    if (argResults.wasParsed('input') && !_fileSystem.isFileSync(stringArg('input'))) {
      throwToolExit('${stringArg('input')} does not exist.');
    }
    return super.validateCommand();
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    Stream<List<int>> input;
    IOSink output;

    // Configure output to either specified file or stdout.
    if (argResults.wasParsed('output')) {
      final File outputFile = _fileSystem.file(stringArg('output'));
      if (!outputFile.parent.existsSync()) {
        outputFile.parent.createSync(recursive: true);
      }
       output = outputFile.openWrite();
    } else {
      final StreamController<List<int>> outputController = StreamController<List<int>>();
      outputController
        .stream
        .transform(utf8.decoder)
        .listen(_stdio.stdoutWrite);
      output = IOSink(outputController);
    }

    // Configure input from either specified file or stdin.
    if (argResults.wasParsed('input')) {
      input = _fileSystem.file(stringArg('input')).openRead();
    } else {
      input = _stdio.stdin;
    }

    final Uint8List symbols = _fileSystem.file(stringArg('debug-info')).readAsBytesSync();
    await _dwarfSymbolicationService.decode(
      input: input,
      output: output,
      symbols: symbols,
    );

    return FlutterCommandResult.success();
  }
}

/// A service which decodes stack traces from Dart applications.
class DwarfSymbolicationService {

  const DwarfSymbolicationService();

  /// Decode a stack trace from [input] and place the results in [output].
  ///
  /// Requires [symbols] to be a buffer created from the `--split-debug-info`
  /// command line flag.
  ///
  /// Throws a [ToolExit] if the symbols cannot be parsed or the stack trace
  /// cannot be decoded.
  Future<void> decode({
    @required Stream<List<int>> input,
    @required IOSink output,
    @required Uint8List symbols,
  }) async {
    final Dwarf dwarf = Dwarf.fromElf(Elf.fromReader(Reader.fromTypedData(symbols)));
    if (dwarf == null) {
      throwToolExit('Failed to decode symbols file');
    }

    final Completer<void> onDone = Completer<void>();
    input
      .transform(const Utf8Decoder())
      .transform(const LineSplitter())
      .transform(DwarfStackTraceDecoder(dwarf, includeInternalFrames: true))
      .listen(output.writeln, onDone: onDone.complete, onError: onDone.completeError);

    try {
      await onDone.future;
      await output.close();
    } on Exception catch (err) {
      throwToolExit('Failed to symbolicated stack trace:\n $err');
    }
  }
}