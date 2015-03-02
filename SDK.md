Sky SDK
=======

This document describes an experimental development kit for Sky. We're still
iterating on Sky heavily, which means the framework and underlying engine are
both likely to change in incompatible ways several times, but if you're
interested in trying out the system, this document can help you get started.

Set up your device
------------------

Currently Sky requires an Android device running the Lollipop (or newer) version
of the Android operating system.

1. Install ``Sky`` on your device by via the Play Store. The Sky app on your
   device is capable of displaying applications written using Sky.

2. Enable developer mode on your device by visiting ``Settings > About phone``
   and tapping the ``Build number`` field five times.

3. Enable ``USB debugging`` in ``Settings > Developer options``.

Set up your computer
--------------------

1. Install the ``adb`` tool from the Android SDK.
  - Mac: ``brew install android-platform-tools``
  - Linux: ``sudo apt-get install android-tools-adb``

2. Download the Sky framework:
  a. ``curl -O https://domokit.github.io/sky-sdk.tgz``
  b. ``tar -xvzf sky-sdk.tgz``

3. Using a USB cable, plug your phone into your computer. If prompted on your
   device, authorize your computer to access your device.

Running a Sky application
-------------------------

1. ``/path/to/sky-sdk/run myapp.sky && adb logcat``
