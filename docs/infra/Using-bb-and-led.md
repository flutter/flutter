# Using `bb` and `led` with LUCI

Flutter's CI runs on [LUCI](../../dev/bots/README.md#luci-layered-universal-continuous-integration).
Two command line tools from [depot_tools] talk to it directly:

* **`bb`** is the [Buildbucket] client. It lists, inspects, schedules, and
  cancels builds of the builders that already exist.
* **`led`** (LUCI editor) copies a builder's job definition, lets you edit
  anything in it (recipe code, bot dimensions, properties), and launches the
  edited copy as a one-off build.

This page covers setup, which tool to pick, and common `bb` commands. For a
`led` walkthrough, see [Running DeviceLab Tests For a PR](Running-Devicelab-Tests-For-PR.md).

## Setup

1. Install [depot_tools] and add it to your `PATH`. Keep it up to date; old
   versions of `bb` and `led` can fail in confusing ways.

2. Log in. Both login flows are interactive (they open a browser or print a
   URL to visit), so run them yourself in a terminal. An AI agent or script
   can't complete them.

   ```shell
   bb auth-login
   led auth-login   # only if you use led
   ```

3. Check that it worked:

   ```shell
   bb auth-info    # prints "Logged in as <you>@<domain>."
   led auth-info
   ```

If you aren't logged in, every `bb` command fails, including read-only ones like
`bb ls`, with:

```
Login required: run `bb auth-login`
```

### Permissions

Reading builds and logs works with any logged-in account. Creating builds
needs membership in a LUCI group:

| Action                                        | Required group                                                   |
| --------------------------------------------- | ---------------------------------------------------------------- |
| `bb ls`, `bb get`, `bb log`                   | None (any logged-in account)                                     |
| `bb add` in `flutter/try`                     | `project-flutter-try-schedulers`                                 |
| `bb add` in `flutter/staging`, `flutter/prod` | `project-flutter-staging-schedulers`, `project-flutter-prod-schedulers` |
| `led launch` of a `staging` or `try` builder  | `project-flutter-led-users`                                      |
| `led launch` of a `prod` builder              | `project-flutter-led-prod-users`                                 |

These bindings are defined in Flutter's [`realms.cfg`][realms]. Without the
group, `bb add` fails with a `PermissionDenied` error. To request access,
[file an infrastructure issue](https://github.com/flutter/flutter/issues/new?template=06_infrastructure.yml).

## `bb` or `led`?

Rule of thumb: if you are only changing the **code being tested**, use `bb`.
If you need to change **how the build runs** (recipe, bot, dimensions), use
`led`.

| I want to...                                                         | Use                                                    |
| -------------------------------------------------------------------- | ------------------------------------------------------ |
| Re-run a failed check on my PR                                       | The GitHub **Re-run** button (see [Understanding a LUCI build failure](Understanding-a-LUCI-build-failure.md)) |
| List recent builds of a builder, or measure how often it fails       | `bb ls`                                                |
| Inspect a build's steps, input properties, or status                 | `bb get`                                               |
| Print a step's log                                                   | `bb log`                                               |
| Run an existing builder N times against a PR or branch (for example, to reproduce a flake) | `bb add`                         |
| Cancel builds                                                        | `bb cancel`                                            |
| Test uncommitted changes to the [recipes] repository                 | `led ... \| led edit-recipe-bundle \| led launch`      |
| Run on different bots or dimensions, or edit fields `bb add` can't override | `led edit`                                      |

How they differ:

* **What runs.** `bb add` schedules the registered builder as is: same recipe
  version, bot pool, dimensions, and service account. You can only change
  input properties, and only the ones the builder allows; other overrides are
  rejected with `invalid property override`. `led` launches whatever job
  definition you hand it.
* **Where results go.** A `bb add` build is a normal, numbered build. It shows
  up in the builder's history on [ci.chromium.org](https://ci.chromium.org/p/flutter)
  and in `bb ls`. A `led` build is a one-off job outside the builder's history;
  `led launch` prints its link.
* **Neither reports to GitHub.** Cocoon only posts PR checks for builds it
  scheduled. Builds you start with `bb add` or `led launch` don't show up as
  checks on the PR.

## Common `bb` commands

Builders are named `<project>/<bucket>/<builder>`. The Flutter project is
`flutter`, and the buckets are `prod` (post-submit), `try` (pre-submit), and
`staging`. Quote builder names because they contain spaces.

### List and inspect builds

```shell
# The 20 most recent post-submit builds of a builder.
bb ls -n 20 'flutter/prod/Linux analyze'

# Only failures.
bb ls -n 20 -status failure 'flutter/prod/Linux analyze'

# One build, with steps and input/output properties. A build can be
# identified by its ID or by <project>/<bucket>/<builder>/<number>.
bb get -steps -p 'flutter/prod/Linux analyze/32853'

# Machine-readable output (one JSON object per line), for jq or scripts.
bb ls -json -steps -n 200 'flutter/prod/Linux analyze'
```

### Read step logs

```shell
bb log <build_id> '<step name>'
```

Nested steps use `|` as the separator, for example `'parent|child'`.

> [!Warning]
> Don't run `bb log` on a step that is still running. The log stream stays
> open until the step finishes, so the command can hang for the rest of the
> build.

### Run a builder against a PR or branch

Flutter builders get most of their input properties from
[Cocoon](https://github.com/flutter/cocoon) when it schedules them, so
`bb add` with no properties usually produces a broken build. Copy the
properties from a recent build of the same builder, point them at your code,
and then schedule:

```shell
BUILDER='Linux analyze'

bb ls -json -p -n 1 "flutter/try/$BUILDER" \
  | jq '.input.properties
        | del(.["$kitchen"], .["$recipe_engine/isolated"], .["$recipe_engine/swarming"],
              .goma_jobs, .rbe_jobs, .flutter_prebuilt_engine_version)
        | .git_url = "https://github.com/flutter/flutter"
        | .git_ref = "refs/pull/<PR number>/head"' \
  > props.json

# Schedules one build. Repeat (or loop) for more copies.
bb add -p @props.json "flutter/try/$BUILDER"
```

* To test a branch on your fork instead of a PR, set
  `git_url` to `https://github.com/<you>/flutter` and `git_ref` to
  `refs/heads/<branch>`.
* If `bb add` fails with `property "<name>": invalid property override`,
  delete that property from `props.json` and try again.
* `flutter_prebuilt_engine_version` is removed because the copied value
  belongs to whatever build you copied from, not to your change.

### Cancel builds

```shell
bb cancel -reason 'No longer needed' <build_id> [<build_id>...]
```

## See also

* [Running DeviceLab Tests For a PR](Running-Devicelab-Tests-For-PR.md) (`led`)
* [Understanding a LUCI build failure](Understanding-a-LUCI-build-failure.md)
* [Reducing Test Flakiness](Reducing-Test-Flakiness.md)
* `bb help <command>` and `led help <command>`

[depot_tools]: https://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up
[Buildbucket]: https://chromium.googlesource.com/infra/luci/luci-go/+/HEAD/buildbucket/
[recipes]: https://flutter.googlesource.com/recipes
[realms]: https://flutter.googlesource.com/infra/+/refs/heads/main/config/generated/flutter/luci/realms.cfg
