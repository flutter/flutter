// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of reporting;

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
///
/// There are two ways to override the behavior of this class:
///
/// * Define a `FLUTTER_CRASH_SERVER_BASE_URL` environment variable that points
///   to a custom crash reporting server. This is useful if your development
///   environment is behind a firewall and unable to send crash reports to
///   Google, or when you wish to use your own server for collecting crash
///   reports from Flutter Tools.
class CrashReportSender {
  CrashReportSender({
    @required http.Client client,
    @required Usage usage,
    @required Platform platform,
    @required Logger logger,
    @required OperatingSystemUtils operatingSystemUtils,
  }) : _client = client,
      _usage = usage,
      _platform = platform,
      _logger = logger,
      _operatingSystemUtils = operatingSystemUtils;

  final http.Client _client;
  final Usage _usage;
  final Platform _platform;
  final Logger _logger;
  final OperatingSystemUtils _operatingSystemUtils;

  bool _crashReportSent = false;

  Uri get _baseUrl {
    final String overrideUrl = _platform.environment['FLUTTER_CRASH_SERVER_BASE_URL'];

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
    @required String command,
  }) async {
    // Only send one crash report per run.
    if (_crashReportSent) {
      return;
    }
    try {
      final String flutterVersion = getFlutterVersion();

      // We don't need to report exceptions happening on user branches
      if (_usage.suppressAnalytics || RegExp(r'^\[user-branch\]\/').hasMatch(flutterVersion)) {
        return;
      }

      _logger.printTrace('Sending crash report to Google.');

      final Uri uri = _baseUrl.replace(
        queryParameters: <String, String>{
          'product': _kProductId,
          'version': flutterVersion,
        },
      );

      final http.MultipartRequest req = http.MultipartRequest('POST', uri);
      req.fields['uuid'] = _usage.clientId;
      req.fields['product'] = _kProductId;
      req.fields['version'] = flutterVersion;
      req.fields['osName'] = _platform.operatingSystem;
      req.fields['osVersion'] = _operatingSystemUtils.name; // this actually includes version
      req.fields['type'] = _kDartTypeId;
      req.fields['error_runtime_type'] = '${error.runtimeType}';
      req.fields['error_message'] = '$error';
      req.fields['comments'] = command;

      req.files.add(http.MultipartFile.fromString(
        _kStackTraceFileField,
        stackTrace.toString(),
        filename: _kStackTraceFilename,
      ));

      final http.StreamedResponse resp = await _client.send(req);

      if (resp.statusCode == 200) {
        final String reportId = await http.ByteStream(resp.stream)
          .bytesToString();
        _logger.printTrace('Crash report sent (report ID: $reportId)');
        _crashReportSent = true;
      } else {
        _logger.printError('Failed to send crash report. Server responded with HTTP status code ${resp.statusCode}');
      }
    // Catch all exceptions to print the message that makes clear that the
    // crash logger crashed.
    } catch (sendError, sendStackTrace) { // ignore: avoid_catches_without_on_clauses
      if (sendError is SocketException || sendError is HttpException) {
        _logger.printError('Failed to send crash report due to a network error: $sendError');
      } else {
        // If the sender itself crashes, just print. We did our best.
        _logger.printError('Crash report sender itself crashed: $sendError\n$sendStackTrace');
      }
    }
  }
}
