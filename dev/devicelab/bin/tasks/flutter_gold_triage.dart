// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';

const String _kTriageCountKey = 'count';

Future<TaskResult> getTriageCount() async {
  final HttpClient skiaClient = HttpClient();
  int digestCount = 0;
  try {
    final HttpClientRequest request = await skiaClient.getUrl(Uri.parse(
      'https://flutter-gold.skia.org/json/trstatus'
    ));
    final HttpClientResponse response = await request.close();
    final String responseBody = await response.transform(utf8.decoder).join();
    final Map<String, dynamic> json = jsonDecode(responseBody);
    digestCount = json['corpStatus'][0]['untriagedCount'];
  } catch(e) {
    return TaskResult.failure(e.toString());
  }
  return TaskResult.success(
    <String, dynamic>{_kTriageCountKey: digestCount},
    benchmarkScoreKeys: <String>[_kTriageCountKey],
  );
}

Future<void> main() async {
  await task(() => getTriageCount());
}
