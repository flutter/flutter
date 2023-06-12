## 0.9.30

* Upgrade ExoPlayer to 2.18.1.
* Fix bug using headers with LockCachingAudioSource.
* Add LockCachingAudioSource.resolve().

## 0.9.29

* Fix bug in ConcatenatingAudioSource.clear().
* Fix bug where proxy drains origin faster than it feeds client.
* Fix bug where User Agent was not set on redirects (@mikel-snipd)
* Fix bug where StreamAudioSource requests are not closed when proxy is disposed (@mikel-snipd)

## 0.9.28

* Recursively apply headers to HLS fragments.
* Add positionDiscontinuityStream.

## 0.9.27

* Support offload scheduling on Android.
* Fix iOS/macOS documentation for non-HTTP URLS and proxy usage.

## 0.9.26

* Auto-correct invalid HTTP headers in proxy.

## 0.9.25

* Fix compile issue with Android SDK 33.

## 0.9.24

* Bump Android compileSdkVersion to 31.

## 0.9.23

* Fallback to constant bitrate seeking on Android.

## 0.9.22

* Migrate to Flutter 3, Xcode 13, ExoPlayer 2.17.1.
* Add just_audio_mpv and just_audio_windows to example.

## 0.9.21

* Handle and report network disconnections in StreamAudioSource.
* Fix iOS/macOS bug starting with empty playlist.
* Migrate from pedantic to flutter_lints.
* Accept Longs in AndroidLivePlaybackSpeedControl where appropriate (@aam).

## 0.9.20

* Fix initial position on iOS/macOS when switching sources (@addie9000).

## 0.9.19

* Dispose players on iOS/macOS hot restart.
* Fix initialIndex out of bounds bug on iOS/macOS.

## 0.9.18

* Fix null duration bug on LockCachingAudioSource.

## 0.9.17

* LockCachingAudioSource works with servers not supporting range requests.
* Add StreamAudioResponse.rangeRequestsSupported.
* Fix doc typos (@robert-j-webb)

## 0.9.16

* Fix pubspec declaration for Linux/Windows implementation.

## 0.9.15

* Fix bug initialising proxy on ConcatenatingAudioSource.add.

## 0.9.14

* Fix bug when pausing/stopping quickly after play.

## 0.9.13

* Fix MIME type in LockCachingAudioSource.
* Add radio/livestream example.
* Report URL from ICY metadata on iOS/macOS.
* Update example to just_audio_libwinmedia 0.0.4 (@bdlukaa)

## 0.9.12

* Windows/Linux support (@bdlukaa, credit to @alexmercerind for libwinmedia).

## 0.9.11

* Upgrade Android to ExoPlayer 2.15.0.

## 0.9.10

* Fix Android bug playing after stopping.

## 0.9.9

* Fix web bug adding/removing items while paused.

## 0.9.8

* Fix bug restoring AndroidEqualizer state after stop.
* Make exceptions implement Exception.
* Upgrade to ExoPlayer 2.13.3.

## 0.9.7

* Update Gradle version.
* Change == parameter from dynamic to Object (@cedvdb).
* Check runtimeType in all == operators.
* Fix Android compiler warnings.

## 0.9.6

* Fix iOS 12.4 `LockCachingAudioSource` fetch exception (@akindone).

## 0.9.5

* Fix iOS/macOS bug updating shuffle order.
* Fix iOS/macOS bug advancing to next in shuffle order.

## 0.9.4

* Remember position after stop().

## 0.9.3

* Fix bug when updating playlist before loading.

## 0.9.2

* Fix Android bug when loading empty playlist.
* Fix Android NullPointerException on stop().

## 0.9.1

* Fix iOS/macOS bug when setting volume before load.

## 0.9.0

* Update to support just_audio_background.

## 0.8.1

* Fix update position bug on Android.
* Compile-time option to include/exclude microphone API.

## 0.8.0

* Add buffer options via AudioLoadConfiguration for iOS/Android.
* Add setSkipSilenceEnabled for Android (@subhash279).
* Add setPitch for Android.
* Add audio effects:
  * AndroidLoudnessEnhancer
  * AndroidEqualizer
* Dispose players when hot restarting on Android.

## 0.7.5

* Support rxdart 0.27.0
* Mention INTERNET Android permission in README (@nt4f04uNd).

## 0.7.4+1

* Link to tutorials in README.

## 0.7.4

* Fix hang after stopping while loading.
* Fix pending timers error (@minhqdao).

## 0.7.3

* Silence uncaught exceptions in positionStream.

## 0.7.2

* Propagate play() exceptions (@twogood).

## 0.7.1

* Fix IllegalSeekPositionException on Android (@DenisShakinov).
* Fix error playing files when a user agent is set.

## 0.7.0

* Null safety.
* Retype headers from Map to Map<String, String>

## 0.6.15+1

* Fix doc references.

## 0.6.15

* Fix bug with spaces in asset paths.
* Fix bug setting a ClippingAudioSource after another source.

## 0.6.14+1

* Update ICY metadata feature status in README.

## 0.6.14

* Initial support for ICY metadata on iOS.
* Upgrade to ExoPlayer 2.13.1 (@MichealReed).

## 0.6.13

* Add userAgent parameter to AudioPlayer constructor.
* Support seeks during download in LockCachingAudioSource.
* Fix negative duration bug on iOS/macOS.

## 0.6.12

* Fix non-completing seek-to-index bug on iOS/macOS.
* More options to manage audio_session.

## 0.6.11

* Update example to indicate buffer position.
* Document pre-release and experimental features in README.

## 0.6.10

* Fix range error in SequenceState (@smkhalsa).

## 0.6.9

* Support assets on web.
* Support StreamAudioSource on web.
* Fix bug on web when manipulating playlists.
* Asset cache no longer deleted on dispose.
* Add contentType to StreamAudioResponse.

## 0.6.8

* Fix pubspec description.

## 0.6.7

* Fix bug with bufferedPositionStream on iOS/macOS.

## 0.6.6

* Experimental cache support.
* Experimental stream audio source.
* Disable iOS/macOS logs (@pschuegr).
* Fix bug with empty playlist (iOS/macOS/web).
* Fix Android bug when initialIndex==null.
* Avoid duplicates in asset cache.
* Guard against unsupported assets on web.

## 0.6.5

* Rewrite setLoopMode on iOS to be gapless.

## 0.6.4

* Emit PlaybackEvent when playing (compatibility with 0.5.x).

## 0.6.3

* Fix iOS compiler warnings.
* Fix bug where native platform wasn't disposed.
* Remove Java compiler warnings.
* Process play/pause state transitions in a consistent order.

## 0.6.2

* Fix bugs related to the new setAudioSource method:
  * When calling setAudioSource more than once
  * When calling setAudioSource/load/play simultaneously

## 0.6.1

* Fix bug with Android skipping start of audio.

## 0.6.0

* Breaking change: Replace load by setAudioSource.
* Breaking change: Rename ProcessingState.none to idle.
* Support custom shuffle order.
* Fix bug dynamically adding to ConcatenatingAudioSource.
* Correctly return null for unknown duration on Android.
* Update dependency versions.

## 0.5.7

* Fix podspec error in web package (@timilehinjegede).
* Fix iOS out-of-range bug.
* Remove Objective C compiler warnings.
* Unit tests.

## 0.5.6

* Fix iOS memory leak.
* Enable useLazyPreparation by default.

## 0.5.5

* Add initialPosition/initialIndex parameters to load.
* Fix iOS crash when disposing just before FlutterEngine is destroyed.
* Fix bug with simultaneous seek requests on iOS.
* Fix seeking when using headers (@nuc134r).
* Fix loading state transition on Android.
* Pass through all setSpeeds requests on iOS, ignoring canPlayFast/Slow.
* Fix bug loading file paths containing spaces (@hsangtini).
* Add web endorsement (@creativecreatorormaybenot).

## 0.5.4

* Use audio_session 0.0.9.

## 0.5.3

* ARC fixes on iOS.
* Update to use platform interface 1.1.0.
* Retain player.position after dispose.
* Fix unnattached player bug in ConcatenatingAudioSource (@nuc134r).

## 0.5.2

* Fix bug in concatenating add/addAll.

## 0.5.1

* Fix bug in loading from assets.
* Ignore method calls from invalid states.
* Forward exceptions from iOS platform implementation.

## 0.5.0

* Convert to federated plugin.

## 0.4.5

* Fix iOS bug in seek/position/duration in HLS streams (@snaeji).
* Fix web bug for audio sources with unknown durations.

## 0.4.4

* Fix crash when disposing of positionStream controller.
* Handle interruptions correctly when willPauseWhenDucked is set.
* Correct seek/position/duration in HLS streams (@snaeji).
* Resume at correct speed after seek on iOS (@subhash279).

## 0.4.3

* Add section to README on configuring the audio session.

## 0.4.2

* Make default audio session settings compatible with iOS control center.
* Update README to mention NSMicrophoneUsageDescription key in Info.plist.

## 0.4.1

* Fix setSpeed bug on iOS.

## 0.4.0

* Handles audio focus/interruptions via audio_session
* Bug fixes

## 0.3.4

* Fix bug in icy metadata
* Allow Android AudioAttributes to be set
* Provide access to Android audio session ID

## 0.3.3

* Remove dependency on Java streams API

## 0.3.2

* Fix dynamic methods on ConcatenatingAudioSource for iOS/Android
* Add sequenceStream/sequenceStateStream
* Change asset URI from asset:// to asset:///

## 0.3.1

* Prevent hang in dispose

## 0.3.0

* Playlists
* Looping
* Shuffling
* Composing
* Clipping support added for iOS/macOS
* New player state model consisting of:
  * playing: true/false
  * processingState: none/loading/buffering/ready/completed
* Feature complete on iOS and macOS (except for DASH)
* Improved example
* Exception classes

## 0.2.2

* Fix dependencies for stable channel.

## 0.2.1

* Improve handling of headers.
* Report setUrl errors and duration on web.

## 0.2.0

* Support dynamic duration
* Support seeking to end of live streams
* Support request headers
* V2 implementation
* Report setUrl errors on iOS
* setUrl throws exception if interrupted
* Return null when duration is unknown

## 0.1.10

* Option to set audio session category on iOS.

## 0.1.9

* Bug fixes.

## 0.1.8

* Reduce distortion at slow speeds on iOS

## 0.1.7

* Minor bug fixes.

## 0.1.6

* Eliminate event lag over method channels.
* Report setUrl errors on Android.
* Report Icy Metadata on Android.
* Bug fixes.

## 0.1.5

* Update dependencies and documentation.

## 0.1.4

* Add MacOS implementation.
* Support cross-platform redirects on Android.
* Bug fixes.

## 0.1.3

* Fix bug in web implementation.

## 0.1.2

* Broadcast how much audio has been buffered.

## 0.1.1

* Web implementation.
* iOS option to minimize stalling.
* Fix setAsset on iOS.

## 0.1.0

* Separate buffering state from PlaybackState.
* More permissive state transitions.
* Support playing local files on iOS.

## 0.0.6

* Bug fixes.

## 0.0.5

* API change for audio clipping.
* Performance improvements and bug fixes on Android.

## 0.0.4

* Remove reseeking hack.

## 0.0.3

* Feature to change audio speed.

## 0.0.2

* iOS implementation for testing (may not work).

## 0.0.1

* Initial release with Android implementation.
