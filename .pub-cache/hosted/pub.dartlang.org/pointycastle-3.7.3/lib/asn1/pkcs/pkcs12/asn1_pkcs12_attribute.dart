import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';

///
///```
/// PKCS12Attribute ::= SEQUENCE {
///      attrId      ATTRIBUTE.&id ({PKCS12AttrSet}),
///      attrValues  SET OF ATTRIBUTE.&Type ({PKCS12AttrSet}{@attrId})
/// }
///```
///
class ASN1Pkcs12Attribute extends ASN1Object {
  ///
  /// Defines the type of the attribute.
  ///
  /// Possible objectIdentifier :
  /// * 1.2.840.113549.1.9.20 (friendlyName)
  /// * 1.2.840.113549.1.9.21 (localKeyID)
  ///
  /// See https://www.rfc-editor.org/rfc/rfc2985#section-5 for all possible attribute types.
  ///
  late ASN1ObjectIdentifier attrId;

  ///
  /// ASN1Set containing the values, depending on the [attrId].
  ///
  late ASN1Set attrValues;

  ASN1Pkcs12Attribute(this.attrId, this.attrValues);

  ///
  /// Creates an instance of Attribute for friendlyName with the given [name].
  ///
  ASN1Pkcs12Attribute.friendlyName(String name) {
    attrId = ASN1ObjectIdentifier.fromIdentifierString('1.2.840.113549.1.9.20');
    var bmpString = ASN1BMPString(stringValue: name);
    attrValues = ASN1Set(elements: [bmpString]);
  }

  ///
  /// Creates an instance of Attribute for localKeyID with the given [octets].
  ///
  ASN1Pkcs12Attribute.localKeyID(Uint8List octets) {
    //attrId = ASN1ObjectIdentifier.fromIdentifierString('1.2.840.113549.1.9.21');
    attrId = ASN1ObjectIdentifier.fromBytes(Uint8List.fromList(
        [0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x09, 0x15]));
    var octetString = ASN1OctetString(octets: octets);
    attrValues = ASN1Set(elements: [octetString]);
  }

  @override
  Uint8List encode(
      {ASN1EncodingRule encodingRule = ASN1EncodingRule.ENCODING_DER}) {
    var tmp = ASN1Sequence(elements: [attrId, attrValues]);
    return tmp.encode(encodingRule: encodingRule);
  }
}
