// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of vector_math_lists;

/// A list of [Vector3].
class Vector3List extends VectorList<Vector3> {
  /// Create a new vector list with [length] elements. Optionally it is possible
  /// to specify an [offset] in the [buffer] and a [stride] between each vector.
  Vector3List(int length, [int offset = 0, int stride = 0])
      : super(length, 3, offset, stride);

  /// Create a new vector list from a list of vectors. Optionally it is possible
  /// to specify an [offset] in the [buffer] and a [stride] between each vector.
  Vector3List.fromList(List<Vector3> list, [int offset = 0, int stride = 0])
      : super.fromList(list, 3, offset, stride);

  /// Create a new vector list as a view of [buffer]. Optionally it is possible
  /// to specify a [offset] in the [buffer] and a [stride] between each vector.
  Vector3List.view(Float32List buffer, [int offset = 0, int stride = 0])
      : super.view(buffer, 3, offset, stride);

  @override
  Vector3 newVector() => Vector3.zero();

  /// Retrieves the vector at [index] and stores it in [vector].
  @override
  void load(int index, Vector3 vector) {
    final i = _vectorIndexToBufferIndex(index);
    vector.storage[0] = _buffer[i + 0];
    vector.storage[1] = _buffer[i + 1];
    vector.storage[2] = _buffer[i + 2];
  }

  /// Store [vector] in the list at [index].
  @override
  void store(int index, Vector3 vector) {
    final i = _vectorIndexToBufferIndex(index);
    final storage = vector.storage;
    _buffer[i + 0] = storage[0];
    _buffer[i + 1] = storage[1];
    _buffer[i + 2] = storage[2];
  }

  /// Set the vector at [index] to zero.
  void setZero(int index) => setValues(index, 0.0, 0.0, 0.0);

  /// Set the vector at [index] to [x], [y], and [z].
  void setValues(int index, double x, double y, double z) {
    final i = _vectorIndexToBufferIndex(index);
    buffer[i + 0] = x;
    buffer[i + 1] = y;
    buffer[i + 2] = z;
  }

  /// Add [vector] to the vector at [index].
  void add(int index, Vector3 vector) {
    final i = _vectorIndexToBufferIndex(index);
    final storage = vector.storage;
    buffer[i + 0] += storage[0];
    buffer[i + 1] += storage[1];
    buffer[i + 2] += storage[2];
  }

  /// Add [vector] scaled by [factor] to the vector at [index].
  void addScaled(int index, Vector3 vector, double factor) {
    final i = _vectorIndexToBufferIndex(index);
    final storage = vector.storage;
    buffer[i + 0] += storage[0] * factor;
    buffer[i + 1] += storage[1] * factor;
    buffer[i + 2] += storage[2] * factor;
  }

  /// Substract [vector] from the vector at [index].
  void sub(int index, Vector3 vector) {
    final i = _vectorIndexToBufferIndex(index);
    final storage = vector.storage;
    buffer[i + 0] -= storage[0];
    buffer[i + 1] -= storage[1];
    buffer[i + 2] -= storage[2];
  }

  /// Multiply the vector at [index] by [vector].
  void multiply(int index, Vector3 vector) {
    final i = _vectorIndexToBufferIndex(index);
    final storage = vector.storage;
    buffer[i + 0] *= storage[0];
    buffer[i + 1] *= storage[1];
    buffer[i + 2] *= storage[2];
  }

  /// Scale the vector at [index] by [factor].
  void scale(int index, double factor) {
    final i = _vectorIndexToBufferIndex(index);
    buffer[i + 0] *= factor;
    buffer[i + 1] *= factor;
    buffer[i + 2] *= factor;
  }
}
