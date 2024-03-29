# Demo of `package:test` with `DEPS`-vendored packages

Historically, `flutter/engine` used a homegrown test framework,
[`package:litetest`](../litetest/) to avoid depending on the unwieldy set of
dependencies that `package:test` brings in. However, `package:test` is now
vendored in `DEPS` (used by the Dart SDK).'

This demo shows that:

- It's possible to use `package:test` with entirely local dependencies.
- The functionality of `package:test` (such as filtering, IDE integration, etc.)
  is available.

See <https://github.com/flutter/flutter/issues/133569> for details.

## Usage

Navigate to this directory:

```sh
cd testing/pkg_test_demo
```

And run the tests using `dart test`[^1]:

```sh
dart test
```

[^1]:
    In practice, you'll want to use the `dart` binary that is vendored in the
    pre-built SDK.
