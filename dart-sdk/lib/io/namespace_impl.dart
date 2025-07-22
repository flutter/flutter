// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

// Each Isolate may run in a different "namespace", which provides the scope in
// which file paths are resolved.
abstract class _Namespace {
  // This getter does not increase the reference count on the underlying native
  // object. It cannot be passed in a dispatch message to the IOService thread.
  external static _Namespace get _namespace;

  // This getter does increase the reference count on the underlying native
  // object. It must be passed in a dispatch message to the IOService thread.
  external static int get _namespacePointer;

  // This sets up the Isolate's namespace. It should be set up by the embedder.
  // If it is not set up by the embedder, relative paths will be resolved
  // relative to the process's current working directory and absolute paths will
  // be left relative to the file system root.
  @pragma("vm:entry-point")
  external static void _setupNamespace(var namespace);
}
