# Devtools

Unopinionated tools for **running**, **debugging** and **testing** Mojo apps.

## Repo contents

Devtools offer the following tools:

 - **mojo_shell** - universall shell runner
 - **debugger** - supports interactive tracing and debugging of a running mojo shell
 - **remote_adb_setup** - configures adb on a remote machine to communicate with
   a device attached to the local machine

and a Python scripting library designed for being embedded (devtoolslib).

### Devtoolslib

**devtoolslib** is a Python module containing the core scripting functionality
for running Mojo apps: shell abstraction with implementations for Android and
Linux and support for apptest frameworks. The executable scripts in devtools
are based on this module.

As devtools carry no assumptions about build system or file layout being used,
one can choose to embed the functionality provided by **devtoolslib** in their
own wrapper, instead of relying on the provided scripts. For examples, one can
refer to mojo's [apptest
runner](https://github.com/domokit/mojo/blob/master/mojo/tools/apptest_runner.py).

## Install

```
git clone https://github.com/domokit/devtools.git
```

## Development

The library is canonically developed [in the mojo
repository](https://github.com/domokit/mojo/tree/master/mojo/devtools/common),
https://github.com/domokit/devtools is a mirror allowing to consume it
separately.
