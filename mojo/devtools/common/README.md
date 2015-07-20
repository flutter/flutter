# Devtools

Unopinionated tools for **running**, **debugging** and **testing** Mojo apps.

## Install

```
git clone https://github.com/domokit/devtools.git
```

## Contents

Devtools offers the following tools:

 - `mojo_shell` - universal shell runner
 - `debugger` - supports interactive tracing and debugging of a running mojo
   shell
 - `remote_adb_setup` - configures adb on a remote machine to communicate with
   a device attached to the local machine

and a Python scripting library designed for being embedded (`devtoolslib`).

### debugger

The `debugger` script allows you to interactively inspect a running shell,
collect performance traces and attach a gdb debugger.

#### Tracing
To collect [performance
traces](https://www.chromium.org/developers/how-tos/trace-event-profiling-tool)
and retrieve the result:

```sh
debugger tracing start
debugger tracing stop [result.json]
```

The trace file can be then loaded using the trace viewer in Chrome available at
`about://tracing`.

#### GDB
It is possible to inspect a Mojo Shell process using GDB. The `debugger` script
can be used to launch GDB and attach it to a running shell process (android
only):

```sh
debugger gdb attach
```

#### Android crash stacks
When Mojo shell crashes on Android ("Unfortunately, Mojo shell has stopped.")
due to a crash in native code, `debugger` can be used to find and symbolize the
stack trace present in the device log:

```sh
debugger device stack
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
