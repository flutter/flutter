// Copyright (c) 2017, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of '../iterable.dart';

/// [Iterable] that is either a [BuiltList] or a [BuiltSet].
abstract class BuiltIterable<E> implements Iterable<E> {
  /// Converts to a [BuiltList].
  BuiltList<E> toBuiltList();

  /// Converts to a [BuiltSet].
  BuiltSet<E> toBuiltSet();
}
