// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../watcher.dart';
import 'custom_watcher_factory.dart';
import 'directory_watcher/linux.dart';
import 'directory_watcher/mac_os.dart';
import 'directory_watcher/windows.dart';

/// Watches the contents of a directory and emits [WatchEvent]s when something
/// in the directory has changed.
abstract class DirectoryWatcher implements Watcher {
  /// The directory whose contents are being monitored.
  @Deprecated('Expires in 1.0.0. Use DirectoryWatcher.path instead.')
  String get directory;

  /// Creates a new [DirectoryWatcher] monitoring [directory].
  ///
  /// If a native directory watcher is available for this platform, this will
  /// use it. Otherwise, it will fall back to a [PollingDirectoryWatcher].
  ///
  /// If [pollingDelay] is passed, it specifies the amount of time the watcher
  /// will pause between successive polls of the directory contents. Making this
  /// shorter will give more immediate feedback at the expense of doing more IO
  /// and higher CPU usage. Defaults to one second. Ignored for non-polling
  /// watchers.
  factory DirectoryWatcher(String directory, {Duration? pollingDelay}) {
    if (FileSystemEntity.isWatchSupported) {
      var customWatcher =
          createCustomDirectoryWatcher(directory, pollingDelay: pollingDelay);
      if (customWatcher != null) return customWatcher;
      if (Platform.isLinux) return LinuxDirectoryWatcher(directory);
      if (Platform.isMacOS) return MacOSDirectoryWatcher(directory);
      if (Platform.isWindows) return WindowsDirectoryWatcher(directory);
    }
    return PollingDirectoryWatcher(directory, pollingDelay: pollingDelay);
  }
}
