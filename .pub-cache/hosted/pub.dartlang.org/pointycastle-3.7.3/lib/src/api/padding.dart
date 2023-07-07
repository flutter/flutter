// See file LICENSE for more information.

part of api;

/// The interface that a padding conforms to.
abstract class Padding extends Algorithm {
  /// Create the digest specified by the standard [algorithmName].
  factory Padding(String algorithmName) =>
      registry.create<Padding>(algorithmName);

  /// Initialise the padder. Normally, paddings don't need any init params.
  void init([CipherParameters? params]);

  /// Process a whole block of [data] at once, returning the result in a byte array. If [pad] is
  /// true adds padding to the given block, otherwise, padding is removed.
  ///
  /// Note: this assumes that the last block of plain text is always passed to it inside [data]. The
  /// reason for this is that some modes such as 'trailing bit compliment' base the padding on the
  /// last byte of plain text.
  Uint8List process(bool pad, Uint8List data);

  /// Add the pad bytes to the passed in block, returning the number of bytes added.
  ///
  /// Note: this assumes that the last block of plain text is always passed to it inside [data]. i.e.
  /// if [offset] is zero, indicating the entire block is to be overwritten with padding the value of
  /// [data] should be the same as the last block of plain text. The reason for this is that some
  /// modes such as 'trailing bit compliment' base the padding on the last byte of plain text.
  int addPadding(Uint8List data, int offset);

  /// Get the number of pad bytes present in the block.
  int padCount(Uint8List data);
}
