#!/usr/bin/env dart

// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

// TODO (devoncarew): Remove this once the chromium bot is updated.
Future<Null> main(List<String> args) async {
  Process.runSync('pub', <String>['get'], workingDirectory: 'dev/tools');
  Process process = await Process.start('dart', <String>['dartdoc.dart'],
    workingDirectory: 'dev/tools');
  process.stdout
    .transform(UTF8.decoder)
    .transform(const LineSplitter())
    .listen(print);
  process.stderr
    .transform(UTF8.decoder)
    .transform(const LineSplitter())
    .listen(print);
  exit(await process.exitCode);
}
