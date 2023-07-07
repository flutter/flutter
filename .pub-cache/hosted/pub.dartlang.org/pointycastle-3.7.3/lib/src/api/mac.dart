// See file LICENSE for more information.

part of api;

/// The interface that a MAC (message authentication code) conforms to.
abstract class Mac extends Algorithm {
  /// Create the MAC specified by the standard [algorithmName].
  factory Mac(String algorithmName) => registry.create<Mac>(algorithmName);

  /// Get this MAC's output size.
  int get macSize;

  /// Reset the MAC to its original state.
  void reset();

  /// Init the MAC with its initialization [params]. The type of
  /// [CipherParameters] depends on the algorithm being used (see
  /// the documentation of each implementation to find out more).
  void init(CipherParameters params);

  /// Process a whole block of [data] at once, returning the result in a new
  /// byte array.
  Uint8List process(Uint8List data);

  /// Add one byte of data to the MAC input.
  void updateByte(int inp);

  /// Add [len] bytes of data contained in [inp], starting at position [inpOff]
  /// to the MAC'ed input.
  void update(Uint8List inp, int inpOff, int len);

  /// Store the MAC of previously given data in buffer [out] starting at
  /// offset [outOff]. This method returns the size of the digest.
  int doFinal(Uint8List out, int outOff);
}
