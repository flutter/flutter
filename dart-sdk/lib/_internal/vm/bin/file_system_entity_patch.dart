// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "common_patch.dart";

@patch
class FileStat {
  @patch
  @pragma("vm:external-name", "File_Stat")
  external static _statSync(_Namespace namespace, String path);
}

@patch
class FileSystemEntity {
  @patch
  @pragma("vm:external-name", "File_GetType")
  external static _getTypeNative(
      _Namespace namespace, Uint8List rawPath, bool followLinks);
  @patch
  @pragma("vm:external-name", "File_AreIdentical")
  external static _identicalNative(
      _Namespace namespace, String path1, String path2);
  @patch
  @pragma("vm:external-name", "File_ResolveSymbolicLinks")
  external static _resolveSymbolicLinks(_Namespace namespace, Uint8List path);
}
