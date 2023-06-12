import 'dart:typed_data';

import 'half.dart';
import 'hdr_image.dart';

/// A slice is the data for an image framebuffer for a single channel.
class HdrSlice {
  final String? name;
  final int width;
  final int height;

  /// Indicates the type of data stored by the slice, either [HdrImage.INT],
  /// [HdrImage.FLOAT], or [HdrImage.UINT].
  final int type;

  /// How many bits per sample, either 8, 16, 32, or 64.
  final int bitsPerSample;

  /// [data] will be one of the type data lists, depending on the [type] and
  /// [bitsPerSample]. 16-bit FLOAT slices will be stored in a [Uint16List].
  final List data;

  static List allocateDataForType(int size, int type, int bitsPerSample) {
    switch (type) {
      case HdrImage.INT:
        if (bitsPerSample == 8) {
          return Int8List(size);
        } else if (bitsPerSample == 16) {
          return Int16List(size);
        } else if (bitsPerSample == 32) {
          return Int32List(size);
        }
        break;
      case HdrImage.UINT:
        if (bitsPerSample == 8) {
          return Uint8List(size);
        } else if (bitsPerSample == 16) {
          return Uint16List(size);
        } else if (bitsPerSample == 32) {
          return Uint32List(size);
        }
        break;
      case HdrImage.FLOAT:
        if (bitsPerSample == 16) {
          return Uint16List(size);
        } else if (bitsPerSample == 32) {
          return Float32List(size);
        } else if (bitsPerSample == 64) {
          return Float64List(size);
        }
        break;
    }
    throw UnimplementedError();
  }

  HdrSlice(this.name, this.width, this.height, this.type, this.bitsPerSample)
      : data = allocateDataForType(width * height, type, bitsPerSample);

  /// Create a copy of the [other] HdrSlice.
  HdrSlice.from(HdrSlice other)
      : name = other.name,
        width = other.width,
        height = other.height,
        type = other.type,
        bitsPerSample = other.bitsPerSample,
        data = other.data.sublist(0);

  /// Get the raw bytes of the data buffer.
  Uint8List getBytes() => Uint8List.view((data as TypedData).buffer);

  /// Does this channel store floating-point data?
  bool get isFloat => type == HdrImage.FLOAT;

  int get _maxIntSize {
    var v = (bitsPerSample == 8
        ? 0xff
        : bitsPerSample == 16
            ? 0xffff
            : 0xffffffff);
    if (type == HdrImage.INT) {
      v -= 1;
    }
    return v;
  }

  /// Get the float value of the sample at the coordinates [x],[y].
  /// [Half] samples are converted to double.
  double getFloat(int x, int y) {
    final pi = y * width + x;
    if (type == HdrImage.INT || type == HdrImage.UINT) {
      return (data[pi] as int) / _maxIntSize;
    }
    final s = (type == HdrImage.FLOAT && bitsPerSample == 16)
        ? Half.HalfToDouble(data[pi] as int)
        : data[pi] as double;
    return s;
  }

  /// Set the float value of the sample at the coordinates [x],[y] for
  ///[FLOAT] slices.
  void setFloat(int x, int y, num v) {
    if (type != HdrImage.FLOAT) {
      return;
    }
    final pi = y * width + x;
    if (bitsPerSample == 16) {
      data[pi] = Half.DoubleToHalf(v);
    } else {
      data[pi] = v;
    }
  }

  /// Get the int value of the sample at the coordinates [x],[y].
  ///An exception will occur if the slice stores FLOAT data.
  int getInt(int x, int y) {
    final pi = y * width + x;
    return data[pi] as int;
  }

  /// Set the int value of the sample at the coordinates [x],[y] for [INT] and
  /// [UINT] slices.
  void setInt(int x, int y, int v) {
    final pi = y * width + x;
    data[pi] = v;
  }
}
