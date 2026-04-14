// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import '../native_memory.dart';
import 'canvaskit_api.dart';

export '../native_memory.dart' show StackTraceDebugger;

/// Manages the lifecycle of a C++ object referenced by a single Dart object.
class CkUniqueRef<T extends JSObject> extends UniqueRef<T> {
  CkUniqueRef(super.owner, super.nativeObject, super.debugOwnerLabel)
    : super(
        onDispose: (T obj) {
          final deletable = obj as SkDeletable;
          if (!deletable.isDeleted()) {
            deletable.delete();
          }
        },
      );
}

/// Manages the lifecycle of a C++ object referenced by multiple Dart objects.
class CkCountedRef<R extends StackTraceDebugger, T extends JSObject> extends CountedRef<R, T> {
  CkCountedRef(super.nativeObject, super.debugReferrer, super.debugLabel, {super.onDisposed})
    : super(
        onDispose: (T obj) {
          final deletable = obj as SkDeletable;
          if (!deletable.isDeleted()) {
            deletable.delete();
          }
        },
      );
}
