// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:multicast_dns/multicast_dns.dart';
import '../base/time.dart';
import '../base/utils.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';

const _noRunningAppsFoundMessage = 'No running Flutter apps found.';

/// Command to list running Flutter applications.
class RunningAppsCommand extends FlutterCommand {
  RunningAppsCommand({this.hidden = false, @visibleForTesting MDnsClient? mdnsClient})
    : _mdnsClient = mdnsClient {
    argParser.addFlag('machine', negatable: false, help: 'Print output in JSON format.');
  }

  final MDnsClient? _mdnsClient;

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

    globals.printStatus('Searching for running Flutter apps...');
    final MDnsClient client = _mdnsClient ?? MDnsClient();

    final List<Map<String, String>> apps = [];
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
                // multicast_dns might return multiple TXT records or one with multiple strings.
                // In many implementations, TXT records are a set of strings.
                // The 'text' property might join them or we might need to access raw data.
                // Assuming 'text' contains the joined strings, we split by common separators if needed,
                // but usually it's one key-value pair per string in the TXT record.
                // For now, let's try to parse it as key=value pairs, assuming they might be separated by commas or newlines if joined.

                // If txt.text is used, we need to know how it's joined.
                // Let's try to split by common delimiters just in case, or handle it as a single pair.
                // Given the serving side uses a list of strings, they might come as separate TXT records or joined.

                final List<String> parts = txt.text.split('\n'); // Try newline first
                for (final part in parts) {
                  final int equalsIndex = part.indexOf('=');
                  if (equalsIndex != -1) {
                    metadata[part.substring(0, equalsIndex)] = part.substring(equalsIndex + 1);
                  }
                }
                if (metadata.isNotEmpty) {
                  final String? uri = metadata['ws_uri'];
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
      globals.printStatus(json.encode(apps));
    } else {
      if (apps.isEmpty) {
        globals.printStatus(_noRunningAppsFoundMessage);
        return FlutterCommandResult.success();
      }

      // Sort by epoch descending (newest/shortest duration first).
      apps.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
        final int? epochA = int.tryParse(a['epoch'] as String? ?? '');
        final int? epochB = int.tryParse(b['epoch'] as String? ?? '');
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

      globals.printStatus('Found ${apps.length} running Flutter ${pluralize('app', apps.length)}:');
      final table = <List<String>>[];
      for (final Map<String, dynamic> app in apps) {
        final String projectName = app['project_name'] as String? ?? 'Unknown';
        final String mode = app['mode'] as String? ?? 'Unknown';
        final String deviceName = app['device_name'] as String? ?? 'Unknown';
        final String deviceId = app['device_id'] as String? ?? 'Unknown';
        final String platform = app['target_platform'] as String? ?? 'Unknown';
        final String vmServiceUri = app['ws_uri'] as String? ?? 'Unknown';
        final String age = getProcessAge(app['epoch'] as String?, globals.systemClock);

        // If the device name and ID are effectively the same (e.g. "macos" and "macos"),
        // only show the name to avoid redundancy like "macos (macos)".
        final deviceString = (deviceName.toLowerCase() == deviceId.toLowerCase())
            ? deviceName
            : '$deviceName ($deviceId)';
        table.add(<String>[
          '$projectName ($mode)',
          deviceString,
          platform,
          vmServiceUri,
          age,
        ]);
      }

      // Calculate column widths
      final indices = List<int>.generate(table[0].length - 1, (int i) => i);
      List<int> widths = indices.map<int>((int i) => 0).toList();
      for (final row in table) {
        widths = indices.map<int>((int i) => math.max(widths[i], row[i].length)).toList();
      }

      // Join columns into lines of text
      for (final row in table) {
        globals.printStatus(
          '  ${indices.map<String>((int i) => row[i].padRight(widths[i])).followedBy(<String>[row.last]).join(' • ')}',
        );
      }
    }
    return FlutterCommandResult.success();
  }
}

/// Formats the elapsed time since the given epoch.
@visibleForTesting
String getProcessAge(String? epochString, SystemClock systemClock) {
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
