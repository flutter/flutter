// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../file_watcher.dart';
import '../resubscribable.dart';
import '../stat.dart';
import '../watch_event.dart';

/// Periodically polls a file for changes.
class PollingFileWatcher extends ResubscribableWatcher implements FileWatcher {
  PollingFileWatcher(String path, {Duration? pollingDelay})
      : super(path, () {
          return _PollingFileWatcher(
              path, pollingDelay ?? Duration(seconds: 1));
        });
}

class _PollingFileWatcher implements FileWatcher, ManuallyClosedWatcher {
  @override
  final String path;

  @override
  Stream<WatchEvent> get events => _eventsController.stream;
  final _eventsController = StreamController<WatchEvent>.broadcast();

  @override
  bool get isReady => _readyCompleter.isCompleted;

  @override
  Future get ready => _readyCompleter.future;
  final _readyCompleter = Completer();

  /// The timer that controls polling.
  late final Timer _timer;

  /// The previous modification time of the file.
  ///
  /// Used to tell when the file was modified. This is `null` before the file's
  /// mtime has first been checked.
  DateTime? _lastModified;

  _PollingFileWatcher(this.path, Duration pollingDelay) {
    _timer = Timer.periodic(pollingDelay, (_) => _poll());
    _poll();
  }

  /// Checks the mtime of the file and whether it's been removed.
  Future _poll() async {
    // We don't mark the file as removed if this is the first poll (indicated by
    // [_lastModified] being null). Instead, below we forward the dart:io error
    // that comes from trying to read the mtime below.
    var pathExists = await File(path).exists();
    if (_eventsController.isClosed) return;

    if (_lastModified != null && !pathExists) {
      _eventsController.add(WatchEvent(ChangeType.REMOVE, path));
      unawaited(close());
      return;
    }

    DateTime? modified;
    try {
      modified = await modificationTime(path);
    } on FileSystemException catch (error, stackTrace) {
      if (!_eventsController.isClosed) {
        _eventsController.addError(error, stackTrace);
        await close();
      }
    }
    if (_eventsController.isClosed) return;

    if (_lastModified == modified) return;

    if (_lastModified == null) {
      // If this is the first poll, don't emit an event, just set the last mtime
      // and complete the completer.
      _lastModified = modified;
      _readyCompleter.complete();
    } else {
      _lastModified = modified;
      _eventsController.add(WatchEvent(ChangeType.MODIFY, path));
    }
  }

  @override
  Future<void> close() async {
    _timer.cancel();
    await _eventsController.close();
  }
}
