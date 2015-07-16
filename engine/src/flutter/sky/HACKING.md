Hacking on Sky
==============

Building
--------

* Follow the setup & build instructions for [Mojo](https://github.com/domokit/mojo)

The build directory will be `out/Debug` for Linux debug builds, and
`out/Release` for Linux release builds. For Android builds, prefix
`android_`, as in, `android_Debug`.

For Sky on iOS, you can try following these [experimental instructions](https://docs.google.com/document/d/1qm8Vvyz8Mngw6EsSg4FELQ7FOegjBJ5Itg9OBJGN5JM/edit#heading=h.ikz9bdwswdct).

Running applications
--------------------

To run an application on your device, run:

* `mojo/devtools/common/mojo_shell --sky [url] --android`

When the shell is running, `mojo/devtools/common/debugger` allows you to
collect traces, symbolize stack crashes and attach gdb if needed. Refer to the
[documentation](https://github.com/domokit/mojo#debugging-tracing-profiling)
for the details.

Running tests
-------------

Tests are only supported on Linux currently.

* ``sky/tools/test_sky --debug``
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

### C++

Launch a debug Sky build on Android as usual:

```
mojo/devtools/common/mojo_shell --sky [url] --android`
```

and use the debugger to attach gdb:
```
mojo/devtools/common/debugger gdb attach
```

Once gdb has loaded, hit `c` to continue the execution. When your app crashes,
it will pause in the debugger. At that point, regular gdb commands will work:
`n` to step over the current statement, `s` to step into the current statement,
`f` to step out of the current block, `c` to continue until the next breakpoint
or exception.

### Dart

Use Observatory.
