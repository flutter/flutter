// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/terminal.dart';
import '../base/utils.dart';
import '../convert.dart';

/// An interface to the Dart analysis server.
class AnalysisServer {
  AnalysisServer(this.sdkPath, this.directories, {
    @required FileSystem fileSystem,
    @required ProcessManager processManager,
    @required Logger logger,
    @required Platform platform,
    @required Terminal terminal,
    @required List<String> experiments,
  }) : _fileSystem = fileSystem,
       _processManager = processManager,
       _logger = logger,
       _platform = platform,
       _terminal = terminal,
       _experiments = experiments;

  final String sdkPath;
  final List<String> directories;
  final FileSystem _fileSystem;
  final ProcessManager _processManager;
  final Logger _logger;
  final Platform _platform;
  final Terminal _terminal;
  final List<String> _experiments;

  Process _process;
  final StreamController<bool> _analyzingController =
      StreamController<bool>.broadcast();
  final StreamController<FileAnalysisErrors> _errorsController =
      StreamController<FileAnalysisErrors>.broadcast();
  bool _didServerErrorOccur = false;

  int _id = 0;

  Future<void> start() async {
    final String snapshot = _fileSystem.path.join(
      sdkPath,
      'bin',
      'snapshots',
      'analysis_server.dart.snapshot',
    );
    final List<String> command = <String>[
      _fileSystem.path.join(sdkPath, 'bin', 'dart'),
      '--disable-dart-dev',
      snapshot,
      for (String experiment in _experiments)
        ...<String>[
          '--enable-experiment',
          experiment,
        ],
      '--disable-server-feature-completion',
      '--disable-server-feature-search',
      '--sdk',
      sdkPath,
    ];

    _logger.printTrace('dart ${command.skip(1).join(' ')}');
    _process = await _processManager.start(command);
    // This callback hookup can't throw.
    unawaited(_process.exitCode.whenComplete(() => _process = null));

    final Stream<String> errorStream =
        _process.stderr.transform<String>(utf8.decoder).transform<String>(const LineSplitter());
    errorStream.listen(_logger.printError);

    final Stream<String> inStream =
        _process.stdout.transform<String>(utf8.decoder).transform<String>(const LineSplitter());
    inStream.listen(_handleServerResponse);

    _sendCommand('server.setSubscriptions', <String, dynamic>{
      'subscriptions': <String>['STATUS'],
    });

    _sendCommand('analysis.setAnalysisRoots',
        <String, dynamic>{'included': directories, 'excluded': <String>[]});
  }

  bool get didServerErrorOccur => _didServerErrorOccur;
  Stream<bool> get onAnalyzing => _analyzingController.stream;
  Stream<FileAnalysisErrors> get onErrors => _errorsController.stream;

  Future<int> get onExit => _process.exitCode;

  void _sendCommand(String method, Map<String, dynamic> params) {
    final String message = json.encode(<String, dynamic>{
      'id': (++_id).toString(),
      'method': method,
      'params': params,
    });
    _process.stdin.writeln(message);
    _logger.printTrace('==> $message');
  }

  void _handleServerResponse(String line) {
    _logger.printTrace('<== $line');

    final dynamic response = json.decode(line);

    if (response is Map<String, dynamic>) {
      if (response['event'] != null) {
        final String event = response['event'] as String;
        final dynamic params = response['params'];

        if (params is Map<String, dynamic>) {
          if (event == 'server.status') {
            _handleStatus(castStringKeyedMap(response['params']));
          } else if (event == 'analysis.errors') {
            _handleAnalysisIssues(castStringKeyedMap(response['params']));
          } else if (event == 'server.error') {
            _handleServerError(castStringKeyedMap(response['params']));
          }
        }
      } else if (response['error'] != null) {
        // Fields are 'code', 'message', and 'stackTrace'.
        final Map<String, dynamic> error = castStringKeyedMap(response['error']);
        _logger.printError(
            'Error response from the server: ${error['code']} ${error['message']}');
        if (error['stackTrace'] != null) {
          _logger.printError(error['stackTrace'] as String);
        }
      }
    }
  }

  void _handleStatus(Map<String, dynamic> statusInfo) {
    // {"event":"server.status","params":{"analysis":{"isAnalyzing":true}}}
    if (statusInfo['analysis'] != null && !_analyzingController.isClosed) {
      final bool isAnalyzing = statusInfo['analysis']['isAnalyzing'] as bool;
      _analyzingController.add(isAnalyzing);
    }
  }

  void _handleServerError(Map<String, dynamic> error) {
    // Fields are 'isFatal', 'message', and 'stackTrace'.
    _logger.printError('Error from the analysis server: ${error['message']}');
    if (error['stackTrace'] != null) {
      _logger.printError(error['stackTrace'] as String);
    }
    _didServerErrorOccur = true;
  }

  void _handleAnalysisIssues(Map<String, dynamic> issueInfo) {
    // {"event":"analysis.errors","params":{"file":"/Users/.../lib/main.dart","errors":[]}}
    final String file = issueInfo['file'] as String;
    final List<dynamic> errorsList = issueInfo['errors'] as List<dynamic>;
    final List<AnalysisError> errors = errorsList
        .map<Map<String, dynamic>>(castStringKeyedMap)
        .map<AnalysisError>((Map<String, dynamic> json) {
          return AnalysisError(json,
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

  Future<bool> dispose() async {
    await _analyzingController.close();
    await _errorsController.close();
    return _process?.kill();
  }
}

enum _AnalysisSeverity {
  error,
  warning,
  info,
  none,
}

class AnalysisError implements Comparable<AnalysisError> {
  AnalysisError(this.json, {
    @required Platform platform,
    @required Terminal terminal,
    @required FileSystem fileSystem,
  }) : _platform = platform,
       _terminal = terminal,
       _fileSystem = fileSystem;

  final Platform _platform;
  final Terminal _terminal;
  final FileSystem _fileSystem;

  static final Map<String, _AnalysisSeverity> _severityMap = <String, _AnalysisSeverity>{
    'INFO': _AnalysisSeverity.info,
    'WARNING': _AnalysisSeverity.warning,
    'ERROR': _AnalysisSeverity.error,
  };

  String  get _separator => _platform.isWindows ? '-' : '•';

  // "severity":"INFO","type":"TODO","location":{
  //   "file":"/Users/.../lib/test.dart","offset":362,"length":72,"startLine":15,"startColumn":4
  // },"message":"...","hasFix":false}
  Map<String, dynamic> json;

  String get severity => json['severity'] as String;
  String get colorSeverity {
    switch(_severityLevel) {
      case _AnalysisSeverity.error:
        return _terminal.color(severity, TerminalColor.red);
      case _AnalysisSeverity.warning:
        return _terminal.color(severity, TerminalColor.yellow);
      case _AnalysisSeverity.info:
      case _AnalysisSeverity.none:
        return severity;
    }
    return null;
  }
  _AnalysisSeverity get _severityLevel => _severityMap[severity] ?? _AnalysisSeverity.none;
  String get type => json['type'] as String;
  String get message => json['message'] as String;
  String get code => json['code'] as String;

  String get file => json['location']['file'] as String;
  int get startLine => json['location']['startLine'] as int;
  int get startColumn => json['location']['startColumn'] as int;
  int get offset => json['location']['offset'] as int;

  String get messageSentenceFragment {
    if (message.endsWith('.')) {
      return message.substring(0, message.length - 1);
    } else {
      return message;
    }
  }

  @override
  int compareTo(AnalysisError other) {
    // Sort in order of file path, error location, severity, and message.
    if (file != other.file) {
      return file.compareTo(other.file);
    }

    if (offset != other.offset) {
      return offset - other.offset;
    }

    final int diff = other._severityLevel.index - _severityLevel.index;
    if (diff != 0) {
      return diff;
    }

    return message.compareTo(other.message);
  }

  @override
  String toString() {
    // Can't use "padLeft" because of ANSI color sequences in the colorized
    // severity.
    final String padding = ' ' * math.max(0, 7 - severity.length);
    return '$padding${colorSeverity.toLowerCase()} $_separator '
        '$messageSentenceFragment $_separator '
        '${_fileSystem.path.relative(file)}:$startLine:$startColumn $_separator '
        '$code';
  }

  String toLegacyString() {
    return '[${severity.toLowerCase()}] $messageSentenceFragment ($file:$startLine:$startColumn)';
  }
}

class FileAnalysisErrors {
  FileAnalysisErrors(this.file, this.errors);

  final String file;
  final List<AnalysisError> errors;
}
