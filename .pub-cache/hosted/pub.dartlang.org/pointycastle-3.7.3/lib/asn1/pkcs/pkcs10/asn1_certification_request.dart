import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';

///
///```
/// CertificationRequest ::= SEQUENCE {
///   certificationRequestInfo CertificationRequestInfo,
///   signatureAlgorithm AlgorithmIdentifier{{ SignatureAlgorithms }},
///   signature          BIT STRING
/// }
///```
///
class ASN1CertificationRequest extends ASN1Object {
  late ASN1Object certificationRequestInfo;
  late ASN1AlgorithmIdentifier signatureAlgorithm;
  late ASN1BitString signature;

  ASN1CertificationRequest(
    this.certificationRequestInfo,
    this.signatureAlgorithm,
    this.signature,
  );

  ASN1CertificationRequest.fromSequence(ASN1Sequence seq) {
    if (seq.elements == null || seq.elements!.length != 3) {
      throw ArgumentError('');
    }
    if (!(seq.elements!.elementAt(0) is ASN1Sequence)) {
      throw ArgumentError('Element at index 0 has to be ASN1Sequence');
    }
    if (!(seq.elements!.elementAt(1) is ASN1Sequence)) {
      throw ArgumentError('Element at index 1 has to be ASN1Sequence');
    }
    if (!(seq.elements!.elementAt(2) is ASN1BitString)) {
      throw ArgumentError('Element at index 2 has to be ASN1BitString');
    }
    certificationRequestInfo = seq.elements!.elementAt(0);
    signatureAlgorithm = ASN1AlgorithmIdentifier.fromSequence(
        seq.elements!.elementAt(1) as ASN1Sequence);
    signature = seq.elements!.elementAt(2) as ASN1BitString;
  }

  @override
  Uint8List encode(
      {ASN1EncodingRule encodingRule = ASN1EncodingRule.ENCODING_DER}) {
    var tmp = ASN1Sequence(
        elements: [certificationRequestInfo, signatureAlgorithm, signature]);

    return tmp.encode(encodingRule: encodingRule);
  }
}
