
import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';

///
///```
///  SafeContents ::= SEQUENCE OF SafeBag
///```
///
class ASN1SafeContents extends ASN1Object {
  ///
  /// The safebags to store.
  ///
  late List<ASN1SafeBag> safeBags;

  ASN1SafeContents(this.safeBags);

  ///
  /// Creates a SafeContents object from the given sequence consisting of [SafeBag] or [ASN1Sequence].
  ///
  ASN1SafeContents.fromSequence(ASN1Sequence seq) {
    safeBags = [];
    if (seq.elements != null) {
      seq.elements!.forEach((element) {
        if (element is ASN1SafeBag) {
          safeBags.add(element);
        } else if (element is ASN1Sequence) {
          safeBags.add(ASN1SafeBag.fromSequence(element));
        }
      });
    }
  }

  @override
  Uint8List encode(
      {ASN1EncodingRule encodingRule = ASN1EncodingRule.ENCODING_DER}) {
    var tmp = ASN1Sequence(elements: safeBags);
    return tmp.encode(encodingRule: encodingRule);
  }
}
