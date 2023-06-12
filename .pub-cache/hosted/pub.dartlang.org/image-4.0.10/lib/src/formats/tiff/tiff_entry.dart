import '../../exif/exif_tag.dart';
import '../../exif/ifd_value.dart';
import '../../util/input_buffer.dart';

class TiffEntry {
  int tag;
  IfdValueType type;
  int count;
  int valueOffset;
  IfdValue? value;
  InputBuffer p;

  TiffEntry(this.tag, this.type, this.count, this.p, this.valueOffset);

  @override
  String toString() {
    final exifTag = exifImageTags[tag];
    if (exifTag != null) {
      return '${exifTag.name}: $type $count';
    }
    return '<$tag>: $type $count';
  }

  bool get isValid => type != IfdValueType.none;

  int get typeSize => isValid ? ifdValueTypeSize[type.index] : 0;

  bool get isString => type == IfdValueType.ascii;

  IfdValue? read() {
    if (value != null) {
      return value;
    }
    p.offset = valueOffset;
    final data = p.readBytes(count * typeSize);
    switch (type) {
      case IfdValueType.byte:
        return value = IfdByteValue.data(data, count);
      case IfdValueType.ascii:
        return value = IfdValueAscii.data(data, count);
      case IfdValueType.undefined:
        return value = IfdByteValue.data(data, count);
      case IfdValueType.short:
        return value = IfdValueShort.data(data, count);
      case IfdValueType.long:
        return value = IfdValueLong.data(data, count);
      case IfdValueType.rational:
        return value = IfdValueRational.data(data, count);
      case IfdValueType.single:
        return value = IfdValueSingle.data(data, count);
      case IfdValueType.double:
        return value = IfdValueDouble.data(data, count);
      case IfdValueType.sByte:
        return value = IfdValueSByte.data(data, count);
      case IfdValueType.sShort:
        return value = IfdValueSShort.data(data, count);
      case IfdValueType.sLong:
        return value = IfdValueSLong.data(data, count);
      case IfdValueType.sRational:
        return value = IfdValueSRational.data(data, count);
      case IfdValueType.none:
        return null;
    }
  }
}
