// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:multicast_dns/multicast_dns.dart';

import '../base/logger.dart';
import '../base/time.dart';
import '../base/utils.dart';
import '../convert.dart';
import '../mdns_device_discovery.dart';
import '../runner/flutter_command.dart';
import '../runner/flutter_command_runner.dart';
import 'run.dart';

const String _noRunningAppsFoundMessage =
    'No running Flutter apps found.\n'
    'Note: Flutter running-apps only detects apps running with the '
    '"--${RunCommand.kEnableLocalDiscovery}" flag (debug/profile mode only).';

/// Command to list running Flutter applications.
class RunningAppsCommand extends FlutterCommand {
  RunningAppsCommand({
    this.hidden = false,
    @visibleForTesting MDnsClient? mdnsClient,
    required SystemClock systemClock,
    required Logger logger,
  }) : _mdnsClient = mdnsClient ?? MDnsClient(),
       _systemClock = systemClock,
       _logger = logger {
    argParser.addFlag(
      FlutterGlobalOptions.kMachineFlag,
      negatable: false,
      help: 'Print output in JSON format.',
    );
  }

  final MDnsClient _mdnsClient;
  final SystemClock _systemClock;
  final Logger _logger;

  @override
  final name = 'running-apps';

  @override
  final bool hidden;

  @override
  final description = 'List running applications.';

  @override
  final String category = FlutterCommandCategory.tools;

  @override
  Future<FlutterCommandResult> runCommand() async {
    _logger.printStatus('Searching for running Flutter apps...');

    final apps = <MDNSObservation>[];
    final seenUris = <String>{};
    try {
      await _mdnsClient.start();

      final pendingLookups = <Future<void>>[];
      // Listen for pointer records (PTR) to find services
      await for (final PtrResourceRecord ptr
          in _mdnsClient
              .lookup<PtrResourceRecord>(
                ResourceRecordQuery.serverPointer(MDNSDeviceDiscovery.kFlutterDevicesService),
              )
              .timeout(
                const Duration(seconds: 5),
                onTimeout: (EventSink<PtrResourceRecord> sink) => sink.close(),
              )) {
        pendingLookups.add(_resolveAppMetadata(ptr, seenUris, apps));
      }
      await pendingLookups.wait;
    } finally {
      _mdnsClient.stop();
    }

    if (boolArg(FlutterGlobalOptions.kMachineFlag)) {
      _logger.printStatus(json.encode(apps));
      return FlutterCommandResult.success();
    }

    if (apps.isEmpty) {
      _logger.printStatus(_noRunningAppsFoundMessage);
      return FlutterCommandResult.success();
    }

    // Sort by epoch descending (newest/shortest duration first).
    apps.sort((MDNSObservation a, MDNSObservation b) {
      final int epochA = a.epoch;
      final int epochB = b.epoch;
      return epochB.compareTo(epochA);
    });

    _logger.printStatus('Found ${apps.length} running Flutter ${pluralize('app', apps.length)}:');
    final table = <List<String>>[];
    for (final app in apps) {
      final String projectName = app.projectName;
      final String mode = app.mode;
      final String deviceName = app.deviceName;
      final String deviceId = app.deviceId;
      final String platform = app.targetPlatform;
      final String vmServiceUri = app.wsUri;
      final String age = _systemClock
          .now()
          .difference(DateTime.fromMillisecondsSinceEpoch(app.epoch))
          .ago();

      // If the device name and ID are effectively the same (e.g., "macos" and "macos"),
      // only show the name to avoid redundancy like "macos (macos)".
      final deviceString = (deviceName.toLowerCase() == deviceId.toLowerCase())
          ? deviceName
          : '$deviceName ($deviceId)';
      table.add(<String>['$projectName ($mode)', deviceString, platform, vmServiceUri, age]);
    }

    // Join columns into lines of text
    _logger.printStatus(formatTable(table, indent: 2).join('\n'));
    return FlutterCommandResult.success();
  }

  /// Resolves the app's metadata (e.g., project name, device, observatory URI)
  /// from the TXT records.
  ///
  /// The [apps] list is populated with the metadata found.
  /// The [seenUris] set is used to avoid duplicate entries for the same app.
  Future<void> _resolveAppMetadata(
    PtrResourceRecord ptr,
    Set<String> seenUris,
    List<MDNSObservation> apps,
  ) async {
    try {
      // For each PTR, look up the TXT records
      await for (final TxtResourceRecord txt in _mdnsClient.lookup<TxtResourceRecord>(
        ResourceRecordQuery.text(ptr.domainName),
      )) {
        final MDNSObservation? observation = MDNSObservation.parse(txt.text);
        if (observation != null) {
          final String uri = observation.wsUri;
          if (!seenUris.add(uri)) {
            continue;
          }
          apps.add(observation);
        }
      }
    } on Exception {
      // Ignore errors for individual lookups
    }
  }
}
