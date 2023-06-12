import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/asn1/asn1_encoding_rule.dart';
import 'package:pointycastle/asn1/asn1_object.dart';
import 'package:pointycastle/asn1/asn1_tags.dart';
import 'package:pointycastle/asn1/unsupported_asn1_encoding_rule_exception.dart';

///
/// An ASN1 Utc Time object
///
/// **Note**: It is not recommended to use the UTC Time in the far future because this will not work anymore after the year 2075,
/// due to the fact that the UTC Time only uses 2 digits to represent the year.!
///
/// Use the **GeneralizedTime** instead!
///
class ASN1UtcTime extends ASN1Object {
  ///
  /// The decoded DateTime value
  ///
  DateTime? time;

  ///
  /// Creates an [ASN1UtcTime] entity with the given [time].
  ///
  ASN1UtcTime(this.time, {int tag = ASN1Tags.UTC_TIME}) : super(tag: tag);

  ///
  /// Creates an [ASN1UtcTime] entity from the given [encodedBytes].
  ///
  ASN1UtcTime.fromBytes(Uint8List encodedBytes)
      : super.fromBytes(encodedBytes) {
    var stringValue = ascii.decode(valueBytes!);
    var formatedStringValue = _format(stringValue);
    time = DateTime.parse(formatedStringValue);
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
    var utc = time!.toUtc();
    var year = utc.year.toString().substring(2).padLeft(2, '0');
    var month = utc.month.toString().padLeft(2, '0');
    var day = utc.day.toString().padLeft(2, '0');
    var hour = utc.hour.toString().padLeft(2, '0');
    var minute = utc.minute.toString().padLeft(2, '0');
    var second = utc.second.toString().padLeft(2, '0');
    // Encode string to YYMMDDhhmm[ss]Z
    var utcString = '$year$month$day$hour$minute${second}Z';
    valueBytes = ascii.encode(utcString);
    valueByteLength = valueBytes!.length;
    return super.encode();
  }

  ///
  /// Formats the given [stringValue].
  ///
  /// This needs to be done, due to the fact that the UTC Time only uses 2 digits to represent the year.
  /// To use the DateTime.parse() method we have to add the century.
  ///
  /// **Note**: It is not recommended to use the UTC Time in the future because this will not work anymore after the year 2075! Use the GeneralizedTime instead.
  ///
  String _format(String stringValue) {
    var y2 = int.parse(stringValue.substring(0, 2));
    if (y2 > 75) {
      stringValue = '19' + stringValue;
    } else {
      stringValue = '20' + stringValue;
    }
    return stringValue.substring(0, 8) + 'T' + stringValue.substring(8);
  }

  @override
  String dump({int spaces = 0}) {
    var sb = StringBuffer();
    for (var i = 0; i < spaces; i++) {
      sb.write(' ');
    }
    sb.write('UTCTIME ${time!.toIso8601String()}');
    return sb.toString();
  }
}
