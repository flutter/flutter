## Directory contents

The `.yaml` files in these directories are used to
define the [`dart fix` framework](https://dart.dev/tools/dart-fix) refactorings
used by the Flutter framework.

The number of fix rules defined in a file should not exceed 50 for better
maintainability. Searching for `title:` in a given `.yaml` file will account
for the number of fixes. Splitting out fix rules should be done by class.

When adding a new `.yaml` file, make a copy of `fix_template.yaml`. If the new
file is not for generic library fixes (`fix_material.yaml`), ensure it is
enclosed in an appropriate library directory (`fix_data/fix_material`), and
named after the class. Fix files outside of generic libraries should represent
individual classes (`fix_data/fix_material/fix_app_bar.yaml`).

See the flutter/packages/flutter/test_fixes directory for the tests that
validate these fix rules.

To run these tests locally, execute this command in the
flutter/packages/flutter/test_fixes directory.
```sh
dart fix --compare-to-golden
```

For more documentation about Data Driven Fixes, see
https://dart.dev/go/data-driven-fixes#test-folder.

To learn more about how fixes are authored in package:flutter, see [Data driven Fixes](../../../../docs/contributing/Data-driven-Fixes.md).

## When making structural changes to this directory

The tests in this directory are also invoked from external
repositories. Specifically, the CI system for the dart-lang/sdk repo
runs these tests in order to ensure that changes to the dart fix file
format do not break Flutter.

See [tools/bots/flutter/analyze_flutter_flutter.sh](https://github.com/dart-lang/sdk/blob/main/tools/bots/flutter/analyze_flutter_flutter.sh)
for where the tests are invoked.

When possible, please coordinate changes to this directory that might affect the
`analyze_flutter_flutter.sh` script.
