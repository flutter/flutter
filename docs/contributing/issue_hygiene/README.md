## tl;dr

- Avoid asking about the status of an issue; if we have an update, we'll post it.
- If you have permission, assign bugs to yourself if you're working on them.
- Unassign bugs that you are not working on soon.
- If an issue is not assigned, assume it is available to be worked on.

## Overview

We use three issue trackers: the [main one on flutter/flutter](https://github.com/flutter/flutter/issues), one for [the flutter.dev Website, on flutter/website](https://github.com/flutter/website/issues), and one for [the IntelliJ and Android Studio plugins, on flutter/flutter-intellij](https://github.com/flutter/flutter-intellij/issues).

This page mostly talks about how we handle things for the flutter/flutter issue tracker.

### Issue philosophy

We assume that Flutter, like all non-trivial software, has an infinite number of bugs. The issue tracker contains the list of bugs that we are very lucky to have had reported by our generous community. Bugs includes known defects, as well as feature requests, planned work, and proposals.

Within the bug database we try to make sure each issue is actionable and discoverable. We do this by carefully updating the issue subject line, making sure every issue has steps to reproduce, and using labels to categorize the issue in ways that can be found by GitHub search.


## Comments

### Do not add "me too" or "same" or "is there an update" comments to issues or PRs

The Flutter team prioritizes issues in part based on the number of +1 (thumbs
up) reactions on the top level comment of the bug. Adding comments like "me
too" or "same here" is generally distracting and makes it harder to find
other more meaningful content in the bug. If you have no new details to add,
consider just thumbs up-ing the issue.  If you wish to subscribe to the issue,
click the "subscribe" button in the right hand column of the GitHub UI.

Adding comments explaining how a bug is dire and how you will stop using Flutter
if it is not fixed is upsetting for the engineers working on Flutter (many of
whom are volunteers, not that being paid to work on Flutter makes such comments
any less upsetting). Out of a respect for the team, and as required by our [code
of conduct](https://github.com/flutter/flutter/blob/main/CODE_OF_CONDUCT.md), we
ask that you avoid adding comments that are not actively helpful. There are other
venues if you want to complain without being constructive.

Asking for updates is also not generally helpful, because it just leads to issues
being full of comments asking for updates and that makes finding useful information
in a bug harder (an exception might be if you are participating in the triage process,
but even then consider reaching out to people directly if possible). If you believe
there could be information that has not been posted, ask on our Discord server instead
(see [Chat](../Chat.md)).

### Issues are not always the best venue for discussions

Discussions within an issue should remain focused on the topic, specifically about what the filed issue is and how to solve it. Broader discussions are best suited to happen on Discord (see [Chat](../Chat.md)) or in design docs using Google Docs (see [Design Documents](../Design-Documents.md)). This is because GitHub hides comments, doesn't have threading, notifications get lost in the swamp of other GitHub e-mails, etc.

If you move to another tool for part of the discussion, remember to add a summary of the discussion and document any decisions that took place. This allows people following the issue to keep updated and continue to participate.

Issues are never an appropriate venue for asking for help with your code. Issues are also not a good venue for discussing project direction.

### Comments providing workarounds

Providing workarounds for issues can be helpful for developers using Flutter and finding a bug,
but please keep such comments to a minimum so as to avoid disrupting the engineers trying to
fix the issue. Rather than discussing workarounds, provide a pointer to another forum
(e.g. Stack Overflow) where workarounds and temporary solutions are more appropriate. Thanks.
However, when a workaround has been identified, consider applying the `workaround available` label to make that info readily available.

### Avoid posting screenshots of text

If you want to show code, quote someone, or show a string of text that does
not render properly with Flutter, please avoid sharing it via an image or
screenshot. Text in images cannot be copied, and cannot be automatically
translated via services like Google Translate. This makes it harder for team
members who do not speak that language to participate in the issue.

It is perfectly fine to share a screenshot of text rendering invalidly, but
also include the actual string or character(s) that lead to it so that they
can be copied and pasted into a test case.

### Provide reduced test cases

To debug a problem, we will need to be able to reproduce it. The best way
to help us do that is to provide code, licensed according to [the BSD license
used by Flutter](https://github.com/flutter/flutter/blob/main/LICENSE), that
has been reduced as far as possible (such that removing anything further stops
showing the bug). Attach such a file or files to the issue itself.

For legal reasons, we cannot debug problems that require looking at proprietary
code or, generally, code that is not publicly available.

### Consider posting issues in English

If you are able to read and write English clearly, consider posting your issue
in English, even if it is about a language specific issue (like the way text
renders in some non-English language).

It is fine to post issues in languages other than English, but consider that
many readers will rely on automatic translation services to read your issue.
Please avoid using screenshots in languages other than English, as services like
Google Translate will not translate the text in images, and the pool of people
able to assist you will be reduced.


## Locking an issue

**Closed** issues that haven't received any activity in a [few weeks](https://github.com/flutter/flutter/blob/main/.github/lock.yml#L4)
are automatically locked by a [bot](https://github.com/apps/lock). This is
done to encourage developers to file new bugs, instead of piling comments
on old ones.

Under normal circumstances, open issues should not regularly be locked. The most
common reason for manually locking an open issue is that issue is well
understood by the engineers working on it,
is believed to be appropriately prioritized, has a clear
path to being fixed, and is otherwise attracting
a lot of off-topic or distracting comments like "me too" or
"when will this be fixed" or "I have a similar issue that might
or might not be the same as this one".

If you are concerned that such an issue is not receiving its due
attention, see Escalating an Issue, described above. If you are
not already a contributor but would like to work on that issue,
consider reaching out on an appropriate [chat](../Chat.md).

If you have a similar issue and are not sure if it is the same,
it is fine to file a new issue and linking it to the other issue.
Please avoid intentionally filing duplicates.

Very rarely, an issue gets locked because discussion has become
unproductive and has repeatedly violated the [Code of Conduct](https://github.com/flutter/flutter/blob/main/CODE_OF_CONDUCT.md).


## Priorities

**The [`P0`](https://github.com/flutter/flutter/labels/P0) label** indicates that the issue is one of the following:
* a build break, regression, or failure in an existing feature that prevents us from shipping the current build.
* an important item of technical debt that we want to fix promptly because it is impacting team velocity.
* an issue blocking, or about to block, a top-tier customer. (See [below](#customers) under "customers" for a definition of "top-tier customer".)

There are generally less than twenty-five P0 bugs (one GitHub search results page). If you find yourself assigning a P0 label to an issue, please be sure that there's a positive handoff between filing and a prospective owner for the issue.

Issues at this level should be resolved in a matter of weeks and should have weekly updates on GitHub.

During normal work weeks (e.g. not around the new year), issues marked P0 get audited weekly during the "critical triage" meeting to ensure we do not forget about them. Issues marked P0 should get updates at least once a week, to keep the rest of the team (and anyone affected by the issues) apprised of progress.

**The [`P1`](https://github.com/flutter/flutter/labels/P1) label** indicates high-priority issues that are at the top of the work list. This is the highest priority level a bug can have if it isn't affecting a top-tier customer or breaking the build. Bugs marked P1 are generally actively being worked on unless the assignee is dealing with a P0 bug (or another P1 bug).

Issues at this level should be resolved in a matter of months and should have monthly updates on GitHub.

**The [`P2`](https://github.com/flutter/flutter/labels/P2) label** indicates issues that we agree are important to work on, but are not at the top of the work list. This is the default level for new issues. A bug at this priority level may not be fixed for a long time. Sometimes an issue at this level will first migrate to P1 before we work on them, but that is not required.

**The [`P3`](https://github.com/flutter/flutter/labels/P3) label** indicates issues that we currently consider less important to the Flutter project. We use "thumbs-up" on these issues as a signal when discussing whether to promote them to P2 or higher based on demand. (Of course, this does not mean the issues are not important to _you_, just that we don't view them as the especially important for Flutter itself.)

Typically we would accept PRs for `P3` issues (assuming they follow our [style guide](../Style-guide-for-Flutter-repo.md) and follow our [other rules](../Tree-hygiene.md)). Issues marked with the [`would require significant investment`](https://github.com/flutter/flutter/issues?q=is%3Aopen+is%3Aissue+label%3A%22would+require+significant+investment%22) label may require more than just a PR, for example, adding support for a whole new platform will require a commitment to provide CI resources for build and test, and someone to own the maintenance of those systems.

### When will my bug be fixed?

Flutter is an open source project and many people contribute their time (or their employees' time) to fix code and implement features. Typically, people fix bugs that are relevant to their customers. For example, Google engineers who contribute to Flutter are going to prioritize issues that affect Flutter apps written by Google teams. Many of us, however, also volunteer time to fix more general issues.

To determine when a bug will be fixed, look at the issue.

If there's a recent status update on the issue, that is the best information we have about the bug. If there's a lot of comments on the issue, we try to link to the latest status from the top comment, so look there. (Please [don't _ask_](#do-not-add-me-too-or-same-or-is-there-an-update-comments-to-issues-or-prs) for updates, though.)

If the issue is labeled with priorities `P0` or `P1`, or if the issue is assigned, we are likely to address it in the near term; we just need to find time.

Otherwise, we don't know when we're going to fix it. We may never get to it. In general, `P2` bugs are seen as more important than `P3` bugs. See the more detailed definitions of _priorities_ above.

_See also [Popular issues](../issue_hygiene/Popular-issues.md)._

### Escalating an issue that has the wrong priority

If you have a relationship with the Flutter team, raise the issue with
your contact if you think the priority should be changed.

If you don't, consider finding like-minded developers to either implement
the feature as a team, or to fund hiring someone to work on the feature,
or to [mark the issue with a thumbs-up reaction](#thumbs-up-reactions).

Please don't comment on an issue to indicate your interest. Comments should
be reserved for making progress on the issue.


### Thumbs-up reactions

To vote on an issue, use the "Thumbs-up" emoji to react to the issue.

When examining issues, we use the number of thumbs-up reactions to an issue to determine an issue's relative popularity.
This is, of course, but one input.
At the end of the day, Flutter is an open source project and everyone (or every company) who contributes does so to further their own needs.
To the extent that those needs are aligned with making Flutter popular,
they tend to let their priorities be influenced by the "thumbs-up" reactions,
but if you have something on which your business depends,
the best solution is to pay someone to work on it.

See also:

 * [All open issues sorted by thumbs-up](https://github.com/flutter/flutter/issues?q=is%3Aissue+is%3Aopen+sort%3Areactions-%2B1-desc)

 * [Feature requests by thumbs-up](https://github.com/flutter/flutter/issues?q=is%3Aissue+is%3Aopen+sort%3Areactions-%2B1-desc+label%3A%22c%3A+new+feature%22)

 * [Bugs by thumbs-up](https://github.com/flutter/flutter/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aopen+sort%3Areactions-%2B1-desc+-label%3A%22c%3A+new+feature%22+)

We ignore other emoji reactions.



## Labels

We use [many labels](https://github.com/flutter/flutter/labels).

### Naming conventions

Common naming conventions for labels include:
- **`a: *`** - The `a` ("area") prefix is used for labels that are about a specific topic that could span different layers of Flutter's implementation (for example "accessibility" or "text input").
- **`browser: *`** - Indicates the browser for browser-specific issues for the web port of Flutter.
- **`c: *`** - The `c` ("category") prefix says what kind of bug we're looking at (regression, crash, new feature request, etc).
- **`d: *`** - The purple `d` ("devtools") labels are for organizing our developer tool issues.
- **`d: *`** - The green `d` ("documentation") labels are for organizing our documentation-related issues.
- **`dependency: *`** - Indicates the upstream team for issues that are blocked on some work from an upstream project (e.g. Skia, Dart).
- **`e: *`** - The `e` ("engine") prefix is for subsets of the Flutter engine ([flutter/engine](https://github.com/flutter/engine)).
- **`f: *`** - The `f` ("framework") prefix is for subsets of the Flutter framework ([flutter/flutter's packages/flutter/](https://github.com/flutter/flutter/tree/main/packages/flutter)).
- **`found in release: x.yy`** - Used for a series of labels that indicate which versions of Flutter an issue was found in.
- **`from: *`** - Labels that indicate where an issue originated (e.g. research, postmortems), if it wasn't filed organically.
- **`t: *`** - The `t` ("tool") prefix is for subsets of the Flutter tool ([flutter/flutter's packages/flutter_tools/](https://github.com/flutter/flutter/tree/main/packages/flutter_tools)).
- **`p: *`** - The `p` ("package") prefix is for specific packages ([flutter/packages](https://github.com/flutter/packages)). Light teal for packages and darker teal for plugins.
- **`platform-*`** - The `platform` prefix is for bugs that are specific to one or more platforms.
- **`r: *`** - The `r` ("resolution") prefix is used for labels that describe why an issue was closed.

### Adding labels

Labels are more or less free, so we can add them pretty easily. Please mention it to other team members first, so that they know what you are planning and can give feedback (please at a minimum mention it on `#hidden-chat` in our [Chat](../Chat.md)). Please make sure labels use a consistent color and naming scheme (e.g. all the framework-related labels are blue and start with `f:`).

Labels should be used for adding information to a bug. If you plan to use a label to find all instances of a particular topic (e.g. finding all PRs where someone wrote a design doc), be aware that there's no way to force people to label issues or PRs. You can, however, rely on automation to do it, for example we have a script that labels all PRs that affect the framework.

### Customers

The Flutter team is formed of engineers from many sources, including dedicated volunteers and employees of companies like Google. Each of these may have different ideas of who their customers are. For example, Google engineers consider some Google teams to be their customers, but someone who contributes on a code-for-hire basis may have their own customers.

Some teams using Flutter have a special relationship with some members of the Flutter team (e.g. they're collaborating with us on a new feature, or they're working with us on a product demo for an upcoming event). This is usually a fairly short-term arrangement for a specific business purpose. We provide such customers with a label (`customer: ...`) in our GitHub issue tracker. When these customers are working closely with members of the Flutter team, we may consider them "top-tier customers" for the purposes of prioritization.

Priority `P0` (see below) is sometimes used for bugs that affect these top-tier customers.

#### Coordinating between bug systems

Some customers have their own separate bug systems, in which they track Flutter
issues. We consider our GitHub issue list to be canonical. However, if there
is a link from the issue in our bug system to the customer's issue in their bug
system, and we have been granted access, we will follow that link and may
communicate in that separate bug system when attempting to track down the issue.

#### Special customer labels

The `customer: product` label is used to bring issues that product management
and senior leads want resolved to the attention of the appropriate engineering
team.

The `customer: crowd` label is used to represent bugs that are affecting large
numbers of people; during initial [Triage](../../triage/README.md), high-profile bugs get labeled in
this way to bring them to the attention of the engineering team. "Large numbers"
is a judgement call. If dozens of people independently run into the same issue
and file a bug and we end up realizing that they're all duplicates of each other,
then that would be a good candidate. On the other hand, if there is an active
campaign to get people to comment on a bug, then it's probably not legitimately
a `customer: crowd` bug, because people generally report bugs without having to
be convinced to do so.

In general, a bug should only be marked `customer: crowd` `P0` if it
is so bad that it is literally causing large numbers of people to consider changing
careers.


#### Other noteworthy labels

The `blocked` label can be used to indicate that a particular issue is unable to make progress until some other problem is resolved. This is particularly useful if you use your own list of assigned issues to drive your work.

The `good first issue` label should be used on issues that seem like friendly introductions to contributing to Flutter. They should be relatively well-understood issues that are not controversial, do not require a design doc, and do not require a deep understanding of our stack, but are sufficiently involved that they at least require a basic test to be added.


## Milestones

We do not use GitHub milestones to track work.


## Assigning Issues

Issues are typically self-assigned. Only assign a bug to someone else if
they have explicitly volunteered to do the task. If you don't have permissions
to assign yourself an issue you want to work on, don't worry about it, just
submit the PR (see [Tree Hygiene](../Tree-hygiene.md)).

Only assign a bug to yourself when you are actively working on it
or scheduled to work on it. If you don't know when you'll be working
on it, leave it unassigned. Similarly, don't assign bugs to
people unless you know they are going to work on it. If you find
yourself with bugs assigned that you have not scheduled specific time
to work on, unassign the bug so that other people feel
empowered to work on them.

_Do_ assign a bug to yourself if you are working on it, or if you have
scheduled time to work on it and are confident you will do so! This is how
people can figure out what is happening. It also prevents duplicate
work where two people try to fix the same issue at once.

You may hear team members refer to "licking the cookie". Assigning a
bug to yourself, or otherwise indicating that you will work on it,
tells others on the team to not fix it. If you then don't work on it,
you are acting like someone who has taken a cookie,
licked it to be unappetizing to other people, and then not eaten it.
By extension, "unlicking the cookie" means indicating to the
rest of the team that you are not actually going to work on the bug
after all, e.g. by unassigning the bug from yourself.

## File bugs for everything

File bugs for anything that you come across that needs doing. When you
implement something but know it's not complete, file bugs for what you
haven't done. That way, we can keep track of what still needs doing.

### Exceptions

Do _not_ file bugs that meet the following criteria:

- Asking meta-questions like "why was bug #XYZ closed?" Instead, post
  on the original issue or raise the actual problem that is still not
  resolved.
- Intentional duplicates like  "This is the same as bug #ABC but that
  one is not getting enough attention." Instead, upvote the original
  issue or add a comment that provides new details that are not already
  captured or (best of all) assign it to yourself and start working on it!

### How to propose a specific change

If you have an idea that you would like to land, the recommended process is:

1. [File a bug](https://github.com/flutter/flutter/issues/new/choose) describing the problem.
2. Write a [design doc](https://flutter.dev/go/template) that references this problem and describes your solution.
3. Socialize your design on the bug you filed and on [Chat](../Chat.md). Collect feedback from various people.
4. Once you have received feedback, if it is mostly positive, implement your idea and submit it. See the [Tree Hygiene](../Tree-hygiene.md) wiki page for details on submitting PRs.

### Every issue should be actionable

Avoid filing issues that are on vague topics without a clear problem description.

Please close issues that are not actionable. See [Triage](../../triage/README.md) for more details.

#### Issues should have clear steps to reproduce

Every issue should have a clear description of the steps to reproduce the problem, the expected results, and the actual results.

If an issue is lacking this information, request it from the commenter and close the issue if information is not forthcoming.

## Closing issues

An issue should be closed if:

* it is fixed!
* it is a [duplicate](../../triage/README.md#duplicates).
* it makes multiple requests which could be addressed independently. Encourage people to file separate bugs for each independent item.
* it is describing a _solution_ rather than a _problem_. For example, it has no use cases, and the use cases are not obvious, or might have other solutions.
* it is not [actionable](../../triage/README.md#what-makes-an-issue-actionable) and does not [have unusual symptoms](../../triage/README.md#unactionable-bugs-with-unusual-symptoms). This covers a wide variety of cases, such as invalid bugs, bugs without steps to reproduce, bugs that have become irrelevant, or bugs that are unclear and which the reporter has not offered more details for. It also includes non-catastrophic bugs that cannot be reproduced by anyone but the original reporter. For this latter case, encourage the reporter to attempt to debug the issue themselves, potentially giving suggestions for places where they could instrument the code to find the issue, and invite them to join the Discord for help; then add the `waiting for customer response` label. The issue will get automatically closed after a few weeks if they don't respond.
* it is a feature request that we are unlikely to ever address, and if we did address it, it would not be part of the core SDK (e.g. it would be in a package). (For example, anything in the [`would be a good package` `P3`](https://github.com/flutter/flutter/issues?q=is%3Aopen+is%3Aissue+label%3A%22would+be+a+good+package%22+label%3AP3) list is a good candidate for closing without fixing.)
* we would not accept a fix even if one were to be offered ([e.g. support for platforms at level of support 4](../../about/Values.md#levels-of-support)).
* it is an issue regarding internal processes, tooling, or infrastructure (i.e. something that our users are not affected by), that we have no plans to get to (e.g. that would be marked P3). (For example, anything in the [`c: tech-debt` `P3`](https://github.com/flutter/flutter/issues?q=is%3Aopen+is%3Aissue+label%3A%22c%3A+tech-debt%22+label%3AP3) list is a good candidate for closing.)
* it is tracking technical debt but the suggested improvements are marginal at best or would require significant research to be evaluated. Prefer having folks who work in the relevant part of the code make improvements based on their judgment.


The following are poor reasons for closing an issue:

* it has not been updated for a long time. This is fine; if the issue has not changed, then it is normal for it to not be updated.
* it is a low-priority user-facing issue. We would prefer to have one long-lived open bug with a single conversation, than many short-lived closed bugs with many independent conversations.
* it would be hard to fix.


In general, any bug that has the following characteristics should definitely not be closed:

* it is a well-described problem that we can reproduce reliably.
* it is a well-argued feature request with a solid use case and clear goal that cannot reasonably be implemented in a package. (If it's something we're unlikely to ever do, it should be marked P3.)
* it is tracking technical debt that is clearly actionable and whose benefits are clear.
* it is a request to add a customization to a material widget that fits cleanly into the existing material design library's ethos.
* it was filed by a team member and is assigned to that team member.


## Tracking bugs for team members

If you need to track some work item, you can file a bug and assign it to yourself. Self-assigned bugs like this are mostly ignored by the bots and you can ignore the rules for such issues. (When you leave the team, we'll likely close these issues.) Some people like to use bugs like this as "umbrella" bugs for tracking work. You may also find it useful to use GitHub projects to manage work items.


## Flaky tests

When a test flakes, a P0 bug is automatically filed with the label [`team: flakes`](https://github.com/flutter/flutter/issues?q=is%3Aopen+is%3Aissue+label%3A%22team%3A+flakes%22+sort%3Aupdated-asc). This issue should be investigated with all due haste, and a priority level should then be assigned to the issue. At any particular time, the most flaky tests should remain P0. However, flakes that are hard to pin down may be downgraded in priority (e.g. to P1). Please do not ignore the issue entirely, however, and make sure to close bugs once they are resolved, even if it's by magic.

_See also: [Reducing test flakiness](../../infra/Reducing-Test-Flakiness.md)_