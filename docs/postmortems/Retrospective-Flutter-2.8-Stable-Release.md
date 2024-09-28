# Flutter 2.8 Stable Retrospective
Date: 16 December 2021

Facilitator: Kevin Chisholm
## Attendees
1. Nuritzi Sanchez
1. Alexander Thomas
1. Godofredo Contreras
1. Vijay Menon
1. Devon Carew
1. Ian Hickson
1. Devon Carew
1. Todd Volkert
1. Khyati Mehta
1. Eric Seidel
1. Christopher Fujino
1. Andrew Brogdon
1. Kevin Chisholm


## Retrospective Guidelines
### Blameless
Focus on the actions and behaviors, not the people.  Our retrospectives should be a safe place to reflect on what we can do to improve as a team.
### Inclusive
All input is valuable, we should never make someone feel as if their thoughts and contributions are not valued.
### Actionable
Work toward defining the issues that can be actioned on to be more successful in the future.
## Retrospective Items
### What went well
* We released a quality SDK on the expected date.
  * No P0 issues to hotfix.
* Our infrastructure and test owners responded rapidly to the chat allowing us to address issues.
* The social team was proactive in keeping customers informed.
* Were able to delay blog post and docs.
  * Got them out in time after the release was available.
### Challenges
* We did not properly take into account how long the release would take.
* We had no process to separate the build from the release.
* Documentation is lacking / not prescriptive enough to accurately describe the entire process.
  * Release documentation. We have a lot of documentation, but it’s not consolidated into a single source of truth with handoffs and DRIs (directly responsible individuals)
  * A lot of this release seemed based on undocumented institutional knowledge.
  * Didn’t find info about dot releases and cherrypicking. Not written down anywhere.
* We incorrectly tagged the Dart commit.
* We did not have the Dart commit hash posted in the release engineering doc.
* Missed deadline by 8 hours.
  * PM team had to do extra work and expend their social capital.
* We need documentation for the binary signing process.
  * We may not have benefited from publishing the Dart SDK release earlier. We had the Dart stable hash on Friday, but did not properly communicate it to the release engineer. As soon as the Dart hash exists, Flutter and Dart release processes are independent, so if we had published it on Monday or Tuesday it wouldn’t have helped.
  * Right now we start betas on a certain day and then stable have to be shipped on a certain day. We may need to rethink this and standardize.
* Fixes were needed to the stable bots (they were not the same as commit-bots/beta bots).
  * Java version was wrong.
  * Properties used to select the correct versions of artifacts were missing.
Xcode/Mac/iOS were force updated in between the beta to stable time window
  * Web Engine Framework, Framework sdk tests in the engine failed because they used the master version of framework with old version of engine.
  * Branch configurations were updated after landing the PR causing multiple purples and several manual retries.

### How can we improve [30 Minutes]
* Build Flutter in advance.
  * Should have been done the day before and pushed the morning of.
  * Do most of the build and release process in advance; on the day-of, do the tagging / packaging work (<1 hr, and a predictable process).
  * How early we can release may be determined by what bugs we need to hotfix.
  * Docs need to be updated after the branch push
  * What is the delta between the master and stable branch?
    * ~6 days
* Create a solid release playbook on the wiki to be followed.
  * Should be clear enough that two interns (meaning, two inexperienced people new to the team who have the appropriate permissions) should be able to make a release without supervision while everyone else is on vacation. (It has to be two because you need two people to authorize a release).
  * [Release Process](../releases/Release-process.md) should be (or point to) that process doc; other pages on the wiki should be up to date also.
* Align beta and stable release processes.
* Practice release dry runs.
  * Have people who have never followed the steps before practice the steps, to find where the documentation is missing important details.
* Run retrospectives after every beta and stable release.
* Improve testing infrastructure.
* Better define owners.
* Improve communication.
* Cherry pick owners were not notified of the release times.
  * Were not able to resolve issues.
### Action Items

| Status | Action Item | Owner |
|--------|-------------|-------|
| In Progress | Create a single source of truth release playbook unifying the Flutter and Dart release processes | Kevin |
| In Progress | Rethink timing of releases | Kevin |
| In Progress | Identify release calendars and make sure they are easily accessible to everyone who needs to see them | Kevin |
| In Progress | Conduct retrospectives after every release | Kevin |
| In Progress | Create a release rotation for beta releases | Godofredo |
| In Progress | Create meeting for Dart / Flutter EngProd teams and TPM team on release weeks | Kevin |
| In Progress | Clean up and consolidate release documentation | TPM |
| In Progress | Successfully produce at least 2 betas before our Feb stable to verify that we will be without issues for the Feb stable | Devon / Kevin |
| In Progress | Consider the milestone flow on github | Ian / Kevin |
