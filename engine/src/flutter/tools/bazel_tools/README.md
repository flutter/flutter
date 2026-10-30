# bazel_tools

Tooling that keeps the Bazel workspace in sync with the rest of the
repository during the GN → Bazel migration of the engine build.

Nothing here is needed to build with GN. Bazel is driven through `bazelisk`
from the repository root (see the root `MODULE.bazel`, `.bazelrc` and
`.bazelversion`). Install bazelisk yourself — see
<https://github.com/bazelbuild/bazelisk#installation> — and make sure it is on
`PATH`; it is a local prerequisite like git and depot_tools, and a developer's
sync does not fetch it. (`DEPS` can: the gclient variable `download_bazelisk`
puts the CIPD package at `engine/src/flutter/third_party/bazelisk`, which is
how the CI builders that build with Bazel get it -- `build/bazel/ci.md`.) The
Bazel version it downloads is pinned by `.bazelversion`.

## `bin/gen_deps.dart`

Generates the files Bazel derives from `DEPS`:

| Output (relative to the repository root)      | Contents                                                                                    |
| --------------------------------------------- | ------------------------------------------------------------------------------------------- |
| `build_defs/repositories/deps.lock.bzl` | `VARS`, `GIT_DEPS`, `CIPD_DEPS`, `GCLIENT_GN_ARGS[_FILE]`: the pins from `DEPS` as Starlark |
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

## `bin/check_hermeticity.dart`

Scans the Bazel action graph for references to the host machine, the check
behind the migration's hermeticity metric ("no compile line references
`/usr/include`, `/usr/bin` or a system compiler"):

```sh
dart engine/src/flutter/tools/bazel_tools/bin/check_hermeticity.dart            # deps(//...) in the default configuration
dart engine/src/flutter/tools/bazel_tools/bin/check_hermeticity.dart -- -c opt  # options after -- go to bazel
dart engine/src/flutter/tools/bazel_tools/bin/check_hermeticity.dart --pattern='deps(//engine/src/flutter/fml:fml_unittests)'
```

It runs `bazel aquery --output=jsonproto --include_param_files` from the
repository root (`--bazel` picks the executable, default `bazelisk`; `--input`
scans a saved document instead) and fails, listing every finding by target and
mnemonic, if any action

- mentions an absolute path in an argument, a parameter file or an environment
  variable, other than `/proc/self/cwd` (what Bazel sets `PWD` to in the
  sandbox) and `/dev/null` — `--allow` adds more;
- has Bazel's own `PATH` or `PWD` variable set to anything but the value
  `--incompatible_strict_action_env` gives it;
- is a C/C++ action (`CppCompile`, `CppLink`, `CppArchive`, ...) whose
  executable is not a binary of one of the `clang_<platform>` repositories
  defined in `build_defs/repositories/extensions.bzl`.

The scan is textual: it proves that no command line names anything outside
the execution root, not that the tools behave hermetically; sandboxing and the
strict action environment cover that side. `lib/src/hermeticity_check.dart`
holds the rules, `test/hermeticity_check_test.dart` exercises them on
synthetic graphs without running Bazel.
