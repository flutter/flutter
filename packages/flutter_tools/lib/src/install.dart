// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.install;

import 'dart:async';

import 'package:args/args.dart';

import 'common.dart';
import 'device.dart';

class InstallCommandHandler extends CommandHandler {
  InstallCommandHandler()
      : super('install', 'Install your Sky app on attached devices.');

  @override
  ArgParser get parser {
    ArgParser parser = new ArgParser();
    parser.addFlag('help',
        abbr: 'h', negatable: false, help: 'Display this help message.');
    return parser;
  }

  @override
  Future<int> processArgResults(ArgResults results) async {
    if (results['help']) {
      printUsage();
      return 0;
    }

    bool installedSomewhere = false;

    AndroidDevice android = new AndroidDevice();
    if (android.isConnected()) {
      installedSomewhere = installedSomewhere || android.installApp('');
    }

    if (installedSomewhere) {
      return 0;
    } else {
      return 2;
    }
  }
}
