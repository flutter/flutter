When triaging web issues follow the following process:

* Make sure there are no [unassigned P0 and P1 issues](https://github.com/flutter/flutter/issues?q=is%3Aopen+is%3Aissue+label%3Ateam-web+label%3AP1%2CP0+no%3Aassignee).
* Make sure there are no [P1 issues outside the backlog](https://github.com/flutter/flutter/issues?q=is%3Aopen+is%3Aissue+label%3Ateam-web+label%3AP1%2CP0+-project%3Aflutter%2F41+).
* Make sure there are no [P3 issues in the backlog](https://github.com/flutter/flutter/issues?q=is%3Aopen+is%3Aissue+project%3Aflutter%2F41+label%3AP3).
* Make sure all assigned issues are either P0 or P1 (if you'd like to become a regular Flutter Web contributor, please ping yjbanov on Discord to be added to this list, and we'll watch that your issues are properly triaged):
  * [harryterkelsen](https://github.com/flutter/flutter/issues?q=is%3Aopen+is%3Aissue+label%3Ateam-web+-label%3AP0%2CP1+assignee%3Aharryterkelsen)
  * [kevmoo](https://github.com/flutter/flutter/issues?q=is%3Aopen+is%3Aissue+label%3Ateam-web+-label%3AP0%2CP1+assignee%3Akevmoo)
  * [mdebbar](https://github.com/flutter/flutter/issues?q=is%3Aopen+is%3Aissue+label%3Ateam-web+-label%3AP0%2CP1+assignee%3Amdebbar)
  * [yjbanov](https://github.com/flutter/flutter/issues?q=is%3Aopen+is%3Aissue+label%3Ateam-web+-label%3AP0%2CP1+assignee%3Ayjbanov)
  * [flutter-zl](https://github.com/flutter/flutter/issues?q=is%3Aopen+is%3Aissue+label%3Ateam-web+-label%3AP0%2CP1+assignee%3Aflutter-zl)
* All [P0 issues](https://github.com/flutter/flutter/issues?q=is%3Aopen+is%3Aissue+label%3Ateam-web+label%3AP0) are assigned and being worked on.
* The list of [P1 issues](https://github.com/flutter/flutter/issues?q=is%3Aopen+is%3Aissue+label%3Ateam-web+label%3AP1) should be manageable (<30 issues)
* Number of open PRs should be manageable (<15):
  * [flutter/flutter](https://github.com/flutter/flutter/pulls?q=is%3Aopen+is%3Apr+label%3Aplatform-web+sort%3Acreated-asc+draft%3Afalse+-label%3Atriaged-web)
  * [flutter/packages](https://github.com/flutter/packages/pulls?q=is%3Aopen+is%3Apr+label%3Atriage-web+sort%3Aupdated-asc+-is%3Adraft)
    * Remove the `triage-web` label when the PR is approved.
    * If you are the last reviewer, add the `autosubmit` label.
* Triage [untriaged issues](https://github.com/flutter/flutter/issues?q=is%3Aissue+is%3Aopen+label%3Ateam-web%2Cfyi-web+-label%3Atriaged-web+no%3Aassignee+-label%3A%22will+need+additional+triage%22+sort%3Aupdated-asc+-label%3A%22waiting+for+customer+response%22+)
