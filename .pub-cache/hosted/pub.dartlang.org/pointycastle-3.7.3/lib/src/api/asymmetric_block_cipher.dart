// See file LICENSE for more information.

part of api;

/// Asymmetric block cipher engines are expected to conform to this interface.
abstract class AsymmetricBlockCipher extends Algorithm {
  /// Create the cipher specified by the standard [algorithmName].
  factory AsymmetricBlockCipher(String algorithmName) =>
      registry.create<AsymmetricBlockCipher>(algorithmName);

  /// Get this ciphers's maximum input block size.
  int get inputBlockSize;

  /// Get this ciphers's maximum output block size.
  int get outputBlockSize;

  /// Reset the cipher to its original state.
  void reset();

  /// Init the cipher with its initialization [params]. The type of [CipherParameters] depends on the algorithm being used (see
  /// the documentation of each implementation to find out more).
  ///
  /// Use the argument [forEncryption] to tell the cipher if you want to encrypt or decrypt data.
  void init(bool forEncryption, CipherParameters params);

  /// Process a whole block of [data] at once, returning the result in a byte array.
  Uint8List process(Uint8List data);

  /// Process a block of [len] bytes given by [inp] and starting at offset [inpOff] and put the resulting cipher text in [out]
  /// beginning at position [outOff].
  ///
  /// This method returns the total bytes put in the output buffer.
  int processBlock(
      Uint8List inp, int inpOff, int len, Uint8List out, int outOff);
}
