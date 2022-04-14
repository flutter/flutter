// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/migrate/migrate_utils.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

  group('Auto signing', () {
    late Config testConfig;
    late AnsiTerminal testTerminal;
    late BufferLogger logger;

    setUp(() async {
      logger = BufferLogger.test();
      testConfig = Config.test();
      testTerminal = TestTerminal();
      // testTerminal.usesTerminalUi = true;
    });

    testWithoutContext('git init', () async {
      MigrateUtils.gitInit();
    });
  });
}

