// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../constructable_file_system_event.dart';
import '../directory_watcher.dart';
import '../path_set.dart';
import '../resubscribable.dart';
import '../utils.dart';
import '../watch_event.dart';

/// Uses the FSEvents subsystem to watch for filesystem events.
///
/// FSEvents has two main idiosyncrasies that this class works around. First, it
/// will occasionally report events that occurred before the filesystem watch
/// was initiated. Second, if multiple events happen to the same file in close
/// succession, it won't report them in the order they occurred. See issue
/// 14373.
///
/// This also works around issues 16003 and 14849 in the implementation of
/// [Directory.watch].
class MacOSDirectoryWatcher extends ResubscribableWatcher
    implements DirectoryWatcher {
  @override
  String get directory => path;

  MacOSDirectoryWatcher(String directory)
      : super(directory, () => _MacOSDirectoryWatcher(directory));
}

class _MacOSDirectoryWatcher
    implements DirectoryWatcher, ManuallyClosedWatcher {
  @override
  String get directory => path;
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

  /// The set of files that are known to exist recursively within the watched
  /// directory.
  ///
  /// The state of files on the filesystem is compared against this to determine
  /// the real change that occurred when working around issue 14373. This is
  /// also used to emit REMOVE events when subdirectories are moved out of the
  /// watched directory.
  final PathSet _files;

  /// The subscription to the stream returned by [Directory.watch].
  ///
  /// This is separate from [_listSubscriptions] because this stream
  /// occasionally needs to be resubscribed in order to work around issue 14849.
  StreamSubscription<List<FileSystemEvent>>? _watchSubscription;

  /// The subscription to the [Directory.list] call for the initial listing of
  /// the directory to determine its initial state.
  StreamSubscription<FileSystemEntity>? _initialListSubscription;

  /// The subscriptions to [Directory.list] calls for listing the contents of a
  /// subdirectory that was moved into the watched directory.
  final _listSubscriptions = <StreamSubscription<FileSystemEntity>>{};

  /// The timer for tracking how long we wait for an initial batch of bogus
  /// events (see issue 14373).
  late Timer _bogusEventTimer;

  _MacOSDirectoryWatcher(this.path) : _files = PathSet(path) {
    _startWatch();

    // Before we're ready to emit events, wait for [_listDir] to complete and
    // for enough time to elapse that if bogus events (issue 14373) would be
    // emitted, they will be.
    //
    // If we do receive a batch of events, [_onBatch] will ensure that these
    // futures don't fire and that the directory is re-listed.
    Future.wait([_listDir(), _waitForBogusEvents()]).then((_) {
      if (!isReady) {
        _readyCompleter.complete();
      }
    });
  }

  @override
  void close() {
    _watchSubscription?.cancel();
    _initialListSubscription?.cancel();
    _watchSubscription = null;
    _initialListSubscription = null;

    for (var subscription in _listSubscriptions) {
      subscription.cancel();
    }
    _listSubscriptions.clear();

    _eventsController.close();
  }

  /// The callback that's run when [Directory.watch] emits a batch of events.
  void _onBatch(List<FileSystemEvent> batch) {
    // If we get a batch of events before we're ready to begin emitting events,
    // it's probable that it's a batch of pre-watcher events (see issue 14373).
    // Ignore those events and re-list the directory.
    if (!isReady) {
      // Cancel the timer because bogus events only occur in the first batch, so
      // we can fire [ready] as soon as we're done listing the directory.
      _bogusEventTimer.cancel();
      _listDir().then((_) {
        if (!isReady) {
          _readyCompleter.complete();
        }
      });
      return;
    }

    _sortEvents(batch).forEach((path, eventSet) {
      var canonicalEvent = _canonicalEvent(eventSet);
      var events = canonicalEvent == null
          ? _eventsBasedOnFileSystem(path)
          : [canonicalEvent];

      for (var event in events) {
        if (event is FileSystemCreateEvent) {
          if (!event.isDirectory) {
            // If we already know about the file, treat it like a modification.
            // This can happen if a file is copied on top of an existing one.
            // We'll see an ADD event for the latter file when from the user's
            // perspective, the file's contents just changed.
            var type =
                _files.contains(path) ? ChangeType.MODIFY : ChangeType.ADD;

            _emitEvent(type, path);
            _files.add(path);
            continue;
          }

          if (_files.containsDir(path)) continue;

          var stream = Directory(path).list(recursive: true);
          var subscription = stream.listen((entity) {
            if (entity is Directory) return;
            if (_files.contains(path)) return;

            _emitEvent(ChangeType.ADD, entity.path);
            _files.add(entity.path);
          }, cancelOnError: true);
          subscription.onDone(() {
            _listSubscriptions.remove(subscription);
          });
          subscription.onError((Object e, StackTrace stackTrace) {
            _emitError(e, stackTrace);
          });
          _listSubscriptions.add(subscription);
        } else if (event is FileSystemModifyEvent) {
          assert(!event.isDirectory);
          _emitEvent(ChangeType.MODIFY, path);
        } else {
          assert(event is FileSystemDeleteEvent);
          for (var removedPath in _files.remove(path)) {
            _emitEvent(ChangeType.REMOVE, removedPath);
          }
        }
      }
    });
  }

  /// Sort all the events in a batch into sets based on their path.
  ///
  /// A single input event may result in multiple events in the returned map;
  /// for example, a MOVE event becomes a DELETE event for the source and a
  /// CREATE event for the destination.
  ///
  /// The returned events won't contain any [FileSystemMoveEvent]s, nor will it
  /// contain any events relating to [path].
  Map<String, Set<FileSystemEvent>> _sortEvents(List<FileSystemEvent> batch) {
    var eventsForPaths = <String, Set<FileSystemEvent>>{};

    // FSEvents can report past events, including events on the root directory
    // such as it being created. We want to ignore these. If the directory is
    // really deleted, that's handled by [_onDone].
    batch = batch.where((event) => event.path != path).toList();

    // Events within directories that already have events are superfluous; the
    // directory's full contents will be examined anyway, so we ignore such
    // events. Emitting them could cause useless or out-of-order events.
    var directories = unionAll(batch.map((event) {
      if (!event.isDirectory) return <String>{};
      if (event is FileSystemMoveEvent) {
        var destination = event.destination;
        if (destination != null) {
          return {event.path, destination};
        }
      }
      return {event.path};
    }));

    bool isInModifiedDirectory(String path) =>
        directories.any((dir) => path != dir && p.isWithin(dir, path));

    void addEvent(String path, FileSystemEvent event) {
      if (isInModifiedDirectory(path)) return;
      eventsForPaths.putIfAbsent(path, () => <FileSystemEvent>{}).add(event);
    }

    for (var event in batch) {
      // The Mac OS watcher doesn't emit move events. See issue 14806.
      assert(event is! FileSystemMoveEvent);
      addEvent(event.path, event);
    }

    return eventsForPaths;
  }

  /// Returns the canonical event from a batch of events on the same path, if
  /// one exists.
  ///
  /// If [batch] doesn't contain any contradictory events (e.g. DELETE and
  /// CREATE, or events with different values for `isDirectory`), this returns a
  /// single event that describes what happened to the path in question.
  ///
  /// If [batch] does contain contradictory events, this returns `null` to
  /// indicate that the state of the path on the filesystem should be checked to
  /// determine what occurred.
  FileSystemEvent? _canonicalEvent(Set<FileSystemEvent> batch) {
    // An empty batch indicates that we've learned earlier that the batch is
    // contradictory (e.g. because of a move).
    if (batch.isEmpty) return null;

    var type = batch.first.type;
    var isDir = batch.first.isDirectory;
    var hadModifyEvent = false;

    for (var event in batch.skip(1)) {
      // If one event reports that the file is a directory and another event
      // doesn't, that's a contradiction.
      if (isDir != event.isDirectory) return null;

      // Modify events don't contradict either CREATE or REMOVE events. We can
      // safely assume the file was modified after a CREATE or before the
      // REMOVE; otherwise there will also be a REMOVE or CREATE event
      // (respectively) that will be contradictory.
      if (event is FileSystemModifyEvent) {
        hadModifyEvent = true;
        continue;
      }
      assert(event is FileSystemCreateEvent || event is FileSystemDeleteEvent);

      // If we previously thought this was a MODIFY, we now consider it to be a
      // CREATE or REMOVE event. This is safe for the same reason as above.
      if (type == FileSystemEvent.modify) {
        type = event.type;
        continue;
      }

      // A CREATE event contradicts a REMOVE event and vice versa.
      assert(type == FileSystemEvent.create || type == FileSystemEvent.delete);
      if (type != event.type) return null;
    }

    // If we got a CREATE event for a file we already knew about, that comes
    // from FSEvents reporting an add that happened prior to the watch
    // beginning. If we also received a MODIFY event, we want to report that,
    // but not the CREATE.
    if (type == FileSystemEvent.create &&
        hadModifyEvent &&
        _files.contains(batch.first.path)) {
      type = FileSystemEvent.modify;
    }

    switch (type) {
      case FileSystemEvent.create:
        // Issue 16003 means that a CREATE event for a directory can indicate
        // that the directory was moved and then re-created.
        // [_eventsBasedOnFileSystem] will handle this correctly by producing a
        // DELETE event followed by a CREATE event if the directory exists.
        if (isDir) return null;
        return ConstructableFileSystemCreateEvent(batch.first.path, false);
      case FileSystemEvent.delete:
        return ConstructableFileSystemDeleteEvent(batch.first.path, isDir);
      case FileSystemEvent.modify:
        return ConstructableFileSystemModifyEvent(
            batch.first.path, isDir, false);
      default:
        throw 'unreachable';
    }
  }

  /// Returns one or more events that describe the change between the last known
  /// state of [path] and its current state on the filesystem.
  ///
  /// This returns a list whose order should be reflected in the events emitted
  /// to the user, unlike the batched events from [Directory.watch]. The
  /// returned list may be empty, indicating that no changes occurred to [path]
  /// (probably indicating that it was created and then immediately deleted).
  List<FileSystemEvent> _eventsBasedOnFileSystem(String path) {
    var fileExisted = _files.contains(path);
    var dirExisted = _files.containsDir(path);
    var fileExists = File(path).existsSync();
    var dirExists = Directory(path).existsSync();

    var events = <FileSystemEvent>[];
    if (fileExisted) {
      if (fileExists) {
        events.add(ConstructableFileSystemModifyEvent(path, false, false));
      } else {
        events.add(ConstructableFileSystemDeleteEvent(path, false));
      }
    } else if (dirExisted) {
      if (dirExists) {
        // If we got contradictory events for a directory that used to exist and
        // still exists, we need to rescan the whole thing in case it was
        // replaced with a different directory.
        events.add(ConstructableFileSystemDeleteEvent(path, true));
        events.add(ConstructableFileSystemCreateEvent(path, true));
      } else {
        events.add(ConstructableFileSystemDeleteEvent(path, true));
      }
    }

    if (!fileExisted && fileExists) {
      events.add(ConstructableFileSystemCreateEvent(path, false));
    } else if (!dirExisted && dirExists) {
      events.add(ConstructableFileSystemCreateEvent(path, true));
    }

    return events;
  }

  /// The callback that's run when the [Directory.watch] stream is closed.
  void _onDone() {
    _watchSubscription = null;

    // If the directory still exists and we're still expecting bogus events,
    // this is probably issue 14849 rather than a real close event. We should
    // just restart the watcher.
    if (!isReady && Directory(path).existsSync()) {
      _startWatch();
      return;
    }

    // FSEvents can fail to report the contents of the directory being removed
    // when the directory itself is removed, so we need to manually mark the
    // files as removed.
    for (var file in _files.paths) {
      _emitEvent(ChangeType.REMOVE, file);
    }
    _files.clear();
    close();
  }

  /// Start or restart the underlying [Directory.watch] stream.
  void _startWatch() {
    // Batch the FSEvent changes together so that we can dedup events.
    var innerStream = Directory(path).watch(recursive: true).batchEvents();
    _watchSubscription = innerStream.listen(_onBatch,
        onError: _eventsController.addError, onDone: _onDone);
  }

  /// Starts or restarts listing the watched directory to get an initial picture
  /// of its state.
  Future _listDir() {
    assert(!isReady);
    _initialListSubscription?.cancel();

    _files.clear();
    var completer = Completer();
    var stream = Directory(path).list(recursive: true);
    _initialListSubscription = stream.listen((entity) {
      if (entity is! Directory) _files.add(entity.path);
    }, onError: _emitError, onDone: completer.complete, cancelOnError: true);
    return completer.future;
  }

  /// Wait 200ms for a batch of bogus events (issue 14373) to come in.
  ///
  /// 200ms is short in terms of human interaction, but longer than any Mac OS
  /// watcher tests take on the bots, so it should be safe to assume that any
  /// bogus events will be signaled in that time frame.
  Future _waitForBogusEvents() {
    var completer = Completer();
    _bogusEventTimer = Timer(Duration(milliseconds: 200), completer.complete);
    return completer.future;
  }

  /// Emit an event with the given [type] and [path].
  void _emitEvent(ChangeType type, String path) {
    if (!isReady) return;
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
}
