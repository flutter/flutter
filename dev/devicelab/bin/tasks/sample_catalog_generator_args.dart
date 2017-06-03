// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';

String extractCloudAuthTokenArg(List<String> rawArgs) {
  final ArgParser _argParser = new ArgParser()..addOption('cloud-auth-token');
  ArgResults args;
  try {
    args = _argParser.parse(rawArgs);
  } on FormatException catch(error) {
    stderr.writeln('${error.message}\n');
    stderr.writeln('Usage:\n');
    stderr.writeln(_argParser.usage);
    return null;
  }

  final String token = args['cloud-auth-token'];
  if (token == null) {
    stderr.writeln('Required option --cloud-auth-token not found');
    return null;
  }
  return token;
}
