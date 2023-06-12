import 'dart:typed_data';

import '../util/input_buffer.dart';
import '../util/output_buffer.dart';
import 'exif_tag.dart';
import 'exif_value.dart';

class ExifIFDContainer {
  Map<String, ExifIFD> directories;

  ExifIFDContainer()
    : directories = {};

  ExifIFDContainer.from(ExifIFDContainer? other)
    : directories = other == null ? {} : Map<String, ExifIFD>.from(other.directories);

  Iterable<String> get keys => directories.keys;
  Iterable<ExifIFD> get values => directories.values;

  bool get isEmpty {
    if (directories.isEmpty) {
      return true;
    }
    for (var ifd in directories.values) {
      if (!ifd.isEmpty) {
        return false;
      }
    }
    return true;
  }

  bool containsKey(String key) => directories.containsKey(key);

  void clear() {
    directories.clear();
  }

  ExifIFD operator[](String ifdName) {
    if (!directories.containsKey(ifdName))
      directories[ifdName] = ExifIFD();
    return directories[ifdName]!;
  }

  void operator[]=(String ifdName, ExifIFD value) {
    directories[ifdName] = value;
  }
}

class ExifIFD {
  final data = Map<int, ExifValue>();
  final sub = ExifIFDContainer();

  Iterable<int> get keys => data.keys;
  Iterable<ExifValue> get values => data.values;

  bool get isEmpty => data.isEmpty && sub.isEmpty;

  bool containsKey(int tag) => data.containsKey(tag);

  ExifValue? operator[](Object? tag) {
    if (tag is String) {
      tag = ExifTagNameToID[tag];
    }
    if (tag is int) {
      return data[tag];
    }
    return null;
  }

  void operator[]=(Object? tag, Object? value) {
    if (tag is String) {
      tag = ExifTagNameToID[tag];
    }
    if (tag is! int) {
      return;
    }

    if (value == null) {
      data.remove(tag);
    } else {
      if (value is ExifValue) {
        data[tag] = value;
      } else {
        final tagInfo = ExifImageTags[tag];
        if (tagInfo != null) {
          final tagType = tagInfo.type;
          final tagCount = tagInfo.count;
          switch (tagType) {
            case ExifValueType.Byte:
              if (value is List<int> && value.length == tagCount) {
                data[tag] = ExifByteValue.list(Uint8List.fromList(value));
              } else if (value is int && tagCount == 1) {
                data[tag] = ExifByteValue(value);
              }
              break;
            case ExifValueType.Ascii:
              if (value is String) {
                data[tag] = ExifAsciiValue(value);
              }
              break;
            case ExifValueType.Short:
              if (value is List<int> && value.length == tagCount) {
                data[tag] = ExifShortValue.list(Uint16List.fromList(value));
              } else if (value is int && tagCount == 1) {
                data[tag] = ExifShortValue(value);
              }
              break;
            case ExifValueType.Long:
              if (value is List<int> && value.length == tagCount) {
                data[tag] = ExifLongValue.list(Uint32List.fromList(value));
              } else if (value is int && tagCount == 1) {
                data[tag] = ExifLongValue(value);
              }
              break;
            case ExifValueType.Rational:
              if (value is List<Rational> && value.length == tagCount) {
                data[tag] = ExifRationalValue.list(value);
              } else if (tagCount == 1 && value is List<int> &&
                  value.length == 2) {
                data[tag] = ExifRationalValue(value[0], value[1]);
              } else if (tagCount == 1 && value is Rational) {
                data[tag] = ExifRationalValue.from(value);
              } else if (value is List<List<int>> && value.length == tagCount) {
                data[tag] = ExifRationalValue.list(
                    List<Rational>.generate(value.length,
                        (index) => Rational(value[index][0], value[index][1])));
              }
              break;
            case ExifValueType.SByte:
              if (value is List<int> && value.length == tagCount) {
                data[tag] = ExifSByteValue.list(Int8List.fromList(value));
              } else if (value is int && tagCount == 1) {
                data[tag] = ExifSByteValue(value);
              }
              break;
            case ExifValueType.Undefined:
              if (value is List<int>) {
                data[tag] = ExifUndefinedValue.list(Uint8List.fromList(value));
              }
              break;
            case ExifValueType.SShort:
              if (value is List<int> && value.length == tagCount) {
                data[tag] = ExifSShortValue.list(Int16List.fromList(value));
              } else if (value is int && tagCount == 1) {
                data[tag] = ExifSShortValue(value);
              }
              break;
            case ExifValueType.SLong:
              if (value is List<int> && value.length == tagCount) {
                data[tag] = ExifSLongValue.list(Int32List.fromList(value));
              } else if (value is int && tagCount == 1) {
                data[tag] = ExifSLongValue(value);
              }
              break;
            case ExifValueType.SRational:
              if (value is List<Rational> && value.length == tagCount) {
                data[tag] = ExifSRationalValue.list(value);
              } else if (tagCount == 1 && value is List<int> &&
                  value.length == 2) {
                data[tag] = ExifSRationalValue(value[0], value[1]);
              } else if (tagCount == 1 && value is Rational) {
                data[tag] = ExifSRationalValue.from(value);
              } else if (value is List<List<int>> && value.length == tagCount) {
                data[tag] = ExifSRationalValue.list(
                  List<Rational>.generate(value.length,
                        (index) => Rational(value[index][0], value[index][1])));
              }
              break;
            case ExifValueType.Single:
              if (value is List<double> && value.length == tagCount) {
                data[tag] = ExifSingleValue.list(Float32List.fromList(value));
              } else if (value is double && tagCount == 1) {
                data[tag] = ExifSingleValue(value);
              } else if (value is int && tagCount == 1) {
                data[tag] = ExifSingleValue(value.toDouble());
              }
              break;
            case ExifValueType.Double:
              if (value is List<double> && value.length == tagCount) {
                data[tag] = ExifDoubleValue.list(Float64List.fromList(value));
              } else if (value is double && tagCount == 1) {
                data[tag] = ExifDoubleValue(value);
              } else if (value is int && tagCount == 1) {
                data[tag] = ExifDoubleValue(value.toDouble());
              }
              break;
            case ExifValueType.None:
              break;
          }
        }
      }
    }
  }

  bool get hasImageDescription => data.containsKey(0x010e);
  String? get ImageDescription => data[0x010e]?.toString();
  set ImageDescription(String? value) {
    if (value == null) {
      data.remove(0x010e);
    } else {
      data[0x010e] = ExifAsciiValue(value);
    }
  }

  bool get hasMake => data.containsKey(0x010f);
  String? get Make => data[0x010f]?.toString();
  set Make(String? value) {
    if (value == null) {
      data.remove(0x010f);
    } else {
      data[0x010f] = ExifAsciiValue(value);
    }
  }

  bool get hasModel => data.containsKey(0x0110);
  String? get Model => data[0x0110]?.toString();
  set Model(String? value) {
    if (value == null) {
      data.remove(0x0110);
    } else {
      data[0x0110] = ExifAsciiValue(value);
    }
  }

  bool get hasOrientation => data.containsKey(0x0112);
  int? get Orientation => data[0x0112]?.toInt();
  set Orientation(int? value) {
    if (value == null) {
      data.remove(0x0112);
    } else {
      data[0x0112] = ExifShortValue(value);
    }
  }

  bool _setRational(int tag, Object? value) {
    if (value is Rational) {
      data[tag] = ExifRationalValue.from(value);
      return true;
    } else if (value is List<int>) {
      if (value.length == 2) {
        data[tag] = ExifRationalValue.from(Rational(value[0], value[1]));
        return true;
      }
    }
    return false;
  }

  bool get hasXResolution => data.containsKey(0x011a);
  Rational? get XResolution => data[0x011a]?.toRational();
  set XResolution(Object? value) {
    if (!_setRational(0x011a, value)) {
      data.remove(0x011a);
    }
  }

  bool get hasYResolution => data.containsKey(0x011b);
  Rational? get YResolution => data[0x011b]?.toRational();
  set YResolution(Object? value) {
    if (!_setRational(0x011b, value)) {
      data.remove(0x011b);
    }
  }

  bool get hasResolutionUnit => data.containsKey(0x0128);
  int? get ResolutionUnit => data[0x0128]?.toInt();
  set ResolutionUnit(int? value) {
    if (value == null) {
      data.remove(0x0128);
    } else {
      data[0x0128] = ExifShortValue(value);
    }
  }

  bool get hasImageWidth => data.containsKey(0x0100);
  int? get ImageWidth => data[0x0100]?.toInt();
  set ImageWidth(int? value) {
    if (value == null) {
      data.remove(0x0100);
    } else {
      data[0x0100] = ExifShortValue(value);
    }
  }

  bool get hasImageHeight => data.containsKey(0x0101);
  int? get ImageHeight => data[0x0101]?.toInt();
  set ImageHeight(int? value) {
    if (value == null) {
      data.remove(0x0101);
    } else {
      data[0x0101] = ExifShortValue(value);
    }
  }

  bool get hasSoftware => data.containsKey(0x0131);
  String? get Software => data[0x0131]?.toString();
  set Software(String? value) {
    if (value == null) {
      data.remove(0x0131);
    } else {
      data[0x0131] = ExifAsciiValue(value);
    }
  }

  bool get hasCopyright => data.containsKey(0x8298);
  String? get Copyright => data[0x8298]?.toString();
  set Copyright(String? value) {
    if (value == null) {
      data.remove(0x8298);
    } else {
      data[0x8298] = ExifAsciiValue(value);
    }
  }
}

class ExifEntry {
  int tag;
  ExifValue? value;

  ExifEntry(this.tag, this.value);
}

class ExifData extends ExifIFDContainer {
  ExifData()
    : super();

  ExifData.from(ExifData? other)
    : super.from(other);

  ExifData.fromInputBuffer(InputBuffer input)
    : super() {
    read(input);
  }

  bool hasTag(int tag) {
    for (var directory in directories.values) {
      if (directory.containsKey(tag)) {
        return true;
      }
    }
    return false;
  }

  ExifIFD get imageIfd => this['ifd0'];

  ExifIFD get thumbnailIfd => this['ifd1'];

  ExifIFD get exifIfd => this['ifd0'].sub['exif'];

  ExifIFD get gpsIfd => this['ifd0'].sub['gps'];

  ExifIFD get interopIfd => this['ifd0'].sub['interop'];

  ExifValue? getTag(int tag) {
    for (var directory in directories.values) {
      if (directory.containsKey(tag)) {
        return directory[tag];
      }
    }
    return null;
  }

  String getTagName(int tag) {
    if (!ExifImageTags.containsKey(tag)) {
      return '<unknown>';
    }
    return ExifImageTags[tag]!.name;
  }

  String toString() {
    final s = StringBuffer();
    for (var name in directories.keys) {
      s.write('$name\n');
      final directory = directories[name]!;
      for (var tag in directory.keys) {
        var value = directory[tag];
        if (value == null) {
          s.write('\t${getTagName(tag)}\n');
        } else {
          s.write('\t${getTagName(tag)}: $value\n');
        }
      }
      for (var subName in directory.sub.keys) {
        s.write('$subName\n');
        final subDirectory = directory.sub[subName];
        for (var tag in subDirectory.keys) {
          var value = subDirectory[tag];
          if (value == null) {
            s.write('\t${getTagName(tag)}\n');
          } else {
            s.write('\t${getTagName(tag)}: $value\n');
          }
        }
      }
    }
    return s.toString();
  }

  void write(OutputBuffer out) {
    final saveEndian = out.bigEndian;
    out.bigEndian = true;

    // Tiff header
    out.writeUint16(0x4d4d); // big endian
    out.writeUint16(0x002a);
    out.writeUint32(8); // offset to first ifd block

    if (directories['ifd0'] == null)
      directories['ifd0'] = ExifIFD();

    var dataOffset = 8; // offset to first ifd block, from start of tiff header
    var offsets = <String,int>{};

    for (var name in directories.keys) {
      final ifd = directories[name]!;
      offsets[name] = dataOffset;

      if (ifd.sub.containsKey('exif')) {
        ifd[0x8769] = ExifLongValue(0);
      } else {
        ifd.data.remove(0x8769);
      }

      if (ifd.sub.containsKey('interop')) {
        ifd[0xA005] = ExifLongValue(0);
      } else {
        ifd.data.remove(0xA005);
      }

      if (ifd.sub.containsKey('gps')) {
        ifd[0x8825] = ExifLongValue(0);
      } else {
        ifd.data.remove(0x8825);
      }

      // ifd block size
      dataOffset += 2 + (12 * ifd.values.length) + 4;

      // storage for large tag values
      for (var value in ifd.values) {
        final dataSize = value.dataSize;
        if (dataSize > 4) {
          dataOffset += dataSize;
        }
      }

      // storage for sub-ifd blocks
      for (var subName in ifd.sub.keys) {
        final subIfd = ifd.sub[subName];
        offsets[subName] = dataOffset;
        int subSize = 2 + (12 * subIfd.values.length);
        for (var value in subIfd.values) {
          final dataSize = value.dataSize;
          if (dataSize > 4) {
            subSize += dataSize;
          }
        }
        dataOffset += subSize;
      }
    }

    var numIfd = directories.keys.length;
    for (int i = 0; i < numIfd; ++i) {
      final name = directories.keys.elementAt(i);
      final ifd = directories.values.elementAt(i);

      if (ifd.sub.containsKey('exif')) {
        ifd[0x8769]!.setInt(offsets['exif']!);
      }

      if (ifd.sub.containsKey('interop')) {
        ifd[0xA005]!.setInt(offsets['interop']!);
      }

      if (ifd.sub.containsKey('gps')) {
        ifd[0x8825]!.setInt(offsets['gps']!);
      }

      final ifdOffset = offsets[name]!;
      final dataOffset = ifdOffset + 2 + (12 * ifd.values.length) + 4;

      _writeDirectory(out, ifd, dataOffset);

      if (i == numIfd - 1) {
        out.writeUint32(0);
      } else {
        final nextName = directories.keys.elementAt(i + 1);
        out.writeUint32(offsets[nextName]!);
      }

      _writeDirectoryLargeValues(out, ifd);

      for (var subName in ifd.sub.keys) {
        final subIfd = ifd.sub[subName];
        final subOffset = offsets[subName]!;
        final dataOffset = subOffset + 2 + (12 * subIfd.values.length);
        _writeDirectory(out, subIfd, dataOffset);
        _writeDirectoryLargeValues(out, subIfd);
      }
    }

    out.bigEndian = saveEndian;
  }

  int _writeDirectory(OutputBuffer out, ExifIFD ifd, int dataOffset) {
    out.writeUint16(ifd.keys.length);
    for (var tag in ifd.keys) {
      final value = ifd[tag]!;

      out.writeUint16(tag);
      out.writeUint16(value.type.index);
      out.writeUint32(value.length);

      var size = value.dataSize;
      if (size <= 4) {
        value.write(out);
        while (size < 4) {
          out.writeByte(0);
          size++;
        }
      } else {
        out.writeUint32(dataOffset);
        dataOffset += size;
      }
    }
    return dataOffset;
  }

  void _writeDirectoryLargeValues(OutputBuffer out, ExifIFD ifd) {
    for (var value in ifd.values) {
      var size = value.dataSize;
      if (size > 4) {
        value.write(out);
      }
    }
  }

  bool read(InputBuffer block) {
    final saveEndian = block.bigEndian;
    block.bigEndian = true;

    int blockOffset = block.offset;

    // Tiff header
    int endian = block.readUint16();
    if (endian == 0x4949) { // II
      block.bigEndian = false;
      if (block.readUint16() != 0x2a00) {
        block.bigEndian = saveEndian;
        return false;
      }
    } else if (endian == 0x4d4d) { // MM
      block.bigEndian = true;
      if (block.readUint16() != 0x002a) {
        block.bigEndian = saveEndian;
        return false;
      }
    } else {
      return false;
    }

    int ifdOffset = block.readUint32();

    // IFD blocks
    var index = 0;
    while (ifdOffset > 0) {
      block.offset = blockOffset + ifdOffset;

      final directory = ExifIFD();
      final numEntries = block.readUint16();
      final dir = List<ExifEntry>.generate(numEntries, (i) =>
          _readEntry(block, blockOffset));

      for (var entry in dir) {
        if (entry.value != null) {
          directory[entry.tag] = entry.value!;
        }
      }
      directories['ifd$index'] = directory;
      index++;

      ifdOffset = block.readUint32();
    }

    const subTags = {
      0x8769: 'exif',
      0xA005: 'interop',
      0x8825: 'gps',
    };

    for (var d in directories.values) {
      for (var dt in subTags.keys) {
        if (d.containsKey(dt)) { // ExifOffset
          int ifdOffset = d[dt]!.toInt();
          block.offset = blockOffset + ifdOffset;
          final directory = ExifIFD();
          final numEntries = block.readUint16();
          final dir = List<ExifEntry>.generate(numEntries, (i) =>
              _readEntry(block, blockOffset));

          for (var entry in dir) {
            if (entry.value != null) {
              directory[entry.tag] = entry.value!;
            }
          }
          d.sub[subTags[dt]!] = directory;
        }
      }
    }

    block.bigEndian = saveEndian;
    return false;
  }

  ExifEntry _readEntry(InputBuffer block, int blockOffset) {
    final tag = block.readUint16();
    final format = block.readUint16();
    final count = block.readUint32();

    final entry = ExifEntry(tag, null);

    if (format > ExifValueType.values.length)
      return entry;

    final f = ExifValueType.values[format];
    final fsize = ExifValueTypeSize[format];
    final size = count * fsize;

    final endOffset = block.offset + 4;

    if (size > 4) {
      final fieldOffset = block.readUint32();
      block.offset = fieldOffset + blockOffset;
    }

    if (block.offset + size > block.end) {
      return entry;
    }

    final data = block.readBytes(size);

    switch (f) {
      case ExifValueType.None:
        break;
      case ExifValueType.SByte:
        entry.value = ExifSByteValue.data(data, count);
        break;
      case ExifValueType.Byte:
        entry.value = ExifByteValue.data(data, count);
        break;
      case ExifValueType.Undefined:
        entry.value = ExifUndefinedValue.data(data, count);
        break;
      case ExifValueType.Ascii:
        entry.value = ExifAsciiValue.data(data, count);
        break;
      case ExifValueType.Short:
        entry.value = ExifShortValue.data(data, count);
        break;
      case ExifValueType.Long:
        entry.value = ExifLongValue.data(data, count);
        break;
      case ExifValueType.Rational:
        entry.value = ExifRationalValue.data(data, count);
        break;
      case ExifValueType.SRational:
        entry.value = ExifSRationalValue.data(data, count);
        break;
      case ExifValueType.SShort:
        entry.value = ExifSShortValue.data(data, count);
        break;
      case ExifValueType.SLong:
        entry.value = ExifSLongValue.data(data, count);
        break;
      case ExifValueType.Single:
        entry.value = ExifSingleValue.data(data, count);
        break;
      case ExifValueType.Double:
        entry.value = ExifDoubleValue.data(data, count);
        break;
    }

    block.offset = endOffset;

    return entry;
  }
}