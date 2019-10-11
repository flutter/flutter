## What's `felt`?
`felt` stands for "Flutter Engine Local Tester". It's a cli tool that aims to make development in the Flutter web engine more productive and pleasant.

## What can `felt` do?
`felt` supports multiple commands as follows:

1. **`felt check-licenses`**: Checks that all Dart and JS source code files contain the correct license headers.
2. **`felt test`**: Runs all or some tests depending on the passed arguments.
3. **`felt build`**: Builds the engine locally so it can be used by Flutter apps. It also supports a watch mode for more convenience.

You could also run `felt help` or `felt help <command>` to get more information about the available commands and arguments.

## How can I use `felt`?
Once you have your local copy of the engine [setup](https://github.com/flutter/flutter/wiki/Setting-up-the-Engine-development-environment), it's recommended that you add `/path/to/engine/src/flutter/lib/web_ui/dev` to your `PATH`.
Then you would be able to use the `felt` tool from anywhere:
```
felt check-licenses
```
or:
```
felt build --watch
```

If you don't want to add `felt` to your path, you can still invoke it using a relative path like `./web_ui/dev/felt <command>`

## Running web engine tests
To run all tests:
```
felt test
```

To run a single test:
```
felt test test/golden_tests/engine/canvas_golden_test.dart
```

To debug a test:
```
felt test --debug test/golden_tests/engine/canvas_golden_test.dart
```

## Configuration files

`chrome_lock.yaml` contains the version of Chrome we use to test Flutter for
web. Chrome is not automatically updated whenever a new release is available.
Instead, we update this file manually once in a while.

`goldens_lock.yaml` refers to a revision in the https://github.com/flutter/goldens
repo. Screenshot tests are compared with the golden files at that revision.
When making engine changes that affect screenshots, first submit a PR to
flutter/goldens updating the screenshots. Then update this file pointing to
the new revision.
