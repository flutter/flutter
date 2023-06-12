import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';

///
///```
/// DigestInfo ::= SEQUENCE {
///      digestAlgorithm DigestAlgorithmIdentifier,
///      digest Digest
/// }
///
/// Digest ::= OCTET STRING
///```
///
class ASN1DigestInfo extends ASN1Object {
  late ASN1AlgorithmIdentifier digestAlgorithm;
  late Uint8List digest;

  ASN1DigestInfo(this.digest, this.digestAlgorithm);

  ASN1DigestInfo.fromSequence(ASN1Sequence seq) {
    if (seq.elements!.length != 2) {
      throw ArgumentError('Sequence has not enough elements');
    }
    digestAlgorithm = ASN1AlgorithmIdentifier.fromSequence(
        seq.elements!.elementAt(0) as ASN1Sequence);
    var o = seq.elements!.elementAt(1) as ASN1OctetString;
    if (o.valueBytes != null) {
      digest = o.valueBytes!;
    }
  }

  @override
  Uint8List encode(
      {ASN1EncodingRule encodingRule = ASN1EncodingRule.ENCODING_DER}) {
    var tmp = ASN1Sequence(elements: [
      digestAlgorithm,
      ASN1OctetString(octets: digest),
    ]);
    return tmp.encode(encodingRule: encodingRule);
  }
}
