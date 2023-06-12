part of hive;

/// Abstract cipher can be implemented to customize encryption.
abstract class HiveCipher {
  /// Calculate a hash of the key. Make sure to use a secure hash.
  int calculateKeyCrc();

  /// The maximum size the input can have after it has been encrypted.
  int maxEncryptedSize(Uint8List inp);

  /// Encrypt the given bytes.
  int encrypt(
      Uint8List inp, int inpOff, int inpLength, Uint8List out, int outOff);

  /// Decrypt the given bytes.
  int decrypt(
      Uint8List inp, int inpOff, int inpLength, Uint8List out, int outOff);
}
