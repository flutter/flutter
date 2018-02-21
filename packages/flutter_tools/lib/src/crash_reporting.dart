// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:stack_trace/stack_trace.dart';

import 'base/io.dart';
import 'base/os.dart';
import 'base/platform.dart';
import 'globals.dart';
import 'usage.dart';

/// Tells crash backend that the error is from the Flutter CLI.
const String _kProductId = 'Flutter_Tools';

/// Tells crash backend that this is a Dart error as opposed to, say, Java.
const String _kDartTypeId = 'DartError';

/// Crash backend host.
const String _kCrashServerHost = 'clients2.google.com';

/// Path to the crash servlet.
const String _kCrashEndpointPath = '/cr/report';

/// The field corresponding to the multipart/form-data file attachment where
/// crash backend expects to find the Dart stack trace.
const String _kStackTraceFileField = 'DartError';

/// The name of the file attached as [_kStackTraceFileField].
///
/// The precise value is not important. It is ignored by the crash back end, but
/// it must be supplied in the request.
const String _kStackTraceFilename = 'stacktrace_file';

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
    @required StackTrace stackTrace,
    @required String getFlutterVersion(),
  }) async {
    try {
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
      req.fields['uuid'] = _usage.clientId;
      req.fields['product'] = _kProductId;
      req.fields['version'] = flutterVersion;
      req.fields['osName'] = platform.operatingSystem;
      req.fields['osVersion'] = os.name; // this actually includes version
      req.fields['type'] = _kDartTypeId;
      req.fields['error_runtime_type'] = '${error.runtimeType}';

      final String stackTraceWithRelativePaths = new Chain.parse(stackTrace.toString()).terse.toString();
      req.files.add(new http.MultipartFile.fromString(
        _kStackTraceFileField,
        stackTraceWithRelativePaths,
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
