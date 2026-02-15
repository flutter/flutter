# Flutter postmortem: Build Breakage on 2016-11-08

Status: final<br>
Owners: chinmay

## Summary

Description: Travis reported failures on builds<br>
Component: flutter repository<br>
Date/time: 2016-11-07 21:30<br>
Duration: 16h 45m<br>
User impact: Flutter team members were unable to merge new PRs. Users would have been unable to run flutter tests if they upgraded, though we did not receive complaints during the outage.

## Timeline (all times in PST/PDT)

### 2016-10-24

A change to package:args is committed ([591f9c](https://github.com/dart-lang/args/pull/55/commits/08b1b5301de1aa3f18dedf9343ea637a58591f9c)) that introduces a bug whereby `run()` no longer returns the value returned by the command.

### 2016-11-02

**15:11** The [change](https://github.com/dart-lang/args/pull/55) to package:args is merged into the args repository.

### 2016-11-07

**16:27** Dart package:args tag 0.13.6+1 is cut -- and shortly after is pushed to pub **&lt;START OF OUTAGE&gt;**<br>
**21:36** ianh reports that Travis is upset and all PRs are failing

2016-11-08

**07:52** danrubel reports that Travis is still failing<br>
**11:03** chinmaygarde reports he’s facing the same breakage in his pending PR<br>
**11:07** Issue is reproduced locally. chinmaygarde, jsimmons and danrubel begin looking for the root cause of the breakage.<br>
**13:08** Root cause of outage identified as a new version of package:args that Flutter picked up whereby `run()` no longer returns the value returned by the command (so we couldn’t get accurate exit codes).<br>
**13:19** Flutter PR [#6765](https://github.com/flutter/flutter/pull/6765) sent to pin Flutter to a known good version of package:args<br>
**13:42** [fb3bf7a](https://github.com/flutter/flutter/commit/fb3bf7a9d776c81651e3d65268d02ef97a259e1c) identified as root cause of the internal breakage.<br>
**14:15** Fix lands. **&lt;END OF OUTAGE&gt;**

## Root causes

A bug was introduced in package:args that was picked up by Flutter.  Flutter was vulnerable to this bug because our external dependencies have open-ended version constraints, so the stability of our codebase is not hermetic. This was an intentional choice; we have experienced this failure mode previously, and have been running on the basis that we are not yet stable enough to deal with the costs of being hermetic.

## Action items

### Prevention

| Action Item | Owner | Tracking bug | Notes |
|-------------|-------|--------------|-------|
| Pin our external Dart dependencies to specific versions to ensure that our public stability is hermetic. | chinmay | [#6767](https://github.com/flutter/flutter/issues/6767) | |

### Detection

| Action Item | Owner | Tracking bug | Notes |
|-------------|-------|--------------|-------|
| We should have a continuous monitoring bot that tries to run all our tests | ianh | [#6777](https://github.com/flutter/flutter/issues/6777) | |

### Mitigation

None.

### Process

None.

### Fixes

| Action Item | Owner | Tracking bug | Notes |
|-------------|-------|--------------|-------|
| Update our package:args dependency to a known good version | danrubel | [PR #6575](https://github.com/flutter/flutter/pull/6765) | Done |
| Deploy a forward-rolling bot that goes red if our dependencies release a breaking change, and otherwise updates us to the latest versions of everything. | ianh | [#4696](https://github.com/flutter/flutter/issues/4696) | |

## Lessons learned

### What worked

* Once the Flutter team had a clear set of owners for the issue, it was root-caused and resolved quickly.

### Where we got lucky

* The outage did not break users. It likely would have if we had a larger userbase.

### What didn't work

* There were indications of the breakage as early as 2016/11/07 21:30, yet the team didn’t start looking into it in earnest until 2016/11/08 11:00. Once we get to the point where our build is hermetic (so we control our own stability) and we separate production artifacts from development artifacts (e.g., have a release branch), then we should consider providing an SLA, at which time we’d have to create processes around how to maintain that SLA.
