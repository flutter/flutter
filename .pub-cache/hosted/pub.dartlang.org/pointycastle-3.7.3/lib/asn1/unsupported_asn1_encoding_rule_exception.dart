import 'package:pointycastle/asn1/asn1_encoding_rule.dart';

///
/// Exception that indicates that the given [ASN1EncodingRule] is not supported
///
class UnsupportedAsn1EncodingRuleException implements Exception {
  ASN1EncodingRule rule;

  UnsupportedAsn1EncodingRuleException(this.rule);

  @override
  String toString() =>
      'UnsupportedAsn1EncodingRuleException: Encoding $rule is not supported by this ASN1Object.';
}
