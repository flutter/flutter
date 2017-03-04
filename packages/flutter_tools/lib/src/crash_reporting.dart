// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

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

bool _testing = false;

/// Sends crash reports to Google.
class CrashReportSender {
  static final Uri _defaultBaseUri = new Uri(
      scheme: 'https',
      host: _kCrashServerHost,
      port: 443,
      path: _kCrashEndpointPath,
  );

  static Uri _baseUri = _defaultBaseUri;

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
    @required String flutterVersion,
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

      final Uri uri = _baseUri.replace(
        queryParameters: <String, String>{
          'product': _kProductId,
          'version': flutterVersion,
        },
      );

      final _MultipartRequest req = new _MultipartRequest('POST', uri);
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

/// Overrides [CrashReportSender._baseUri] for testing and enables testing
/// mode.
@visibleForTesting
void overrideBaseCrashUrlForTesting(Uri uri) {
  CrashReportSender._baseUri = uri;
  _testing = true;
}

/// Resets [CrashReportSender._baseUri] back to the original value and disables
/// test mode.
@visibleForTesting
void resetBaseCrashUrlForTesting() {
  CrashReportSender._baseUri = CrashReportSender._defaultBaseUri;
  _testing = false;
}


// Below is a patched version of the MultipartRequest class from package:http
// made to conform to Flutter's style guide and to comply with the crash
// reporting backend. Specifically, the backend does not correctly handle quoted
// boundary values. The implementation below:
//   - reduces boundary character set to those that do not need quotes
//   - compensates for the smaller set by generating a longer boundary value

final RegExp _newlineRegExp = new RegExp(r"\r\n|\r|\n");

/// A `multipart/form-data` request. Such a request has both string [fields],
/// which function as normal form fields, and (potentially streamed) binary
/// [files].
///
/// This request automatically sets the Content-Type header to
/// `multipart/form-data`. This value will override any value set by the user.
///
///     var uri = Uri.parse("http://pub.dartlang.org/packages/create");
///     var request = new http.MultipartRequest("POST", url);
///     request.fields['user'] = 'nweiz@google.com';
///     request.files.add(new http.MultipartFile.fromFile(
///         'package',
///         new File('build/package.tar.gz'),
///         contentType: new MediaType('application', 'x-tar'));
///     request.send().then((response) {
///       if (response.statusCode == 200) print("Uploaded!");
///     });
class _MultipartRequest extends http.BaseRequest {
  /// The total length of the multipart boundaries used when building the
  /// request body. According to http://tools.ietf.org/html/rfc1341.html, this
  /// can't be longer than 70.
  static const int _BOUNDARY_LENGTH = 70;

  static final Random _random = new Random();

  /// The form fields to send for this request.
  final Map<String, String> fields;

  /// The private version of [files].
  final List<http.MultipartFile> _files;

  /// Creates a new [MultipartRequest].
  _MultipartRequest(String method, Uri url)
      : fields = <String, String>{},
        _files = <http.MultipartFile>[],
        super(method, url);

  /// The list of files to upload for this request.
  List<http.MultipartFile> get files => _files;

  /// The total length of the request body, in bytes. This is calculated from
  /// [fields] and [files] and cannot be set manually.
  @override
  int get contentLength {
    int length = 0;

    fields.forEach((String name, String value) {
      length += "--".length + _BOUNDARY_LENGTH + "\r\n".length +
          UTF8.encode(_headerForField(name, value)).length +
          UTF8.encode(value).length + "\r\n".length;
    });

    for (http.MultipartFile file in _files) {
      length += "--".length + _BOUNDARY_LENGTH + "\r\n".length +
          UTF8.encode(_headerForFile(file)).length +
          file.length + "\r\n".length;
    }

    return length + "--".length + _BOUNDARY_LENGTH + "--\r\n".length;
  }

  @override
  set contentLength(int value) {
    throw new UnsupportedError("Cannot set the contentLength property of "
        "multipart requests.");
  }

  /// Freezes all mutable fields and returns a single-subscription [ByteStream]
  /// that will emit the request body.
  @override
  http.ByteStream finalize() {
    final String boundary = _boundaryString();
    headers['content-type'] = 'multipart/form-data; boundary=$boundary';
    super.finalize();

    final StreamController<List<int>> controller = new StreamController<List<int>>(sync: true);

    void writeAscii(String string) {
      controller.add(UTF8.encode(string));
    }

    void writeUtf8(String string) {
      controller.add(UTF8.encode(string));
    }
    void writeLine() {
      controller.add(<int>[13, 10]); // \r\n
    }

    fields.forEach((String name, String value) {
      writeAscii('--$boundary\r\n');
      writeAscii(_headerForField(name, value));
      writeUtf8(value);
      writeLine();
    });

    Future.forEach(_files, (http.MultipartFile file) {
      writeAscii('--$boundary\r\n');
      writeAscii(_headerForFile(file));
      return writeStreamToSink(file.finalize(), controller)
          .then((dynamic _) => writeLine());
    }).then<Null>((dynamic _) {
      writeAscii('--$boundary--\r\n');
      controller.close();
    });

    return new http.ByteStream(controller.stream);
  }

  /// Valid boundary character codes that do not need to be quoted. From
  /// http://tools.ietf.org/html/rfc2046#section-5.1.1.
  static const List<int> _BOUNDARY_CHARACTERS = const <int>[
    // Digits
    48,
    49,
    50,
    51,
    52,
    53,
    54,
    55,
    56,
    57,
    // Capital letters
    65,
    66,
    67,
    68,
    69,
    70,
    71,
    72,
    73,
    74,
    75,
    76,
    77,
    78,
    79,
    80,
    81,
    82,
    83,
    84,
    85,
    86,
    87,
    88,
    89,
    90,
    // Small letters
    97,
    98,
    99,
    100,
    101,
    102,
    103,
    104,
    105,
    106,
    107,
    108,
    109,
    110,
    111,
    112,
    113,
    114,
    115,
    116,
    117,
    118,
    119,
    120,
    121,
    122,
  ];

  /// Returns the header string for a field. The return value is guaranteed to
  /// contain only ASCII characters.
  String _headerForField(String name, String value) {
    String header =
        'content-disposition: form-data; name="${_browserEncode(name)}"';
    if (!isPlainAscii(value)) {
      header = '$header\r\n'
          'content-type: text/plain; charset=utf-8\r\n'
          'content-transfer-encoding: binary';
    }
    return '$header\r\n\r\n';
  }

  /// Returns the header string for a file. The return value is guaranteed to
  /// contain only ASCII characters.
  String _headerForFile(http.MultipartFile file) {
    String header = 'content-type: ${file.contentType}\r\n'
        'content-disposition: form-data; name="${_browserEncode(file.field)}"';

    if (file.filename != null) {
      header = '$header; filename="${_browserEncode(file.filename)}"';
    }
    return '$header\r\n\r\n';
  }

  /// Encode [value] in the same way browsers do.
  String _browserEncode(String value) {
    // http://tools.ietf.org/html/rfc2388 mandates some complex encodings for
    // field names and file names, but in practice user agents seem not to
    // follow this at all. Instead, they URL-encode `\r`, `\n`, and `\r\n` as
    // `\r\n`; URL-encode `"`; and do nothing else (even for `%` or non-ASCII
    // characters). We follow their behavior.
    return value.replaceAll(_newlineRegExp, "%0D%0A").replaceAll('"', "%22");
  }

  /// Returns a randomly-generated multipart boundary string
  String _boundaryString() {
    final String prefix = "dart-";
    final List<int> list = new List<int>.generate(_BOUNDARY_LENGTH - prefix.length,
            (int index) =>
        _BOUNDARY_CHARACTERS[_random.nextInt(_BOUNDARY_CHARACTERS.length)],
        growable: false);
    return "$prefix${new String.fromCharCodes(list)}";
  }
}

/// Pipes all data and errors from [stream] into [sink]. Completes [Future] once
/// [stream] is done. Unlike [store], [sink] remains open after [stream] is
/// done.
Future<Null> writeStreamToSink<O, I extends O>(Stream<I> stream, EventSink<O> sink) {
  final Completer<Null> completer = new Completer<Null>();
  stream.listen(sink.add,
      onError: sink.addError,
      onDone: () => completer.complete());
  return completer.future;
}

/// A regular expression that matches strings that are composed entirely of
/// ASCII-compatible characters.
final RegExp _kAsciiOnly = new RegExp(r"^[\x00-\x7F]+$");

/// Returns whether [string] is composed entirely of ASCII-compatible
/// characters.
bool isPlainAscii(String string) => _kAsciiOnly.hasMatch(string);
