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
      _Namespace namespace, Uint8List rawPath, bool exclusive);
  @patch
  @pragma("vm:external-name", "File_CreateLink")
  external static _createLink(
      _Namespace namespace, Uint8List rawPath, String target);
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
      _Namespace namespace, Uint8List oldPath, String newPath);
  @patch
  @pragma("vm:external-name", "File_RenameLink")
  external static _renameLink(
      _Namespace namespace, Uint8List oldPath, String newPath);
  @patch
  @pragma("vm:external-name", "File_Copy")
  external static _copy(
      _Namespace namespace, Uint8List oldPath, String newPath);
  @patch
  @pragma("vm:external-name", "File_LengthFromPath")
  external static _lengthFromPath(_Namespace namespace, Uint8List rawPath);
  @patch
  @pragma("vm:external-name", "File_LastModified")
  external static _lastModified(_Namespace namespace, Uint8List rawPath);
  @patch
  @pragma("vm:external-name", "File_SetLastModified")
  external static _setLastModified(
      _Namespace namespace, Uint8List rawPath, int millis);
  @patch
  @pragma("vm:external-name", "File_LastAccessed")
  external static _lastAccessed(_Namespace namespace, Uint8List rawPath);
  @patch
  @pragma("vm:external-name", "File_SetLastAccessed")
  external static _setLastAccessed(
      _Namespace namespace, Uint8List rawPath, int millis);
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
  factory _RandomAccessFileOps(int pointer) =>
      new _RandomAccessFileOpsImpl(pointer);
}

@pragma("vm:entry-point")
base class _RandomAccessFileOpsImpl extends NativeFieldWrapperClass1
    implements _RandomAccessFileOps {
  _RandomAccessFileOpsImpl._();

  factory _RandomAccessFileOpsImpl(int pointer) =>
      new _RandomAccessFileOpsImpl._().._setPointer(pointer);

  @pragma("vm:external-name", "File_SetPointer")
  external void _setPointer(int pointer);
  @pragma("vm:external-name", "File_GetPointer")
  external int getPointer();
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

class _WatcherPath {
  final int pathId;
  final String path;
  final int events;
  int count = 0;
  _WatcherPath(this.pathId, this.path, this.events);
}

@patch
abstract class _FileSystemWatcher {
  void _pathWatchedEnd();

  static int? _id;
  static final Map<int, _WatcherPath> _idMap = {};

  final String _path;
  final int _events;
  final bool _recursive;

  _WatcherPath? _watcherPath;

  final StreamController<FileSystemEvent> _broadcastController =
      new StreamController<FileSystemEvent>.broadcast();

  /// Subscription on the stream returned by [_watchPath].
  ///
  /// Stored while piping events from that stream into [_broadcastController],
  /// so it can be cancelled when [_broadcastController] is cancelled.
  StreamSubscription? _sourceSubscription;

  @patch
  static Stream<FileSystemEvent> _watch(
      String path, int events, bool recursive) {
    if (Platform.isLinux || Platform.isAndroid) {
      return new _InotifyFileSystemWatcher(path, events, recursive)._stream;
    }
    if (Platform.isWindows) {
      return new _Win32FileSystemWatcher(path, events, recursive)._stream;
    }
    if (Platform.isMacOS) {
      return new _FSEventStreamFileSystemWatcher(path, events, recursive)
          ._stream;
    }
    throw new FileSystemException(
        "File system watching is not supported on this platform");
  }

  _FileSystemWatcher._(this._path, this._events, this._recursive) {
    if (!isSupported) {
      throw new FileSystemException(
          "File system watching is not supported on this platform", _path);
    }
    _broadcastController
      ..onListen = _listen
      ..onCancel = _cancel;
  }

  Stream<FileSystemEvent> get _stream => _broadcastController.stream;

  void _listen() {
    if (_id == null) {
      try {
        _id = _initWatcher();
        _newWatcher();
      } on dynamic catch (e) {
        _broadcastController.addError(FileSystemException._fromOSError(
            e, "Failed to initialize file system entity watcher", _path));
        _broadcastController.close();
        return;
      }
    }
    var pathId;
    try {
      pathId =
          _watchPath(_id!, _Namespace._namespace, _path, _events, _recursive);
    } on dynamic catch (e) {
      _broadcastController.addError(
          FileSystemException._fromOSError(e, "Failed to watch path", _path));
      _broadcastController.close();
      return;
    }
    if (!_idMap.containsKey(pathId)) {
      _idMap[pathId] = new _WatcherPath(pathId, _path, _events);
    }
    _watcherPath = _idMap[pathId];
    _watcherPath!.count++;
    _sourceSubscription = _pathWatched().listen(_broadcastController.add,
        onError: _broadcastController.addError,
        onDone: _broadcastController.close);
  }

  void _cancel() {
    final watcherPath = _watcherPath;
    if (watcherPath != null) {
      assert(watcherPath.count > 0);
      watcherPath.count--;
      if (watcherPath.count == 0) {
        var pathId = watcherPath.pathId;
        // DirectoryWatchHandle(aka pathId) might be closed already initiated
        // by issueReadEvent for example. When that happens, appropriate closeEvent
        // will arrive to us and we will remove this pathId from _idMap. If that
        // happens we should not try to close it again as pathId is no
        // longer usable(the memory it points to might be released)
        if (_idMap.containsKey(pathId)) {
          _unwatchPath(_id!, pathId);
          _pathWatchedEnd();
          _idMap.remove(pathId);
        }
      }
      _watcherPath = null;
    }
    final id = _id;
    if (_idMap.isEmpty && id != null) {
      _closeWatcher(id);
      _doneWatcher();
      _id = null;
    }
    _sourceSubscription?.cancel();
    _sourceSubscription = null;
  }

  // Called when (and after) a new watcher instance is created and available.
  void _newWatcher() {}
  // Called when a watcher is no longer needed.
  void _doneWatcher() {}
  // Called when a new path is being watched.
  Stream<FileSystemEvent> _pathWatched();
  // Called when a path is no longer being watched.
  void _donePathWatched() {}

  static _WatcherPath _pathFromPathId(int pathId) {
    return _idMap[pathId]!;
  }

  static Stream _listenOnSocket(int socketId, int id, int pathId) {
    final nativeSocket = _NativeSocket.watch(socketId);
    final rawSocket = _RawSocket(nativeSocket);
    return rawSocket.expand((event) {
      var stops = [];
      var events = [];
      var pair = {};
      if (event == RawSocketEvent.read) {
        String getPath(event) {
          var path = _pathFromPathId(event[4]).path;
          if (event[2] != null && event[2].isNotEmpty) {
            path += Platform.pathSeparator;
            path += event[2];
          }
          return path;
        }

        bool getIsDir(event) {
          if (Platform.isWindows) {
            // Windows does not get 'isDir' as part of the event.
            // Links should also be skipped.
            return FileSystemEntity.isDirectorySync(getPath(event)) &&
                !FileSystemEntity.isLinkSync(getPath(event));
          }
          return (event[0] & FileSystemEvent._isDir) != 0;
        }

        void add(id, event) {
          if ((event.type & _pathFromPathId(id).events) == 0) return;
          events.add([id, event]);
        }

        void rewriteMove(event, isDir) {
          if (event[3]) {
            add(event[4], new FileSystemCreateEvent(getPath(event), isDir));
          } else {
            add(event[4], new FileSystemDeleteEvent(getPath(event), false));
          }
        }

        int eventCount;
        do {
          eventCount = 0;
          for (var event in _readEvents(id, pathId)) {
            if (event == null) continue;
            eventCount++;
            int pathId = event[4];
            if (!_idMap.containsKey(pathId)) {
              // Path is no longer being wathed.
              continue;
            }
            bool isDir = getIsDir(event);
            var path = getPath(event);
            if ((event[0] & FileSystemEvent.create) != 0) {
              add(event[4], new FileSystemCreateEvent(path, isDir));
            }
            if ((event[0] & FileSystemEvent.modify) != 0) {
              add(event[4], new FileSystemModifyEvent(path, isDir, true));
            }
            if ((event[0] & FileSystemEvent._modifyAttributes) != 0) {
              add(event[4], new FileSystemModifyEvent(path, isDir, false));
            }
            if ((event[0] & FileSystemEvent.move) != 0) {
              int link = event[1];
              if (link > 0) {
                pair.putIfAbsent(pathId, () => {});
                if (pair[pathId].containsKey(link)) {
                  add(
                      event[4],
                      new FileSystemMoveEvent(
                          getPath(pair[pathId][link]), isDir, path));
                  pair[pathId].remove(link);
                } else {
                  pair[pathId][link] = event;
                }
              } else {
                rewriteMove(event, isDir);
              }
            }
            if ((event[0] & FileSystemEvent.delete) != 0) {
              add(event[4], new FileSystemDeleteEvent(path, false));
            }
            if ((event[0] & FileSystemEvent._deleteSelf) != 0) {
              add(event[4], new FileSystemDeleteEvent(path, false));
              // Signal done event.
              stops.add([event[4], null]);
            }
          }
        } while (eventCount > 0);
        // Be sure to clear this manually, as the sockets are not read through
        // the _NativeSocket interface.
        nativeSocket.available = 0;
        for (var map in pair.values) {
          for (var event in map.values) {
            rewriteMove(event, getIsDir(event));
          }
        }
      } else if (event == RawSocketEvent.closed) {
        // After this point we should not try to do anything with pathId as
        // the handle it represented is closed and gone now.
        if (_idMap.containsKey(pathId)) {
          _idMap.remove(pathId);
          if (_idMap.isEmpty && _id != null) {
            _closeWatcher(_id!);
            _id = null;
          }
        }
      } else if (event == RawSocketEvent.readClosed) {
        // If Directory watcher buffer overflows, it will send an readClosed event.
        // Normal closing will cancel stream subscription so that path is
        // no longer being watched, not present in _idMap.
        if (_idMap.containsKey(pathId)) {
          var path = _pathFromPathId(pathId).path;
          _idMap.remove(pathId);
          if (_idMap.isEmpty && _id != null) {
            _closeWatcher(_id!);
            _id = null;
          }
          throw FileSystemException(
              'Directory watcher closed unexpectedly', path);
        }
      } else {
        assert(false);
      }
      events.addAll(stops);
      return events;
    });
  }

  @patch
  @pragma("vm:external-name", "FileSystemWatcher_IsSupported")
  external static bool get isSupported;

  @pragma("vm:external-name", "FileSystemWatcher_InitWatcher")
  external static int _initWatcher();
  @pragma("vm:external-name", "FileSystemWatcher_CloseWatcher")
  external static void _closeWatcher(int id);

  @pragma("vm:external-name", "FileSystemWatcher_WatchPath")
  external static int _watchPath(
      int id, _Namespace namespace, String path, int events, bool recursive);
  @pragma("vm:external-name", "FileSystemWatcher_UnwatchPath")
  external static void _unwatchPath(int id, int path_id);
  @pragma("vm:external-name", "FileSystemWatcher_ReadEvents")
  external static List _readEvents(int id, int path_id);
  @pragma("vm:external-name", "FileSystemWatcher_GetSocketId")
  external static int _getSocketId(int id, int path_id);
}

class _InotifyFileSystemWatcher extends _FileSystemWatcher {
  static final Map<int, StreamController<FileSystemEvent>> _idMap = {};
  static late StreamSubscription _subscription;

  _InotifyFileSystemWatcher(path, events, recursive)
      : super._(path, events, recursive);

  void _newWatcher() {
    int id = _FileSystemWatcher._id!;
    _subscription =
        _FileSystemWatcher._listenOnSocket(id, id, 0).listen((event) {
      if (_idMap.containsKey(event[0])) {
        if (event[1] != null) {
          _idMap[event[0]]!.add(event[1]);
        } else {
          _idMap[event[0]]!.close();
        }
      }
    });
  }

  void _doneWatcher() {
    _subscription.cancel();
  }

  Stream<FileSystemEvent> _pathWatched() {
    var pathId = _watcherPath!.pathId;
    if (!_idMap.containsKey(pathId)) {
      _idMap[pathId] = new StreamController<FileSystemEvent>.broadcast();
    }
    return _idMap[pathId]!.stream;
  }

  void _pathWatchedEnd() {
    var pathId = _watcherPath!.pathId;
    if (!_idMap.containsKey(pathId)) return;
    _idMap[pathId]!.close();
    _idMap.remove(pathId);
  }
}

class _Win32FileSystemWatcher extends _FileSystemWatcher {
  late StreamSubscription _subscription;
  late StreamController<FileSystemEvent> _controller;

  _Win32FileSystemWatcher(path, events, recursive)
      : super._(path, events, recursive);

  Stream<FileSystemEvent> _pathWatched() {
    var pathId = _watcherPath!.pathId;
    _controller = new StreamController<FileSystemEvent>();
    _subscription =
        _FileSystemWatcher._listenOnSocket(pathId, 0, pathId).listen((event) {
      assert(event[0] == pathId);
      if (event[1] != null) {
        _controller.add(event[1]);
      } else {
        _controller.close();
      }
    });
    return _controller.stream;
  }

  void _pathWatchedEnd() {
    _subscription.cancel();
    _controller.close();
  }
}

class _FSEventStreamFileSystemWatcher extends _FileSystemWatcher {
  late StreamSubscription _subscription;
  late StreamController<FileSystemEvent> _controller;

  _FSEventStreamFileSystemWatcher(path, events, recursive)
      : super._(path, events, recursive);

  Stream<FileSystemEvent> _pathWatched() {
    var pathId = _watcherPath!.pathId;
    var socketId = _FileSystemWatcher._getSocketId(0, pathId);
    _controller = new StreamController<FileSystemEvent>();
    _subscription =
        _FileSystemWatcher._listenOnSocket(socketId, 0, pathId).listen((event) {
      if (event[1] != null) {
        _controller.add(event[1]);
      } else {
        _controller.close();
      }
    });
    return _controller.stream;
  }

  void _pathWatchedEnd() {
    _subscription.cancel();
    _controller.close();
  }
}

@pragma("vm:entry-point", "call")
Uint8List _makeUint8ListView(Uint8List source, int offsetInBytes, int length) {
  return new Uint8List.view(source.buffer, offsetInBytes, length);
}
