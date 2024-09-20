// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "common_patch.dart";

@patch
class _Directory {
  @patch
  @pragma("vm:external-name", "Directory_Current")
  external static _current(_Namespace namespace);
  @patch
  @pragma("vm:external-name", "Directory_SetCurrent")
  external static _setCurrent(_Namespace namespace, Uint8List rawPath);
  @patch
  @pragma("vm:external-name", "Directory_CreateTemp")
  external static _createTemp(_Namespace namespace, Uint8List rawPath);
  @patch
  @pragma("vm:external-name", "Directory_SystemTemp")
  external static String _systemTemp(_Namespace namespace);
  @patch
  @pragma("vm:external-name", "Directory_Exists")
  external static _exists(_Namespace namespace, Uint8List rawPath);
  @patch
  @pragma("vm:external-name", "Directory_Create")
  external static _create(_Namespace namespace, Uint8List rawPath);
  @patch
  @pragma("vm:external-name", "Directory_Delete")
  external static _deleteNative(
      _Namespace namespace, Uint8List rawPath, bool recursive);
  @patch
  @pragma("vm:external-name", "Directory_Rename")
  external static _rename(
      _Namespace namespace, Uint8List rawPath, String newPath);
  @patch
  @pragma("vm:external-name", "Directory_FillWithDirectoryListing")
  external static void _fillWithDirectoryListing(
      _Namespace namespace,
      List<FileSystemEntity> list,
      Uint8List rawPath,
      bool recursive,
      bool followLinks);
}

@patch
class _AsyncDirectoryListerOps {
  @patch
  factory _AsyncDirectoryListerOps(int pointer) =>
      new _AsyncDirectoryListerOpsImpl(pointer);
}

base class _AsyncDirectoryListerOpsImpl extends NativeFieldWrapperClass1
    implements _AsyncDirectoryListerOps {
  _AsyncDirectoryListerOpsImpl._();

  factory _AsyncDirectoryListerOpsImpl(int pointer) =>
      new _AsyncDirectoryListerOpsImpl._().._setPointer(pointer);

  @pragma("vm:external-name", "Directory_SetAsyncDirectoryListerPointer")
  external void _setPointer(int pointer);

  @pragma("vm:external-name", "Directory_GetAsyncDirectoryListerPointer")
  external int getPointer();
}

// Corelib 'Uri.base' implementation.
// Uri.base is susceptible to changes in the current working directory.
Uri _uriBaseClosure() {
  var overrides = IOOverrides.current;
  if (overrides != null) {
    return overrides.getCurrentDirectory().uri;
  }
  var result = _Directory._current(_Namespace._namespace);
  if (result is OSError) {
    throw new FileSystemException._fromOSError(
        result, "Getting current working directory failed", "");
  }
  return new Uri.directory(result as String);
}

@pragma("vm:entry-point", "call")
_getUriBaseClosure() => _uriBaseClosure;
