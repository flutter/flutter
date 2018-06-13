// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/context.dart';
import '../globals.dart';
import 'common.dart';
import 'io.dart';

const int kNetworkProblemExitCode = 50;

typedef HttpClient HttpClientFactory();

/// Download a file from the given URL and return the bytes.
Future<List<int>> fetchUrl(Uri url) async {
  int attempts = 0;
  int duration = 1;
  while (true) {
    attempts += 1;
    final List<int> result = await _attempt(url);
    if (result != null)
      return result;
    printStatus('Download failed -- attempting retry $attempts in $duration second${ duration == 1 ? "" : "s"}...');
    await new Future<Null>.delayed(new Duration(seconds: duration));
    if (duration < 64)
      duration *= 2;
  }
}

Future<List<int>> _attempt(Uri url) async {
  printTrace('Downloading: $url');
  HttpClient httpClient;
  if (context[HttpClientFactory] != null) {
    httpClient = context[HttpClientFactory]();
  } else {
    httpClient = new HttpClient();
  }
  HttpClientRequest request;
  try {
    request = await httpClient.getUrl(url);
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
  }
  final HttpClientResponse response = await request.close();
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
    final BytesBuilder responseBody = new BytesBuilder(copy: false);
    await response.forEach(responseBody.add);
    return responseBody.takeBytes();
  } on IOException catch (error) {
    printTrace('Download error: $error');
    return null;
  }
}
