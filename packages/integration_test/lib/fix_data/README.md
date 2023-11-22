## Directory contents

The `.yaml` files in these directories are used to
define the [`dart fix` framework](https://dart.dev/tools/dart-fix) refactorings
used by `integration_test`.

The number of fix rules defined in a file should not exceed 50 for better
maintainability. Searching for `title:` in a given `.yaml` file will account
for the number of fixes. Splitting out fix rules should be done by class.

When adding a new `.yaml` file, make a copy of `template.yaml`. Each file should
be for a single class and named `fix_<class>.yaml`. To make sure each file is
grouped with related classes, a `fix_<filename>` folder will contain all of the
fix files for the individual classes.

See the flutter/packages/integration_test/test_fixes directory for the tests
that validate these fix rules.

To run these tests locally, execute this command in the
flutter/packages/integration_test/test_fixes directory.
```sh
dart fix --compare-to-golden
```

For more documentation about Data Driven Fixes, see
https://dart.dev/go/data-driven-fixes#test-folder.

To learn more about how fixes are authored in package:integration_test, see
https://github.com/flutter/flutter/wiki/Data-driven-Fixes

## When making structural changes to this directory

The tests in this directory are also invoked from external
repositories. Specifically, the CI system for the dart-lang/sdk repo
runs these tests in order to ensure that changes to the dart fix file
format do not break Flutter.

See [tools/bots/flutter/analyze_flutter_flutter.sh](https://github.com/dart-lang/sdk/blob/main/tools/bots/flutter/analyze_flutter_flutter.sh)
for where the flutter fix tests are invoked for the dart repo.

See [dev/bots/test.dart](https://github.com/flutter/flutter/blob/master/dev/bots/test.dart)
for where the flutter fix tests are invoked for the flutter/flutter repo.

When possible, please coordinate changes to this directory that might affect the
`analyze_flutter_flutter.sh` script.
