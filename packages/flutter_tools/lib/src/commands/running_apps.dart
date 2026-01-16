// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:multicast_dns/multicast_dns.dart';

import '../base/logger.dart';
import '../base/time.dart';
import '../base/utils.dart';
import '../convert.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';

const _noRunningAppsFoundMessage = 'No running Flutter apps found.';

/// Command to list running Flutter applications.
class RunningAppsCommand extends FlutterCommand {
  RunningAppsCommand({
    this.hidden = false,
    @visibleForTesting MDnsClient? mdnsClient,
    @visibleForTesting SystemClock? systemClock,
    required Logger logger,
  }) : _mdnsClient = mdnsClient,
       _systemClock = systemClock ?? globals.systemClock,
       _logger = logger {
    argParser.addFlag('machine', negatable: false, help: 'Print output in JSON format.');
  }

  final MDnsClient? _mdnsClient;
  final SystemClock _systemClock;
  final Logger _logger;

  static const String _kProjectName = 'project_name';
  static const String _kDeviceName = 'device_name';
  static const String _kDeviceId = 'device_id';
  static const String _kTargetPlatform = 'target_platform';
  static const String _kMode = 'mode';
  static const String _kWsUri = 'ws_uri';
  static const String _kEpoch = 'epoch';

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
    // Use mDNS to discover running Flutter apps, the multicast_dns package is
    // used instead of mdns_dart as the discovery functionality is insufficient
    // in the mdns_dart package, only discovering a maximum of one service.

    _logger.printStatus('Searching for running Flutter apps...');
    final MDnsClient client = _mdnsClient ?? MDnsClient();

    final apps = <Map<String, String>>[];
    final seenUris = <String>{};
    try {
      await client.start();

      final pendingLookups = <Future<void>>[];
      // Listen for pointer records (PTR) to find services
      await for (final PtrResourceRecord ptr
          in client
              .lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer('_flutter_devices._tcp'))
              .timeout(
                const Duration(seconds: 5),
                onTimeout: (EventSink<PtrResourceRecord> sink) => sink.close(),
              )) {
        pendingLookups.add(
          (() async {
            try {
              // For each PTR, look up the TXT records
              await for (final TxtResourceRecord txt in client.lookup<TxtResourceRecord>(
                ResourceRecordQuery.text(ptr.domainName),
              )) {
                final metadata = <String, String>{};
                // The multicast_dns package joins the strings of a TXT record with newlines.
                final List<String> parts = txt.text.split('\n');
                for (final part in parts) {
                  final int equalsIndex = part.indexOf('=');
                  if (equalsIndex != -1) {
                    metadata[part.substring(0, equalsIndex)] = part.substring(equalsIndex + 1);
                  }
                }
                if (metadata.isNotEmpty) {
                  final String? uri = metadata[_kWsUri];
                  if (uri != null) {
                    if (seenUris.contains(uri)) {
                      continue;
                    }
                    seenUris.add(uri);
                  }
                  apps.add(metadata);
                }
              }
            } on Exception {
              // Ignore errors for individual lookups
            }
          })(),
        );
      }
      await Future.wait(pendingLookups);
    } finally {
      client.stop();
    }

    if (boolArg('machine')) {
      _logger.printStatus(json.encode(apps));
    } else {
      if (apps.isEmpty) {
        _logger.printStatus(_noRunningAppsFoundMessage);
        return FlutterCommandResult.success();
      }

      // Sort by epoch descending (newest/shortest duration first).
      apps.sort((Map<String, String> a, Map<String, String> b) {
        final int? epochA = int.tryParse(a[_kEpoch] ?? '');
        final int? epochB = int.tryParse(b[_kEpoch] ?? '');
        if (epochA == null && epochB == null) {
          return 0;
        }
        if (epochA == null) {
          return 1; // Put unknown age last
        }
        if (epochB == null) {
          return -1; // Put unknown age last
        }
        return epochB.compareTo(epochA);
      });

      _logger.printStatus('Found ${apps.length} running Flutter ${pluralize('app', apps.length)}:');
      final table = <List<String>>[];
      for (final app in apps) {
        final String projectName = app[_kProjectName] ?? 'Unknown';
        final String mode = app[_kMode] ?? 'Unknown';
        final String deviceName = app[_kDeviceName] ?? 'Unknown';
        final String deviceId = app[_kDeviceId] ?? 'Unknown';
        final String platform = app[_kTargetPlatform] ?? 'Unknown';
        final String vmServiceUri = app[_kWsUri] ?? 'Unknown';
        final String age = getProcessAge(app[_kEpoch], _systemClock);

        // If the device name and ID are effectively the same (e.g. "macos" and "macos"),
        // only show the name to avoid redundancy like "macos (macos)".
        final deviceString = (deviceName.toLowerCase() == deviceId.toLowerCase())
            ? deviceName
            : '$deviceName ($deviceId)';
        table.add(<String>['$projectName ($mode)', deviceString, platform, vmServiceUri, age]);
      }

      // TODO(jwren): consider combining this logic with the logic in `flutter devices`,
      // see https://github.com/flutter/flutter/issues/180949
      // Calculate column widths
      final indices = List<int>.generate(table[0].length - 1, (int i) => i);
      List<int> widths = indices.map<int>((int i) => 0).toList();
      for (final row in table) {
        widths = indices.map<int>((int i) => math.max(widths[i], row[i].length)).toList();
      }

      // Join columns into lines of text
      for (final row in table) {
        final String rowString = indices
            .map<String>((int i) => row[i].padRight(widths[i]))
            .followedBy(<String>[row.last])
            .join(' • ');
        _logger.printStatus('  $rowString');
      }
    }
    return FlutterCommandResult.success();
  }
}

/// Formats the elapsed time since the given epoch.
@visibleForTesting
String getProcessAge(String? epochString, SystemClock systemClock) {
  // TODO(jwren): Consider using [DurationAgo] from `lib/src/base/utils.dart`.
  // We need to decide on the width and precision, possibly modifying the utility
  // to support a shorter form (e.g. "5m" versus "5 minutes ago").
  if (epochString == null) {
    return 'unknown age';
  }
  final int? epoch = int.tryParse(epochString);
  if (epoch == null) {
    return 'unknown age';
  }
  final Duration elapsed = systemClock.now().difference(DateTime.fromMillisecondsSinceEpoch(epoch));
  if (elapsed.inDays > 0) {
    return '${elapsed.inDays}d';
  } else if (elapsed.inHours > 0) {
    return '${elapsed.inHours}h';
  } else if (elapsed.inMinutes > 0) {
    return '${elapsed.inMinutes}m';
  } else {
    return '${elapsed.inSeconds}s';
  }
}
