Sky SDK
=======

We're still iterating on Sky heavily, which means the framework and underlying
engine are both likely to change in incompatible ways several times, but if
you're interested in trying out the system, this document can help you get
started.

Set up your computer
--------------------

1. Install the Dart SDK:
  - https://www.dartlang.org/tools/download.html

2. Install the ``adb`` tool from the Android SDK:
  - https://developer.android.com/sdk/installing/index.html

3. Install the Sky SDK:
  - ``git clone https://github.com/domokit/sky_sdk.git``

4.  Ensure sure $DART_SDK is set to the path of your Dart SDK and 'adb'
    (inside 'platform-tools' in the android sdk) is in your $PATH.

Set up your device
------------------

Currently Sky requires an Android device running the Lollipop (or newer) version
of the Android operating system.

1. Enable developer mode on your device by visiting ``Settings > About phone``
   and tapping the ``Build number`` field five times.

2. Enable ``USB debugging`` in ``Settings > Developer options``.

3. Using a USB cable, plug your phone into your computer. If prompted on your
   device, authorize your computer to access your device.

Running a Sky application
-------------------------

1. ``sky_sdk/bin/sky --install sky_sdk/examples/index.sky``
   The --install flag is only necessary the first time to install SkyDemo.apk.

2.  Use ``adb logcat`` to view any errors or Dart print() output from the app.
