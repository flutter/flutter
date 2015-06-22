Hacking on Sky
==============

Building
--------

* Follow the setup & build instructions for [Mojo](https://github.com/domokit/mojo)

The build directory will be `out/Debug` for Linux debug builds, and
`out/Release` for Linux release builds. For Android builds, prefix
`android_`, as in, `android_Debug`.

Running applications
--------------------

To run an application on your device, run:

* ``./mojo/tools/mojodb start out/android_Debug [url]``

`mojodb` has numerous commands, visible via `mojodb help`.  Common ones include:
* `mojodb start` BUILD_DIR [url]
* `mojodb load` [url]
* `mojodb stop`
* `mojodb start_tracing` # Starts recoding a performance trace (use stop_tracing to stop)
* `mojodb print_crash` # Symbolicate the most recent crash from android.

Once `mojodb start` is issued, all subsequent commands will be sent to
the running mojo_shell instance (even on an attached android device).
`mojodb start` reads gn args from the passed build directory to
determine whether its using android, for example.

Running tests
-------------

Tests are only supported on Linux currently.

* ``./sky/tools/test_sky --debug``
  * This runs the tests against ``//out/Debug``. If you want to run against
    ``//out/Release``, omit the ``--debug`` flag.

Running tests manually
----------------------

Running tests manually lets you more quickly iterate during
development; rather than having to compile and rerun all the tests,
then trawl through the build output to find the current results, you
can just run the test you're working on and reload it over and over,
seeing the output right there on your console.

* ``sky/tools/skygo/linux64/sky_server -v -p 8000 out/Debug out/Debug/gen/dart-pkg/packages``
* ``out/Debug/mojo_shell --args-for="mojo:native_viewport_service --use-headless-config --use-osmesa" --args-for"=mojo:sky_viewer --testing" --content-handlers=application/dart,mojo:sky_viewer --url-mappings=mojo:window_manager=mojo:sky_tester,mojo:surfaces_service=mojo:fake_surfaces_service mojo:window_manager``
* The ``sky_tester`` should print ``#READY`` when ready
* Type the URL you wish to run, for example ``http://127.0.0.1:8000/sky/tests/widgets/dialog.dart``, and press the enter key
* The harness should print the results of the test.  You can then type another URL.

Writing tests
-------------

We recommend using the [Dart
``test``](https://pub.dartlang.org/packages/test) testing framework.
See [``sky/tests/raw/color_bounds.dart``](tests/raw/color_bounds.dart)
for an example.

Debugging Sky
-------------

This document aims to explain how to debug Sky itself.

=== C++

Launch a debug Sky build on Linux as follows (where `app.dart` is the
test you are running and trying to debug):

```bash
mojodb start --gdb out/Debug app.dart
mojodb gdb_attach
```

=== Dart

Use Observatory.
