// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

/// Function for creating instances of [PaintingContext].
///
/// Used by [TestWidgetsFlutterBinding.createPaintingContext]
typedef PaintingContextFactory = PaintingContext Function({
  ContainerLayer layer,
  Rect paintBounds,
});

/// A function that will be used to create fresh [PaintingContext]s into
/// which [RenderObject]s may paint.
///
/// This allows tests a hook into the creation of [PaintingContext]s, thus
/// allowing them to inspect painting operations that are issued during their
/// tests.
///
/// Tests that set this value are required to unset it by the end of their test
/// so as to not interfere with other tests. Failure to do so will cause the
/// test to fail.
PaintingContextFactory createPaintingContext;
