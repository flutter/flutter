// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:watcher/src/watch_event.dart';

abstract class ChangeProvider {
  /// Returns a list of file changes.
  ///
  /// Called immediately before a manual build. If the list is empty a no-op
  /// build of all tracked targets will be attempted.
  Future<List<WatchEvent>> collectChanges();

  /// A stream of file changes.
  ///
  /// A build is triggered upon each stream event.
  ///
  /// If multiple files change together then they should be sent in the same
  /// event. Otherwise, at least two builds will be triggered.
  Stream<List<WatchEvent>> get changes;
}
