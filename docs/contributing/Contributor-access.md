For people who make the occasional contribution to Flutter (filing an issue, submitting the occasional PR, chatting on Discord), the default set of permissions is fine. However, if you are a regular contributor, whether helping in triage, fixing bugs, reviewing pull requests, improving documentation, or participating in design discussions, you can earn triage and commit permissions through the **[Flutter Contributor Ladder](https://github.com/flutter/contributors)** (see [`docs/LADDER.md`](https://github.com/flutter/contributors/blob/main/docs/LADDER.md)).

Active ladder members are listed in [`ROSTER.md`](https://github.com/flutter/contributors/blob/main/ROSTER.md) in [`flutter/contributors`](https://github.com/flutter/contributors), and belong to the `@flutter/flutter-hackers` parent team on GitHub through one of its role-based child teams:

* **Reviewer (`@flutter/reviewers` — GitHub Triage role):** Community contributors with ≥ 10 qualifying contributions over the preceding 12 months (merged PRs, valid issues filed, reviews on merged PRs, or qualitative contributions such as issue triage, reproduction verification, [RFC](https://github.com/flutter/rfc) reviews, and mentoring). Reviewers conduct first-pass code reviews on community PRs, provide one of the two required approvals on Contributor/Reviewer PRs, and triage and label issues.
* **Committer (`@flutter/committers` — GitHub Write role):** Experienced contributors with ≥ 30 qualifying contributions over the preceding 12 months, including ≥ 10 merged PRs. Committers provide binding review approvals, mentor Contributors and Reviewers, and have repository write/merge permissions.
* **Maintainer (`@flutter/maintainers`, `@flutter/googlers`, `@flutter/partners` — GitHub Write + Moderation):** Flutter team engineers at Google and verified partner team engineers who steward subsystems, hold GitHub organization moderation privileges, and lead architectural and policy decisions.
* **Dasher Emeritus ([`EMERITUS.md`](https://github.com/flutter/contributors/blob/main/EMERITUS.md) — Alumni):** Former ladder members who have stepped back from active contribution (< 10 contributions over 12 months after a 30-day grace period).

Being on the contributor ladder means you are added to the appropriate `@flutter/flutter-hackers` child team on GitHub (`@flutter/reviewers`, `@flutter/committers`, or `@flutter/maintainers`), granted the "team" role on Discord, and invited to the announcement-only `flutter-contributors` Google Group (via the registration form pinned in `#hidden-chat` on Discord). This privilege comes with an expectation of responsibility: ladder members care about Flutter and help move the project forward along our [roadmap](../roadmap/Roadmap.md), collaborate constructively with the team, contribute and review high-quality code, and follow through on bugs and tests.

Ladder members must follow all project processes and policies, and must adhere to our [code of conduct](https://github.com/flutter/flutter/blob/main/CODE_OF_CONDUCT.md) and [style guide](Style-guide-for-Flutter-repo.md). Access will be revoked if trust or the code of conduct is violated.


### Responsibilities

#### Code of conduct

If you are on the contributor ladder or hold "team" access on the Discord server, you are expected to uphold and help enforce our [code of conduct](https://github.com/flutter/flutter/blob/main/CODE_OF_CONDUCT.md).

Our code of conduct is much, much stricter than most. We do not wait until someone has been actively rude or insulting. Being disrespectful in any way is grounds for action. For example, passive-aggressive whining and general unconstructive negativity are all violations of the code of conduct. If someone is in a bad mood, we would rather they avoided contributing to Flutter on that day.

When you see something that might be described as unwelcoming or is in some other way a violation of our code of conduct, promptly contact the offender and ask them to read the code of conduct and consider how they might more effectively espouse its philosophy. Most people react very positively to this.

If they react negatively, or if they continue to make the environment unpleasant, they should be removed from the environment. On Discord, this would be kicking them from the channel. Repeat offenders should be banned. On GitHub, organization moderation permissions (blocking accounts, locking conversations, hiding comments) are held by Maintainers (you can also contact `conduct@flutter.dev` or ping @github-admin on Discord). Please let the #server-support [Chat](Chat.md) channel know when you do anything like this, so that we can keep an eye on how common it is.

#### Maintaining documentation

Part of being a contributor is making sure our documentation is up to date, including our internal (team-facing) documentation such as `docs/`. If you spot something wrong, please fix it!

### Privileges

Depending on your tier in `@flutter/flutter-hackers` (see [`docs/LADDER.md`](https://github.com/flutter/contributors/blob/main/docs/LADDER.md) and [`docs/CODE_REVIEW_WORKFLOW.md`](https://github.com/flutter/contributors/blob/main/docs/CODE_REVIEW_WORKFLOW.md)), GitHub organization membership gives you:

* **Reviewers (`@flutter/reviewers` — Triage role):**
  * The ability to add labels, milestones, and assignees, and close duplicate or resolved issues on GitHub (see [Issue Hygiene](./issue_hygiene/README.md)).
  * First-pass code review approval on Contributor and Reviewer PRs (counting as one of the two required `@flutter/flutter-hackers` approvals, alongside a binding approval from a Committer or Maintainer).
  * Faster pre-submit CI test execution on PRs.

* **Committers (`@flutter/committers`) and Maintainers (`@flutter/maintainers`) — Write role:**
  * All Reviewer privileges above.
  * Authoritative/binding code review approvals on pull requests.
  * The ability to merge pull requests (requiring 1 approval from a Reviewer or higher on your own PRs) and apply the `autosubmit` label (see [Tree Hygiene](Tree-hygiene.md)).
  * Exemption from the 2 concurrent open pull request limit on public Flutter repositories.

Being in the Discord "team" group gives you the following:

* Access to `#hidden-chat` (which includes the pinned sign-up form for the `flutter-contributors` Google Group, delivering announcements and calendar invites for the Flutter Contributor Roundtable and the Dash Forum).
* The ability to talk without rate-limiting on the #hackers-* channels.
* The ability to kick people.
* The ability to manage the server emoji.


## Process

Invitations and promotions on the contributor ladder are managed through **[Quarterly Reviews](https://github.com/flutter/contributors/blob/main/docs/QUARTERLY_REVIEW.md)** in [`flutter/contributors`](https://github.com/flutter/contributors):

1. Every quarter, automated activity tracking across active `flutter` repositories evaluates rolling 12-month contributions and opens a public Community Contributor Ladder Audit issue in [`flutter/contributors`](https://github.com/flutter/contributors/issues) for a 30-day review period.
2. Contributors who meet the criteria for **Reviewer** (≥ 10 contributions) or **Committer** (≥ 30 contributions, including ≥ 10 merged PRs) and are in good Code of Conduct standing are invited on the quarterly audit issue.
3. Invited contributors reply on the tracking issue to accept their invitation (confirming agreement with our [code of conduct](https://github.com/flutter/flutter/blob/main/CODE_OF_CONDUCT.md) and [style guide](Style-guide-for-Flutter-repo.md)) and share their Discord username.
4. At the conclusion of the 30-day review period, [`ROSTER.md`](https://github.com/flutter/contributors/blob/main/ROSTER.md) is updated and organization admins provision the corresponding GitHub team (`@flutter/reviewers` or `@flutter/committers` under `@flutter/flutter-hackers`) and Discord "team" role.
5. For exceptional off-cycle needs between quarterly reviews, an active organization member can sponsor an out-of-band nomination issue in [`flutter/contributors`](https://github.com/flutter/contributors/issues/new/choose).

*For new Googlers and Partner engineers*: Googlers are provisioned via `@flutter/googlers` (managed through internal tooling) and added to `@flutter/maintainers` by an admin. Partner engineers are managed through `@flutter/partners` child teams and verified quarterly (see [`docs/GOVERNANCE.md`](https://github.com/flutter/contributors/blob/main/docs/GOVERNANCE.md)).


## Inactivity and Dasher Emeritus

During each [quarterly review](https://github.com/flutter/contributors/blob/main/docs/QUARTERLY_REVIEW.md), ladder members with fewer than 10 recorded GitHub contributions over the preceding 12 months are placed in a **30-day grace period** on the public quarterly audit issue. Members who have been active through qualitative contributions not captured by automated PR/issue/review counts (such as issue triage, verifying reproductions, reviewing [RFCs](https://github.com/flutter/rfc) or design docs, or mentoring) can reply on the audit issue during the 30-day window to retain their active role.

After the 30-day grace period, inactive members transition to **Dasher Emeritus** and are honored in [`EMERITUS.md`](https://github.com/flutter/contributors/blob/main/EMERITUS.md). To maintain repository security, Dasher Emeriti exit the `flutter` GitHub organization, while retaining their Discord "team" role (including `#hidden-chat`) and membership in the `flutter-contributors` Google Group so they can stay connected with the team.

If you are a Dasher Emeritus and return to active contributing, you will be automatically identified for reinstatement during the next quarterly review once you reach 10 contributions, or you can ask an active organization member in `#hidden-chat` on Discord to sponsor an off-cycle [Dasher Emeritus Reinstatement request](https://github.com/flutter/contributors/issues/new?template=2_emeritus_reinstatement.yml) in [`flutter/contributors`](https://github.com/flutter/contributors).


# Access rights to Flutter dashboard

The [Flutter dashboard](https://flutter-dashboard.appspot.com/) shows what recently landed and what tests passed or failed with those commits. To see rerun tasks, you need to be added to an allowlist. Anyone with commit access is eligible to be added to that allowlist, but only certain team members have the permissions required to update the backend database where the permissions are stored. To get access, ask on #hackers-infra to be added to the allowlist.

## Adding a contributor to Flutter Dashboard

*This is only for team members with access to the Flutter Dashboard Datastore.*

1. Open [flutter-dashboard datastore](https://console.cloud.google.com/datastore/entities;kind=AllowedAccount;ns=__$DEFAULT$__/query/kind?project=flutter-dashboard)
2. Click `Create Entity`
3. Click `Email: Empty` -> Edit property. Insert contributor Google account
4. Click `Create`

# Access to LUCI recipes and configuration repositories

If you need access to the LUCI recipes, you need to be added to the relevant ACLs. Ask in #hackers-infra to be added to the LUCI ACLs.

## Process

A Googler has to be the one to grant permission. Documentation on how to use the relevant tools is available at: https://goto.google.com/gob-ctl#add-or-remove-users-in-host-acl

# Access to Flutter Gold

If you need access to triage images in [Flutter Gold](https://flutter-gold.skia.org/), you need to be added as an authorized user.
Users in the `@google.com` domain are already authorized to use Flutter Gold, but `@gmail.com` addresses can also be added to the allow list.

## Process
The list of authorized users is maintained in the [skia build-bot repository](https://skia.googlesource.com/buildbot), in [this file](https://skia.googlesource.com/buildbot/+/refs/heads/main/golden/k8s-instances/flutter/flutter-skiacorrectness.json5). Googlers can submit a change to add to the authorized users.

This repository is also [mirrored on GitHub.](https://github.com/google/skia-buildbot)

# fcontrib.org accounts

Historically, team members authoring design docs as Google Docs needed non-corporate accounts to share them publicly. Because design documents and RFCs are hosted in the [flutter/rfc](https://github.com/flutter/rfc) repository using standard GitHub accounts (see [Design Documents](Design-Documents.md)), `fcontrib.org` accounts are not used for design work.

If a team member requires access to Flutter Google Workspace resources without using a personal account, an admin can provision an `fcontrib.org` account upon request in the #server-support channel on Discord.

## Process

You’ll need the user’s email account somewhere else, first and last name, and desired fcontrib.org account login before you begin.

To add a fcontrib.org participant:
1. Open an incognito window and log in using _your_ admin fcontrib credentials at https://admin.google.com/. (q.v. valentine)
2. Under “Users” in the upper left of the main content area, click “Add a User” and follow the prompts.
3. For a password, choose “Generate Password” and email the password to the new account holder using their non-fcontrib account -- they’ll be able to log in with that and then choose a new password.

# Review teams

Some parts of the codebase have teams specified so that PRs get round-robin assigned for review.

To join one of these teams, request members be added/deleted, or change any settings, ping @github-admin on Discord. Members must be a member of the Flutter Hackers group (as documented at the top of this page).

We currently have the following review teams:

* [`android-reviewers`](https://github.com/orgs/flutter/teams/android-reviewers): for folks working on the Android port of Flutter; use `#hackers-android` for discussions.
* [`devtools-reviewers`](https://github.com/orgs/flutter/teams/devtools-reviewers): for the [devtools](https://github.com/flutter/devtools) repo; use `#hackers-devexp` for discussions.
* [`ios-reviewers`](https://github.com/orgs/flutter/teams/ios-reviewers): for folks working on the iOS port of Flutter; use `#hackers-ios` for discussions.
* [`linux-reviewers`](https://github.com/orgs/flutter/teams/linux-reviewers): for folks working on the Linux port of Flutter; use `#hackers-desktop` for discussions.
* [`macos-reviewers`](https://github.com/orgs/flutter/teams/macos-reviewers): for folks working on the macOS port of Flutter; use `#hackers-desktop` for discussions.
* [`website-reviewers`](https://github.com/orgs/flutter/teams/website-reviewers): for folks working on www.flutter.dev and docs.flutter.dev; use `#hackers-devrel` for discussions.
* [`windows-reviewers`](https://github.com/orgs/flutter/teams/windows-reviewers): for folks working on the Windows port of Flutter; use `#hackers-desktop` for discussions.

To create a new team, contact @github-admin on Discord. You will also need to create a `CODEOWNERS` file to actually trigger the review assignment.

# Pusher permissions

Some branches are protected to avoid accidents. Only people in the specific branches can push to them. Anyone can ask to be added or removed from these groups, they exist only to reduce accidents, not for security.

To join one of these teams, request members be added/deleted, or change any settings, ping @github-admin on Discord. Members must be a member of the Flutter Hackers group (as documented at the top of this page).

The following groups have been defined for these purposes: pushers-beta, pushers-fuchsia
