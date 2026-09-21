# Working in the Flutter repo with Claude Code

This file is the entry point for [Claude Code](https://claude.com/claude-code). It is
deliberately thin: the substance lives in `.agents/`, which is shared by every agent
that works in this repository. Read the linked files rather than relying on what is
summarised here.

## Read these first

| What | Where |
| --- | --- |
| Always-on editing rules (analyze, format, layer dependencies) | [`.agents/rules/dart-editing.md`](.agents/rules/dart-editing.md) |
| Task-specific skills (cherry-picks, PR checks, rebuilding the tool, …) | [`.agents/skills/`](.agents/skills/README.md) — also reachable as `.claude/skills`, which is a symlink |
| Agent configurations | [`.agents/agents/README.md`](.agents/agents/README.md) |
| Contributor process, tree hygiene, style guide | [`docs/contributing/`](docs/contributing/) and [`CONTRIBUTING.md`](CONTRIBUTING.md) |

`.claude/skills` is a symlink to `.agents/skills`. Add new skills under `.agents/`, never
under `.claude/` directly.

## Before declaring a task done

Per `.agents/rules/dart-editing.md`, on every file you modified:

```sh
dart analyze --fatal-infos <files>
dart format <files>
```

## Repository layout

This is a monorepo. The directory you are in determines almost everything:

- `packages/flutter/` — the framework. Subject to the layer dependency rules in
  `.agents/rules/dart-editing.md`: `material` and `cupertino` code may not cross over.
- `packages/flutter_tools/` — the `flutter` CLI. Pure Dart, not a Flutter app.
- `engine/` — the engine sources.
- `dev/` — devicelab, benchmarks and repo tooling (including
  `dev/tools/test/validate_skills_test.dart`, which validates `.agents/skills`).
- `examples/`, `docs/`.

## Use the SDK's own Dart, not a system one

The toolchain is pinned per checkout. Bootstrap it with `./bin/dart --version` (which
downloads it on first run), then invoke it explicitly:

```sh
./bin/cache/dart-sdk/bin/dart ...
```

A system-installed `dart` or `flutter` on `PATH` may be a different version and will
produce results that do not match CI.

## Running tests

For `packages/flutter_tools`, run `dart pub get` in that directory first, then target
the narrowest file you can:

```sh
cd packages/flutter_tools
../../bin/cache/dart-sdk/bin/dart test test/general.shard/base/error_handling_io_test.dart
```

Gotcha worth knowing: invoking `dart test` over a whole shard (for example
`test/general.shard/`) reports a large number of failures that are **not** regressions —
those tests expect the full `flutter test` harness. Before concluding that a change
broke something, re-run the identical command on an unmodified checkout and compare the
pass/fail counts, rather than reading the raw failure count as a verdict.

Framework tests run through the Flutter test runner:

```sh
./bin/flutter test packages/flutter/test/widgets/<file>_test.dart
```

## Pull requests

- One concern per PR. Unrelated cleanups belong in a separate PR.
- The title is prefixed with the area, for example `[flutter_tools] …`.
- The body must reference the issue it fixes (`Fixes #12345`) and keep the
  pre-launch checklist from [`.github/PULL_REQUEST_TEMPLATE.md`](.github/PULL_REQUEST_TEMPLATE.md).
- Contributors must sign the [Google CLA](https://cla.developers.google.com/) before a PR
  can land. This is a human step; it cannot be automated.
- Every new file needs the standard Flutter copyright header. Copy it from a neighbouring
  file in the same directory.
