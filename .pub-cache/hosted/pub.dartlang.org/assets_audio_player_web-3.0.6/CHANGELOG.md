## 3.0.6

- Update kotling version and fix minor issues

## 3.0.5

- Breaking change, with Flutter 3.0 removed null aware for WidgetsBinding

## 3.0.4+5

- Fixed null aware

## 3.0.4+4

- Fix issues and update exoplayer

## 3.0.4+3

- Fix warnings and abstract issue

## 3.0.4+2

- Fix flutter 3.0 issues

## 3.0.4+1

- Fix andorid 12 issues and update exoplayer and gradles

## 3.0.4

- Fix web open player issue
- update example app Android 12 compatable

## 3.0.3+9

- Fix mimType issue mp3 files from urls without extension #630
- Fix web Null issue

## 3.0.3+8

- Fix android 12 / api 31 issue.
- Fix macOs build issue
- Fix web assets issue for Web

## 3.0.3+7

- Fix android 12 / api 31 issue.
- Fix macOs build issue
- Fix web assets issue for Web

## 3.0.3+6

- Added DRM supports
- Fix playSpeed for WEB.

## 3.0.3+5

- Added pitch controller

## 3.0.3+4

- Updated dependencies
- Fix duplicate class issue
- Fix: assetsAudioPlayer.open playSpeed is not work

## 3.0.3+3

- fix duration issue

## 3.0.3+2

- update build number

## 3.0.3+1

- fixed no function for stopForeground

## 3.0.3

- Fix notification issue

## 3.0.2

- Fix version issue

## 3.0.1

- Fix web player

## 3.0.0

- Fix some issues
- Migrate to null safety

## 2.0.15

- update android 30 and fixed local assets issue
- should fix android alarm manager issue

## 2.0.14

- update packages

## 2.0.13+9

- fix opening multiple audio player.

## 2.0.13+8

- fix opening multiple audio player.

## 2.0.13+7

- fix version conflicts

## 2.0.13+6

- fix android crash issue

## 2.0.13+5

- fix opened multiple instance for android problem.

## 2.0.13+2

- fixed some issues on ios
- fix crash issue on android

## 2.0.13+1

- fixed some innues on macos/ios

## 2.0.12

- Fixed AudioType.network networkHeaders
- Improve documentation
- CustomPrevIcon fixed

## 2.0.9+2

- Renamed PhoneCallStrategy to AudioFocusStrategy
- Allow on android to resume native players after focus lost

## 2.0.8+5

- Added Android HeadPhoneStrategy
- Fix local path file uri (android)
- Added open multiple calls protection
- Open uri content on androids

## 2.0.6+7

- Cache now use `http` instead of `dio`
- Added live tag on notification for LiveStream play (ios)
- Added audio session id (android only)

## 2.0.5+7

- Added custom error handling (beta)
- Dispose is now a future
- Fixed playlist insert / replace

## 2.0.5

- Added Cache management (beta), with Audio.network(url, cached: true)

## 2.0.4+2

- Added HLS, Dash, SmoothStream support on Android
- Added `laylist.replaceAt` method

## 2.0.3+6

- ExoPlayer network now set `allowCrossProtocolRedirect=true` by default
- Fixed notification hide on livestream pause (android)
- Added custom icons for android from drawable names
- Fixed notification texts on Samsung devices

## 2.0.3+1

- Added custom notification icons for Android (in AndroidManifest.xml)
- Fixed `seek` and `seekBy` not working on the web
- `PlayList.startIndex` is now mutable
- Stop player then call `play` reopen it at `playlist.startIndex`
- Increased buffer size on android/exoplayer
- Added keepLoopMode on prev/next

## 2.0.2

- Breaking change : `loop` boolean now enumerate 3 values : `none`, `single` and `playlist`

## 2.0.1+9

- Added `.showNotification = true/false` to hide dynamically displayed notification
- Added custom action on notif click(android)
- Added `isBuffering` to `RealtimePlayingInfos`
- Added `AssetsAudioPlayerGroup` (beta)
- Added Headers in `Audio.network` & `Audio.liveStream`

## 2.0.1

- Added `.playerState` (play/pause/stop)
- Stop now ping finish listeners

## 2.0.0+6

- Added MacOS support
- Fixed gapeless loop (single audio)
- Fixed audio file notification

## 1.7.0

- Fixed bluetooth on android on some devices
- Fallback to android native MediaPlayer if exoplayer can't read the file
- Added `audio.updateMetas` to update notification content after creation
- Android Seekbar notification is now optional
- Android usable notification Seekbar
- Added stop custom notification action

## 1.6.3

- Custom notification icon (android)
- Custom notification actions
- Fixed notification close on android
- Fixed android auto-focus
- Added playInBackground mode
- Added shuffle

## 1.6.1

- Playlist is now mutable, we can add audios after creation
- renamed `ReadingPlaylist get playlist` to `ReadingPlaylist get readingPlaylist`
- added `Playlist get playlist`

## 1.6.0+4

- Fixed playlist issue on android
- Fixed issue on bluetooth android play/pause
- Fixed PlayerBuilder currentPosition
- Added extra map into audio

## 1.6.0

- Added some checks on swift code
- Fixed totalDuration or liveStream
- Fixed ios notifications
- Added bluetooth headset actions (play/pause/next/prev/stop)

## 1.5.0

- Added `Audio.liveStream(url)`
- Fixed notification image from assets on android
- Fixed android notification actions on playlist
- Added `AudioWidget`

## 1.4.7

- added `package` on assets audios (& notif images)
- all methods return Future
- open can throw an exception if the url is not found

## 1.4.6+1

- fixed android notifications actions
- refactored package, added `src/` and `package` keyword
- added player_builders

## 1.4.5

- fixed implementation of local file play on iOS

## 1.4.4

- Added notifications on android

## 1.4+3+6

- Beta fix for audio focus

## 1.4+3+5

- Beta implementation of local file play on iOS

## 1.4.3+4

- Moved to last flutter version `>=1.12.13+hotfix.6`
- Implemented new android `FlutterPlugin`
- Stop all players while getting a phone call
- Added `playspeed` as optional parameter on on open()

## 1.4.2+1

- Moved to android ExoPlayer
- Added `playSpeed` (beta)
- Added `forwardRewind` (beta)
- Added `seekBy`

## 1.4.0+1

- Bump gradle versions : `wrapper`=(5.4.1-all) `build:gradle`=(3.5.3)

## 1.4.0

- Added `respectSilentMode` as open optional argument
- Added `showNotification` on iOS to map with MPNowPlayingInfoCenter (default: false)
- Added `metas` on audios (title, artist, ...) for notifications
- Use new plugin build format for iOS

## 1.3.9

- Empty constructor now create a new player
- Added factory AssetsAudioPlayer.withId()
- Added `playAndForget` witch create, open, play & dispose the player on finish
- Added AssetsAudioPlayer.allPlayers() witch returns a map of all players
- Reworked the android player

## 1.3.8+1

- Added `seek` as optional parameter on `open` method

## 1.3.8

- Fully rebased the web support on html.AudioElement (instead of howler)
- Fully rebases the ios support on AvPlayer (instead of AvAudioPlayer)
- Added support for network audios with `.open(Audio.network(url))` on Android/ios/web

## 1.3.7+1

- Added `RealtimePlayingInfos` stream

## 1.3.6+1

- Added volume as optional parameter on open()

## 1.3.6

- Extracted web support to assets_audio_player_web: 1.3.6

## 1.3.5+1

- Volume does not reset anymore on looping audios

## 1.3.4

- Fixed player on Android

## 1.3.3

- Fixed build on Android & iOS

## 1.3.2

- Rewritten the web support, using now https://github.com/florent37/flutter_web_howl

## 1.3.1+2

- Upgraded RxDart dependency
- fixed lint issues
- lowerCamelCase AssetsAudioPlayer volumes consts

## 1.3.1

- Fixed build on iOS

## 1.3.0

- Added web support, works only on debug mode

## 1.2.8

- Added constructors

* AssetsAudioPlayer.newPlayer
* AssetsAudioPlayer(id: "PLAYER_ID")

to create new players and play multiples songs in parallel

the default constructor AssetsAudioPlayer() still works as usual

## 1.2.7

- Added "volume" property (listen/set)

## 1.2.6

- Added an "autoPlay" optional attribute to open methods

## 1.2.5

- Compatible with Swift 5

## 1.2.4

- Added playlist

## 1.2.3

- Added playlist (beta)

## 1.2.1

- Added looping setter/getter

## 1.2.0

- Upgraded RxDart to 0.23.1
- Fixed assets playing on iOS
- Fixed playing location on Android

## 0.0.1

- initial release.
