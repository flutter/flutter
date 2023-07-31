// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';

import '../directory_watcher.dart';
import '../path_set.dart';
import '../resubscribable.dart';
import '../utils.dart';
import '../watch_event.dart';

/// Uses the inotify subsystem to watch for filesystem events.
///
/// Inotify doesn't suport recursively watching subdirectories, nor does
/// [Directory.watch] polyfill that functionality. This class polyfills it
/// instead.
///
/// This class also compensates for the non-inotify-specific issues of
/// [Directory.watch] producing multiple events for a single logical action
/// (issue 14372) and providing insufficient information about move events
/// (issue 14424).
class LinuxDirectoryWatcher extends ResubscribableWatcher
    implements DirectoryWatcher {
  @override
  String get directory => path;

  LinuxDirectoryWatcher(String directory)
      : super(directory, () => _LinuxDirectoryWatcher(directory));
}

class _LinuxDirectoryWatcher
    implements DirectoryWatcher, ManuallyClosedWatcher {
  @override
  String get directory => _files.root;
  @override
  String get path => _files.root;

  @override
  Stream<WatchEvent> get events => _eventsController.stream;
  final _eventsController = StreamController<WatchEvent>.broadcast();

  @override
  bool get isReady => _readyCompleter.isCompleted;

  @override
  Future get ready => _readyCompleter.future;
  final _readyCompleter = Completer();

  /// A stream group for the [Directory.watch] events of [path] and all its
  /// subdirectories.
  final _nativeEvents = StreamGroup<FileSystemEvent>();

  /// All known files recursively within [path].
  final PathSet _files;

  /// [Directory.watch] streams for [path]'s subdirectories, indexed by name.
  ///
  /// A stream is in this map if and only if it's also in [_nativeEvents].
  final _subdirStreams = <String, Stream<FileSystemEvent>>{};

  /// A set of all subscriptions that this watcher subscribes to.
  ///
  /// These are gathered together so that they may all be canceled when the
  /// watcher is closed.
  final _subscriptions = <StreamSubscription>{};

  _LinuxDirectoryWatcher(String path) : _files = PathSet(path) {
    _nativeEvents.add(Directory(path)
        .watch()
        .transform(StreamTransformer.fromHandlers(handleDone: (sink) {
      // Handle the done event here rather than in the call to [_listen] because
      // [innerStream] won't close until we close the [StreamGroup]. However, if
      // we close the [StreamGroup] here, we run the risk of new-directory
      // events being fired after the group is closed, since batching delays
      // those events. See b/30768513.
      _onDone();
    })));

    // Batch the inotify changes together so that we can dedup events.
    var innerStream = _nativeEvents.stream.batchEvents();
    _listen(innerStream, _onBatch,
        onError: (Object error, StackTrace stackTrace) {
      // Guarantee that ready always completes.
      if (!isReady) {
        _readyCompleter.complete();
      }
      _eventsController.addError(error, stackTrace);
    });

    _listen(
      Directory(path).list(recursive: true),
      (FileSystemEntity entity) {
        if (entity is Directory) {
          _watchSubdir(entity.path);
        } else {
          _files.add(entity.path);
        }
      },
      onError: _emitError,
      onDone: () {
        if (!isReady) {
          _readyCompleter.complete();
        }
      },
      cancelOnError: true,
    );
  }

  @override
  void close() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }

    _subscriptions.clear();
    _subdirStreams.clear();
    _files.clear();
    _nativeEvents.close();
    _eventsController.close();
  }

  /// Watch a subdirectory of [directory] for changes.
  void _watchSubdir(String path) {
    // TODO(nweiz): Right now it's possible for the watcher to emit an event for
    // a file before the directory list is complete. This could lead to the user
    // seeing a MODIFY or REMOVE event for a file before they see an ADD event,
    // which is bad. We should handle that.
    //
    // One possibility is to provide a general means (e.g.
    // `DirectoryWatcher.eventsAndExistingFiles`) to tell a watcher to emit
    // events for all the files that already exist. This would be useful for
    // top-level clients such as barback as well, and could be implemented with
    // a wrapper similar to how listening/canceling works now.

    // TODO(nweiz): Catch any errors here that indicate that the directory in
    // question doesn't exist and silently stop watching it instead of
    // propagating the errors.
    var stream = Directory(path).watch();
    _subdirStreams[path] = stream;
    _nativeEvents.add(stream);
  }

  /// The callback that's run when a batch of changes comes in.
  void _onBatch(List<FileSystemEvent> batch) {
    var files = <String>{};
    var dirs = <String>{};
    var changed = <String>{};

    // inotify event batches are ordered by occurrence, so we treat them as a
    // log of what happened to a file. We only emit events based on the
    // difference between the state before the batch and the state after it, not
    // the intermediate state.
    for (var event in batch) {
      // If the watched directory is deleted or moved, we'll get a deletion
      // event for it. Ignore it; we handle closing [this] when the underlying
      // stream is closed.
      if (event.path == path) continue;

      changed.add(event.path);

      if (event is FileSystemMoveEvent) {
        files.remove(event.path);
        dirs.remove(event.path);

        var destination = event.destination;
        if (destination == null) continue;

        changed.add(destination);
        if (event.isDirectory) {
          files.remove(destination);
          dirs.add(destination);
        } else {
          files.add(destination);
          dirs.remove(destination);
        }
      } else if (event is FileSystemDeleteEvent) {
        files.remove(event.path);
        dirs.remove(event.path);
      } else if (event.isDirectory) {
        files.remove(event.path);
        dirs.add(event.path);
      } else {
        files.add(event.path);
        dirs.remove(event.path);
      }
    }

    _applyChanges(files, dirs, changed);
  }

  /// Applies the net changes computed for a batch.
  ///
  /// The [files] and [dirs] sets contain the files and directories that now
  /// exist, respectively. The [changed] set contains all files and directories
  /// that have changed (including being removed), and so is a superset of
  /// [files] and [dirs].
  void _applyChanges(Set<String> files, Set<String> dirs, Set<String> changed) {
    for (var path in changed) {
      var stream = _subdirStreams.remove(path);
      if (stream != null) _nativeEvents.add(stream);

      // Unless [path] was a file and still is, emit REMOVE events for it or its
      // contents,
      if (files.contains(path) && _files.contains(path)) continue;
      for (var file in _files.remove(path)) {
        _emitEvent(ChangeType.REMOVE, file);
      }
    }

    for (var file in files) {
      if (_files.contains(file)) {
        _emitEvent(ChangeType.MODIFY, file);
      } else {
        _emitEvent(ChangeType.ADD, file);
        _files.add(file);
      }
    }

    for (var dir in dirs) {
      _watchSubdir(dir);
      _addSubdir(dir);
    }
  }

  /// Emits [ChangeType.ADD] events for the recursive contents of [path].
  void _addSubdir(String path) {
    _listen(Directory(path).list(recursive: true), (FileSystemEntity entity) {
      if (entity is Directory) {
        _watchSubdir(entity.path);
      } else {
        _files.add(entity.path);
        _emitEvent(ChangeType.ADD, entity.path);
      }
    }, onError: (Object error, StackTrace stackTrace) {
      // Ignore an exception caused by the dir not existing. It's fine if it
      // was added and then quickly removed.
      if (error is FileSystemException) return;

      _emitError(error, stackTrace);
    }, cancelOnError: true);
  }

  /// Handles the underlying event stream closing, indicating that the directory
  /// being watched was removed.
  void _onDone() {
    // Most of the time when a directory is removed, its contents will get
    // individual REMOVE events before the watch stream is closed -- in that
    // case, [_files] will be empty here. However, if the directory's removal is
    // caused by a MOVE, we need to manually emit events.
    if (isReady) {
      for (var file in _files.paths) {
        _emitEvent(ChangeType.REMOVE, file);
      }
    }

    close();
  }

  /// Emits a [WatchEvent] with [type] and [path] if this watcher is in a state
  /// to emit events.
  void _emitEvent(ChangeType type, String path) {
    if (!isReady) return;
    if (_eventsController.isClosed) return;
    _eventsController.add(WatchEvent(type, path));
  }

  /// Emit an error, then close the watcher.
  void _emitError(Object error, StackTrace stackTrace) {
    // Guarantee that ready always completes.
    if (!isReady) {
      _readyCompleter.complete();
    }
    _eventsController.addError(error, stackTrace);
    close();
  }

  /// Like [Stream.listen], but automatically adds the subscription to
  /// [_subscriptions] so that it can be canceled when [close] is called.
  void _listen<T>(Stream<T> stream, void Function(T) onData,
      {Function? onError,
      void Function()? onDone,
      bool cancelOnError = false}) {
    late StreamSubscription subscription;
    subscription = stream.listen(onData, onError: onError, onDone: () {
      _subscriptions.remove(subscription);
      onDone?.call();
    }, cancelOnError: cancelOnError);
    _subscriptions.add(subscription);
  }
}
