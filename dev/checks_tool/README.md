# Flutter Repository Checks

Repository-wide (excluding `engine/**`) analysis and code health checks.

This directory is an experimental project to modularize the code that lives
today in [`dev/bots/analyze.dart`](../bots/analyze.dart), and make it fast
enough (and compatible with) an optional git-commit hook. If you have any
questions or concerns, see [#170491](https://github.com/flutter/flutter/issues/170491).

## Usage

```sh
./dev/checks
```
