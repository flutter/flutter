part of api;

class RC2Parameters extends KeyParameter {
  late int effectiveKeyBits;

  RC2Parameters(Uint8List key, {int? bits}) : super(key) {
    if (bits != null) {
      effectiveKeyBits = bits;
    } else {
      effectiveKeyBits = (key.length > 128) ? 1024 : (key.length * 8);
    }
  }
}
