## Updating pigeon-generated files

If you update files in the pigeons/ directory, run the following
command in this directory (ignore the errors you get about
dependencies in the examples directory):

```bash
flutter pub upgrade
flutter pub run pigeon --dart_null_safety --input pigeons/messages.dart
# git commit your changes so that your working environment is clean
(cd ../../../; ./script/tool_runner.sh format --clang-format=clang-format-7)
```

If you update pigeon itself and want to test the changes here,
temporarily update the pubspec.yaml by adding the following to the
`dependency_overrides` section, assuming you have checked out the
`flutter/packages` repo in a sibling directory to the `plugins` repo:

```yaml
  pigeon:
    path:
      ../../../../packages/packages/pigeon/
```

Then, run the commands above. When you run `pub get` it should warn
you that you're using an override. If you do this, you will need to
publish pigeon before you can land the updates to this package, since
the CI tests run the analysis using latest published version of
pigeon, not your version or the version on master.

In either case, the configuration will be obtained automatically from
the `pigeons/messages.dart` file (see `configurePigeon` at the bottom
of that file).
