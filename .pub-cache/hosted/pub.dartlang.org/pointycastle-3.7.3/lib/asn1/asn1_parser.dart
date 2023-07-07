import 'dart:typed_data';

import 'package:pointycastle/asn1/asn1_object.dart';
import 'package:pointycastle/asn1/asn1_tags.dart';
import 'package:pointycastle/asn1/asn1_utils.dart';
import 'package:pointycastle/asn1/primitives/asn1_bit_string.dart';
import 'package:pointycastle/asn1/primitives/asn1_bmp_string.dart';
import 'package:pointycastle/asn1/primitives/asn1_boolean.dart';
import 'package:pointycastle/asn1/primitives/asn1_generalized_time.dart';
import 'package:pointycastle/asn1/primitives/asn1_ia5_string.dart';
import 'package:pointycastle/asn1/primitives/asn1_integer.dart';
import 'package:pointycastle/asn1/primitives/asn1_null.dart';
import 'package:pointycastle/asn1/primitives/asn1_object_identifier.dart';
import 'package:pointycastle/asn1/primitives/asn1_octet_string.dart';
import 'package:pointycastle/asn1/primitives/asn1_printable_string.dart';
import 'package:pointycastle/asn1/primitives/asn1_sequence.dart';
import 'package:pointycastle/asn1/primitives/asn1_set.dart';
import 'package:pointycastle/asn1/primitives/asn1_teletext_string.dart';
import 'package:pointycastle/asn1/primitives/asn1_utc_time.dart';
import 'package:pointycastle/asn1/primitives/asn1_utf8_string.dart';
import 'package:pointycastle/asn1/unsupported_asn1_tag_exception.dart';

///
/// The ASN1Parser to parse bytes into ASN1 Objects
///
class ASN1Parser {
  ///
  /// The bytes to parse
  ///
  final Uint8List? bytes;

  ///
  /// The current position in the byte array.
  ///
  /// The inital value is 0.
  ///
  int _position = 0;

  ASN1Parser(this.bytes);

  ///
  /// Returns true if there is still an object to parse. Otherwise false.
  ///
  bool hasNext() {
    return _position < bytes!.length;
  }

  ///
  /// Parses the next object in the [bytes].
  ///
  ASN1Object nextObject() {
    // Get the current tag in the list bytes
    var tag = bytes![_position];

    // Get the length of the value bytes for the current object
    var length = ASN1Utils.decodeLength(bytes!.sublist(_position));

    var valueStartPosition =
        ASN1Utils.calculateValueStartPosition(bytes!.sublist(_position));
    if (_position < length + valueStartPosition) {
      length = length + valueStartPosition;
    } else {
      length = bytes!.length - _position;
    }

    // Create new view from the bytes
    var offset = _position + bytes!.offsetInBytes;
    var subBytes = Uint8List.view(bytes!.buffer, offset, length);

    // Parse the view and the tag to an ASN1Object
    var isConstructed = ASN1Utils.isConstructed(tag);
    var isPrimitive = (0xC0 & tag) == 0;
    //var isApplication = (0x40 & tag) != 0;

    ASN1Object obj;
    if (isConstructed) {
      obj = _createConstructed(tag, subBytes);
    } else if (isPrimitive) {
      obj = _createPrimitive(tag, subBytes);
    } else {
      // create a vanilla object
      obj = ASN1Object.fromBytes(subBytes);
    }

    // Update the position
    _position = _position + obj.totalEncodedByteLength;
    return obj;
  }

  ///
  /// Creates a constructed ASN1Object depending on the given [tag] and [bytes]
  ///
  ASN1Object _createConstructed(int tag, Uint8List bytes) {
    switch (tag) {
      case ASN1Tags.SEQUENCE: // sequence
        return ASN1Sequence.fromBytes(bytes);
      case ASN1Tags.SET:
        return ASN1Set.fromBytes(bytes);
      case ASN1Tags.IA5_STRING_CONSTRUCTED:
        return ASN1IA5String.fromBytes(bytes);
      case ASN1Tags.BIT_STRING_CONSTRUCTED:
        return ASN1BitString.fromBytes(bytes);
      case ASN1Tags.OCTET_STRING_CONSTRUCTED:
        return ASN1OctetString.fromBytes(bytes);
      case ASN1Tags.PRINTABLE_STRING_CONSTRUCTED:
        return ASN1PrintableString.fromBytes(bytes);
      case ASN1Tags.T61_STRING_CONSTRUCTED:
        return ASN1TeletextString.fromBytes(bytes);
      case 0xA0:
      case 0xA1:
      case 0xA2:
      case 0xA3:
      case 0xA4:
        return ASN1Object.fromBytes(bytes);
      default:
        throw UnsupportedASN1TagException(tag);
    }
  }

  ///
  /// Creates a primitive ASN1Object depending on the given [tag] and [bytes]
  ///
  ASN1Object _createPrimitive(int tag, Uint8List bytes) {
    switch (tag) {
      case ASN1Tags.OCTET_STRING:
        return ASN1OctetString.fromBytes(bytes);
      case ASN1Tags.UTF8_STRING:
        return ASN1UTF8String.fromBytes(bytes);
      case ASN1Tags.IA5_STRING:
        return ASN1IA5String.fromBytes(bytes);
      case ASN1Tags.INTEGER:
      case ASN1Tags.ENUMERATED:
        return ASN1Integer.fromBytes(bytes);
      case ASN1Tags.BOOLEAN:
        return ASN1Boolean.fromBytes(bytes);
      case ASN1Tags.OBJECT_IDENTIFIER:
        return ASN1ObjectIdentifier.fromBytes(bytes);
      case ASN1Tags.BIT_STRING:
        return ASN1BitString.fromBytes(bytes);
      case ASN1Tags.NULL:
        return ASN1Null.fromBytes(bytes);
      case ASN1Tags.PRINTABLE_STRING:
        return ASN1PrintableString.fromBytes(bytes);
      case ASN1Tags.UTC_TIME:
        return ASN1UtcTime.fromBytes(bytes);
      case ASN1Tags.T61_STRING:
        return ASN1TeletextString.fromBytes(bytes);
      case ASN1Tags.GENERALIZED_TIME:
        return ASN1GeneralizedTime.fromBytes(bytes);
      case ASN1Tags.BMP_STRING:
        return ASN1BMPString.fromBytes(bytes);
      default:
        throw UnsupportedASN1TagException(tag);
    }
  }
}
