part of api;

class DESedeParameters extends DESParameters {
  final int DES_EDE_KEY_LENGTH = 24;

  DESedeParameters(Uint8List key) : super(key);
}
