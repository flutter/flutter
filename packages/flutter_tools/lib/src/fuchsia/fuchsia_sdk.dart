// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import '../base/common.dart';
import '../base/context.dart';
import '../base/io.dart';
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
  Stream<Uint8List> netaddr() async * {
    try {
      final Process process = await runDetached(<String>['fx', 'netaddr', '--fuchsia']);
      yield* process.stdout;
    } on ArgumentError catch (exception) {
      throwToolExit('$exception');
    }
  }

  /// Invokes the `netls` command.
  ///
  /// This lists attached fuchsia devices with their name and address. Does
  /// not currently support multiple attached devices.
  ///
  /// Example output:
  ///     $ fx netls
  ///     > device liliac-shore-only-last (fe80::82e4:da4d:fe81:227d/3)
  Stream<Uint8List> netls() async * {
    try {
      final Process process = await runDetached(<String>['fx', 'netls']);
      yield* process.stdout;
    } on ArgumentError catch (exception) {
      throwToolExit('$exception');
    }
  }
}
