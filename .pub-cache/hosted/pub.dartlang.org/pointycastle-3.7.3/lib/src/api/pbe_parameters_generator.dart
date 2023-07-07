part of api;

abstract class PBEParametersGenerator {
  factory PBEParametersGenerator(String algorithmName) =>
      registry.create<PBEParametersGenerator>(algorithmName);

  void init(Uint8List password, Uint8List salt, int iterationCount);

  ///
  /// Generates a derived key with the given [keySize] in bytes.
  ///
  KeyParameter generateDerivedParameters(int keySize);

  ///
  /// Generates a derived key with the given [keySize] in bytes and a derived IV with the given [ivSize].
  ///
  ParametersWithIV generateDerivedParametersWithIV(int keySize, int ivSize);

  ///
  /// Generates a derived key with the given [keySize] in bytes used for mac generating.
  ///
  KeyParameter generateDerivedMacParameters(int keySize);
}
