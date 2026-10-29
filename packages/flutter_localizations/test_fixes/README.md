## Directory contents

The Dart files and golden master `.expect` files in this directory are used to
test the [`dart fix` framework](https://dart.dev/tools/dart-fix) refactorings
used by the Flutter framework.

See the flutter/packages/flutter_localizations/lib/fix_data directory for the current
package:flutter_localizations data-driven fixes.

To run these tests locally, execute this command in the
flutter/packages/flutter_localizations/test_fixes directory.
```sh
dart fix --compare-to-golden
```

For more documentation about Data Driven Fixes, see
https://dart.dev/go/data-driven-fixes#test-folder.

To learn more about how fixes are authored in package:flutter, see
[Data driven fixes](../../../docs/contributing/Data-driven-Fixes.md).
