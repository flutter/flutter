// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../src/fake_process_manager.dart' as test_process_manager;

/// A mock LSP server that allows a test to control analysis status, progress
/// notifications and diagnostics.
class MockLspServerProcess extends test_process_manager.FakeProcess {
  factory MockLspServerProcess() {
    final stdinController = StreamController<List<int>>();
    final stdinSink = IOSink(stdinController.sink);
    final exitCompleter = Completer<void>();
    return MockLspServerProcess._(stdinController, stdin: stdinSink, exitCompleter: exitCompleter);
  }

  MockLspServerProcess._(
    this._stdinController, {
    required super.stdin,
    required Completer<void> exitCompleter,
  }) : _exitCompleter = exitCompleter,
       super(completer: exitCompleter) {
    _stdinController.stream.transform(utf8.decoder).listen(_handleStdinChunk);
  }

  final StreamController<List<int>> _stdinController;
  final _inputBuffer = StringBuffer();
  final _stdoutController = StreamController<List<int>>();
  final Completer<void> _exitCompleter;

  Completer<void>? _analysisCompleter;
  final _initializeRequestCompleter = Completer<Map<String, Object?>>();
  Future<Map<String, Object?>> get initializeRequest => _initializeRequestCompleter.future;

  @override
  Stream<List<int>> get stdout => _stdoutController.stream;

  /// Starts simulated analysis on the server, but does not wait for it.
  void triggerSimulatedAnalysis({Uri? diagnosticsFor, int diagnosticsCount = 1}) {
    unawaited(
      runSimulatedAnalysis(diagnosticsFor: diagnosticsFor, diagnosticsCount: diagnosticsCount),
    );
  }

  /// Simulates analysis on the server.
  ///
  /// This will trigger a progress notification indicating that analysis has
  /// started, optionally send [diagnosticsCount] diagnostics for
  /// [diagnosticsFor], then send a progress notification indicating that anlaysis has ended.
  Future<void> runSimulatedAnalysis({Uri? diagnosticsFor, int diagnosticsCount = 1}) async {
    _simulateAnalysisStart();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    if (diagnosticsFor != null) {
      _simulateDiagnostics(diagnosticsFor, diagnosticsCount);
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    _simulateAnalysisEnd();
  }

  /// Causes the process to write a Dart VM Service banner to stdout.
  void triggerVmServiceUriBanner() {
    _writeRawOutput('The Dart VM service is listening on http://127.0.0.1:65155/ZkxDXuYz2Aw=/\n');
  }

  Future<void> _handleRequest(Map<String, Object?> request) async {
    switch (request['method']) {
      case 'initialize':
        _initializeRequestCompleter.complete(request);
        _writeAsLspToStdout(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': request['id'],
            'result': {'capabilities': <String, Object?>{}},
          }),
        );
      case 'dart/workspace/analysis/complete':
        await _analysisCompleter?.future;
        _sendResponse(request['id'], null);
    }
  }

  void _handleStdinChunk(String chunk) {
    _inputBuffer.write(chunk);
    var input = _inputBuffer.toString();
    while (true) {
      final int headerEnd = input.indexOf('\r\n\r\n');
      if (headerEnd == -1) {
        break;
      }
      final String header = input.substring(0, headerEnd);
      final Match? contentLengthMatch = RegExp(r'Content-Length: (\d+)').firstMatch(header);
      if (contentLengthMatch == null) {
        throw StateError('LSP request is missing a Content-Length header.');
      }
      final int contentLength = int.parse(contentLengthMatch.group(1)!);
      final int messageEnd = headerEnd + 4 + contentLength;
      if (input.length < messageEnd) {
        break;
      }
      final String message = input.substring(headerEnd + 4, messageEnd);
      unawaited(_handleRequest(jsonDecode(message) as Map<String, Object?>));
      input = input.substring(messageEnd);
    }
    _inputBuffer
      ..clear()
      ..write(input);
  }

  void _sendNotification(String method, Map<String, Object?> params) {
    _writeAsLspToStdout(
      jsonEncode(<String, Object?>{'jsonrpc': '2.0', 'method': method, 'params': params}),
    );
  }

  void _sendResponse(Object? id, Map<String, Object?>? result) {
    _writeAsLspToStdout(jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': result}));
  }

  void _simulateAnalysisEnd() {
    _analysisCompleter?.complete();
    _analysisCompleter = null;
    _sendNotification(r'$/progress', <String, Object?>{
      'token': 'analyze',
      'value': <String, Object?>{'kind': 'end'},
    });
  }

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    _exitCompleter.complete();
    return super.kill();
  }

  void _simulateAnalysisStart() {
    if (_analysisCompleter case null || Completer(isCompleted: true)) {
      _analysisCompleter = Completer<void>();
      _sendNotification(r'$/progress', <String, Object?>{
        'token': 'analyze',
        'value': <String, Object?>{'kind': 'begin'},
      });
    }
  }

  void _simulateDiagnostics(Uri targetUri, int count) {
    _sendNotification('textDocument/publishDiagnostics', {
      'uri': targetUri.toString(),
      'diagnostics': <Object?>[
        for (var i = 0; i < count; i++)
          <String, Object?>{
            'range': <String, Object?>{
              'start': <String, Object?>{'line': 99 + i, 'character': 4},
              'end': <String, Object?>{'line': 99 + i, 'character': 4},
            },
            'severity': 2,
            'code': '500',
            'message': "It's an error.",
          },
      ],
    });
  }

  void _writeAsLspToStdout(String message) {
    _stdoutController.add(utf8.encode('Content-Length: ${message.length}\r\n\r\n$message'));
  }

  void _writeRawOutput(String output) {
    _stdoutController.add(utf8.encode(output));
  }
}
