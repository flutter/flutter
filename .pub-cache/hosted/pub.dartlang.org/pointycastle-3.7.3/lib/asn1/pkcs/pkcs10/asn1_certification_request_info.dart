import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';

///
///```
/// CertificationRequestInfo ::= SEQUENCE {
///   version       INTEGER { v1(0) } (v1,...),
///   subject       Name,
///   subjectPKInfo SubjectPublicKeyInfo{{ PKInfoAlgorithms }},
///   attributes    [0] Attributes{{ CRIAttributes }}
/// }
///```
///
class ASN1CertificationRequestInfo extends ASN1Object {
  /// The version. The default should be 0
  late ASN1Integer version;

  /// The distinguished name of the certificate subject
  late ASN1Name subject;

  /// Information about the public key being certified.
  late ASN1SubjectPublicKeyInfo subjectPKInfo;

  /// Collection of attributes providing additional information about the subject of the certificate.
  ASN1Object? attributes;

  ASN1CertificationRequestInfo(
    this.version,
    this.subject,
    this.subjectPKInfo, {
    this.attributes,
  });

  ASN1CertificationRequestInfo.fromSequence(ASN1Sequence seq) {
    if (seq.elements == null || seq.elements!.length != 3) {
      throw ArgumentError('');
    }
    if (!(seq.elements!.elementAt(0) is ASN1Integer)) {
      throw ArgumentError('Element at index 0 has to be ASN1Integer');
    }
    version = seq.elements!.elementAt(0) as ASN1Integer;
  }

  @override
  Uint8List encode(
      {ASN1EncodingRule encodingRule = ASN1EncodingRule.ENCODING_DER}) {
    var tmp = ASN1Sequence(
        elements: [version, subject, subjectPKInfo, _getWrapper()]);

    return tmp.encode(encodingRule: encodingRule);
  }

  ASN1Object _getWrapper() {
    var wrapper = ASN1Object(tag: 0xA0);
    if (attributes != null) {
      var contentBytes = attributes!.encode();
      wrapper.valueBytes = contentBytes;
      wrapper.valueByteLength = contentBytes.length;
    } else {
      wrapper.valueBytes = Uint8List(0);
      wrapper.valueByteLength = 0;
    }
    return wrapper;
  }
}
