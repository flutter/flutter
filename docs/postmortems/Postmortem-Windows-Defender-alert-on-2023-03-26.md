# Flutter postmortem: Windows Defender alert

Status: final<br>
Owner: drewroengoogle

## Summary

Description: A change to Windows Defender caused transient CI failures and, more importantly, flagged Flutter as malware for some users.<br>
Component: Release<br>
Date/time: 2023-03-26<br>
Duration: two days<br>
User impact: An unknown number of users and potential new users were unable to use Flutter. Some tests failed.

## Timeline (all times in PST/PDT)

### 2023-03-26

??:?? - Microsoft deploys an update to Windows Defender **&lt;START OF OUTAGE&gt;**<br>
13:02 - We receive a message to security@flutter.dev reporting "Flutter Windows Installation WacAtac Trojan" from user S01.<br>
20:57 - A test [fails in CI](https://ci.chromium.org/ui/p/flutter/builders/prod/Windows_android%20hot_mode_dev_cycle_win__benchmark/9172/overview) with the message "the file contains a virus or potentially unwanted software".<br>
22:10 - @zanderso files [#123519](https://github.com/flutter/flutter/issues/123519) and marks it P0.<br>
12:51 - @andrewkolos files [#123525](https://github.com/flutter/flutter/issues/123525) after seeing multiple other CI failures.<br>
12:52 - @andrewkolos marks #123525 as a duplicate of #123519.<br>

### 2023-03-27

08:05 - @drewroengoogle begins investigating.<br>
08:40 - @drewroengoogle was unable to reproduce the problem and lowers the priority of the issue after the previously failing tests passed on rerun.<br>
09:02 - User Woo⛈ on Discord reports getting a Windows Defender warning for windows-x64.zip.<br>
10:03 - @MP00 reports on #123519 that Windows Defender quarantined windows-x64.zip on their machine at 10:42 in some unspecified time zone.<br>
10:27 - @godofredoc forwards the security e-mail from S01 to @sealesj and @drewroengoogle.<br>
10:59 - @Hixie replies to S01 by e-mail asking for more details.<br>
11:12 - S01 provides the specific URL that caused issues.<br>
11:45 - @Hixie asks S01 for even more details.<br>
11:47 - @Hixie flags this as a P0 to @godofredoc, @sealesj, and @drewroengoogle.<br>
11:53 - @godofredoc asks @drewroengoogle if #123519 is related.<br>
11:53 - @drewroengoogle marks #123519 as P0.<br>
12:03 - S01 provides the sha256 for flutter_windows_3.7.8-stable.zip.<br>
12:10 - @Hixie provides the reporter with the issue number.<br>
12:21 - @drewroengoogle verifies that the hash of flutter_windows_3.7.8-stable.zip in storage matches the hash reported by S01, confirming that the file was not corrupted or compromised during download by the reporter.<br>
12:34 - @Hixie attempts to upload the files to virustotal.com for independent verification of the file state. windows-x64.zip is marked as uncompromised and flutter_windows_3.7.8-stable.zip is too big to be uploaded.<br>
12:40 - @Hixie asks anyone on Discord who has a Windows machine whether they can reproduce the problem.<br>
12:52 - @gspencergoog reports getting the same message for gen_snapshot.exe.<br>
13:00 - @timsneath provides information on how to report this to Microsoft.<br>
13:04 - @Hixie creates an #incident-response channel on Discord to coordinate the response.<br>
13:48 - @gspencergoog successfully uploads windows-x64.zip to Microsoft for analysis. The instant report was that no malware was detected but the report was still pending.<br>
14:18 - @gspencergoog confirms that virustotal.com does not detect any malware in the affected files.<br>
??:?? - Microsoft deploys an update to Windows Defender **&lt;END OF OUTAGE&gt;**<br>
14:59 - @gspencergoog reports being unable to reproduce the problem for files that previously were affected.<br>
15:18 - @godofredoc attempts to rebuild the affected files.<br>

### 2023-03-28

05:38 - User @FusoraTech reports having a similar problem.<br>
08:47 - @godofredoc confirms using Google Cloud Storage audit logs that the affected artifact never changed while in storage.<br>
10:28 - @gpencergoog reports that Microsoft confirmed the submission did not contain malware.<br>
10:39 - @Hixie closes the issue as a transient Windows Defender issue.<br>

## Impact

Several users reported being unable to use Flutter.

Some tests in continuous integration failed.

## Root causes

As best we can determine, the cause was a transient issue with Windows Defender that caused certain Flutter binaries to be flagged as having the Trojan:Script/Wacatac.B!ml trojan when downloaded.

## History

This is not the first time Flutter binaries have been labeled as "Trojan:Script/Wacatac.B!ml" by Windows Defender.

In March 2021, @esDotDev reported a similar problem in [#78463](https://github.com/flutter/flutter/issues/78463), though at the time we were unable to reproduce it and the issue was closed due to insufficient information.

In January 2023, @anggoran reported a similar problem in [#118430](https://github.com/flutter/flutter/issues/118430). We were again unable to reproduce the problem and closed the issue.

In general there is a history of false positives with virus tools, we generally mark them as duplicates of [#95167](https://github.com/flutter/flutter/issues/95167) which is a non-actionable placeholder issue for us, or [#61997](https://github.com/flutter/flutter/issues/61997), which is an umbrella issue tracking any work we would do to react more gracefully when antivirus tools flag Flutter components or generated code as malware.

## Lessons learned

This section refers to the actual root cause, i.e., a false positive in Windows Defender. It may be worth considering our processes for handling a similar situation in the event that it was real.

### What worked

We did not in fact get compromised.

Our release bucket has audit logs configured, which allowed us to check that the artifact was not modified after the initial upload.

### Where we got lucky

The damage caused by the false positive seems to have been minimal. We are only aware of three user reports, the CI failures happened mainly over a weekend, and the tests were not reliably failing so rerunning the bots allowed PRs to land. There was no press cycle, and a quick Google search found no mention of this in social media channels.

### What didn't work

Windows Defender, obviously.

Our builds are not reproducible: rerunning the same build stage does not create identical bits. This makes it hard for us to confirm that builds are not compromised by rerunning the build in a new VM.

Had this been a real compromise, our response rate would not have been especially prompt.

We do not have a way to communicate effectively to our users about incidents like this.

We don’t know the appropriate identification information/channel to expedite malware analysis at Microsoft (or other antivirus providers), even though that channel almost certainly exists and is available to us.

Devs did not have quick access to Windows machines to be able to attempt to reproduce the behavior, adding extra time to the triage process.

Although we have audit logs enabled, there was no documentation on how to search them, also adding to the total triage time.

We don't publish the hashes of the artifacts we allow developers to download. One user who was affected by this failure asked if there was a list anywhere so that they could verify their download locally.

## Action items

### Prevention

It is unclear what we can do to avoid such problems in the future.

### Detection

We could intentionally run Windows Defender updates and scans against recent artifacts continually to detect when an event occurs.

### Mitigation

It's unclear there is much we can do to prevent third-party tools from accidentally reporting Flutter as malware.

### Process

As part of this incident we created a new Discord channel, #incident-response. We should document this.

### Fixes

No fixes were necessary.

### Documentation

Add documentation on how Flutter infra can triage these issues quicker through audit logs.

## Appendix

### #incident-response logs

```discord
[1:04 PM]Hixie: @Drewroen @Greg Spencer (gspencergoog) @timsneath let's coordinate here so we're not all speaking in different venues
[1:04 PM]Hixie: current issue is https://github.com/flutter/flutter/issues/123519
[1:05 PM]Hixie: greg and/or drew are you able to upload the affected file to the site tim gave?
[1:21 PM]Greg Spencer (gspencergoog): I would, but I'm not sure how to sign in. Am I an "enterprise customer", or a "software developer"? Apparently you have to sign in to a Microsoft account before submitting it, and I'm not sure what account is the correct one to use (Is it OK to associate my @google.com account with my GitHub account for MS login?, Should I use a personal GitHub account?, etc.)
[1:37 PM]Greg Spencer (gspencergoog): Okay, I figured out how to log in.
[1:43 PM]Greg Spencer (gspencergoog): I've submitted it, but it's unclear when we'll get a response. I submitted it at "normal" priority because I didn't have the necessary ID numbers to submit it with Google enterprise credentials to get a higher priority.
[1:44 PM]Hixie: sounds good, can you update the issue as well?
[1:44 PM]Hixie: and thanks for your help here
[1:44 PM]Greg Spencer (gspencergoog): Yes.
[1:44 PM]Greg Spencer (gspencergoog): No problem.
[1:45 PM]Drewroen: (Catching up now, had a meeting) Thank you for submitting, @Greg Spencer (gspencergoog)!
[1:48 PM]Hixie: @Greg Spencer (gspencergoog) do you get anything useful if you upload the file to https://www.virustotal.com/gui/home/upload ?
[2:18 PM]Greg Spencer (gspencergoog): No, it doesn't detect any threats.
[2:19 PM]Greg Spencer (gspencergoog): I'm trying to figure out how to download previous versions of the gen_snapshot tool and see if they too trigger the quarantine.
[2:20 PM]Greg Spencer (gspencergoog): Anyone know how to find out the hash on the flutter_infra_release gcs instance for a previous release?
[2:23 PM]Greg Spencer (gspencergoog): Is it just the full github hash for the release? (You'd think I'd know this: I think I wrote it originally! I just can't remember)
[2:33 PM]Greg Spencer (gspencergoog): What is the "windows-x64.zip" file from?  Is that from a Dart distro?
[2:33 PM]Drewroen: Maybe there's a simpler way, but I found the release commit for flutter/flutter for 3.7.7, then got the engine version from https://github.com/flutter/flutter/blob/2ad6cd72c040113b47ee9055e722606a490ef0da/bin/internal/engine.version and used that hash in the storage.googleapis url

Long story short, this should be the engine artifact for the 3.7.7 windows stable: https://storage.googleapis.com/flutter_infra_release/flutter/1837b5be5f0f1376a1ccf383950e83a80177fb4e/android-x64-release/windows-x64.zip
[2:33 PM]Greg Spencer (gspencergoog): The Flutter version seems to be windows-x64-flutter.zip, and doesn't appear to have the problem (at least in the latest master build)
[2:34 PM]Greg Spencer (gspencergoog): Ahh, so it's in an Engine build.
[2:36 PM]Greg Spencer (gspencergoog): OK, so that 3.7.7 binary doesn't seem to trigger the quarantine.
[2:40 PM]Hixie: do we have any way to check if the machine on which we did the builds is compromised?
[2:40 PM]Hixie: cc @Godofredo Contreras (godofredoc)
[2:45 PM]Greg Spencer (gspencergoog): Actually, I just tried unpacking the original windows-x64.zip file that triggered the quarantine before, and it no longer flags the file.  As far as I know, it's the same file I unpacked before, and the same zip file I uploaded to MS for analysis.
[2:45 PM]Greg Spencer (gspencergoog): Perhaps they've updated their cloud definitions and corrected an incorrect definition?
[2:46 PM]Greg Spencer (gspencergoog): I haven't updated my local definitions, so it would have to be something online.
[3:05 PM]Godofredo Contreras (godofredoc): @Hixie those are ephemeral VMs recycled every 24 hours. There is no way to access it.
[3:06 PM]Godofredo Contreras (godofredoc): Let me get the builder that file was generated on, if the machine was compromised I'd expect all the other artifacts from the same build to also be infected
[3:08 PM]Godofredo Contreras (godofredoc): @Greg Spencer (gspencergoog) that's correct only prod service accounts and release engineers have access to update artifacts. I would not expect the file to be updated but we can check our trail logs just in case
[3:09 PM]Greg Spencer (gspencergoog): I completely agree. Also, the same file I originally downloaded earlier today no longer triggers it, and it is identical to the one I just downloaded now (same sha256sum).
[3:10 PM]Greg Spencer (gspencergoog): So I think we can rule out someone replacing the file with an innocuous one.
[3:11 PM]Greg Spencer (gspencergoog): The submission to MS is still "pending".
[3:13 PM]Greg Spencer (gspencergoog): My money is on MS Defender just falsely flagging the file, and them updating their definitions.
[3:15 PM]Hixie: that does seem most likely, but i would hate for us to assume that is the case and then later find it isn't :-)
[3:15 PM]Greg Spencer (gspencergoog): Oh, definitely!
[3:15 PM]Greg Spencer (gspencergoog): I haven't closed the issue yet. :-)
[3:16 PM]Hixie: @Godofredo Contreras (godofredoc)  if we rerun the build, do we get the same bits? it'd be a good test of our reproducible builds logic if we have it yet :-)
[3:18 PM]Godofredo Contreras (godofredoc): not sure, but let me give it a try
[4:40 PM]Hixie: @Godofredo Contreras (godofredoc) any luck?
[4:56 PM]Godofredo Contreras (godofredoc): The build has not finished yet, I'm using https://ci.chromium.org/p/flutter/builders/prod/Windows%20Host%20Engine/21257
[4:58 PM]Godofredo Contreras (godofredoc): I'll validate using this artifact https://storage.cloud.google.com/flutter_infra_release/flutter/8cb080365fb189a1e5d1e33a991518f2422e319b/dart-sdk-windows-x64.zip
[4:59 PM]Greg Spencer (gspencergoog): Can anyone else with a Windows machine reproduce the quarantine that used to happen if you download and unpack https://storage.googleapis.com/flutter_infra_release/flutter/685fbc6f4d9db8026c56ee1a177bb10cc09f884b/android-x64-release/windows-x64.zip ?
[5:00 PM]Greg Spencer (gspencergoog): It's not happening for me anymore.
[5:00 PM]Godofredo Contreras (godofredoc): let me check on my windows pc
[5:00 PM]Godofredo Contreras (godofredoc): @Greg Spencer (gspencergoog) which win OS are you using?
[5:00 PM]Greg Spencer (gspencergoog): Windows 11
[5:01 PM]Godofredo Contreras (godofredoc): ok, my computer is windows 10
[5:01 PM]Greg Spencer (gspencergoog): But I think the build servers are running Windows 10, right? And they saw the same issue.
[5:02 PM]Godofredo Contreras (godofredoc): yes, they are using win 10
[5:07 PM]Godofredo Contreras (godofredoc): were you getting the error when downloading? or when extracting?
[5:08 PM]Greg Spencer (gspencergoog): After extracting the zip file.
[5:08 PM]Greg Spencer (gspencergoog): It quarantined the gen_snapshot.exe file.
[5:10 PM]Godofredo Contreras (godofredoc): new behavior with downloads?
[5:11 PM]Godofredo Contreras (godofredoc): after downloading and extracting I get a blue window with message "Microsoft defender smartscreen prevented an unrecognized app from starting"
[5:12 PM]Godofredo Contreras (godofredoc): more info -> App: gen_snapshot.exe publisher: unknown publisher
[5:12 PM]Godofredo Contreras (godofredoc): with the option run anyway and don't run
[5:13 PM]Godofredo Contreras (godofredoc): I wonder if they started forcing | will start enforcing app signing
[5:15 PM]Godofredo Contreras (godofredoc): do you know how the flutter tool downloads binaries in win?
[5:16 PM]Godofredo Contreras (godofredoc): @Hixie https://luci-milo.appspot.com/raw/build/logs.chromium.org/flutter/led/godofredoc_google.com/9d161b36a3996876610f0a49660b9e0fd37f7e43881c33f17aa9fa0f5ec277f8/+/build.proto, I'll validate hashes once the build is complete
[5:31 PM]Greg Spencer (gspencergoog): It also might vary according to the system configuration. Mine is a stock Windows 11 install, not a corp machine.
[5:34 PM]Godofredo Contreras (godofredoc): mine is a win 10 with stock windows
[5:40 PM]Godofredo Contreras (godofredoc): Confirmed our builds are not replicable, sha for the test file in GCS 873d80acf1855733ce11a5b569859b6bc803ee38035cfb3491c0e3748544a48e and the one generated from a rebuild using the same build configs 57573123fff2713032b31cd8d99e30e79c0452516a54388c7aa237b8da1890b4
[5:41 PM]Hixie: that could mean the first one was bad or, more likely, that we just haven't managed to get replicable builds yet, right?
[5:45 PM]Godofredo Contreras (godofredoc): I used a build from a couple of hours ago for the validation, the two builds are correct
[5:46 PM]Godofredo Contreras (godofredoc): is just that we may use some compilation/linker flags that impacts replicability or maybe we are using timestamps somewhere in the build system
[5:46 PM]Godofredo Contreras (godofredoc): I haven't validate it yet the logs for the artifact, but let me do that
[5:49 PM]Hixie: does the new version also trigger windows defender?
[5:51 PM]Godofredo Contreras (godofredoc): In my windows machine it consistently blocks the execution on any binaries downloaded from the internet, until I explicitly allow them to run
[6:09 PM]Godofredo Contreras (godofredoc): AI: document how to audit GCS logs
[6:21 PM]Godofredo Contreras (godofredoc): There is a single log: event=storage.objects.create
[6:21 PM]Godofredo Contreras (godofredoc): timestamp: "2023-03-24T22:19:48.210794479Z"
[6:22 PM]Godofredo Contreras (godofredoc): auth: "flutter-prod-builder@chops-service-accounts.iam.gserviceaccount.com"
[6:31 PM]Godofredo Contreras (godofredoc): ok, rewinding everything to use the right data
[6:32 PM]Godofredo Contreras (godofredoc): Stable - 3.7.7 was https://github.com/flutter/flutter/commit/2ad6cd72c040113b47ee9055e722606a490ef0da
[6:32 PM]Godofredo Contreras (godofredoc): which is using engine 1837b5be5f0f1376a1ccf383950e83a80177fb4e
[6:33 PM]Godofredo Contreras (godofredoc): The artifact to validate is https://storage.googleapis.com/flutter_infra_release/flutter/1837b5be5f0f1376a1ccf383950e83a80177fb4e/android-x64-release/windows-x64.zip
[6:40 PM]Godofredo Contreras (godofredoc): Single log, create object event, timestamp: "2023-03-08T06:05:16.234063683Z" by flutter-prod-builder@chops-service-accounts.iam.gserviceaccount.com"
[6:42 PM]Godofredo Contreras (godofredoc): which correlates with the information in the builder https://ci.chromium.org/p/flutter/builders/prod/Windows%20Host%20Engine/20852
[6:44 PM]Godofredo Contreras (godofredoc): the end time of the build is 2023-03-08T06:16:58Z
[6:45 PM]Godofredo Contreras (godofredoc): Defender is not finding any issues with the file on my Win 10 machine
[8:45 PM]Hixie: so at this point we're not able to reproduce the problem, basically?
[10:34 AM]Greg Spencer (gspencergoog): When I download the new artifact, it has the same sha256sum as the one I downloaded from the original build with this issue.  Unpacking the zip file still doesn't trigger any quarantine.
[10:34 AM]Greg Spencer (gspencergoog): As I reported in the bug, MS also found no issue with the contents of the zip file.
[10:34 AM]Greg Spencer (gspencergoog):
Image
[10:35 AM]Greg Spencer (gspencergoog): (both the automated "No malware detected" and the analyst "Not malware" determination)
[10:40 AM]Greg Spencer (gspencergoog): Unless someone can come up with a reproduction case, I think all we can do now is probably close the incident.
[10:45 AM]Hixie: agreed. thanks greg and everyone else who worked on this.
[10:45 AM]Hixie: i've closed the issue.
[10:46 AM]Greg Spencer (gspencergoog): No problem!
[10:47 AM]Godofredo Contreras (godofredoc): One thing that I'd like to get feedback is how can we do better in this situation? some thoughts:
[10:48 AM]Godofredo Contreras (godofredoc): a) Get non corp win machines for the security team.
[10:48 AM]Godofredo Contreras (godofredoc): b) Document the process to audit an artifact, including how to get the right SHAs for a given release version
[10:49 AM]Godofredo Contreras (godofredoc): c) [medium/long term] start working on replicable builds
[10:49 AM]Hixie: do we want to write a mini postmortem about it?
[10:49 AM]Greg Spencer (gspencergoog): I think that seems like a good idea.
[10:50 AM]Godofredo Contreras (godofredoc): Yes, that will be helpful. In a real threat scenario we won't have the luxury of figuring out things with the research step spanning during multiple hours
[10:51 AM]Greg Spencer (gspencergoog): Agreed.
[10:52 AM]Godofredo Contreras (godofredoc): Also forgot d) Sign windows binaries
[10:52 AM]Greg Spencer (gspencergoog): In this particular case, signing the binaries would have let us narrow where we were looking.
[10:53 AM]Greg Spencer (gspencergoog): And in the end, you seem to have produced an artifact with the same sha256.
[10:54 AM]Godofredo Contreras (godofredoc): no, I used a different commit and uploaded to an experimental location, the hashes were different
[10:55 AM]Greg Spencer (gspencergoog): Oh?  Well the one you posted above with "The artifact to validate:" had the same sha256 as the original artifact that triggered the quarantine.
[10:55 AM]Greg Spencer (gspencergoog): This one: https://storage.googleapis.com/flutter_infra_release/flutter/1837b5be5f0f1376a1ccf383950e83a80177fb4e/android-x64-release/windows-x64.zip
[10:56 AM]Greg Spencer (gspencergoog): The commit hashes might have been different, but the artifact wasn't.
[10:56 AM]Godofredo Contreras (godofredoc): aaaah ok, yeah I downloaded that file and validated locally extracting and running defender on my win machine
[10:56 AM]Greg Spencer (gspencergoog): Okay, so did I test the right thing?
[10:57 AM]Godofredo Contreras (godofredoc): let me double check, I validated both 3.7.7 and 3.7.8
[10:57 AM]Greg Spencer (gspencergoog): Because this was the original artifact we found the problem in: https://storage.googleapis.com/flutter_infra_release/flutter/685fbc6f4d9db8026c56ee1a177bb10cc09f884b/android-x64-release/windows-x64.zip
[10:59 AM]Godofredo Contreras (godofredoc): 3.7.8 hash is 9aa7816315095c86410527932918c718cb35e7d6
[10:59 AM]Greg Spencer (gspencergoog): That's a sha1 from the windows-64.zip, right?
[10:59 AM]Godofredo Contreras (godofredoc): 3.7.7 has is 1837b5be5f0f1376a1ccf383950e83a80177fb4e
[11:00 AM]Godofredo Contreras (godofredoc): that's the commit hash for the engine artifacts
[11:00 AM]Greg Spencer (gspencergoog): Ahh, OK.
[11:02 AM]Greg Spencer (gspencergoog): Git makes a new hash for each commit even if the content doesn't change, so those would have to be different.  I thought you had posted the link to a newly built version of the same artifact. If that's not what that was, then what was it?
[11:35 AM]Hixie: https://docs.google.com/document/d/1g5LyqB4uezd-5xNYMwlTBbWTntHhyjLCBYI_ZInX-R0/edit?usp=sharing postmortem doc (currently just the template) - this is a markdown file for putting on the wiki
[11:35 AM]Hixie: (right now everyone has edit access so don't share that link outside the team)
[11:39 AM]Godofredo Contreras (godofredoc): @Greg Spencer (gspencergoog) this is the build I used for validating if the builds are replicable https://luci-milo.appspot.com/raw/build/logs.chromium.org/flutter/led/godofredoc_google.com/9d161b36a3996876610f0a49660b9e0fd37f7e43881c33f17aa9fa0f5ec277f8/+/build.proto
[11:41 AM]Godofredo Contreras (godofredoc): I compared some of the artifacts in that build(experimental) with the ones in the release bucket
[11:42 AM]Godofredo Contreras (godofredoc): e.g. https://storage.cloud.google.com/flutter_infra_release/flutter/experimental/8cb080365fb189a1e5d1e33a991518f2422e319b/windows-x64-debug/windows-x64-flutter.zip vs https://storage.cloud.google.com/flutter_infra_release/flutter/8cb080365fb189a1e5d1e33a991518f2422e319b/windows-x64-debug/windows-x64-flutter.zip
[11:54 AM]Greg Spencer (gspencergoog): Yes, those aren't even the same size (by several hundred K), so they definitely are different artifacts.
[11:59 AM]Greg Spencer (gspencergoog): So I see why you want to work on making reproducible builds.
```
