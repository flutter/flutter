import 'dart:typed_data';

import 'package:pointycastle/asn1/asn1_encoding_rule.dart';
import 'package:pointycastle/asn1/asn1_object.dart';
import 'package:pointycastle/asn1/asn1_parser.dart';
import 'package:pointycastle/asn1/asn1_tags.dart';
import 'package:pointycastle/asn1/asn1_utils.dart';
import 'package:pointycastle/asn1/unsupported_asn1_encoding_rule_exception.dart';

///
/// An ASN1 Bit String object
///
class ASN1BitString extends ASN1Object {
  ///
  /// The decoded string value
  ///
  List<int>? stringValues;

  ///
  /// The unused bits
  ///
  int? unusedbits;

  ///
  /// A list of elements. Only set if this ASN1IA5String is constructed, otherwhise null.
  ///
  ///
  List<ASN1Object>? elements;

  ///
  /// Create an [ASN1BitString] entity with the given [stringValues].
  ///
  ASN1BitString(
      {this.stringValues, this.elements, int tag = ASN1Tags.BIT_STRING})
      : super(tag: tag);

  ///
  /// Creates an [ASN1BitString] entity from the given [encodedBytes].
  ///
  ASN1BitString.fromBytes(Uint8List bytes) : super.fromBytes(bytes) {
    if (ASN1Utils.isConstructed(encodedBytes!.elementAt(0))) {
      elements = [];
      var parser = ASN1Parser(valueBytes);
      stringValues = [];
      while (parser.hasNext()) {
        var bitString = parser.nextObject() as ASN1BitString;
        stringValues!.addAll(bitString.stringValues!);
        elements!.add(bitString);
      }
    } else {
      unusedbits = valueBytes![0];
      stringValues = valueBytes!.sublist(1);
    }
  }

  ///
  /// Encodes this ASN1Object depending on the given [encodingRule]
  ///
  /// If no [ASN1EncodingRule] is given, ENCODING_DER will be used.
  ///
  /// Supported encoding rules are :
  /// * [ASN1EncodingRule.ENCODING_DER]
  /// * [ASN1EncodingRule.ENCODING_BER_LONG_LENGTH_FORM]
  /// * [ASN1EncodingRule.ENCODING_BER_CONSTRUCTED]
  /// * [ASN1EncodingRule.ENCODING_BER_CONSTRUCTED_INDEFINITE_LENGTH]
  /// * [ASN1EncodingRule.ENCODING_BER_PADDED]
  ///
  /// Throws an [UnsupportedAsn1EncodingRuleException] if the given [encodingRule] is not supported.
  ///
  @override
  Uint8List encode(
      {ASN1EncodingRule encodingRule = ASN1EncodingRule.ENCODING_DER}) {
    switch (encodingRule) {
      case ASN1EncodingRule.ENCODING_BER_PADDED:
      case ASN1EncodingRule.ENCODING_DER:
      case ASN1EncodingRule.ENCODING_BER_LONG_LENGTH_FORM:
        var b = <int>[];
        if (unusedbits != null) {
          b.add(unusedbits!);
        } else {
          b.add(0);
        }
        b.addAll(stringValues!);
        valueBytes = Uint8List.fromList(b);
        break;
      case ASN1EncodingRule.ENCODING_BER_CONSTRUCTED_INDEFINITE_LENGTH:
      case ASN1EncodingRule.ENCODING_BER_CONSTRUCTED:
        valueByteLength = 0;
        if (elements == null) {
          elements = <ASN1Object>[];
          elements!.add(ASN1BitString(stringValues: stringValues));
        }
        valueByteLength = _childLength(
            isIndefinite: encodingRule ==
                ASN1EncodingRule.ENCODING_BER_CONSTRUCTED_INDEFINITE_LENGTH);
        valueBytes = Uint8List(valueByteLength!);
        var i = 0;
        elements!.forEach((obj) {
          var b = obj.encode();
          valueBytes!.setRange(i, i + b.length, b);
          i += b.length;
        });
        break;
    }

    return super.encode(encodingRule: encodingRule);
  }

  ///
  /// Calculate encoded length of all children
  ///
  int _childLength({bool isIndefinite = false}) {
    var l = 0;
    elements!.forEach((ASN1Object obj) {
      l += obj.encode().length;
    });
    if (isIndefinite) {
      return l + 2;
    }
    return l;
  }

  @override
  String dump({int spaces = 0}) {
    var sb = StringBuffer();
    for (var i = 0; i < spaces; i++) {
      sb.write(' ');
    }
    if (isConstructed!) {
      sb.write('BIT STRING (${elements!.length} elem)');
      for (var e in elements!) {
        var dump = e.dump(spaces: spaces + dumpIndent);
        sb.write('\n$dump');
      }
    } else {
      if (ASN1Utils.isASN1Tag(stringValues!.elementAt(0))) {
        var sb2 = StringBuffer();
        for (var v in stringValues!) {
          var s = v.toRadixString(2);
          sb2.write(s);
        }
        var bits = sb2.toString();
        if (unusedbits != null) {
          bits = bits.substring(0, bits.length - unusedbits!);
        }
        var parser = ASN1Parser(stringValues as Uint8List?);
        var next = parser.nextObject();
        var dump = next.dump(spaces: spaces + dumpIndent);
        sb.write('BIT STRING (${(bits.length)} bit)\n$dump');
      } else {
        var sb2 = StringBuffer();
        for (var v in stringValues!) {
          var s = v.toRadixString(2);
          sb2.write(s);
        }
        var bits = sb2.toString();
        if (unusedbits != null) {
          bits = bits.substring(0, bits.length - unusedbits!);
        }
        sb.write('BIT STRING (${(bits.length)} bit) ');
        sb.write(bits);
      }
    }
    return sb.toString();
  }
}
