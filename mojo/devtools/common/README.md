# Devtools

Unopinionated tools for **running**, **debugging** and **testing** Mojo apps.

## Install

```
git clone https://github.com/domokit/devtools.git
```

## Contents

Devtools offers the following tools:

 - `mojo_run` - shell runner
 - `mojo_test` - apptest runner
 - `mojo_debug` - debugger supporting interactive tracing and debugging of a
   running mojo shell

Additionally, `remote_adb_setup` script helps to configure adb on a remote
machine to communicate with a device attached to a local machine, forwarding the
ports used by `mojo_run`.

### Runner

`mojo_run` allows you to run a Mojo shell either on the host, or on an attached
Android device.

```sh
mojo_run APP_URL  # Run on the host.
mojo_run APP_URL --android  # Run on Android device.
mojo_run "APP_URL APP_ARGUMENTS"  # Run an app with startup arguments
```

Unless running within a Mojo checkout, we need to indicate the path to the shell
binary:

```sh
mojo_run --shell-path path/to/shell/binary APP_URL
```

Some applications are running embedded inside a window manager. To start such an
app, you have to first start the window manager app, then have it embed the app
you are interested in. It is done as follows using the default window manager:

```sh
mojo_run "mojo:window_manager APP_URL"
```

By default, `mojo_run` uses `mojo:kiosk_wm` as the default window manager. It
can be changed using the `--window-manager` flag.

#### Sky apps

To run a [Sky](https://github.com/domokit/sky_engine) app, you need to build
`sky_viewer.mojo` in a Sky checkout, and indicate the path to the binary using
the `--map-url` parameter:

```sh
mojo_run --map-url mojo:sky_viewer=/path/to/sky/viewer "mojo:window_manager APP_URL"
```

If the app does not declare a shebang indicating that it needs to be run in
`sky_viewer`, pass `--sky` to map `sky_viewer` as a default content handler for
dart apps:

```sh
mojo_run --map-url mojo:sky_viewer=/path/to/sky/viewer "mojo:window_manager APP_URL" --sky
```

Note that Sky apps will need the --use-osmesa flag to run
over [chromoting](https://support.google.com/chrome/answer/1649523?hl=en):

### Debugger

`mojo_debug` allows you to interactively inspect a running shell, collect
performance traces and attach a gdb debugger.

#### Tracing
To collect [performance
traces](https://www.chromium.org/developers/how-tos/trace-event-profiling-tool)
and retrieve the result:

```sh
mojo_debug tracing start
mojo_debug tracing stop [result.json]
```

The trace file can be then loaded using the trace viewer in Chrome available at
`about://tracing`.

#### GDB
It is possible to inspect a Mojo Shell process using GDB. The `mojo_debug`
script can be used to launch GDB and attach it to a running shell process
(android only):

```sh
mojo_debug gdb attach
```

Once started, GDB will first stop the Mojo Shell execution, then load symbols
from loaded Mojo applications. Please note that this initial step can take some
time (up to several minutes in the worst case).

After each execution pause, GDB will update the set of loaded symbols based on
the selected thread only. If you need symbols for all threads, use the
`update-symbols` GDB command:
```sh
(gdb) update-symbols
```

If you only want to update symbols for the current selected thread (for example,
after changing threads), use the `current` option:
```sh
(gdb) update-symbols current
```

If you want to debug the startup of your application, you can pass
`--wait-for-debugger` to `mojo_run` to have the Mojo Shell stop and wait to be
attached by `gdb` before continuing.

#### Android crash stacks
When Mojo shell crashes on Android ("Unfortunately, Mojo shell has stopped.")
due to a crash in native code, `mojo_debug` can be used to find and symbolize
the stack trace present in the device log:

```sh
mojo_debug device stack
```

## Development

The library is canonically developed [in the mojo
repository](https://github.com/domokit/mojo/tree/master/mojo/devtools/common),
https://github.com/domokit/devtools is a mirror allowing to consume it
separately.
