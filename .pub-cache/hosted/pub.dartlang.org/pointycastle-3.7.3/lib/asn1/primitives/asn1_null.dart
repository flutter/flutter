import 'dart:typed_data';

import 'package:pointycastle/asn1/asn1_encoding_rule.dart';
import 'package:pointycastle/asn1/asn1_object.dart';
import 'package:pointycastle/asn1/asn1_tags.dart';
import 'package:pointycastle/asn1/unsupported_asn1_encoding_rule_exception.dart';

///
/// An ASN1 Null object
///
class ASN1Null extends ASN1Object {
  ///
  /// Creates an empty [ASN1Null] entity with only the [tag] set.
  ///
  ASN1Null({int tag = ASN1Tags.NULL}) : super(tag: tag);

  ///
  /// Creates an [ASN1Null] entity from the given [encodedBytes].
  ///
  ASN1Null.fromBytes(Uint8List encodedBytes) : super.fromBytes(encodedBytes);

  ///
  /// Encode the [ASN1Null] to the byte representation.
  ///
  /// This basically returns **[0x05, 0x00]** or **[0x05, 0x81, 0x00]** depending on the [encodingRule] and will not call the *super.encode()* method.
  ///
  /// Supported encoding rules are :
  /// * [ASN1EncodingRule.ENCODING_DER]
  /// * [ASN1EncodingRule.ENCODING_BER_LONG_LENGTH_FORM]
  ///
  @override
  Uint8List encode(
      {ASN1EncodingRule encodingRule = ASN1EncodingRule.ENCODING_DER}) {
    switch (encodingRule) {
      case ASN1EncodingRule.ENCODING_DER:
        return Uint8List.fromList([tag!, 0x00]);
      case ASN1EncodingRule.ENCODING_BER_LONG_LENGTH_FORM:
        return Uint8List.fromList([tag!, 0x81, 0x00]);
      default:
        throw UnsupportedAsn1EncodingRuleException(encodingRule);
    }
  }

  @override
  String dump({int spaces = 0}) {
    var sb = StringBuffer();
    for (var i = 0; i < spaces; i++) {
      sb.write(' ');
    }
    sb.write('NULL');
    return sb.toString();
  }
}
