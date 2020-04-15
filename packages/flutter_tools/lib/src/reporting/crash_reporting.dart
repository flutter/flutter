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
/// * In tests call [initializeWith] and provide a mock implementation of
///   [http.Client].
class CrashReportSender {
  CrashReportSender._(this._client);

  static CrashReportSender _instance;

  static CrashReportSender get instance => _instance ?? CrashReportSender._(http.Client());

  bool _crashReportSent = false;

  /// Overrides the default [http.Client] with [client] for testing purposes.
  @visibleForTesting
  static void initializeWith(http.Client client) {
    _instance = CrashReportSender._(client);
  }

  final http.Client _client;
  final Usage _usage = globals.flutterUsage;

  Uri get _baseUrl {
    final String overrideUrl = globals.platform.environment['FLUTTER_CRASH_SERVER_BASE_URL'];

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

      globals.printTrace('Sending crash report to Google.');

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
      req.fields['osName'] = globals.platform.operatingSystem;
      req.fields['osVersion'] = globals.os.name; // this actually includes version
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
        globals.printTrace('Crash report sent (report ID: $reportId)');
        _crashReportSent = true;
      } else {
        globals.printError('Failed to send crash report. Server responded with HTTP status code ${resp.statusCode}');
      }
    // Catch all exceptions to print the message that makes clear that the
    // crash logger crashed.
    } catch (sendError, sendStackTrace) { // ignore: avoid_catches_without_on_clauses
      if (sendError is SocketException || sendError is HttpException) {
        globals.printError('Failed to send crash report due to a network error: $sendError');
      } else {
        // If the sender itself crashes, just print. We did our best.
        globals.printError('Crash report sender itself crashed: $sendError\n$sendStackTrace');
      }
    }
  }

  Future<void> informUserOfCrash(List<String> args, dynamic error, StackTrace stackTrace, String errorString) async {
    final String doctorText = await _doctorText();
    final File file = await _createLocalCrashReport(args, error, stackTrace, doctorText);

    globals.printError('A crash report has been written to ${file.path}.');
    globals.printStatus('This crash may already be reported. Check GitHub for similar crashes.', emphasis: true);

    final HttpClientFactory clientFactory = context.get<HttpClientFactory>();
    final GitHubTemplateCreator gitHubTemplateCreator = context.get<GitHubTemplateCreator>() ?? GitHubTemplateCreator(
      fileSystem: globals.fs,
      logger: globals.logger,
      flutterProjectFactory: globals.projectFactory,
      client: clientFactory != null ? clientFactory() : HttpClient(),
    );
    final String similarIssuesURL = GitHubTemplateCreator.toolCrashSimilarIssuesURL(errorString);
    globals.printStatus('$similarIssuesURL\n', wrap: false);
    globals.printStatus('To report your crash to the Flutter team, first read the guide to filing a bug.', emphasis: true);
    globals.printStatus('https://flutter.dev/docs/resources/bug-reports\n', wrap: false);
    globals.printStatus('Create a new GitHub issue by pasting this link into your browser and completing the issue template. Thank you!', emphasis: true);

    final String command = _crashCommand(args);
    final String gitHubTemplateURL = await gitHubTemplateCreator.toolCrashIssueTemplateGitHubURL(
      command,
      error,
      stackTrace,
      doctorText
    );
    globals.printStatus('$gitHubTemplateURL\n', wrap: false);
  }

  String _crashCommand(List<String> args) => 'flutter ${args.join(' ')}';

  String _crashException(dynamic error) => '${error.runtimeType}: $error';

  /// File system used by the crash reporting logic.
  ///
  /// We do not want to use the file system stored in the context because it may
  /// be recording. Additionally, in the case of a crash we do not trust the
  /// integrity of the [AppContext].
  @visibleForTesting
  static FileSystem crashFileSystem = const LocalFileSystem();

  /// Saves the crash report to a local file.
  Future<File> _createLocalCrashReport(List<String> args, dynamic error, StackTrace stackTrace, String doctorText) async {
    File crashFile = globals.fsUtils.getUniqueFile(
      crashFileSystem.currentDirectory,
      'flutter',
      'log',
    );

    final StringBuffer buffer = StringBuffer();

    buffer.writeln('Flutter crash report; please file at https://github.com/flutter/flutter/issues.\n');

    buffer.writeln('## command\n');
    buffer.writeln('${_crashCommand(args)}\n');

    buffer.writeln('## exception\n');
    buffer.writeln('${_crashException(error)}\n');
    buffer.writeln('```\n$stackTrace```\n');

    buffer.writeln('## flutter doctor\n');
    buffer.writeln('```\n$doctorText```');

    try {
      crashFile.writeAsStringSync(buffer.toString());
    } on FileSystemException catch (_) {
      // Fallback to the system temporary directory.
      crashFile = globals.fsUtils.getUniqueFile(
        crashFileSystem.systemTempDirectory,
        'flutter',
        'log',
      );
      try {
        crashFile.writeAsStringSync(buffer.toString());
      } on FileSystemException catch (e) {
        globals.printError('Could not write crash report to disk: $e');
        globals.printError(buffer.toString());
      }
    }

    return crashFile;
  }

  Future<String> _doctorText() async {
    try {
      final BufferLogger logger = BufferLogger(
        terminal: globals.terminal,
        outputPreferences: globals.outputPreferences,
      );

      await context.run<bool>(
        body: () => doctor.diagnose(verbose: true, showColor: false),
        overrides: <Type, Generator>{
          Logger: () => logger,
        },
      );

      return logger.statusText;
    } on Exception catch (error, trace) {
      return 'encountered exception: $error\n\n${trace.toString().trim()}\n';
    }
  }
}
