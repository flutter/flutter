import 'dart:convert';
import 'dart:typed_data';

import '../util/rational.dart';
import 'exif_tag.dart';
import 'ifd_container.dart';
import 'ifd_value.dart';

/// An EXIF IfdDirectory stores a collection of IFD tags and values.
class IfdDirectory {
  final data = <int, IfdValue>{};
  final sub = IfdContainer();

  IfdDirectory();

  IfdDirectory.from(IfdDirectory other) {
    copy(other);
  }

  Iterable<int> get keys => data.keys;

  Iterable<IfdValue> get values => data.values;

  bool get isEmpty => data.isEmpty && sub.isEmpty;

  IfdDirectory clone() => IfdDirectory.from(this);

  void copy(IfdDirectory other) {
    other.data.forEach((tag, value) => data[tag] = value.clone());
    other.sub.directories
        .forEach((tag, value) => sub.directories[tag] = value.clone());
  }

  /// The size in bytes of the data written by this directory. Can be used to
  /// calculate end-of-block offsets.
  int getDataSize() {
    final numEntries = values.length;
    var dataOffset = 2 + (12 * numEntries) + 4;
    for (var value in values) {
      final dataSize = value.dataSize;
      if (dataSize > 4) {
        dataOffset += dataSize;
      }
    }
    // storage for sub-ifd blocks
    for (var subName in sub.keys) {
      final subIfd = sub[subName];
      var subSize = 2 + (12 * subIfd.values.length);
      for (var value in subIfd.values) {
        final dataSize = value.dataSize;
        if (dataSize > 4) {
          subSize += dataSize;
        }
      }
      dataOffset += subSize;
    }
    return dataOffset;
  }

  bool containsKey(int tag) => data.containsKey(tag);

  IfdValue? operator [](Object? tag) {
    if (tag is String) {
      tag = exifTagNameToID[tag];
    }
    if (tag is int) {
      return data[tag];
    }
    return null;
  }

  void operator []=(Object? tag, Object? value) {
    if (tag is String) {
      tag = exifTagNameToID[tag];
    }
    if (tag is! int) {
      return;
    }

    if (value == null) {
      data.remove(tag);
    } else {
      if (value is IfdValue) {
        data[tag] = value;
      } else {
        final tagInfo = exifImageTags[tag];
        if (tagInfo != null) {
          final tagType = tagInfo.type;
          //final tagCount = tagInfo.count;
          switch (tagType) {
            case IfdValueType.byte:
              if (value is List<int>) {
                data[tag] = IfdByteValue.list(Uint8List.fromList(value));
              } else if (value is int) {
                data[tag] = IfdByteValue(value);
              }
              break;
            case IfdValueType.ascii:
              if (value is String) {
                data[tag] = IfdValueAscii(value);
              }
              break;
            case IfdValueType.short:
              if (value is List<int>) {
                data[tag] = IfdValueShort.list(Uint16List.fromList(value));
              } else if (value is int) {
                data[tag] = IfdValueShort(value);
              }
              break;
            case IfdValueType.long:
              if (value is List<int>) {
                data[tag] = IfdValueLong.list(Uint32List.fromList(value));
              } else if (value is int) {
                data[tag] = IfdValueLong(value);
              }
              break;
            case IfdValueType.rational:
              if (value is List<Rational>) {
                data[tag] = IfdValueRational.list(value);
              } else if (value is List<int> && value.length == 2) {
                data[tag] = IfdValueRational(value[0], value[1]);
              } else if (value is Rational) {
                data[tag] = IfdValueRational.from(value);
              } else if (value is List<List<int>>) {
                data[tag] = IfdValueRational.list(List<Rational>.generate(
                    value.length,
                    (index) => Rational(value[index][0], value[index][1])));
              }
              break;
            case IfdValueType.sByte:
              if (value is List<int>) {
                data[tag] = IfdValueSByte.list(Int8List.fromList(value));
              } else if (value is int) {
                data[tag] = IfdValueSByte(value);
              }
              break;
            case IfdValueType.undefined:
              if (value is List<int>) {
                data[tag] = IfdValueUndefined.list(Uint8List.fromList(value));
              }
              break;
            case IfdValueType.sShort:
              if (value is List<int>) {
                data[tag] = IfdValueSShort.list(Int16List.fromList(value));
              } else if (value is int) {
                data[tag] = IfdValueSShort(value);
              }
              break;
            case IfdValueType.sLong:
              if (value is List<int>) {
                data[tag] = IfdValueSLong.list(Int32List.fromList(value));
              } else if (value is int) {
                data[tag] = IfdValueSLong(value);
              }
              break;
            case IfdValueType.sRational:
              if (value is List<Rational>) {
                data[tag] = IfdValueSRational.list(value);
              } else if (value is List<int> && value.length == 2) {
                data[tag] = IfdValueSRational(value[0], value[1]);
              } else if (value is Rational) {
                data[tag] = IfdValueSRational.from(value);
              } else if (value is List<List<int>>) {
                data[tag] = IfdValueSRational.list(List<Rational>.generate(
                    value.length,
                    (index) => Rational(value[index][0], value[index][1])));
              }
              break;
            case IfdValueType.single:
              if (value is List<double>) {
                data[tag] = IfdValueSingle.list(Float32List.fromList(value));
              } else if (value is double) {
                data[tag] = IfdValueSingle(value);
              } else if (value is int) {
                data[tag] = IfdValueSingle(value.toDouble());
              }
              break;
            case IfdValueType.double:
              if (value is List<double>) {
                data[tag] = IfdValueDouble.list(Float64List.fromList(value));
              } else if (value is double) {
                data[tag] = IfdValueDouble(value);
              } else if (value is int) {
                data[tag] = IfdValueDouble(value.toDouble());
              }
              break;
            case IfdValueType.none:
              break;
          }
        }
      }
    }
  }

  bool get hasUserComment => data.containsKey(0x9286);
  String? get userComment =>
      utf8.decode(data[0x9286]?.toData() ?? [], allowMalformed: true);
  set userComment(String? value) {
    if (value == null) {
      data.remove(0x9286);
    } else {
      data[0x9286] = IfdValueUndefined.list(value.codeUnits);
    }
  }

  bool get hasImageDescription => data.containsKey(0x010e);
  String? get imageDescription => data[0x010e]?.toString();
  set imageDescription(String? value) {
    if (value == null) {
      data.remove(0x010e);
    } else {
      data[0x010e] = IfdValueAscii(value);
    }
  }

  bool get hasMake => data.containsKey(0x010f);
  String? get make => data[0x010f]?.toString();
  set make(String? value) {
    if (value == null) {
      data.remove(0x010f);
    } else {
      data[0x010f] = IfdValueAscii(value);
    }
  }

  bool get hasModel => data.containsKey(0x0110);
  String? get model => data[0x0110]?.toString();
  set model(String? value) {
    if (value == null) {
      data.remove(0x0110);
    } else {
      data[0x0110] = IfdValueAscii(value);
    }
  }

  bool get hasOrientation => data.containsKey(0x0112);
  int? get orientation => data[0x0112]?.toInt();
  set orientation(int? value) {
    if (value == null) {
      data.remove(0x0112);
    } else {
      data[0x0112] = IfdValueShort(value);
    }
  }

  bool _setRational(int tag, Object? value) {
    if (value is Rational) {
      data[tag] = IfdValueRational.from(value);
      return true;
    } else if (value is List<int>) {
      if (value.length == 2) {
        data[tag] = IfdValueRational.from(Rational(value[0], value[1]));
        return true;
      }
    }
    return false;
  }

  bool get hasXResolution => data.containsKey(0x011a);
  Rational? get xResolution => data[0x011a]?.toRational();
  set xResolution(Object? value) {
    if (!_setRational(0x011a, value)) {
      data.remove(0x011a);
    }
  }

  bool get hasYResolution => data.containsKey(0x011b);
  Rational? get yResolution => data[0x011b]?.toRational();
  set yResolution(Object? value) {
    if (!_setRational(0x011b, value)) {
      data.remove(0x011b);
    }
  }

  bool get hasResolutionUnit => data.containsKey(0x0128);
  int? get resolutionUnit => data[0x0128]?.toInt();
  set resolutionUnit(int? value) {
    if (value == null) {
      data.remove(0x0128);
    } else {
      data[0x0128] = IfdValueShort(value);
    }
  }

  bool get hasImageWidth => data.containsKey(0x0100);
  int? get imageWidth => data[0x0100]?.toInt();
  set imageWidth(int? value) {
    if (value == null) {
      data.remove(0x0100);
    } else {
      data[0x0100] = IfdValueShort(value);
    }
  }

  bool get hasImageHeight => data.containsKey(0x0101);
  int? get imageHeight => data[0x0101]?.toInt();
  set imageHeight(int? value) {
    if (value == null) {
      data.remove(0x0101);
    } else {
      data[0x0101] = IfdValueShort(value);
    }
  }

  bool get hasSoftware => data.containsKey(0x0131);
  String? get software => data[0x0131]?.toString();
  set software(String? value) {
    if (value == null) {
      data.remove(0x0131);
    } else {
      data[0x0131] = IfdValueAscii(value);
    }
  }

  bool get hasCopyright => data.containsKey(0x8298);
  String? get copyright => data[0x8298]?.toString();
  set copyright(String? value) {
    if (value == null) {
      data.remove(0x8298);
    } else {
      data[0x8298] = IfdValueAscii(value);
    }
  }
}
