// See file LICENSE for more information.

part of api;

/// The interface that asymmetric key generators conform to.
///
/// A [KeyGenerator] is used to create a pair of public and private keys.
abstract class KeyGenerator extends Algorithm {
  /// Create the key generator specified by the standard [algorithmName].
  factory KeyGenerator(String algorithmName) =>
      registry.create<KeyGenerator>(algorithmName);

  /// Init the generator with its initialization [params]. The type of [CipherParameters] depends on the algorithm being used
  /// (see the documentation of each implementation to find out more).
  void init(CipherParameters params);

  /// Generate a key pair.
  AsymmetricKeyPair generateKeyPair();
}
