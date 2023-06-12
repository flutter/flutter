# audio_session

This plugin informs the operating system of the nature of your audio app (e.g. game, media player, assistant, etc.) and how your app will handle and initiate audio interruptions (e.g. phone call interruptions). It also provides access to all of the capabilities of AVAudioSession on iOS and AudioManager on Android, providing for discoverability and configuration of audio hardware.

Audio apps often have unique requirements. For example, when a navigator app speaks driving instructions, a music player should duck its audio while a podcast player should pause its audio. Depending on which one of these three apps you are building, you will need to configure your app's audio settings and callbacks to appropriately handle these interactions.

This plugin can be used both by app developers, to initialise appropriate audio settings for their app, and by plugin authors, to provide easy access to low level features of iOS's AVAudioSession and Android's AudioManager in Dart.

## For app developers

### Configuring the audio session

Configure your app's audio session with reasonable defaults for playing music:

```dart
final session = await AudioSession.instance;
await session.configure(AudioSessionConfiguration.music());
```

Configure your app's audio session with reasonable defaults for playing podcasts/audiobooks:

```dart
final session = await AudioSession.instance;
await session.configure(AudioSessionConfiguration.speech());
```

Or use a custom configuration:

```dart
final session = await AudioSession.instance;
await session.configure(AudioSessionConfiguration(
  avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
  avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth,
  avAudioSessionMode: AVAudioSessionMode.spokenAudio,
  avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
  avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
  androidAudioAttributes: const AndroidAudioAttributes(
    contentType: AndroidAudioContentType.speech,
    flags: AndroidAudioFlags.none,
    usage: AndroidAudioUsage.voiceCommunication,
  ),
  androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
  androidWillPauseWhenDucked: true,
));
```

Note that iOS (and hence this plugin) provides a single audio session to your app which is shared by all of the different audio plugins you use. If your app uses multiple audio plugins, e.g. any combination of audio recording, text to speech, background audio, audio playing, or speech recognition, then it is possible that those plugins may internally overwrite each other's choice of these global system audio settings, including the ones you set via this plugin. Therefore, it is recommended that you apply your own preferred configuration using audio_session after all other audio plugins have loaded. You may consider asking the developer of each audio plugin you use to provide an option to not overwrite these global settings and allow them be managed externally.

### Activating the audio session

Each time you invoke an audio plugin to play audio, that plugin will activate your app's shared audio session to inform the operating system that your app is now actively playing audio. Depending on the configuration set above, this will also inform other audio apps to either stop playing audio, or possibly continue playing at a lower volume (i.e. ducking). You normally do not need to activate the audio session yourself, however if the audio plugin you use does not activate the audio session, you can activate it yourself:

```dart
// Activate the audio session before playing audio.
if (await session.setActive(true)) {
  // Now play audio.
} else {
  // The request was denied and the app should not play audio
}
```

### Reacting to audio interruptions

When another app (e.g. navigator, phone app, music player) activates its audio session, it similarly may ask your app to pause or duck its audio. Once again, the particular audio plugin you use may automatically pause or duck audio when requested. However, if it does not (or if you have switched off this behaviour), then you can respond to these events yourself by listening to `session.interruptionEventStream`. Similarly, if the audio plugin doesn't handle unplugged headphone events, you can respond to these yourself by listening to `session.becomingNoisyEventStream`.

Observe interruptions to the audio session:

```dart
session.interruptionEventStream.listen((event) {
  if (event.begin) {
    switch (event.type) {
      case AudioInterruptionType.duck:
        // Another app started playing audio and we should duck.
        break;
      case AudioInterruptionType.pause:
      case AudioInterruptionType.unknown:
        // Another app started playing audio and we should pause.
        break;
    }
  } else {
    switch (event.type) {
      case AudioInterruptionType.duck:
        // The interruption ended and we should unduck.
        break;
      case AudioInterruptionType.pause:
        // The interruption ended and we should resume.
      case AudioInterruptionType.unknown:
        // The interruption ended but we should not resume.
        break;
    }
  }
});
```

Observe unplugged headphones:

```dart
session.becomingNoisyEventStream.listen((_) {
  // The user unplugged the headphones, so we should pause or lower the volume.
});
```

Observe when devices are added or removed:

```dart
session.devicesChangedEventStream.listen((event) {
  print('Devices added:   ${event.devicesAdded}');
  print('Devices removed: ${event.devicesRemoved}');
});
```

## For plugin authors

This plugin provides easy access to the iOS AVAudioSession and Android AudioManager APIs from Dart, and provides a unified API to activate the audio session for both platforms:

```dart
// Activate the audio session before playing or recording audio.
if (await session.setActive(true)) {
  // Now play or record audio.
} else {
  // The request was denied and the app should not play audio
  // e.g. a phonecall is in progress.
}
```

On iOS this calls `AVAudioSession.setActive` and on Android this calls `AudioManager.requestAudioFocus`. In addition to calling the lower level APIs, it also registers callbacks and forwards events to Dart via the streams `AudioSession.interruptionEventStream` and `AudioSession.becomingNoisyEventStream`. This allows both plugins and apps to interface with a shared instance of the audio focus request and audio session without conflict.

If a plugin can handle audio interruptions (i.e. by listening to the `interruptionEventStream` and automatically pausing audio), it is preferable to provide an option to turn this feature on or off, since some apps may have specialised requirements. e.g.:

```dart
player = AudioPlayer(handleInterruptions: false);
```

Note that iOS and Android have fundamentally different ways to set the audio attributes and categories: for iOS it is app-wide, while for Android it is per player or audio track. As such, `audioSession.configure()` can and does set the app-wide configuration on iOS immediately, while on Android these app-wide settings are stored within audio_session and can be obtained by individual audio plugins via a Stream. The following code shows how a player plugin can listen for changes to the Android AudioAttributes and apply them:

```dart
audioSession.configurationStream
    .map((conf) => conf?.androidAudioAttributes)
    .distinct()
    .listen((attributes) {
  // apply the attributes to this Android audio track
  _channel.invokeMethod("setAudioAttributes", attributes.toJson());
});
```

All numeric values encoded in `AndroidAudioAttributes.toJson()` correspond exactly to the Android platform constants.

`configurationStream` will always emit the latest configuration as the first event upon subscribing, and so the above code will handle both the initial configuration choice and subsequent changes to it throughout the life of the app.

## iOS setup

This plugin contains APIs for accessing all of your phone's audio hardware.

When submitting your app to the app store, it will detect that this plugin contains microphone-related APIs and will require you to add an `NSMicrophoneUsageDescription` key to your `Info.plist` file explaining why your app needs microphone access.

If your app does indeed use the microphone, you can add this key to your `Info.plist` as follows:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>... explain why the app uses the microphone here ...</string>
```

But if your app doesn't use the microphone, you can pass a build option to this plugin to "compile out" microphone code so that the app store won't ask for the above usage description. To do so, edit your `ios/Podfile` as follows:

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
