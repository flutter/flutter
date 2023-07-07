# Test Package Architecture

* [Code Organization](#code-organization)
  * [Frontend](#frontend)
  * [Backend](#backend)
  * [Runner](#runner)
* [Lifecycle of a Test Run](#lifecycle-of-a-test-run)
  * [Loading a Suite on the VM](#loading-a-suite-on-the-vm)
  * [Loading a Suite in the Browser](#loading-a-suite-in-the-browser)

## Code Organization

From a user's perspective, the test package provides two main pieces of
functionality: an API for defining tests, and a command-line tool to run those
tests. The structure of the package reflects this division. The code is divided
into three main sections: the frontend, the backend, and the runner.

### Frontend

The [`lib/src/frontend`][frontend] directory contains APIs that are exposed to
the user when they import `package:test/test.dart`. This includes core functions
such as `expect()` and `expectAsync()`, test-specific matchers such as
`throwsA()` and `prints()`, and annotation classes such as `TestOn` and
`Timeout`. The functions that define the top-level structure of the test, such
as `test()` and `group()`, are defined in `lib/test.dart`, but they can be
thought of as frontend functions as well.

[frontend]: https://github.com/dart-lang/test/tree/master/lib/src/frontend

The frontend communicates with the backend using zone-scoped getters.
[`Invoker.current`][Invoker] provides access to the current test case to
built-in matchers like [`completion()`][completion], for example to control when
it completes. Structural functions use [`Declarer.current`][Declarer] to
gradually build up an in-memory representation of a test suite. The runner is in
charge of setting up these variables, but the frontend never communicates with
the runner directly.

[Invoker]: https://github.com/dart-lang/test/blob/master/lib/src/backend/invoker.dart
[completion]: https://pub.dev/documentation/test_api/latest/test_api/completion.html
[Declarer]: https://github.com/dart-lang/test/blob/master/lib/src/backend/declarer.dart

### Backend

The [`lib/src/backend`][backend] directory contains classes that represent the
in-memory structure of a test suite. A [`Suite`][Suite] represents a single test
file, and class contains a tree of [`Group`][Group]s, each of which contains
many [`Test`][Test]s. These classes are built using a [`Declarer`][Declarer].

[backend]: https://github.com/dart-lang/test/tree/master/lib/src/backend
[Suite]: https://github.com/dart-lang/test/blob/master/lib/src/backend/suite.dart
[Group]: https://github.com/dart-lang/test/blob/master/lib/src/backend/group.dart
[Test]: https://github.com/dart-lang/test/blob/master/lib/src/backend/test.dart

The backend also contains the [`Invoker`][Invoker], which is responsible for
actually running an individual test case—including tracking how many outstanding
asynchronous callbacks are pending, handling exceptions, and timing out the test
if it takes too long. The `Invoker` provides information about the status of a
running test as streams and futures on a [`LiveTest`][LiveTest] object.

[LiveTest]: https://github.com/dart-lang/test/blob/master/lib/src/backend/live_test.dart

The backend provides a bridge between the frontend and the runner. The runner
sets up the `Declarer` and starts the `Invoker`, which the frontend functions
then communicate with directly.

### Runner

The [`lib/src/runner`][runner] directory contains the code that's executed when
`dart test` is invoked. It's in charge of locating test files, loading them,
executing them, and communicating their results to the user. It's also by far
the biggest section. For more information on the runner architecture, see
[Lifecycle of a Test Run](#lifecycle-of-a-test-suite) below.

[runner]: https://github.com/dart-lang/test/tree/master/lib/src/runner

## Lifecycle of a Test Run

To understand generally how the test runner works, let's look at an example run.
When the user first invokes `dart test`, the command-line arguments and
[configuration files][] are combined into a single
[`Configuration`][Configuration] object which is passed into the
[`Runner`][Runner] class. The `Runner` is mostly just glue: it starts up the
various components necessary for a test run, and connects them to one another.
It's also in charge of handling certain `Configuration` flags.

[configuration files]: https://github.com/dart-lang/test/blob/master/doc/configuration.md
[Configuration]: https://github.com/dart-lang/test/tree/master/lib/src/runner/configuration.dart
[Runner]: https://github.com/dart-lang/test/tree/master/lib/src/runner.dart

The first thing the runner starts is the [`Engine`][Engine]. The engine iterates
through a test suite's tests and invokes them in order. It knows how to handle
set-up and tear-down functions, and how to combine the output of multiple test
suites running concurrently. It exposes its progress through a collection of
getters and streams that provide access to individual [`LiveTest`][LiveTest]s.

[Engine]: https://github.com/dart-lang/test/tree/master/lib/src/runner/engine.dart

The runner then passes the `Engine` to a [`Reporter`][Reporter], which listens
to the `Engine`'s streams and exposes the information there to the user, usually
by printing human-readable text. [`CompactReporter`][CompactReporter] is the
default on Posix platforms, but others may be selected based on the
`Configuration`. Nearly everything the user sees comes through the reporter.
[Reporter]: https://github.com/dart-lang/test/tree/master/lib/src/runner/reporter.dart
[CompactReporter]: https://github.com/dart-lang/test/tree/master/lib/src/runner/reporter/compact.dart

The `Engine` and `Reporter` can't do much of anything, though, without any test
suites to run. The next step is to load those suites. The [`Loader`][Loader] is
in charge of this part. It takes in file or directory paths and finds all the
test files they contain—by default any files matching `*_test.dart`. It then
proceeds to load each file on all the platforms specified in the `Configuration`
that's also supported by the test suite.

[Loader]: https://github.com/dart-lang/test/tree/master/lib/src/runner/loader.dart

The specifics of loading suites differs based on whether the platform is a
browser or the Dart VM. I'll cover each platform below, but for now let's stick
to what they have in common. Every platform will emit a
[`LoadSuite`][LoadSuite], which is a synthetic [`Suite`][Suite] containing a
single test that, when invoked, produces the actual `Suite` defined in the test
file.

[LoadSuite]: https://github.com/dart-lang/test/tree/master/lib/src/runner/load_suite.dart

Wrapping the loading process in a synthetic `Suite` gives us the very useful
invariant that *all test errors occur within a `Suite`*. Loading can fail in all
sorts of ways—the code might not compile, the `main()` method might throw, the
browser might not be installed, and so on. Locating those errors within a
`Suite` means that the `Engine` and `Reporter`, which already know how to deal
with test errors, can deal with load errors in exactly the same way. It makes
the load process a little more complex, but it makes everything else a lot
cleaner.

Once a `Suite` has been loaded, the runner does a little post-processing to make
sure the `Configuration` is handled properly. It filters out tests whose tags
don't match the `--tags` flag, or whose names don't match the `--name` flag.
Then it passes the resulting `Suite`s on to the `Engine` and they begin to run.

### Loading a Suite on the VM

Let's start with looking at how suites are loaded on the Dart VM, since the
process is substantially simpler than loading them on a browser. This loading is
handled by the [`VMPlatform`][VMPlatform], which extends the
[`PlatformPlugin`][PlatformPlugin] class. [Eventually][issue 49], we plan to
support a user-accessible platform plugin API, so we model platforms as plugins
to prepare for that.

[VMPlatform]: https://github.com/dart-lang/test/tree/master/lib/src/runner/vm/platform.dart
[PlatformPlugin]: https://github.com/dart-lang/test/tree/master/lib/src/runner/plugin/platform.dart
[issue 49]: https://github.com/dart-lang/test/issues/49

In its simplest form, a `PlatformPlugin`'s responsibility is just to create a
[`StreamChannel`][StreamChannel] that connects the test runner to a remote
isolate—everything else is handled by helper functions. The `VMPlatform` uses
[`Isolate`][Isolate]s to dynamically load its test suites, and then communicates
with them using an [`IsolateChannel`][IsolateChannel]. It passes in a `data:`
URI containing Dart code that imports the user's code, and runs that code in the
context of the [`serializeSuite()`][remote platform helpers] helper, and the
`PlatformPlugin` superclass deserializes it on the other side using
[`deserializeSuite()`][platform helpers].

[StreamChannel]: https://pub.dev/packages/stream_channel
[Isolate]: https://api.dart.dev/stable/dart-isolate/Isolate-class.html
[IsolateChannel]: https://pub.dev/documentation/stream_channel/latest/stream_channel/IsolateChannel-class.html
[remote platform helpers]: https://github.com/dart-lang/test/tree/master/lib/src/runner/plugin/remote_platform_helpers.dart
[platform helpers]: https://github.com/dart-lang/test/tree/master/lib/src/runner/plugin/platform_helpers.dart

When a test suite is serialized and deserialized, it's not just converted to and
from some static representation like JSON. The [`Engine`][Engine] needs
fine-grained control over the remote suite, and the [`Reporter`][Reporter] needs
fine-grained access to the [`LiveTest`][LiveTest]s it emits. To make this work,
the helper functions use the [`MultiChannel`][MultiChannel] class to tunnel
streams for each test through the main `IsolateChannel`. Each test has its own
virtual channel that gets a message when the test runner calls
[`Test.load()`][Test], and that sends messages back to indicate the progress of
the test.

Information about these virtual channels, as well as test names and metadata,
are bundled up into a JSON object and sent over the `IsolateChannel` to be
deserialized. The deserialization process then converts them into
[`RunnerTest`][RunnerTest]s within a [`RunnerSuite`][RunnerSuite], which the
`Engine` can then run just like normal `Test`s in a normal [`Suite`][Suite].

[MultiChannel]: https://pub.dev/documentation/stream_channel/latest/stream_channel/MultiChannel-class.html
[RunnerTest]: https://github.com/dart-lang/test/tree/master/lib/src/runner/runner_test.dart
[RunnerSuite]: https://github.com/dart-lang/test/tree/master/lib/src/runner/runner_suite.dart

### Loading a Suite in the Browser

The [`BrowserPlatform`][BrowserPlatform] class also extends
[`PlatformPlugin`][PlatformPlugin], but rather than just emitting a
[`StreamChannel`][StreamChannel] and letting the plugin helpers do the rest, it
takes more control over the loading process. It emits its own
[`RunnerSuite`][RunnerSuite], which allows it to expose its own
[`Environment`][Environment] to enable debugging.

[BrowserPlatform]: https://github.com/dart-lang/test/tree/master/lib/src/runner/browser/platform.dart
[Environment]: https://github.com/dart-lang/test/tree/master/lib/src/runner/environment.dart

Whereas the [`VMPlatform`][VMPlatform] loads each separate suite in isolation,
the `BrowserPlatform` shares a substantial amount of resources between suites.
All suites load their code from a single HTTP server, which is managed by the
platform. This server provides access to compiled JavaScript for other browsers,
and to HTML files that bootstrap the tests.

In addition to sharing a server, when multiple suites are loaded for the same
browser, they all share a tab within that browser. Each separate browser is
controlled by its own [`BrowserManager`][BrowserManager], which uses
`WebSocket`s to communicate with Dart code running in the main frame—also known
as [the host][host].

[BrowserManager]: https://github.com/dart-lang/test/tree/master/lib/src/runner/browser/browser_manager.dart
[host]: https://github.com/dart-lang/test/tree/master/lib/src/runner/browser/static/host.dart

Each browser is spawned with a tab pointing to
`packages/test/src/runner/browser/static/index.html`, the host page. The host's
code then opens a `WebSocket` connection to a dynamically-generated URL. This
URL tells the `BrowserPlatform` which `BrowserManager` to send the `WebSocket`
to.

To load a suite for this browser, the `BrowserPlatform` passes the URL for that
suite's HTML file to the `BrowserManager`, which in turn sends it down to the
host page. The host opens this HTML in an iframe, opens a
[`StreamChannel`][StreamChannel] with this iframe using
[`Window.postMessage()`][Window.postMessage]. It then tunnels this channel
through the `WebSocket` connection, again using [`MultiChannel`][MultiChannel],
so that the `BrowserManager` has a direct line to the iframe where the tests are
defined.

[Window.postMessage]: https://api.dart.dev/stable/dart-html/Window/postMessage.html

From this point forward the process is similar to `VMPlatform`. The iframe
serializes its test suite using [`serializeSuite()`][remote platform helpers],
and the `BrowserManager` deserializes it using
[`deserializeSuite()`][platform helpers]. It's then forwarded to the `Loader`
via the `BrowserPlatform`.
