Animated GIFs are useful for documentating animations. Here’s how to make them:

## Capturing video of an Android device

 * This feature is available on KitKat and later.
 * Make sure to launch the app using `flutter run --release` for faster performance.
 * Start recording video by running this command on the command line:

    ```adb shell screenrecord /sdcard/recording.mp4```

 * Interact with the app. When you are done you can terminate the recording with CTRL+c.

 * Pull the recording off the device and onto your local hard drive:

    ```adb pull /sdcard/recording.mp4 ~/Downloads/```

## Capturing video of the iOS simulator

 * Move the iOS simulator above your other applications
 * Launch the "QuickTime Player" app
 * Select “New Screen Recording” from the File menu
 * Draw a box around the Simulator and click "Start Recording"
 * When you're finished, click on Stop Recording on the Menu Bar.
 * If needed, trim your recording using "Trim" from the "Edit" menu.
 * Save the recording

## Converting the recording to GIF

 * Go to http://ezgif.com/video-to-gif and upload the video.
 * If further trimming is needed, select the start and end times for your GIF.
 * Select an appropriately small size for the GIF (recommended: 320xAUTO).
 * Select a high framerate for the GIF (the max is 20) for smoothest animation
 * Convert to GIF and download the GIF file

## Example

![Example Animated GIF](http://i.imgur.com/tSqVQkx.gif)