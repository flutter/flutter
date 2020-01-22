// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:googleapis/bigquery/v2.dart' as bq;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'flutter_compact_formatter.dart';
import 'run_command.dart';
import 'utils.dart';

/// Used to cehck for any tryjob results from Flutter Gold
Future<void> main() async {
  // Allow time for the results to have finished processing on Gold's end
  print('$clock WAITING TO START STATUS CHECK');
  try {
    flutterTestArgs.addAll(args);
    if (Platform.environment.containsKey(CIRRUS_TASK_NAME))
      print('Running task: ${Platform.environment[CIRRUS_TASK_NAME]}');
    print('═' * 80);
    await _runSmokeTests();
    print('═' * 80);
    await selectShard(const <String, ShardRunner>{
      'add_to_app_tests': _runAddToAppTests,
      'build_tests': _runBuildTests,
      'framework_coverage': _runFrameworkCoverage,
      'framework_tests': _runFrameworkTests,
      'hostonly_devicelab_tests': _runHostOnlyDeviceLabTests,
      'tool_coverage': _runToolCoverage,
      'tool_tests': _runToolTests,
      'web_tests': _runWebTests,
    });
  } on ExitException catch (error) {
    error.apply();
  }
  print('$clock ${bold}Test successful.$reset');
}