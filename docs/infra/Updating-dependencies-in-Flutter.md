Instead of manually updating dependencies in a `pubspec.yaml` file, use the [`update-packages`](/packages/flutter_tools/lib/src/commands/update_packages.dart) CLI tool:

## To update all dependencies:

`flutter update-packages --force-upgrade`

## To pin a dependency:

Sometimes you need to prevent a dependency from being updated when you run `flutter update-packages --force-upgrade`.

In that case, first pin the dependency in [`kManuallyPinnedDependencies`](/packages/flutter_tools/lib/src/update_packages_pins.dart) and include a comment with a link to an issue to unpin the dependency.

You can then re-run `flutter update-packages --force-upgrade`.

## To update a single dependency for cherrypicks:

Sometimes you need to update a single dependency as a [cherrypick to a release candidate branch](../releases/Flutter-Cherrypick-Process.md).

In that case, you can run:

`flutter update-packages --cherry-pick=[pub package name]:[pub package version],[pub package2 name]:[pub package2 version]`

for example, to update the `test` dependencies, run
`flutter update-packages --cherry-pick=test_api:0.7.6,test_core:0.6.10,test:1.26.1`
