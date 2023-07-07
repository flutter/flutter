// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../file_watcher.dart';
import '../resubscribable.dart';
import '../utils.dart';
import '../watch_event.dart';

/// Uses the native file system notifications to watch for filesystem events.
///
/// Single-file notifications are much simpler than those for multiple files, so
/// this doesn't need to be split out into multiple OS-specific classes.
class NativeFileWatcher extends ResubscribableWatcher implements FileWatcher {
  NativeFileWatcher(String path) : super(path, () => _NativeFileWatcher(path));
}

class _NativeFileWatcher implements FileWatcher, ManuallyClosedWatcher {
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

  StreamSubscription? _subscription;

  _NativeFileWatcher(this.path) {
    _listen();

    // We don't need to do any initial set-up, so we're ready immediately after
    // being listened to.
    _readyCompleter.complete();
  }

  void _listen() {
    // Batch the events together so that we can dedup them.
    _subscription = File(path)
        .watch()
        .batchEvents()
        .listen(_onBatch, onError: _eventsController.addError, onDone: _onDone);
  }

  void _onBatch(List<FileSystemEvent> batch) {
    if (batch.any((event) => event.type == FileSystemEvent.delete)) {
      // If the file is deleted, the underlying stream will close. We handle
      // emitting our own REMOVE event in [_onDone].
      return;
    }

    _eventsController.add(WatchEvent(ChangeType.MODIFY, path));
  }

  void _onDone() async {
    var fileExists = await File(path).exists();

    // Check for this after checking whether the file exists because it's
    // possible that [close] was called between [File.exists] being called and
    // it completing.
    if (_eventsController.isClosed) return;

    if (fileExists) {
      // If the file exists now, it was probably removed and quickly replaced;
      // this can happen for example when another file is moved on top of it.
      // Re-subscribe and report a modify event.
      _eventsController.add(WatchEvent(ChangeType.MODIFY, path));
      _listen();
    } else {
      _eventsController.add(WatchEvent(ChangeType.REMOVE, path));
      close();
    }
  }

  @override
  void close() {
    _subscription?.cancel();
    _subscription = null;
    _eventsController.close();
  }
}
