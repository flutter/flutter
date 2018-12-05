// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
// import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:stack_trace/stack_trace.dart';

import 'base/io.dart';
import 'base/os.dart';
import 'base/platform.dart';
import 'base/terminal.dart';
import 'globals.dart';
import 'usage.dart';

/// Tells crash backend that the error is from the Flutter CLI.
const String _kProductToolsId = 'Flutter_Tools';
/// Tells crash backend that the error is from the Flutter CLI.
const String _kProductEngineId = 'Flutter_Engine';

/// Tells crash backend that this is a Dart error as opposed to, say, Java.
const String _kDartTypeId = 'DartError';
/// Tells crash backend that this is a C++ error as opposed to, say, Java.
const String _kEngineTypeId = 'EngineCrash';

/// Crash backend host.
const String _kCrashServerHost = 'clients2.google.com';

/// Path to the crash servlet.
const String _kCrashEndpointPath = '/cr/report';

/// The field corresponding to the multipart/form-data file attachment where
/// crash backend expects to find the Dart stack trace.
const String _kStackTraceFileField = 'DartError';

/// The field corresponding to the multipart/form-data file attachment where
/// crash backend expects to find the Engine stack trace, registers, and general
/// error information.
const String _kEngineStackTraceFileField = 'EngineStackTrace';
const String _kEngineRegistersFileField = 'EngineRegisters';
const String _kEngineErrorFileField = 'EngineError';

/// The name of the file attached as [_kStackTraceFileField].
///
/// The precise value is not important. It is ignored by the crash back end, but
/// it must be supplied in the request.
const String _kStackTraceFilename = 'stacktrace_file';

/// Sends crash reports to Google.
///
/// There are two ways to override the behavior of this class:
///
/// * Define a `FLUTTER_CRASH_SERVER_BASE_URL` environment variable that points
///   to a custom crash reporting server. This is useful if your development
///   environment is behind a firewall and unable to send crash reports to
///   Google, or when you wish to use your own server for collecting crash
///   reports from Flutter Tools.
/// * In tests call [initializeWith] and provide a mock implementation of
///   [http.Client].
class CrashReportSender {
  CrashReportSender._(this._client);

  static CrashReportSender _instance;

  static CrashReportSender get instance => _instance ?? CrashReportSender._(http.Client());

  // Holds the crash data and stack trace for engine crashes. Since engine crashes
  // end the flutter tool, we can only crash once per run, so this is a static
  // variable.
  static EngineCrash engineCrash;

  /// Overrides the default [http.Client] with [client] for testing purposes.
  @visibleForTesting
  static void initializeWith(http.Client client) {
    _instance = CrashReportSender._(client);
  }

  final http.Client _client;
  final Usage _usage = Usage.instance;

  Uri get _baseUrl {
    final String overrideUrl = platform.environment['FLUTTER_CRASH_SERVER_BASE_URL'];

    if (overrideUrl != null) {
      return Uri.parse(overrideUrl);
    }
    return Uri(
      scheme: 'https',
      host: _kCrashServerHost,
      port: 443,
      path: _kCrashEndpointPath,
    );
  }

  /// Sends one crash report.
  ///
  /// The report is populated from data in [error] and [stackTrace].
  Future<void> sendReport({
    @required dynamic error,
    @required StackTrace stackTrace,
    @required String getFlutterVersion(),
  }) async {
    try {
      if (_usage.suppressAnalytics)
        return;

      printStatus('Sending crash report to Google.');

      final String flutterVersion = getFlutterVersion();
      final Uri uri = _baseUrl.replace(
        queryParameters: <String, String>{
          'product': _kProductToolsId,
          'version': flutterVersion,
        },
      );

      final http.MultipartRequest req = http.MultipartRequest('POST', uri);
      req.fields['uuid'] = _usage.clientId;
      req.fields['product'] = _kProductToolsId;
      req.fields['version'] = flutterVersion;
      req.fields['osName'] = platform.operatingSystem;
      req.fields['osVersion'] = os.name; // this actually includes version
      req.fields['type'] = _kDartTypeId;
      req.fields['error_runtime_type'] = '${error.runtimeType}';

      final String stackTraceWithRelativePaths = Chain.parse(stackTrace.toString()).terse.toString();
      req.files.add(http.MultipartFile.fromString(
        _kStackTraceFileField,
        stackTraceWithRelativePaths,
        filename: _kStackTraceFilename,
      ));

      final http.StreamedResponse resp = await _client.send(req);

      if (resp.statusCode == 200) {
        final String reportId = await http.ByteStream(resp.stream)
            .bytesToString();
        printStatus('Crash report sent (report ID: $reportId)');
      } else {
        printError('Failed to send crash report. Server responded with HTTP status code ${resp.statusCode}');
      }
    } catch (sendError, sendStackTrace) {
      if (sendError is SocketException) {
        printError('Failed to send crash report due to a network error: $sendError');
      } else {
        // If the sender itself crashes, just print. We did our best.
        printError('Crash report sender itself crashed: $sendError\n$sendStackTrace');
      }
    }
  }

  /// Checks if there is an engine crash report available and asks user if
  /// they want to send the report to Google.
  ///
  /// The report is populated from parsed data in engineCrash, which is in
  /// turn parsed from adb logcat.
  Future<void> checkAndSendEngineReport({
    @required String getFlutterVersion(),
  }) async {
    engineCrash = CrashReportSender.engineCrash;
    if (engineCrash == null || engineCrash.reportStatus != null) {
      return;
    }
    engineCrash.beginReport();

    printError('Flutter Engine has crashed!', emphasis: true);
    printStatus('The following error report has been generated:', emphasis: true);
    printStatus('');
    printStatus('====================================================================');
    printStatus(engineCrash.squashBacktrace());

    printStatus('ClientID: ' + _usage.clientId);
    printStatus('Flutter Version: ' + getFlutterVersion());
    printStatus('OS: ' + platform.operatingSystem);
    printStatus('OS version: ' + os.name); // this actually includes version
    printStatus('====================================================================');
    printStatus('');

    bool always = config.getValue('engine-crash-reporting'); // Read this value from disk in flutter settings.
    if (!always) {
      printStatus('Reporting this crash will help improve Flutter.', emphasis: true);
      final String input = (await terminal.promptForCharInput(
        <String>['y', 'n', 'a', 'Y', 'N', 'A'],
        prompt: 'Would you like to send this Engine crash report to Google?\n([y]es|[N]o|[a]lways)',
        defaultChoiceIndex: 1,
        displayAcceptedCharacters: false)).toLowerCase().trim();
      if (input == 'a' || input == 'always') {
        // Set flag in settings
        config.setValueBool('engine-crash-reporting', true);
        always = true;
      } else if (input == 'y' || input == 'yes') {
        // Nothing to do.
      } else if (input == 'n' || input == 'no' || input == '') {
        // "No" or no recognized response. Default to not sending report.
        printStatus('Skipped sending engine crash report.');
        engineCrash.endReport();
        return;
      }
    }
    try {
      printStatus('Sending crash report to Google.');
      if (always) {
        printStatus('===========================================================================');
        printStatus('If you would like to stop automatically sending engine crash reports, use: ');
        printStatus('  flutter config --no-engine-crash-reporting');
        printStatus('===========================================================================');
      }

      final String flutterVersion = getFlutterVersion();
      final Uri uri = _baseUrl.replace(
        queryParameters: <String, String>{
          'product': _kProductEngineId,
          'version': flutterVersion,
        },
      );

      final http.MultipartRequest req = http.MultipartRequest('POST', uri);
      req.fields['uuid'] = _usage.clientId;
      req.fields['product'] = _kProductEngineId;
      req.fields['version'] = flutterVersion;
      req.fields['osName'] = platform.operatingSystem;
      req.fields['osVersion'] = os.name; // this actually includes version
      req.fields['type'] = _kEngineTypeId;
      req.fields['signature'] = engineCrash.parseSignature();
      req.fields['error_runtime_type'] = _kEngineTypeId;

      if (engineCrash.lineContaining('backtrace') != -1) {
        req.files.add(http.MultipartFile.fromString(
          _kEngineStackTraceFileField,
          engineCrash.squashBacktrace(
            startLine: engineCrash.lineContaining('backtrace') + 1,
          ),
          filename: _kEngineStackTraceFileField,
        ));

        req.files.add(http.MultipartFile.fromString(
          _kEngineRegistersFileField,
          engineCrash.squashBacktrace(
            startLine: engineCrash.lineContaining('backtrace') - 5,
            endLine: engineCrash.lineContaining('backtrace')
          ),
          filename: _kEngineRegistersFileField,
        ));

        req.files.add(http.MultipartFile.fromString(
          _kEngineErrorFileField,
          engineCrash.squashBacktrace(
            endLine: engineCrash.lineContaining('backtrace: ') - 4,
          ),
          filename: _kEngineErrorFileField,
        ));
      } else {
        // Malformed error with no backtrace. Report entire error.
        req.files.add(http.MultipartFile.fromString(
          _kEngineErrorFileField,
          engineCrash.squashBacktrace(),
          filename: _kEngineErrorFileField,
        ));
      }

      final http.StreamedResponse resp = await _client.send(req);

      if (resp.statusCode == 200) {
        final String reportId = await http.ByteStream(resp.stream)
            .bytesToString();
        printStatus('Crash report sent (report ID: $reportId)');
      } else {
        printError('Failed to send crash report. Server responded with HTTP status code ${resp.statusCode}');
      }
    } catch (sendError, sendStackTrace) {
      if (sendError is SocketException) {
        printError('Failed to send crash report due to a network error: $sendError');
      } else {
        // If the sender itself crashes, just print. We did our best.
        printError('Crash report sender itself crashed: $sendError\n$sendStackTrace');
      }
    }
    engineCrash.endReport();
  }
}

// Holds the parsed data (from logs) of an engine crash.
class EngineCrash {

  EngineCrash() {
    error = '';
    _backtrace = <String>[];
  }

  String error;

  // Lines that make up the backtrace.
  List<String> _backtrace;

  // Completes when the report is fully submitted or skipped. Is null when
  // no report attempt has been made.
  Future<void> reportStatus;
  Completer<void> _completer;

  void addTraceLine(String line) {
    _backtrace.add(line);
  }

  // 'Locks' the report so that the program will not end while waiting for
  // input/server response.
  void beginReport() {
    _completer = Completer<void>();
    reportStatus = _completer.future;
  }

  // 'Unlocks' the report and allows the program execution to continue.
  void endReport() {
    _completer.complete();
  }

  String squashBacktrace({int startLine = 0, int endLine = -1}) {
    if (endLine < 0) {
      endLine = _backtrace.length;
    }
    String out = '';
    for (; startLine < endLine; startLine++) {
      out += _backtrace[startLine] + '\n';
    }
    return out;
  }

  int lineContaining(String str) {
    for (int i = 0; i < _backtrace.length; i++) {
      final String line = _backtrace[i];
      if (line.contains(str)) {
        return i;
      }
    }
    return -1;
  }

  String parseSignature() {
    const String signature = 'Fatal ';
    final String line = _backtrace[lineContaining('backtrace') - 5];
    return signature + line;
  }
}
