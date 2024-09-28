Further documentation on Flutter's build infrastructure can be found in <https://github.com/flutter/flutter/blob/main/dev/bots/README.md>.

## Requirements for a Flutter/LUCI build

A general outline of the requirements that a Flutter CI test shard has:

1. On LUCI, test shards map to builders. Each test shard must have its own LUCI builder. For the Framework, these are defined in [framework_config.star](https://flutter.googlesource.com/infra/+/refs/heads/main/config/framework_config.star). Generally you will need to have both a pre-submit ("try" in LUCI terminology) builder and a post-submit ("prod") builder.
1. This LUCI builder will specify a "recipe" to run. These are [starlark](https://github.com/bazelbuild/starlark) scripts that determine the actual CI steps to run, and are defined in [flutter.googlesource.com/recipes](https://flutter.googlesource.com/recipes). Most Framework tests use the [flutter/flutter_drone.py](https://flutter.googlesource.com/recipes/+/refs/heads/main/recipes/flutter/flutter_drone.py) recipe. To learn how to edit these, see <https://github.com/flutter/flutter/blob/main/dev/bots/README.md#editing-a-recipe>.
1. Builders are then added to [.ci.yaml](https://github.com/flutter/flutter/blob/main/.ci.yaml). These files are read by [Flutter's build dashboard](https://flutter-dashboard.appspot.com/#/build), and are used for scheduling builds.

## Steps to add a new Framework Test Shard

It is important to land these changes in order to prevent any failing builds during the migration period:

1. Framework tests are run by a Dart test runner called [test.dart](https://github.com/flutter/flutter/blob/main/dev/bots/test.dart) that lives in the framework repository. Any new test shards must first be added to this file. Merge this framework change. Note that sharding an existing test doesn't need to update test.dart.
1. Update [.ci.yaml](https://github.com/flutter/flutter/blob/main/.ci.yaml) in the Framework tree to include the newly added builder following [CI_YAML.md](https://github.com/flutter/cocoon/blob/main/CI_YAML.md#adding-new-targets). Ensure that the "shard" and "subshard"/"subshards" properties match what was added to test.dart in the previous step. Verify that the entry is marked as `bringup: true`. New shards should always be marked in bringup to verify they are passing on master before being able to block the tree. Merge this change. Note that the new shard will not run in presubmit at this point as the target is with `bringup: true`.
1. Monitor the CI results of the new shard on the [Flutter build dashboard](https://flutter-dashboard.appspot.com/#/build). After 50 consecutive passing builds without any flakes, the flake bot will create a PR to remove the `bringup: true` parameter from `.ci.yaml` in the Framework tree. This will allow the test to block the tree, preventing breakages. With this change, the new shard will start running in presubmit automatically, unless specify `presubmit: false`. Note the flake bot runs once a week on Weds.

Note: if a new post-submit target is renamed from an existing target, there is no need to follow the bringup process.