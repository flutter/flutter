// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/// A library containing matrix operations ([Matrix44Operations]) that can be
/// performed on [Float32List] instances and SIMD optimized operations
/// ([Matrix44SIMDOperations]) that can be performed on [Float32x4List]
/// instances.
library vector_math_operations;

import 'dart:typed_data';

part 'src/vector_math_operations/vector.dart';
part 'src/vector_math_operations/matrix.dart';
