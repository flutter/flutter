// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:process/process.dart';

import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/terminal.dart';
import '../base/utils.dart';
import '../convert.dart';
import '../globals.dart' as globals;

/// An interface to the Dart analysis server.
class AnalysisServer {
  AnalysisServer(
    this.sdkPath,
    this.directories, {
    required FileSystem fileSystem,
    required ProcessManager processManager,
    required Logger logger,
    required Platform platform,
    required Terminal terminal,
    required this.suppressAnalytics,
    String? protocolTrafficLog,
  }) : _fileSystem = fileSystem,
       _processManager = processManager,
       _logger = logger,
       _platform = platform,
       _terminal = terminal,
       _protocolTrafficLog = protocolTrafficLog;

  final String sdkPath;
  final List<String> directories;
  final FileSystem _fileSystem;
  final ProcessManager _processManager;
  final Logger _logger;
  final Platform _platform;
  final Terminal _terminal;
  final String? _protocolTrafficLog;
  final bool suppressAnalytics;

  Process? _process;
  final _analyzingController = StreamController<bool>.broadcast();
  final _errorsController = StreamController<FileAnalysisErrors>.broadcast();
  var _didServerErrorOccur = false;

  var _id = 0;
  int? _initializeId;
  Completer<void>? _initializeCompleter;

  Future<void> start() async {
    final String snapshot = _fileSystem.path.join(
      sdkPath,
      'bin',
      'snapshots',
      'analysis_server.dart.snapshot',
    );
    final command = <String>[
      _fileSystem.path.join(sdkPath, 'bin', 'dart'),
      snapshot,
      '--lsp',
      '--sdk',
      sdkPath,
      if (suppressAnalytics) '--suppress-analytics',
      if (_protocolTrafficLog != null) '--protocol-traffic-log=$_protocolTrafficLog',
    ];

    _logger.printTrace('dart ${command.skip(1).join(' ')}');
    _process = await _processManager.start(command);
    // This callback hookup can't throw.
    unawaited(_process!.exitCode.whenComplete(() => _process = null));

    final Stream<String> errorStream = _process!.stderr.transform(utf8LineDecoder);
    errorStream.listen(_handleError);

    _process!.stdout.listen(_handleServerResponseRaw);

    _initializeId = ++_id;
    _initializeCompleter = Completer<void>();
    _sendCommandWithId(_initializeId!, 'initialize', <String, Object?>{
      'processId': pid,
      'rootUri': _fileSystem.directory(directories.first).uri.toString(),
      'capabilities': <String, Object?>{
        'window': <String, Object?>{'workDoneProgress': true},
      },
    });

    await _initializeCompleter!.future;
    _sendNotification('initialized', <String, Object?>{});
  }

  final _logs = <String>[];

  /// Aggregated STDOUT and STDERR logs from the server.
  ///
  /// This can be surfaced to the user if the server crashes. If [tail] is null,
  /// returns all logs, else only the last [tail] lines.
  String getLogs([int? tail]) {
    if (tail == null) {
      return _logs.join('\n');
    }
    // Since List doesn't implement a .tail() method, we reverse it then use
    // .take()
    final Iterable<String> reversedLogs = _logs.reversed;
    final List<String> firstTailLogs = reversedLogs.take(tail).toList();
    return firstTailLogs.reversed.join('\n');
  }

  void _handleError(String message) {
    _logs.add('[stderr] $message');
    _logger.printError(message);
  }

  bool get didServerErrorOccur => _didServerErrorOccur;

  Stream<bool> get onAnalyzing => _analyzingController.stream;

  Stream<FileAnalysisErrors> get onErrors => _errorsController.stream;

  Future<int?> get onExit async => _process?.exitCode;

  /// Tells the analysis server to register services with a DTD instance at [dtdUri].
  void connectToDtd({required Uri dtdUri}) {
    _sendCommand('dart/connectToDtd', {'uri': dtdUri.toString()});
  }

  void _sendCommand(String method, Map<String, Object?> params) {
    _sendCommandWithId(++_id, method, params);
  }

  void _sendNotification(String method, Map<String, Object?> params) {
    final String message = json.encode(<String, Object?>{
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
    });
    _process?.stdin.write('Content-Length: ${message.length}\r\n\r\n$message');
    _logger.printTrace('==> $message');
  }

  void _sendResponse(Object? id, Object? result) {
    final String message = json.encode(<String, Object?>{
      'jsonrpc': '2.0',
      'id': id,
      'result': result,
    });
    _process?.stdin.write('Content-Length: ${message.length}\r\n\r\n$message');
    _logger.printTrace('==> $message');
  }

  void _sendCommandWithId(int id, String method, Map<String, Object?> params) {
    final String message = json.encode(<String, Object?>{
      'jsonrpc': '2.0',
      'id': ++id,
      'method': method,
      'params': params,
    });
    _process?.stdin.write('Content-Length: ${message.length}\r\n\r\n$message');
    _logger.printTrace('==> $message');
  }

  final List<int> _byteBuffer = <int>[];
  void _handleServerResponseRaw(List<int> data) {
    _byteBuffer.addAll(data);
    while (_byteBuffer.isNotEmpty) {
      // Find \r\n\r\n header separator
      var byteHeaderEnd = -1;
      for (var i = 0; i < _byteBuffer.length - 3; i++) {
        if (_byteBuffer[i] == 13 &&
            _byteBuffer[i + 1] == 10 &&
            _byteBuffer[i + 2] == 13 &&
            _byteBuffer[i + 3] == 10) {
          byteHeaderEnd = i;
          break;
        }
      }
      if (byteHeaderEnd == -1) {
        break;
      }

      final String headers = utf8.decode(_byteBuffer.sublist(0, byteHeaderEnd));
      final int contentLength = _parseContentLength(headers);
      if (contentLength == -1) {
        _logger.printTrace('No Content-Length found in headers:\n$headers');
        _byteBuffer.removeRange(0, byteHeaderEnd + 4);
        continue;
      }
      if (_byteBuffer.length < byteHeaderEnd + 4 + contentLength) {
        break;
      }
      final List<int> messageBytes = _byteBuffer.sublist(
        byteHeaderEnd + 4,
        byteHeaderEnd + 4 + contentLength,
      );
      _byteBuffer.removeRange(0, byteHeaderEnd + 4 + contentLength);
      final String message = utf8.decode(messageBytes);
      _handleServerResponse(message);
    }
  }

  static final RegExp _contentLengthRegExp = RegExp(
    r'content-length:\s*(\d+)',
    caseSensitive: false,
  );

  int _parseContentLength(String headers) {
    final Match? match = _contentLengthRegExp.firstMatch(headers);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? -1;
    }
    return -1;
  }

  void _handleServerResponse(String line) {
    _logs.add('[stdout] $line');
    _logger.printTrace('<== $line');
    if (line.startsWith(globals.kVMServiceMessageRegExp)) {
      return;
    }

    final Object? response = json.decode(line);

    if (response is Map<String, Object?>) {
      if (response.containsKey('result') || response.containsKey('error')) {
        final Object? id = response['id'];
        if (id == _initializeId) {
          if (response.containsKey('result')) {
            _initializeCompleter?.complete();
          } else {
            final Map<String, Object?> error = castStringKeyedMap(response['error'])!;
            _initializeCompleter?.completeError(
              error['message'] ?? 'Unknown error during initialize',
            );
          }
        }
      }

      final method = response['method'] as String?;
      if (method != null) {
        final Object? id = response['id'];
        final Object? params = response['params'];
        Map<String, Object?>? paramsMap;
        if (params is Map<String, Object?>) {
          paramsMap = castStringKeyedMap(params);
        }

        if (id != null) {
          // Handle requests from the server
          switch (method) {
            case 'window/workDoneProgress/create':
              _sendResponse(id, null);
          }
        } else if (paramsMap != null) {
          // Handle notifications from the server
          switch (method) {
            case r'$/progress':
              _handleProgress(paramsMap);
            case 'textDocument/publishDiagnostics':
              _handleAnalysisIssues(paramsMap);
            case 'window/showMessage':
              _handleServerError(paramsMap);
          }
        }
      }
    }
  }

  void _handleProgress(Map<String, Object?> params) {
    // LSP progress for analysis is typically reported via tokens.
    // The server sends begin/report/end for a token.
    final Object? value = params['value'];
    if (value is Map<String, Object?>) {
      final kind = value['kind'] as String?;
      if (kind == 'begin') {
        _analyzingController.add(true);
      } else if (kind == 'end') {
        _analyzingController.add(false);
      }
    }
  }

  void _handleServerError(Map<String, Object?> params) {
    // LSP window/showMessage
    final message = params['message']! as String;
    _logger.printError('Error from the analysis server: $message');
    _didServerErrorOccur = true;
  }

  void _handleAnalysisIssues(Map<String, Object?> params) {
    // {"method":"textDocument/publishDiagnostics","params":{"uri":"file:///.../lib/main.dart","diagnostics":[]}}
    final Uri uri = Uri.parse(params['uri']! as String);
    final String file = uri.toFilePath();
    final diagnosticsList = params['diagnostics']! as List<Object?>;

    final List<AnalysisError> errors = diagnosticsList
        .map<Map<String, Object?>>((Object? e) => castStringKeyedMap(e) ?? <String, Object?>{})
        .map<AnalysisError>((Map<String, Object?> json) {
          return AnalysisError(
            WrittenError.fromLsp(json, file),
            fileSystem: _fileSystem,
            platform: _platform,
            terminal: _terminal,
          );
        })
        .toList();
    if (!_errorsController.isClosed) {
      _errorsController.add(FileAnalysisErrors(file, errors));
    }
  }

  Future<bool?> dispose() async {
    await _analyzingController.close();
    await _errorsController.close();
    return _process?.kill();
  }
}

enum AnalysisSeverity { error, warning, info, none }

/// [AnalysisError] with command line style.
class AnalysisError implements Comparable<AnalysisError> {
  AnalysisError(
    this.writtenError, {
    required Platform platform,
    required Terminal terminal,
    required FileSystem fileSystem,
  }) : _platform = platform,
       _terminal = terminal,
       _fileSystem = fileSystem;

  final WrittenError writtenError;
  final Platform _platform;
  final Terminal _terminal;
  final FileSystem _fileSystem;

  String get _separator => _platform.isWindows ? '-' : '•';

  String get colorSeverity => switch (writtenError.severityLevel) {
    AnalysisSeverity.error => _terminal.color(writtenError.severity, TerminalColor.red),
    AnalysisSeverity.warning => _terminal.color(writtenError.severity, TerminalColor.yellow),
    AnalysisSeverity.info || AnalysisSeverity.none => writtenError.severity,
  };

  String get type => writtenError.type;
  String get code => writtenError.code;

  @override
  int compareTo(AnalysisError other) {
    // Sort in order of file path, error location, severity, and message.
    if (writtenError.file != other.writtenError.file) {
      return writtenError.file.compareTo(other.writtenError.file);
    }

    if (writtenError.offset != other.writtenError.offset &&
        writtenError.offset != -1 &&
        other.writtenError.offset != -1) {
      return writtenError.offset - other.writtenError.offset;
    }

    if (writtenError.startLine != other.writtenError.startLine) {
      return writtenError.startLine - other.writtenError.startLine;
    }

    if (writtenError.startColumn != other.writtenError.startColumn) {
      return writtenError.startColumn - other.writtenError.startColumn;
    }

    final int diff = other.writtenError.severityLevel.index - writtenError.severityLevel.index;
    if (diff != 0) {
      return diff;
    }

    return writtenError.message.compareTo(other.writtenError.message);
  }

  @override
  String toString() {
    // Can't use "padLeft" because of ANSI color sequences in the colorized
    // severity.
    final String padding = ' ' * math.max(0, 7 - writtenError.severity.length);
    return '$padding${colorSeverity.toLowerCase()} $_separator '
        '${writtenError.messageSentenceFragment} $_separator '
        '${_fileSystem.path.relative(writtenError.file)}:${writtenError.startLine}:${writtenError.startColumn} $_separator '
        '$code';
  }

  String toLegacyString() {
    return writtenError.toString();
  }
}

/// [AnalysisError] in plain text content.
class WrittenError {
  WrittenError._({
    required this.severity,
    required this.type,
    required this.message,
    required this.code,
    required this.file,
    required this.startLine,
    required this.startColumn,
    required this.offset,
  });

  ///  {
  ///      "severity":"INFO",
  ///      "type":"TODO",
  ///      "location":{
  ///          "file":"/Users/.../lib/test.dart",
  ///          "offset":362,
  ///          "length":72,
  ///          "startLine":15,
  ///         "startColumn":4
  ///      },
  ///      "message":"...",
  ///      "hasFix":false
  ///  }
  static WrittenError fromJson(Map<String, Object?> json) {
    final location = json['location']! as Map<String, Object?>;
    return WrittenError._(
      severity: json['severity']! as String,
      type: json['type']! as String,
      message: json['message']! as String,
      code: json['code']! as String,
      file: location['file']! as String,
      startLine: location['startLine']! as int,
      startColumn: location['startColumn']! as int,
      offset: location['offset']! as int,
    );
  }

  static WrittenError fromLsp(Map<String, Object?> json, String file) {
    final range = json['range']! as Map<String, Object?>;
    final start = range['start']! as Map<String, Object?>;
    final severity = json['severity'] as int?;
    return WrittenError._(
      severity: _lspSeverityMap[severity] ?? 'INFO',
      type: 'ANALYSIS', // LSP doesn't have a direct equivalent to 'type'
      message: json['message']! as String,
      code: (json['code'] ?? '').toString(),
      file: file,
      // LSP is 0-indexed, legacy is 1-indexed.
      startLine: (start['line']! as int) + 1,
      startColumn: (start['character']! as int) + 1,
      offset: -1, // LSP doesn't provide offset
    );
  }

  final String severity;
  final String type;
  final String message;
  final String code;

  final String file;
  final int startLine;
  final int startColumn;
  final int offset;

  static final _severityMap = <String, AnalysisSeverity>{
    'INFO': AnalysisSeverity.info,
    'WARNING': AnalysisSeverity.warning,
    'ERROR': AnalysisSeverity.error,
  };

  static final _lspSeverityMap = <int, String>{1: 'ERROR', 2: 'WARNING', 3: 'INFO', 4: 'INFO'};

  AnalysisSeverity get severityLevel => _severityMap[severity] ?? AnalysisSeverity.none;

  String get messageSentenceFragment {
    if (message.endsWith('.')) {
      return message.substring(0, message.length - 1);
    }
    return message;
  }

  @override
  String toString() {
    return '[${severity.toLowerCase()}] $messageSentenceFragment ($file:$startLine:$startColumn)';
  }
}

class FileAnalysisErrors {
  FileAnalysisErrors(this.file, this.errors);

  final String file;
  final List<AnalysisError> errors;
}
