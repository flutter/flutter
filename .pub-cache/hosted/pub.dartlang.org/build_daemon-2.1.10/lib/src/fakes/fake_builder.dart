// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build_daemon/daemon_builder.dart';
import 'package:build_daemon/data/build_status.dart';
import 'package:build_daemon/data/build_target.dart';
import 'package:build_daemon/data/server_log.dart';
import 'package:watcher/src/watch_event.dart';

class FakeDaemonBuilder implements DaemonBuilder {
  @override
  Stream<BuildResults> get builds => Stream.empty();

  @override
  Stream<ServerLog> get logs => Stream.empty();

  @override
  Future<void> build(
      Set<BuildTarget> targets, Iterable<WatchEvent> changes) async {}

  @override
  Future<void> stop() async {}
}
