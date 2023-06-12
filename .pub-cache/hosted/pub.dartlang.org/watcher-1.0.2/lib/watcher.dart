// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'src/directory_watcher.dart';
import 'src/file_watcher.dart';
import 'src/watch_event.dart';

export 'src/custom_watcher_factory.dart' show registerCustomWatcher;
export 'src/directory_watcher.dart';
export 'src/directory_watcher/polling.dart';
export 'src/file_watcher.dart';
export 'src/file_watcher/polling.dart';
export 'src/watch_event.dart';

abstract class Watcher {
  /// The path to the file or directory whose contents are being monitored.
  String get path;

  /// The broadcast [Stream] of events that have occurred to the watched file or
  /// files in the watched directory.
  ///
  /// Changes will only be monitored while this stream has subscribers. Any
  /// changes that occur during periods when there are no subscribers will not
  /// be reported the next time a subscriber is added.
  Stream<WatchEvent> get events;

  /// Whether the watcher is initialized and watching for changes.
  ///
  /// This is true if and only if [ready] is complete.
  bool get isReady;

  /// A [Future] that completes when the watcher is initialized and watching for
  /// changes.
  ///
  /// If the watcher is not currently monitoring the file or directory (because
  /// there are no subscribers to [events]), this returns a future that isn't
  /// complete yet. It will complete when a subscriber starts listening and the
  /// watcher finishes any initialization work it needs to do.
  ///
  /// If the watcher is already monitoring, this returns an already complete
  /// future.
  ///
  /// This future always completes successfully as errors are provided through
  /// the [events] stream.
  Future get ready;

  /// Creates a new [DirectoryWatcher] or [FileWatcher] monitoring [path],
  /// depending on whether it's a file or directory.
  ///
  /// If a native watcher is available for this platform, this will use it.
  /// Otherwise, it will fall back to a polling watcher. Notably, watching
  /// individual files is not natively supported on Windows, although watching
  /// directories is.
  ///
  /// If [pollingDelay] is passed, it specifies the amount of time the watcher
  /// will pause between successive polls of the contents of [path]. Making this
  /// shorter will give more immediate feedback at the expense of doing more IO
  /// and higher CPU usage. Defaults to one second. Ignored for non-polling
  /// watchers.
  factory Watcher(String path, {Duration? pollingDelay}) {
    if (File(path).existsSync()) {
      return FileWatcher(path, pollingDelay: pollingDelay);
    } else {
      return DirectoryWatcher(path, pollingDelay: pollingDelay);
    }
  }
}
