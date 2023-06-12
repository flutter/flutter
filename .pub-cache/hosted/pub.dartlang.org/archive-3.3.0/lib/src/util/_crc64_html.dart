bool isCrc64Supported_() {
  return false;
}

int getCrc64_(List<int> array, [int crc = 0]) {
  throw UnsupportedError('Crc64 is not support on html');
}
