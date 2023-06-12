import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/asn1/asn1_encoding_rule.dart';
import 'package:pointycastle/asn1/asn1_object.dart';
import 'package:pointycastle/asn1/asn1_tags.dart';
import 'package:pointycastle/asn1/unsupported_asn1_encoding_rule_exception.dart';

class ASN1GeneralizedTime extends ASN1Object {
  // The decoded date value
  DateTime? dateTimeValue;

  ///
  /// Create an [ASN1GeneralizedTime] entity with the given BigInt [dateTimeValue].
  ///
  ASN1GeneralizedTime(this.dateTimeValue, {int tag = ASN1Tags.GENERALIZED_TIME})
      : super(tag: tag);

  ///
  /// Creates an [ASN1GeneralizedTime] entity from the given [encodedBytes].
  ///
  ASN1GeneralizedTime.fromBytes(Uint8List bytes) : super.fromBytes(bytes) {
    var octets = valueBytes!;
    var stringValue = ascii.decode(octets);
    var year = stringValue.substring(0, 4);
    var month = stringValue.substring(4, 6);
    var day = stringValue.substring(6, 8);
    var hour = stringValue.substring(8, 10);
    var minute = stringValue.substring(10, 12);
    var second = stringValue.substring(12, 14);
    if (stringValue.length > 14) {
      var timeZone = stringValue.substring(14, stringValue.length);
      dateTimeValue =
          DateTime.parse('$year-$month-$day $hour:$minute:$second$timeZone');
    } else {
      dateTimeValue = DateTime.parse('$year-$month-$day $hour:$minute:$second');
    }
  }

  ///
  /// Encodes this ASN1Object depending on the given [encodingRule]
  ///
  /// If no [ASN1EncodingRule] is given, ENCODING_DER will be used.
  ///
  /// Supported encoding rules are :
  /// * [ASN1EncodingRule.ENCODING_DER]
  ///
  /// Throws an [UnsupportedAsn1EncodingRuleException] if the given [encodingRule] is not supported.
  ///
  @override
  Uint8List encode(
      {ASN1EncodingRule encodingRule = ASN1EncodingRule.ENCODING_DER}) {
    if (encodingRule != ASN1EncodingRule.ENCODING_DER) {
      throw UnsupportedAsn1EncodingRuleException(encodingRule);
    }
    var utc = dateTimeValue!.toUtc();
    var year = utc.year.toString();
    var month = utc.month.toString();
    var day = utc.day.toString();
    var hour = utc.hour.toString();
    var minute = utc.minute.toString();
    var second = utc.second.toString();
    // Encode string to YYMMDDhhmm[ss]Z
    var utcString = '$year$month$day$hour$minute${second}Z';
    valueBytes = ascii.encode(utcString);
    valueByteLength = valueBytes!.length;
    return super.encode();
  }

  @override
  String dump({int spaces = 0}) {
    var sb = StringBuffer();
    for (var i = 0; i < spaces; i++) {
      sb.write(' ');
    }
    sb.write('GENERALIZEDTIME ${dateTimeValue!.toIso8601String()}');
    return sb.toString();
  }
}
