// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/context.dart';
import '../globals.dart';
import 'common.dart';
import 'io.dart';
import 'platform.dart';

const int kNetworkProblemExitCode = 50;

typedef HttpClientFactory = HttpClient Function();

/// Download a file from the given URL and return the bytes.
Future<List<int>> fetchUrl(Uri url, {int maxAttempts}) async {
  int attempts = 0;
  int durationSeconds = 1;
  while (true) {
    attempts += 1;
    final List<int> result = await _attempt(url);
    if (result != null)
      return result;
    if (maxAttempts != null && attempts >= maxAttempts) {
      printStatus('Download failed -- retry $attempts');
      return null;
    }
    printStatus('Download failed -- attempting retry $attempts in '
        '$durationSeconds second${ durationSeconds == 1 ? "" : "s"}...');
    await Future<void>.delayed(Duration(seconds: durationSeconds));
    if (durationSeconds < 64)
      durationSeconds *= 2;
  }
}

/// Check if the given URL points to a valid endpoint.
Future<bool> doesRemoteFileExist(Uri url) async =>
  (await _attempt(url, onlyHeaders: true)) != null;

Future<List<int>> _attempt(Uri url, { bool onlyHeaders = false }) async {
  printTrace('Downloading: $url');
  HttpClient httpClient;
  if (context.get<HttpClientFactory>() != null) {
    httpClient = context.get<HttpClientFactory>()();
  } else {
    httpClient = HttpClient();
  }
  HttpClientRequest request;
  try {
    if (onlyHeaders) {
      request = await httpClient.headUrl(url);
    } else {
      request = await httpClient.getUrl(url);
    }
  } on ArgumentError catch (error) {
    final String overrideUrl = platform.environment['FLUTTER_STORAGE_BASE_URL'];
    if (overrideUrl != null && url.toString().contains(overrideUrl)) {
      printError(error.toString());
      throwToolExit(
        'The value of FLUTTER_STORAGE_BASE_URL ($overrideUrl) could not be '
        'parsed as a valid url. Please see https://flutter.dev/community/china '
        'for an example of how to use it.\n'
        'Full URL: $url',
        exitCode: kNetworkProblemExitCode,);
    }
    printError(error.toString());
    rethrow;
  } on HandshakeException catch (error) {
    printTrace(error.toString());
    throwToolExit(
      'Could not authenticate download server. You may be experiencing a man-in-the-middle attack,\n'
      'your network may be compromised, or you may have malware installed on your computer.\n'
      'URL: $url',
      exitCode: kNetworkProblemExitCode,
    );
  } on SocketException catch (error) {
    printTrace('Download error: $error');
    return null;
  } on HttpException catch (error) {
    printTrace('Download error: $error');
    return null;
  }
  final HttpClientResponse response = await request.close();
  // If we're making a HEAD request, we're only checking to see if the URL is
  // valid.
  if (onlyHeaders) {
    return (response.statusCode == 200) ? <int>[] : null;
  }
  if (response.statusCode != 200) {
    if (response.statusCode > 0 && response.statusCode < 500) {
      throwToolExit(
        'Download failed.\n'
        'URL: $url\n'
        'Error: ${response.statusCode} ${response.reasonPhrase}',
        exitCode: kNetworkProblemExitCode,
      );
    }
    // 5xx errors are server errors and we can try again
    printTrace('Download error: ${response.statusCode} ${response.reasonPhrase}');
    return null;
  }
  printTrace('Received response from server, collecting bytes...');
  try {
    final BytesBuilder responseBody = BytesBuilder(copy: false);
    await response.forEach(responseBody.add);
    return responseBody.takeBytes();
  } on IOException catch (error) {
    printTrace('Download error: $error');
    return null;
  }
}
