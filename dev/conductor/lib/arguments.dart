// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';

import './globals.dart';

ArgResults parseArguments(ArgParser argParser, List<String> args) {
  argParser.addOption(
    kIncrement,
    help: 'Specifies which part of the x.y.z version number to increment. Required.',
    valueHelp: 'level',
    allowed: <String>[kX, kY, kZ],
    allowedHelp: <String, String>{
      kX: 'Indicates a major development, e.g. typically changed after a big press event.',
      kY: 'Indicates a minor development, e.g. typically changed after a beta release.',
      kZ: 'Indicates the least notable level of change. You normally want this.',
    },
  );
  argParser.addOption(
    kCommit,
    help: 'Specifies which git commit to roll to the dev branch. Required.',
    valueHelp: 'hash',
    defaultsTo: null, // This option is required
  );
  argParser.addOption(
    kOrigin,
    help: 'Specifies the name of the upstream repository',
    valueHelp: 'repository',
    defaultsTo: 'upstream',
  );
  argParser.addFlag(
    kForce,
    abbr: 'f',
    help: 'Force push. Necessary when the previous release had cherry-picks.',
    negatable: false,
  );
  argParser.addFlag(
    kJustPrint,
    negatable: false,
    help:
        "Don't actually roll the dev channel; "
        'just print the would-be version and quit.',
  );
  argParser.addFlag(
    kSkipTagging,
    negatable: false,
    help: 'Do not create tag and push to remote, only update release branch. '
    'For recovering when the script fails trying to git push to the release branch.'
  );
  argParser.addFlag(kYes, negatable: false, abbr: 'y', help: 'Skip the confirmation prompt.');
  argParser.addFlag(kHelp, negatable: false, help: 'Show this help message.', hide: true);

  return argParser.parse(args);
}
