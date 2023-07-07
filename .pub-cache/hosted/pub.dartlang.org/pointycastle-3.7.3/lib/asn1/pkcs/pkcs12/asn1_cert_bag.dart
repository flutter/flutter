import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';

///
///```
/// CertBag ::= SEQUENCE {
///   certId      BAG-TYPE.&id   ({CertTypes}),
///   certValue   [0] EXPLICIT BAG-TYPE.&Type ({CertTypes}{@certId})
/// }
///```
///
class ASN1CertBag extends ASN1Object {
  ///
  /// Possible objectIdentifier :
  /// * 1.2.840.113549.1.9.22.1 (x509Certificate)
  /// * 1.2.840.113549.1.9.22.2 (sdsiCertificate)
  ///
  late ASN1ObjectIdentifier certId;

  ///
  /// Possible objects :
  /// * x509Certificate => [ASN1OctetString]
  /// * sdsiCertificate => [ASN1IA5String]
  ///
  late ASN1Object certValue;

  ASN1CertBag(this.certId, this.certValue);

  ///
  /// Constructor to create the CertBag for a X509 Certificate.
  ///
  ASN1CertBag.forX509Certificate(ASN1OctetString certValue) {
    certId =
        ASN1ObjectIdentifier.fromIdentifierString('1.2.840.113549.1.9.22.1');
    this.certValue = certValue;
  }

  ///
  /// Constructor to create the CertBag for a SDSI Certificate.
  ///
  ASN1CertBag.forSdsiCertificate(ASN1IA5String certValue) {
    certId =
        ASN1ObjectIdentifier.fromIdentifierString('1.2.840.113549.1.9.22.2');
    this.certValue = certValue;
  }

  ///
  /// Creates a CertBag object from the given sequence consisting of two elements :
  /// * ASN1ObjectIdentifier
  /// * ASN1OctetString or ASN1IA5String
  ///
  ASN1CertBag.fromSequence(ASN1Sequence seq) {
    certId = seq.elements!.elementAt(0) as ASN1ObjectIdentifier;
    if (seq.elements!.length == 2) {
      var el = seq.elements!.elementAt(1);
      if (el.tag == 0xA0) {
        certValue = ASN1Parser(el.valueBytes).nextObject();
      } else {
        certValue = el;
      }
    }
  }

  @override
  Uint8List encode(
      {ASN1EncodingRule encodingRule = ASN1EncodingRule.ENCODING_DER}) {
    var wrapper = _getWrapper();
    var tmp = ASN1Sequence(elements: [
      certId,
      wrapper,
    ]);
    return tmp.encode(encodingRule: encodingRule);
  }

  ASN1Object _getWrapper() {
    var wrapper = ASN1Object(tag: 0xA0);
    var contentBytes = certValue.encode();
    wrapper.valueBytes = contentBytes;
    wrapper.valueByteLength = contentBytes.length;
    return wrapper;
  }

  ASN1CertBag.fromX509Pem(String pem) {
    var bytes = ASN1Utils.getBytesFromPEMString(pem);
    certValue = ASN1OctetString(octets: bytes);
    certId =
        ASN1ObjectIdentifier.fromIdentifierString('1.2.840.113549.1.9.22.1');
  }
}
