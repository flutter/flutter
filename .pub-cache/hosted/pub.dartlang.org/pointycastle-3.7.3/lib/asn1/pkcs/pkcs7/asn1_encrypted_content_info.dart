import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/pointycastle.dart';

///
///```
/// EncryptedContentInfo ::= SEQUENCE {
///   contentType ContentType,
///   contentEncryptionAlgorithm ContentEncryptionAlgorithmIdentifier,
///   encryptedContent [0] IMPLICIT EncryptedContent OPTIONAL
/// }
///```
///
class ASN1EncryptedContentInfo extends ASN1Object {
  late ASN1ObjectIdentifier contentType;
  late ASN1AlgorithmIdentifier contentEncryptionAlgorithm;
  Uint8List? encryptedContent;

  ASN1EncryptedContentInfo(this.contentType, this.contentEncryptionAlgorithm,
      {this.encryptedContent});

  ASN1EncryptedContentInfo.fromSequence(ASN1Sequence seq) {
    contentType = seq.elements!.elementAt(0) as ASN1ObjectIdentifier;
    if (seq.elements!.length >= 2) {
      var el = seq.elements!.elementAt(1);
      if (el is ASN1Sequence) {
        contentEncryptionAlgorithm = ASN1AlgorithmIdentifier.fromSequence(el);
      }
    }
    if (seq.elements!.length >= 3) {
      var asn1Obj = seq.elements!.elementAt(2);
      encryptedContent = asn1Obj.valueBytes;
    }
  }

  ASN1EncryptedContentInfo.forData(
      this.contentEncryptionAlgorithm, this.encryptedContent) {
    //contentType =
    //    ASN1ObjectIdentifier.fromIdentifierString('1.2.840.113549.1.7.1');
    contentType = ASN1ObjectIdentifier.fromBytes(
      Uint8List.fromList(
          [0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x07, 0x01]),
    );
  }

  @override
  Uint8List encode(
      {ASN1EncodingRule encodingRule = ASN1EncodingRule.ENCODING_DER}) {
    var wrapper = _getWrapper();
    var tmp = ASN1Sequence(elements: [
      contentType,
      contentEncryptionAlgorithm,
      wrapper,
    ]);
    return tmp.encode(encodingRule: encodingRule);
  }

  ASN1Object _getWrapper() {
    var wrapper = ASN1Object(tag: 0x80);
    if (encryptedContent != null) {
      wrapper.valueBytes = encryptedContent;
      wrapper.valueByteLength = encryptedContent!.length;
    }
    return wrapper;
  }
}
