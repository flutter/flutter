// See file LICENSE for more information.

part of api;

/// [CipherParameters] for [PaddedBlockCipher]s consisting of two underlying [CipherParameters], one for the [BlockCipher] (of
/// type [UnderlyingCipherParameters]) and the other for the [Padding] (of type [PaddingCipherParameters]).
class PaddedBlockCipherParameters<
        UnderlyingCipherParameters extends CipherParameters?,
        PaddingCipherParameters extends CipherParameters?>
    implements CipherParameters {
  final UnderlyingCipherParameters? underlyingCipherParameters;
  final PaddingCipherParameters? paddingCipherParameters;

  PaddedBlockCipherParameters(
      this.underlyingCipherParameters, this.paddingCipherParameters);
}
