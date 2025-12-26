# Flutter postmortem: Platform-View-android-14-regression

Status:Published
Owners: johnmccutchen, reidbaker, jrect

## Summary

Flutter “Platform Views” on Android 14 stopped displaying when apps were backgrounded and onMemoryTrim was called. Confounding investigation, the OEM had a different but related issue that impacted viewing Platform Views. Platform Views are particularly important because they are the mechanism used to display ads.

Component: Android, Platform Views
Date/time: 2024-05-28
Duration: 6 months

### Purpose of this doc

This is a postmortem for the regression in Flutter Platform Views on Android 14. The purpose is to understand what went wrong, why it took so long to diagnose and/or fix, and how to avoid such breakages and long resolution periods in the future.

### User Impact

All Flutter customers using Platform Views on Android 14, including apps that use ads for revenue.

### Root Cause(s)

An AOSP public Android API was subtly broken in the commit here.
An OEM specific broken public API that was caused by similar roots but had different observable outcomes.
Flutter integration tests did not catch this class of error.

Timeline (all times in PST/PDT)

2023-07-11
17:11 - [Commit lands](https://googleplex-android.googlesource.com/platform%2Fframeworks%2Fbase/+/20a4d68338ca000e3ee0c5c71a01552eab1061e1) in android to destroy "prefetched layers when the context is destroyed"

<START OF OUTAGE>
2023
2023-11-27
00:00 - flutter issue filed describing WebViewWidget showing as white on one OEM's devices. https://github.com/flutter/flutter/issues/139039 "With android 14 device, WebViewWidget show white screen after foregrounded.(test with Galaxy s23 android 14"

2023-11-30
00:00 - Triaged as a potential platform view issue https://github.com/flutter/flutter/issues/139039#issuecomment-1834483618
00:01 - Gets an unusual amount of community attention.
00:02 - Reproduction is claimed to be on some of one OEM's android 14 devices but not all https://github.com/flutter/flutter/issues/139039#issuecomment-1835256092

2023-12-06
00:00 - First [duplicate bug](https://github.com/flutter/flutter/issues/139630#issue-2027860460) filed.

2023-12-07
00:00 - Flutter team acquires a device since it appears to be device specific https://github.com/flutter/flutter/issues/139039#issuecomment-1846052563

2023-12-08
00:00 - Bug is reproduced by flutter team. https://github.com/flutter/flutter/issues/139039#issuecomment-1847822918 and title is changed to "Galaxy S23 On Android 14 stops drawing platform views on resume"
00:01 - Bug that was closed as a dup is not reproducible. https://github.com/flutter/flutter/issues/139630#issuecomment-1847795930

2023-12-15
00:00 - User reports that the issue has appeared on multiple of one OEM's devices that were all recently updated to android 14. https://github.com/flutter/flutter/issues/139039#issuecomment-1857737055
00:01 - Flutter team finds that rotation and requestLayout can avoid the issue and posts a work around. https://github.com/flutter/flutter/issues/139630#issuecomment-1858465706
17:04 - Flutter team filed b/316626640 as a p0 referencing #139039 in the the OEM's component.

2023-12-19
00:00 - Bug title is changed to "... phones running Android 14 stops drawing platform views on resume"

2023-12-29
00:00 User report escalation to the OEM [comment](https://github.com/flutter/flutter/issues/139039#issuecomment-1872081990), [the OEM Forum](https://forum.developer.samsung.com/t/emergency-about-compatibility-between-flutter-and-samsung/28701)

2024-01-04
14:19 - First acknowledgement from the OEM partner. https://b.corp.google.com/issues/316626640#comment5

2024-01-19
00:00 - Flutter updates users that we believe this is an OEM issue and that they are working on it [comment](https://github.com/flutter/flutter/issues/139039#issuecomment-1901033982).

2024-01-22
15:01 - After multiple pings on the bug the OEM responds saying they have a fix and it will ship in the end of march release. https://b.corp.google.com/issues/316626640#comment13
15:03 - Flutter team requests a build so we can validate the issue.

2024-01-23
15:19 - the OEM acknowledges the request and asks for device info to share a build.

2024-01-24
13:10 - Flutter team shares the model information so that we can get a build with the fix while awaiting an explanation of what is wrong.

2024-01-31
00:00 - On an external bug with active commentary from multiple flutter contributors. Flutter still believes the issue to be the OEM only. https://github.com/pichillilorenzo/flutter_inappwebview/issues/1981#issuecomment-1919482839


2024-02-16
00:00 - Flutter dev puts up pr to modify ImageReader on memory pressure. [Pr is closed](https://github.com/flutter/engine/pull/50734) as not the right approach and has first frame regressions.
15:56 - After ~7 attempts to flash a device by the flutter team, director level escalation and a GVC with the OEM the flutter team is able to flash the build. Bug is “verified” but also flakey so flutter team members will keep testing. As of 2024-05-29 The flutter team has not received either an explanation of the fix or a CTS test.

2024-02-20
00:00 - Pr is created to close image readers when "onMemoryTrim" is called. https://github.com/flutter/engine/pull/50792

2024-02-27
00:00 - Issue is filed that points to pr/50792 as the cause of more issues. https://github.com/flutter/flutter/issues/144219

2024-02-28
00:00 - Issue [#144219](https://github.com/flutter/flutter/issues/144219) is reproduced. https://github.com/flutter/flutter/issues/144219#issuecomment-1969628748
15:35 - b/327419893 was filed against the OEM “ImageReaders stop working when app is backgrounded <The OEM's version of> Android 14”

2024-03-06
00:00 - Flutter team is waiting on the OEM to respond. https://github.com/flutter/flutter/issues/139039#issuecomment-1982309350

2024-03-13
00:00 - Pr is merged to revert "The OEM's specific fix" https://github.com/flutter/engine/pull/51391 and fixes issue #144219.
12:09 - The OEM finally responds to b/327419893 asking if it is the same as b/316626640

2024-03-18
14:24 - Gpay files a bug b/330184547 "After maximizing the Gpay app the blank screen showed and if tapping back button its navigating to home screen" which is marked as a blocker of their release.

2024-03-22
08:54 - The OEM claims to have a fix that will be available in the early april release. https://b.corp.google.com/issues/327419893#comment10
09:07 - Android team member asks for an explanation as of 2024-05-29 no explanation has been given.

2024-04-03
00:00 - Flutter team tells community we believe this is an OEM specific issue again. https://github.com/flutter/flutter/issues/139039#issuecomment-2035508888

2024-04-09
00:00 - First bug is filed that indicates the issue appears on pixel devices. "Platform views with FlutterEngineCache freeze/disappear on resume" https://github.com/flutter/flutter/issues/146499#issue-2233188697

20240-4-11
00:00 - First reproduction on a non the OEM device. https://github.com/flutter/flutter/issues/146499#issuecomment-2050686706

2024-04-15
15:06 - Flutter  team reaches out to Android team for help debugging why “ImageReader.OnImageAvailableListener“ is not firing after backgrounding. And sharing b/327502995 https://chat.google.com/room/AAAA2HILVWw/AZzn5F4REbw
15:36 - Android team tells flutter team that “ImageReader has zero interaction with activity lifecycle”
15:47 - Flutter team suspects that https://github.com/flutter/engine/pull/50792 might be the cause based on a flutter bisect.

2024-04-16
12:42 - Flutter team “confirmed that we background/resume the app that android.media.ImageReader$1.run is never invoked https://screenshot.googleplex.com/oHSDvH23MQCbhVT” Flutter team is running out of ways to validate the underlying android code is working as expected.
13:07 - Android team confirms that the bug must be in the flutter stack. “The only thing that ever happens to an ImageReader is what you do to it. Zero interaction with any system anything”

2024-04-17
00:00 Flutter team member was able to reproduce the bug on a pixel but not a pixel fold running 2 different versions of android 14. https://github.com/flutter/flutter/issues/146499#issuecomment-2062321046
00:01 - Flutter team member was able to verify that versions of flutter back 2+ years were all broken in the same way. https://github.com/flutter/flutter/issues/146499#issuecomment-2062787817
19:23: Flutter team is convinced that this is an android 14 issue. “ we've been trying different versions of Android and this behavior is only happening on Android 14”, Android team suggests we bisect to find the problem “If you're certain it's an Android regression a repro case & a bug works. If you want to bisect on your own go/flash”
23:01 Flutter team member bisects on an emulator using go/ab “Finished the bisect on the git_trunk-release branch using the emulator.

The change in behavior happened between build 10480234 (from 7/11/2023) and build 10488473 (from 7/12/2023)”


2024-04-18
00:00 - we get a [url to search commits](https://android-build.corp.google.com/range_search/cls/from_id/10488473/to_id/10480234/?s=menu&includeTo=0&includeFrom=1) from the android team.
11:25 - Flutter team “I'm now wondering if some of the OEM-specific issues we've been dealing with was just the OEM shipping this build of Android earlier than Google did. We have a cluster of bugs around this area that have been popping up since December.”
11:40 - Flutter team files b/335646931 "ImageReader stops producing images after suspend/resume of Flutter applications"
00:00 - Flutter team communicates to users we believe this is an android wide issue. Primary tracking bug is now #146499 https://github.com/flutter/flutter/issues/139039#issuecomment-2064675344
11:52 - Flutter team marks android 14 background issue b/327419893 as duplicate of b/335646931
14:08 - Android team puts up a patch for review https://googleplex-android-review.git.corp.google.com/c/platform/frameworks/base/+/27015418
12:11 - Android team “good news: easy fix
bad news: you'll need a workaround
medium (?) news: workaround isn't that bad at least, you'll need to switch to HardwareRenderer instead and make sure you either call setContentRoot after a resume orrrr just call it every frame it's not that big of a hit”, “ well, bad news pt2: this bug already shipped”



2024-04-19
00:00 - Android team merges fix https://b.corp.google.com/issues/335646931#comment7

2024-04-24
16:48 - Android team confirms the fix is in Android 15.

2024-04-26
00:00 - Lots of hate on the bug resulting in hixe having to step in. https://github.com/flutter/flutter/issues/146499#issuecomment-2080030263

2024-04-29
00:00 - PR landed with work around for flutter users. https://github.com/flutter/engine/pull/52370

2024-05-01
00:00 - Cherry pick request to avoid issue in flutter engine. https://github.com/flutter/engine/pull/52491 https://github.com/flutter/flutter/issues/147644

2024-05-09
12:58 - Escalation to pixel release team https://b.corp.google.com/issues/335646931#comment9
13:39 - Android Partner update ticket filed by flutter team. b/339659092


2024-05-14
00:00 - Flutter 3.22 released. https://medium.com/flutter/whats-new-in-flutter-3-22-fbde6c164fe3
00:00 <PARTIAL END OF OUTAGE>

2024-05-20
03:13 - Flutter issue filed indicating platform views still break in multi activity apps. https://github.com/flutter/flutter/issues/148662

2024-05-21
12:18 - Patch lands in july MPR for pixel devices https://b.corp.google.com/issues/335646931#comment18

2024-05-22
00:00 - Second flutter patch to handle the corner case where a non flutter activity was in the foreground. #148662 https://github.com/flutter/engine/pull/52980  cherry pick https://github.com/flutter/engine/pull/52982 https://github.com/flutter/flutter/issues/148885

2024-05-30
16:47 - Android rejected AOSP patch for partners.  https://buganizer.corp.google.com/issues/339659092#comment12

2024-06-06
Discussion among Flutter leads about whether the OEM-specific workaround(s) that were CP’d into Flutter 3.22 should be reverted. The workarounds imply additional Flutter public APIs that are not believed to be sustainable.
https://github.com/flutter/flutter/issues/148417

3.22.2 released to the public with the second mitigation. Flutter apps need to recompile and republish. https://groups.google.com/g/flutter-announce/c/0PEE5AvDZqc
End of outage.

### What went well

Once the Flutter team found the build range, the Android team fixed the problem for AOSP quickly.

### Where we got lucky

The issue did not affect all Platform Views on launch.
Drawing on prior experience, the Flutter team was able to quickly bisect on Android builds. Presumably, most Android customers wouldn’t be able to do this.

### What could have gone better?

The Flutter team struggled for several months to identify the difference between an Android issue from one manufacturer and an Android issue in AOSP.
The root-causing effort could have been more collaborative.
Platform Views are high risk and high value.
The fix could have been cherry-picked into AOSP.
The initial fix from the Android team could have included a test in the same patch.
With the original patch author out on leave, another expert in this API area on the Android team could have been available to write a test for the fix.

Action items
* P1 Add a test as described in b/343765967
* P1 Revert the workaround from the Flutter Engine and CP into Flutter 3.22.
* P1 Plugins that use Texture will have a new SurfaceProducerHolder object they can use for lifecycle awareness. Notes - ImageReader
* P1 CTS Test for ImageReader behavior as it responds to android lifecycle events (memoryTrim).
* P1 Screenshot Integration test for an arbitrary version of android that displays a platform view.
* P2 Screenshot Integration test for an arbitrary version of android that displays a platform view after backgrounding the activity and triggering memory trim

### Process

go/critical-partner-patches this document describes the work to escalate android patches to other android manufacturers.
go/pr-bug form required to get a patch shipped to pixel devices.


### Fixes
https://googleplex-android-review.git.corp.google.com/c/platform/frameworks/base/+/27015418
https://github.com/flutter/engine/pull/52370
