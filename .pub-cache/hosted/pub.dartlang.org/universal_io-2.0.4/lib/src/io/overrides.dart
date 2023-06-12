// ------------------------------------------------------------------
// THIS FILE WAS DERIVED FROM SOURCE CODE UNDER THE FOLLOWING LICENSE
// ------------------------------------------------------------------
//
// Copyright 2012, the Dart project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ---------------------------------------------------------
// THIS, DERIVED FILE IS LICENSE UNDER THE FOLLOWING LICENSE
// ---------------------------------------------------------
// Copyright 2020 terrier989@gmail.com.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';

import 'package:universal_io/src/io_impl_js.dart';

import '../io_impl_js.dart';

const _asyncRunZoned = runZoned;

final _ioOverridesToken = Object();

/// This class facilitates overriding various APIs of dart:io with mock
/// implementations.
///
/// This abstract base class should be extended with overrides for the
/// operations needed to construct mocks. The implementations in this base class
/// default to the actual dart:io implementation. For example:
///
/// ```
/// class MyDirectory implements Directory {
///   ...
///   // An implementation of the Directory interface
///   ...
/// }
///
/// main() {
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
  /// These are the [IOOverrides] that will be used in the root Zone, and in
  /// Zone's that do not set [IOOverrides] and whose ancestors up to the root
  /// Zone do not set [IOOverrides].
  static set global(IOOverrides? overrides) {
    _global = overrides;
  }

  /// Creates a new [Directory] object for the given [path].
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `new Directory()` and `new Directory.fromUri()`.
  Directory createDirectory(String path) => throw UnimplementedError();

  /// Creates a new [File] object for the given [path].
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `new File()` and `new File.fromUri()`.
  File createFile(String path) => throw UnimplementedError();

  // Directory

  /// Returns a new [Link] object for the given [path].
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `new Link()` and `new Link.fromUri()`.
  Link createLink(String path) => throw UnimplementedError();

  /// Asynchronously returns the [FileSystemEntityType] for [path].
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `FileSystemEntity.type`.
  Future<FileSystemEntityType> fseGetType(String path, bool followLinks) {
    throw UnimplementedError();
  }

  /// Returns the [FileSystemEntityType] for [path].
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `FileSystemEntity.typeSync`.
  FileSystemEntityType fseGetTypeSync(String path, bool followLinks) {
    throw UnimplementedError();
  }

  /// Asynchronously returns `true` if [path1] and [path2] are paths to the
  /// same file system object.
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `FileSystemEntity.identical`.
  Future<bool> fseIdentical(String path1, String path2) {
    throw UnimplementedError();
  }

  // File

  /// Returns `true` if [path1] and [path2] are paths to the
  /// same file system object.
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `FileSystemEntity.identicalSync`.
  bool fseIdenticalSync(String path1, String path2) {
    throw UnimplementedError();
  }

  // FileStat

  /// Returns a [Stream] of [FileSystemEvent]s.
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `FileSystemEntity.watch()`.
  Stream<FileSystemEvent> fsWatch(String path, int events, bool recursive) {
    throw UnimplementedError();
  }

  /// Returns `true` when [FileSystemEntity.watch] is supported.
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `FileSystemEntity.isWatchSupported`.
  bool fsWatchIsSupported() => throw UnimplementedError();

  // FileSystemEntity

  /// Returns the current working directory.
  ///
  /// When this override is installed, this function overrides the behavior of
  /// the static getter `Directory.current`
  Directory getCurrentDirectory() => throw UnimplementedError();

  /// Returns the system temporary directory.
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `Directory.systemTemp`.
  Directory getSystemTempDirectory() => throw UnimplementedError();

  /// Asynchronously returns a [ServerSocket] that connects to the given address
  /// and port when successful.
  ///
  /// When this override is installed, this functions overrides the behavior of
  /// `ServerSocket.bind(...)`.
  Future<ServerSocket> serverSocketBind(address, int port,
      {int backlog = 0, bool v6Only = false, bool shared = false}) {
    throw UnimplementedError();
  }

  /// Sets the current working directory to be [path].
  ///
  /// When this override is installed, this function overrides the behavior of
  /// the setter `Directory.current`.
  void setCurrentDirectory(String path) {
    throw UnimplementedError();
  }

  // _FileSystemWatcher

  /// Asynchronously returns a [Socket] connected to the given host and port.
  ///
  /// When this override is installed, this functions overrides the behavior of
  /// `Socket.connect(...)`.
  Future<Socket> socketConnect(host, int port,
      {sourceAddress, Duration? timeout}) {
    throw UnimplementedError();
  }

  /// Asynchronously returns a [ConnectionTask] that connects to the given host
  /// and port when successful.
  ///
  /// When this override is installed, this functions overrides the behavior of
  /// `Socket.startConnect(...)`.
  Future<ConnectionTask<Socket>> socketStartConnect(host, int port,
      {sourceAddress}) {
    throw UnimplementedError();
  }

  // Link

  /// Asynchronously returns [FileStat] information for [path].
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `FileStat.stat()`.
  Future<FileStat> stat(String path) {
    throw UnimplementedError();
  }

  // Socket

  /// Returns [FileStat] information for [path].
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `FileStat.statSync()`.
  FileStat statSync(String path) {
    throw UnimplementedError();
  }

  /// Runs [body] in a fresh [Zone] using the overrides found in [overrides].
  ///
  /// Note that [overrides] should be an instance of a class that extends
  /// [IOOverrides].
  static R runWithIOOverrides<R>(R Function() body, IOOverrides overrides) {
    return _asyncRunZoned<R>(body, zoneValues: {_ioOverridesToken: overrides});
  }

  // ServerSocket

  /// Runs [body] in a fresh [Zone] using the provided overrides.
  ///
  /// See the documentation on the corresponding methods of IOOverrides for
  /// information about what the optional arguments do.
  static R runZoned<R>(R Function() body,
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
              {dynamic sourceAddress, Duration? timeout})?
          socketConnect,
      Future<ConnectionTask<Socket>> Function(dynamic, int,
              {dynamic sourceAddress})?
          socketStartConnect,

      // ServerSocket
      Future<ServerSocket> Function(dynamic, int,
              {int backlog, bool v6Only, bool shared})?
          serverSocketBind}) {
    IOOverrides overrides = _IOOverridesScope(
      // Directory
      createDirectory,
      getCurrentDirectory,
      setCurrentDirectory,
      getSystemTempDirectory,

      // File
      createFile,

      // FileStat
      stat,
      statSync,

      // FileSystemEntity
      fseIdentical,
      fseIdenticalSync,
      fseGetType,
      fseGetTypeSync,

      // _FileSystemWatcher
      fsWatch,
      fsWatchIsSupported,

      // Link
      createLink,

      // Socket
      socketConnect,
      socketStartConnect,

      // ServerSocket
      serverSocketBind,
    );
    return _asyncRunZoned<R>(body, zoneValues: {_ioOverridesToken: overrides});
  }
}

class _IOOverridesScope extends IOOverrides {
  final IOOverrides? _previous = IOOverrides.current;

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
      {dynamic sourceAddress, Duration? timeout})? _socketConnect;
  final Future<ConnectionTask<Socket>> Function(dynamic, int,
      {dynamic sourceAddress})? _socketStartConnect;

  // ServerSocket
  final Future<ServerSocket> Function(dynamic, int,
      {int backlog, bool v6Only, bool shared})? _serverSocketBind;

  _IOOverridesScope(
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
  );

  // Directory
  @override
  Directory createDirectory(String path) {
    if (_createDirectory != null) return _createDirectory!(path);
    if (_previous != null) return _previous!.createDirectory(path);
    return super.createDirectory(path);
  }

  @override
  File createFile(String path) {
    if (_createFile != null) return _createFile!(path);
    if (_previous != null) return _previous!.createFile(path);
    return super.createFile(path);
  }

  @override
  Link createLink(String path) {
    if (_createLink != null) return _createLink!(path);
    if (_previous != null) return _previous!.createLink(path);
    return super.createLink(path);
  }

  @override
  Future<FileSystemEntityType> fseGetType(String path, bool followLinks) {
    if (_fseGetType != null) return _fseGetType!(path, followLinks);
    if (_previous != null) return _previous!.fseGetType(path, followLinks);
    return super.fseGetType(path, followLinks);
  }

  // File
  @override
  FileSystemEntityType fseGetTypeSync(String path, bool followLinks) {
    if (_fseGetTypeSync != null) return _fseGetTypeSync!(path, followLinks);
    if (_previous != null) return _previous!.fseGetTypeSync(path, followLinks);
    return super.fseGetTypeSync(path, followLinks);
  }

  // FileStat
  @override
  Future<bool> fseIdentical(String path1, String path2) {
    if (_fseIdentical != null) return _fseIdentical!(path1, path2);
    if (_previous != null) return _previous!.fseIdentical(path1, path2);
    return super.fseIdentical(path1, path2);
  }

  @override
  bool fseIdenticalSync(String path1, String path2) {
    if (_fseIdenticalSync != null) return _fseIdenticalSync!(path1, path2);
    if (_previous != null) return _previous!.fseIdenticalSync(path1, path2);
    return super.fseIdenticalSync(path1, path2);
  }

  // FileSystemEntity
  @override
  Stream<FileSystemEvent> fsWatch(String path, int events, bool recursive) {
    if (_fsWatch != null) return _fsWatch!(path, events, recursive);
    if (_previous != null) return _previous!.fsWatch(path, events, recursive);
    return super.fsWatch(path, events, recursive);
  }

  @override
  bool fsWatchIsSupported() {
    if (_fsWatchIsSupported != null) return _fsWatchIsSupported!();
    if (_previous != null) return _previous!.fsWatchIsSupported();
    return super.fsWatchIsSupported();
  }

  @override
  Directory getCurrentDirectory() {
    if (_getCurrentDirectory != null) return _getCurrentDirectory!();
    if (_previous != null) return _previous!.getCurrentDirectory();
    return super.getCurrentDirectory();
  }

  @override
  Directory getSystemTempDirectory() {
    if (_getSystemTempDirectory != null) return _getSystemTempDirectory!();
    if (_previous != null) return _previous!.getSystemTempDirectory();
    return super.getSystemTempDirectory();
  }

  // _FileSystemWatcher
  @override
  Future<ServerSocket> serverSocketBind(address, int port,
      {int backlog = 0, bool v6Only = false, bool shared = false}) {
    if (_serverSocketBind != null) {
      return _serverSocketBind!(address, port,
          backlog: backlog, v6Only: v6Only, shared: shared);
    }
    if (_previous != null) {
      return _previous!.serverSocketBind(address, port,
          backlog: backlog, v6Only: v6Only, shared: shared);
    }
    return super.serverSocketBind(address, port,
        backlog: backlog, v6Only: v6Only, shared: shared);
  }

  @override
  void setCurrentDirectory(String path) {
    if (_setCurrentDirectory != null) {
      _setCurrentDirectory!(path);
    } else if (_previous != null) {
      _previous!.setCurrentDirectory(path);
    } else {
      super.setCurrentDirectory(path);
    }
  }

  // Link
  @override
  Future<Socket> socketConnect(host, int port,
      {sourceAddress, Duration? timeout}) {
    if (_socketConnect != null) {
      return _socketConnect!(host, port,
          sourceAddress: sourceAddress, timeout: timeout);
    }
    if (_previous != null) {
      return _previous!.socketConnect(host, port,
          sourceAddress: sourceAddress, timeout: timeout);
    }
    return super.socketConnect(host, port,
        sourceAddress: sourceAddress, timeout: timeout);
  }

  // Socket
  @override
  Future<ConnectionTask<Socket>> socketStartConnect(host, int port,
      {sourceAddress}) {
    if (_socketStartConnect != null) {
      return _socketStartConnect!(host, port, sourceAddress: sourceAddress);
    }
    if (_previous != null) {
      return _previous!
          .socketStartConnect(host, port, sourceAddress: sourceAddress);
    }
    return super.socketStartConnect(host, port, sourceAddress: sourceAddress);
  }

  @override
  Future<FileStat> stat(String path) {
    if (_stat != null) return _stat!(path);
    if (_previous != null) return _previous!.stat(path);
    return super.stat(path);
  }

  // ServerSocket
  @override
  FileStat statSync(String path) {
    if (_stat != null) return _statSync!(path);
    if (_previous != null) return _previous!.statSync(path);
    return super.statSync(path);
  }
}
