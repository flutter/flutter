# AI contribution policies

This document contains Flutter's policies around the use of AI assistants or
agents when contributing to Flutter. We expect both humans and AI agents to
follow the letter and spirit of these policies. If contributors notice behaviors
that are not aligned with these policies, they should contact
[conduct@flutter.dev](mailto:conduct@flutter.dev).

## Philosophy

A common question in discussions around AI policies for open source projects is:
"Why have an AI policy at all? Why does it matter how the code was created;
shouldn't the code speak for itself?"

In general, we agree, which is why our policy focuses on behaviors rather than
tools. The behaviors that led to the creation of this policy are problematic
regardless of whether they are AI-generated or human-generated. However, it is
useful to highlight these policies in the context of AI because we have seen
that these behaviors are orders of magnitude more common when AI is involved.
For example:

* Submitting a PR containing hundreds of lines of code that the contributor
  doesn't understand is always a problem. This was rare before the widespread
  use of AI agents, but is more common with AI-assisted development.
* Having several rounds of exchanges where a reviewer asks for a change, and the
  contributor says that they have made that change but haven't, is always a
  waste of reviewer time. It's very rare for a contributor to deliberately and
  obviously lie to a reviewer, but unfortunately common for contributors to
  uncritically repeat AI agent hallucinations.
* Contributions that ignore our process have always been problematic, because
  standardizing the process is an important part of how we keep our triage and
  review load manageable. However, a contributor who has spent hours or days on
  a PR is much more likely to take some time to learn and follow our process to
  avoid having that effort be wasted than someone who spent a few minutes
  generating the PR.

Overall, regardless of the forum and whether by way of automation or manual
unedited copy-and-paste, do not use AI to substitute for you in human
discussion.

## Our CLA

All submissions to Google Open Source projects need to follow
[Google's Contributor License Agreement (CLA)](https://cla.developers.google.com/),
in which contributors agree that their contribution is an original work of
authorship. This does not prohibit the use of coding assistance tools, but what
is submitted needs to be the contributor's original creation.

## Issues and triage

Comments and reports in the issue database should add value (see
[issue hygiene](./docs/contributing/issue_hygiene/README.md) and the
[triage guide](./docs/triage/README.md)). Anyone can easily feed an issue URL
into an agent, so just posting the results of doing that is generally not
helpful.

* **Do not** run an unsupervised agent that posts triage comments to the issue
  database. Any automated agent needs to be approved in advance, after
  discussion with the Flutter team.
* Use AI tools to help you contribute to an issue rather than as replacements
  for your contribution. AI tools may be helpful for specific tasks, such as
  creating reduced test cases or identifying potential duplicate issues, but you
  must verify their output. For example, if you use an AI tool to create a
  reduced test case, make sure that you can actually reproduce the issue before
  posting it.
* Edit AI-generated text to focus on the important details. Longer is not better
  in issues, and AI output is often verbose.

## Pull requests

PRs prepared using AI tools must follow the standard
[tree hygiene](./docs/contributing/Tree-hygiene.md) process and the
[style guide](./docs/contributing/Style-guide-for-Flutter-repo.md), along with
these requirements:

1. You must review all AI-generated code before opening a (non-draft) PR, and
   before requesting re-review of any updates to the PR.
   * You are responsible for making sure that code you submit meets the Flutter
     project's standards.
   * Unmodified AI output generally does not meet those standards.
1. You must understand and be able to discuss the code in the PR.
   * Non-trivial PRs require discussion and iteration during review. If you do
     not understand the code, you cannot meaningfully respond to review
     feedback.
   * In our experience, simply feeding review feedback into an AI agent and
     uncritically reposting its output will not lead to a constructive review.
1. You must verify the accuracy of any AI-generated text you include in the PR
   description or review discussion comments.
   * If an AI provides you incorrect information, it is just hallucinating; if
     you choose to paste that text into GitHub, you are misrepresenting your PR
     to your reviewer.
   * In particular, do not tell a reviewer that you have addressed their
     feedback just because AI output says so. It is your responsibility to make
     sure that review feedback has actually been addressed.

### Reviewer guidelines

Because the Flutter team's time is limited, and the capacity for people outside
the team to generate plausible-looking code is unlimited, be mindful as a
reviewer about what code you choose to review. Consider immediately closing PRs
that have any of the following red flags:

* The PR description has entirely replaced our template with AI-generated
  output, and the PR is missing at least one obvious checklist item (tests,
  issue link, etc.).
  * If the contributor did not follow our process from the outset, they are
    unlikely to understand what is expected of them during review.
* The PR description does not match the changes.
  * If the contributor did not review both the changes and the description
    enough to notice this, they have not followed the AI contribution policy.
* The PR contains irrelevant AI-generated files, such as agent planning `.md`
  files.
  * If the contributor did not review the changes enough to notice and remove
    these files, they have not followed the AI contribution policy.

As always when closing a PR, explain why and provide next steps.

As a guiding principle, if at any point in the process you feel that you are
getting unfiltered or minimally filtered AI output as code and/or comment
responses, ask yourself:

* If this PR weren't here, would I choose to spend my time fixing this issue?
* Would I choose to fix it using an AI agent that took hours or days to respond
  to every prompt?

Unless the answer to both questions is yes, the review is not a good use of your
time.

This applies even if you are multiple rounds into the review: if the contributor
closed the PR, would you take it over using an extremely high-latency agent?
Beware the sunk cost fallacy.
