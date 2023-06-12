import 'dart:typed_data';

/// Exif data stored with an image.
class ExifData {
  static const CAMERA_MAKE = 0x010F; // string
  static const CAMERA_MODEL = 0x0110; // string
  static const DATE_TIME = 0x0132; // string
  static const ORIENTATION = 0x0112; // int

  List<Uint8List>? rawData;
  Map<int, dynamic> data;

  ExifData() : data = <int, dynamic>{};

  ExifData.from(ExifData? other)
      : data = (other == null)
            ? <int, dynamic>{}
            : Map<int, dynamic>.from(other.data) {
    if (other != null && other.rawData != null) {
      rawData = List<Uint8List>.generate(
          other.rawData!.length, (i) => other.rawData![i].sublist(0));
    }
  }

  bool get hasRawData => rawData != null && rawData!.isNotEmpty;

  bool get hasOrientation => data.containsKey(ORIENTATION);
  int get orientation => data[ORIENTATION] as int;
  set orientation(int value) => data[ORIENTATION] = value;
}
