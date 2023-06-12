// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build_daemon/change_provider.dart';
import 'package:watcher/src/watch_event.dart';

class FakeChangeProvider implements ChangeProvider {
  @override
  Stream<List<WatchEvent>> get changes => Stream.empty();

  @override
  Future<List<WatchEvent>> collectChanges() async => [];
}
