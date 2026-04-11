// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Tags(<String>['flutter-test-driver'])
library;

import 'dart:io';

import '../integration.shard/test_data/hot_reload_test_common.dart';
import '../src/common.dart';

Future<List<String>> _getIps() async {
  final List<String> ips = [];
  final List<NetworkInterface> interfaces = await NetworkInterface.list();

  if (interfaces.isNotEmpty) {
    for (final interface in interfaces) {
      for (final InternetAddress address in interface.addresses) {
        ips.add(address.address);
      }
    }
  }

  return ips;
}

void main() async {
  final List<String> ips = await _getIps();

  testAll(
    chrome: true,
    additionalCommandArgs: <String>[
      '--web-experimental-hot-reload',
      '--no-web-resources-cdn',
      '--web-hostname=${ips.single}',
      '--web-port=8080',
    ],
  );
}
