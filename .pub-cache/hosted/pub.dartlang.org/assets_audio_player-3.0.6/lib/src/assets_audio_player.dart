import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'cache/cache_downloader.dart';
import 'cache/cache_manager.dart';
import 'notification.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

import 'applifecycle.dart';
import 'cache/cache.dart';
import 'playable.dart';
import 'playing.dart';
import 'loop.dart';
import 'errors.dart';
import 'PhoneStrategy.dart';
import 'network_settings.dart';

export 'applifecycle.dart';
export 'notification.dart';
export 'playable.dart';
export 'playing.dart';
export 'loop.dart';
export 'errors.dart';
export 'PhoneStrategy.dart';

const bool _DEFAULT_AUTO_START = true;
const bool _DEFAULT_RESPECT_SILENT_MODE = false;
const bool _DEFAULT_SHOW_NOTIFICATION = false;
const PlayInBackground _DEFAULT_PLAY_IN_BACKGROUND = PlayInBackground.enabled;
const HeadPhoneStrategy _DEFAULT_HEADPHONE_STRATEGY = HeadPhoneStrategy.none;
const LoopMode _DEFAULT_LOOP_MODE = LoopMode.none;
const String _DEFAULT_PLAYER = 'DEFAULT_PLAYER';

const String METHOD_POSITION = 'player.position';
const String METHOD_VOLUME = 'player.volume';
const String METHOD_FINISHED = 'player.finished';
const String METHOD_IS_PLAYING = 'player.isPlaying';
const String METHOD_IS_BUFFERING = 'player.isBuffering';
const String METHOD_CURRENT = 'player.current';
const String METHOD_FORWARD_REWIND_SPEED = 'player.forwardRewind';
const String METHOD_NOTIFICATION_NEXT = 'player.next';
const String METHOD_NOTIFICATION_PREV = 'player.prev';
const String METHOD_NOTIFICATION_STOP = 'player.stop';
const String METHOD_NOTIFICATION_PLAY_OR_PAUSE = 'player.playOrPause';
const String METHOD_PLAY_SPEED = 'player.playSpeed';
const String METHOD_PITCH = 'player.pitch';
const String METHOD_ERROR = 'player.error';
const String METHOD_AUDIO_SESSION_ID = 'player.audioSessionId';

enum PlayerState {
  play,
  pause,
  stop,
}

class PlayerEditor {
  const PlayerEditor(this.assetsAudioPlayer);

  final AssetsAudioPlayer assetsAudioPlayer;
  PlayerEditor._(this.assetsAudioPlayer);

  void onAudioRemovedAt(int index) {
    if (assetsAudioPlayer._playlist != null) {
      if (index < assetsAudioPlayer._playlist!.playlistIndex) {
        assetsAudioPlayer._playlist!.playlistIndex =
            assetsAudioPlayer._playlist!.playlistIndex - 1;
      }
      assetsAudioPlayer._updatePlaylistIndexes();
      if (assetsAudioPlayer._playlist!.playlistIndex == index) {
        assetsAudioPlayer._openPlaylistCurrent();
      }
    }
  }

  void onAudioAddedAt(int index) {
    assetsAudioPlayer._updatePlaylistIndexes();
    if (assetsAudioPlayer._playlist!.playlistIndex == index) {
      assetsAudioPlayer._openPlaylistCurrent();
    }
  }

  void onAudioReplacedAt(int index, bool keepPlayingPositionIfCurrent) {
    assetsAudioPlayer._updatePlaylistIndexes();
    if (assetsAudioPlayer._playlist!.playlistIndex == index) {
      final currentPosition = assetsAudioPlayer.currentPosition.valueOrNull;
      final isPlaying = assetsAudioPlayer.isPlaying.valueOrNull ?? false;
      //print('onAudioReplacedAt/ currentPosition : $currentPosition');
      if (keepPlayingPositionIfCurrent && currentPosition != null) {
        assetsAudioPlayer._openPlaylistCurrent(
            seek: currentPosition, autoStart: isPlaying);
      } else {
        assetsAudioPlayer._openPlaylistCurrent(autoStart: isPlaying);
      }
    }
  }

  void onAudioMetasUpdated(Audio audio) {
    assetsAudioPlayer._onAudioUpdated(audio);
  }
}

/// The AssetsAudioPlayer, playing audios from assets/
/// Example :
///
///     AssetsAudioPlayer _assetsAudioPlayer = AssetsAudioPlayer();
///
///     _assetsAudioPlayer.open(Audio(
///         '/assets/audio/myAudio.mp3',
///     ))
///
/// Don't forget to declare the audio folder in your `pubspec.yaml`
///
///     flutter:
///       assets:
///         - assets/audios/
class AssetsAudioPlayer {
  PlayerEditor? _playerEditor;

  AssetsAudioPlayerCache _audioPlayerCache = defaultAssetsAudioPlayerCache;

  static final double minVolume = 0.0;
  static final double maxVolume = 1.0;
  static final double minPlaySpeed = 0.0;
  static final double maxPlaySpeed = 16.0;
  static final double defaultVolume = maxVolume;
  static final double defaultPlaySpeed = 1.0;
  static final double minPitch = 0.0;
  static final double maxPitch = 16.0;
  static final double defaultPitch = 1.0;
  static final AudioFocusStrategy defaultFocusStrategy =
      AudioFocusStrategy.request(resumeAfterInterruption: true);
  static final NotificationSettings defaultNotificationSettings =
      const NotificationSettings();

  //region notification click
  static MethodChannel _notificationOpenChannel =
      const MethodChannel('assets_audio_player_notification');
  static final BehaviorSubject<ClickedNotificationWrapper>
      __onNotificationClicked = BehaviorSubject<ClickedNotificationWrapper>();
  static final Stream<ClickedNotificationWrapper> _onNotificationClicked =
      __onNotificationClicked.stream;

  static void setupNotificationsOpenAction(NotificationOpenAction action) {
    WidgetsFlutterBinding.ensureInitialized();
    _notificationOpenChannel =
        const MethodChannel('assets_audio_player_notification');
    _notificationOpenChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'selectNotification':
          {
            final String audioId = call.arguments;
            __onNotificationClicked.add(
              ClickedNotificationWrapper(
                ClickedNotification(audioId: audioId),
              ),
            );
            break;
          }
      }
    });
    addNotificationOpenAction(action);
  }

  static StreamSubscription addNotificationOpenAction(
      NotificationOpenAction action) {
    return _onNotificationClicked.listen((ClickedNotificationWrapper clicked) {
      if (!clicked.handled) {
        final handled = action(clicked.clickedNotification);
        clicked.handled = handled;
      }
    });
  }
  //endregion

  static final uuid = Uuid();

  /// The channel between the native and Dart
  final MethodChannel _sendChannel = const MethodChannel('assets_audio_player');
  late MethodChannel _recieveChannel;

  /// Stores opened asset audio path to use it on the `_current` BehaviorSubject (in `PlayingAudio`)
  Audio? _lastOpenedAssetsAudio;

  _CurrentPlaylist? _playlist;

  final String id;
  final NetworkSettings networkSettings = NetworkSettings();

  set cachePathProvider(AssetsAudioPlayerCache newValue) {
    _audioPlayerCache = newValue;
  }

  bool _acceptUserOpen = true; //if false, user cannot call open method

  AssetsAudioPlayer._({this.id = _DEFAULT_PLAYER}) {
    _init();
  }

  static final Map<String, AssetsAudioPlayer> _players = {};

  static Map<String, AssetsAudioPlayer> allPlayers() {
    return Map.from(_players); //return a copy
  }

  static AssetsAudioPlayer _getOrCreate({required String id}) {
    if (_players.containsKey(id)) {
      return _players[id]!;
    } else {
      final player = AssetsAudioPlayer._(id: id);
      _players[id] = player;
      return player;
    }
  }

  factory AssetsAudioPlayer.newPlayer() => _getOrCreate(id: uuid.v4());

  /// empty constructor now create a new player
  factory AssetsAudioPlayer() => AssetsAudioPlayer.newPlayer();

  factory AssetsAudioPlayer.withId(String? id) =>
      _getOrCreate(id: id ?? uuid.v4());

  /// Create a new player for this audio, play it, and dispose it automatically
  static void playAndForget(
    Audio audio, {
    double? volume,
    bool respectSilentMode = _DEFAULT_RESPECT_SILENT_MODE,
    Duration? seek,
    double? playSpeed,
  }) {
    final player = AssetsAudioPlayer.newPlayer();
    StreamSubscription? onFinished;
    onFinished = player.playlistFinished.listen((finished) {
      if (finished) {
        onFinished?.cancel();
        player.dispose();
      }
    });
    player.open(
      audio,
      volume: volume,
      seek: seek,
      respectSilentMode: respectSilentMode,
      autoStart: true,
      playSpeed: playSpeed,
    );
  }

  ReadingPlaylist? get readingPlaylist {
    if (_playlist == null) {
      return null;
    } else {
      return ReadingPlaylist(
        // immutable copy
        audios: _playlist!.playlist.audios,
        currentIndex: _playlist!.playlistIndex,
      );
    }
  }

  Playlist? get playlist => _playlist?.playlist;

  /// Then mediaplayer playing state (mutable)
  final BehaviorSubject<bool> _isPlaying = BehaviorSubject<bool>.seeded(false);

  /// Boolean observable representing the current mediaplayer playing state
  ///
  /// retrieve directly the current player state
  ///     final bool playing = _assetsAudioPlayer.isPlaying.value;
  ///
  /// will follow the AssetsAudioPlayer playing state
  ///     return StreamBuilder(
  ///         stream: _assetsAudioPlayer.currentPosition,
  ///         builder: (context, asyncSnapshot) {
  ///             final bool isPlaying = asyncSnapshot.data;
  ///             return Text(isPlaying ? 'Pause' : 'Play');
  ///         }),
  ValueStream<bool> get isPlaying => _isPlaying.stream;
  String get getCurrentAudioTitle =>
      _current.valueOrNull?.audio.audio.metas.title ?? '';
  String get getCurrentAudioArtist =>
      _current.valueOrNull?.audio.audio.metas.artist ?? '';
  Map<String, dynamic> get getCurrentAudioextra =>
      _current.valueOrNull?.audio.audio.metas.extra ?? <String, dynamic>{};
  String get getCurrentAudioAlbum =>
      _current.valueOrNull?.audio.audio.metas.album ?? '';
  MetasImage? get getCurrentAudioImage =>
      _current.valueOrNull?.audio.audio.metas.image;

  /// represent the android session id
  /// does nothing on others platforms
  final BehaviorSubject<int> _audioSessionId = BehaviorSubject<int>();

  ValueStream<int> get audioSessionId => _audioSessionId.stream;

  final BehaviorSubject<PlayerState> _playerState =
      BehaviorSubject<PlayerState>.seeded(PlayerState.stop);

  ValueStream<PlayerState> get playerState => _playerState.stream;

  /// Then mediaplayer playing audio (mutable)
  final BehaviorSubject<Playing?> _current = BehaviorSubject();

  /// The current playing audio, filled with the total song duration
  /// Exposes a PlayingAudio
  ///
  /// Retrieve directly the current played asset
  ///     final PlayingAudio playing = _assetsAudioPlayer.current.value;
  ///
  /// Listen to the current playing song
  ///     _assetsAudioPlayer.current.listen((playing){
  ///         final path = playing.audio.path;
  ///         final songDuration = playing.audio.duration;
  ///     })
  ///
  ValueStream<Playing?> get current => _current.stream;

  Stream<PlayingAudio?> get onReadyToPlay =>
      current.map((playing) => playing?.audio); // another comprehensible name

  /// Called when the the complete playlist finished to play (mutable)
  final BehaviorSubject<bool> _playlistFinished =
      BehaviorSubject<bool>.seeded(false);

  /// Called when the complete playlist has finished to play
  ///     _assetsAudioPlayer.finished.listen((finished){
  ///
  ///     })
  ///
  ValueStream<bool> get playlistFinished => _playlistFinished.stream;

  /// Called when the current playlist song has finished (mutable)
  /// Using a playlist, the `finished` stram will be called only if the complete playlist finished
  /// _assetsAudioPlayer.playlistAudioFinished.listen((audio){
  ///      the $audio has finished to play, moving to next audio
  /// })
  final PublishSubject<Playing> _playlistAudioFinished = PublishSubject();

  /// Called when the current playlist song has finished
  /// Using a playlist, the `finished` stram will be called only if the complete playlist finished
  Stream<Playing> get playlistAudioFinished => _playlistAudioFinished.stream;

  /// Then current playing song position (in seconds) (mutable)
  final BehaviorSubject<Duration> _currentPosition =
      BehaviorSubject<Duration>.seeded(const Duration());

  /// Retrieve directly the current song position (in seconds)
  ///     final Duration position = _assetsAudioPlayer.currentPosition.value;
  ///
  ///     return StreamBuilder(
  ///         stream: _assetsAudioPlayer.currentPosition,
  ///         builder: (context, asyncSnapshot) {
  ///             final Duration duration = asyncSnapshot.data;
  ///             return Text(duration.toString());
  ///         }),
  ValueStream<Duration> get currentPosition => _currentPosition.stream;

  /// The volume of the media Player (min: 0, max: 1)
  final BehaviorSubject<double> _volume =
      BehaviorSubject<double>.seeded(defaultVolume);

  ValueStream<bool> get isBuffering => _isBuffering.stream;
  final BehaviorSubject<bool> _isBuffering =
      BehaviorSubject<bool>.seeded(false);

  final PublishSubject<CacheDownloadInfos> _cacheDownloadInfos =
      PublishSubject<CacheDownloadInfos>();
  Stream<CacheDownloadInfos> get cacheDownloadInfos =>
      _cacheDownloadInfos.stream;

  /// Streams the volume of the media Player (min: 0, max: 1)
  ///     final double volume = _assetsAudioPlayer.volume.value;
  ///
  ///     return StreamBuilder(
  ///         stream: _assetsAudioPlayer.volume,
  ///         builder: (context, asyncSnapshot) {
  ///             final double volume = asyncSnapshot.data;
  ///             return Text('volume: ${volume.toString()});
  ///         }),
  ValueStream<double> get volume => _volume.stream;

  final BehaviorSubject<LoopMode> _loopMode =
      BehaviorSubject<LoopMode>.seeded(_DEFAULT_LOOP_MODE);
  final BehaviorSubject<bool> _shuffle = BehaviorSubject<bool>.seeded(false);

  /// Called when the looping state changes
  ///     _assetsAudioPlayer.isLooping.listen((looping){
  ///
  ///     })
  ///
  ValueStream<LoopMode> get loopMode => _loopMode.stream;

  ValueStream<bool> get isShuffling => _shuffle.stream;

  final BehaviorSubject<RealtimePlayingInfos> _realtimePlayingInfos =
      BehaviorSubject<RealtimePlayingInfos>();

  ValueStream<RealtimePlayingInfos> get realtimePlayingInfos =>
      _realtimePlayingInfos.stream;

  AssetsAudioPlayerErrorHandler?
      onErrorDo; // custom error Handler, default value in '_init'

  final BehaviorSubject<double> _playSpeed = BehaviorSubject.seeded(1.0);

  ValueStream<double> get playSpeed => _playSpeed.stream;

  final BehaviorSubject<double> _pitch = BehaviorSubject.seeded(1.0);

  ValueStream<double> get pitch => _pitch.stream;

  final BehaviorSubject<double> _forwardRewindSpeed = BehaviorSubject.seeded(0);

  ValueStream<double> get forwardRewindSpeed => _forwardRewindSpeed.stream;

  Duration? _lastSeek;

  /// returns the looping state : true -> looping, false -> not looping
  LoopMode? get currentLoopMode => _loopMode.value;

  bool get shuffle => _shuffle.valueOrNull ?? false;

  bool _stopped = false;

  bool _respectSilentMode = _DEFAULT_RESPECT_SILENT_MODE;

  bool get respectSilentMode => _respectSilentMode;

  bool _showNotification = false;
  bool get showNotification => _showNotification;
  set showNotification(bool newValue) {
    _showNotification = newValue;

    /* await */ _sendChannel.invokeMethod(
        'showNotification', {'id': id, 'show': _showNotification});
  }

  Future<void> setLoopMode(LoopMode value) async {
    if (_playlist != null) {
      _playlist!.loopMode = value;
      _loopMode.add(value);
      if (_playlist!.isSingleAudio || value == LoopMode.single) {
        await _loopSingleAudio(value != LoopMode.none);
      } else {
        await _loopSingleAudio(false);
      }
    }
  }

  /// assign the shuffling state : true -> shuffling, false -> not shuffling
  set shuffle(value) {
    _shuffle.add(value);
  }

  /// toggle the looping state
  /// if it was looping -> stops this
  /// if it was'nt looping -> now it is
  Future<void> toggleLoop() async {
    if (_playlist != null) {
      final currentMode = loopMode.value;
      if (_playlist!.isSingleAudio) {
        if (currentMode == LoopMode.none) {
          await setLoopMode(LoopMode.single);
        } else {
          await setLoopMode(LoopMode.none);
        }
      } else {
        if (currentMode == LoopMode.none) {
          await setLoopMode(LoopMode.playlist);
        } else if (currentMode == LoopMode.playlist) {
          await setLoopMode(LoopMode.single);
        } else {
          await setLoopMode(LoopMode.none);
        }
      }
    }
  }

  /// toggle the shuffling state
  /// if it was shuffling -> stops this
  /// if it was'nt shuffling -> now it is
  void toggleShuffle() {
    shuffle = !shuffle;
    _updatePlaylistIndexes();
  }

  /// Call it to dispose stream
  Future<void> dispose() async {
    await stop();

    if (_playerEditor != null) {
      playlist?.removeCurrentlyOpenedIn(_playerEditor!);
    }

    await _currentPosition.close();
    await _isPlaying.close();
    await _volume.close();
    await _playlistFinished.close();
    await _current.close();
    await _playlistAudioFinished.close();
    await _audioSessionId.close();
    await _loopMode.close();
    await _shuffle.close();
    await _cacheDownloadInfos.close();
    await _playSpeed.close();
    await _playerState.close();
    await _isBuffering.close();
    await _forwardRewindSpeed.close();
    await _realtimePlayingInfos.close();
    await _realTimeSubscription?.cancel();
    _players.remove(id);

    _playerEditor = null;

    if (_lifecycleObserver != null) {
      WidgetsBinding.instance.removeObserver(_lifecycleObserver!);
      _lifecycleObserver = null;
    }
  }

  void _init() {
    // default action, can be overriden using player.onErrorDo = (error, player) { ACTION };
    onErrorDo = (errorHandler) {
      print(errorHandler.error.message);
      errorHandler.player.stop();
    };

    _playerEditor = PlayerEditor._(this);

    _recieveChannel = MethodChannel('assets_audio_player/$id');
    _recieveChannel.setMethodCallHandler((MethodCall call) async {
      // print('received call ${call.method} with arguments ${call.arguments}');
      switch (call.method) {
        case 'log':
          print('log: ' + call.arguments);
          break;
        case METHOD_FINISHED:
          await _onFinished(call.arguments);
          break;
        case METHOD_NOTIFICATION_NEXT:
          _notificationNext();
          break;
        case METHOD_NOTIFICATION_PREV:
          _notificationPrevious();
          break;
        case METHOD_NOTIFICATION_STOP:
          _notificationStop();
          break;
        case METHOD_NOTIFICATION_PLAY_OR_PAUSE: // eg: from notification
          _notificationPlayPause();
          break;
        case METHOD_ERROR:
          _handleOnError(call.arguments);
          break;
        case METHOD_AUDIO_SESSION_ID:
          if (call.arguments != null) {
            _audioSessionId.add(call.arguments);
          }
          break;
        case METHOD_CURRENT:
          if (call.arguments == null) {
            final current = _current.valueOrNull;
            if (current != null) {
              final finishedPlay = Playing(
                audio: current.audio,
                index: current.index,
                hasNext: false,
                playlist: current.playlist,
              );
              _playlistAudioFinished.add(finishedPlay);
            }
            _playlistFinished.add(true);
            _current.add(null);
            _playerState.add(PlayerState.stop);
          } else {
            final totalDurationMs =
                _toDuration(call.arguments['totalDurationMs']);

            if (_lastOpenedAssetsAudio != null) {
              final playingAudio = PlayingAudio(
                audio: _lastOpenedAssetsAudio!,
                duration: totalDurationMs,
              );

              if (_playlist != null) {
                final current = Playing(
                  audio: playingAudio,
                  index: _playlist!.playlistIndex,
                  hasNext: _playlist!.hasNext(),
                  playlist: ReadingPlaylist(
                      audios: _playlist!.playlist.audios,
                      currentIndex: _playlist!.playlistIndex,
                      nextIndex: _playlist!.nextIndex(),
                      previousIndex: _playlist!.previousIndex()),
                );
                _current.add(current);
              }
            }
          }
          break;
        case METHOD_POSITION:
          _onPositionReceived(call.arguments);

          break;
        case METHOD_IS_PLAYING:
          final bool playing = call.arguments;
          _isPlaying.add(playing);
          _playerState.add(playing ? PlayerState.play : PlayerState.pause);
          break;
        case METHOD_VOLUME:
          _volume.add(call.arguments);
          break;
        case METHOD_IS_BUFFERING:
          _isBuffering.add(call.arguments);
          break;
        case METHOD_PLAY_SPEED:
          _playSpeed.add(call.arguments);
          break;
        case METHOD_PITCH:
          _pitch.add(call.arguments);
          break;
        case METHOD_FORWARD_REWIND_SPEED:
          final double newValue = call.arguments;
          if (_forwardRewindSpeed.value != newValue) {
            _forwardRewindSpeed.add(newValue);
          }
          break;
        default:
          print('[ERROR] Channel method ${call.method} not implemented.');
      }
    });
    _registerToAppLifecycle();
  }

  StreamSubscription? _realTimeSubscription;

  AppLifecycleObserver? _lifecycleObserver;

  bool? _wasPlayingBeforeEnterBackground;

  /* = null */
  void _registerToAppLifecycle() {
    _lifecycleObserver = AppLifecycleObserver(onBackground: () {
      if (_playlist != null) {
        switch (_playlist!.playInBackground) {
          case PlayInBackground.enabled:
          case null:
            {
              /* do nothing */
            }
            break;
          case PlayInBackground.disabledPause:
            pause();
            break;
          case PlayInBackground.disabledRestoreOnForeground:
            _wasPlayingBeforeEnterBackground = isPlaying.valueOrNull ?? false;
            pause();
            break;
        }
      }
    }, onForeground: () {
      if (_playlist != null) {
        switch (_playlist!.playInBackground) {
          case PlayInBackground.enabled:
          case null:
            {
              /* do nothing */
            }
            break;
          case PlayInBackground.disabledPause:
            {
              /* do nothing, keep the pause */
            }
            break;
          case PlayInBackground.disabledRestoreOnForeground:
            if (_wasPlayingBeforeEnterBackground == true) {
              play();
            } else {
              /* do nothing, keep the pause */
            }
            break;
        }
      }
    });
    if (_lifecycleObserver != null) {
      WidgetsBinding.instance.addObserver(_lifecycleObserver!);
    }
  }

  void _replaceRealtimeSubscription() {
    _realTimeSubscription?.cancel();
    _realTimeSubscription = null;
    _realTimeSubscription = CombineLatestStream.list<dynamic>([
      volume,
      isPlaying,
      loopMode,
      isShuffling,
      current,
      currentPosition,
      isBuffering
    ])
        .map((values) => RealtimePlayingInfos(
              volume: values[0],
              isPlaying: values[1],
              loopMode: values[2],
              isShuffling: values[3],
              current: values[4],
              currentPosition: values[5],
              isBuffering: values[6],
              playerId: id,
            ))
        .listen((readingInfos) {
      _realtimePlayingInfos.add(readingInfos);
    });
  }

  Future<void> playlistPlayAtIndex(int index) async {
    if (_playlist != null) {
      _playlist!.moveTo(index);
      await _openPlaylistCurrent();
    }
  }

  /// keepLoopMode:
  /// if true : the loopMode is .single => execute previous() will keep it .single
  /// if false : the loopMode is .single => execute previous() will set it as .playlist
  Future<bool> previous({bool keepLoopMode = true}) async {
    if (_playlist != null) {
      // more than 5 sec played, go back to the start of audio
      if (_currentPosition.valueOrNull != null &&
          _currentPosition.valueOrNull!.inSeconds >= 5) {
        await seek(Duration.zero, force: true);
      } else if (_playlist!.hasPrev()) {
        if (!keepLoopMode) {
          if (loopMode.value == LoopMode.single) {
            await setLoopMode(LoopMode.playlist);
          }
        }
        _playlist!.selectPrev();
        await _openPlaylistCurrent();
        return true;
      } else if (_playlist!.playlistIndex == 0) {
        await seek(Duration.zero);
        return true;
      }
    }

    return false;
  }

  void _onPositionReceived(dynamic argument) {
    final oldValue = _currentPosition.valueOrNull;
    int? newValue;
    if (argument is int) {
      final value = argument;
      newValue = value;
    } else if (argument is double) {
      final value = argument;
      newValue = value.round();
    }
    if (newValue != null) {
      _currentPosition.add(Duration(milliseconds: newValue));
      if (loopMode.value == LoopMode.single ||
          (_playlist?.isSingleAudio == true &&
              loopMode.value == LoopMode.playlist)) {
        final current = this.current.value;
        if (current != null) {
          final completeDuration = current.audio.duration;
          final oldEndReached = (completeDuration.inMilliseconds -
                  (oldValue?.inMilliseconds ?? 0)) <
              800; // <800ms
          final newJustStarted = newValue < 800; //<800ms

          // print('old: ${oldValue.inMilliseconds}, dur : ${completeDuration.inMilliseconds}');
          if (newJustStarted && oldEndReached) {
            // print('loop');
            final finishedPlay = Playing(
              audio: current.audio,
              index: current.index,
              hasNext: _playlist?.hasNext() ?? false,
              playlist: current.playlist,
            );
            _playlistAudioFinished.add(finishedPlay);
            if (_playlist?.isSingleAudio == true) {
              _playlistFinished.add(true);
            }
          } else if (newJustStarted && _playlistFinished.value == true) {
            // if was true (just finished an audio)
            // re-set it to false
            _playlistFinished.add(false);
          }
        }
      }
    }
  }

  Future<void> _openPlaylistCurrent(
      {bool autoStart = true, Duration? seek}) async {
    if (_playlist != null) {
      return _open(
        _playlist!.currentAudio(),
        forcedVolume: _playlist!.volume,
        respectSilentMode: _playlist!.respectSilentMode,
        showNotification: _playlist!.showNotification,
        playSpeed: _playlist!.playSpeed,
        pitch: _playlist!.pitch,
        notificationSettings: _playlist!.notificationSettings,
        autoStart: autoStart,
        loopMode: _playlist!.loopMode,
        headPhoneStrategy: _playlist!.headPhoneStrategy,
        audioFocusStrategy: _playlist!.audioFocusStrategy,
        seek: seek,
      );
    }
  }

  /// keepLoopMode:
  /// if true : the loopMode is .single => execute next() will keep it .single
  /// if false : the loopMode is .single => execute next() will set it as .playlist
  Future<bool> next({
    bool stopIfLast = false,
    bool keepLoopMode = true,
  }) {
    return _next(
      stopIfLast: stopIfLast,
      requestByUser: true,
      keepLoopMode: keepLoopMode,
    );
  }

  Future<bool> _next({
    bool stopIfLast = false,
    bool requestByUser = false,
    bool keepLoopMode = true,
  }) async {
    if (_playlist != null) {
      if (loopMode.value == LoopMode.single) {
        if (!requestByUser) {
          await seek(Duration.zero);
          return true;
        } else {
          if (!keepLoopMode) {
            await setLoopMode(LoopMode
                .playlist); //on loop.single + next, change it to loopMode.playlist
          }
        }
      }
      if (_playlist!.hasNext()) {
        final curr = _current.valueOrNull;
        if (curr != null) {
          _playlistAudioFinished.add(Playing(
            audio: curr.audio,
            index: curr.index,
            hasNext: true,
            playlist: _current.value!.playlist,
          ));
        }
        _playlist!.selectNext();
        await _openPlaylistCurrent();

        return true;
      } else if (loopMode.value == LoopMode.playlist) {
        //last element
        final curr = _current.valueOrNull;
        if (curr != null) {
          _playlistAudioFinished.add(Playing(
            audio: curr.audio,
            index: curr.index,
            hasNext: false,
            playlist: _current.value!.playlist,
          ));
        }

        _playlist!.returnToFirst();
        await _openPlaylistCurrent();

        return true;
      } else if (stopIfLast) {
        await stop();
        return true;
      } else if (requestByUser) {
        //last element
        final curr = _current.valueOrNull;
        if (curr != null) {
          _playlistAudioFinished.add(Playing(
            audio: curr.audio,
            index: curr.index,
            hasNext: false,
            playlist: _current.value!.playlist,
          ));
        }

        _playlist!.returnToFirst();
        await _openPlaylistCurrent();

        return true;
      }
    }
    return false;
  }

  Future<void> _onFinished(bool? isFinished) async {
    final nextDone = await _next(stopIfLast: false, requestByUser: false);
    if (nextDone) {
      _playlistFinished.add(false); // continue playing the playlist
    } else {
      _playlistFinished.add(true); // no next elements -> finished
      await stop();
    }
  }

  void _handleOnError(Map args) async {
    final String errorType = args['type'] ?? 'Unknown';
    final String errorMessage = args['message'] ?? 'Something went wrong!';
    final error = AssetsAudioPlayerError(
      errorType: parseAssetsAudioPlayerErrorType(errorType),
      message: errorMessage,
    );

    /* example
    onErrorDo = (handler){
      handler.player.open(
          handler.playlist.copyWith(startIndex: handler.playlistIndex),
          seek: handler.currentPosition
      );
    };
     */

    if (onErrorDo != null) {
      final errorHandler = ErrorHandler(
          player: this,
          currentPosition: currentPosition.value,
          playlist: _playlist?.playlist,
          playlistIndex: _playlist?.playlistIndex,
          error: error);
      if (onErrorDo != null) {
        onErrorDo!(errorHandler);
      }
    }
  }

  void _updatePlaylistIndexes() {
    _playlist?.clearPlayerAudio(shuffle);
  }

  /// Converts a number to duration
  Duration _toDuration(num value) {
    if (value.isNaN) {
      return Duration(milliseconds: 0);
    } else if (value is int) {
      return Duration(milliseconds: value);
    } else if (value is double) {
      return Duration(milliseconds: value.round());
    } else {
      return Duration();
    }
  }

  void _notificationPrevious() {
    if (_playlist?.notificationSettings?.customPrevAction != null) {
      _playlist!.notificationSettings!.customPrevAction!(this);
    } else {
      previous();
    }
  }

  void _notificationStop() {
    if (_playlist?.notificationSettings?.customStopAction != null) {
      _playlist!.notificationSettings!.customStopAction!(this);
    } else {
      stop();
    }
  }

  void _notificationPlayPause() {
    if (_playlist?.notificationSettings?.customPlayPauseAction != null) {
      _playlist!.notificationSettings!.customPlayPauseAction!(this);
    } else {
      playOrPause();
    }
  }

  void _notificationNext() {
    if (_playlist?.notificationSettings?.customNextAction != null) {
      _playlist!.notificationSettings!.customNextAction!(this);
    } else {
      next();
    }
  }

  // private method, used in open(playlist) and open(path)
  Future<void> _open(
    Audio? audioInput, {
    required bool? autoStart,
    required double? forcedVolume,
    required bool? respectSilentMode,
    required bool? showNotification,
    required Duration? seek,
    required double? playSpeed,
    required double? pitch,
    required LoopMode? loopMode,
    required HeadPhoneStrategy? headPhoneStrategy,
    required AudioFocusStrategy? audioFocusStrategy,
    required NotificationSettings? notificationSettings,
  }) async {
    final _autoStart = autoStart ?? _DEFAULT_AUTO_START;
    final _loopMode = loopMode ?? _DEFAULT_LOOP_MODE;
    final _audioFocusStrategy = audioFocusStrategy ?? defaultFocusStrategy;
    final currentAudio = _lastOpenedAssetsAudio;
    final _headPhoneStrategy = headPhoneStrategy ?? _DEFAULT_HEADPHONE_STRATEGY;
    if (audioInput != null) {
      _respectSilentMode = respectSilentMode ?? _DEFAULT_RESPECT_SILENT_MODE;
      _showNotification = showNotification ?? _DEFAULT_SHOW_NOTIFICATION;

      var audio = await _handlePlatformAsset(audioInput);
      audio = await _downloadOrFetchFromCacheIfNecessary(audio);

      audio.setCurrentlyOpenedIn(_playerEditor);

      try {
        final params = {
          'id': id,
          'audioType': audioTypeDescription(audio.audioType),
          'path': audio.path,
          'autoStart': _autoStart,
          'respectSilentMode': _respectSilentMode,
          'headPhoneStrategy': describeHeadPhoneStrategy(_headPhoneStrategy),
          'audioFocusStrategy': describeAudioFocusStrategy(_audioFocusStrategy),
          'displayNotification': _showNotification,
          'volume': forcedVolume ?? volume.valueOrNull ?? defaultVolume,
          'playSpeed': playSpeed ??
              audio.playSpeed ??
              this.playSpeed.valueOrNull ??
              defaultPlaySpeed,
          'pitch':
              pitch ?? audio.pitch ?? this.pitch.valueOrNull ?? defaultPitch,
        };
        if (seek != null) {
          params['seek'] = seek.inMilliseconds.round();
        }
        if (audio.package != null) {
          params['package'] = audio.package.toString();
        }
        if (audio.audioType == AudioType.file ||
            audio.audioType == AudioType.network ||
            audio.audioType == AudioType.liveStream) {
          params['networkHeaders'] =
              audio.networkHeaders ?? networkSettings.defaultHeaders;
        }

        if (audio.drmConfiguration != null) {
          var drmMap = {};
          drmMap['drmType'] = audio.drmConfiguration!.drmType.toString();
          if (audio.drmConfiguration!.drmType == DrmType.clearKey) {
            drmMap['clearKey'] = audio.drmConfiguration!.clearKey;
          }
          params['drmConfiguration'] = drmMap;
        }

        //region notifs
        final notifSettings = notificationSettings ?? NotificationSettings();
        writeNotificationSettingsInto(params, notifSettings);
        //endregion

        writeAudioMetasInto(params, audio.metas);
        _lastOpenedAssetsAudio = audioInput;
        /*final result = */

        await _sendChannel.invokeMethod('open', params);

        await setLoopMode(_loopMode);

        _stopped = false;
        _playlistFinished.add(false);
        _isBuffering.add(false);
      } catch (e) {
        _lastOpenedAssetsAudio = currentAudio; // revert to the previous audio
        _current.add(null);
        _isBuffering.add(false);
        _currentPosition.add(Duration.zero);
        try {
          await stop();
        } catch (t) {
          print(t);
        }
        print(e);
        return Future.error(e);
      }
    }
  }

  Future<void> _onAudioUpdated(Audio audio) async {
    if (_lastOpenedAssetsAudio?.path == audio.path) {
      final params = {
        'id': id,
        'path': audio.path,
      };

      writeAudioMetasInto(params, audio.metas);

      await _sendChannel.invokeMethod('onAudioUpdated', params);
    }
  }

  Future<void> updateCurrentAudioNotification(
      {Metas? metas, bool showNotifications = true}) async {
    if (_lastOpenedAssetsAudio != null) {
      final params = {
        'id': id,
        'path': _lastOpenedAssetsAudio?.path,
        'showNotification': showNotifications,
      };

      writeAudioMetasInto(params, metas);

      await _sendChannel.invokeMethod('onAudioUpdated', params);
    }
  }

  Future<void> _openPlaylist(
    Playlist playlist, {
    bool autoStart = _DEFAULT_AUTO_START,
    double? volume,
    bool respectSilentMode = _DEFAULT_RESPECT_SILENT_MODE,
    bool showNotification = _DEFAULT_SHOW_NOTIFICATION,
    Duration? seek,
    double? playSpeed,
    double? pitch,
    LoopMode? loopMode,
    NotificationSettings? notificationSettings,
    PlayInBackground? playInBackground,
    HeadPhoneStrategy headPhoneStrategy = _DEFAULT_HEADPHONE_STRATEGY,
    AudioFocusStrategy? audioFocusStrategy,
  }) async {
    _lastSeek = null;
    _replaceRealtimeSubscription();
    _playlist = _CurrentPlaylist(
      playlist: playlist,
      volume: volume,
      respectSilentMode: respectSilentMode,
      showNotification: showNotification,
      playSpeed: playSpeed,
      pitch: pitch,
      loopMode: loopMode,
      audioFocusStrategy: audioFocusStrategy ?? defaultFocusStrategy,
      notificationSettings: notificationSettings,
      playInBackground: playInBackground ?? _DEFAULT_PLAY_IN_BACKGROUND,
      headPhoneStrategy: headPhoneStrategy,
    );
    _updatePlaylistIndexes();
    _playlist!.moveTo(playlist.startIndex);

    playlist.setCurrentlyOpenedIn(_playerEditor);

    return _openPlaylistCurrent(autoStart: autoStart, seek: seek);
  }

  bool get _isLiveStream {
    return _lastOpenedAssetsAudio?.audioType == AudioType.liveStream;
  }

  /// Open a song from the asset
  /// ### Example
  ///
  ///     AssetsAudioPlayer _assetsAudioPlayer = AssetsAudioPlayer();
  ///
  ///     _assetsAudioPlayer.open(Audio('assets/audios/song1.mp3'))
  ///
  /// Don't forget to declare the audio folder in your `pubspec.yaml`
  ///
  ///     flutter:
  ///       assets:
  ///         - assets/audios/
  ///
  Future<void> open(
    Playable playable, {
    bool autoStart = _DEFAULT_AUTO_START,
    double? volume,
    bool respectSilentMode = _DEFAULT_RESPECT_SILENT_MODE,
    bool showNotification = _DEFAULT_SHOW_NOTIFICATION,
    Duration? seek,
    double? playSpeed,
    double? pitch,
    NotificationSettings? notificationSettings,
    LoopMode loopMode = _DEFAULT_LOOP_MODE,
    PlayInBackground playInBackground = _DEFAULT_PLAY_IN_BACKGROUND,
    HeadPhoneStrategy headPhoneStrategy = _DEFAULT_HEADPHONE_STRATEGY,
    AudioFocusStrategy? audioFocusStrategy,
    bool forceOpen = false, // skip the _acceptUserOpen
  }) async {
    final focusStrategy = audioFocusStrategy ?? defaultFocusStrategy;

    if (forceOpen) {
      _acceptUserOpen = true;
    }

    if (_acceptUserOpen == false) {
      return;
    }

    try {
      _acceptUserOpen = false;
      Playlist? playlist;
      if (playable is Playlist && playable.audios.isNotEmpty) {
        playlist = playable;
      } else if (playable is Audio) {
        playlist = Playlist(audios: [playable]);
      }

      if (playlist != null) {
        await _openPlaylist(
          playlist,
          autoStart: autoStart,
          volume: volume,
          respectSilentMode: respectSilentMode,
          showNotification: showNotification,
          seek: seek,
          loopMode: loopMode,
          playSpeed: playSpeed,
          pitch: pitch,
          headPhoneStrategy: headPhoneStrategy,
          audioFocusStrategy: focusStrategy,
          notificationSettings:
              notificationSettings ?? defaultNotificationSettings,
          playInBackground: playInBackground,
        );
      }
      _acceptUserOpen = true;
    } catch (t) {
      _acceptUserOpen = true;
      rethrow;
    }
  }

  /// Toggle the current playing state
  /// If the media player is playing, then pauses it
  /// If the media player has been paused, then play it
  ///
  ///     _assetsAudioPlayer.playOfPause();
  ///
  Future<void> playOrPause() async {
    final playing = _isPlaying.valueOrNull ?? true;
    if (playing) {
      await pause();
    } else {
      await play();
    }
  }

  /// Tells the media player to play the current song
  ///     _assetsAudioPlayer.play();
  ///
  Future<void> play() async {
    if (_isLiveStream) {
      // on livestream, it re-open the media to be live and not on buffer
      await _openPlaylistCurrent();
    } else {
      if (_stopped) {
        _stopped = false;
        _lastOpenedAssetsAudio = null; //to force open again
        // open the last
        _playlist?.returnToFirst();
        await _openPlaylistCurrent();
      } else {
        await _play();
      }
    }
  }

  Future<void> _play() async {
    await _sendChannel.invokeMethod('play', {
      'id': id,
    });
  }

  Future<void> _loopSingleAudio(bool loop) async {
    await _sendChannel
        .invokeMethod('loopSingleAudio', {'id': id, 'loop': loop});
  }

  /// Tells the media player to pause the current song
  ///     _assetsAudioPlayer.pause();
  ///
  Future<void> pause() async {
    if (_isLiveStream) {
      // on livestream, we stop
      await _stop(removeNotification: false);
    } else {
      if (!_stopped) {
        await _sendChannel.invokeMethod('pause', {
          'id': id,
        });
        _lastSeek = _currentPosition.value;
      }
    }
  }

  /// Change the current position of the song
  /// Tells the player to go to a specific position of the current song
  ///
  ///     _assetsAudioPlayer.seek(Duration(minutes: 1, seconds: 34));
  ///
  Future<void> seek(Duration to, {bool force = false}) async {
    if (to != _lastSeek || force) {
      _lastSeek = to;
      await _sendChannel.invokeMethod('seek', {
        'id': id,
        'to': to.inMilliseconds.round(),
      });
    }
  }

  bool? _wasPlayingBeforeForwardRewind;

  /// If positive, forward (progressively)
  /// If Negative rewind (progressively)
  /// If 0 or null, restore the playing state
  Future<void> forwardOrRewind(double speed) async {
    if (speed == 0) {
      if (_wasPlayingBeforeForwardRewind == true) {
        await play();
      } else {
        await pause();
      }
      _wasPlayingBeforeForwardRewind = null;
    } else {
      _wasPlayingBeforeForwardRewind ??= isPlaying.value;

      await _sendChannel.invokeMethod('forwardRewind', {
        'id': id,
        'speed': speed,
      });
    }
  }

  /// if by > 0 Forward (jump) the current audio, to currentPosition + `by` (duration)
  ///
  /// eg: _assetsAudioPlayer.foward(Duration(seconds: 10))
  ///
  /// Rewind (jump) the current audio, to currentPosition - `by` (duration)
  ///
  ///  eg: _assetsAudioPlayer.rewind(Duration(seconds: 10))
  ///
  Future<void> seekBy(Duration by) async {
    // only if playing a song
    final playing = current.valueOrNull;
    if (playing != null) {
      final totalDuration = playing.audio.duration;

      final currentPosition = this.currentPosition.valueOrNull ?? Duration();

      if (by.inMilliseconds >= 0) {
        final nextPosition = currentPosition + by;

        // don't seek more that song duration
        final currentPositionCapped = Duration(
          milliseconds:
              min(totalDuration.inMilliseconds, nextPosition.inMilliseconds),
        );

        await seek(currentPositionCapped);
      } else {
        // only if playing a song
        final currentPosition = this.currentPosition.valueOrNull ?? Duration();
        final nextPosition = currentPosition + by;

        // don't seek less that 0
        final currentPositionCapped = Duration(
          milliseconds: max(0, nextPosition.inMilliseconds),
        );

        await seek(currentPositionCapped);
      }
    }
  }

  /// Change the current volume of the MediaPlayer
  ///
  ///     _assetsAudioPlayer.setVolume(0.4);
  ///
  /// MIN : 0
  /// MAX : 1
  ///
  Future<void> setVolume(double volume) async {
    await _sendChannel.invokeMethod('volume', {
      'id': id,
      'volume': volume.clamp(minVolume, maxVolume),
    });
  }

  /// Tells the media player to stop the current song, then release the MediaPlayer
  ///     _assetsAudioPlayer.stop();
  ///
  Future<void> stop() async {
    return _stop(removeNotification: true);
  }

  Future<void> _stop({bool removeNotification = true}) async {
    _stopped = true;
    await _sendChannel.invokeMethod(
        'stop', {'id': id, 'removeNotification': removeNotification});
  }

  /// Change the current play speed (rate) of the MediaPlayer
  ///
  ///     _assetsAudioPlayer.setPlaySpeed(0.4);
  ///
  /// MIN : 0.0
  /// MAX : 16.0
  ///
  /// if null, set to defaultPlaySpeed (1.0)
  ///
  Future<void> setPlaySpeed(double playSpeed) async {
    await _sendChannel.invokeMethod('playSpeed', {
      'id': id,
      'playSpeed': playSpeed.clamp(minPlaySpeed, maxPlaySpeed),
    });
  }

  /// Change the current pitch of the MediaPlayer
  ///
  ///     _assetsAudioPlayer.setPitch(0.4);
  ///
  /// MIN : 0.0
  /// MAX : 16.0
  ///
  /// if null, set to defaultPitch (1.0)
  ///
  Future<void> setPitch(double pitch) async {
    await _sendChannel.invokeMethod('pitch', {
      'id': id,
      'pitch': pitch.clamp(minPitch, maxPitch),
    });
  }

  Future<Audio> _handlePlatformAsset(Audio input) async {
    if (defaultTargetPlatform == TargetPlatform.macOS &&
        input.audioType == AudioType.asset &&
        !kIsWeb) {
      //on macos assets are not available from native
      final path = await _copyToTmpMemory(
          package: input.package, assetSource: input.path);
      return input.copyWith(audioType: AudioType.file, path: path);
    }
    return input;
  }

  Future<Audio> _downloadOrFetchFromCacheIfNecessary(Audio input) async {
    return AssetsAudioPlayerCacheManager().transform(_audioPlayerCache, input,
        (downloadInfos) {
      _cacheDownloadInfos.add(downloadInfos);
    });
  }

  //returns the file path
  Future<String> _copyToTmpMemory(
      {String? package, String? assetSource}) async {
    final fileName = '${package ?? ''}$assetSource';
    final completePath = '${(await getTemporaryDirectory()).path}/$fileName';
    final file = File(completePath);
    if (await file.exists()) {
      return file.path;
    } else {
      await file.create(recursive: true);

      ByteData assetContent;
      if (package == null) {
        assetContent = await rootBundle.load('$assetSource');
      } else {
        assetContent = await rootBundle.load('$package/$assetSource');
      }

      await file.writeAsBytes(assetContent.buffer.asUint8List());

      return file.path;
    }
  }
}

class _CurrentPlaylist {
  final Playlist playlist;

  final double? volume;
  final bool? respectSilentMode;
  final bool? showNotification;
  LoopMode? loopMode;
  final double? playSpeed;
  final double? pitch;
  final NotificationSettings? notificationSettings;
  final AudioFocusStrategy? audioFocusStrategy;
  final PlayInBackground? playInBackground;
  final HeadPhoneStrategy? headPhoneStrategy;

  int playlistIndex = 0;

  int nextIndex() {
    final index = indexList.indexWhere((element) => playlistIndex == element);
    if (index + 1 == indexList.length) {
      return indexList.first;
    } else {
      return indexList[index + 1];
    }
  }

  int previousIndex() {
    final index = indexList.indexWhere((element) => playlistIndex == element);
    if (index == 0) {
      return indexList.last;
    } else {
      return indexList[index - 1];
    }
  }

  void selectNext() {
    var index = indexList.indexWhere((element) => playlistIndex == element);
    if (hasNext()) {
      index = index + 1;
    }
    playlistIndex = index;
  }

  List<int> indexList = [];

  void sortAudios() {
    for (var i = 0; i < playlist.audios.length; i++) {
      indexList.add(i);
    }
  }

  void clearPlayerAudio(bool shuffle) {
    indexList.clear();
    if (shuffle) {
      shuffleAudios();
    } else {
      sortAudios();
    }
  }

  void shuffleAudios() {
    for (var i = 0; i < playlist.audios.length; i++) {
      final index = _shuffleNumbers();
      indexList.add(index);
    }
  }

  int _shuffleNumbers() {
    final random = Random();
    var index = random.nextInt(playlist.audios.length);
    if (indexList.contains(index)) {
      index = _shuffleNumbers();
    }
    return index;
  }

  int moveTo(int index) {
    if (index < 0) {
      playlistIndex = indexList.indexWhere((element) => element == 0);
    } else {
      playlistIndex = indexList.indexWhere((element) => element == index);
    }
    return playlistIndex;
  }

  Audio? audioAt({required int at}) {
    if (at < playlist.audios.length) {
      return playlist.audios[at];
    } else {
      return null;
    }
  }

  Audio? currentAudio() {
    return audioAt(at: indexList[playlistIndex]);
  }

  bool hasNext() {
    var index = indexList.indexWhere((element) => playlistIndex == element);
    return index + 1 < indexList.length;
  }

  bool get isSingleAudio => playlist.audios.length == 1;

  _CurrentPlaylist({
    required this.playlist,
    this.volume,
    this.respectSilentMode,
    this.showNotification,
    this.playSpeed,
    this.pitch,
    this.notificationSettings,
    this.playInBackground,
    this.loopMode,
    this.headPhoneStrategy,
    this.audioFocusStrategy,
  });

  void returnToFirst() {
    playlistIndex = playlist.startIndex;
  }

  bool hasPrev() {
    var index = indexList.indexWhere((element) => playlistIndex == element);
    return index > 0;
  }

  void selectPrev() {
    var index = indexList.indexWhere((element) => playlistIndex == element);
    index = index - 1;
    playlistIndex = index;
    if (playlistIndex < 0) {
      playlistIndex = 0;
    }
  }
}
