// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A pair of values. Used for testing custom codecs.
class Pair<L, R> {
  final L left;
  final R right;

  Pair(this.left, this.right);

  @override
  String toString() => 'Pair[$left, $right]';
}
