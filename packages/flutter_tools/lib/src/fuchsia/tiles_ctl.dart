// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import '../base/process.dart';
import '../globals_null_migrated.dart' as globals;

import 'fuchsia_device.dart';

// Usage: tiles_ctl <command>
//   Supported commands:
//     start
//     add [--disable-focus] <url> [<args>...]
//     remove <key>
//     list
//     quit

/// A simple wrapper around the 'tiles_ctl' tool running on the Fuchsia device.
class FuchsiaTilesCtl {
  /// Finds the key for the app called [appName], or returns -1 if it can't be
  /// found.
  static Future<int> findAppKey(FuchsiaDevice device, String appName) async {
    final FuchsiaTilesCtl tilesCtl = fuchsiaDeviceTools.tilesCtl;
    final Map<int, String> runningApps = await tilesCtl.list(device);
    if (runningApps == null) {
      globals.printTrace('tiles_ctl is not running');
      return -1;
    }
    for (final MapEntry<int, String> entry in runningApps.entries) {
      if (entry.value.contains('$appName#meta')) {
        return entry.key;
      }
    }
    return -1;
  }

  /// Ensures that tiles is running on the device.
  static Future<bool> ensureStarted(FuchsiaDevice device) async {
    final FuchsiaTilesCtl tilesCtl = fuchsiaDeviceTools.tilesCtl;
    final Map<int, String> runningApps = await tilesCtl.list(device);
    if (runningApps == null) {
      return tilesCtl.start(device);
    }
    return true;
  }

  /// Instructs 'tiles' to start on the device.
  ///
  /// Returns true on success and false on failure.
  Future<bool> start(FuchsiaDevice device) async {
    final RunResult result = await device.shell('tiles_ctl start');
    return result.exitCode == 0;
  }

  /// Returns a mapping of tile keys to app URLs.
  ///
  /// Returns an empty mapping if tiles_ctl is running but no apps are running.
  /// Returns null if tiles_ctl is not running.
  Future<Map<int, String>> list(FuchsiaDevice device) async {
    // Output of tiles_ctl list has the format:
    // Found 1 tiles:
    // Tile key 1 url fuchsia-pkg://fuchsia.com/stocks#meta/stocks.cmx ...
    final Map<int, String> tiles = <int, String>{};
    final RunResult result = await device.shell('tiles_ctl list');
    if (result.exitCode != 0) {
      return null;
    }
    // Look for evidence that tiles_ctl is not running.
    if (result.stdout.contains("Couldn't find tiles component in realm")) {
      return null;
    }
    // Find lines beginning with 'Tile'
    for (final String line in result.stdout.split('\n')) {
      final List<String> words = line.split(' ');
      if (words.isNotEmpty && words[0] == 'Tile') {
        final int key = int.tryParse(words[2]);
        final String url = words[4];
        tiles[key] = url;
      }
    }
    return tiles;
  }

  /// Instructs tiles on the device to begin running the app at [url] in a new
  /// tile.
  ///
  /// The app is passed the arguments in [args]. Flutter apps receive these
  /// arguments as arguments to `main()`. [url] should be formatted as a
  /// Fuchsia-style package URL, e.g.:
  ///     fuchsia-pkg://fuchsia.com/flutter_gallery#meta/flutter_gallery.cmx
  /// Returns true on success and false on failure.
  Future<bool> add(FuchsiaDevice device, String url, List<String> args) async {
    final RunResult result = await device.shell(
        'tiles_ctl add $url ${args.join(" ")}');
    return result.exitCode == 0;
  }

  /// Instructs tiles on the device to remove the app with key [key].
  ///
  /// Returns true on success and false on failure.
  Future<bool> remove(FuchsiaDevice device, int key) async {
    final RunResult result = await device.shell('tiles_ctl remove $key');
    return result.exitCode == 0;
  }

  /// Instructs tiles on the device to quit.
  ///
  /// Returns true on success and false on failure.
  Future<bool> quit(FuchsiaDevice device) async {
    final RunResult result = await device.shell('tiles_ctl quit');
    return result.exitCode == 0;
  }
}
