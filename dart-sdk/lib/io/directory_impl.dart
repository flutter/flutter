// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

class _Directory extends FileSystemEntity implements Directory {
  final String _path;
  final Uint8List _rawPath;

  _Directory(String path)
      : _path = _checkNotNull(path, "path"),
        _rawPath = FileSystemEntity._toUtf8Array(path);

  _Directory.fromRawPath(Uint8List rawPath)
      : _rawPath = FileSystemEntity._toNullTerminatedUtf8Array(
            _checkNotNull(rawPath, "rawPath")),
        _path = FileSystemEntity._toStringFromUtf8Array(rawPath);

  String get path => _path;

  external static _current(_Namespace namespace);
  external static _setCurrent(_Namespace namespace, Uint8List rawPath);
  external static _createTemp(_Namespace namespace, Uint8List rawPath);
  external static String _systemTemp(_Namespace namespace);
  external static _exists(_Namespace namespace, Uint8List rawPath);
  external static _create(_Namespace namespace, Uint8List rawPath);
  external static _deleteNative(
      _Namespace namespace, Uint8List rawPath, bool recursive);
  external static _rename(
      _Namespace namespace, Uint8List rawPath, String newPath);
  external static void _fillWithDirectoryListing(
      _Namespace namespace,
      List<FileSystemEntity> list,
      Uint8List rawPath,
      bool recursive,
      bool followLinks);

  static Directory get current {
    var result = _current(_Namespace._namespace);
    if (result is OSError) {
      throw FileSystemException._fromOSError(
          result, "Getting current working directory failed", "");
    }
    return new _Directory(result);
  }

  static void set current(Object? path) {
    var _rawPath = switch (path) {
      // For our internal Directory implementation, go ahead and use the raw
      // path.
      _Directory d => d._rawPath,
      // Fall back to the String-based path.
      Directory d => FileSystemEntity._toUtf8Array(d.path),
      String s => FileSystemEntity._toUtf8Array(s),
      _ => throw ArgumentError('${Error.safeToString(path)} is not a String or'
          ' Directory')
    };

    if (!_EmbedderConfig._mayChdir) {
      throw new UnsupportedError(
          "This embedder disallows setting Directory.current");
    }
    var result = _setCurrent(_Namespace._namespace, _rawPath);
    if (result is ArgumentError) throw result;
    if (result is OSError) {
      throw FileSystemException._fromOSError(
          result, "Setting current working directory failed", path.toString());
    }
  }

  Uri get uri {
    return new Uri.directory(path);
  }

  Future<bool> exists() {
    return _File._dispatchWithNamespace(
        _IOService.directoryExists, [null, _rawPath]).then((response) {
      _checkForErrorResponse(response, "Exists failed", path);
      return response == 1;
    });
  }

  bool existsSync() {
    var result = _exists(_Namespace._namespace, _rawPath);
    if (result is OSError) {
      throw new FileSystemException("Exists failed", path, result);
    }
    return (result == 1);
  }

  Directory get absolute => new Directory(_absolutePath);

  Future<Directory> create({bool recursive = false}) {
    if (recursive) {
      return exists().then((exists) {
        if (exists) return this;
        if (path != parent.path) {
          return parent.create(recursive: true).then((_) {
            return create();
          });
        } else {
          return create();
        }
      });
    } else {
      return _File._dispatchWithNamespace(
          _IOService.directoryCreate, [null, _rawPath]).then((response) {
        _checkForErrorResponse(response, "Creation failed", path);
        return this;
      });
    }
  }

  void createSync({bool recursive = false}) {
    if (recursive) {
      if (existsSync()) return;
      if (path != parent.path) {
        parent.createSync(recursive: true);
      }
    }
    var result = _create(_Namespace._namespace, _rawPath);
    if (result is OSError) {
      throw FileSystemException._fromOSError(result, "Creation failed", path);
    }
  }

  static Directory get systemTemp =>
      new Directory(_systemTemp(_Namespace._namespace));

  Future<Directory> createTemp([String? prefix]) {
    prefix ??= '';
    if (path == '') {
      throw new ArgumentError("Directory.createTemp called with an empty path. "
          "To use the system temp directory, use Directory.systemTemp");
    }
    String fullPrefix;
    // FIXME(bkonyi): here we're using `path` directly, which might cause
    // issues if it is not UTF-8 encoded.
    if (path.endsWith('/') || (Platform.isWindows && path.endsWith('\\'))) {
      fullPrefix = "$path$prefix";
    } else {
      fullPrefix = "$path${Platform.pathSeparator}$prefix";
    }
    return _File._dispatchWithNamespace(_IOService.directoryCreateTemp,
        [null, FileSystemEntity._toUtf8Array(fullPrefix)]).then((response) {
      _checkForErrorResponse(
          response, "Creation of temporary directory failed", path);
      return Directory(response as String);
    });
  }

  Directory createTempSync([String? prefix]) {
    prefix ??= '';
    if (path == '') {
      throw new ArgumentError("Directory.createTemp called with an empty path. "
          "To use the system temp directory, use Directory.systemTemp");
    }
    String fullPrefix;
    // FIXME(bkonyi): here we're using `path` directly, which might cause
    // issues if it is not UTF-8 encoded.
    if (path.endsWith('/') || (Platform.isWindows && path.endsWith('\\'))) {
      fullPrefix = "$path$prefix";
    } else {
      fullPrefix = "$path${Platform.pathSeparator}$prefix";
    }
    var result = _createTemp(
        _Namespace._namespace, FileSystemEntity._toUtf8Array(fullPrefix));
    if (result is OSError) {
      throw new FileSystemException._fromOSError(
          result, "Creation of temporary directory failed", fullPrefix);
    }
    return new Directory(result);
  }

  Future<Directory> _delete({bool recursive = false}) {
    return _File._dispatchWithNamespace(
            _IOService.directoryDelete, [null, _rawPath, recursive])
        .then((response) {
      _checkForErrorResponse(response, "Deletion failed", path);
      return this;
    });
  }

  void _deleteSync({bool recursive = false}) {
    var result = _deleteNative(_Namespace._namespace, _rawPath, recursive);
    if (result is OSError) {
      throw FileSystemException._fromOSError(result, "Deletion failed", path);
    }
  }

  Future<Directory> rename(String newPath) {
    return _File._dispatchWithNamespace(
        _IOService.directoryRename, [null, _rawPath, newPath]).then((response) {
      _checkForErrorResponse(response, "Rename failed", path);
      return new Directory(newPath);
    });
  }

  Directory renameSync(String newPath) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(newPath, "newPath");
    var result = _rename(_Namespace._namespace, _rawPath, newPath);
    if (result is OSError) {
      throw FileSystemException._fromOSError(result, "Rename failed", path);
    }
    return new Directory(newPath);
  }

  Stream<FileSystemEntity> list(
      {bool recursive = false, bool followLinks = true}) {
    return new _AsyncDirectoryLister(
            // FIXME(bkonyi): here we're using `path` directly, which might cause issues
            // if it is not UTF-8 encoded.
            FileSystemEntity._toUtf8Array(
                FileSystemEntity._ensureTrailingPathSeparators(path)),
            recursive,
            followLinks)
        .stream;
  }

  List<FileSystemEntity> listSync(
      {bool recursive = false, bool followLinks = true}) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(recursive, "recursive");
    ArgumentError.checkNotNull(followLinks, "followLinks");
    var result = <FileSystemEntity>[];
    _fillWithDirectoryListing(
        _Namespace._namespace,
        result,
        // FIXME(bkonyi): here we're using `path` directly, which might cause issues
        // if it is not UTF-8 encoded.
        FileSystemEntity._toUtf8Array(
            FileSystemEntity._ensureTrailingPathSeparators(path)),
        recursive,
        followLinks);
    return result;
  }

  String toString() => "Directory: '$path'";

  // TODO(40614): Remove once non-nullability is sound.
  static T _checkNotNull<T>(T t, String name) {
    ArgumentError.checkNotNull(t, name);
    return t;
  }
}

abstract class _AsyncDirectoryListerOps {
  external factory _AsyncDirectoryListerOps(int pointer);

  int? getPointer();
}

class _AsyncDirectoryLister {
  static const int listFile = 0;
  static const int listDirectory = 1;
  static const int listLink = 2;
  static const int listError = 3;
  static const int listDone = 4;

  static const int responseType = 0;
  static const int responsePath = 1;
  static const int responseComplete = 1;
  static const int responseError = 2;

  final Uint8List rawPath;
  final bool recursive;
  final bool followLinks;

  final controller = new StreamController<FileSystemEntity>(sync: true);
  bool canceled = false;
  bool nextRunning = false;
  bool closed = false;
  _AsyncDirectoryListerOps? _ops;
  Completer closeCompleter = new Completer();

  _AsyncDirectoryLister(this.rawPath, this.recursive, this.followLinks) {
    controller
      ..onListen = onListen
      ..onResume = onResume
      ..onCancel = onCancel;
  }

  // WARNING:
  // Calling this function will increase the reference count on the native
  // object that implements the async directory lister operations. It should
  // only be called to pass the pointer to the IO Service, which will decrement
  // the reference count when it is finished with it.
  int? _pointer() {
    return _ops?.getPointer();
  }

  Stream<FileSystemEntity> get stream => controller.stream;

  void onListen() {
    _File._dispatchWithNamespace(_IOService.directoryListStart,
        [null, rawPath, recursive, followLinks]).then((response) {
      if (response is int) {
        _ops = new _AsyncDirectoryListerOps(response);
        next();
      } else if (response is Error) {
        controller.addError(response, response.stackTrace);
        close();
      } else {
        error(response as List<Object?>);
        close();
      }
    });
  }

  void onResume() {
    if (!nextRunning) {
      next();
    }
  }

  Future onCancel() {
    canceled = true;
    // If we are active, but not requesting, close.
    if (!nextRunning) {
      close();
    }

    return closeCompleter.future;
  }

  void next() {
    if (canceled) {
      close();
      return;
    }
    if (controller.isPaused || nextRunning) {
      return;
    }
    var pointer = _pointer();
    if (pointer == null) {
      return;
    }
    nextRunning = true;
    _IOService._dispatch(_IOService.directoryListNext, [pointer])
        .then((result) {
      nextRunning = false;
      if (result is List) {
        next();
        assert(result.length % 2 == 0);
        for (int i = 0; i < result.length; i++) {
          assert(i % 2 == 0);
          switch (result[i++]) {
            case listFile:
              controller.add(new File.fromRawPath(result[i]));
              break;
            case listDirectory:
              controller.add(new Directory.fromRawPath(result[i]));
              break;
            case listLink:
              controller.add(new Link.fromRawPath(result[i]));
              break;
            case listError:
              error(result[i]);
              break;
            case listDone:
              canceled = true;
              return;
          }
        }
      } else {
        controller.addError(new FileSystemException("Internal error"));
      }
    });
  }

  void _cleanup() {
    controller.close();
    closeCompleter.complete();
    _ops = null;
  }

  void close() {
    if (closed) {
      return;
    }
    if (nextRunning) {
      return;
    }
    closed = true;

    var pointer = _pointer();
    if (pointer == null) {
      _cleanup();
    } else {
      _IOService._dispatch(_IOService.directoryListStop, [pointer])
          .whenComplete(_cleanup);
    }
  }

  void error(List<Object?> message) {
    var errorResponseInfo = message[responseError]! as List<Object?>;
    var errorType = errorResponseInfo[_errorResponseErrorType];
    if (errorType == _illegalArgumentResponse) {
      controller.addError(new ArgumentError());
    } else if (errorType == _osErrorResponse) {
      var err = new OSError(
          errorResponseInfo[_osErrorResponseMessage] as String,
          errorResponseInfo[_osErrorResponseErrorCode] as int);
      var errorPath = message[responsePath];
      if (errorPath == null) {
        errorPath = utf8.decode(rawPath, allowMalformed: true);
      } else if (errorPath is Uint8List) {
        errorPath = utf8.decode(errorPath, allowMalformed: true);
      }
      controller.addError(FileSystemException._fromOSError(
          err, "Directory listing failed", errorPath as String));
    } else {
      controller.addError(new FileSystemException("Internal error"));
    }
  }
}
