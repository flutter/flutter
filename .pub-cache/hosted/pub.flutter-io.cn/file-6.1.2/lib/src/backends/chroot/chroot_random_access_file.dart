// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.backends.chroot;

class _ChrootRandomAccessFile with ForwardingRandomAccessFile {
  _ChrootRandomAccessFile(this.path, this.delegate);

  @override
  final io.RandomAccessFile delegate;

  @override
  final String path;
}
