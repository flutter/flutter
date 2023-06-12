import 'package:flutter/foundation.dart';

import 'test_page.dart';

/// Deprecated test page.
class DeprecatedTestPage extends TestPage {
  /// Deprecated test page.
  DeprecatedTestPage({Key? key}) : super('Deprecated tests', key: key) {
    test('None', () async {});
  }
}
