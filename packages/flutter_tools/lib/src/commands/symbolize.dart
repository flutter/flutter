// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:native_stack_traces/native_stack_traces.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../convert.dart';
import '../runner/flutter_command.dart';

/// Support for symbolizing a Dart stack trace.
///
/// This command accepts either paths to an input file containing the
/// stack trace and an output file for the symbolizing trace to be
/// written, or it accepts a stack trace over stdin and outputs it
/// over stdout.
class SymbolizeCommand extends FlutterCommand {
  SymbolizeCommand({
    required Stdio stdio,
    required FileSystem fileSystem,
    DwarfSymbolizationService dwarfSymbolizationService = const DwarfSymbolizationService(),
  }) : _stdio = stdio,
       _fileSystem = fileSystem,
       _dwarfSymbolizationService = dwarfSymbolizationService {
    argParser.addOption(
      'debug-info',
      abbr: 'd',
      valueHelp: '/out/android/app.arm64.symbols',
      help: 'A path to the symbols file generated with "--split-debug-info".'
    );
    argParser.addOption(
      'input',
      abbr: 'i',
      valueHelp: '/crashes/stack_trace.err',
      help: 'A file path containing a Dart stack trace.'
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'A file path for a symbolized stack trace to be written to.'
    );
  }

  final Stdio _stdio;
  final FileSystem _fileSystem;
  final DwarfSymbolizationService _dwarfSymbolizationService;

  @override
  String get description => 'Symbolize a stack trace from an AOT-compiled Flutter app.';

  @override
  String get name => 'symbolize';

  @override
  final String category = FlutterCommandCategory.tools;

  @override
  bool get shouldUpdateCache => false;

  @override
  Future<void> validateCommand() {
    if (argResults?.wasParsed('debug-info') != true) {
      throwToolExit('"--debug-info" is required to symbolize stack traces.');
    }
    if (!_fileSystem.isFileSync(stringArg('debug-info')!)) {
      throwToolExit('${stringArg('debug-info')} does not exist.');
    }
    if (argResults?.wasParsed('input') == true && !_fileSystem.isFileSync(stringArg('input')!)) {
      throwToolExit('${stringArg('input')} does not exist.');
    }
    return super.validateCommand();
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    Stream<List<int>> input;
    IOSink output;

    // Configure output to either specified file or stdout.
    if (argResults?.wasParsed('output') == true) {
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
    if (argResults?.wasParsed('input') == true) {
      input = _fileSystem.file(stringArg('input')).openRead();
    } else {
      input = _stdio.stdin;
    }

    final Uint8List symbols = _fileSystem.file(stringArg('debug-info')).readAsBytesSync();
    await _dwarfSymbolizationService.decode(
      input: input,
      output: output,
      symbols: symbols,
    );

    return FlutterCommandResult.success();
  }
}

typedef SymbolsTransformer = StreamTransformer<String, String> Function(Uint8List);

StreamTransformer<String, String> _defaultTransformer(Uint8List symbols) {
  final Dwarf? dwarf = Dwarf.fromBytes(symbols);
  if (dwarf == null) {
    throwToolExit('Failed to decode symbols file');
  }
  return DwarfStackTraceDecoder(dwarf, includeInternalFrames: true);
}

// A no-op transformer for `DwarfSymbolizationService.test`
StreamTransformer<String, String> _testTransformer(Uint8List buffer) {
  return StreamTransformer<String, String>.fromHandlers(
    handleData: (String data, EventSink<String> sink) {
      sink.add(data);
    },
    handleDone: (EventSink<String> sink) {
      sink.close();
    },
    handleError: (Object error, StackTrace stackTrace, EventSink<String> sink) {
      sink.addError(error, stackTrace);
    }
  );
}

/// A service which decodes stack traces from Dart applications.
class DwarfSymbolizationService {
  const DwarfSymbolizationService({
    SymbolsTransformer symbolsTransformer = _defaultTransformer,
  }) : _transformer = symbolsTransformer;

  /// Create a DwarfSymbolizationService with a no-op transformer for testing.
  @visibleForTesting
  factory DwarfSymbolizationService.test() {
    return const DwarfSymbolizationService(
      symbolsTransformer: _testTransformer
    );
  }

  final SymbolsTransformer _transformer;

  /// Decode a stack trace from [input] and place the results in [output].
  ///
  /// Requires [symbols] to be a buffer created from the `--split-debug-info`
  /// command line flag.
  ///
  /// Throws a [ToolExit] if the symbols cannot be parsed or the stack trace
  /// cannot be decoded.
  Future<void> decode({
    required Stream<List<int>> input,
    required IOSink output,
    required Uint8List symbols,
  }) async {
    final Completer<void> onDone = Completer<void>();
    StreamSubscription<void>? subscription;
    subscription = input
      .cast<List<int>>()
      .transform(const Utf8Decoder())
      .transform(const LineSplitter())
      .transform(_transformer(symbols))
      .listen((String line) {
        try {
          output.writeln(line);
        } on Exception catch(e, s) {
          subscription?.cancel().whenComplete(() {
            if (!onDone.isCompleted) {
              onDone.completeError(e, s);
            }
          });
        }
      }, onDone: onDone.complete, onError: onDone.completeError);

    try {
      await onDone.future;
      await output.close();
    } on Exception catch (err) {
      throwToolExit('Failed to symbolize stack trace:\n $err');
    }
  }
}
