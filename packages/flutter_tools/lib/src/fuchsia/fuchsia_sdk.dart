// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/context.dart';
import '../base/process.dart';

/// The [FuchsiaSdk] instance.
FuchsiaSdk get fuchsiaSdk => context[FuchsiaSdk];

/// The Fuchsia SDK shell commands.
///
/// This workflow assumes development within the fuchsia source tree,
/// including a working fx command-line tool in the user's PATH.
class FuchsiaSdk {

  /// Invokes the `netaddr` command.
  ///
  /// This returns the network address of an attached fuchsia device. Does
  /// not currently support multiple attached devices.
  ///
  /// Example output:
  ///     $ fx netaddr --fuchsia
  ///     > fe80::9aaa:fcff:fe60:d3af%eth1
  Future<String> netaddr() async {
    try {
      final RunResult process = await runAsync(<String>['fx', 'netaddr', '--fuchsia', '--nowait']);
      return process.stdout;
    } on ArgumentError catch (exception) {
      throwToolExit('$exception');
    }
    return null;
  }

  /// Invokes the `netls` command.
  ///
  /// This lists attached fuchsia devices with their name and address. Does
  /// not currently support multiple attached devices.
  ///
  /// Example output:
  ///     $ fx netls
  ///     > device liliac-shore-only-last (fe80::82e4:da4d:fe81:227d/3)
  Future<String> netls() async {
    try {
      final RunResult process = await runAsync(
        <String>['fx', 'netls', '--nowait']);
      return process.stdout;
    } on ArgumentError catch (exception) {
      throwToolExit('$exception');
    }
    return null;
  }
}
