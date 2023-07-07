import 'dart:typed_data';
import 'package:archive/archive.dart';

enum IccProfileCompression { none, deflate }

/// ICC Profile data stored with an image.
class IccProfile {
  String name = '';
  IccProfileCompression compression;
  Uint8List data;

  IccProfile(this.name, this.compression, this.data);

  IccProfile.from(IccProfile other)
      : name = other.name,
        compression = other.compression,
        data = other.data.sublist(0);

  IccProfile clone() => IccProfile.from(this);

  /// Returns the compressed data of the ICC Profile, compressing the stored
  /// data as necessary.
  Uint8List compressed() {
    if (compression == IccProfileCompression.deflate) {
      return data;
    }
    data = const ZLibEncoder().encode(data) as Uint8List;
    compression = IccProfileCompression.deflate;
    return data;
  }

  /// Returns the uncompressed data of the ICC Profile, decompressing the stored
  /// data as necessary.
  Uint8List decompressed() {
    if (compression == IccProfileCompression.deflate) {
      return data;
    }
    data = const ZLibDecoder().decodeBytes(data) as Uint8List;
    compression = IccProfileCompression.none;
    return data;
  }
}
