// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.backends.chroot;

abstract class _ChrootFileSystemEntity<T extends FileSystemEntity,
    D extends io.FileSystemEntity> extends ForwardingFileSystemEntity<T, D> {
  _ChrootFileSystemEntity(this.fileSystem, this.path);

  @override
  final ChrootFileSystem fileSystem;

  @override
  final String path;

  @override
  String get dirname => fileSystem.path.dirname(path);

  @override
  String get basename => fileSystem.path.basename(path);

  @override
  D get delegate => getDelegate();

  /// Gets the delegate file system entity in the underlying file system that
  /// corresponds to this entity's local file system path.
  ///
  /// If [followLinks] is true and this entity's path references a symbolic
  /// link, then the path of the delegate entity will reference the ultimate
  /// target of that symbolic link. Symbolic links in the middle of the path
  /// will always be resolved in the delegate entity's path.
  D getDelegate({bool followLinks = false}) =>
      _rawDelegate(fileSystem._real(path, followLinks: followLinks));

  /// Returns the expected type of this entity, which may differ from the type
  /// of the entity that's found at the path specified by this entity.
  FileSystemEntityType get expectedType;

  /// Returns a delegate entity at the specified [realPath] (the path in the
  /// underlying file system).
  D _rawDelegate(String realPath);

  /// Gets the path of this entity as an absolute path (unchanged if the
  /// entity already specifies an absolute path).
  String get _absolutePath => fileSystem.path.absolute(path);

  /// Tells whether this entity's path references a symbolic link.
  bool get _isLink =>
      fileSystem.typeSync(path, followLinks: false) ==
      FileSystemEntityType.link;

  @override
  Directory wrapDirectory(io.Directory delegate) =>
      _ChrootDirectory.wrapped(fileSystem, delegate as Directory,
          relative: !isAbsolute);

  @override
  File wrapFile(io.File delegate) =>
      _ChrootFile.wrapped(fileSystem, delegate, relative: !isAbsolute);

  @override
  Link wrapLink(io.Link delegate) =>
      _ChrootLink.wrapped(fileSystem, delegate, relative: !isAbsolute);

  @override
  Uri get uri => Uri.file(path);

  @override
  Future<bool> exists() => getDelegate(followLinks: true).exists();

  @override
  bool existsSync() => getDelegate(followLinks: true).existsSync();

  @override
  Future<String> resolveSymbolicLinks() async => resolveSymbolicLinksSync();

  @override
  String resolveSymbolicLinksSync() =>
      fileSystem._resolve(path, notFound: _NotFoundBehavior.throwError);

  @override
  Future<FileStat> stat() {
    D delegate;
    try {
      delegate = getDelegate(followLinks: true);
    } on FileSystemException {
      return Future<FileStat>.value(const _NotFoundFileStat());
    }
    return delegate.stat();
  }

  @override
  FileStat statSync() {
    D delegate;
    try {
      delegate = getDelegate(followLinks: true);
    } on FileSystemException {
      return const _NotFoundFileStat();
    }
    return delegate.statSync();
  }

  @override
  Future<T> delete({bool recursive = false}) async {
    String path = fileSystem._resolve(this.path,
        followLinks: false, notFound: _NotFoundBehavior.throwError);

    String real(String path) => fileSystem._real(path, resolve: false);
    Future<FileSystemEntityType> type(String path) =>
        fileSystem.delegate.type(real(path), followLinks: false);

    if (await type(path) == FileSystemEntityType.link) {
      if (expectedType == FileSystemEntityType.link) {
        await fileSystem.delegate.link(real(path)).delete();
      } else {
        String resolvedPath = fileSystem._resolve(p.basename(path),
            from: p.dirname(path), notFound: _NotFoundBehavior.allowAtTail);
        if (!recursive && await type(resolvedPath) != expectedType) {
          throw expectedType == FileSystemEntityType.file
              ? common.isADirectory(path)
              : common.notADirectory(path);
        }
        await fileSystem.delegate.link(real(path)).delete();
      }
      return this as T;
    } else {
      return wrap(
          await _rawDelegate(real(path)).delete(recursive: recursive) as D);
    }
  }

  @override
  void deleteSync({bool recursive = false}) {
    String path = fileSystem._resolve(this.path,
        followLinks: false, notFound: _NotFoundBehavior.throwError);

    String real(String path) => fileSystem._real(path, resolve: false);
    FileSystemEntityType type(String path) =>
        fileSystem.delegate.typeSync(real(path), followLinks: false);

    if (type(path) == FileSystemEntityType.link) {
      if (expectedType == FileSystemEntityType.link) {
        fileSystem.delegate.link(real(path)).deleteSync();
      } else {
        String resolvedPath = fileSystem._resolve(p.basename(path),
            from: p.dirname(path), notFound: _NotFoundBehavior.allowAtTail);
        if (!recursive && type(resolvedPath) != expectedType) {
          throw expectedType == FileSystemEntityType.file
              ? common.isADirectory(path)
              : common.notADirectory(path);
        }
        fileSystem.delegate.link(real(path)).deleteSync();
      }
    } else {
      _rawDelegate(real(path)).deleteSync(recursive: recursive);
    }
  }

  @override
  Stream<FileSystemEvent> watch({
    int events = FileSystemEvent.all,
    bool recursive = false,
  }) =>
      throw UnsupportedError('watch is not supported on ChrootFileSystem');

  @override
  bool get isAbsolute => fileSystem.path.isAbsolute(path);
}
