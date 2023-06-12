import '_crc64_stub.dart'
  if (dart.library.io) '_crc64_io.dart'
  if (dart.library.js) '_crc64_html.dart';

int getCrc64(List<int> array, [int crc = 0]) {
  return getCrc64_(array, crc);
}

bool isCrc64Supported() {
  return isCrc64Supported_();
}
