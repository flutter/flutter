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

### Debugger

The `mojo_debug` script allows you to interactively inspect a running shell,
collect performance traces and attach a gdb debugger.

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

#### Android crash stacks
When Mojo shell crashes on Android ("Unfortunately, Mojo shell has stopped.")
due to a crash in native code, `mojo_debug` can be used to find and symbolize
the stack trace present in the device log:

```sh
mojo_debug device stack
```

### devtoolslib

**devtoolslib** is a Python module containing the core scripting functionality
for running Mojo apps: shell abstraction with implementations for Android and
Linux and support for apptest frameworks. The executable scripts in devtools are
based on this module. One can also choose to embed the functionality provided by
**devtoolslib** in their own wrapper.

## Development

The library is canonically developed [in the mojo
repository](https://github.com/domokit/mojo/tree/master/mojo/devtools/common),
https://github.com/domokit/devtools is a mirror allowing to consume it
separately.
