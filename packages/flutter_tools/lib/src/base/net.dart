// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../globals.dart';
import 'common.dart';
import 'io.dart';

const int kNetworkProblemExitCode = 50;

/// Download a file from the given URL and return the bytes.
Future<List<int>> fetchUrl(Uri url) async {
  printTrace('Downloading $url.');

  HttpClient httpClient = new HttpClient();
  HttpClientRequest request = await httpClient.getUrl(url);
  HttpClientResponse response = await request.close();

  printTrace('Received response statusCode=${response.statusCode}');
  if (response.statusCode != 200) {
    throwToolExit(
      'Download failed: $url\n'
          '  because (${response.statusCode}) ${response.reasonPhrase}',
      exitCode: kNetworkProblemExitCode,
    );
  }

  try {
    BytesBuilder responseBody = new BytesBuilder(copy: false);
    await for (List<int> chunk in response)
        responseBody.add(chunk);

    return responseBody.takeBytes();
  } on IOException catch (e) {
    throw new ToolExit(
      'Download failed: $url\n  $e',
      exitCode: kNetworkProblemExitCode,
    );
  }
}
