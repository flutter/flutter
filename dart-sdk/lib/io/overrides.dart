// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

final _ioOverridesToken = new Object();

/// Facilities for overriding various APIs of `dart:io` with mock
/// implementations.
///
/// This abstract base class should be extended with overrides for the
/// operations needed to construct mocks. The implementations in this base class
/// default to the actual `dart:io` implementation. For example:
///
/// ```dart
/// class MyDirectory implements Directory {
///   ...
///   // An implementation of the Directory interface
///   ...
/// }
///
/// void main() {
///   IOOverrides.runZoned(() {
///     ...
///     // Operations will use MyDirectory instead of dart:io's Directory
///     // implementation whenever Directory is used.
///     ...
///   }, createDirectory: (String path) => new MyDirectory(path));
/// }
/// ```
abstract class IOOverrides {
  static IOOverrides? _global;

  static IOOverrides? get current {
    return Zone.current[_ioOverridesToken] ?? _global;
  }

  /// The [IOOverrides] to use in the root [Zone].
  ///
  /// These are the [IOOverrides] that will be used in the root [Zone], and in
  /// [Zone]'s that do not set [IOOverrides] and whose ancestors up to the root
  /// [Zone] also do not set [IOOverrides].
  static set global(IOOverrides? overrides) {
    _global = overrides;
  }

  /// Runs [body] in a fresh [Zone] using the provided overrides.
  ///
  /// See the documentation on the corresponding methods of [IOOverrides] for
  /// information about what the optional arguments do.
  static R runZoned<R>(R body(),
      {
      // Directory
      Directory Function(String)? createDirectory,
      Directory Function()? getCurrentDirectory,
      void Function(String)? setCurrentDirectory,
      Directory Function()? getSystemTempDirectory,

      // File
      File Function(String)? createFile,

      // FileStat
      Future<FileStat> Function(String)? stat,
      FileStat Function(String)? statSync,

      // FileSystemEntity
      Future<bool> Function(String, String)? fseIdentical,
      bool Function(String, String)? fseIdenticalSync,
      Future<FileSystemEntityType> Function(String, bool)? fseGetType,
      FileSystemEntityType Function(String, bool)? fseGetTypeSync,

      // _FileSystemWatcher
      Stream<FileSystemEvent> Function(String, int, bool)? fsWatch,
      bool Function()? fsWatchIsSupported,

      // Link
      Link Function(String)? createLink,

      // Socket
      Future<Socket> Function(dynamic, int,
              {dynamic sourceAddress, int sourcePort, Duration? timeout})?
          socketConnect,
      Future<ConnectionTask<Socket>> Function(dynamic, int,
              {dynamic sourceAddress, int sourcePort})?
          socketStartConnect,

      // ServerSocket
      Future<ServerSocket> Function(dynamic, int,
              {int backlog, bool v6Only, bool shared})?
          serverSocketBind,

      // Standard Streams
      Stdin Function()? stdin,
      Stdout Function()? stdout,
      Stdout Function()? stderr}) {
    // Avoid building chains of override scopes. Just copy outer scope's
    // functions and `_previous`.
    var current = IOOverrides.current;
    _IOOverridesScope? currentScope;
    if (current is _IOOverridesScope) {
      currentScope = current;
      current = currentScope._previous;
    }
    IOOverrides overrides = new _IOOverridesScope(
      current,
      // Directory
      createDirectory ?? currentScope?._createDirectory,
      getCurrentDirectory ?? currentScope?._getCurrentDirectory,
      setCurrentDirectory ?? currentScope?._setCurrentDirectory,
      getSystemTempDirectory ?? currentScope?._getSystemTempDirectory,

      // File
      createFile ?? currentScope?._createFile,

      // FileStat
      stat ?? currentScope?._stat,
      statSync ?? currentScope?._statSync,

      // FileSystemEntity
      fseIdentical ?? currentScope?._fseIdentical,
      fseIdenticalSync ?? currentScope?._fseIdenticalSync,
      fseGetType ?? currentScope?._fseGetType,
      fseGetTypeSync ?? currentScope?._fseGetTypeSync,

      // _FileSystemWatcher
      fsWatch ?? currentScope?._fsWatch,
      fsWatchIsSupported ?? currentScope?._fsWatchIsSupported,

      // Link
      createLink ?? currentScope?._createLink,

      // Socket
      socketConnect ?? currentScope?._socketConnect,
      socketStartConnect ?? currentScope?._socketStartConnect,

      // ServerSocket
      serverSocketBind ?? currentScope?._serverSocketBind,

      // Standard streams
      stdin ?? currentScope?._stdin,
      stdout ?? currentScope?._stdout,
      stderr ?? currentScope?._stderr,
    );
    return dart_async
        .runZoned<R>(body, zoneValues: {_ioOverridesToken: overrides});
  }

  /// Runs [body] in a fresh [Zone] using the overrides found in [overrides].
  ///
  /// Note that [overrides] should be an instance of a class that extends
  /// [IOOverrides].
  static R runWithIOOverrides<R>(R body(), IOOverrides overrides) {
    return dart_async
        .runZoned<R>(body, zoneValues: {_ioOverridesToken: overrides});
  }

  // Directory

  /// Creates a new [Directory] object for the given [path].
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `new Directory()` and `new Directory.fromUri()`.
  Directory createDirectory(String path) => new _Directory(path);

  /// Returns the current working directory.
  ///
  /// When this override is installed, this function overrides the behavior of
  /// the static getter `Directory.current`
  Directory getCurrentDirectory() => _Directory.current;

  /// Sets the current working directory to be [path].
  ///
  /// When this override is installed, this function overrides the behavior of
  /// the setter `Directory.current`.
  void setCurrentDirectory(String path) {
    _Directory.current = path;
  }

  /// Returns the system temporary directory.
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `Directory.systemTemp`.
  Directory getSystemTempDirectory() => _Directory.systemTemp;

  // File

  /// Creates a new [File] object for the given [path].
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `new File()` and `new File.fromUri()`.
  File createFile(String path) => new _File(path);

  // FileStat

  /// Asynchronously returns [FileStat] information for [path].
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `FileStat.stat()`.
  Future<FileStat> stat(String path) {
    return FileStat._stat(path);
  }

  /// Returns [FileStat] information for [path].
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `FileStat.statSync()`.
  FileStat statSync(String path) {
    return FileStat._statSyncInternal(path);
  }

  // FileSystemEntity

  /// Asynchronously returns `true` if [path1] and [path2] are paths to the
  /// same file system object.
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `FileSystemEntity.identical`.
  Future<bool> fseIdentical(String path1, String path2) {
    return FileSystemEntity._identical(path1, path2);
  }

  /// Returns `true` if [path1] and [path2] are paths to the
  /// same file system object.
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `FileSystemEntity.identicalSync`.
  bool fseIdenticalSync(String path1, String path2) {
    return FileSystemEntity._identicalSync(path1, path2);
  }

  /// Asynchronously returns the [FileSystemEntityType] for [path].
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `FileSystemEntity.type`.
  Future<FileSystemEntityType> fseGetType(String path, bool followLinks) {
    return FileSystemEntity._getTypeRequest(utf8.encode(path), followLinks);
  }

  /// Returns the [FileSystemEntityType] for [path].
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `FileSystemEntity.typeSync`.
  FileSystemEntityType fseGetTypeSync(String path, bool followLinks) {
    return FileSystemEntity._getTypeSyncHelper(utf8.encode(path), followLinks);
  }

  // _FileSystemWatcher

  /// Returns a [Stream] of [FileSystemEvent]s.
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `FileSystemEntity.watch()`.
  Stream<FileSystemEvent> fsWatch(String path, int events, bool recursive) {
    return _FileSystemWatcher._watch(path, events, recursive);
  }

  /// Returns `true` when [FileSystemEntity.watch] is supported.
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `FileSystemEntity.isWatchSupported`.
  bool fsWatchIsSupported() => _FileSystemWatcher.isSupported;

  // Link

  /// Returns a new [Link] object for the given [path].
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `new Link()` and `new Link.fromUri()`.
  Link createLink(String path) => new _Link(path);

  // Socket

  /// Asynchronously returns a [Socket] connected to the given host and port.
  ///
  /// When this override is installed, this functions overrides the behavior of
  /// `Socket.connect(...)`.
  Future<Socket> socketConnect(host, int port,
      {sourceAddress, int sourcePort = 0, Duration? timeout}) {
    return Socket._connect(host, port,
        sourceAddress: sourceAddress, sourcePort: sourcePort, timeout: timeout);
  }

  /// Asynchronously returns a [ConnectionTask] that connects to the given host
  /// and port when successful.
  ///
  /// When this override is installed, this functions overrides the behavior of
  /// `Socket.startConnect(...)`.
  Future<ConnectionTask<Socket>> socketStartConnect(host, int port,
      {sourceAddress, int sourcePort = 0}) {
    return Socket._startConnect(host, port,
        sourceAddress: sourceAddress, sourcePort: sourcePort);
  }

  // ServerSocket

  /// Asynchronously returns a [ServerSocket] that connects to the given address
  /// and port when successful.
  ///
  /// When this override is installed, this functions overrides the behavior of
  /// `ServerSocket.bind(...)`.
  Future<ServerSocket> serverSocketBind(address, int port,
      {int backlog = 0, bool v6Only = false, bool shared = false}) {
    return ServerSocket._bind(address, port,
        backlog: backlog, v6Only: v6Only, shared: shared);
  }

  // Standard streams

  /// The standard input stream of data read by this program.
  ///
  /// When this override is installed, this getter overrides the behavior of
  /// the top-level `stdin` getter.
  Stdin get stdin {
    return _stdin;
  }

  /// The standard output stream of data written by this program.
  ///
  /// When this override is installed, this getter overrides the behavior of
  /// the top-level `stdout` getter.
  Stdout get stdout {
    return _stdout;
  }

  /// The standard output stream of errors written by this program.
  ///
  /// When this override is installed, this getter overrides the behavior of
  /// the top-level `stderr` getter.
  Stdout get stderr {
    return _stderr;
  }
}

class _IOOverridesScope extends IOOverrides {
  final IOOverrides? _previous;

  // Directory
  final Directory Function(String)? _createDirectory;
  final Directory Function()? _getCurrentDirectory;
  final void Function(String)? _setCurrentDirectory;
  final Directory Function()? _getSystemTempDirectory;

  // File
  final File Function(String)? _createFile;

  // FileStat
  final Future<FileStat> Function(String)? _stat;
  final FileStat Function(String)? _statSync;

  // FileSystemEntity
  final Future<bool> Function(String, String)? _fseIdentical;
  final bool Function(String, String)? _fseIdenticalSync;
  final Future<FileSystemEntityType> Function(String, bool)? _fseGetType;
  final FileSystemEntityType Function(String, bool)? _fseGetTypeSync;

  // _FileSystemWatcher
  final Stream<FileSystemEvent> Function(String, int, bool)? _fsWatch;
  final bool Function()? _fsWatchIsSupported;

  // Link
  final Link Function(String)? _createLink;

  // Socket
  final Future<Socket> Function(dynamic, int,
      {dynamic sourceAddress,
      int sourcePort,
      Duration? timeout})? _socketConnect;
  final Future<ConnectionTask<Socket>> Function(dynamic, int,
      {dynamic sourceAddress, int sourcePort})? _socketStartConnect;

  // ServerSocket
  final Future<ServerSocket> Function(dynamic, int,
      {int backlog, bool v6Only, bool shared})? _serverSocketBind;

  // Standard streams
  final Stdin Function()? _stdin;
  final Stdout Function()? _stdout;
  final Stdout Function()? _stderr;

  _IOOverridesScope(
    this._previous,

    // Directory
    this._createDirectory,
    this._getCurrentDirectory,
    this._setCurrentDirectory,
    this._getSystemTempDirectory,

    // File
    this._createFile,

    // FileStat
    this._stat,
    this._statSync,

    // FileSystemEntity
    this._fseIdentical,
    this._fseIdenticalSync,
    this._fseGetType,
    this._fseGetTypeSync,

    // _FileSystemWatcher
    this._fsWatch,
    this._fsWatchIsSupported,

    // Link
    this._createLink,

    // Socket
    this._socketConnect,
    this._socketStartConnect,

    // ServerSocket
    this._serverSocketBind,

    // Standard streams
    this._stdin,
    this._stdout,
    this._stderr,
  );

  // Directory
  @override
  Directory createDirectory(String path) =>
      _createDirectory?.call(path) ??
      _previous?.createDirectory(path) ??
      super.createDirectory(path);

  @override
  Directory getCurrentDirectory() =>
      _getCurrentDirectory?.call() ??
      _previous?.getCurrentDirectory() ??
      super.getCurrentDirectory();

  @override
  void setCurrentDirectory(String path) {
    var setter = _setCurrentDirectory;
    if (setter != null) {
      setter(path);
    } else {
      super.setCurrentDirectory(path);
    }
  }

  @override
  Directory getSystemTempDirectory() =>
      _getSystemTempDirectory?.call() ??
      _previous?.getSystemTempDirectory() ??
      super.getSystemTempDirectory();

  // File
  @override
  File createFile(String path) =>
      _createFile?.call(path) ??
      _previous?.createFile(path) ??
      super.createFile(path);

  // FileStat
  @override
  Future<FileStat> stat(String path) =>
      _stat?.call(path) ?? _previous?.stat(path) ?? super.stat(path);

  @override
  FileStat statSync(String path) =>
      _statSync?.call(path) ??
      _previous?.statSync(path) ??
      super.statSync(path);

  // FileSystemEntity
  @override
  Future<bool> fseIdentical(String path1, String path2) =>
      _fseIdentical?.call(path1, path2) ??
      _previous?.fseIdentical(path1, path2) ??
      super.fseIdentical(path1, path2);

  @override
  bool fseIdenticalSync(String path1, String path2) =>
      _fseIdenticalSync?.call(path1, path2) ??
      _previous?.fseIdenticalSync(path1, path2) ??
      super.fseIdenticalSync(path1, path2);

  @override
  Future<FileSystemEntityType> fseGetType(String path, bool followLinks) =>
      _fseGetType?.call(path, followLinks) ??
      _previous?.fseGetType(path, followLinks) ??
      super.fseGetType(path, followLinks);

  @override
  FileSystemEntityType fseGetTypeSync(String path, bool followLinks) =>
      _fseGetTypeSync?.call(path, followLinks) ??
      _previous?.fseGetTypeSync(path, followLinks) ??
      super.fseGetTypeSync(path, followLinks);

  // _FileSystemWatcher
  @override
  Stream<FileSystemEvent> fsWatch(String path, int events, bool recursive) =>
      _fsWatch?.call(path, events, recursive) ??
      _previous?.fsWatch(path, events, recursive) ??
      super.fsWatch(path, events, recursive);

  @override
  bool fsWatchIsSupported() =>
      _fsWatchIsSupported?.call() ??
      _previous?.fsWatchIsSupported() ??
      super.fsWatchIsSupported();

  // Link
  @override
  Link createLink(String path) =>
      _createLink?.call(path) ??
      _previous?.createLink(path) ??
      super.createLink(path);

  // Socket
  @override
  Future<Socket> socketConnect(host, int port,
          {sourceAddress, int sourcePort = 0, Duration? timeout}) =>
      _socketConnect?.call(host, port,
          sourceAddress: sourceAddress,
          sourcePort: sourcePort,
          timeout: timeout) ??
      _previous?.socketConnect(host, port,
          sourceAddress: sourceAddress,
          sourcePort: sourcePort,
          timeout: timeout) ??
      super.socketConnect(host, port,
          sourceAddress: sourceAddress,
          sourcePort: sourcePort,
          timeout: timeout);

  @override
  Future<ConnectionTask<Socket>> socketStartConnect(host, int port,
          {sourceAddress, int sourcePort = 0}) =>
      _socketStartConnect?.call(host, port,
          sourceAddress: sourceAddress, sourcePort: sourcePort) ??
      _previous?.socketStartConnect(host, port,
          sourceAddress: sourceAddress, sourcePort: sourcePort) ??
      super.socketStartConnect(host, port,
          sourceAddress: sourceAddress, sourcePort: sourcePort);

  // ServerSocket
  @override
  Future<ServerSocket> serverSocketBind(address, int port,
          {int backlog = 0, bool v6Only = false, bool shared = false}) =>
      _serverSocketBind?.call(address, port,
          backlog: backlog, v6Only: v6Only, shared: shared) ??
      _previous?.serverSocketBind(address, port,
          backlog: backlog, v6Only: v6Only, shared: shared) ??
      super.serverSocketBind(address, port,
          backlog: backlog, v6Only: v6Only, shared: shared);

  // Standard streams
  @override
  Stdin get stdin => _stdin?.call() ?? _previous?.stdin ?? super.stdin;

  @override
  Stdout get stdout => _stdout?.call() ?? _previous?.stdout ?? super.stdout;

  @override
  Stdout get stderr => _stderr?.call() ?? _previous?.stderr ?? super.stderr;
}
