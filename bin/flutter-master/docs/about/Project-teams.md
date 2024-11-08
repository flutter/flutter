The Flutter project has many teams, including, but not limited to:

* Design languages, covering:

  * The material library ([flutter/flutter packages/flutter/lib/src/material](https://github.com/flutter/flutter/blob/main/packages/flutter/lib/src/material); label ["f: material design"](https://github.com/flutter/flutter/labels/f%3A%20material%20design))

  * The cupertino library ([flutter/flutter packages/flutter/lib/src/cupertino](https://github.com/flutter/flutter/blob/main/packages/flutter/lib/src/cupertino); label ["f: cupertino"](https://github.com/flutter/flutter/labels/f%3A%20cupertino))

* The Flutter framework (code in [flutter/flutter packages/flutter/lib/src/widgets](https://github.com/flutter/flutter/blob/main/packages/flutter/lib/src/widgets),  [...rendering/](https://github.com/flutter/flutter/blob/main/packages/flutter/lib/src/rendering),  [...painting/](https://github.com/flutter/flutter/blob/main/packages/flutter/lib/src/painting), etc; label ["framework"](https://github.com/flutter/flutter/labels/framework))

* The Flutter command line tool ([flutter/flutter packages/flutter_tools](https://github.com/flutter/flutter/blob/main/packages/flutter_tools/), label ["tool"](https://github.com/flutter/flutter/labels/tool))

* Ecosystem ([flutter/plugins](https://github.com/flutter/plugins), [flutter/packages](https://github.com/flutter/packages), [the plugin infrastructure in flutter/flutter](https://github.com/flutter/flutter/tree/main/packages/flutter/lib/src/services); labels ["plugins"](https://github.com/flutter/flutter/labels/plugins), and ["packages"](https://github.com/flutter/flutter/labels/packages))

* The Engine ([flutter/engine](https://github.com/flutter/engine) and [flutter/buildroot](https://github.com/flutter/buildroot/); label ["engine"](https://github.com/flutter/flutter/labels/engine))

* Various platform-specific teams including iOS, Android, Windows, Linux, and macOS (some code in flutter/flutter and flutter/engine); labels ["platform-android"](https://github.com/flutter/flutter/labels/platform-android), ["platform-ios"](https://github.com/flutter/flutter/labels/platform-ios), etc).

* Desktop-specific features (some code in flutter/flutter and flutter/engine, ["a: desktop"](https://github.com/flutter/flutter/labels/a%3A%20desktop))

* Web (some code in flutter/flutter and flutter/engine, label ["platform-web"](https://github.com/flutter/flutter/labels/platform-web))

* Developer experience (e.g. [the devtools package](https://github.com/flutter/devtools/))

* User Experience Research

* Developer Relations (e.g. [the samples repo](https://github.com/flutter/samples/), [docs.flutter.dev](https://docs.flutter.dev/))

* Infrastructure (mainly [flutter/cocoon](https://github.com/flutter/cocoon) and [flutter/flutter dev/devicelab](https://github.com/flutter/flutter/tree/main/dev), label ["team: infra"](https://github.com/flutter/flutter/labels/team%3A%20infra))

There are also specific cross-cutting areas of work that may have their own subteam and that affect multiple subteams (e.g. accessibility, performance, etc).

We also work closely with other projects, such as [Dart](https://dart.dev) and [Skia](https://skia.org), and with many [customers](../contributing/issue_hygiene/README.md#customers).

## Responsibilities

Subteams are responsible for reviewing PRs in their area, triaging issues, and scheduling work.
How subteams organize themselves is not defined by this document. This document does not attempt to impose a process, merely a set of responsibilities.

See the [Roadmap](../roadmap/Roadmap.md) and [What should I work on?](../contributing/What-should-I-work-on.md) pages for details on how to prioritize work.

### Reviewing PRs

Please review PRs in your area (based on label and/or repositories). The goal is to have a prompt (less than one week) turnaround for all PRs. Please have goals around handling of PRs with the relevant label and/or in the relevant repository. Please don't leave lingering stale PRs open. All PRs should be actively being worked on. If nobody has the time to work on a PR, it should be closed; the relevant issue can have the ["has partial patch"](https://github.com/flutter/flutter/labels/has%20partial%20patch) label applied.

### Triage

Please triage issues with your label on a regular basis. You may do this in whatever manner you prefer (on your phone while in line for lunch, as a team exercise in a dedicated meeting room, by having some sort of team rotation, whatever).

[You must cover these bug lists in particular.](../triage/README.md#triage-process-for-teams)

* Assign bugs that you are working on or that you have committed to work on.

* Unassign bugs you are not working on and have no specific scheduled plans to work on.

* Make sure that assigned bugs have a month-based milestone (see section below).

[See our page on managing issues.](../contributing/issue_hygiene/README.md)

Keep an eye out for bugs that should block releases, update the [bad builds](../releases/Bad-Builds.md) page accordingly.

### Be conservative when scheduling

Customers always assume things will be done sooner than you promise, and there are always going to be emergencies, so you need slack in your schedule.

You will be more effective, more popular, and your morale will be higher, if you focus on a small set of things and really knock those out of the park, than if you try to do a large number of things and only do a little bit for each, so aim to underpromise and overdeliver.

This may mean your OKRs are more optimistic than what you report as your scheduled timeline. With OKRs we generally try to hit 67% of the plan. With the roadmap we want to hit 150%.

(OKRs are how some team members plan their work, notably it is used by Google engineers.)