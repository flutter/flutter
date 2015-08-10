// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:path/path.dart' as path;

import 'main.dart';
import 'package:sky/mojo/activity.dart';

String cachedDataFilePath = null;

Future<String> dataFilePath() async {
  if (cachedDataFilePath == null) {
    String dataDir = await getFilesDir();
    cachedDataFilePath = path.join(dataDir, 'data.json');
  }
  return cachedDataFilePath;
}

Future<List<Measurement>> loadFitnessData() async {
  List<Measurement> items = [];
  String dataPath = await dataFilePath();
  print("Loading from $dataPath");
  JsonDecoder decoder = new JsonDecoder();
  var data = await decoder.convert(await new File(dataPath).readAsString());
  data.forEach((item) {
    items.add(new Measurement.fromJson(item));
  });
  return items;
}

// Intentionally synchronous for execution just before shutdown.
Future saveFitnessData(List<Measurement> data) async {
  String dataPath = await dataFilePath();
  print("Saving to $dataPath");
  JsonEncoder encoder = new JsonEncoder();
  String contents = await encoder.convert(data);
  File dataFile = await new File(dataPath).writeAsString(contents);
  print("Success! $dataFile");
}
