# Process

The [`process_runner`] package for Dart uses the [`ProcessManager`] class from
[`process`] package to allow invocation of external OS processes, and manages
the stderr and stdout properly so that you don't lose any output, and can easily
access it without needing to wait on streams.

Like `dart:io` and [`process`], it supplies a rich, Dart-idiomatic API for
spawning OS processes, with the added benefit of easy retrieval of stdout and
stderr from the result of running the process, with proper waiting for the
process and stderr/stdout streams to be closed. Because it uses [`process`], you
can supply a mocked [`ProcessManager`] to allow testing of code that uses
[`process_runner`].

In addition to being able to launch processes separately with [`ProcessRunner`],
it allows creation of a pool of worker processes with [`ProcessPool`], and
manages running them with a set number of active [`WorkerJob`s], and manages the
collection of their stdout, stderr, and interleaved stdout and stderr output.

See the [example](example/main.dart) and [`process_runner` library docs] for
more information on how to use it, but the basic usage for  is:

```dart
import 'package:process_runner/process_runner.dart';

Future<void> main() async {
  ProcessRunner processRunner = ProcessRunner();
  ProcessRunnerResult result = await processRunner.runProcess(['ls']);

  print('stdout: ${result.stdout}');
  print('stderr: ${result.stderr}');

  // Print interleaved stdout/stderr:
  print('combined: ${result.output}');
}
```

For the [`ProcessPool`](lib/process_pool.dart), also see the [example](example),
but it basically looks like this:

```dart
import 'package:process_runner/process_runner.dart';

Future<void> main() async {
  ProcessPool pool = ProcessPool(numWorkers: 2);
  final List<WorkerJob> jobs = <WorkerJob>[
    WorkerJob(['ls'], name: 'Job 1'),
    WorkerJob(['df'], name: 'Job 2'),
  ];
  await for (final WorkerJob job in pool.startWorkers(jobs)) {
    print('\nFinished job ${job.name}');
  }
}
```

Or, if you just want the answer when it's done:

```dart
import 'package:process_runner/process_runner.dart';

Future<void> main() async {
  ProcessPool pool = ProcessPool(numWorkers: 2);
  final List<WorkerJob> jobs = <WorkerJob>[
    WorkerJob(['ls'], name: 'Job 1'),
    WorkerJob(['df'], name: 'Job 2'),
  ];
  List<WorkerJob> finishedJobs = await pool.runToCompletion(jobs);
  for (final WorkerJob job in finishedJobs) {
    print("${job.name}: ${job.result.stdout}");
  }
}
```

## `process_runner` utility

The example can also be installed and run as a useful command-line utility. You can install it using:

```shell
dart pub global activate process_runner
```

And you can run it with:

```shell
dart pub global run process_runner
```

The above steps will work on any Dart-supported platform.

Of course, you can also just compile the example into a native executable and move it to a directory in your PATH:

```shell
dart compile exe bin/process_runner.dart -o process_runner
mv process_runner /some/bin/dir/in/your/path
```

The usage for the utility is as follows:

```
process_runner [--help] [--quiet] [--report] [--stdout] [--stderr]
               [--run-in-shell] [--working-directory=<working directory>]
               [--jobs=<num_worker_jobs>] [--command="command" ...]
               [--source=<file|"-"> ...]:
-h, --help                 Print help for process_runner.
-q, --quiet                Silences the stderr and stdout output of the
                           commands. This is a shorthand for "--no-stdout
                           --no-stderr".
-r, --report               Print progress on the jobs to stderr while running.
    --[no-]stdout          Prints the stdout output of the commands to stdout in
                           the order they complete. Will not interleave lines
                           from separate processes. Has no effect if --quiet is
                           specified.
                           (defaults to on)
    --[no-]stderr          Prints the stderr output of the commands to stderr in
                           the order they complete. Will not interleave lines
                           from separate processes. Has no effect if --quiet is
                           specified
                           (defaults to on)
    --run-in-shell         Run the commands in a subshell.
    --[no-]fail-ok         If set, allows continuing execution of the remaining
                           commands even if one fails to execute. If not set,
                           ("--no-fail-ok") then process will just exit with a
                           non-zero code at completion if there were any jobs
                           that failed.
-j, --jobs                 Specify the number of worker jobs to run
                           simultaneously. Defaults to the number of processor
                           cores on the machine.
    --working-directory    Specify the working directory to run in.
                           (defaults to ".")
-c, --command              Specify a command to add to the commands to be run.
                           Commands specified with this option run before those
                           specified with --source. Be sure to quote arguments
                           to --command properly on the command line.
-s, --source               Specify the name of a file to read commands from, one
                           per line, as they would appear on the command line,
                           with spaces escaped or quoted. Specify "--source -"
                           to read from stdin. More than one --source argument
                           may be specified, and they will be concatenated in
                           the order specified. The stdin ("--source -")
                           argument may only be specified once.
```

[`ProcessManager`]: https://github.com/google/process.dart/blob/master/lib/src/interface/process_manager.dart#L21
[`process`]: https://pub.dev/packages/process
[`process_runner`]: https://pub.dev/packages/process_runner
[`ProcessRunner`]: https://pub.dev/documentation/process_runner/latest/process_runner/ProcessRunner-class.html
[`ProcessPool`]: https://pub.dev/documentation/process_runner/latest/process_runner/ProcessPool-class.html
[`process_runner` library docs]: https://pub.dev/documentation/process_runner/latest/process_runner/process_runner-library.html
[`WorkerJob`s]: https://pub.dev/documentation/process_runner/latest/process_runner/WorkerJob-class.html
