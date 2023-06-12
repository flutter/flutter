// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../watcher.dart';

/// A factory to produce custom watchers for specific file paths.
class _CustomWatcherFactory {
  final String id;
  final DirectoryWatcher? Function(String path, {Duration? pollingDelay})
      createDirectoryWatcher;
  final FileWatcher? Function(String path, {Duration? pollingDelay})
      createFileWatcher;

  _CustomWatcherFactory(
      this.id, this.createDirectoryWatcher, this.createFileWatcher);
}

/// Registers a custom watcher.
///
/// Each custom watcher must have a unique [id] and the same watcher may not be
/// registered more than once.
/// [createDirectoryWatcher] and [createFileWatcher] should return watchers for
/// the file paths they are able to handle. If the custom watcher is not able to
/// handle the path it should return null.
/// The paths handled by each custom watch may not overlap, at most one custom
/// matcher may return a non-null watcher for a given path.
///
/// When a file or directory watcher is created the path is checked against each
/// registered custom watcher, and if exactly one custom watcher is available it
/// will be used instead of the default.
void registerCustomWatcher(
  String id,
  DirectoryWatcher? Function(String path, {Duration? pollingDelay})?
      createDirectoryWatcher,
  FileWatcher? Function(String path, {Duration? pollingDelay})?
      createFileWatcher,
) {
  if (_customWatcherFactories.containsKey(id)) {
    throw ArgumentError('A custom watcher with id `$id` '
        'has already been registered');
  }
  _customWatcherFactories[id] = _CustomWatcherFactory(
      id,
      createDirectoryWatcher ?? (_, {pollingDelay}) => null,
      createFileWatcher ?? (_, {pollingDelay}) => null);
}

/// Tries to create a custom [DirectoryWatcher] and returns it.
///
/// Returns `null` if no custom watcher was applicable and throws a [StateError]
/// if more than one was.
DirectoryWatcher? createCustomDirectoryWatcher(String path,
    {Duration? pollingDelay}) {
  DirectoryWatcher? customWatcher;
  String? customFactoryId;
  for (var watcherFactory in _customWatcherFactories.values) {
    if (customWatcher != null) {
      throw StateError('Two `CustomWatcherFactory`s applicable: '
          '`$customFactoryId` and `${watcherFactory.id}` for `$path`');
    }
    customWatcher =
        watcherFactory.createDirectoryWatcher(path, pollingDelay: pollingDelay);
    customFactoryId = watcherFactory.id;
  }
  return customWatcher;
}

/// Tries to create a custom [FileWatcher] and returns it.
///
/// Returns `null` if no custom watcher was applicable and throws a [StateError]
/// if more than one was.
FileWatcher? createCustomFileWatcher(String path, {Duration? pollingDelay}) {
  FileWatcher? customWatcher;
  String? customFactoryId;
  for (var watcherFactory in _customWatcherFactories.values) {
    if (customWatcher != null) {
      throw StateError('Two `CustomWatcherFactory`s applicable: '
          '`$customFactoryId` and `${watcherFactory.id}` for `$path`');
    }
    customWatcher =
        watcherFactory.createFileWatcher(path, pollingDelay: pollingDelay);
    customFactoryId = watcherFactory.id;
  }
  return customWatcher;
}

final _customWatcherFactories = <String, _CustomWatcherFactory>{};
