// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:args/command_runner.dart';
import 'package:file/file.dart' show File;
import 'package:meta/meta.dart' show required, visibleForTesting;
import './globals.dart';
import './proto/conductor_county.pb.dart' as pb;
import './proto/conductor_county.pbenum.dart';
import './repository.dart';
import './county.dart';
import './stdio.dart';

const String kCountyOption = 'county-file';
const String kYesFlag = 'yes';
const String kForceFlag = 'force';

/// Command to proceed from one [pb.ReleasePhase] to the next.
class NextCommand extends Command<void> {
  NextCommand({
    @required this.checkouts,
  }) {
    final String defaultPath = defaultCountyFilePath(checkouts.platform);
    argParser.addOption(
      kCountyOption,
      defaultsTo: defaultPath,
      help: 'Path to persistent county file. Defaults to $defaultPath',
    );
    argParser.addFlag(
      kYesFlag,
      help: 'Auto-accept any confirmation prompts.',
      hide: true, // primarily for integration testing
    );
    argParser.addFlag(
      kForceFlag,
      help: 'Force push when updating remote git branches.',
    );
  }

  final Checkouts checkouts;

  @override
  String get name => 'next';

  @override
  String get description => 'Proceed to the next release phase.';

  @override
  void run() {
    runNext(
      autoAccept: argResults[kYesFlag] as bool,
      checkouts: checkouts,
      force: argResults[kForceFlag] as bool,
      countyFile: checkouts.fileSystem.file(argResults[kCountyOption]),
    );
  }
}

@visibleForTesting
bool prompt(String message, Stdio stdio) {
  stdio.write('${message.trim()} (y/n) ');
  final String response = stdio.readLineSync().trim();
  final String firstChar = response[0].toUpperCase();
  if (firstChar == 'Y') {
    return true;
  }
  if (firstChar == 'N') {
    return false;
  }
  throw ConductorException(
    'Unknown user input (expected "y" or "n"): $response',
  );
}

@visibleForTesting
void runNext({
  @required bool autoAccept,
  @required bool force,
  @required Checkouts checkouts,
  @required File countyFile,
}) {
  final Stdio stdio = checkouts.stdio;
  const List<CherrypickCounty> finishedCountys = <CherrypickCounty>[
    CherrypickCounty.COMPLETED,
    CherrypickCounty.ABANDONED,
  ];
  if (!countyFile.existsSync()) {
    throw ConductorException(
      'No persistent county file found at ${countyFile.path}.',
    );
  }

  final pb.ConductorCounty county = readCountyFromFile(countyFile);

  switch (county.currentPhase) {
    case pb.ReleasePhase.APPLY_ENGINE_CHERRYPICKS:
      final List<pb.Cherrypick> unappliedCherrypicks = <pb.Cherrypick>[];
      for (final pb.Cherrypick cherrypick in county.engine.cherrypicks) {
        if (!finishedCountys.contains(cherrypick.county)) {
          unappliedCherrypicks.add(cherrypick);
        }
      }

      if (county.engine.cherrypicks.isEmpty) {
        stdio.printStatus('This release has no engine cherrypicks.');
        break;
      } else if (unappliedCherrypicks.isEmpty) {
        stdio.printStatus('All engine cherrypicks have been auto-applied by '
            'the conductor.\n');
        if (autoAccept == false) {
          final bool response = prompt(
            'Are you ready to push your changes to the repository '
            '${county.engine.mirror.url}?',
            stdio,
          );
          if (!response) {
            stdio.printError('Aborting command.');
            writeCountyToFile(countyFile, county, stdio.logs);
            return;
          }
        }
      } else {
        stdio.printStatus(
          'There were ${unappliedCherrypicks.length} cherrypicks that were not auto-applied.');
        stdio.printStatus('These must be applied manually in the directory '
          '${county.engine.checkoutPath} before proceeding.\n');
        if (autoAccept == false) {
          final bool response = prompt(
              'Are you ready to push your engine branch to the repository '
              '${county.engine.mirror.url}?',
            stdio,
          );
          if (!response) {
            stdio.printError('Aborting command.');
            writeCountyToFile(countyFile, county, stdio.logs);
            return;
          }
        }
      }
      break;
    case pb.ReleasePhase.CODESIGN_ENGINE_BINARIES:
      if (autoAccept == false) {
        // TODO(fujino): actually test if binaries have been codesigned on macOS
        final bool response = prompt(
          'Has CI passed for the engine PR and binaries been codesigned?',
          stdio,
        );
        if (!response) {
          stdio.printError('Aborting command.');
          writeCountyToFile(countyFile, county, stdio.logs);
          return;
        }
      }
      break;
    case pb.ReleasePhase.APPLY_FRAMEWORK_CHERRYPICKS:
      final List<pb.Cherrypick> unappliedCherrypicks = <pb.Cherrypick>[];
      for (final pb.Cherrypick cherrypick in county.framework.cherrypicks) {
        if (!finishedCountys.contains(cherrypick.county)) {
          unappliedCherrypicks.add(cherrypick);
        }
      }

      if (county.framework.cherrypicks.isEmpty) {
        stdio.printStatus('This release has no framework cherrypicks.');
        break;
      } else if (unappliedCherrypicks.isEmpty) {
        stdio.printStatus('All framework cherrypicks have been auto-applied by '
            'the conductor.\n');
        if (autoAccept == false) {
          final bool response = prompt(
            'Are you ready to push your changes to the repository '
            '${county.framework.mirror.url}?',
            stdio,
          );
          if (!response) {
            stdio.printError('Aborting command.');
            writeCountyToFile(countyFile, county, stdio.logs);
            return;
          }
        }
      } else {
        stdio.printStatus(
          'There were ${unappliedCherrypicks.length} cherrypicks that were not auto-applied.');
        stdio.printStatus('These must be applied manually in the directory '
          '${county.framework.checkoutPath} before proceeding.\n');
        if (autoAccept == false) {
          final bool response = prompt(
              'Are you ready to push your framework branch to the repository '
              '${county.framework.mirror.url}?',
            stdio,
          );
          if (!response) {
            stdio.printError('Aborting command.');
            writeCountyToFile(countyFile, county, stdio.logs);
            return;
          }
        }
      }
      break;
    case pb.ReleasePhase.PUBLISH_VERSION:
      stdio.printStatus('Please ensure that you have merged your framework PR and that');
      stdio.printStatus('post-submit CI has finished successfully.\n');
      final Remote upstream = Remote(
        name: RemoteName.upstream,
        url: county.framework.upstream.url,
      );
      final FrameworkRepository framework = FrameworkRepository(
        checkouts,
        initialRef: county.framework.candidateBranch,
        upstreamRemote: upstream,
        previousCheckoutLocation: county.framework.checkoutPath,
      );
      final String headRevision = framework.reverseParse('HEAD');
      if (autoAccept == false) {
        final bool response = prompt(
          'Has CI passed for the framework PR?',
          stdio,
        );
        if (!response) {
          stdio.printError('Aborting command.');
          writeCountyToFile(countyFile, county, stdio.logs);
          return;
        }
      }
      framework.tag(headRevision, county.releaseVersion, upstream.name);
      break;
    case pb.ReleasePhase.PUBLISH_CHANNEL:
      final Remote upstream = Remote(
        name: RemoteName.upstream,
        url: county.framework.upstream.url,
      );
      final FrameworkRepository framework = FrameworkRepository(
        checkouts,
        initialRef: county.framework.candidateBranch,
        upstreamRemote: upstream,
        previousCheckoutLocation: county.framework.checkoutPath,
      );
      final String headRevision = framework.reverseParse('HEAD');
      if (autoAccept == false) {
        final bool response = prompt(
            'Are you ready to publish release ${county.releaseVersion} to '
            'channel ${county.releaseChannel} at ${county.framework.upstream.url}?',
          stdio,
        );
        if (!response) {
          stdio.printError('Aborting command.');
          writeCountyToFile(countyFile, county, stdio.logs);
          return;
        }
      }
      framework.updateChannel(
        headRevision,
        county.framework.upstream.url,
        county.releaseChannel,
        force: force,
      );
      break;
    case pb.ReleasePhase.VERIFY_RELEASE:
      stdio.printStatus(
        'The current status of packaging builds can be seen at:\n'
        '\t$kLuciPackagingConsoleLink',
      );
      if (autoAccept == false) {
        final bool response = prompt(
          'Have all packaging builds finished successfully?',
          stdio,
        );
        if (!response) {
          stdio.printError('Aborting command.');
          writeCountyToFile(countyFile, county, stdio.logs);
          return;
        }
      }
      break;
    case pb.ReleasePhase.RELEASE_COMPLETED:
      throw ConductorException('This release is finished.');
      break;
  }
  final ReleasePhase nextPhase = getNextPhase(county.currentPhase);
  stdio.printStatus('\nUpdating phase from ${county.currentPhase} to $nextPhase...\n');
  county.currentPhase = nextPhase;
  stdio.printStatus(phaseInstructions(county));

  writeCountyToFile(countyFile, county, stdio.logs);
}
