# just_audio

just_audio is a feature-rich audio player for Android, iOS, macOS, web, Linux and Windows.

[Platform Support](#platform-support) — [API Documentation](https://pub.dev/documentation/just_audio/latest/just_audio/just_audio-library.html) — [Tutorials](#tutorials) — [Background Audio](https://pub.dev/packages/just_audio_background) — [Community Support](https://stackoverflow.com/questions/tagged/just-audio)

![Screenshot with arrows pointing to features](https://user-images.githubusercontent.com/19899190/125459608-e89cd6d4-9f09-426c-abcc-ed7513d9acfc.png)

### Quick synopsis

```dart
import 'package:just_audio/just_audio.dart';

final player = AudioPlayer();                   // Create a player
final duration = await player.setUrl(           // Load a URL
    'https://foo.com/bar.mp3');                 // Schemes: (https: | file: | asset: )
player.play();                                  // Play without waiting for completion
await player.play();                            // Play while waiting for completion
await player.pause();                           // Pause but remain ready to play
await player.seek(Duration(second: 10));        // Jump to the 10 second position
await player.setSpeed(2.0);                     // Twice as fast
await player.setVolume(0.5);                    // Half as loud
await player.stop();                            // Stop and free resources
```

### Working with multiple players

```dart
// Set up two players with different audio files
final player1 = AudioPlayer(); await player1.setUrl(...);
final player2 = AudioPlayer(); await player2.setUrl(...);

// Play both at the same time
player1.play();
player2.play();

// Play one after the other
await player1.play();
await player2.play();

// Loop player1 until player2 finishes
await player1.setLoopMode(LoopMode.one);
player1.play();          // Don't wait
await player2.play();    // Wait for player2 to finish
await player1.pause();   // Finish player1

// Free platform decoders and buffers for each player.
await player1.stop();
await player2.stop();
```

### Working with clips

```dart
// Play clip 2-4 seconds followed by clip 10-12 seconds
await player.setClip(start: Duration(seconds: 2), end: Duration(seconds: 4));
await player.play(); await player.pause();
await player.setClip(start: Duration(seconds: 10), end: Duration(seconds: 12));
await player.play(); await player.pause();

await player.setClip(); // Clear clip region
```

### Working with gapless playlists

```dart
// Define the playlist
final playlist = ConcatenatingAudioSource(
  // Start loading next item just before reaching it
  useLazyPreparation: true,
  // Customise the shuffle algorithm
  shuffleOrder: DefaultShuffleOrder(),
  // Specify the playlist items
  children: [
    AudioSource.uri(Uri.parse('https://example.com/track1.mp3')),
    AudioSource.uri(Uri.parse('https://example.com/track2.mp3')),
    AudioSource.uri(Uri.parse('https://example.com/track3.mp3')),
  ],
);

// Load and play the playlist
await player.setAudioSource(playlist, initialIndex: 0, initialPosition: Duration.zero);
await player.seekToNext();                     // Skip to the next item
await player.seekToPrevious();                 // Skip to the previous item
await player.seek(Duration.zero, index: 2);    // Skip to the start of track3.mp3
await player.setLoopMode(LoopMode.all);        // Set playlist to loop (off|all|one)
await player.setShuffleModeEnabled(true);      // Shuffle playlist order (true|false)

// Update the playlist
await playlist.add(newChild1);
await playlist.insert(3, newChild2);
await playlist.removeAt(3);
```

### Working with headers

```dart
// Setting the HTTP user agent
final player = AudioPlayer(
  userAgent: 'myradioapp/1.0 (Linux;Android 11) https://myradioapp.com',
);

// Setting request headers
final duration = await player.setUrl('https://foo.com/bar.mp3',
    headers: {'header1': 'value1', 'header2': 'value2'});
```

Note: headers are implemented via a local HTTP proxy which on Android, iOS and macOS requires non-HTTPS support to be enabled. See [Platform Specific Configuration](#platform-specific-configuration).

### Working with caches

```dart
// Clear the asset cache directory
await AudioPlayer.clearAssetCache();

// Download and cache audio while playing it (experimental)
final audioSource = LockCachingAudioSource('https://foo.com/bar.mp3');
await player.setAudioSource(audioSource);
// Delete the cached file
await audioSource.clearCache();
```

Note: `LockCachingAudioSource` is implemented via a local HTTP proxy which on Android, iOS and macOS requires non-HTTPS support to be enabled. See [Platform Specific Configuration](#platform-specific-configuration).

### Working with stream audio sources

```dart
// Feed your own stream of bytes into the player
class MyCustomSource extends StreamAudioSource {
  final List<int> bytes;
  MyCustomSource(this.bytes);
  
  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}

await player.setAudioSource(MyCustomSource());
player.play();
```

Note: `StreamAudioSource` is implemented via a local HTTP proxy which on Android, iOS and macOS requires non-HTTPS support to be enabled. See [Platform Specific Configuration](#platform-specific-configuration).


### Working with errors

```dart
// Catching errors at load time
try {
  await player.setUrl("https://s3.amazonaws.com/404-file.mp3");
} on PlayerException catch (e) {
  // iOS/macOS: maps to NSError.code
  // Android: maps to ExoPlayerException.type
  // Web: maps to MediaError.code
  // Linux/Windows: maps to PlayerErrorCode.index
  print("Error code: ${e.code}");
  // iOS/macOS: maps to NSError.localizedDescription
  // Android: maps to ExoPlaybackException.getMessage()
  // Web/Linux: a generic message
  // Windows: MediaPlayerError.message
  print("Error message: ${e.message}");
} on PlayerInterruptedException catch (e) {
  // This call was interrupted since another audio source was loaded or the
  // player was stopped or disposed before this audio source could complete
  // loading.
  print("Connection aborted: ${e.message}");
} catch (e) {
  // Fallback for all other errors
  print('An error occured: $e');
}

// Catching errors during playback (e.g. lost network connection)
player.playbackEventStream.listen((event) {}, onError: (Object e, StackTrace st) {
  if (e is PlayerException) {
    print('Error code: ${e.code}');
    print('Error message: ${e.message}');
  } else {
    print('An error occurred: $e');
  }
});
```

### Working with state streams

See [The state model](#the-state-model) for details.

```dart
player.playerStateStream.listen((state) {
  if (state.playing) ... else ...
  switch (state.processingState) {
    case ProcessingState.idle: ...
    case ProcessingState.loading: ...
    case ProcessingState.buffering: ...
    case ProcessingState.ready: ...
    case ProcessingState.completed: ...
  }
});

// See also:
// - durationStream
// - positionStream
// - bufferedPositionStream
// - sequenceStateStream
// - sequenceStream
// - currentIndexStream
// - icyMetadataStream
// - playingStream
// - processingStateStream
// - loopModeStream
// - shuffleModeEnabledStream
// - volumeStream
// - speedStream
// - playbackEventStream
```

## Credits

This project is supported by the amazing open source community of [GitHub contributors](https://github.com/ryanheise/just_audio/blob/minor/CONTRIBUTING.md) and [sponsors](https://github.com/sponsors/ryanheise). Thank you!

## Platform specific configuration

### Android

To allow your application to access audio files on the Internet, add the following permission to your `AndroidManifest.xml` file:

```xml
    <uses-permission android:name="android.permission.INTERNET"/>
```

If you wish to connect to non-HTTPS URLS, or if you use a feature that depends on the proxy such as headers, caching or stream audio sources, also add the following attribute to the `application` element:

```xml
    <application ... android:usesCleartextTraffic="true">
```

If you need access to the player's AudioSession ID, you can listen to `AudioPlayer.androidAudioSessionIdStream`. Note that the AudioSession ID will change whenever you set new AudioAttributes.

If there are multiple plugins in your app that use ExoPlayer to decode media, it is possible to encounter a `Duplicate class` error if those plugins use different versions of ExoPlayer. In this case you may report an issue for each respective plugin to upgrade to the latest version of ExoPlayer, or you may downgrade one or more of your app's plugins until the versions match. In some cases where a plugin uses non-breaking parts of the ExoPlayer API, you can also try forcing all plugins to use the same version of ExoPlayer by editing your own app's `android/app/build.gradle` file and inserting the dependencies for the desired Exoplayer version:

```
dependencies {
    def exoplayer_version = "...specify-version-here...."
    implementation "com.google.android.exoplayer:exoplayer-core:$exoplayer_version"
    implementation "com.google.android.exoplayer:exoplayer-dash:$exoplayer_version"
    implementation "com.google.android.exoplayer:exoplayer-hls:$exoplayer_version"
    implementation "com.google.android.exoplayer:exoplayer-smoothstreaming:$exoplayer_version"
}
```

### iOS

Using the default configuration, the App Store will detect that your app uses the AVAudioSession API which includes a microphone API, and for privacy reasons it will ask you to describe your app's usage of the microphone. If your app does indeed use the microphone, you can describe your usage by editing the `Info.plist` file as follows:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>... explain why the app uses the microphone here ...</string>
```

But if your app does not use the microphone, you can pass a build option to "compile out" any microphone code so that the App Store won't ask for the above usage description. To do so, edit your `ios/Podfile` as follows:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # ADD THE NEXT SECTION
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'AUDIO_SESSION_MICROPHONE=0'
      ]
    end
    
  end
end
```

If you wish to connect to non-HTTPS URLS, or if you use a feature that depends on the proxy such as headers, caching or stream audio sources, add the following to your `Info.plist` file:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

The iOS player relies on server headers (e.g. `Content-Type`, `Content-Length` and [byte range requests](https://developer.apple.com/library/archive/documentation/AppleApplications/Reference/SafariWebContent/CreatingVideoforSafarioniPhone/CreatingVideoforSafarioniPhone.html#//apple_ref/doc/uid/TP40006514-SW6)) to know how to decode the file and where applicable to report its duration. In the case of files, iOS relies on the file extension.

### macOS

To allow your macOS application to access audio files on the Internet, add the following to your `DebugProfile.entitlements` and `Release.entitlements` files:

```xml
    <key>com.apple.security.network.client</key>
    <true/>
```

If you wish to connect to non-HTTPS URLS, or if you use a feature that depends on the proxy such as headers, caching or stream audio sources, add the following to your `Info.plist` file:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

The macOS player relies on server headers (e.g. `Content-Type`, `Content-Length` and [byte range requests](https://developer.apple.com/library/archive/documentation/AppleApplications/Reference/SafariWebContent/CreatingVideoforSafarioniPhone/CreatingVideoforSafarioniPhone.html#//apple_ref/doc/uid/TP40006514-SW6)) to know how to decode the file and where applicable to report its duration. In the case of files, macOS relies on the file extension.

### Windows

Windows support is enabled by adding an additional dependency to your `pubspec.yaml` alongside `just_audio`. There are a number of alternative options:

* [just_audio_windows](https://pub.dev/packages/just_audio_windows)
* [just_audio_libwinmedia](https://pub.dev/packages/just_audio_libwinmedia)

Example:

```yaml
dependencies:
  just_audio: any # substitute version number
  just_audio_windows: any # substitute version number
```

For issues with the Windows implementation, please open an issue on the respective implementation's GitHub issues page.

### Linux

Linux support is enabled by adding an additional dependency to your `pubspec.yaml` alongside `just_audio`. There are a number of alternative options:

* [just_audio_mpv](https://pub.dev/packages/just_audio_mpv)
* [just_audio_libwinmedia](https://pub.dev/packages/just_audio_libwinmedia) (untested)

```yaml
dependencies:
  just_audio: any # substitute version number
  just_audio_mpv: any # substitute version number
```

For issues with the Linux implementation, please open an issue on the respective implementation's GitHub issues page.

### Mixing and matching audio plugins

The flutter plugin ecosystem contains a wide variety of useful audio plugins. In order to allow these to work together in a single app, just_audio "just" plays audio. By focusing on a single responsibility, different audio plugins can safely work together without overlapping responsibilities causing runtime conflicts.

Other common audio capabilities are optionally provided by separate plugins:

* [just_audio_background](https://pub.dev/packages/just_audio_background): Use this to allow your app to play audio in the background and respond to controls on the lockscreen, media notification, headset, AndroidAuto/CarPlay or smart watch.
* [audio_service](https://pub.dev/packages/audio_service): Use this if your app has more advanced background audio requirements than can be supported by `just_audio_background`.
* [audio_session](https://pub.dev/packages/audio_session): Use this to configure and manage how your app interacts with other audio apps (e.g. phone call or navigator interruptions).
* [just_waveform](https://pub.dev/packages/just_waveform): Use this to extract an audio file's waveform suitable for visual rendering.

## Tutorials

* [Create a simple Flutter music player app](https://ishouldgotosleep.com/simple-flutter-music-player-app/) by @mvolpato
* [Playing short audio clips in Flutter with Just Audio](https://suragch.medium.com/playing-short-audio-clips-in-flutter-with-just-audio-3c80eb7eb6ea?sk=aaf6cc523c2c6fc747b5087277932607) by @suragch
* [Streaming audio in Flutter with Just Audio](https://suragch.medium.com/steaming-audio-in-flutter-with-just-audio-7435fcf672bf?sk=c7163e8496b914c9e0e5446ec6020f04) by @suragch
* [Managing playlists in Flutter with Just Audio](https://suragch.medium.com/managing-playlists-in-flutter-with-just-audio-c4b8f2af12eb?sk=1b1ffa2cb0b3ed50a320d8cc32cef342) by @suragch

## Vote on upcoming features

Press the thumbs up icon on the GitHub issues you would like to vote on:

* Pitch shifting: [#329](https://github.com/ryanheise/just_audio/issues/329)
* Equaliser: [#147](https://github.com/ryanheise/just_audio/issues/147)
* Casting support (Chromecast and AirPlay): [#211](https://github.com/ryanheise/just_audio/issues/211)
* Volume boost and skip silence: [#307](https://github.com/ryanheise/just_audio/issues/307)
* [All feature requests sorted by popularity](https://github.com/ryanheise/just_audio/issues?q=is%3Aopen+is%3Aissue+label%3Aenhancement+sort%3Areactions-%2B1-desc)

Please also consider pressing the thumbs up button at the top of [this page](https://pub.dev/packages/just_audio) (pub.dev) if you would like to bring more momentum to the project. More users leads to more bug reports and feature requests, which leads to increased stability and functionality.

## Platform support

| Feature                        | Android | iOS | macOS | Web | Windows | Linux |
| ------------------------------ | :-----: | :-: | :---: | :-: | :-----: | :---: |
| read from URL                  | ✅      | ✅  | ✅    | ✅  | ✅      | ✅    |
| read from file                 | ✅      | ✅  | ✅    | ✅  | ✅      | ✅    |
| read from asset                | ✅      | ✅  | ✅    | ✅  | ✅      | ✅    |
| read from byte stream          | ✅      | ✅  | ✅    | ✅  | ✅      | ✅    |
| request headers                | ✅      | ✅  | ✅    |     | ✅      | ✅    |
| DASH                           | ✅      |     |       |     | ✅      | ✅    |
| HLS                            | ✅      | ✅  | ✅    |     | ✅      | ✅    |
| ICY metadata                   | ✅      | ✅  | ✅    |     |         |       |
| buffer status/position         | ✅      | ✅  | ✅    | ✅  | ✅      | ✅    |
| play/pause/seek                | ✅      | ✅  | ✅    | ✅  | ✅      | ✅    |
| set volume/speed               | ✅      | ✅  | ✅    | ✅  | ✅      | ✅    |
| clip audio                     | ✅      | ✅  | ✅    | ✅  |         | ✅    |
| playlists                      | ✅      | ✅  | ✅    | ✅  | ✅      | ✅    |
| looping/shuffling              | ✅      | ✅  | ✅    | ✅  | ✅      | ✅    |
| compose audio                  | ✅      | ✅  | ✅    | ✅  |         | ✅    |
| gapless playback               | ✅      | ✅  | ✅    |     | ✅      | ✅    |
| report player errors           | ✅      | ✅  | ✅    | ✅  | ✅      | ✅    |
| handle phonecall interruptions | ✅      | ✅  |       |     |         |       |
| buffering/loading options      | ✅      | ✅  | ✅    |     |         |       |
| set pitch                      | ✅      |     |       |     |         |       |
| skip silence                   | ✅      |     |       |     |         |       |
| equalizer                      | ✅      |     |       |     |         | ✅    |
| volume boost                   | ✅      |     |       |     |         | ✅    |

## Experimental features

| Feature                                                                            | Android   | iOS     | macOS   | Web     |
| -------                                                                            | :-------: | :-----: | :-----: | :-----: |
| Simultaneous downloading+caching                                                   | ✅        | ✅      | ✅      |         |
| Waveform visualizer (See [#97](https://github.com/ryanheise/just_audio/issues/97)) | ✅        | ✅      |         |         |
| FFT visualizer (See [#97](https://github.com/ryanheise/just_audio/issues/97))      | ✅        | ✅      | ✅      |         |
| Background                                                                         | ✅        | ✅      | ✅      | ✅      |

Please consider reporting any bugs you encounter [here](https://github.com/ryanheise/just_audio/issues) or submitting pull requests [here](https://github.com/ryanheise/just_audio/pulls).

## The state model

The state of the player consists of two orthogonal states: `playing` and `processingState`. The `playing` state typically maps to the app's play/pause button and only ever changes in response to direct method calls by the app. By contrast, `processingState` reflects the state of the underlying audio decoder and can change both in response to method calls by the app and also in response to events occurring asynchronously within the audio processing pipeline. The following diagram depicts the valid state transitions:

![just_audio_states](https://user-images.githubusercontent.com/19899190/103147563-e6601100-47aa-11eb-8baf-dee00d8e2cd4.png)

This state model provides a flexible way to capture different combinations of states such as playing+buffering vs paused+buffering, and this allows state to be more accurately represented in an app's UI. It is important to understand that even when `playing == true`, no sound will actually be audible unless `processingState == ready` which indicates that the buffers are filled and ready to play. This makes intuitive sense when imagining the `playing` state as mapping onto an app's play/pause button:

* When the user presses "play" to start a new track, the button will immediately reflect the "playing" state change although there will be a few moments of silence while the audio is loading (while `processingState == loading`) but once the buffers are finally filled (i.e. `processingState == ready`), audio playback will begin.
* When buffering occurs during playback (e.g. due to a slow network connection), the app's play/pause button remains in the `playing` state, although temporarily no sound will be audible while `processingState == buffering`. Sound will be audible again as soon as the buffers are filled again and `processingState == ready`.
* When playback reaches the end of the audio stream, the player remains in the `playing` state with the seek bar positioned at the end of the track. No sound will be audible until the app seeks to an earlier point in the stream. Some apps may choose to display a "replay" button in place of the play/pause button at this point, which calls `seek(Duration.zero)`. When clicked, playback will automatically continue from the seek point (because it was never paused in the first place). Other apps may instead wish to listen for the `processingState == completed` event and programmatically pause and rewind the audio at that point.

Apps that wish to react to both orthogonal states through a single combined stream may listen to `playerStateStream`. This stream will emit events that contain the latest value of both `playing` and `processingState`.

## Configuring the audio session

If your app uses audio, you should tell the operating system what kind of usage scenario your app has and how your app will interact with other audio apps on the device. Different audio apps often have unique requirements. For example, when a navigator app speaks driving instructions, a music player should duck its audio while a podcast player should pause its audio. Depending on which one of these three apps you are building, you will need to configure your app's audio settings and callbacks to appropriately handle these interactions.

just_audio will by default choose settings that are appropriate for a music player app which means that it will automatically duck audio when a navigator starts speaking, but should pause when a phone call or another music player starts. If you are building a podcast player or audio book reader, this behaviour would not be appropriate. While the user may be able to comprehend the navigator instructions while ducked music is playing in the background, it would be much more difficult to understand the navigator instructions while simultaneously listening to an audio book or podcast.

You can use the [audio_session](https://pub.dev/packages/audio_session) package to change the default audio session configuration for your app. E.g. for a podcast player, you may use:

```dart
final session = await AudioSession.instance;
await session.configure(AudioSessionConfiguration.speech());
```

Note: If your app uses a number of different audio plugins, e.g. for audio recording, or text to speech, or background audio, it is possible that those plugins may internally override each other's audio session settings, so it is recommended that you apply your own preferred configuration using audio_session after all other audio plugins have loaded. You may consider asking the developer of each audio plugin you use to provide an option to not overwrite these global settings and allow them be managed externally.
