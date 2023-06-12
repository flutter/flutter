// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.backends.chroot;

class _ChrootDirectory extends _ChrootFileSystemEntity<Directory, io.Directory>
    with ForwardingDirectory<Directory>, common.DirectoryAddOnsMixin {
  _ChrootDirectory(ChrootFileSystem fs, String path) : super(fs, path);

  factory _ChrootDirectory.wrapped(
    ChrootFileSystem fs,
    Directory delegate, {
    bool relative = false,
  }) {
    String localPath = fs._local(delegate.path, relative: relative);
    return _ChrootDirectory(fs, localPath);
  }

  @override
  FileSystemEntityType get expectedType => FileSystemEntityType.directory;

  @override
  io.Directory _rawDelegate(String path) => fileSystem.delegate.directory(path);

  @override
  Uri get uri => Uri.directory(path);

  @override
  Future<Directory> rename(String newPath) async {
    if (_isLink) {
      if (await fileSystem.type(path) != expectedType) {
        throw common.notADirectory(path);
      }
      FileSystemEntityType type = await fileSystem.type(newPath);
      if (type != FileSystemEntityType.notFound) {
        if (type != expectedType) {
          throw common.notADirectory(newPath);
        }
        if (!(await fileSystem
            .directory(newPath)
            .list(followLinks: false)
            .isEmpty)) {
          throw common.directoryNotEmpty(newPath);
        }
      }
      String target = await fileSystem.link(path).target();
      await fileSystem.link(path).delete();
      await fileSystem.link(newPath).create(target);
      return fileSystem.directory(newPath);
    } else {
      return wrap(await getDelegate(followLinks: true)
          .rename(fileSystem._real(newPath)));
    }
  }

  @override
  Directory renameSync(String newPath) {
    if (_isLink) {
      if (fileSystem.typeSync(path) != expectedType) {
        throw common.notADirectory(path);
      }
      FileSystemEntityType type = fileSystem.typeSync(newPath);
      if (type != FileSystemEntityType.notFound) {
        if (type != expectedType) {
          throw common.notADirectory(newPath);
        }
        if (fileSystem
            .directory(newPath)
            .listSync(followLinks: false)
            .isNotEmpty) {
          throw common.directoryNotEmpty(newPath);
        }
      }
      String target = fileSystem.link(path).targetSync();
      fileSystem.link(path).deleteSync();
      fileSystem.link(newPath).createSync(target);
      return fileSystem.directory(newPath);
    } else {
      return wrap(
          getDelegate(followLinks: true).renameSync(fileSystem._real(newPath)));
    }
  }

  @override
  Directory get absolute => _ChrootDirectory(fileSystem, _absolutePath);

  @override
  Directory get parent {
    try {
      return wrapDirectory(delegate.parent);
    } on _ChrootJailException {
      return this;
    }
  }

  @override
  Future<Directory> create({bool recursive = false}) async {
    if (_isLink) {
      switch (await fileSystem.type(path)) {
        case FileSystemEntityType.notFound:
          throw common.noSuchFileOrDirectory(path);
        case FileSystemEntityType.file:
          throw common.fileExists(path);
        case FileSystemEntityType.directory:
          // Nothing to do.
          return this;
        default:
          throw AssertionError();
      }
    } else {
      return wrap(await delegate.create(recursive: recursive));
    }
  }

  @override
  void createSync({bool recursive = false}) {
    if (_isLink) {
      switch (fileSystem.typeSync(path)) {
        case FileSystemEntityType.notFound:
          throw common.noSuchFileOrDirectory(path);
        case FileSystemEntityType.file:
          throw common.fileExists(path);
        case FileSystemEntityType.directory:
          // Nothing to do.
          return;
        default:
          throw AssertionError();
      }
    } else {
      delegate.createSync(recursive: recursive);
    }
  }

  @override
  Stream<FileSystemEntity> list({
    bool recursive = false,
    bool followLinks = true,
  }) {
    Directory delegate = this.delegate as Directory;
    String dirname = delegate.path;
    return delegate
        .list(recursive: recursive, followLinks: followLinks)
        .map((io.FileSystemEntity entity) => _denormalize(entity, dirname));
  }

  @override
  List<FileSystemEntity> listSync({
    bool recursive = false,
    bool followLinks = true,
  }) {
    Directory delegate = this.delegate as Directory;
    String dirname = delegate.path;
    return delegate
        .listSync(recursive: recursive, followLinks: followLinks)
        .map((io.FileSystemEntity entity) => _denormalize(entity, dirname))
        .toList();
  }

  FileSystemEntity _denormalize(io.FileSystemEntity entity, String dirname) {
    p.Context ctx = fileSystem.path;
    String relativePart = ctx.relative(entity.path, from: dirname);
    String entityPath = ctx.join(path, relativePart);
    if (entity is io.File) {
      return _ChrootFile(fileSystem, entityPath);
    } else if (entity is io.Directory) {
      return _ChrootDirectory(fileSystem, entityPath);
    } else if (entity is io.Link) {
      return _ChrootLink(fileSystem, entityPath);
    }
    throw FileSystemException('Unsupported type: $entity', entity.path);
  }

  @override
  String toString() => "ChrootDirectory: '$path'";
}
