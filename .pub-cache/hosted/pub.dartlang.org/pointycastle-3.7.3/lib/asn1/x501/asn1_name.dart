import 'dart:typed_data';
import 'package:pointycastle/asn1.dart';

///
///```
/// Name ::= CHOICE { -- only one possibility for now --
///   rdnSequence  RDNSequence
/// }
///
/// RDNSequence ::= SEQUENCE OF RelativeDistinguishedName
///```
///
class ASN1Name extends ASN1Object {
  late List<ASN1RDN> rdnSequence;

  ASN1Name(this.rdnSequence);

  @override
  Uint8List encode(
      {ASN1EncodingRule encodingRule = ASN1EncodingRule.ENCODING_DER}) {
    var tmp = ASN1Sequence(
      elements: rdnSequence,
    );
    return tmp.encode(encodingRule: encodingRule);
  }
}
