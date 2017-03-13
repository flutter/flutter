// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:stack_trace/stack_trace.dart';

import 'base/io.dart';
import 'globals.dart';
import 'usage.dart';

/// Tells crash backend that the error is from the Flutter CLI.
String _kProductId = 'Flutter_Tools';

/// Tells crash backend that this is a Dart error as opposed to, say, Java.
String _kDartTypeId = 'DartError';

/// Crash backend host.
String _kCrashServerHost = 'clients2.google.com';

/// Path to the crash servlet.
// TODO(yjbanov): switch to non-staging when production is ready.
String _kCrashEndpointPath = '/cr/staging_report';

/// The field corresponding to the multipart/form-data file attachment where
/// crash backend expects to find the Dart stack trace.
String _kStackTraceFileField = 'DartError';

/// The name of the file attached as [_kStackTraceFileField].
///
/// The precise value is not important. It is ignored by the crash back end, but
/// it must be supplied in the request.
String _kStackTraceFilename = 'stacktrace_file';

/// We only send crash reports in testing mode.
///
/// See [enterTestingMode] and [exitTestingMode].
bool _testing = false;

/// Sends crash reports to Google.
class CrashReportSender {
  static final Uri _baseUri = new Uri(
      scheme: 'https',
      host: _kCrashServerHost,
      port: 443,
      path: _kCrashEndpointPath,
  );

  static CrashReportSender _instance;

  CrashReportSender._(this._client);

  static CrashReportSender get instance => _instance ?? new CrashReportSender._(new http.Client());

  /// Overrides the default [http.Client] with [client] for testing purposes.
  @visibleForTesting
  static void initializeWith(http.Client client) {
    _instance = new CrashReportSender._(client);
  }

  final http.Client _client;
  final Usage _usage = Usage.instance;

  /// Sends one crash report.
  ///
  /// The report is populated from data in [error] and [stackTrace].
  Future<Null> sendReport({
    @required dynamic error,
    @required dynamic stackTrace,
    @required String getFlutterVersion(),
  }) async {
    try {
      // TODO(yjbanov): we only actually send crash reports in tests. When we
      // iron out the process, we will remove this guard and report crashes
      // when !flutterUsage.suppressAnalytics.
      if (!_testing)
        return null;

      if (_usage.suppressAnalytics)
        return null;

      printStatus('Sending crash report to Google.');

      final String flutterVersion = getFlutterVersion();
      final Uri uri = _baseUri.replace(
        queryParameters: <String, String>{
          'product': _kProductId,
          'version': flutterVersion,
        },
      );

      final http.MultipartRequest req = new http.MultipartRequest('POST', uri);
      req.fields['product'] = _kProductId;
      req.fields['version'] = flutterVersion;
      req.fields['type'] = _kDartTypeId;
      req.fields['error_runtime_type'] = '${error.runtimeType}';

      final Chain chain = stackTrace is StackTrace
          ? new Chain.forTrace(stackTrace)
          : new Chain.parse(stackTrace.toString());

      req.files.add(new http.MultipartFile.fromString(
        _kStackTraceFileField,
        '${chain.terse}',
        filename: _kStackTraceFilename,
      ));

      final http.StreamedResponse resp = await _client.send(req);

      if (resp.statusCode == 200) {
        final String reportId = await new http.ByteStream(resp.stream)
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
}

/// Enables testing mode.
@visibleForTesting
void enterTestingMode() {
  _testing = true;
}

/// Disables testing mode.
@visibleForTesting
void exitTestingMode() {
  _testing = false;
}
