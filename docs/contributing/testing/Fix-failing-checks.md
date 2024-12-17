![Some checks were not successful](https://github.com/user-attachments/assets/95fd56e9-4839-4944-b9ac-cc45404896a2)

# How to fix a PR's failing checks

<br>

### tree-status

![Tree is currently broken.](https://github.com/user-attachments/assets/b611d540-c4cb-47dc-a27f-bef8709f24ce)

Unlike other checks, **tree-status** isn't tied to the pull request:
instead, it shows whether checks are passing in the main branch.\
Failures can happen for a variety of reasons and should be addressed
before anything else is merged in.

**What to do:** Once [review requirements](../Tree-hygiene.md#getting-a-code-review)
are met and all other checks are passing, a reviewer will add the
[**`autosubmit`**](../../infra/Landing-Changes-With-Autosubmit.md) label,
and then a bot will merge the PR once **tree-status** succeeds.

<br>

### Google testing

![Google testing](https://github.com/user-attachments/assets/7d1f9a66-b84a-4223-b57d-77b44f205d1c)

A Google testing failure could be a flake ([see below](#flaking)), or it
might be due to changes in the PR (See
[Understanding Google Testing](../../infra/Understanding-Google-Testing.md)
for more info).
Google employees can view the test output and give feedback accordingly.

**What to do:** If 2 weeks have gone by and nobody's looked into it,
feel free to [reach out on Discord](../Chat.md).

<br>

### ci.yaml validation

![ci.yaml validation](https://github.com/user-attachments/assets/545a55f8-5bde-460f-92dd-9d87788f9fe8)

In order for checks to run correctly, the [.ci.yaml](../../../.ci.yaml)
file needs to stay in sync with the base branch.

**What to do:** This check failure can be fixed by applying the latest changes
from master.\
(The [Tree hygiene](../Tree-hygiene.md#using-git) page recommends updating
via rebase, rather than a merge commit.)

![Update with rebase](https://github.com/user-attachments/assets/8bacd87f-410a-4a9c-8ad0-075dd05f3eff)

<br>

## A bug in the PR

Oftentimes, a change inadvertently breaks expected behavior.\
When this happens, usually the best way to find out what's wrong is to
[**view the test output**](#view-the-test-output).

If a **customer_testing** check is unsuccessful, it's a signal that something in the
[Flutter customer test registry](https://github.com/flutter/tests/) has failed.
This includes [package tests](../../ecosystem/testing/Understanding-Packages-tests.md)
along with other tests from open-source Flutter projects.\
If a pull request requires an update to those external tests, it qualifies as a
[**breaking change**](../Tree-hygiene.md#handling-breaking-changes);
please avoid those when possible.

If **Linux Analyze** fails, it's likely that one or more changes in the PR
violated a [linter rule](https://dart.dev/lints/).\
Consider reviewing the steps outlined in
[setting up the framework dev environment](../../Setting-up-the-Framework-development-environment.md)
so that most of these problems get caught in static analysis right away.

> [!NOTE]
> All Dart code is run through static analysis:
> this includes markdown code snippets in doc comments!
>
> See [Hixie's Natural Log](https://ln.hixie.ch/?start=1660174115) for more details.

<br>

### View the test output

Click on **Details** for the failing test, and then click
**View more details on flutter-dashboard**.

![view more details](https://github.com/user-attachments/assets/df667176-205f-42b2-8997-885c50ab238d)

The full test output is linked at the bottom of the page.

![LUCI overview page](https://github.com/user-attachments/assets/9603c6ad-90ec-47e1-96e8-9e3430f2c1b8)

<br>

Often, there will be a message that resembles the one below:

```
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text
"AsyncSnapshot<String>(ConnectionState.waiting, null, null, null)": []>
   Which: means none were found but one was expected

When the exception was thrown, this was the stack:
#4      main.<anonymous closure>.<anonymous closure> (…/packages/flutter/test/widgets/async_test.dart:115:7)
<asynchronous suspension>
#5      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:189:15)
<asynchronous suspension>
#6      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1032:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

This was caught by the test expectation on the following line:
  file:///b/s/w/ir/x/w/flutter/packages/flutter/test/widgets/async_test.dart line 115
The test description was:
  gracefully handles transition from null future
════════════════════════════════════════════════════════════════════════════════════════════════════
```

From there, it's just a matter of finding the failing test,
[running it locally](./Running-and-writing-tests.md),
and figuring out how to fix it!

<br>

### Flaking

A check might "flake", or randomly fail, for a variety of reasons.

Sometimes a flake resolves itself after changes are pushed to re-trigger
the checks. Consider [performing a rebase](#ciyaml-validation) to include
the latest changes from the main branch.

Flakes often happen due to **infra errors**.
For information on how to view and report infrastructure bugs, see the
[infra failure overview](../../infra/Understanding-a-LUCI-build-failure.md#overview-of-an-infra-failure-build).
