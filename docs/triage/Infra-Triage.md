# Flutter Infra Team Triage

_Canonical Link: [flutter.dev/to/team-infra](https://flutter.dev/to/team-infra)._

This doc details how to triage and work on issues marked [`team-infra`][].

[`team-infra`]: https://github.com/flutter/flutter/issues?q=is%3Aissue%20state%3Aopen%20label%3Ateam-infra

---

The _infrastructure_ sub-team works a bit differently than our externally
facing product, as it is producing (and maintaining) infrastructure _for_
Flutter, which includes tools and services that are open source but are **not
supported for external use**.

As a result, our process _differs_ from the general [issue hygiene](../contributing/issue_hygiene/) and [issue triage](README.md):

- We [own](#ownership) _general_ infrastructure, and decline other requests
- We use [_priority_ labels](#priorities) to mean specific things
- We accept [contributions](#contributing) in a more limited fashion
- We [close issues](#we-prefer-closing-issues) we do not plan to address and
  will not accept contributions on

This process allows us to have a more organized handle on the number of open
issues potentially affecting the team's velocity, including critical components
like release health.

Table of contents:

- [Triage](#triage)
- [Ownership](#ownership)
- [Priorities](#priorities)
  - [P0](#p0)
  - [P1](#p1)
  - [P2](#p2)
  - [P3](#p3)
- [We prefer closing issues](#we-prefer-closing-issues)
- [Contributing](#contributing)
- [Communication](#communication)
  - [How to contact us](#how-to-contact-us)

## Triage

Links:

- [P0 list](https://github.com/flutter/flutter/issues?q=is%3Aissue+is%3Aopen+label%3Ateam-infra+label%3AP0+sort%3Aupdated-asc)
- [Cocoon PRs](https://github.com/flutter/cocoon/pulls)
- [GoB CLs](https://flutter-review.googlesource.com/q/status:open+-is:wip)
- [Incoming issue list](https://github.com/flutter/flutter/issues?q=is%3Aissue+is%3Aopen+label%3Ateam-infra%2Cfyi-infra+-label%3Atriaged-infra+no%3Aassignee+-label%3A%22will+need+additional+triage%22+sort%3Aupdated-asc)
- [Latest updated issue list](https://github.com/flutter/flutter/issues?q=is%3Aissue+is%3Aopen+label%3Ateam-infra%2Cfyi-infra+sort%3Aupdated-desc)

## Ownership

The infra sub-team owns _general_ infrastructure that is often shared or used
across the Flutter project, but _not all_ testing and or tooling infrastructure;
that is, unless the tool is mentioned below, we may decline or direct you at
another sub-team:

- General CI/CD issues affecting [flutter/flutter](https://github.com/flutter/flutter)
  or [flutter/packages](https://github.com/flutter/packages)
- The [dashboard](https://flutter-dashboard.appspot.com/)
- Anything in [flutter/cocoon](https://github.com/flutter/cocoon),
  [flutter/recipes](https://flutter.googlesource.com/recipes/), and
  [flutter/infra](https://flutter.googlesource.com/infra/)
- _Some_ of the general infrastructure in [`dev/**`](../../dev)

## Priorities

Our prioritization is _similar_ to [team-wide priorities](../contributing/issue_hygiene/README.md#priorities),
but with a few more specifics. Unless you work _on_ the infra team, we ask you
do not add or change priority labels.

### [P0](https://github.com/flutter/flutter/issues?q=state%3Aopen%20label%3Ateam-infra%20label%3AP0)

An **emergency** that needs to be addressed ASAP as there is no reasonable
workaround.

P0s are worked on actively, with an update shared with the core team at least
once a week, and supercede _all_ other priorities (i.e. are a "stop work" order
on other issues).

Examples might include:

- PRs cannot be submitted
- Updating a PR, or pushing blank commits, do not trigger presubmits
- A serious security or privacy vulnerability in a deployed release

### [P1](https://github.com/flutter/flutter/issues?q=state%3Aopen%20label%3Ateam-infra%20label%3AP1)

An important change that would significantly improve productivity for the team,
or significantly improve reliability of the infrastructure (causing less P0 and
P1 issues).

If an issue has not been pre-aligned with the team, or does not have a sponsor
from another team that will be immediately responsible for a feature or bug fix,
then P1 is _not_ suitable.

Examples might include:

- PRs can only be submitted with workarounds
- Presubmits or postsubmits across the board have degraded in speed or
  reliability

### [P2](https://github.com/flutter/flutter/issues?q=state%3Aopen%20label%3Ateam-infra%20label%3AP2)

A change we agree with, but do not have bandwidth for.

An individual _could_ meaningfully make progress on this issue, and we would review it. If there are no volunteers, it may never be completed.

_See also: [contributing](#contributing)._

### [P3](https://github.com/flutter/flutter/issues?q=state%3Aopen%20label%3Ateam-infra%20label%3AP3)

A change we agree with, but would require significant maintenance.

While an individual _could_ meaningfully make progress on this issue, we would
_not_ review and accept it, as the cost of maintaining it is beyond what we can
currently sustain.

Our own team's discretion is used for what P3 issues are left open, and which
are [closed as not planned](#we-prefer-closing-issues).

_See also: [contributions](#contributions)._

## We prefer closing issues

[Unlike the external Flutter product](../contributing/issue_hygiene/README.md#closing-issues),
we do not accept contributions on all issues, and run the `team-infra` label more
like an operations team; that is, if an issue is unlikely to be addressed or
does not meet the [priorities criteria](#priorities) above, we often will close
the issue as _not planned_.

An issue closed as _not planned_ does not mean the issue does not have validity,
or that a subsequent more fleshed out issue or request would get more attention,
it just represents the limited bandwidth and capability of the team responsible.

We encourage you/your team to manage your own "wishlist" of items, which could
be in the format of a github issue (but _not_ tagged `team-infra`), a gist,
a github project, a Google doc, or another format, and to
[share it with us](#how-to-contact-us).

_See also: [contributing](#contributing)._

## Contributing

This sub-team has a more limited contributions policy than other parts of the
project, as we build and support tools that are **not supported** as part of the
Flutter product, including internal CI/CD and tooling.

In general, [P2](#p2) issues are a great way to contribute, as they have already
been actively vetted as "this is important to us" and "we would accept a PR or
PRs that address this bug or feature request".

For other issues, if you are part of the core Flutter team, please
[contact us](#how-to-contact-us).

## Communication

The team primarily uses GitHub and internal Google chat for communication, which
is unavailable to non-Google employees. For issues that are important to the
broader community, we use [Discord](https://discord.com/channels/608014603317936148/608116355836805126)
and [flutter-announce@](https://groups.google.com/g/flutter-announce) as needed.

### How to contact us

If you work at Google, see [go/flutter-infra-team](http://goto.google.com/flutter-infra-team).

Otherwise, see [#hackers-infra](https://discord.com/channels/608014603317936148/608021351567065092)
on Discord. Note responses may be infrequent.
