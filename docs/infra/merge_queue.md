## Github Merge Queue

If you are not hacking on flutter/flutter, you can stop reading now.

> [!IMPORTANT]
> **TL;DR** GitHub merge queue will be enabled in the `flutter/flutter` repo, which slightly changes the PR merge process, but you should not notice a change in your workflow.

On Friday November 15th, 2024, GitHub merge queue feature will be enabled in the `flutter/flutter` repo. After this change, pull requests will first need to pass merge queue tests before landing on the target branch (e.g. `main` or `master`). At this time, no additional tests will run in the merge queue. A PR that passes presubmit checks will be allowed to land on the target branch immediately.

---

### What should I expect?

The only visible change will be the merge button. Currently, the button looks like this:

![Squash and merge button](https://github.com/flutter/assets-for-api-docs/blob/main/assets/wiki/squash_merge.png)

With the merge queue, the button will now look like this:

![Merge when ready button](https://github.com/flutter/assets-for-api-docs/blob/main/assets/wiki/merge_ready.png)


Unlike "Squash and merge", the new button does not immediately land the PR on the target branch, but instead enqueues your PR for extra checks in the merge queue. If you do not do anything, eventually your PR will land.

---

### Can I still use autosubmit?

Yes! Feel free to continue using the `autosubmit` label as normal. The bots will run your PR through the merge queue and land it automatically.

If you have an older PR from before this change, `autosubmit` may refuse to merge it. Resync your pull request to resolve this issue.

---

### What's "Remove from queue"? Can I click it?

While your PR is enqueued, Github will show the following button:

![Remove from queue button](https://github.com/flutter/assets-for-api-docs/blob/main/assets/wiki/remove_queue.png)

When you press this button, GitHub will remove your PR from the queue, and the PR will no longer be landed by any automated machinery.

> [!WARNING]
> Please only use this button in case of emergency. Adding and removing your PR from the queue costs in CI resources. Any CI work being done for your PR and all PRs that follow yours will be stopped and restarted.

---

### What if I have questions?

If you have any questions or concerns, or If you suspect you are unable to land your PRs for reasons other than the familiar test failures and flakes, please contact any of: [@yjbanov](https://github.com/yjbanov), [@jtmcdole](https://github.com/jtmcdole), [@christopherfujino](https://github.com/christopherfujino), [@Piinks](https://github.com/piinks).

### Why do we need the merge queue?

The main reason for this change is that `flutter/engine` and `flutter/flutter` repos will be combined into one "monorepo". In order to preserve the current lightweight dev cycle for the framework code, we need to provide pre-built engine artifacts. This way you don't need to compile any C++ code, or install extra tooling (e.g. `depot_tools`), when hacking on the framework alone. The merge queue is what will be building those engine binaries.

The second reason is we want to be able to catch bugs earlier. Currently a PR can land on the target branch if it passes presubmit tests. However, there's no guarantee that those same tests will pass after the PR is combined with other concurrent changes to the code. When the merge queue runs tests, it will run them against combined code changes, discovering bugs from merge conflicts immediately. This should reduce the number of reverts that have to be done on our `main` and `master` branches, keeping the tree green for longer periods of time.
