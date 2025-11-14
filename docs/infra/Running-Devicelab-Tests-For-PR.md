# Running DeviceLab Tests For a PR

From time to time you might find yourself needing to run a post-submit test
in a PR.  Maybe you landed a PR with clean pre-submits, but the dashboard
ended up red. Maybe you are trying to deflake a test and just need to run it
a few times before landing. Here's how you do that.

> [!Warning]
> Ensure you have followed the prerequisites in [dev/bots/README.md](../../dev/bots/README.md)

## Engine PRs

Engine artifacts for PRs are uploaded using their _commit hash_, not their _content hash_. Failing to follow these steps will cause the tests to be run against post-submit artifacts which will **likely not exist** for your PR since the content hash is different.

1. Make your changes locally and upload to a PR.

2. Wait for infrastructure to build the engine artifacts for you - e.g. `Mac mac_ios_engine` and `Mac mac_host_engine` like builds.

    > [!TIP]
    > If your PR "Checks" is over ~180, the engine artifacts are built for you. Check [`engine/src/flutter/.ci.yaml`](../../engine/src/flutter/.ci.yaml)
    > for the latest artifacts.

3. Collect the following:

    1. `COMMIT_HASH` for the latest version of the engine build of your PR
    2. `PR_NUMBER`
    3. The `PRESUBMIT_TEST` you want to run (full name, e.g. `Windows_mokey hot_mode_dev_cycle_win__benchmark`)

4. From the recipes repository check out, run:

    ```shell
    led get-builder 'luci.flutter.staging:PRESUBMIT_TEST' \
    | led edit -pa git_ref='refs/pull/PR_NUMBER/head' \
    | led edit -pa git_url='https://github.com/flutter/flutter' \
    | led edit -pa flutter_prebuilt_engine_version='COMMIT_HASH' \
    | led edit -pa flutter_realm='flutter_archives_v2' \
    | led edit-recipe-bundle \
    | led launch
    ```

## Framework PRs

For Framework PRs, the process is simpler:

1. Collect the following:

    1. `PR_NUMBER`
    2. The `PRESUBMIT_TEST` you want to run (full name, e.g. `Windows_mokey hot_mode_dev_cycle_win__benchmark`)

2. From the recipes repository check out, run:

    ```shell
    led get-builder 'luci.flutter.staging:PRESUBMIT_TEST' \
    | led edit -pa git_ref='refs/pull/PR_NUMBER/head' \
    | led edit -pa git_url='https://github.com/flutter/flutter' \
    | led edit-recipe-bundle \
    | led launch
    ```
