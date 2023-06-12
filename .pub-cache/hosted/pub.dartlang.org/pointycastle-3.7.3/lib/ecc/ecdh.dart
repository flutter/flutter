import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/ecc_base.dart';
import 'package:pointycastle/src/platform_check/platform_check.dart';

/// P1363 7.2.1 ECSVDP-DH
///
/// ECSVDP-DH is Elliptic Curve Secret Value Derivation Primitive,
/// Diffie-Hellman version. It is based on the work of [DH76], [Mil86],
/// and [Kob87]. This primitive derives a shared secret value from one
/// party's private key and another party's public key, where both have
/// the same set of EC domain parameters. If two parties correctly
/// execute this primitive, they will produce the same output. This
/// primitive can be invoked by a scheme to derive a shared secret key;
/// specifically, it may be used with the schemes ECKAS-DH1 and
/// DL/ECKAS-DH2. It assumes that the input keys are valid (see also
/// Section 7.2.2).
class ECDHBasicAgreement implements ECDHAgreement {
  late ECPrivateKey key;

  @override
  void init(ECPrivateKey key) {
    this.key = key;
  }

  @override
  int getFieldSize() {
    return (key.parameters!.curve.fieldSize + 7) ~/ 8;
  }

  @override
  BigInt calculateAgreement(ECPublicKey pubKey) {
    var params = key.parameters;
    if (pubKey.parameters?.curve != params?.curve) {
      throw PlatformException('ECDH public key has wrong domain parameters');
    }

    var d = key.d!;

    // Always perform calculations on the exact curve specified by our private key's parameters
    var Q = cleanPoint(params!.curve, pubKey.Q!);
    if (Q == null || Q.isInfinity) {
      throw PlatformException('Infinity is not a valid public key for ECDH');
    }

    var h = (params as ECDomainParametersImpl).h!;

    if (!(h.compareTo(BigInt.one) == 0)) {
      d = (h.modInverse(params.n) * d) % params.n;
      Q = Q * h;
    }

    var P = (Q! * d)!;

    if (P.isInfinity) {
      throw PlatformException(
          'Infinity is not a valid agreement value for ECDH');
    }

    return P.x!.toBigInteger()!;
  }
}

ECPoint? cleanPoint(ECCurve c, ECPoint p) {
  var cp = p.curve;
  if (c != cp) {
    throw PlatformException('Point must be on the same curve');
  }

  return c.decodePoint(p.getEncoded(false));
}
