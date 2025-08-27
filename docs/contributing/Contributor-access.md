For people who make the occasional contribution to Flutter (filing an issue, submitting the occasional PR, chatting on Discord), the default set of permissions is fine. However, if you are a frequent contributor, whether helping us in triage, or often fixing bugs, or regularly improving our documentation, or regularly helping others in our #help channel, or participating in high-level design discussions and prioritization, you may find your life is more pleasant with commit access (also known as "contributor access", "being a member of the flutter-hackers group", "being a member of the Flutter team").

We grant commit access (which includes full rights to the issue database, such as being able to edit labels, and grants access to our internal chat channels) to people who have gained our trust and demonstrated a commitment to Flutter.

Specifically, if you meet one of the following criteria and you have a sponsor (someone who already has contributor access and agrees that you should be granted access), then please ask your sponsor to propose, on the #server-support [Chat](Chat.md) channel, that you be made a member of the team, and then reply to that message explaining which criteria below you are claiming to meet. The possible criteria are:

* You have a long history of participating productively, e.g. in our [Chat](Chat.md) channels, helping with [Triage](../triage/README.md), helping other contributors track down problems, finding meaningful issues in submitted PRs, helping people in our #help channel, etc, all while demonstrating exemplary behavior that closely aligns with our [code of conduct](https://github.com/flutter/flutter/blob/main/CODE_OF_CONDUCT.md).
* You have recently submitted several PRs that have landed successfully (received an LGTM, PR was merged, no regressions reported, PR was not reverted), without needing extensive tutoring in the process.
* You are employed by a company with a history of contributing to Flutter, for the purpose of yourself regularly contributing to Flutter.
* You represent a development team that creates applications, plugins, or packages using Flutter and have a close relationship with our developer relations team, including having a customer label, and have a great need to regularly update labels on issues (see [Issue hygiene, Customers](./issue_hygiene/README.md#customers)). (This is rare.)

Being granted access means that you will be added to the "flutter-hackers" group on GitHub and the "team" role on Discord. This privilege is granted with some expectation of responsibility: contributors are people who care about Flutter and want to help Flutter along our [roadmap](../roadmap/Roadmap.md). A contributor is not just someone who can make changes or comment on issues, but someone who has demonstrated their ability to collaborate with the team, get the most knowledgeable people to review code, contribute high-quality code, follow through to fix bugs (in code or tests), and provide meaningful insights on issues.

We grant access optimistically based on a reasonably small volume of evidence of good faith. Correspondingly, we will remove access quickly if we find our trust has been violated. Contributors with commit access must still follow all our processes and policies, and must follow our [code of conduct](https://github.com/flutter/flutter/blob/main/CODE_OF_CONDUCT.md) rigorously. (Please read it, it's stricter than most.)


### Responsibilities

#### Code of conduct

If you have commit access or "team" access on the Discord server, you are responsible for enforcing our [code of conduct](https://github.com/flutter/flutter/blob/main/CODE_OF_CONDUCT.md).

Our code of conduct is much, much stricter than most. We do not wait until someone has been actively rude or insulting. Being disrespectful in any way is grounds for action. For example, passive-aggressive whining and general unconstructive negativity are all violations of the code of conduct. If someone is in a bad mood, we would rather they avoided contributing to Flutter on that day.

When you see something that might be described as unwelcoming or is in some other way a violation of our code of conduct, promptly contact the offender and ask them to read the code of conduct and consider how they might more effectively espouse its philosophy. Most people react very positively to this.

If they react negatively, or if they continue to make the environment unpleasant, they should be removed from the environment. On Discord, this would be kicking them from the channel. Repeat offenders should be banned. On GitHub, they can be blocked from our organization (you can ask @github-admin on Discord to do this). Please let the #server-support [Chat](Chat.md) channel know when you do anything like this, so that we can keep an eye on how common it is.

#### Maintaining documentation

Part of being a contributor is making sure our documentation is up to date, including our internal (team-facing) documentation such as this wiki. If you spot something wrong, please fix it! As a contributor, you have access to the wiki.

### Privileges

Being in the GitHub "flutter-hackers" group gives you the following:

* The ability to merge your own PRs once they are reviewed (see [Tree Hygiene](Tree-hygiene.md)).

* The ability to add labels, milestones, etc, on issues on GitHub (see [Issue Hygiene](./issue_hygiene/README.md)).

* PRs will run their tests slightly faster.

Being in the Discord "team" group gives you the following:

* The ability to talk without rate-limiting on the #hackers-* channels.

* The ability to kick people.

* The ability to manage the server emoji.


## Process

The actual process (as followed by Flutter repo admins) is as follows:

1. Verify that they qualify under all the terms described above. Make sure they have a sponsor who isn't you.
1. Verify the identity of the person making the request. Ask them to confirm, on Discord, that they have read the style guide, issue or tree hygiene wiki page, code of conduct, and other documents relevant to them.
1. Add them to our private spreadsheet (go/flutter-organization-members).
1. Click the "Add a member" button on [the flutter-hackers team page](https://github.com/orgs/flutter/teams/flutter-hackers/members) on GitHub.
1. Type their name in the text field, select them, then click the "Invite" button.
1. Add them to the "team" group on Discord. Be sure to verify that you are promoting the right person; multiple people can have the same nickname on Discord!

*For new Googlers joining the team*: You need to ask someone in the team to add you to get added. It's not an automatic process after you join the flutter Google group.


## Inactivity

We occasionally check for account with commit access that have not been used for a while. It takes very little to count as "active" (e.g. commenting on an issue, even adding an emoji reaction to an issue). If your account has been inactive for over a year we will try to reach out (e.g. by e-mail or on Discord) before removing access.

If your account access was removed but you wish to return to contributing to Flutter, you are most welcome to do so; just reach out on the Discord (see [Chat](Chat.md)) and ask someone to renominate you according to the process described above.


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

If you are a team member who wants to share design docs (see [Chat](Chat.md)) but you don't want to use your own personal account, you can ask a Flutter admin for an fcontrib.org account. Ping @Hixie or another admin in the #server-support channel on Discord.

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
* [`website-reviewers`](https://github.com/orgs/flutter/teams/website-reviewers): for folks working on www.flutter.dev and docs.flutter.dev; use `#hackers-devrel` for discussions.

To create a new team, contact @github-admin on Discord. You will also need to create a `CODEOWNERS` file to actually trigger the review assignment.

# Pusher permissions

Some branches are protected to avoid accidents. Only people in the specific branches can push to them. Anyone can ask to be added or removed from these groups, they exist only to reduce accidents, not for security.

To join one of these teams, request members be added/deleted, or change any settings, ping @github-admin on Discord. Members must be a member of the Flutter Hackers group (as documented at the top of this page).

The following groups have been defined for these purposes: pushers-beta, pushers-fuchsia
