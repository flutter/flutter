# 1.0.2

- Require Dart SDK >= 2.14
- Ensure `DirectoryWatcher.ready` completes even when errors occur that close the watcher.
- Add markdown badges to the readme.

# 1.0.1

* Drop package:pedantic and use package:lints instead.

# 1.0.0

* Stable null safety release.

# 1.0.0-nullsafety.0

* Migrate to null safety.
* Add the ability to create custom Watcher types for specific file paths.

# 0.9.7+15

* Fix a bug on Mac where modifying a directory with a path exactly matching a
  prefix of a modified file would suppress change events for that file.

# 0.9.7+14

* Prepare for breaking change in SDK where modified times for not found files
  becomes meaningless instead of null.

# 0.9.7+13

* Catch & forward `FileSystemException` from unexpectedly closed file watchers
  on windows; the watcher will also be automatically restarted when this occurs.

# 0.9.7+12

* Catch `FileSystemException` during `existsSync()` on Windows.
* Internal cleanup.

# 0.9.7+11

* Fix an analysis hint.

# 0.9.7+10

* Set max SDK version to `<3.0.0`, and adjust other dependencies.

# 0.9.7+9

* Internal changes only.

# 0.9.7+8

* Fix Dart 2.0 type issues on Mac and Windows.

# 0.9.7+7

* Updates to support Dart 2.0 core library changes (wave 2.2).
  See [issue 31847][sdk#31847] for details.

  [sdk#31847]: https://github.com/dart-lang/sdk/issues/31847


# 0.9.7+6

* Internal changes only, namely removing dep on scheduled test.

# 0.9.7+5

* Fix an analysis warning.

# 0.9.7+4

* Declare support for `async` 2.0.0.

# 0.9.7+3

* Fix a crashing bug on Linux.

# 0.9.7+2

* Narrow the constraint on `async` to reflect the APIs this package is actually
  using.

# 0.9.7+1

* Fix all strong-mode warnings.

# 0.9.7

* Fix a bug in `FileWatcher` where events could be added after watchers were
  closed.

# 0.9.6

* Add a `Watcher` interface that encompasses watching both files and
  directories.

* Add `FileWatcher` and `PollingFileWatcher` classes for watching changes to
  individual files.

* Deprecate `DirectoryWatcher.directory`. Use `DirectoryWatcher.path` instead.

# 0.9.5

* Fix bugs where events could be added after watchers were closed.

# 0.9.4

* Treat add events for known files as modifications instead of discarding them
  on Mac OS.

# 0.9.3

* Improved support for Windows via `WindowsDirectoryWatcher`.

* Simplified `PollingDirectoryWatcher`.

* Fixed bugs in `MacOSDirectoryWatcher`
