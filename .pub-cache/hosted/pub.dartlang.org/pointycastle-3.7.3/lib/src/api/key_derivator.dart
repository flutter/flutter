// See file LICENSE for more information.

part of api;

/// The interface that a symmetric key derivator conforms to.
///
/// A [KeyDerivator] is normally used to convert some master data (like a password, for instance) to a symmetric key.
abstract class KeyDerivator extends Algorithm {
  /// Create the key derivator specified by the standard [algorithmName].
  factory KeyDerivator(String algorithmName) =>
      registry.create<KeyDerivator>(algorithmName);

  /// Get this derivator key's output size.
  int get keySize;

  /// Init the derivator with its initialization [params]. The type of [CipherParameters] depends on the algorithm being used
  /// (see the documentation of each implementation to find out more).
  void init(CipherParameters params);

  /// Process a whole block of [data] at once, returning the result in a byte array.
  Uint8List process(Uint8List data);

  /// Derive key from given input and put it in [out] at offset [outOff].
  int deriveKey(Uint8List inp, int inpOff, Uint8List out, int outOff);
}
