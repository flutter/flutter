# User config paths and variables

When running dart script from an IDE where you might not always (or want to) control the user environment variables
and binary paths.

You can set a global environment in an external file that will called the **User environment file** a `env.yaml` file in 
YAML format located

- `~/.config/tekartik/process_run/env.yaml` on Mac/Linux
- `%APPDATA%\tekartik\process_run\env.yaml` on Windows.

You might want to get a password to use as a parameter and have a path available to find the proper executables.

Experimental: You can edit the environment file on Mac/Linux/Windows using the following
command:

```
pub run process_run:shell edit-env
```

## Add a binary path

`env.yaml`:
```yaml
path:
  - ~/.android/bin
  - ~/.firebase/tools/bin
  - /home/user/Apps/bin
```

These paths will be automatically tried to find relative executable binaries?

## Add environment variables

`env.yaml`:
```yaml
var:
  ANDROID_TOP: ~/.android
  FLUTTER_BIN: ~/.flutter/bin
  MY_PROJECT_ID: WKDL_456_Q;
```

These added environment variable will be available in the `userEnvironment` map. It must be explicitely used as the
`environment` argument in the `run` methods to get used by the callee.

## Sample file

`~/.config/tekartik/process_run/env.yaml`:
```yaml
path:
  - ~/.android/bin
  - ~/.firebase/tools/bin
  - /home/user/Apps/bin
var:
  ANDROID_TOP: ~/.android
  FLUTTER_BIN: ~/.flutter/bin
  MY_PROJECT_ID: WKDL_456_Q;
```

## Global configuration

System env path location could be overriden using