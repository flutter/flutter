// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../watcher.dart';
import 'custom_watcher_factory.dart';
import 'file_watcher/native.dart';

/// Watches a file and emits [WatchEvent]s when the file has changed.
///
/// Note that since each watcher only watches a single file, it will only emit
/// [ChangeType.MODIFY] events, except when the file is deleted at which point
/// it will emit a single [ChangeType.REMOVE] event and then close the stream.
///
/// If the file is deleted and quickly replaced (when a new file is moved in its
/// place, for example) this will emit a [ChangeType.MODIFY] event.
abstract class FileWatcher implements Watcher {
  /// Creates a new [FileWatcher] monitoring [file].
  ///
  /// If a native file watcher is available for this platform, this will use it.
  /// Otherwise, it will fall back to a [PollingFileWatcher]. Notably, native
  /// file watching is *not* supported on Windows.
  ///
  /// If [pollingDelay] is passed, it specifies the amount of time the watcher
  /// will pause between successive polls of the directory contents. Making this
  /// shorter will give more immediate feedback at the expense of doing more IO
  /// and higher CPU usage. Defaults to one second. Ignored for non-polling
  /// watchers.
  factory FileWatcher(String file, {Duration? pollingDelay}) {
    var customWatcher =
        createCustomFileWatcher(file, pollingDelay: pollingDelay);
    if (customWatcher != null) return customWatcher;

    // [File.watch] doesn't work on Windows, but
    // [FileSystemEntity.isWatchSupported] is still true because directory
    // watching does work.
    if (FileSystemEntity.isWatchSupported && !Platform.isWindows) {
      return NativeFileWatcher(file);
    }
    return PollingFileWatcher(file, pollingDelay: pollingDelay);
  }
}
