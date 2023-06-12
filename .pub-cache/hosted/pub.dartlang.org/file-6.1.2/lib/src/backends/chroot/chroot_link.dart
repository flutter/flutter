// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.backends.chroot;

class _ChrootLink extends _ChrootFileSystemEntity<Link, io.Link>
    with ForwardingLink {
  _ChrootLink(ChrootFileSystem fs, String path) : super(fs, path);

  factory _ChrootLink.wrapped(
    ChrootFileSystem fs,
    io.Link delegate, {
    bool relative = false,
  }) {
    String localPath = fs._local(delegate.path, relative: relative);
    return _ChrootLink(fs, localPath);
  }

  @override
  Future<bool> exists() => delegate.exists();

  @override
  bool existsSync() => delegate.existsSync();

  @override
  Future<Link> rename(String newPath) async {
    return wrap(await delegate.rename(fileSystem._real(newPath)));
  }

  @override
  Link renameSync(String newPath) {
    return wrap(delegate.renameSync(fileSystem._real(newPath)));
  }

  @override
  FileSystemEntityType get expectedType => FileSystemEntityType.link;

  @override
  io.Link _rawDelegate(String path) => fileSystem.delegate.link(path);

  @override
  Link get absolute => _ChrootLink(fileSystem, _absolutePath);

  @override
  String toString() => "ChrootLink: '$path'";
}
