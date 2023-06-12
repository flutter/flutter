// See file LICENSE for more information.

part of api;

/// A pair of public and private asymmetric keys.
class AsymmetricKeyPair<B extends PublicKey, V extends PrivateKey> {
  final B publicKey;
  final V privateKey;

  AsymmetricKeyPair(this.publicKey, this.privateKey);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AsymmetricKeyPair &&
          runtimeType == other.runtimeType &&
          publicKey == other.publicKey &&
          privateKey == other.privateKey;

  @override
  int get hashCode => publicKey.hashCode ^ privateKey.hashCode;
}
