import 'package:pointycastle/asn1/object_identifiers_database.dart';

///
/// Class holding a list of object identifiers
///
class ObjectIdentifiers {
  ///
  /// Returns the object identifier corresponding to the given [readableName].
  ///
  /// Returns null if none object identifier can be found for the given [readableName].
  ///
  static Map<String, dynamic>? getIdentifierByName(String readableName) {
    for (var element in oi) {
      if (element['readableName'] == readableName) {
        return element;
      }
    }
    return null;
  }

  ///
  /// Returns the object identifier corresponding to the given [identifier].
  ///
  /// Returns null if none object identifier can be found for the given [identifier].
  ///
  static Map<String, dynamic>? getIdentifierByIdentifier(String? identifier) {
    for (var element in oi) {
      if (element['identifierString'] == identifier) {
        return element;
      }
    }
    return null;
  }
}
