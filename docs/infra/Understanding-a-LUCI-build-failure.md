Most tests have been running in Flutter CI [LUCI](https://github.com/flutter/flutter/tree/main/dev/bots#luci-layered-universal-continuous-integration) for multiple flutter repositories, including [post-submit framework](https://flutter-dashboard.appspot.com/#/build), [pre-submit framework](https://ci.chromium.org/p/flutter/g/framework-try/builders), etc. This page uses framework as an example, and talks about what to do when a LUCI build failure happens.

## Build dashboards
* [Flutter build dashboard](https://flutter-dashboard.appspot.com/#/build)
* [LUCI Milo dashboard](https://ci.chromium.org/p/flutter)

## Infra Failure
An infra failure comes with network connection issues, hardware outage, recipe breakage, cipd dependency issues, etc. It shows up as a purple box in the dashboards:

* Framework post-submit build dashboard: ![three green squares, a purple square, and four green squares, representing build results](https://github.com/flutter/assets-for-api-docs/blob/main/assets/wiki/luci_post_submit_infra_failure.png)
* Framework pre-submit build console: ![one green rectangle, a purple rectangle, and one more green rectangle, representing build results](https://github.com/flutter/assets-for-api-docs/blob/main/assets/wiki/luci_pre_submit_infra_failure.png)

### Overview of an infra failure build
An example build: [Linux color_filter_and_fade_perf__e2e_summary](https://ci.chromium.org/ui/p/flutter/builders/prod/Linux%20color_filter_and_fade_perf__e2e_summary/1563/overview)

<img src="https://raw.githubusercontent.com/wiki/flutter/flutter/images/luci_infra_failure_overview.png" align="center" height="450" width="800"/>

*  (i) Link to the historical build list of this builder
*  (ii) A quick glimpse of the infra failure
*  (iii) The step list of this builder, defined by the recipe on the right
*  (iv) The real failed step causing the build failure
*  (v) Check `stdout` for detailed log

### What to do
1. Check if the infra failure has happened on earlier builds by clicking (i)
2. Check if issue already exists in the [infra bug pool](https://github.com/flutter/flutter/issues?q=is%3Aopen+is%3Aissue+label%3A%22team%3A+infra%22)
3. If not, file [an infra bug](https://github.com/flutter/flutter/issues/new?template=6_infrastructure.yml)
4. If this is a blocking failure, please add Projects [`Infra Ticket Queue`](./Infra-Ticket-Queue.md). The infra gardener will scan through the queue frequently.
5. If you want to get an immediate help, please ask in the discord `hackers-infra` channel
6. If this is an infra flake, and a retry is needed
   *  For pre-submit test, click `Re-run` in the [check run page](https://github.com/flutter/flutter/pull/83894/checks?check_run_id=2738146673). ![The presubmit rerun interface](https://github.com/flutter/assets-for-api-docs/blob/main/assets/wiki/luci_pre_submit_rerun.png)
      * Limited to `flutter-hackers` group.
      * Ask a team member to re-run in [Chat](../contributing/Chat.md) channel `#hackers-infra` if you don't have access.
   *  For post-submit test, login to [framework build dashboard](https://flutter-dashboard.appspot.com/#/build), click the task box, and click `RERUN`. ![The post submit rerun interface](https://github.com/flutter/assets-for-api-docs/blob/main/assets/wiki/luci_post_submit_rerun.png)
      * Limited to Googlers currently due to some technical limitations of our infrastructure.
      * Ask a Googler to re-run in [Chat](../contributing/Chat.md) channel `#hackers-infra`.

## Test Failure
A test failure shows up as a red box in the dashboards:

* Framework post-submit build dashboard: ![two green squares, a red square, and three green squares, representing build results](https://github.com/flutter/assets-for-api-docs/blob/main/assets/wiki/luci_post_submit_test_failure.png)
* Framework pre-submit build console: ![two green squares, a red square, and two green squares, representing build results](https://github.com/flutter/assets-for-api-docs/blob/main/assets/wiki/luci_pre_submit_test_failure.png)

### Overview of a test failure build
Please refer to the above example of the infra failure.

### What to do
1. Check if it happens in earlier builds/commits via (i)
2. Debug based on the error message (ii) and detailed log (v) to see if a real test failure caused by code changes.
3. Check if the issue already exists in the [issues list](https://github.com/flutter/flutter/issues)
4. Check if a flaky bug has been filed in [the flaky issues list](https://github.com/flutter/flutter/issues?q=is%3Aopen+is%3Aissue+label%3A%22c%3A+flake%22)
5. File a new bug if needed
6. If a rerun is needed, please refer to step 6 in the above infra failure session.

See also: [How to fix a PR's failing checks](../contributing/testing/Fix-failing-checks.md)
