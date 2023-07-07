import 'dart:typed_data';
import 'package:archive/archive.dart';

enum ICCPCompression { none, deflate }

/// ICC Profile data stored with an image.
class ICCProfileData {
  String name = '';
  ICCPCompression compression;
  Uint8List data;

  ICCProfileData(this.name, this.compression, this.data);

  ICCProfileData.from(ICCProfileData other)
      : name = other.name,
        compression = other.compression,
        data = other.data.sublist(0);

  /// Returns the compressed data of the ICC Profile, compressing the stored
  /// data as necessary.
  Uint8List compressed() {
    if (compression == ICCPCompression.deflate) {
      return data;
    }
    data = const ZLibEncoder().encode(data) as Uint8List;
    compression = ICCPCompression.deflate;
    return data;
  }

  /// Returns the uncompressed data of the ICC Profile, decompressing the stored
  /// data as necessary.
  Uint8List decompressed() {
    if (compression == ICCPCompression.deflate) {
      return data;
    }
    data = const ZLibDecoder().decodeBytes(data) as Uint8List;
    compression = ICCPCompression.none;
    return data;
  }
}
