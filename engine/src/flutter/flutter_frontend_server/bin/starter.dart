// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library frontend_server;

import 'dart:io';

import 'package:flutter_frontend_server/server.dart';

Future<void> main(List<String> args) async {
  final int exitCode = await starter(args);
  if (exitCode != 0) {
    exit(exitCode);
  }
}
