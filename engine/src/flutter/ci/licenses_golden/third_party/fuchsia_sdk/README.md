# Fuchsia SDK NOTICES

This is a snapshot of the licenses brought in from the Fuschia SDK. It was
generated with the tool at
`//engine/src/flutter/tools/licenes_cpp/tools/convert.dart` with the old value
of
[`licenses_fuchsia`](https://raw.githubusercontent.com/flutter/flutter/87d5b753196cd8eaec15bf4080f4dffbe0c36617/engine/src/flutter/ci/licenses_golden/licenses_fuchsia).

This is brought into the codebase since it's a requirement that the license
checker has the same output when run on macOS and Linux, but on macOS the
Fuchsia SDK source code isn't brought in.

Previously, the old license checker would generate this file on CI on a Linux
machine. In theory someone running the license checker on macOS would patch in
the partial license checker output. That doesn't happen anymore.

TODO(TBD): Bring in the source code for fuchsia on macOS to generate the
licenses fully without this NOTICES.
