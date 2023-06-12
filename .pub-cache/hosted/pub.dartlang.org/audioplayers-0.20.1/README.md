# AudioPlayers

[![Pub](https://img.shields.io/pub/v/audioplayers.svg?style=popout)](https://pub.dartlang.org/packages/audioplayers) [![Build Status](https://github.com/luanpotter/audioplayers/workflows/build/badge.svg?branch=master)](https://github.com/luanpotter/audioplayers/actions?query=workflow%3A"build"+branch%3Amaster) [![Discord](https://img.shields.io/discord/509714518008528896.svg)](https://discord.gg/pxrBmy4)

A Flutter plugin to play multiple simultaneously audio files, works for Android, iOS, macOS and web.

![](/images/tab1s.jpg) ![](/images/tab2s.jpg) ![](/images/tab3s.jpg)

## Contributing

We now have new rules for contributing!

All help is appreciated but if you have questions, bug reports, issues, feature requests, pull requests, etc, please first refer to our [Contributing Guide](contributing.md).

Also, as always, please give us a star to help!

## Support us

You can support us by becoming a patron on Patreon, any support is much appreciated.

[![Patreon](https://c5.patreon.com/external/logo/become_a_patron_button.png)](https://www.patreon.com/fireslime)

## Feature Parity Table

Not all features are available on all platforms. [Click here](feature_parity_table.md) to see a table relating what features can be used on each target.

Feel free to use it for ideas for possible PRs and contributions you can help with on our roadmap! If you are submiting a PR, don't forget to update the table.

## Usage

An `AudioPlayer` instance can play a single audio at a time. To create it, simply call the constructor:

```dart
    AudioPlayer audioPlayer = AudioPlayer();
```

To use the low latency API, better for gaming sounds, use:

```dart
    AudioPlayer audioPlayer = AudioPlayer(mode: PlayerMode.LOW_LATENCY);
```

In this mode the backend won't fire any duration or position updates.
Also, it is not possible to use the seek method to set the audio a specific position.
This mode is also not available on web.

You can create multiple instances to play audio simultaneously.

For all methods that return a `Future<int>`: that's the status of the operation. If `1`, the operation was successful. Otherwise, it's the platform native error code.

Logs are disable by default! To debug, run:

```dart
  AudioPlayer.logEnabled = true;
```

### Playing Audio

There are four possible sources of audio:

- Remote file on the Internet
- Local file on the user's device
- Local asset from your Flutter project
- Audio in the form of a byte array (in Flutter, Uint8List)

Both for Remote Files or Local Files, use the `play` method, just setting appropriately the flag `isLocal`.

For Local Assets, you have to use the `AudioCache` class (see below).

To play a Remote File, just call `play` with the url (the `isLocal` parameter is false by default):

If you want to play audio for a long period of time, you need to set appropriately the flag `stayAwake`,
If you pass `stayAwake` as true you need to add this permission to your app manifest:
`<uses-permission android:name="android.permission.WAKE_LOCK" />`.

```dart
  play() async {
    int result = await audioPlayer.play(url);
    if (result == 1) {
      // success
    }
  }
```

For a Local File, add the `isLocal` parameter:

```dart
  playLocal() async {
    int result = await audioPlayer.play(localPath, isLocal: true);
  }
```

To play a file in the form of a data buffer (Uint8List), use the method `playBytes`.
This currently only works for Android (requiring API >= 23, be sure to handle that if you use this method on your code).

```dart
  playLocal() async {
    Uint8List byteData = .. // Load audio as a byte array here.
    int result = await audioPlayer.playBytes(byteData);
  }
```

The `isLocal` flag is required only because iOS and macOS make a difference about it (Android doesn't care either way).

There is also an optional named `double volume` parameter, that defaults to `1.0`. It can go from `0.0` (mute) to `1.0` (max), varying linearly.

The volume can also be changed at any time using the `setVolume` method.

### Controlling

Note: these features are not implemented in web yet.

After playing, you can control the audio with pause, stop and seek commands.

Pause will pause the audio but keep the cursor where it was. Subsequently calling play will resume from this point.

```dart
  int result = await audioPlayer.pause();
```

Stop will stop the audio and reset the cursor. Subsequently calling play will resume from the beginning.

```dart
  int result = await audioPlayer.stop();
```

Finally, use seek to jump through your audio:

```dart
  int result = await audioPlayer.seek(Duration(milliseconds: 1200));
```

Also, you can resume (like play, but without new parameters):

```dart
  int result = await audioPlayer.resume();
```

### Finer Control

By default, the player will be release once the playback is finished or the stop method is called.

This is because on Android, a MediaPlayer instance can be quite resource-heavy, and keep it unreleased would cause performance issues if you play lots of different audios.

On iOS and macOS this doesn't apply, so release does nothing.

You can change the Release Mode to determine the actual behavior of the MediaPlayer once finished/stopped. There are three options:

- RELEASE: default mode, will release after stop/completed.
- STOP: will never release; calling play should be faster.
- LOOP: will never release; after completed, it will start playing again on loop.

If you are not on RELEASE mode, you should call the release method yourself; for example:

```dart
  await audioPlayer.setUrl('clicking.mp3'); // prepare the player with this audio but do not start playing
  await audioPlayer.setReleaseMode(ReleaseMode.STOP); // set release mode so that it never releases

  // on button click
  await audioPlayer.resume(); // quickly plays the sound, will not release

  // on exiting screen
  await audioPlayer.release(); // manually release when no longer needed
```

Despite the complex state diagram of Android's MediaPlayer, an AudioPlayer instance should never have an invalid state. Even if it's released, if resume is called, the data will be fetch again.

#### Stream routing
You can choose between speakers and earpiece. By default using speakers.
Toggle between speakers and earpiece.
```
int result = await player.earpieceOrSpeakersToggle();
```

### Streams

Note: streams are not available on web yet.

The AudioPlayer supports subscribing to events like so:

#### Duration Event

This event returns the duration of the file, when it's available (it might take a while because it's being downloaded or buffered).

```dart
  player.onDurationChanged.listen((Duration d) {
    print('Max duration: $d');
    setState(() => duration = d);
  });
```

#### Position Event

This Event updates the current position of the audio. You can use it to make a progress bar, for instance.

```dart
  player.onAudioPositionChanged.listen((Duration  p) => {
    print('Current position: $p');
    setState(() => position = p);
  });
```

#### State Event

This Event returns the current player state. You can use it to show if player playing, or stopped, or paused.

```dart
  player.onPlayerStateChanged.listen((PlayerState s) => {
    print('Current player state: $s');
    setState(() => playerState = s);
  });
```

#### Completion Event

This Event is called when the audio finishes playing; it's used in the loop method, for instance.

It does not fire when you interrupt the audio with pause or stop.

```dart
  player.onPlayerCompletion.listen((event) {
    onComplete();
    setState(() {
      position = duration;
    });
  });
```

#### Error Event

This is called when an unexpected error is thrown in the native code.

```dart
  player.onPlayerError.listen((msg) {
    print('audioPlayer error : $msg');
    setState(() {
      playerState = PlayerState.stopped;
      duration = Duration(seconds: 0);
      position = Duration(seconds: 0);
    });
  });
```

### AudioCache

In order to play Local Assets, you must use the `AudioCache` class. AudioCache is not available for Flutter Web.

Flutter does not provide an easy way to play audio on your assets, but this class helps a lot. It actually copies the asset to a temporary folder in the device, where it is then played as a Local File.

It works as a cache because it keeps track of the copied files so that you can replay them without delay.

You can find the full documentation for this class [here](https://github.com/luanpotter/audioplayers/blob/master/packages/audioplayers/doc/audio_cache.md).

### playerId

By default, each time you initialize a new instance of AudioPlayer a unique playerId is generated and assigned using [uuid package](https://pub.dev/packages/uuid), this is designed this way to play multiple audio files simultaneously, if you want to play using the same instance that was created before simply pass your playerId when creating a new AudioPlayer instance.

```dart
final audioPlayer = AudioPlayer(playerId: 'my_unique_playerId');
```

## Supported Formats

You can check a list of supported formats below:

- [Android](https://developer.android.com/guide/topics/media/media-formats.html)
- [iOS and macOS](https://www.techotopia.com/index.php/Playing_Audio_on_iOS_8_using_AVAudioPlayer#Supported_Audio_Formats)
- web: audio formats supported by the browser you are using ([more details](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API))

## :warning: iOS & macOS App Transport Security

By default iOS and macOS forbid loading from non-https url. To cancel this restriction on iOS or macOS you must edit your `.plist` and add:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```
## :warning: macOS Outgoing Connections

By default, Flutter macOS apps don't allow outgoing connections, so playing audio files/streams from the internet won't work. To fix this, add the following to the `.entitlements` files for your app:

```xml
<key>com.apple.security.network.client</key>
<true/>
```

**Note:** On Android by default, there is a restriction not allowing traffic from HTTP resources. There is a fix for this and it requires
adding `android:usesCleartextTraffic="true"` within your AndroidManifest.xml file located in `android/app/src/main/AndroidManifest.xml`.

Here is an example of how it should look like:
```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest ...>
    <uses-permission android:name="android.permission.INTERNET" />
    <application
        ...
        android:usesCleartextTraffic="true"
        ...>
        ...
    </application>
</manifest>
```

## Android Support

Giving support to old Android devices is very hard, on this plugin we set the minSdk as 16, but we only ensure support >= 23 as that is the minimum version that the team has devices available to test changes and new features.

This mean that, Audioplayer should work on older devices, but we can't give any guarantees, we will not be able to look after issues regarding API < 23. But we would glady take any pull requests from the community that fixes or improve support on those old versions.

## Background playing

To control playback from lock screen on iOS and Android you can use [audio_service](https://pub.dev/packages/audio_service). [Example](https://denis-korovitskii.medium.com/flutter-demo-audioplayers-on-background-via-audio-service-c95d65c90ae1) how to implement all AudioPlayers features with and audio_service.

## Credits

This was originally a fork of [rxlabz's audioplayer](https://github.com/rxlabz/audioplayer), but since we have diverged and added more features.

Thanks for @rxlabz for the amazing work!
