## What's `felt`?
`felt` stands for "Flutter Engine Local Tester". It's a cli tool that aims to make development in the Flutter web engine more productive and pleasant.

## What can `felt` do?
`felt` supports multiple commands as follows:

1. **`felt check-licenses`**: Checks that all Dart and JS source code files contain the correct license headers.
2. **`felt test`**: Runs all or some tests depending on the passed arguments.
3. **`felt build`**: Builds the engine locally so it can be used by Flutter apps. It also supports a watch mode for more convenience.

You could also run `felt help` or `felt help <command>` to get more information about the available commands and arguments.

## How can I use `felt`?
Once you have your local copy of the engine [setup](https://github.com/flutter/flutter/wiki/Setting-up-the-Engine-development-environment), you'll need to add `/path/to/engine/src/flutter/lib/web_ui/dev` to your `PATH`.
Then you would be able to use the `felt` tool from anywhere:
```
felt check-licenses
```
or:
```
felt build --watch
```
