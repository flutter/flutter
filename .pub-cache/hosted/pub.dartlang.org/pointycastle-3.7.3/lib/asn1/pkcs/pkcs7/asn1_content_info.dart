import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';

///
///
/// ```
/// ContentInfo ::= SEQUENCE {
///   contentType ContentType,
///   content
///     [0] EXPLICIT ANY DEFINED BY contentType OPTIONAL }
/// ```
///
class ASN1ContentInfo extends ASN1Object {
  late ASN1ObjectIdentifier contentType;
  ASN1Object? content;

  ASN1ContentInfo(this.contentType, {this.content});

  ASN1ContentInfo.fromSequence(ASN1Sequence seq) {
    contentType = seq.elements!.elementAt(0) as ASN1ObjectIdentifier;
    if (seq.elements!.length == 2) {
      var el = seq.elements!.elementAt(1);
      if (el.tag == 0xA0) {
        content = ASN1Parser(el.valueBytes).nextObject();
      } else {
        content = el;
      }
    }
  }

  ASN1ContentInfo.forData(this.content) {
    contentType =
        ASN1ObjectIdentifier.fromIdentifierString('1.2.840.113549.1.7.1');
  }

  ASN1ContentInfo.forEncryptedData(this.content) {
    contentType =
        ASN1ObjectIdentifier.fromIdentifierString('1.2.840.113549.1.7.6');
  }

  @override
  Uint8List encode(
      {ASN1EncodingRule encodingRule = ASN1EncodingRule.ENCODING_DER}) {
    var wrapper = _getWrapper();
    var tmp = ASN1Sequence(elements: [
      contentType,
      wrapper,
    ]);
    return tmp.encode(encodingRule: encodingRule);
  }

  ASN1Object _getWrapper() {
    var wrapper = ASN1Object(tag: 0xA0);
    if (content != null) {
      var contentBytes = content!.encode();
      wrapper.valueBytes = contentBytes;
      wrapper.valueByteLength = contentBytes.length;
    } else {
      wrapper.valueBytes = Uint8List(0);
      wrapper.valueByteLength = 0;
    }
    return wrapper;
  }
}
