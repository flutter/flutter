// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of vector_math_lists;

/// Defines a view of scalar values over a [Float32List] that allows for a
/// custom offset and stride.
class ScalarListView {
  final int _offset;
  final int _stride;
  final int _length;
  final Float32List _buffer;

  /// The count of vectors in this list.
  int get length => _length;

  /// The internal storage buffer of this list.
  Float32List get buffer => _buffer;

  static int _listLength(int offset, int stride, int length) {
    final width = stride == 0 ? 1 : stride;
    return offset + width * length;
  }

  /// Create a new vector list with [length] elements.
  ///
  /// Optionally it is possible to specify an [offset] in the
  /// [buffer] and a [stride] between each vector.
  ScalarListView(int length, [int offset = 0, int stride = 0])
      : _offset = offset,
        _stride = stride == 0 ? 1 : stride,
        _length = length,
        _buffer = Float32List(_listLength(offset, stride, length));

  /// Create a new vector list from a list of vectors.
  ///
  /// Optionally it is possible to specify an [offset] in the
  /// [buffer] and a [stride] between each vector.
  ScalarListView.fromList(List<double> list, [int offset = 0, int stride = 0])
      : _offset = offset,
        _stride = stride == 0 ? 1 : stride,
        _length = list.length,
        _buffer =
            Float32List(offset + list.length * (stride == 0 ? 1 : stride)) {
    for (var i = 0; i < _length; i++) {
      this[i] = list[i];
    }
  }

  /// Create a new stride list as a view of [buffer]. Optionally it is possible
  /// to specify a [offset] in the [buffer] and a [stride] between each vector.
  ScalarListView.view(Float32List buffer, [int offset = 0, int stride = 0])
      : _offset = offset,
        _stride = stride == 0 ? 1 : stride,
        _length = (buffer.length - math.max(0, offset - stride)) ~/
            (stride == 0 ? 1 : stride),
        _buffer = buffer;

  int _elementIndexToBufferIndex(int index) => _offset + _stride * index;

  /// Retrieves the value at [index].
  double operator [](int index) => load(index);

  /// Store [value] in the list at [index].
  void operator []=(int index, double value) {
    store(index, value);
  }

  /// Store [value] in the list at [index].
  void store(int index, double value) {
    final i = _elementIndexToBufferIndex(index);
    _buffer[i] = value;
  }

  /// Retrieves the value at [index].
  double load(int index) => _buffer[_elementIndexToBufferIndex(index)];
}
