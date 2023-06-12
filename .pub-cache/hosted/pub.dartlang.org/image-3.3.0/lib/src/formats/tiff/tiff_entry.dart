import '../../image_exception.dart';
import '../../util/input_buffer.dart';
import 'tiff_image.dart';

class TiffEntry {
  int tag;
  int type;
  int numValues;
  int? valueOffset;
  InputBuffer p;

  TiffEntry(this.tag, this.type, this.numValues, this.p);

  @override
  String toString() {
    if (TiffImage.TAG_NAME.containsKey(tag)) {
      return '${TiffImage.TAG_NAME[tag]}: $type $numValues';
    }
    return '<$tag>: $type $numValues';
  }

  bool get isValid => type < 13 && type > 0;

  int get typeSize => isValid ? SIZE_OF_TYPE[type] : 0;

  bool get isString => type == TYPE_ASCII;

  int readValue() {
    p.offset = valueOffset!;
    return _readValue();
  }

  List<int> readValues() {
    p.offset = valueOffset!;
    final values = <int>[];
    for (var i = 0; i < numValues; ++i) {
      values.add(_readValue());
    }
    return values;
  }

  String readString() {
    if (type != TYPE_ASCII) {
      throw ImageException('readString requires ASCII entity');
    }
    // TODO: ASCII fields can contain multiple strings, separated with a NULL.
    return String.fromCharCodes(readValues());
  }

  List read() {
    p.offset = valueOffset!;
    final values = <dynamic>[];
    for (var i = 0; i < numValues; ++i) {
      switch (type) {
        case TYPE_BYTE:
        case TYPE_ASCII:
          values.add(p.readByte());
          break;
        case TYPE_SHORT:
          values.add(p.readUint16());
          break;
        case TYPE_LONG:
          values.add(p.readUint32());
          break;
        case TYPE_RATIONAL:
          final num = p.readUint32();
          final den = p.readUint32();
          if (den != 0) {
            values.add(num / den);
          }
          break;
        case TYPE_FLOAT:
          values.add(p.readFloat32());
          break;
        case TYPE_DOUBLE:
          values.add(p.readFloat64());
          break;
      }
    }
    return values;
  }

  int _readValue() {
    switch (type) {
      case TYPE_BYTE:
      case TYPE_ASCII:
        return p.readByte();
      case TYPE_SHORT:
        return p.readUint16();
      case TYPE_LONG:
        return p.readUint32();
      case TYPE_RATIONAL:
        final num = p.readUint32();
        final den = p.readUint32();
        if (den == 0) {
          return 0;
        }
        return num ~/ den;
      case TYPE_SBYTE:
        throw ImageException('Unhandled value type: SBYTE');
      case TYPE_UNDEFINED:
        return p.readByte();
      case TYPE_SSHORT:
        throw ImageException('Unhandled value type: SSHORT');
      case TYPE_SLONG:
        throw ImageException('Unhandled value type: SLONG');
      case TYPE_SRATIONAL:
        throw ImageException('Unhandled value type: SRATIONAL');
      case TYPE_FLOAT:
        throw ImageException('Unhandled value type: FLOAT');
      case TYPE_DOUBLE:
        throw ImageException('Unhandled value type: DOUBLE');
    }
    return 0;
  }

  static const TYPE_BYTE = 1;
  static const TYPE_ASCII = 2;
  static const TYPE_SHORT = 3;
  static const TYPE_LONG = 4;
  static const TYPE_RATIONAL = 5;
  static const TYPE_SBYTE = 6;
  static const TYPE_UNDEFINED = 7;
  static const TYPE_SSHORT = 8;
  static const TYPE_SLONG = 9;
  static const TYPE_SRATIONAL = 10;
  static const TYPE_FLOAT = 11;
  static const TYPE_DOUBLE = 12;

  static const List<int> SIZE_OF_TYPE = [
    0, //  0 = n/a
    1, //  1 = byte
    1, //  2 = ascii
    2, //  3 = short
    4, //  4 = long
    8, //  5 = rational
    1, //  6 = sbyte
    1, //  7 = undefined
    2, //  8 = sshort
    4, //  9 = slong
    8, // 10 = srational
    4, // 11 = float
    8, // 12 = double
    0
  ];
}
