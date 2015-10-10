// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:path/path.dart' as path;

import 'main.dart';
import 'package:flutter/services.dart';

String cachedDataFilePath = null;

Future<String> dataFilePath() async {
  if (cachedDataFilePath == null) {
    String dataDir = await getFilesDir();
    cachedDataFilePath = path.join(dataDir, 'data.json');
  }
  return cachedDataFilePath;
}

Future<UserData> loadFitnessData() async {
  String dataPath = await dataFilePath();
  print("Loading from $dataPath");
  JsonDecoder decoder = new JsonDecoder();
  Map data = await decoder.convert(await new File(dataPath).readAsString());
  return new UserDataImpl.fromJson(data);
}

// Intentionally synchronous for execution just before shutdown.
Future saveFitnessData(UserDataImpl data) async {
  String dataPath = await dataFilePath();
  print("Saving to $dataPath");
  JsonEncoder encoder = new JsonEncoder();
  String contents = await encoder.convert(data);
  File dataFile = await new File(dataPath).writeAsString(contents);
  print("Success! $dataFile");
}
