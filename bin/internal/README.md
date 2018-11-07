Dart SDK dependency
===================

The `bin/internal/engine.version` file controls which version of the Flutter engine to use.
The file contains the commit hash of a commit in the <https://github.com/flutter/engine> repository.
That hash must have successfully been compiled on <https://build.chromium.org/p/client.flutter/> and had its artifacts (the binaries that run on Android and iOS, the compiler, etc) successfully uploaded to Google Cloud Storage.

The `/bin/internal/engine.merge_method` file controls how we merge a pull
request created by the engine auto-roller. If it's `squash`, there's only one
commit for a pull request no matter how many engine commits there are inside
that pull request. If it's `rebase`, the number of commits in the framework is
equal to the number of engine commits in the pull request. The latter method
makes it easier to detect regressions but costs more test resources.
