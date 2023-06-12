import 'package:test/test.dart';

import 'utils/assertions.dart';
import 'utils/examples.dart';

void main() {
  for (final entry in allXml.entries) {
    test(entry.key, () => assertDocumentParseInvariants(entry.value));
  }
}
