# Running Framework presubmit tests on Engine PRs

This documentation describes how to run flutter/flutter presubmit checks on flutter/engine PRs before submitting them.

# Overview

1. Wait for all presubmit checks on your flutter/engine PR to be green.
2. Determine the commit hash for your flutter/engine PR.
3. Create and upload a flutter/flutter PR, (OR run tests locally).
4. Wait for flutter/flutter presubmits/tests to run ☕.

Step (1) is the usual flutter/engine workflow.

# 2. The commit hash

1. Go to the "Commits" tab in the GitHub UI for you Engine PR.
1. Click the button to copy the most recent commit hash to your clipboard.

<img width="1128" alt="Screenshot 2023-08-04 at 12 54 55 PM" src="https://github.com/flutter/flutter/assets/6343103/491be0dd-e29b-4057-a077-3a28d3beec9e">

# 3. Create and upload a flutter/flutter PR.

Edit your flutter/flutter checkout as follows:

1. `bin/internal/engine.version` should be edited to contain the commit hash from (2).
1. `bin/internal/engine.realm` should be edited to contain the string `flutter_archives_v2`.

To run flutter/flutter presubmits on CI, you can accomplish these two edits directly in the GitHub editor UI, if desired. Otherwise, upload a flutter/flutter PR with these changes.

You can also build apps, and run tests locally at this point.

# 4. Wait for flutter/flutter presubmits to run ☕.

The flutter/flutter presubmit checks will run. There will be at least two failures:
1. A Flutter CLI test will ensure that a PR with a non-empty `engine.realm` file will fail a presubmit check.
1. The `fuchsia_precache` test will fail because Fuchsia artifacts are not uploaded from Engine presubmit runs.

Any other failures are possibly due to the changes to flutter/engine, so deflake and examine them carefully.

# 5. Devicelab tests

A subset of devicelab tests are available for optionally running in presubmit on flutter/flutter PRs. They are the tests listed in the flutter/flutter [.ci.yaml](https://github.com/flutter/flutter/blob/main/.ci.yaml) file that are prefixed with `Linux_android`, `Mac_android`, and `Mac_ios`.

To run one of these tests, remove the line `presubmit: false` from the `.ci.yaml` file under the test you'd like to run. For an example, see the PR [here](https://github.com/flutter/flutter/pull/135254).

<img width="1117" alt="Screenshot 2023-09-21 at 3 19 51 PM" src="https://github.com/flutter/flutter/assets/6343103/9d234e82-1d6e-430b-a08e-d70bb9267462">

This will trigger the devicelab test to run. The test will show up in the list of presubmit checks, and you can click through to the [LUCI page](https://ci.chromium.org/ui/p/flutter/builders/try/Linux_android%20new_gallery__transition_perf/2/overview) to see the results.
