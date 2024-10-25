# Release engineer/manager onboarding

Googler facing documentation can be found at go/flutter-release-workflow.

### Responsibility

Release engineer is responsible for:
* Branch alignment and/or shepherding cherry picks
* Decision making related to cherry pick risk
* Verification that pre and post submits pass prior to publishing
* Contributor facing communication
* Some public facing post release communication

In the past (and possibly in the future) there was a distinction between a release engineer and release manager.
For now the responsibilities are the same and we will refer to the person managing the release as a release engineer.

## Onboarding

One time setup instructions for new or returning release engineers.

### Groups/Permissions

#### Join flutter-hackers on GitHub

https://github.com/orgs/flutter/teams/flutter-hackers/members

#### [Googler only] Join mdb/flutter-infra

Possibly not required
https://ganpati2.corp.google.com/propose_membership?parent=9147533327&child=$me.prod

#### Join the flutter-announce google group

Ping any current release engineer to add you as an owner and give you publish access.
https://groups.google.com/g/flutter-announce/members?q=role:owner&pli=1

TODO include screenshot

#### [Googler only] Install tool-proxy-client

From a glinux machine run `sudo apt install tool-proxy-client`.

`tool-proxy-client` is the tool that enables/enforces 2 party authorization for controlled builds.

#### [Googler only] Confirm access to release calendar

Public and Beta releases and timelines
go/dash-team-releases

#### [Googler only] Join release chatroom

Release hotline https://chat.google.com/room/AAAA6RKcK2k?cls=7

#### [Googler only] join mdb/flutter-release-team

Controls who can approve 2 party auth requests.
https://ganpati2.corp.google.com/propose_membership?parent=100213927583&child=$me.prod

#### Setup conductor

Conductor is a dart command line interface for common release tasks.
Its instructions are in README.md.

#### [Googler only] Confirm access to Apple signing cert update doc

go/flutter-signing-apple-contracts
Also confirm access to valentine entries listed in that doc.

#### [Googler only] Access release engineer doc

Confirm access to go/release-eng-retros
