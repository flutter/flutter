This page attempts to be a one-stop shop for figuring out what the most important thing to work on is, so that team members (contributors) can determine the more effective way to improve Flutter.

1. Build breakage. Check the [dashboard](https://flutter-dashboard.appspot.com/build.html).
1. [P0 issues](https://github.com/flutter/flutter/labels/P0) (e.g. serious regressions).
1. Mentoring promising new contributors.
1. [Code review of open PRs](https://github.com/pulls?utf8=%E2%9C%93&q=is%3Aopen+is%3Apr+archived%3Afalse+user%3Aflutter+).
1. [P1 issues](https://github.com/flutter/flutter/labels/P1), including:
   1. [Flaky tests](https://github.com/flutter/flutter/issues?q=is%3Aopen+is%3Aissue+label%3A%22team%3A+flakes%22+sort%3Aupdated-asc).
   1. Performance regressions. Check the [dashboard](https://flutter-dashboard.appspot.com/benchmarks.html) for new unreported regressions and see GitHub for the list of [reported performance regressions](https://github.com/flutter/flutter/issues?utf8=%E2%9C%93&q=is%3Aopen+label%3A%22c%3A+performance%22+label%3A%22c%3A+regression%22+).
   1. [Other regressions](https://github.com/flutter/flutter/issues?q=is%3Aopen+is%3Aissue+label%3A%22c%3A+regression%22).
   1. Reducing technical debt. (For example, increasing [our test coverage](./testing/Test-coverage-for-package-flutter.md) by [writing new tests](./testing/Running-and-writing-tests.md), or fixing TODOs.)
1. [P2 issues](https://github.com/flutter/flutter/labels/P1), which correspond to the remaining areas of our [roadmap](../roadmap/Roadmap.md), such as:
    * Bugs marked as [annoyances](https://github.com/flutter/flutter/issues?q=is%3Aopen+is%3Aissue+label%3A%22a%3A+annoyance%22+sort%3Areactions-%2B1-desc).
    * Bugs labeled as issues of [quality](https://github.com/flutter/flutter/issues?utf8=%E2%9C%93&q=is%3Aopen+is%3Aissue+label%3A%22a%3A+quality%22+sort%3Areactions-%2B1-desc+).
    * Bugs with the [crash](https://github.com/flutter/flutter/issues?utf8=%E2%9C%93&q=is%3Aopen+is%3Aissue+label%3A%22c%3A+crash%22+sort%3Areactions-%2B1-desc+) label.
1. [Issues sorted by thumbs-up](https://github.com/flutter/flutter/issues?q=is%3Aissue+is%3Aopen+sort%3Areactions-%2B1-desc). Focus on bugs in existing code and avoid adding new code.
1. Everything else. Consider [this advice](https://ln.hixie.ch/?start=1674863881&count=1) when prioritizing bugs.

Bugs in other bug systems should be tracked with bugs in GitHub. OKRs should be reflected in the items listed above. For example, OKRs should reflect what the roadmap covers, expected customer blockers, and so forth. Work that is unique to a particular quarter would be represented by a filed bug with a milestone and assignee.

During [triage](../triage/README.md), bugs should be prioritized according to the [P0-P3 labels](./issue_hygiene/README.md#priorities) so as to fit the order described above.

Sometimes, items in the list above escalate. For example, a bug might get filed as a P2 issue, then be recognized as a critical regression and upgraded to P0.

See also:

 * [Issue Hygiene](./issue_hygiene/README.md), in particular the section on prioritization.