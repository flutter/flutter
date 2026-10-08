# bazel_tools

Tooling that keeps the Bazel workspace in sync with the rest of the
repository during the GN → Bazel migration of the engine build.

Nothing here is needed to build with GN. Bazel is driven through `bazelisk`
from the repository root (see the root `MODULE.bazel`, `.bazelrc` and
`.bazelversion`). Install bazelisk yourself — see
<https://github.com/bazelbuild/bazelisk#installation> — and make sure it is on
`PATH`; it is a local prerequisite like git and depot_tools, and is
intentionally not part of `DEPS`. The Bazel version it downloads is pinned by
`.bazelversion`.

## `bin/gen_deps.dart`

Generates the files Bazel derives from `DEPS`:

| Output (relative to the repository root)      | Contents                                                                                    |
| --------------------------------------------- | ------------------------------------------------------------------------------------------- |
| `engine/src/flutter/build/bazel/deps.lock.bzl` | `VARS`, `GIT_DEPS`, `CIPD_DEPS`, `GCLIENT_GN_ARGS[_FILE]`: the pins from `DEPS` as Starlark |
| `.bazelignore`                                 | every directory gclient syncs or its hooks populate, plus GN outputs and tool caches        |

Run it from anywhere inside the checkout after editing `DEPS`:

```sh
dart engine/src/flutter/tools/bazel_tools/bin/gen_deps.dart
```

`--check` verifies the files without writing them (exit status 1 if they are
stale); `test/repo_deps_test.dart` runs that check in CI, so a `DEPS` change
that forgets to regenerate the files fails the `dart-host` tests.

`DEPS` is parsed with `lib/src/deps_file.dart`, a Dart implementation of the
Python subset that gclient's `gclient_eval.py` accepts (literal assignments,
`Var()`, `Str()`, `+`, `%` and `{name}` formatting). Values that gclient
computes per host (`host_os`, `host_cpu`, `checkout_*`) are preserved as
`{host_os}`-style placeholders so the generated files are host independent;
`condition` expressions are kept verbatim for Bazel module extensions to
evaluate.
