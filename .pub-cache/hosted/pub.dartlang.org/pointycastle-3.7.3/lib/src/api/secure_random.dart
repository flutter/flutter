// See file LICENSE for more information.

part of api;

/// A synchronous secure random number generator (RNG).
///
/// Being synchronous, this RNG cannot return direct results from sources of randomness like
/// '/dev/random' or similar. For that, use an **EntropySource** which allows to be called
/// asynchronously. Usually an **EntropySource** should be seen like a random generation device while
/// a [SecureRandom] should be seen like a cryptographic PRNG. Thus, data from an **EntropySource**
/// should be seen as 'more random' than that returned from a [SecureRandom].
abstract class SecureRandom extends Algorithm {
  /// Create the secure random specified by the standard [algorithmName].
  factory SecureRandom([String algorithmName = '']) =>
      registry.create<SecureRandom>(algorithmName);

  /// Seed the RNG with some entropy (look at package cipher_entropy providing entropy sources).
  void seed(CipherParameters params);

  /// Get one byte long random int.
  int nextUint8();

  /// Get two bytes long random int.
  int nextUint16();

  /// Get four bytes long random int.
  int nextUint32();

  /// Get a random BigInteger of [bitLength] bits.
  BigInt nextBigInteger(int bitLength);

  /// Get a list of bytes of arbitrary length.
  Uint8List nextBytes(int count);
}
