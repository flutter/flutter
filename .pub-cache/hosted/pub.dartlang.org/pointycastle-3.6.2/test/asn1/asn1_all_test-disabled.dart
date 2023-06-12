///
/// Collection of ASN1 related tests.
/// Invoker for <-->/all_tests_web.dart
///

import 'asn1_object_test.dart' as object_test;
import 'asn1_utils_test.dart' as utils_test;
import 'primitives/asn1_bit_string_test.dart' as p_bitstring_test;
import 'primitives/asn1_boolean_test.dart' as p_boolean_test;
import 'primitives/asn1_enumerated_test.dart' as p_enumerated_test;
import 'primitives/asn1_ia5_string_test.dart' as p_ia5string_test;
import 'primitives/asn1_integer_test.dart' as p_integer_test;
import 'primitives/asn1_null_test.dart' as p_null_test;
import 'primitives/asn1_object_identifier_test.dart' as p_oid_test;
import 'primitives/asn1_octet_string_test.dart' as p_octet_string_test;
import 'primitives/asn1_printable_string_test.dart' as p_printable_string_test;
import 'primitives/asn1_sequence_test.dart' as p_sequence_test;
import 'primitives/asn1_set_test.dart' as p_set_test;
import 'primitives/asn1_utc_time_test.dart' as p_utc_time_test;
import 'primitives/asn1_utf8_string_test.dart' as p_utf8_string_test;

void main() {
  object_test.main();
  utils_test.main();

  p_bitstring_test.main();
  p_boolean_test.main();
  p_enumerated_test.main();
  p_ia5string_test.main();
  p_integer_test.main();
  p_null_test.main();
  p_oid_test.main();
  p_octet_string_test.main();
  p_printable_string_test.main();
  p_sequence_test.main();
  p_set_test.main();
  p_utc_time_test.main();
  p_utf8_string_test.main();
}
