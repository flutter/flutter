# Triage Priorities for Dart Analyzer

This document describes the relative priorities for bugs filed under the
`area-analyzer` tag in GitHub as in
[this search](https://github.com/dart-lang/sdk/issues?q=is%3Aopen+is%3Aissue+label%3Aarea-analyzer).
While there are always exceptions to any rule, in general try to align our
priorities with these definitions.

To triage bugs, search for `area-analyzer`
[bugs that are not currently triaged](https://github.com/dart-lang/sdk/issues?q=is%3Aopen+is%3Aissue+label%3Aarea-analyzer+-label%3AP0+-label%3AP1+-label%3AP2+-label%3AP3+-label%3AP4)
and for each bug, mark priority based on how closely it matches with the below
constraints.

## Analyzer triage priorities

Descriptions here use [terms and definitions](#terms-and-definitions) from the
end of this document.  If your bug doesn't precisely match one of these,
consider how impactful it is compared to examples given here and pick a priority
reflecting that.

### P0

* Incorrect analysis errors or warnings, widespread without a practical
  workaround
* Uncaught exceptions resulting in tool crashes, widespread and no workaround
* Incorrect resolution of symbols or libraries, widespread and no workaround
* Incorrect data from analyzer API, widespread and with no workaround
* Automation resulting in corrupted code from clean inputs, widespread
  * EXAMPLE: A commonly used or important quick fix somehow uses wrong
    offsets and eats random chunks of code.
* Performance regression, large and widespread
* Any problem urgently blocking critical milestones for key users or Dart rolls
  into Flutter/Google3
* Security or privacy problem, widespread

### P1

* Incorrect analysis errors or warnings, on edge cases but no workarounds
  * EXAMPLE: Disabling the afflicted warning or error has no effect, or makes
    the problem worse.
* Incorrect analysis infos, widespread
* Incorrect resolution of symbols or libraries, edge cases, or widespread but
  with workaround
* Incorrect data from analyzer API, widespread but with workaround
* Uncaught exceptions resulting in tool crashes, widespread but with workaround
* Automation resulting in corrupted code from clean inputs, edge cases or with
  an easy workaround
* Automation resulting in incorrect code, widespread
  * EXAMPLE: a commonly used or important quick fix generates code that is
    valid but produces a warning (e.g. [sdk#48946](https://github.com/dart-lang/sdk/issues/48946)).
* Performance regression, large or widespread (but not both), or impacting key
  users.
* An enhancement required for critical milestones for key users, or that has
  significant evidence gathered indicating a positive impact if implemented
* Any problem that, while it doesn't currently block, will block rolls into
  Flutter/Google3 if not resolved within ~2 weeks
* Security or privacy problem, in edge cases or with very simple workarounds

### P2

* Incorrect analysis errors or warnings, on edge cases with simple workaround
  * EXAMPLE: Disabling the error or warning 'fixes' the issue and unblocks
    users.
* Incorrect analysis infos/hints, on edge cases
* Incorrect resolution of symbols or libraries, edge cases only with workarounds
* Incorrect data from analyzer API, edge cases without workaround
* Automation resulting in incorrect code, edge cases
* Uncaught exceptions resulting in tool crashes, edge cases
* Performance regression, large, impacting edge cases, without good workarounds
* Security or privacy problem, theoretical & non-exploitable
* An enhancement that the team agrees is a good idea but without strong evidence
  indicating positive impact

### P3

* Uncaught exceptions caught by a fuzzer, but believed to be theoretical
  situations only
* Incorrect analysis errors or warnings, theoretical
* Incorrect analysis infos/hints, on edge cases with workaround
* Incorrect resolution of symbols or libraries, theoretical
* Incorrect data from analyzer API, edge case with workaround available
* Performance regression impacting edge cases with workaround or without
  workaround if small
* Automation that should be available not triggering, on edge cases
* Automation resulting in incorrect code, theoretical or edge cases with easy
  workaround
* An enhancement that someone on the team thinks might be good but it isn't
  (yet?) generally agreed by those working in the area that it is good

### P4

* Incorrect analysis infos/hints, theoretical
* Incorrect data from analyzer API, theoretical
* Theoretical performance problems
* An enhancement that may have some evidence that it isn't a good idea to
  implement but it isn't clear enough to close

## Terms and definitions

### Terms describing impact

* "commonly used" - Particularly in the case of automation, either metrics
  indicate the automation is triggered manually a high percentage of the time
  (IntelliJ), or it is triggered as part of bulk operations e.g. `dart fix`.
* "edge cases" - Impacting only small parts of the ecosystem.  For example,
  one package, or one key user with a workaround.  Note this is an edge case
  from the perspective of the ecosystem vs. language definition.  If it isn't
  happening much in the wild or (if there isn't evidence either way) if it
  isn't believed to be super likely in the wild, it is an edge case.
* "important" - For diagnostics and their associated automation, if the
  diagnostic is part of the language definition, or the core, recommended, or
  Flutter lint sets, it is important.
* "theoretical" - Something that we think is unlikely to happen in the wild
  and there's no evidence for it happening in the wild.
* "widespread" - Impact endemic throughout the ecosystem, or at least far
  enough that this is impacting multiple key users.

### Other terms

* "automation" - Anything that changes the user's code automatically.
  Autocompletion, quick fixing, refactorings, NNBD migration, etc.
* "corrupted code" - Modification of source code in such a way that it is
  more than just a bit wrong or having some symbols that don't exist, but is
  not valid Dart and would be painful to manually correct.
* "diagnostic" - An error, warning, hint, or lint generated by the analyzer
  or linter.
* "incorrect code" - Modification of code in a way that is known to be wrong,
  but would be trivial to figure out how to fix for the human using the tool.
* "key users" - Flutter, Pub, Fuchsia, Dart, Google/1P
* "tool" - Analysis Server, dart analyzer, migration tool, analyzer-as-library
