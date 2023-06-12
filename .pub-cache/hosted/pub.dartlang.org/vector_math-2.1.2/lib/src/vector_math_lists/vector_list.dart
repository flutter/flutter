// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of vector_math_lists;

/// Abstract base class for vector lists. See [Vector2List], [Vector3List], and
/// [Vector4List] for implementations of this class.
abstract class VectorList<T extends Vector> {
  final int _vectorLength;
  final int _offset;
  final int _stride;
  final int _length;
  final Float32List _buffer;

  /// The count of vectors in this list.
  int get length => _length;

  /// The internal storage buffer of this list.
  Float32List get buffer => _buffer;

  static int _listLength(int offset, int stride, int vectorLength, int length) {
    final width = stride == 0 ? vectorLength : stride;
    return offset + width * length;
  }

  /// Create a new vector list with [length] elements that have a size of
  /// [vectorLength]. Optionally it is possible to specify an [offset] in the
  /// [buffer] and a [stride] between each vector.
  VectorList(int length, int vectorLength, [int offset = 0, int stride = 0])
      : _vectorLength = vectorLength,
        _offset = offset,
        _stride = stride == 0 ? vectorLength : stride,
        _length = length,
        _buffer = Float32List(
            VectorList._listLength(offset, stride, vectorLength, length)) {
    if (_stride < _vectorLength) {
      throw ArgumentError('Stride cannot be smaller than the vector size.');
    }
  }

  /// Create a new vector list from a list of vectors that have a size of
  /// [vectorLength]. Optionally it is possible to specify an [offset] in the
  /// [buffer] and a [stride] between each vector.
  VectorList.fromList(List<T> list, int vectorLength,
      [int offset = 0, int stride = 0])
      : _vectorLength = vectorLength,
        _offset = offset,
        _stride = stride == 0 ? vectorLength : stride,
        _length = list.length,
        _buffer = Float32List(
            offset + list.length * (stride == 0 ? vectorLength : stride)) {
    if (_stride < _vectorLength) {
      throw ArgumentError('Stride cannot be smaller than the vector size.');
    }
    for (var i = 0; i < _length; i++) {
      store(i, list[i]);
    }
  }

  /// Create a new vector list as a view of [buffer] for vectors that have a
  /// size of [vectorLength]. Optionally it is possible to specify an [offset]
  /// in the [buffer] and a [stride] between each vector.
  VectorList.view(Float32List buffer, int vectorLength,
      [int offset = 0, int stride = 0])
      : _vectorLength = vectorLength,
        _offset = offset,
        _stride = stride == 0 ? vectorLength : stride,
        _length = (buffer.length - math.max(0, offset - stride)) ~/
            (stride == 0 ? vectorLength : stride),
        _buffer = buffer {
    if (_stride < _vectorLength) {
      throw ArgumentError('Stride cannot be smaller than the vector size.');
    }
  }

  int _vectorIndexToBufferIndex(int index) => _offset + _stride * index;

  /// Create a new instance of [T].
  T newVector();

  /// Retrieves the vector at [index] and stores it in [vector].
  void load(int index, T vector);

  /// Store [vector] in the list at [index].
  void store(int index, T vector);

  /// Copy a range of [count] vectors beginning at [srcOffset] from [src] into
  /// this list starting at [offset].
  void copy(VectorList<T> src,
      {int srcOffset = 0, int offset = 0, int count = 0}) {
    if (count == 0) {
      count = math.min(length - offset, src.length - srcOffset);
    }
    final minVectorLength = math.min(_vectorLength, src._vectorLength);
    for (var i = 0; i < count; i++) {
      var index = _vectorIndexToBufferIndex(i + offset);
      var srcIndex = src._vectorIndexToBufferIndex(i + srcOffset);
      for (var j = 0; j < minVectorLength; j++) {
        _buffer[index++] = src._buffer[srcIndex++];
      }
    }
  }

  /// Retrieves the vector at [index].
  T operator [](int index) {
    final r = newVector();
    load(index, r);
    return r;
  }

  /// Store [v] in the list at [index].
  void operator []=(int index, T v) {
    store(index, v);
  }
}
