---
name: My app is slow or missing frames.
about: You are writing an application but have discovered that it is slow, you are
  not hitting 60Hz, or you are getting jank (missed frames).
title: ''
labels: 'created via performance template'
assignees: ''

---

<!-- Thank you for using Flutter!

     If you are looking for support, please check out our documentation
     or consider asking a question on Stack Overflow:
      * https://flutter.dev/
      * https://api.flutter.dev/
      * https://stackoverflow.com/questions/tagged/flutter?sort=frequent

     Issues directly asking for support will be closed.

     If you have found a performance problem, then fill out the template below.
     Please read our guide to filing a bug first: https://flutter.dev/docs/resources/bug-reports
-->

## Details

<!--
     Please describe in detail the problem you are running into.
-->

<!--
     Switch flutter to master channel and run this app on a physical device
     using profile mode with Skia tracing enabled, as follows:
       flutter channel master
       flutter run --profile --trace-skia

     The bleeding edge master channel is encouraged here because Flutter is
     constantly fixing bugs and improving its performance. Your problem in an
     older Flutter version may have already been solved in the master channel.
-->

<!--
     Open Observatory and save a timeline trace of the performance issue
     so we know which functions might be causing it. See "How to Collect
     and Read Timeline Traces" on this blog post:
       https://medium.com/flutter/profiling-flutter-applications-using-the-timeline-a1a434964af3#a499

     Make sure the performance overlay is turned OFF when recording the
     trace as that may affect the performance of the profile run.
     (Pressing ‘P’ on the command line toggles the overlay.)
-->

<!--
     Please tell us which target platform(s) the problem occurs (Android / iOS / Web / macOS / Linux / Windows)
     Which target OS version, for Web, browser, is the test system running?
     Does the problem occur on emulator/simulator as well as on physical devices?
-->

**Target Platform:**
**Target OS version/browser:**
**Devices:**



<details>
<summary>Code sample</summary>

<!--
     Please create a minimal reproducible sample that shows the problem
     and attach it below between the lines with the backticks.

     Without this we will unlikely progress on the issue, and thus will have
     to close it.

     If your problem goes out of what can be placed in file, for example
     you have a problem with native channels, you can upload the full code of
     your reproduction into a separate repository and link it.
-->

```dart
```

</details>


<details>
<summary>flutter analyze</summary>

<!--
     Run `flutter analyze` and attach any output of that command below.
     If there are any analysis errors, try resolving them before filing this issue.
-->

```
```

</details>


<details>
<summary>flutter doctor -v</summary>

<!-- Paste the output of running `flutter doctor -v` here, with your device plugged in. -->

```
```

</details>



<!--
     Finally, record a video of the performance issue using another phone so we
     can have an intuitive understanding of what happened. Don’t use
     "adb screenrecord", as that affects the performance of the profile run.

     You can upload the video directly on GitHub.
     Beware that video file size is limited to 10MB.
-->
