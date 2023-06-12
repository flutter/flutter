import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';

///
///```
/// SafeBag ::= SEQUENCE {
///     bagId          BAG-TYPE.&id ({PKCS12BagSet})
///     bagValue       [0] EXPLICIT BAG-TYPE.&Type({PKCS12BagSet}{@bagId}),
///     bagAttributes  SET OF PKCS12Attribute OPTIONAL
/// }
///```
///
class ASN1SafeBag extends ASN1Object {
  ///
  /// Describes the bag type. Possible objectIdentifier :
  ///
  /// * 1.2.840.113549.1.12.10.1.1 (keyBag)
  /// * 1.2.840.113549.1.12.10.1.2 (pkcs-8ShroudedKeyBag)
  /// * 1.2.840.113549.1.12.10.1.3 (certBag)
  /// * 1.2.840.113549.1.12.10.1.4 (crlBag)
  /// * 1.2.840.113549.1.12.10.1.5 (secretBag)
  /// * 1.2.840.113549.1.12.10.1.6 (safeContentsBag)
  ///
  late ASN1ObjectIdentifier bagId;
  late ASN1Object bagValue;
  ASN1Set? bagAttributes;

  ASN1SafeBag(this.bagId, this.bagValue, {this.bagAttributes});

  ///
  /// Constructor to create the SafeBag for a pkcs-8ShroudedKeyBag.
  ///
  ASN1SafeBag.forPkcs8ShroudedKeyBag(this.bagValue, {this.bagAttributes}) {
    bagId =
        ASN1ObjectIdentifier.fromIdentifierString('1.2.840.113549.1.12.10.1.2');
  }

  ///
  /// Constructor to create the SafeBag for a certBag.
  ///
  ASN1SafeBag.forCertBag(this.bagValue, {this.bagAttributes}) {
    bagId =
        ASN1ObjectIdentifier.fromIdentifierString('1.2.840.113549.1.12.10.1.3');
  }

  ///
  /// Constructor to create the SafeBag for a [KeyBag] holding a [PrivateKeyInfo].
  ///
  ASN1SafeBag.forKeyBag(this.bagValue, {this.bagAttributes}) {
    bagId =
        ASN1ObjectIdentifier.fromIdentifierString('1.2.840.113549.1.12.10.1.1');
  }

  ///
  /// Creates a SafeBag object from the given sequence consisting of up to three elements :
  /// * [ASN1ObjectIdentifier]
  /// * [EncryptedPrivateKeyInfo] or [CertBag]
  /// * [ASN1Set] (OPTIONAL)
  ///
  ASN1SafeBag.fromSequence(ASN1Sequence seq) {
    bagId = seq.elements!.elementAt(0) as ASN1ObjectIdentifier;
    if (seq.elements!.length >= 2) {
      var el = seq.elements!.elementAt(1);
      if (el.tag == 0xA0) {
        bagValue = ASN1Parser(el.valueBytes).nextObject();
      } else {
        bagValue = el;
      }
    }
    if (seq.elements!.length == 3) {
      bagAttributes = seq.elements!.elementAt(2) as ASN1Set;
    }
  }

  @override
  Uint8List encode(
      {ASN1EncodingRule encodingRule = ASN1EncodingRule.ENCODING_DER}) {
    var tmp = ASN1Sequence(elements: [bagId, _getWrapper()]);
    if (bagAttributes != null) {
      tmp.add(bagAttributes!);
    }
    return tmp.encode(encodingRule: encodingRule);
  }

  ASN1Object _getWrapper() {
    var wrapper = ASN1Object(tag: 0xA0);
    var contentBytes = bagValue.encode();
    wrapper.valueBytes = contentBytes;
    wrapper.valueByteLength = contentBytes.length;
    return wrapper;
  }
}
