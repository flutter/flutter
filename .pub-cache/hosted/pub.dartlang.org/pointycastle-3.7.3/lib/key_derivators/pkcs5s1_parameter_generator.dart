import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/registry/registry.dart';

class PKCS5S1ParameterGenerator implements PBEParametersGenerator {
  static final FactoryConfig factoryConfig = DynamicFactoryConfig.suffix(
      PBEParametersGenerator,
      '/PKCS5S1',
      (_, final Match match) => () {
            var mac = Digest(match.group(1)!);
            return PKCS5S1ParameterGenerator(mac);
          });

  Digest digest;

  PKCS5S1ParameterGenerator(this.digest);

  late Uint8List password;
  late Uint8List salt;
  late int iterationCount;

  @override
  void init(Uint8List password, Uint8List salt, int iterationCount) {
    this.password = password;
    this.salt = salt;
    this.iterationCount = iterationCount;
  }

  Uint8List generateDerivedKey() {
    var digestBytes = Uint8List(digest.digestSize);

    digest.update(password, 0, password.length);
    digest.update(salt, 0, salt.length);

    digest.doFinal(digestBytes, 0);
    for (var i = 1; i < iterationCount; i++) {
      digest.update(digestBytes, 0, digestBytes.length);
      digest.doFinal(digestBytes, 0);
    }

    return digestBytes;
  }

  @override
  KeyParameter generateDerivedParameters(int keySize) {
    if (keySize > digest.digestSize) {
      throw ArgumentError("Can't generate a derived key $keySize bytes long.");
    }

    var dKey = generateDerivedKey();

    return KeyParameter(dKey);
  }

  @override
  ParametersWithIV generateDerivedParametersWithIV(int keySize, int ivSize) {
    keySize = keySize;
    ivSize = ivSize;

    if ((keySize + ivSize) > digest.digestSize) {
      throw ArgumentError(
          "Can't generate a derived key ${keySize + ivSize} bytes long.");
    }

    var dKey = generateDerivedKey();

    return ParametersWithIV(KeyParameter(dKey), dKey);
  }

  @override
  KeyParameter generateDerivedMacParameters(int keySize) {
    return generateDerivedParameters(keySize);
  }
}
