# Change Log for `process_runner`

## 4.1.2

* Reduces process pool output in "report" mode by not printing individual completions.

## 4.1.1

* Adds missing dependency on args package to allow global activate.

## 4.1.0

* Adds a pub-installable command line utility, based on the example code, to run a tasks queue of commands from a command line. See [README.md](README.md) for more details.
* Example code is updated.
* Now throws a `ProcessRunnerException` if a job fails and `failOk` on that job is `false`.

## 4.0.1

* Add startMode to allow passing of a ProcessStartMode to
  ProcessRunner.runProcess, added live tests, and brought back `args` package for the
  example, now that `args` is null safe.

## 4.0.0

* Convert dependencies to stable versions of the now null-safe packages.
* Modified `WorkerJob.result` to be non-nullable, and initialized with an empty result.

## 4.0.0-nullsafety.4

* Expand the sdk constraint to `<2.12.0`.

## 4.0.0-nullsafety.3

* Rebase onto non-nullsafety version 3.1.1 to pick up those changes. 

## 4.0.0-nullsafety.2

* Rebase onto non-nullsafety version 3.1.0 to pick up those changes. 

## 4.0.0-nullsafety.1

* Expand the sdk constraint to `<2.11.0`.

## 4.0.0-nullsafety

* Convert to non-nullable by default, enable null-safety experiment for Dart.

## 3.1.1

* Reverted part of the migrated null safety changes, as defaulting to the
  current directory for WorkerJobs inadvertently changes behavior.
* Updated the testing harness to also check for working directory in
  invocations.

## 3.1.0

* Add `exception` to the `WorkerJob` so that when commands fail to run, the
  exception output can be seen.
* Fixed a problem with the default output function where it didn't count
  failed jobs as finished.
* Removed dependency on mockito and args to match nullsafety version.

## 3.0.0

* Breaking change to change the `result` given in the `ProcessRunnerException`
  to be a `ProcessRunnerResult` instead of a `ProcessResult`, which can't
  include the interleaved stdout/stderr output for failed commands.
* Modified the `ProcessPool` to set the result correctly on failed jobs.

## 2.0.5

* Added `WorkerJob.failOk` so that failure message of failed worker jobs is
  suppressed by default, but can be turned on.

## 2.0.4

* Added `printOutputDefault` to the `ProcessRunner` constructor, and updated
  docs.

## 2.0.3

* Updated [README.md](README.md) to fix a broken example. Bumping version to get
  updated docs on [pub.dev](https://pub.dev).

## 2.0.2

* Updated docs and [README.md](README.md). Bumping version to get updated docs
  on [pub.dev](https://pub.dev).

## 2.0.1

* Modified the package structure to get credit for having an example
* Moved sub-libraries into lib/src directory to hide them from dartdoc.
* Updated example documentation.

## 2.0.0

* Breaking change to modify the stderr, stdout, and output members of
  `ProcessRunnerResult` so that they return pre-decoded `String`s instead of
  `List<int>`s. Added `stderrRaw`, `stdoutRaw`, and `outputRaw` members that
  return the original `List<int>` values. Decoded strings are decoded by a new
  `decoder` optional argument which uses `SystemEncoder` by default.

* Breaking change to modify the `stdin` member of `WorkerJob` so that it is a
  `Stream<String>` instead of `Stream<List<int>>`, and a new `stdinRaw` method
  that is a `Stream<List<int>>`. Added an `encoder` attribute to `ProcessRunner`
  that provides the encoding for the `stdin` stream, as well as the default
  decoding for results.

* Added `ProcessPool.runToCompletion` convenience function to provide a simple
  interface that just delivers the final results, without dealing with streams.

* Added more tests.

## 1.0.0

* Initial version
