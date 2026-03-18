// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';

import 'package:ui/src/engine/native_memory.dart';

abstract class SkwasmObjectWrapper<T extends NativeType> {
  SkwasmObjectWrapper(this.handle, void Function(Pointer<T>) dispose) {
    _ref = UniqueRef<Pointer<T>>(this, handle, 'SkwasmObject', onDispose: dispose);
  }

  late final UniqueRef<Pointer<T>> _ref;
  final Pointer<T> handle;

  void dispose() {
    _ref.dispose();
  }

  bool get debugDisposed => _ref.isDisposed;
}
