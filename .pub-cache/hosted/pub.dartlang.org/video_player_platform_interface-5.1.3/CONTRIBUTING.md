## Updating pigeon-generated files

**WARNING**: Because `messages.dart` is part of the public API of this package,
breaking changes in that file are breaking changes for the package. This means
that:
- You should never update the version of Pigeon used for this package unless
  making a breaking change to the package for other reasons.
- Because the method channel is a legacy implementation for compatibility with
  existing third-party `video_player` implementations, in many cases the best
  option may be to simply not implemented new features in
  `MethodChannelVideoPlayer`. Breaking changes in this package should never
  be made solely to change `MethodChannelVideoPlayer`.

### Update process

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
pigeon, not your version or the version on `main`.

In either case, the configuration will be obtained automatically from
the `pigeons/messages.dart` file (see `configurePigeon` at the bottom
of that file).
