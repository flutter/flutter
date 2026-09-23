# Running DeviceLab Tests For a PR

From time to time you might find yourself needing to run a post-submit test
in a PR.  Maybe you landed a PR with clean pre-submits, but the dashboard
ended up red. Maybe you are trying to deflake a test and just need to run it
a few times before landing. Here's how you do that.

> [!Warning]
> Ensure you have followed the prerequisites in [dev/bots/README.md](../../dev/bots/README.md)

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
