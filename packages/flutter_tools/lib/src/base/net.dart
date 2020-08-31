// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../convert.dart';
import 'common.dart';
import 'file_system.dart';
import 'io.dart';
import 'logger.dart';
import 'platform.dart';

const int kNetworkProblemExitCode = 50;

typedef HttpClientFactory = HttpClient Function();

typedef UrlTunneller = Future<String> Function(String url);

class Net {
  Net({
    HttpClientFactory httpClientFactory,
    @required Logger logger,
    @required Platform platform,
  }) :
    _httpClientFactory = httpClientFactory,
    _logger = logger,
    _platform = platform;

  final HttpClientFactory _httpClientFactory;

  final Logger _logger;

  final Platform _platform;

  /// Download a file from the given URL.
  ///
  /// If a destination file is not provided, returns the bytes.
  ///
  /// If a destination file is provided, streams the bytes to that file and
  /// returns an empty list.
  ///
  /// If [maxAttempts] is exceeded, returns null.
  Future<List<int>> fetchUrl(Uri url, {
    int maxAttempts,
    File destFile,
  }) async {
    int attempts = 0;
    int durationSeconds = 1;
    while (true) {
      attempts += 1;
      _MemoryIOSink memorySink;
      IOSink sink;
      if (destFile == null) {
        memorySink = _MemoryIOSink();
        sink = memorySink;
      } else {
        sink = destFile.openWrite();
      }

      final dynamic result = await _attempt(
        url,
        destSink: sink,
      );
      if (result == null) {
        return memorySink?.writes?.takeBytes() ?? <int>[];
      }

      if (maxAttempts != null && attempts >= maxAttempts) {
        assert(result != null);
        _logger.printStatus('Download failed -- retry $attempts');
        throw result;
      }
      _logger.printStatus(
        'Download failed -- attempting retry $attempts in '
        '$durationSeconds second${ durationSeconds == 1 ? "" : "s"}...',
      );
      await Future<void>.delayed(Duration(seconds: durationSeconds));
      if (durationSeconds < 64) {
        durationSeconds *= 2;
      }
    }
  }

  /// Check if the given URL points to a valid endpoint.
  Future<bool> doesRemoteFileExist(Uri url) async => (await _attempt(url, onlyHeaders: true)) == null;

  // Returns null on success and the last error on a failure.
  Future<dynamic> _attempt(Uri url, {
    IOSink destSink,
    bool onlyHeaders = false,
  }) async {
    assert(onlyHeaders || destSink != null);
    _logger.printTrace('Downloading: $url');
    HttpClient httpClient;
    if (_httpClientFactory != null) {
      httpClient = _httpClientFactory();
    } else {
      httpClient = HttpClient();
    }
    HttpClientRequest request;
    HttpClientResponse response;
    try {
      if (onlyHeaders) {
        request = await httpClient.headUrl(url);
      } else {
        request = await httpClient.getUrl(url);
      }
      response = await request.close();
    } on ArgumentError catch (error) {
      final String overrideUrl = _platform.environment['FLUTTER_STORAGE_BASE_URL'];
      if (overrideUrl != null && url.toString().contains(overrideUrl)) {
        _logger.printError(error.toString());
        throwToolExit(
          'The value of FLUTTER_STORAGE_BASE_URL ($overrideUrl) could not be '
          'parsed as a valid url. Please see https://flutter.dev/community/china '
          'for an example of how to use it.\n'
          'Full URL: $url',
          exitCode: kNetworkProblemExitCode,);
      }
      _logger.printError(error.toString());
      return error;
    } on HandshakeException catch (error) {
      _logger.printTrace(error.toString());
      throwToolExit(
        'Could not authenticate download server. You may be experiencing a man-in-the-middle attack,\n'
        'your network may be compromised, or you may have malware installed on your computer.\n'
        'URL: $url',
        exitCode: kNetworkProblemExitCode,
      );
    } on SocketException catch (error) {
      _logger.printTrace('Download error: $error');
      return error;
    } on HttpException catch (error) {
      _logger.printTrace('Download error: $error');
      return error;
    }
    assert(response != null);

    if (response.statusCode != HttpStatus.ok) {
      _logger.printTrace('Download error: ${response.statusCode} ${response.reasonPhrase}');
      final Exception exception = Exception(
        'Download failed.\n'
        'URL: $url\n'
        'Error: ${response.statusCode} ${response.reasonPhrase}',
      );
      // 5xx errors are server errors and we can try again
      return exception;
    }
    // If we're making a HEAD request, we're only checking to see if the URL is
    // valid.
    if (onlyHeaders) {
      return null;
    }
    _logger.printTrace('Received response from server, collecting bytes...');
    try {
      assert(destSink != null);
      await response.forEach(destSink.add);
      return null;
    } on IOException catch (error) {
      _logger.printTrace('Download error: $error');
      return error;
    } finally {
      await destSink?.flush();
      await destSink?.close();
    }
  }
}



/// An IOSink that collects whatever is written to it.
class _MemoryIOSink implements IOSink {
  @override
  Encoding encoding = utf8;

  final BytesBuilder writes = BytesBuilder(copy: false);

  @override
  void add(List<int> data) {
    writes.add(data);
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) {
    final Completer<void> completer = Completer<void>();
    stream.listen(add).onDone(completer.complete);
    return completer.future;
  }

  @override
  void writeCharCode(int charCode) {
    add(<int>[charCode]);
  }

  @override
  void write(Object obj) {
    add(encoding.encode('$obj'));
  }

  @override
  void writeln([ Object obj = '' ]) {
    add(encoding.encode('$obj\n'));
  }

  @override
  void writeAll(Iterable<dynamic> objects, [ String separator = '' ]) {
    bool addSeparator = false;
    for (final dynamic object in objects) {
      if (addSeparator) {
        write(separator);
      }
      write(object);
      addSeparator = true;
    }
  }

  @override
  void addError(dynamic error, [ StackTrace stackTrace ]) {
    throw UnimplementedError();
  }

  @override
  Future<void> get done => close();

  @override
  Future<void> close() async { }

  @override
  Future<void> flush() async { }
}

/// Returns [true] if [address] is an IPv6 address.
bool isIPv6Address(String address) {
  try {
    Uri.parseIPv6Address(address);
    return true;
  } on FormatException {
    return false;
  }
}
