## Directory contents

The Dart files and golden master `.expect` files in this directory are used to
test the [`dart fix` framework](https://dart.dev/tools/dart-fix) refactorings
used by the Flutter engine.

See the engine/src/flutter/lib/fix_data directory for the current
data-driven fixes.

To run these tests locally, execute this command in the
engine/src/flutter/test_fixes directory.
```sh
dart fix --compare-to-golden
```

For more documentation about Data Driven Fixes, see
https://dart.dev/go/data-driven-fixes#test-folder.

To learn more about how fixes are authored in package:flutter, see
[Data driven fixes](../../../docs/contributing/Data-driven-Fixes.md).

## When making structural changes to this directory

The tests in this directory are also invoked from external
repositories. Specifically, the CI system for the dart-lang/sdk repo
runs these tests in order to ensure that changes to the dart fix file
format do not break Flutter.

See [tools/bots/flutter/analyze_flutter_flutter.sh](https://github.com/dart-lang/sdk/blob/main/tools/bots/flutter/analyze_flutter_flutter.sh)
for where the tests are invoked.
