import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';

///
///```
/// SubjectPublicKeyInfo { ALGORITHM : IOSet} ::= SEQUENCE {
///   algorithm        AlgorithmIdentifier {{IOSet}},
///   subjectPublicKey BIT STRING
/// }
///```
///
class ASN1SubjectPublicKeyInfo extends ASN1Object {
  late ASN1AlgorithmIdentifier algorithm;
  late ASN1BitString subjectPublicKey;

  ASN1SubjectPublicKeyInfo(
    this.algorithm,
    this.subjectPublicKey,
  );

  ASN1SubjectPublicKeyInfo.fromSequence(ASN1Sequence seq) {
    if (seq.elements == null || seq.elements!.length != 2) {
      throw ArgumentError('');
    }
    if (!(seq.elements!.elementAt(0) is ASN1Sequence)) {
      throw ArgumentError('Element at index 0 has to be ASN1Sequence');
    }
    if (!(seq.elements!.elementAt(1) is ASN1BitString)) {
      throw ArgumentError('Element at index 1 has to be ASN1BitString');
    }
    algorithm = ASN1AlgorithmIdentifier.fromSequence(
        seq.elements!.elementAt(0) as ASN1Sequence);
    subjectPublicKey = seq.elements!.elementAt(1) as ASN1BitString;
  }

  @override
  Uint8List encode(
      {ASN1EncodingRule encodingRule = ASN1EncodingRule.ENCODING_DER}) {
    var tmp = ASN1Sequence(
      elements: [
        algorithm,
        subjectPublicKey,
      ],
    );
    return tmp.encode(encodingRule: encodingRule);
  }
}
