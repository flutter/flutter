// See file LICENSE for more information.

part of api;

/// The interface that a message digest conforms to.
abstract class Digest extends Algorithm {
  /// Create the digest specified by the standard [algorithmName].
  factory Digest(String algorithmName) =>
      registry.create<Digest>(algorithmName);

  /// Get this digest's output size in bytes
  int get digestSize;

  /// Return the size in bytes of the internal buffer the digest applies
  /// it's compression function to.
  int get byteLength;

  /// Reset the digest to its original state.
  void reset();

  /// Process a whole block of [data] at once, returning the result in a new byte array.
  Uint8List process(Uint8List data);

  /// Add one byte of data to the digested input.
  void updateByte(int inp);

  /// Add [len] bytes of data contained in [inp], starting at position [inpOff]
  /// ti the digested input.
  void update(Uint8List inp, int inpOff, int len);

  /// Store the digest of previously given data in buffer [out] starting at
  /// offset [outOff]. This method returns the size of the digest.
  int doFinal(Uint8List out, int outOff);
}
