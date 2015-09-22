// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.cache;

import 'dart:async';

import 'package:args/args.dart';
import 'package:logging/logging.dart';

import 'artifacts.dart';
import 'common.dart';

final Logger _logging = new Logger('sky_tools.cache');

class CacheCommandHandler extends CommandHandler {
  CacheCommandHandler() : super('cache', 'Manages sky_tools\' cache of binary artifacts.');

  ArgParser get parser {
    ArgParser parser = new ArgParser();
    parser.addFlag('help', abbr: 'h', negatable: false);
    parser.addOption('package-root', defaultsTo: 'packages');
    ArgParser clearParser = parser.addCommand('clear');
    clearParser.addFlag('help', abbr: 'h', negatable: false);
    ArgParser populateParser = parser.addCommand('populate');
    populateParser.addFlag('help', abbr: 'h', negatable: false);
    return parser;
  }

  Future<int> _clear(String packageRoot, ArgResults results) async {
    if (results['help']) {
      print('Clears all artifacts from the cache.');
      print(parser.usage);
      return 0;
    }
    ArtifactStore artifacts = new ArtifactStore(packageRoot);
    await artifacts.clear();
    return 0;
  }

  Future<int> _populate(String packageRoot, ArgResults results) async {
    if (results['help']) {
      print('Populates the cache with all known artifacts.');
      print(parser.usage);
      return 0;
    }
    ArtifactStore artifacts = new ArtifactStore(packageRoot);
    await artifacts.populate();
    return 0;
  }

  @override
  Future<int> processArgResults(ArgResults results) async {
    if (results['help'] || results.command == null) {
      print(parser.usage);
      return 0;
    }
    if (results.command.name == 'clear') {
      return _clear(results['package-root'], results.command);
    } else if (results.command.name == 'populate') {
      return _populate(results['package-root'], results.command);
    } else {
      _logging.severe('Unknown cache command \"${results.command.name}\"');
      return 2;
    }
  }
}
