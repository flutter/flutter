// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import '../base/file_system.dart' hide IOSink;
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/platform.dart';
import '../base/process_manager.dart';
import '../base/terminal.dart';
import '../base/utils.dart';
import '../globals.dart';

class AnalysisServer {
  AnalysisServer(this.sdkPath, this.directories);

  final String sdkPath;
  final List<String> directories;

  Process _process;
  final StreamController<bool> _analyzingController =
      StreamController<bool>.broadcast();
  final StreamController<FileAnalysisErrors> _errorsController =
      StreamController<FileAnalysisErrors>.broadcast();

  int _id = 0;

  Future<void> start() async {
    final String snapshot =
        fs.path.join(sdkPath, 'bin/snapshots/analysis_server.dart.snapshot');
    final List<String> command = <String>[
      fs.path.join(sdkPath, 'bin', 'dart'),
      snapshot,
      '--sdk',
      sdkPath,
    ];

    printTrace('dart ${command.skip(1).join(' ')}');
    _process = await processManager.start(command);
    // This callback hookup can't throw.
    _process.exitCode.whenComplete(() => _process = null); // ignore: unawaited_futures

    final Stream<String> errorStream =
        _process.stderr.transform<String>(utf8.decoder).transform<String>(const LineSplitter());
    errorStream.listen(printError);

    final Stream<String> inStream =
        _process.stdout.transform<String>(utf8.decoder).transform<String>(const LineSplitter());
    inStream.listen(_handleServerResponse);

    _sendCommand('server.setSubscriptions', <String, dynamic>{
      'subscriptions': <String>['STATUS']
    });

    _sendCommand('analysis.setAnalysisRoots',
        <String, dynamic>{'included': directories, 'excluded': <String>[]});
  }

  Stream<bool> get onAnalyzing => _analyzingController.stream;
  Stream<FileAnalysisErrors> get onErrors => _errorsController.stream;

  Future<int> get onExit => _process.exitCode;

  void _sendCommand(String method, Map<String, dynamic> params) {
    final String message = json.encode(<String, dynamic>{
      'id': (++_id).toString(),
      'method': method,
      'params': params
    });
    _process.stdin.writeln(message);
    printTrace('==> $message');
  }

  void _handleServerResponse(String line) {
    printTrace('<== $line');

    final dynamic response = json.decode(line);

    if (response is Map<dynamic, dynamic>) {
      if (response['event'] != null) {
        final String event = response['event'];
        final dynamic params = response['params'];

        if (params is Map<dynamic, dynamic>) {
          if (event == 'server.status')
            _handleStatus(response['params']);
          else if (event == 'analysis.errors')
            _handleAnalysisIssues(response['params']);
          else if (event == 'server.error')
            _handleServerError(response['params']);
        }
      } else if (response['error'] != null) {
        // Fields are 'code', 'message', and 'stackTrace'.
        final Map<String, dynamic> error = response['error'];
        printError(
            'Error response from the server: ${error['code']} ${error['message']}');
        if (error['stackTrace'] != null) {
          printError(error['stackTrace']);
        }
      }
    }
  }

  void _handleStatus(Map<String, dynamic> statusInfo) {
    // {"event":"server.status","params":{"analysis":{"isAnalyzing":true}}}
    if (statusInfo['analysis'] != null && !_analyzingController.isClosed) {
      final bool isAnalyzing = statusInfo['analysis']['isAnalyzing'];
      _analyzingController.add(isAnalyzing);
    }
  }

  void _handleServerError(Map<String, dynamic> error) {
    // Fields are 'isFatal', 'message', and 'stackTrace'.
    printError('Error from the analysis server: ${error['message']}');
    if (error['stackTrace'] != null) {
      printError(error['stackTrace']);
    }
  }

  void _handleAnalysisIssues(Map<String, dynamic> issueInfo) {
    // {"event":"analysis.errors","params":{"file":"/Users/.../lib/main.dart","errors":[]}}
    final String file = issueInfo['file'];
    final List<dynamic> errorsList = issueInfo['errors'];
    final List<AnalysisError> errors = errorsList
        .map<Map<String, dynamic>>(castStringKeyedMap)
        .map<AnalysisError>((Map<String, dynamic> json) => AnalysisError(json))
        .toList();
    if (!_errorsController.isClosed)
      _errorsController.add(FileAnalysisErrors(file, errors));
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
  AnalysisError(this.json);

  static final Map<String, _AnalysisSeverity> _severityMap = <String, _AnalysisSeverity>{
    'INFO': _AnalysisSeverity.info,
    'WARNING': _AnalysisSeverity.warning,
    'ERROR': _AnalysisSeverity.error,
  };

  static final String _separator = platform.isWindows ? '-' : '•';

  // "severity":"INFO","type":"TODO","location":{
  //   "file":"/Users/.../lib/test.dart","offset":362,"length":72,"startLine":15,"startColumn":4
  // },"message":"...","hasFix":false}
  Map<String, dynamic> json;

  String get severity => json['severity'];
  String get colorSeverity {
    switch(_severityLevel) {
      case _AnalysisSeverity.error:
        return terminal.color(severity, TerminalColor.red);
      case _AnalysisSeverity.warning:
        return terminal.color(severity, TerminalColor.yellow);
      case _AnalysisSeverity.info:
      case _AnalysisSeverity.none:
        return severity;
    }
    return null;
  }
  _AnalysisSeverity get _severityLevel => _severityMap[severity] ?? _AnalysisSeverity.none;
  String get type => json['type'];
  String get message => json['message'];
  String get code => json['code'];

  String get file => json['location']['file'];
  int get startLine => json['location']['startLine'];
  int get startColumn => json['location']['startColumn'];
  int get offset => json['location']['offset'];

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
    if (file != other.file)
      return file.compareTo(other.file);

    if (offset != other.offset)
      return offset - other.offset;

    final int diff = other._severityLevel.index - _severityLevel.index;
    if (diff != 0)
      return diff;

    return message.compareTo(other.message);
  }

  @override
  String toString() {
    // Can't use "padLeft" because of ANSI color sequences in the colorized
    // severity.
    final String padding = ' ' * math.max(0, 7 - severity.length);
    return '$padding${colorSeverity.toLowerCase()} $_separator '
        '$messageSentenceFragment $_separator '
        '${fs.path.relative(file)}:$startLine:$startColumn $_separator '
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
