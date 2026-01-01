// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "common_patch.dart";

@patch
class _File {
  @patch
  @pragma("vm:external-name", "File_Exists")
  external static _exists(_Namespace namespace, Uint8List rawPath);
  @patch
  @pragma("vm:external-name", "File_Create")
  external static _create(
    _Namespace namespace,
    Uint8List rawPath,
    bool exclusive,
  );
  @patch
  @pragma("vm:external-name", "File_CreateLink")
  external static _createLink(
    _Namespace namespace,
    Uint8List rawPath,
    String target,
  );
  @patch
  @pragma("vm:external-name", "File_CreatePipe")
  external static List<dynamic> _createPipe(_Namespace namespace);
  @patch
  @pragma("vm:external-name", "File_LinkTarget")
  external static _linkTarget(_Namespace namespace, Uint8List rawPath);
  @patch
  @pragma("vm:external-name", "File_Delete")
  external static _deleteNative(_Namespace namespace, Uint8List rawPath);
  @patch
  @pragma("vm:external-name", "File_DeleteLink")
  external static _deleteLinkNative(_Namespace namespace, Uint8List rawPath);
  @patch
  @pragma("vm:external-name", "File_Rename")
  external static _rename(
    _Namespace namespace,
    Uint8List oldPath,
    String newPath,
  );
  @patch
  @pragma("vm:external-name", "File_RenameLink")
  external static _renameLink(
    _Namespace namespace,
    Uint8List oldPath,
    String newPath,
  );
  @patch
  @pragma("vm:external-name", "File_Copy")
  external static _copy(
    _Namespace namespace,
    Uint8List oldPath,
    String newPath,
  );
  @patch
  @pragma("vm:external-name", "File_LengthFromPath")
  external static _lengthFromPath(_Namespace namespace, Uint8List rawPath);
  @patch
  @pragma("vm:external-name", "File_LastModified")
  external static _lastModified(_Namespace namespace, Uint8List rawPath);
  @patch
  @pragma("vm:external-name", "File_SetLastModified")
  external static _setLastModified(
    _Namespace namespace,
    Uint8List rawPath,
    int millis,
  );
  @patch
  @pragma("vm:external-name", "File_LastAccessed")
  external static _lastAccessed(_Namespace namespace, Uint8List rawPath);
  @patch
  @pragma("vm:external-name", "File_SetLastAccessed")
  external static _setLastAccessed(
    _Namespace namespace,
    Uint8List rawPath,
    int millis,
  );
  @patch
  @pragma("vm:external-name", "File_Open")
  external static _open(_Namespace namespace, Uint8List rawPath, int mode);
  @patch
  @pragma("vm:external-name", "File_OpenStdio")
  external static int _openStdio(int fd);
}

@patch
class _RandomAccessFileOps {
  @patch
  factory _RandomAccessFileOps._(int pointer) =>
      _RandomAccessFileOpsImpl._().._setPointer(pointer);
}

@pragma("vm:entry-point")
base class _RandomAccessFileOpsImpl extends NativeFieldWrapperClass1
    implements _RandomAccessFileOps {
  _RandomAccessFileOpsImpl._();

  @pragma("vm:external-name", "File_SetPointer")
  external void _setPointer(int pointer);
  @pragma("vm:external-name", "File_GetPointer")
  external int _getPointer();
  @pragma("vm:external-name", "File_GetFD")
  external int get fd;
  @pragma("vm:external-name", "File_Close")
  external int close();
  @pragma("vm:external-name", "File_ReadByte")
  external readByte();
  @pragma("vm:external-name", "File_Read")
  external read(int bytes);
  @pragma("vm:external-name", "File_ReadInto")
  external readInto(List<int> buffer, int start, int? end);
  @pragma("vm:external-name", "File_WriteByte")
  external writeByte(int value);
  @pragma("vm:external-name", "File_WriteFrom")
  external writeFrom(List<int> buffer, int start, int? end);
  @pragma("vm:external-name", "File_Position")
  external position();
  @pragma("vm:external-name", "File_SetPosition")
  external setPosition(int position);
  @pragma("vm:external-name", "File_Truncate")
  external truncate(int length);
  @pragma("vm:external-name", "File_Length")
  external length();
  @pragma("vm:external-name", "File_Flush")
  external flush();
  @pragma("vm:external-name", "File_Lock")
  external lock(int lock, int start, int end);
}

class _WatchedPath implements ffi.Finalizable {
  /// Path ID returned by [_FileSystemWatcher._watchPath].
  ///
  /// Will remain valid until either [_unwatchPath] is called.
  final int pathId;

  final String path;
  final int events;

  /// Listeners subscribed to [FileSystemEvent] occuring at [path].
  ///
  /// Once the last listener is unsubscribed the underlying watcher will
  /// stop monitoring changes at [path].
  final List<MultiStreamController<FileSystemEvent>> listeners =
      <MultiStreamController<FileSystemEvent>>[];

  bool isClosed = false;

  /// Source of [_NativeFSEvent] for this path.
  ///
  /// This subscription will be cancelled once the last listener is gone.
  ///
  /// Might be `null` if events for this path are delivered over multiplexed
  /// stream (see [_InotifyFileSystemWatcher]).
  StreamSubscription<List<_NativeFSEvent>>? source;

  /// Finalizer associated with [_WatchedPath] instances.
  ///
  /// [_FileSystemWatcher._watchPathImpl] returns `pathId` values which behave
  /// slightly differently on different OSes.
  ///
  /// * On Mac OS X `pathId` values which are actually pointers to `Node`
  ///   objects. These objects need to be released by calling
  ///   [_FileSystemWatcher._unwatchPath] - otherwise they will leak.
  ///   Attaching a [NativeFinalizer] ensures that even if Isolate exits
  ///   abruptly via [Isolate.exit] we will still free these objects.
  /// * On Linux `pathId` is a _watch descriptor_ (returned by
  ///   `inotify_add_watch`) associated with a specific inotify instance.
  ///   Inotify instances are created by [_FileSystemWatcher._initWatcher] (see
  ///   `inotify_init`) which returns a file descriptor. This file descriptor is
  ///   wrapped in a [_NativeSocket] by
  ///   [_FileSystemWatcher._eventsStreamFromSocket]. Socket takes ownership of
  ///   the file descriptor and has a finalizer attached to itself. This
  ///   finalizer will close the descriptor when socket is garbage collected.
  ///   Thus there is no need to associate a separate finalizer with
  ///   [_WatchedPath].
  /// * Windows is a mixture of Linux and Mac OS X: `pathId` itself is a
  ///   pointer to a socket-like `DirectoryWatchHandle`. It is wrapped in a
  ///   socket by [_FileSystemWatcher._eventsStreamFromSocket] by we do not
  ///   allow the socket to take full ownership of the `pathId` handle, because
  ///   we want to guarantee that invariant that `pathId` remains valid
  ///   until we explicitly call `_FileSystemWatcher._unwatchPath`. To ensure
  ///   this we explicitly retain `DirectoryWatchHandle` before returning it
  ///   from [_FileSystemWatcher._initWatcher]. This will keep the handle
  ///   alive even after event handler is done with it. This however means that
  ///   [_FileSystemWatcher._unwatchPath] must be called to release the handle.
  ///   Thus we need to attach a finalizer to [_WatchedPath] to guarantee that.
  static final ffi.NativeFinalizer? finalizer =
      Platform.isMacOS || Platform.isWindows
      ? ffi.NativeFinalizer(
          ffi.Native.addressOf(_FileSystemWatcher._destroyWatch),
        )
      : null;

  _WatchedPath(this.pathId, this.path, this.events) {
    finalizer?.attach(this, .fromAddress(pathId), detach: this);
  }

  FutureOr<void> dispose() {
    assert(listeners.isEmpty);
    isClosed = true;
    finalizer?.detach(this);
    return source?.cancel();
  }

  void add(FileSystemEvent event) {
    if (isClosed) {
      return;
    }

    if ((event.type & events) == 0) {
      return;
    }

    for (var listener in listeners) {
      listener.add(event);
    }
  }

  void close({Object? error}) {
    if (isClosed) {
      return;
    }

    isClosed = true;
    for (var listener in listeners) {
      if (error != null) {
        listener.addError(error);
      }
      listener.close();
    }
  }

  /// Emit the given [_NativeFSEvent] to listeners.
  ///
  /// A single [_NativeFSEvent] is expanded into a sequence of appropriate
  /// [FileSystemEvent].
  ///
  /// Note: this might modify [unmatchedMoves] - the caller is responsible for
  /// calling [flushUnmatchedMoves] once it emitted all events from a chunk
  /// of events.
  void addEvent(_NativeFSEvent event) {
    if (isClosed) {
      return;
    }

    final flags = event.flags;
    final fullPath = fullPathOf(event);
    final isDir = _NativeFSEvent.isDirectory(event, fullPath);

    if ((flags & FileSystemEvent.create) != 0) {
      add(FileSystemCreateEvent(fullPath, isDir));
    }

    if ((flags & FileSystemEvent.modify) != 0) {
      add(FileSystemModifyEvent(fullPath, isDir, true));
    }

    if ((flags & FileSystemEvent._modifyAttributes) != 0) {
      add(FileSystemModifyEvent(fullPath, isDir, false));
    }

    if ((flags & FileSystemEvent.move) != 0) {
      // Use cookie to merge pairs of move from and move to events.
      final int cookie = event.cookie;
      if (cookie > 0) {
        if (unmatchedMoves.remove(cookie) case final linkedEvent?) {
          add(FileSystemMoveEvent(fullPathOf(linkedEvent), isDir, fullPath));
        } else {
          unmatchedMoves[cookie] = event;
        }
      } else {
        addMove(event, fullPath, isDir);
      }
    }

    if ((flags & FileSystemEvent.delete) != 0) {
      add(FileSystemDeleteEvent(fullPath, false));
    }

    if ((flags & FileSystemEvent._deleteSelf) != 0) {
      add(FileSystemDeleteEvent(fullPath, false));
      // Emit all unmatched moves before emitting the stop event to avoid
      // loosing these events.
      flushUnmatchedMoves();
      close();
    }
  }

  /// Flush unmatched move events accumulated in [unmatchedMoves].
  void flushUnmatchedMoves() {
    for (var move in unmatchedMoves.values) {
      final fullPathOfMove = fullPathOf(move);
      addMove(
        move,
        fullPathOfMove,
        _NativeFSEvent.isDirectory(move, fullPathOf(move)),
      );
    }
    unmatchedMoves.clear();
  }

  /// Most recently encountered move events by their [_NativeFSEvent.cookie].
  ///
  /// When converting a chunk of _NativeFSEvent to corresponding FileSystemEvents
  /// we try to match and merge pairs of events which correspond to a single
  /// move operation (e.g. FILE_ACTION_RENAMED_{OLD|NEW}_NAME on Windows and
  /// IN_MOVED_{FROM|TO} on Linux). We use this as a temporary storage for
  /// matching. The caller feeding native events must call [flushUnmatchedMoves]
  /// at the end of the chunk to flush all unmatched moves.
  final Map<int, _NativeFSEvent> unmatchedMoves = {};

  String fullPathOf(_NativeFSEvent event) {
    assert(event.pathId == pathId);
    if (event.relativePath case final eventPath? when eventPath.isNotEmpty) {
      return '${path}${Platform.pathSeparator}${eventPath}';
    } else {
      return path;
    }
  }

  void addMove(_NativeFSEvent event, String fullPath, bool isDir) {
    if ((event.flags & FileSystemEvent._movedTo) != 0) {
      add(FileSystemCreateEvent(fullPath, isDir));
    } else {
      add(FileSystemDeleteEvent(fullPath, false));
    }
  }
}

@patch
abstract class _FileSystemWatcher {
  @patch
  static Stream<FileSystemEvent> _watch(
    String path,
    int events,
    bool recursive,
  ) {
    return _watcher._watchImpl(path, events, recursive);
  }

  Stream<FileSystemEvent> _watchImpl(String path, int events, bool recursive) {
    _WatchedPath? watchedPath;
    final stream = Stream<FileSystemEvent>.multi((controller) {
      _WatchedPath wp;
      try {
        wp = watchedPath ??= _watcher._startWatching(path, events, recursive);
      } on FileSystemException catch (e, st) {
        controller.addError(e, st);
        controller.close();
        return;
      }

      if (wp.isClosed) {
        controller.addError(
          FileSystemException('Directory watcher is already closed', path),
        );
        controller.close();
        return;
      }

      wp.listeners.add(controller);
      controller.onCancel = () {
        wp.listeners.remove(controller);
        if (wp.listeners.isEmpty) {
          watchedPath = null;
          return _stopWatching(wp);
        }
      };
    });

    return stream;
  }

  Stream<List<_NativeFSEvent>> _eventsStreamFromSocket(
    int socketId,
    int pathId,
  ) {
    final nativeSocket = _NativeSocket._watch(socketId);
    return _RawSocket(nativeSocket).map((event) {
      if (event == RawSocketEvent.read) {
        final result = <_NativeFSEvent>[];

        int totalEvents;
        do {
          totalEvents = result.length;
          for (_NativeFSEvent? e in _readEvents(_watcherId, pathId)) {
            if (e == null) {
              break;
            }
            result.add(e);
          }
        } while (result.length > totalEvents);

        // Be sure to clear this manually, as the sockets are not read through
        // the _NativeSocket interface.
        nativeSocket.available = 0;

        return result;
      }
      return [];
    });
  }

  /// Native ID associated with the watcher.
  ///
  /// Passed as a parameter to [_watchPathImpl] and other native functions.
  int get _watcherId => 0;

  /// Start watching the given path for the specified events.
  ///
  /// Returns [_WatchedPath] instances representing the watch.
  _WatchedPath _startWatching(String path, int events, bool recursive);

  /// Stop watching the given path.
  ///
  /// If this causes the watcher to free some native resources (e.g. because
  /// this was the last active filesystem watch) this function will return
  /// an instance of [Future] which will complete after native cleanup is
  /// complete.
  FutureOr<void> _stopWatching(_WatchedPath wp) {
    _unwatchPath(_watcherId, wp.pathId);
    return wp.dispose();
  }

  /// Wrapper over [_watchPathImpl] which takes care of converting
  /// [OSError] into [FileSystemException].
  int _watchPath(String path, int events, bool recursive) {
    try {
      return _watchPathImpl(
        _watcherId,
        _Namespace._namespace,
        path,
        events,
        recursive,
      );
    } on OSError catch (e) {
      throw FileSystemException._fromOSError(e, "Failed to watch path", path);
    }
  }

  /// Singleton [_FileSystemWatcher] which takes care of watching file system.
  static _FileSystemWatcher _watcher = () {
    if (isSupported) {
      if (Platform.isLinux || Platform.isAndroid) {
        return _InotifyFileSystemWatcher();
      }

      if (Platform.isWindows) {
        return _Win32FileSystemWatcher();
      }

      if (Platform.isMacOS) {
        return _FSEventStreamFileSystemWatcher();
      }
    }

    throw FileSystemException(
      "File system watching is not supported on this platform",
    );
  }();

  @patch
  @pragma("vm:external-name", "FileSystemWatcher_IsSupported")
  external static bool get isSupported;

  @pragma("vm:external-name", "FileSystemWatcher_InitWatcher")
  external static int _initWatcher();

  @pragma("vm:external-name", "FileSystemWatcher_WatchPath")
  external static int _watchPathImpl(
    int watcherId,
    _Namespace namespace,
    String path,
    int events,
    bool recursive,
  );
  @pragma("vm:external-name", "FileSystemWatcher_UnwatchPath")
  external static void _unwatchPath(int watcherId, int pathId);

  /// Returns a list each element of which is [_NativeFSEvents] or `null`.
  ///
  /// After the first `null` only `null` entries will follow, in other words
  /// all non-`null` entries form the prefix of the list.
  @pragma("vm:external-name", "FileSystemWatcher_ReadEvents")
  external static List _readEvents(int watcherId, int pathId);

  @pragma("vm:external-name", "FileSystemWatcher_GetSocketId")
  external static int _getSocketId(int watcherId, int pathId);

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.Void>)>(
    symbol: "FileSystemWatcher::DestroyWatch",
  )
  external static void _destroyWatch(ffi.Pointer<ffi.Void> pathId);
}

/// A watcher that receives events for multiple `pathId` on a single channel.
abstract class _MultiplexingFileSystemWatcher extends _FileSystemWatcher {
  /// Map of [_watchedPath] indexed by `pathId` values.
  final Map<int, _WatchedPath> _watchedPaths = <int, _WatchedPath>{};

  /// Perform necessary initialization of the native state for the watcher.
  void _ensureWatcherIsRunning();

  /// Shutdown the watcher when there is no actively watched paths.
  ///
  /// If shutdown requires asynchronous actions returns [Future] which will
  /// complete when shutdown is finished.
  FutureOr<void> _stopWatcher();

  @override
  _WatchedPath _startWatching(String path, int events, bool recursive) {
    _ensureWatcherIsRunning();
    final pathId = super._watchPath(path, events, recursive);
    // On Linux inotify_add_watch will return an existing watch descriptor
    // for the inode if there is already one associated with it. Thus we
    // need accept the possibility that calling _watchPath twice will
    // return the same pathId. Other OSes do not reuse pathId values.
    assert(Platform.isLinux || !_watchedPaths.containsKey(pathId));
    return _watchedPaths[pathId] ??= _WatchedPath(pathId, path, events);
  }

  @override
  Future<void> _stopWatching(_WatchedPath wp) async {
    assert(_watchedPaths[wp.pathId] == wp);
    _watchedPaths.remove(wp.pathId);
    await super._stopWatching(wp);

    // If there are no more active watcher close inotify descriptor.
    if (_watchedPaths.isEmpty) {
      await _stopWatcher();
    }
  }
}

class _InotifyFileSystemWatcher extends _MultiplexingFileSystemWatcher {
  int? _inotifyFd;
  StreamSubscription<List<_NativeFSEvent>>? _inotifySubscription;

  @override
  int get _watcherId => _inotifyFd!;

  @override
  void _ensureWatcherIsRunning() {
    if (_inotifyFd != null) {
      return;
    }

    final inotifyFd = _inotifyFd = _FileSystemWatcher._initWatcher();
    _inotifySubscription = _eventsStreamFromSocket(
      inotifyFd,
      0,
    ).listen(_handleEvents);
  }

  void _handleEvents(List<_NativeFSEvent> events) {
    Set<_WatchedPath>? dirty;

    // Distribute events to corresponding _WatchedPath objects based on
    // pathId.
    for (_NativeFSEvent event in events) {
      if (_watchedPaths[event.pathId] case final watchedPath?) {
        watchedPath.addEvent(event);
        if (watchedPath.unmatchedMoves.isNotEmpty) {
          (dirty ??= {}).add(watchedPath);
        }
      }
    }

    if (dirty != null) {
      for (var watchedPath in dirty) {
        watchedPath.flushUnmatchedMoves();
      }
    }
  }

  @override
  FutureOr<void> _stopWatcher() {
    final subscription = _inotifySubscription;
    _inotifyFd = null;
    _inotifySubscription = null;
    return subscription?.cancel();
  }
}

class _FSEventStreamFileSystemWatcher extends _MultiplexingFileSystemWatcher {
  final _port = RawReceivePort()..keepIsolateAlive = false;

  @override
  late final _watcherId = ffi.NativePort(_port.sendPort).nativePort;

  @override
  void _ensureWatcherIsRunning() {
    _port.keepIsolateAlive = true;
    _port.handler = _handleEvents;
  }

  @override
  FutureOr<void> _stopWatcher() {
    _port.keepIsolateAlive = false;
    _port.handler = null;
  }

  void _handleEvents(List events) {
    // All events in a bundle have the same pathId, and we never get an empty
    // bundle.
    final pathId = (events[0] as _NativeFSEvent).pathId;
    if (_watchedPaths[pathId] case final watchedPath?) {
      for (_NativeFSEvent event in events) {
        watchedPath.addEvent(event);
      }
      watchedPath.flushUnmatchedMoves();
    }
  }
}

class _Win32FileSystemWatcher extends _FileSystemWatcher {
  @override
  _WatchedPath _startWatching(String path, int events, bool recursive) {
    final watchedPath = _WatchedPath(
      _watchPath(path, events, recursive),
      path,
      events,
    );
    watchedPath.source =
        _eventsStreamFromSocket(
          _FileSystemWatcher._getSocketId(0, watchedPath.pathId),
          watchedPath.pathId,
        ).listen(
          (events) {
            for (var e in events) {
              watchedPath.addEvent(e);
            }
            watchedPath.flushUnmatchedMoves();
          },
          onError: (error) {
            if (watchedPath.listeners.isNotEmpty) {
              watchedPath.close(
                error: FileSystemException(
                  'Directory watcher failed due to: $error',
                  watchedPath.path,
                ),
              );
            }
          },
          onDone: () {
            if (watchedPath.listeners.isNotEmpty) {
              watchedPath.close(
                error: FileSystemException(
                  'Directory watcher closed unexpectedly',
                  watchedPath.path,
                ),
              );
            }
          },
          cancelOnError: true,
        );
    return watchedPath;
  }
}

extension type _NativeFSEvent(List<dynamic> _) {
  // See FileSystemWatcher::kEvent*Index constants.
  static const int flagsIndex = 0;
  static const int cookieIndex = 1;
  static const int pathIndex = 2;
  static const int pathIdIndex = 3;

  int get flags => this._[flagsIndex];

  /// A unique identifier (32-bit unsigned integer) for matching related events.
  ///
  /// On Linux (inotify) associates unique cookie values with pairs of
  /// `IN_MOVED_FROM` and `IN_MOVED_TO` events.
  ///
  /// On Windows we set cookie to `1` on pairs of `FILE_ACTION_RENAMED_OLD_NAME`
  /// and `FILE_ACTION_RENAMED_NEW_NAME`.
  ///
  /// Not used on Mac OS X (because `FSEventStream` does not generate move
  /// events).
  int get cookie => this._[cookieIndex];

  String? get relativePath => this._[pathIndex];

  int get pathId => this._[pathIdIndex];

  static bool isDirectory(_NativeFSEvent event, String fullPath) {
    if (Platform.isWindows) {
      // Windows does not get FileSystemEvent._isDir bit as part of the event
      // so we need to compute it by checking the file-system. We ignore links
      // when computing isDirectory.
      return FileSystemEntity._isDirectoryIgnoringLinksSync(fullPath);
    } else {
      return (event.flags & FileSystemEvent._isDir) != 0;
    }
  }
}

@pragma("vm:entry-point", "call")
Uint8List _makeUint8ListView(Uint8List source, int offsetInBytes, int length) {
  return Uint8List.view(source.buffer, offsetInBytes, length);
}
