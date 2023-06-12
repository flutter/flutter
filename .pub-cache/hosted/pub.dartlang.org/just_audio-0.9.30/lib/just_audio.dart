import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:audio_session/audio_session.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:meta/meta.dart' show experimental;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

JustAudioPlatform? _pluginPlatformCache;

JustAudioPlatform get _pluginPlatform {
  var pluginPlatform = JustAudioPlatform.instance;
  // If this is a new FlutterEngine or if we've just hot restarted an existing
  // FlutterEngine...
  if (_pluginPlatformCache == null) {
    // Dispose of all existing players within this FlutterEngine. This helps to
    // shut down existing players on a hot restart. TODO: Remove this hack once
    // https://github.com/flutter/flutter/issues/10437 is implemented.
    try {
      pluginPlatform.disposeAllPlayers(DisposeAllPlayersRequest());
    } catch (e) {
      // Silently ignore if a platform doesn't support this method.
    }
    _pluginPlatformCache = pluginPlatform;
  }
  return pluginPlatform;
}

/// An object to manage playing audio from a URL, a locale file or an asset.
///
/// ```
/// final player = AudioPlayer();
/// await player.setUrl('https://foo.com/bar.mp3');
/// player.play();
/// await player.pause();
/// await player.setClip(start: Duration(seconds: 10), end: Duration(seconds: 20));
/// await player.play();
/// await player.setUrl('https://foo.com/baz.mp3');
/// await player.seek(Duration(minutes: 5));
/// player.play();
/// await player.pause();
/// await player.dispose();
/// ```
///
/// You must call [dispose] to release the resources used by this player,
/// including any temporary files created to cache assets.
class AudioPlayer {
  /// The user agent to set on all HTTP requests.
  final String? _userAgent;

  final AudioLoadConfiguration? _audioLoadConfiguration;

  final bool _androidOffloadSchedulingEnabled;

  /// This is `true` when the audio player needs to engage the native platform
  /// side of the plugin to decode or play audio, and is `false` when the native
  /// resources are not needed (i.e. after initial instantiation and after [stop]).
  bool _active = false;

  /// This is set to [_nativePlatform] when [_active] is `true` and
  /// [_idlePlatform] otherwise.
  late Future<AudioPlayerPlatform> _platform;

  /// Reflects the current platform immediately after it is set.
  AudioPlayerPlatform? _platformValue;

  /// The interface to the native portion of the plugin. This will be disposed
  /// and set to `null` when not in use.
  Future<AudioPlayerPlatform>? _nativePlatform;

  /// A pure Dart implementation of the platform interface for use when the
  /// native platform is not needed.
  _IdleAudioPlayer? _idlePlatform;

  /// The subscription to the event channel of the current platform
  /// implementation. When switching between active and inactive modes, this is
  /// used to cancel the subscription to the previous platform's events and
  /// subscribe to the new platform's events.
  StreamSubscription? _playbackEventSubscription;

  /// The subscription to the data event channel of the current platform
  /// implementation. When switching between active and inactive modes, this is
  /// used to cancel the subscription to the previous platform's events and
  /// subscribe to the new platform's events.
  StreamSubscription? _playerDataSubscription;

  final String _id;
  final _proxy = _ProxyHttpServer();
  AudioSource? _audioSource;
  final Map<String, AudioSource> _audioSources = {};
  bool _disposed = false;
  _InitialSeekValues? _initialSeekValues;
  final AudioPipeline _audioPipeline;

  PlaybackEvent _playbackEvent = PlaybackEvent();
  final _playbackEventSubject = BehaviorSubject<PlaybackEvent>(sync: true);
  Future<Duration?>? _durationFuture;
  final _durationSubject = BehaviorSubject<Duration?>();
  final _processingStateSubject = BehaviorSubject<ProcessingState>();
  final _playingSubject = BehaviorSubject.seeded(false);
  final _volumeSubject = BehaviorSubject.seeded(1.0);
  final _speedSubject = BehaviorSubject.seeded(1.0);
  final _pitchSubject = BehaviorSubject.seeded(1.0);
  final _skipSilenceEnabledSubject = BehaviorSubject.seeded(false);
  final _bufferedPositionSubject = BehaviorSubject<Duration>();
  final _icyMetadataSubject = BehaviorSubject<IcyMetadata?>();
  final _playerStateSubject = BehaviorSubject<PlayerState>();
  final _sequenceSubject = BehaviorSubject<List<IndexedAudioSource>?>();
  final _shuffleIndicesSubject = BehaviorSubject<List<int>?>();
  final _shuffleIndicesInv = <int>[];
  final _currentIndexSubject = BehaviorSubject<int?>(sync: true);
  final _sequenceStateSubject = BehaviorSubject<SequenceState?>();
  final _loopModeSubject = BehaviorSubject.seeded(LoopMode.off);
  final _shuffleModeEnabledSubject = BehaviorSubject.seeded(false);
  final _androidAudioSessionIdSubject = BehaviorSubject<int?>();
  final _positionDiscontinuitySubject =
      PublishSubject<PositionDiscontinuity>(sync: true);
  var _seeking = false;
  // ignore: close_sinks
  BehaviorSubject<Duration>? _positionSubject;
  bool _automaticallyWaitsToMinimizeStalling = true;
  bool _canUseNetworkResourcesForLiveStreamingWhilePaused = false;
  double _preferredPeakBitRate = 0;
  bool _playInterrupted = false;
  bool _platformLoading = false;
  AndroidAudioAttributes? _androidAudioAttributes;
  final bool _androidApplyAudioAttributes;
  final bool _handleAudioSessionActivation;

  /// Counts how many times [_setPlatformActive] is called.
  int _activationCount = 0;

  /// Creates an [AudioPlayer].
  ///
  /// If [userAgent] is specified, it will be included in the header of all HTTP
  /// requests on Android, iOS and macOS to identify your agent to the server.
  /// If set, just_audio will create a cleartext local HTTP proxy on your device
  /// to forward HTTP requests with headers included. If [userAgent] is not
  /// specified, this will default to Apple's Core Audio user agent on iOS/macOS
  /// and to just_audio's own user agent on Android. On Web, the browser will
  /// override any specified user-agent string with its own.
  ///
  /// The player will automatically pause/duck and resume/unduck when audio
  /// interruptions occur (e.g. a phone call) or when headphones are unplugged.
  /// If you wish to handle audio interruptions manually, set
  /// [handleInterruptions] to `false` and interface directly with the audio
  /// session via the [audio_session](https://pub.dev/packages/audio_session)
  /// package. If you do not wish just_audio to automatically activate the audio
  /// session when playing audio, set [handleAudioSessionActivation] to `false`.
  /// If you do not want just_audio to respect the global
  /// [AndroidAudioAttributes] configured by audio_session, set
  /// [androidApplyAudioAttributes] to `false`.
  ///
  /// The default audio loading and buffering behaviour can be configured via
  /// the [audioLoadConfiguration] parameter.
  AudioPlayer({
    String? userAgent,
    bool handleInterruptions = true,
    bool androidApplyAudioAttributes = true,
    bool handleAudioSessionActivation = true,
    AudioLoadConfiguration? audioLoadConfiguration,
    AudioPipeline? audioPipeline,
    bool androidOffloadSchedulingEnabled = false,
  })  : _id = _uuid.v4(),
        _userAgent = userAgent,
        _androidApplyAudioAttributes =
            androidApplyAudioAttributes && _isAndroid(),
        _handleAudioSessionActivation = handleAudioSessionActivation,
        _audioLoadConfiguration = audioLoadConfiguration,
        _audioPipeline = audioPipeline ?? AudioPipeline(),
        _androidOffloadSchedulingEnabled = androidOffloadSchedulingEnabled {
    _audioPipeline._setup(this);
    if (_audioLoadConfiguration?.darwinLoadControl != null) {
      _automaticallyWaitsToMinimizeStalling = _audioLoadConfiguration!
          .darwinLoadControl!.automaticallyWaitsToMinimizeStalling;
    }
    _playbackEventSubject.add(_playbackEvent);
    _processingStateSubject.addStream(playbackEventStream
        .map((event) => event.processingState)
        .distinct()
        .handleError((Object err, StackTrace stackTrace) {/* noop */}));
    _bufferedPositionSubject.addStream(playbackEventStream
        .map((event) => event.bufferedPosition)
        .distinct()
        .handleError((Object err, StackTrace stackTrace) {/* noop */}));
    _icyMetadataSubject.addStream(playbackEventStream
        .map((event) => event.icyMetadata)
        .distinct()
        .handleError((Object err, StackTrace stackTrace) {/* noop */}));
    playbackEventStream.pairwise().listen((pair) {
      final prev = pair.first;
      final curr = pair.last;
      // Detect auto-advance
      if (_seeking) return;
      if (prev.currentIndex == null || curr.currentIndex == null) return;
      if (curr.currentIndex != prev.currentIndex) {
        // If we've changed item without seeking, it must be an autoAdvance.
        _positionDiscontinuitySubject.add(PositionDiscontinuity(
            PositionDiscontinuityReason.autoAdvance, prev, curr));
      } else {
        // If the item is the same, try to determine whether we have looped
        // back.
        final prevPos = _getPositionFor(prev);
        final currPos = _getPositionFor(curr);
        if (loopMode != LoopMode.one) return;
        if (currPos >= prevPos) return;
        if (currPos >= const Duration(milliseconds: 300)) return;
        final duration = this.duration;
        if (duration != null && prevPos < duration * 0.6) return;
        if (duration == null &&
            currPos - prevPos < const Duration(seconds: 1)) {
          return;
        }
        _positionDiscontinuitySubject.add(PositionDiscontinuity(
            PositionDiscontinuityReason.autoAdvance, prev, curr));
      }
    }, onError: (Object e, StackTrace st) {});
    _currentIndexSubject.addStream(playbackEventStream
        .map((event) => event.currentIndex)
        .distinct()
        .handleError((Object err, StackTrace stackTrace) {/* noop */}));
    _androidAudioSessionIdSubject.addStream(playbackEventStream
        .map((event) => event.androidAudioSessionId)
        .distinct()
        .handleError((Object err, StackTrace stackTrace) {/* noop */}));
    _sequenceStateSubject.addStream(Rx.combineLatest5<List<IndexedAudioSource>?,
        List<int>?, int?, bool, LoopMode, SequenceState?>(
      sequenceStream,
      shuffleIndicesStream,
      currentIndexStream,
      shuffleModeEnabledStream,
      loopModeStream,
      (sequence, shuffleIndices, currentIndex, shuffleModeEnabled, loopMode) {
        if (sequence == null) return null;
        if (shuffleIndices == null) return null;
        currentIndex ??= 0;
        currentIndex = max(min(sequence.length - 1, max(0, currentIndex)), 0);
        return SequenceState(
          sequence,
          currentIndex,
          shuffleIndices,
          shuffleModeEnabled,
          loopMode,
        );
      },
    ).distinct().handleError((Object err, StackTrace stackTrace) {/* noop */}));
    _playerStateSubject.addStream(
        Rx.combineLatest2<bool, PlaybackEvent, PlayerState>(
                playingStream,
                playbackEventStream,
                (playing, event) => PlayerState(playing, event.processingState))
            .distinct()
            .handleError((Object err, StackTrace stackTrace) {/* noop */}));
    _shuffleModeEnabledSubject.add(false);
    _loopModeSubject.add(LoopMode.off);
    _setPlatformActive(false, force: true)
        ?.catchError((dynamic e) async => null);
    _sequenceSubject.add(null);
    // Respond to changes to AndroidAudioAttributes configuration.
    if (androidApplyAudioAttributes && _isAndroid()) {
      AudioSession.instance.then((audioSession) {
        audioSession.configurationStream
            .map((conf) => conf.androidAudioAttributes)
            .where((attributes) => attributes != null)
            .cast<AndroidAudioAttributes>()
            .distinct()
            .listen(setAndroidAudioAttributes);
      });
    }
    if (handleInterruptions) {
      AudioSession.instance.then((session) {
        session.becomingNoisyEventStream.listen((_) {
          pause();
        });
        session.interruptionEventStream.listen((event) {
          if (event.begin) {
            switch (event.type) {
              case AudioInterruptionType.duck:
                assert(_isAndroid());
                if (session.androidAudioAttributes!.usage ==
                    AndroidAudioUsage.game) {
                  setVolume(volume / 2);
                }
                _playInterrupted = false;
                break;
              case AudioInterruptionType.pause:
              case AudioInterruptionType.unknown:
                if (playing) {
                  pause();
                  // Although pause is async and sets _playInterrupted = false,
                  // this is done in the sync portion.
                  _playInterrupted = true;
                }
                break;
            }
          } else {
            switch (event.type) {
              case AudioInterruptionType.duck:
                assert(_isAndroid());
                setVolume(min(1.0, volume * 2));
                _playInterrupted = false;
                break;
              case AudioInterruptionType.pause:
                if (_playInterrupted) play();
                _playInterrupted = false;
                break;
              case AudioInterruptionType.unknown:
                _playInterrupted = false;
                break;
            }
          }
        });
      });
    }
    _removeOldAssetCacheDir();
  }

  /// Old versions of just_audio used an asset caching system that created a
  /// separate cache file per asset per player instance, and was highly
  /// dependent on the app calling [dispose] to clean up afterwards. If the app
  /// is upgrading from an old version of just_audio, this will delete the old
  /// cache directory.
  Future<void> _removeOldAssetCacheDir() async {
    if (kIsWeb) return;
    try {
      final oldAssetCacheDir = Directory(p.join(
          (await getTemporaryDirectory()).path, 'just_audio_asset_cache'));
      if (oldAssetCacheDir.existsSync()) {
        try {
          oldAssetCacheDir.deleteSync(recursive: true);
        } catch (e) {
          // ignore: avoid_print
          print("Failed to delete old asset cache dir: $e");
        }
      }
    } catch (e) {
      // There is no temporary directory for this platform.
    }
  }

  /// The previously set [AudioSource], if any.
  AudioSource? get audioSource => _audioSource;

  /// The latest [PlaybackEvent].
  PlaybackEvent get playbackEvent => _playbackEvent;

  /// A stream of [PlaybackEvent]s.
  Stream<PlaybackEvent> get playbackEventStream => _playbackEventSubject.stream;

  /// The duration of the current audio or `null` if unknown.
  Duration? get duration => _playbackEvent.duration;

  /// The duration of the current audio or `null` if unknown.
  Future<Duration?>? get durationFuture => _durationFuture;

  /// The duration of the current audio.
  Stream<Duration?> get durationStream => _durationSubject.stream;

  /// The current [ProcessingState].
  ProcessingState get processingState => _playbackEvent.processingState;

  /// A stream of [ProcessingState]s.
  Stream<ProcessingState> get processingStateStream =>
      _processingStateSubject.stream;

  /// Whether the player is playing.
  bool get playing => _playingSubject.nvalue!;

  /// A stream of changing [playing] states.
  Stream<bool> get playingStream => _playingSubject.stream;

  /// The current volume of the player.
  double get volume => _volumeSubject.nvalue!;

  /// A stream of [volume] changes.
  Stream<double> get volumeStream => _volumeSubject.stream;

  /// The current speed of the player.
  double get speed => _speedSubject.nvalue!;

  /// A stream of current speed values.
  Stream<double> get speedStream => _speedSubject.stream;

  /// The current pitch factor of the player.
  double get pitch => _pitchSubject.nvalue!;

  /// A stream of current pitch factor values.
  Stream<double> get pitchStream => _pitchSubject.stream;

  /// The current skipSilenceEnabled factor of the player.
  bool get skipSilenceEnabled => _skipSilenceEnabledSubject.nvalue!;

  /// A stream of current skipSilenceEnabled factor values.
  Stream<bool> get skipSilenceEnabledStream =>
      _skipSilenceEnabledSubject.stream;

  /// The position up to which buffered audio is available.
  Duration get bufferedPosition =>
      _bufferedPositionSubject.nvalue ?? Duration.zero;

  /// A stream of buffered positions.
  Stream<Duration> get bufferedPositionStream =>
      _bufferedPositionSubject.stream;

  /// The latest ICY metadata received through the audio source, or `null` if no
  /// metadata is available.
  IcyMetadata? get icyMetadata => _playbackEvent.icyMetadata;

  /// A stream of ICY metadata received through the audio source.
  Stream<IcyMetadata?> get icyMetadataStream => _icyMetadataSubject.stream;

  /// The current player state containing only the processing and playing
  /// states.
  PlayerState get playerState =>
      _playerStateSubject.nvalue ?? PlayerState(false, ProcessingState.idle);

  /// A stream of [PlayerState]s.
  Stream<PlayerState> get playerStateStream => _playerStateSubject.stream;

  /// The current sequence of indexed audio sources, or `null` if no audio
  /// source is set.
  List<IndexedAudioSource>? get sequence => _sequenceSubject.nvalue;

  /// A stream broadcasting the current sequence of indexed audio sources.
  Stream<List<IndexedAudioSource>?> get sequenceStream =>
      _sequenceSubject.stream;

  /// The current shuffled sequence of indexed audio sources, or `null` if no
  /// audio source is set.
  List<int>? get shuffleIndices => _shuffleIndicesSubject.nvalue;

  /// A stream broadcasting the current shuffled sequence of indexed audio
  /// sources.
  Stream<List<int>?> get shuffleIndicesStream => _shuffleIndicesSubject.stream;

  //List<IndexedAudioSource> get _effectiveSequence =>
  //    shuffleModeEnabled ? shuffleIndices : sequence;

  /// The index of the current item, or `null` if either no audio source is set,
  /// or the current audio source has an empty sequence.
  int? get currentIndex => _currentIndexSubject.nvalue;

  /// A stream broadcasting the current item.
  Stream<int?> get currentIndexStream => _currentIndexSubject.stream;

  /// The current [SequenceState], or `null` if either [sequence]] or
  /// [currentIndex] is `null`.
  SequenceState? get sequenceState => _sequenceStateSubject.nvalue;

  /// A stream broadcasting the current [SequenceState].
  Stream<SequenceState?> get sequenceStateStream =>
      _sequenceStateSubject.stream;

  /// Whether there is another item after the current index.
  bool get hasNext => nextIndex != null;

  /// Whether there is another item before the current index.
  bool get hasPrevious => previousIndex != null;

  /// Returns [shuffleIndices] if [shuffleModeEnabled] is `true`, otherwise
  /// returns the unshuffled indices. When no current audio source is set, this
  /// returns `null`.
  List<int>? get effectiveIndices {
    if (shuffleIndices == null || sequence == null) return null;
    return shuffleModeEnabled
        ? shuffleIndices
        : List.generate(sequence!.length, (i) => i);
  }

  List<int>? get _effectiveIndicesInv {
    if (shuffleIndices == null || sequence == null) return null;
    return shuffleModeEnabled
        ? _shuffleIndicesInv
        : List.generate(sequence!.length, (i) => i);
  }

  /// The index of the next item to be played, or `null` if there is no next
  /// item.
  int? get nextIndex => _getRelativeIndex(1);

  /// The index of the previous item in play order, or `null` if there is no
  /// previous item.
  int? get previousIndex => _getRelativeIndex(-1);

  int? _getRelativeIndex(int offset) {
    if (_audioSource == null || currentIndex == null) return null;
    if (loopMode == LoopMode.one) return currentIndex;
    final effectiveIndices = this.effectiveIndices;
    if (effectiveIndices == null || effectiveIndices.isEmpty) return null;
    final effectiveIndicesInv = _effectiveIndicesInv!;
    if (currentIndex! >= effectiveIndicesInv.length) return null;
    final invPos = effectiveIndicesInv[currentIndex!];
    var newInvPos = invPos + offset;
    if (newInvPos >= effectiveIndices.length || newInvPos < 0) {
      if (loopMode == LoopMode.all) {
        newInvPos %= effectiveIndices.length;
      } else {
        return null;
      }
    }
    final result = effectiveIndices[newInvPos];
    return result;
  }

  /// The current loop mode.
  LoopMode get loopMode => _loopModeSubject.nvalue!;

  /// A stream of [LoopMode]s.
  Stream<LoopMode> get loopModeStream => _loopModeSubject.stream;

  /// Whether shuffle mode is currently enabled.
  bool get shuffleModeEnabled => _shuffleModeEnabledSubject.nvalue!;

  /// A stream of the shuffle mode status.
  Stream<bool> get shuffleModeEnabledStream =>
      _shuffleModeEnabledSubject.stream;

  /// The current Android AudioSession ID or `null` if not set.
  int? get androidAudioSessionId => _playbackEvent.androidAudioSessionId;

  /// Broadcasts the current Android AudioSession ID or `null` if not set.
  Stream<int?> get androidAudioSessionIdStream =>
      _androidAudioSessionIdSubject.stream;

  /// A stream broadcasting every position discontinuity.
  Stream<PositionDiscontinuity> get positionDiscontinuityStream =>
      _positionDiscontinuitySubject.stream;

  /// Whether the player should automatically delay playback in order to
  /// minimize stalling. (iOS 10.0 or later only)
  bool get automaticallyWaitsToMinimizeStalling =>
      _automaticallyWaitsToMinimizeStalling;

  /// Whether the player can use the network for live streaming while paused on
  /// iOS/macOS.
  bool get canUseNetworkResourcesForLiveStreamingWhilePaused =>
      _canUseNetworkResourcesForLiveStreamingWhilePaused;

  /// The preferred peak bit rate (in bits per second) of bandwidth usage on iOS/macOS.
  double get preferredPeakBitRate => _preferredPeakBitRate;

  /// The current position of the player.
  Duration get position => _getPositionFor(_playbackEvent);

  Duration _getPositionFor(PlaybackEvent playbackEvent) {
    if (playing && processingState == ProcessingState.ready) {
      final result = playbackEvent.updatePosition +
          (DateTime.now().difference(playbackEvent.updateTime)) * speed;
      return playbackEvent.duration == null || result <= playbackEvent.duration!
          ? result
          : playbackEvent.duration!;
    } else {
      return playbackEvent.updatePosition;
    }
  }

  /// A stream tracking the current position of this player, suitable for
  /// animating a seek bar. To ensure a smooth animation, this stream emits
  /// values more frequently on short items where the seek bar moves more
  /// quickly, and less frequenly on long items where the seek bar moves more
  /// slowly. The interval between each update will be no quicker than once
  /// every 16ms and no slower than once every 200ms.
  ///
  /// See [createPositionStream] for more control over the stream parameters.
  Stream<Duration> get positionStream {
    if (_positionSubject == null) {
      _positionSubject = BehaviorSubject<Duration>();
      if (!_disposed) {
        _positionSubject!.addStream(createPositionStream(
            steps: 800,
            minPeriod: const Duration(milliseconds: 16),
            maxPeriod: const Duration(milliseconds: 200)));
      }
    }
    return _positionSubject!.stream;
  }

  /// Creates a new stream periodically tracking the current position of this
  /// player. The stream will aim to emit [steps] position updates from the
  /// beginning to the end of the current audio source, at intervals of
  /// [duration] / [steps]. This interval will be clipped between [minPeriod]
  /// and [maxPeriod]. This stream will not emit values while audio playback is
  /// paused or stalled.
  ///
  /// Note: each time this method is called, a new stream is created. If you
  /// intend to use this stream multiple times, you should hold a reference to
  /// the returned stream and close it once you are done.
  Stream<Duration> createPositionStream({
    int steps = 800,
    Duration minPeriod = const Duration(milliseconds: 200),
    Duration maxPeriod = const Duration(milliseconds: 200),
  }) {
    assert(minPeriod <= maxPeriod);
    assert(minPeriod > Duration.zero);
    final controller = StreamController<Duration>.broadcast();
    if (_disposed) return controller.stream;

    Duration duration() => this.duration ?? Duration.zero;
    Duration step() {
      var s = duration() ~/ steps;
      if (s < minPeriod) s = minPeriod;
      if (s > maxPeriod) s = maxPeriod;
      return s;
    }

    Timer? currentTimer;
    StreamSubscription? durationSubscription;
    StreamSubscription? playbackEventSubscription;
    void yieldPosition(Timer timer) {
      if (controller.isClosed) {
        timer.cancel();
        durationSubscription?.cancel();
        playbackEventSubscription?.cancel();
        return;
      }
      if (_durationSubject.isClosed) {
        timer.cancel();
        durationSubscription?.cancel();
        playbackEventSubscription?.cancel();
        // This will in turn close _positionSubject.
        controller.close();
        return;
      }
      if (playing) {
        controller.add(position);
      }
    }

    durationSubscription = durationStream.listen((duration) {
      currentTimer?.cancel();
      currentTimer = Timer.periodic(step(), yieldPosition);
    }, onError: (Object e, StackTrace stackTrace) {});
    playbackEventSubscription = playbackEventStream.listen((event) {
      controller.add(position);
    }, onError: (Object e, StackTrace stackTrace) {});
    return controller.stream.distinct();
  }

  /// Convenience method to set the audio source to a URL with optional headers,
  /// preloaded by default, with an initial position of zero by default.
  /// If headers are set, just_audio will create a cleartext local HTTP proxy on
  /// your device to forward HTTP requests with headers included.
  ///
  /// This is equivalent to:
  ///
  /// ```
  /// setAudioSource(AudioSource.uri(Uri.parse(url), headers: headers),
  ///     initialPosition: Duration.zero, preload: true);
  /// ```
  ///
  /// See [setAudioSource] for a detailed explanation of the options.
  Future<Duration?> setUrl(
    String url, {
    Map<String, String>? headers,
    Duration? initialPosition,
    bool preload = true,
  }) =>
      setAudioSource(AudioSource.uri(Uri.parse(url), headers: headers),
          initialPosition: initialPosition, preload: preload);

  /// Convenience method to set the audio source to a file, preloaded by
  /// default, with an initial position of zero by default.
  ///
  /// ```
  /// setAudioSource(AudioSource.uri(Uri.file(filePath)),
  ///     initialPosition: Duration.zero, preload: true);
  /// ```
  ///
  /// See [setAudioSource] for a detailed explanation of the options.
  Future<Duration?> setFilePath(
    String filePath, {
    Duration? initialPosition,
    bool preload = true,
  }) =>
      setAudioSource(AudioSource.uri(Uri.file(filePath)),
          initialPosition: initialPosition, preload: preload);

  /// Convenience method to set the audio source to an asset, preloaded by
  /// default, with an initial position of zero by default.
  ///
  /// ```
  /// setAudioSource(AudioSource.uri(Uri.parse('asset:///$assetPath')),
  ///     initialPosition: Duration.zero, preload: true);
  /// ```
  ///
  /// See [setAudioSource] for a detailed explanation of the options.
  Future<Duration?> setAsset(
    String assetPath, {
    bool preload = true,
    Duration? initialPosition,
  }) =>
      setAudioSource(AudioSource.uri(Uri.parse('asset:///$assetPath')),
          initialPosition: initialPosition, preload: preload);

  /// Sets the source from which this audio player should fetch audio.
  ///
  /// By default, this method will immediately start loading audio and return
  /// its duration as soon as it is known, or `null` if that information is
  /// unavailable. Set [preload] to `false` if you would prefer to delay loading
  /// until some later point, either via an explicit call to [load] or via a
  /// call to [play] which implicitly loads the audio. If [preload] is `false`,
  /// a `null` duration will be returned. Note that the [preload] option will
  /// automatically be assumed as `true` if `playing` is currently `true`.
  ///
  /// Optionally specify [initialPosition] and [initialIndex] to seek to an
  /// initial position within a particular item (defaulting to position zero of
  /// the first item).
  ///
  /// When [preload] is `true`, this method may throw:
  ///
  /// * [Exception] if no audio source has been previously set.
  /// * [PlayerException] if the audio source was unable to be loaded.
  /// * [PlayerInterruptedException] if another audio source was loaded before
  /// this call completed or the player was stopped or disposed of before the
  /// call completed.
  Future<Duration?> setAudioSource(
    AudioSource source, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
  }) async {
    if (_disposed) return null;
    _audioSource = null;
    _initialSeekValues =
        _InitialSeekValues(position: initialPosition, index: initialIndex);
    _playbackEventSubject.add(_playbackEvent = PlaybackEvent(
        currentIndex: initialIndex ?? 0,
        updatePosition: initialPosition ?? Duration.zero));
    _audioSource = source;
    _broadcastSequence();
    Duration? duration;
    if (playing) preload = true;
    if (preload) {
      duration = await load();
    } else {
      await _setPlatformActive(false)?.catchError((dynamic e) async => null);
    }
    return duration;
  }

  /// Starts loading the current audio source and returns the audio duration as
  /// soon as it is known, or `null` if unavailable.
  ///
  /// This method throws:
  ///
  /// * [Exception] if no audio source has been previously set.
  /// * [PlayerException] if the audio source was unable to be loaded.
  /// * [PlayerInterruptedException] if another call to [load] happened before
  /// this call completed or the player was stopped or disposed of before the
  /// call could complete.
  Future<Duration?> load() async {
    if (_disposed) return null;
    if (_audioSource == null) {
      throw Exception('Must set AudioSource before loading');
    }
    if (_active) {
      final initialSeekValues = _initialSeekValues;
      _initialSeekValues = null;
      return await _load(await _platform, _audioSource!,
          initialSeekValues: initialSeekValues);
    } else {
      // This will implicitly load the current audio source.
      return await _setPlatformActive(true);
    }
  }

  void _broadcastSequence() {
    // TODO: update currentIndex first if it's out of range as a result of
    // removing items from the playlist.
    _sequenceSubject.add(_audioSource?.sequence);
    _updateShuffleIndices();
  }

  void _updateShuffleIndices() {
    _shuffleIndicesSubject.add(_audioSource?.shuffleIndices);
    final shuffleIndicesLength = shuffleIndices?.length ?? 0;
    if (_shuffleIndicesInv.length > shuffleIndicesLength) {
      _shuffleIndicesInv.removeRange(
          shuffleIndicesLength, _shuffleIndicesInv.length);
    } else if (_shuffleIndicesInv.length < shuffleIndicesLength) {
      _shuffleIndicesInv.addAll(
          List.filled(shuffleIndicesLength - _shuffleIndicesInv.length, 0));
    }
    for (var i = 0; i < shuffleIndicesLength; i++) {
      _shuffleIndicesInv[shuffleIndices![i]] = i;
    }
  }

  void _registerAudioSource(AudioSource source) {
    _audioSources[source._id] = source;
  }

  Future<Duration?> _load(AudioPlayerPlatform platform, AudioSource source,
      {_InitialSeekValues? initialSeekValues}) async {
    final activationNumber = _activationCount;
    void checkInterruption() {
      if (_activationCount != activationNumber) {
        // the platform has changed since we started loading, so abort.
        throw PlatformException(code: 'abort', message: 'Loading interrupted');
      }
    }

    try {
      await source._setup(this);
      checkInterruption();
      source._shuffle(initialIndex: initialSeekValues?.index ?? 0);
      _broadcastSequence();
      _durationFuture = platform
          .load(LoadRequest(
            audioSourceMessage: source._toMessage(),
            initialPosition: initialSeekValues?.position,
            initialIndex: initialSeekValues?.index,
          ))
          .then((response) => response.duration);
      final duration = await _durationFuture;
      checkInterruption();
      _durationSubject.add(duration);
      if (platform != _platformValue) {
        // the platform has changed since we started loading, so abort.
        throw PlatformException(code: 'abort', message: 'Loading interrupted');
      }
      // Wait for loading state to pass.
      await processingStateStream
          .firstWhere((state) => state != ProcessingState.loading);
      checkInterruption();
      return duration;
    } on PlatformException catch (e) {
      try {
        throw PlayerException(int.parse(e.code), e.message);
      } on FormatException catch (_) {
        if (e.code == 'abort') {
          throw PlayerInterruptedException(e.message);
        } else {
          throw PlayerException(9999999, e.message);
        }
      }
    }
  }

  /// Clips the current [AudioSource] to the given [start] and [end]
  /// timestamps. If [start] is null, it will be reset to the start of the
  /// original [AudioSource]. If [end] is null, it will be reset to the end of
  /// the original [AudioSource]. This method cannot be called from the
  /// [ProcessingState.idle] state.
  Future<Duration?> setClip({Duration? start, Duration? end}) async {
    if (_disposed) return null;
    _setPlatformActive(true)?.catchError((dynamic e) async => null);
    final duration = await _load(
        await _platform,
        start == null && end == null
            ? _audioSource!
            : ClippingAudioSource(
                child: _audioSource as UriAudioSource,
                start: start,
                end: end,
              ));
    return duration;
  }

  /// Tells the player to play audio at the current [speed] and [volume] as soon
  /// as an audio source is loaded and ready to play. If an audio source has
  /// been set but not preloaded, this method will also initiate the loading.
  /// The [Future] returned by this method completes when the playback completes
  /// or is paused or stopped. If the player is already playing, this method
  /// completes immediately.
  ///
  /// This method causes [playing] to become true, and it will remain true
  /// until [pause] or [stop] is called. This means that if playback completes,
  /// and then you [seek] to an earlier position in the audio, playback will
  /// continue playing from that position. If you instead wish to [pause] or
  /// [stop] playback on completion, you can call either method as soon as
  /// [processingState] becomes [ProcessingState.completed] by listening to
  /// [processingStateStream].
  ///
  /// This method activates the audio session before playback, and will do
  /// nothing if activation of the audio session fails for any reason.
  Future<void> play() async {
    if (_disposed) return;
    if (playing) return;
    _playInterrupted = false;
    // Broadcast to clients immediately, but revert to false if we fail to
    // activate the audio session. This allows setAudioSource to be aware of a
    // prior play request.
    _playbackEvent = _playbackEvent.copyWith(
      updatePosition: position,
      updateTime: DateTime.now(),
    );
    _playingSubject.add(true);
    _playbackEventSubject.add(_playbackEvent);
    final playCompleter = Completer<dynamic>();
    final audioSession = await AudioSession.instance;
    if (!_handleAudioSessionActivation || await audioSession.setActive(true)) {
      if (!playing) return;
      // TODO: rewrite this to more cleanly handle simultaneous load/play
      // requests which each may result in platform play requests.
      final requireActive = _audioSource != null;
      if (requireActive) {
        if (_active) {
          // If the native platform is already active, send it a play request.
          // NOTE: If a load() request happens simultaneously, this may result
          // in two play requests being sent. The platform implementation should
          // ignore the second play request since it is already playing.
          _sendPlayRequest(await _platform, playCompleter);
        } else {
          // If the native platform wasn't already active, activating it will
          // implicitly restore the playing state and send a play request.
          _setPlatformActive(true, playCompleter: playCompleter)
              ?.catchError((dynamic e) async => null);
        }
      }
    } else {
      // Revert if we fail to activate the audio session.
      _playingSubject.add(false);
    }
    await playCompleter.future;
  }

  /// Pauses the currently playing media. This method does nothing if
  /// ![playing].
  Future<void> pause() async {
    if (_disposed) return;
    if (!playing) return;
    //_setPlatformActive(true);
    _playInterrupted = false;
    // Update local state immediately so that queries aren't surprised.
    _playbackEvent = _playbackEvent.copyWith(
      updatePosition: position,
      updateTime: DateTime.now(),
    );
    _playingSubject.add(false);
    _playbackEventSubject.add(_playbackEvent);
    // TODO: perhaps modify platform side to ensure new state is broadcast
    // before this method returns.
    await (await _platform).pause(PauseRequest());
  }

  Future<void> _sendPlayRequest(
      AudioPlayerPlatform platform, Completer<void>? playCompleter) async {
    try {
      if (!playing) return; // defensive
      await platform.play(PlayRequest());
      playCompleter?.complete();
    } catch (e, stackTrace) {
      playCompleter?.completeError(e, stackTrace);
    }
  }

  /// Stops playing audio and releases decoders and other native platform
  /// resources needed to play audio. The current audio source state will be
  /// retained and playback can be resumed at a later point in time.
  ///
  /// Use [stop] if the app is done playing audio for now but may need still
  /// want to resume playback later. Use [dispose] when the app is completely
  /// finished playing audio. Use [pause] instead if you would like to keep the
  /// decoders alive so that the app can quickly resume audio playback.
  Future<void> stop() async {
    if (_disposed) return;
    final future =
        _setPlatformActive(false)?.catchError((dynamic e) async => null);

    _playInterrupted = false;
    // Update local state immediately so that queries aren't surprised.
    _playingSubject.add(false);
    await future;
  }

  /// Sets the volume of this player, where 1.0 is normal volume.
  Future<void> setVolume(final double volume) async {
    if (_disposed) return;
    _volumeSubject.add(volume);
    await (await _platform).setVolume(SetVolumeRequest(volume: volume));
  }

  /// Sets whether silence should be skipped in audio playback. (Currently
  /// Android only).
  Future<void> setSkipSilenceEnabled(bool enabled) async {
    if (_disposed) return;
    final previouslyEnabled = skipSilenceEnabled;
    if (enabled == previouslyEnabled) return;
    _skipSilenceEnabledSubject.add(enabled);
    try {
      await (await _platform)
          .setSkipSilence(SetSkipSilenceRequest(enabled: enabled));
    } catch (e) {
      _skipSilenceEnabledSubject.add(previouslyEnabled);
      rethrow;
    }
  }

  /// Sets the playback speed to use when [playing] is `true`, where 1.0 is
  /// normal speed. Note that values in excess of 1.0 may result in stalls if
  /// the playback speed is faster than the player is able to downloaded the
  /// audio.
  Future<void> setSpeed(final double speed) async {
    if (_disposed) return;
    _playbackEvent = _playbackEvent.copyWith(
      updatePosition: position,
      updateTime: DateTime.now(),
    );
    _playbackEventSubject.add(_playbackEvent);
    _speedSubject.add(speed);
    await (await _platform).setSpeed(SetSpeedRequest(speed: speed));
  }

  /// Sets the factor by which pitch will be shifted.
  Future<void> setPitch(final double pitch) async {
    if (_disposed) return;
    _playbackEvent = _playbackEvent.copyWith(
      updatePosition: position,
      updateTime: DateTime.now(),
    );
    _playbackEventSubject.add(_playbackEvent);
    _pitchSubject.add(pitch);
    await (await _platform).setPitch(SetPitchRequest(pitch: pitch));
  }

  /// Sets the [LoopMode]. Looping will be gapless on Android, iOS and macOS. On
  /// web, there will be a slight gap at the loop point.
  Future<void> setLoopMode(LoopMode mode) async {
    if (_disposed) return;
    _loopModeSubject.add(mode);
    await (await _platform).setLoopMode(
        SetLoopModeRequest(loopMode: LoopModeMessage.values[mode.index]));
  }

  /// Sets whether shuffle mode is enabled.
  Future<void> setShuffleModeEnabled(bool enabled) async {
    if (_disposed) return;
    _shuffleModeEnabledSubject.add(enabled);
    await (await _platform).setShuffleMode(SetShuffleModeRequest(
        shuffleMode:
            enabled ? ShuffleModeMessage.all : ShuffleModeMessage.none));
  }

  /// Recursively shuffles the children of the currently loaded [AudioSource].
  /// Each [ConcatenatingAudioSource] will be shuffled according to its
  /// configured [ShuffleOrder].
  Future<void> shuffle() async {
    if (_disposed) return;
    if (_audioSource == null) return;
    _audioSource!._shuffle(initialIndex: currentIndex);
    _updateShuffleIndices();
    await (await _platform).setShuffleOrder(
        SetShuffleOrderRequest(audioSourceMessage: _audioSource!._toMessage()));
  }

  /// Sets automaticallyWaitsToMinimizeStalling for AVPlayer in iOS 10.0 or later, defaults to true.
  /// Has no effect on Android clients
  Future<void> setAutomaticallyWaitsToMinimizeStalling(
      final bool automaticallyWaitsToMinimizeStalling) async {
    if (_disposed) return;
    _automaticallyWaitsToMinimizeStalling =
        automaticallyWaitsToMinimizeStalling;
    await (await _platform).setAutomaticallyWaitsToMinimizeStalling(
        SetAutomaticallyWaitsToMinimizeStallingRequest(
            enabled: automaticallyWaitsToMinimizeStalling));
  }

  /// Sets canUseNetworkResourcesForLiveStreamingWhilePaused on iOS/macOS,
  /// defaults to false.
  Future<void> setCanUseNetworkResourcesForLiveStreamingWhilePaused(
      final bool canUseNetworkResourcesForLiveStreamingWhilePaused) async {
    if (_disposed) return;
    _canUseNetworkResourcesForLiveStreamingWhilePaused =
        canUseNetworkResourcesForLiveStreamingWhilePaused;
    await (await _platform)
        .setCanUseNetworkResourcesForLiveStreamingWhilePaused(
            SetCanUseNetworkResourcesForLiveStreamingWhilePausedRequest(
                enabled: canUseNetworkResourcesForLiveStreamingWhilePaused));
  }

  /// Sets preferredPeakBitRate on iOS/macOS, defaults to true.
  Future<void> setPreferredPeakBitRate(
      final double preferredPeakBitRate) async {
    if (_disposed) return;
    _preferredPeakBitRate = preferredPeakBitRate;
    await (await _platform).setPreferredPeakBitRate(
        SetPreferredPeakBitRateRequest(bitRate: preferredPeakBitRate));
  }

  /// Seeks to a particular [position]. If a composition of multiple
  /// [AudioSource]s has been loaded, you may also specify [index] to seek to a
  /// particular item within that sequence. This method has no effect unless
  /// an audio source has been loaded.
  ///
  /// A `null` [position] seeks to the head of a live stream.
  Future<void> seek(final Duration? position, {int? index}) async {
    if (_disposed) return;
    _initialSeekValues = null;
    switch (processingState) {
      case ProcessingState.loading:
        return;
      default:
        try {
          _seeking = true;
          final prevPlaybackEvent = _playbackEvent;
          _playbackEvent = prevPlaybackEvent.copyWith(
            updatePosition: position,
            updateTime: DateTime.now(),
          );
          _playbackEventSubject.add(_playbackEvent);
          _positionDiscontinuitySubject.add(PositionDiscontinuity(
              PositionDiscontinuityReason.seek,
              prevPlaybackEvent,
              _playbackEvent));
          await (await _platform)
              .seek(SeekRequest(position: position, index: index));
        } finally {
          _seeking = false;
        }
    }
  }

  /// Seek to the next item, or does nothing if there is no next item.
  Future<void> seekToNext() async {
    if (hasNext) {
      await seek(Duration.zero, index: nextIndex);
    }
  }

  /// Seek to the previous item, or does nothing if there is no previous item.
  Future<void> seekToPrevious() async {
    if (hasPrevious) {
      await seek(Duration.zero, index: previousIndex);
    }
  }

  /// Set the Android audio attributes for this player. Has no effect on other
  /// platforms. This will cause a new Android AudioSession ID to be generated.
  Future<void> setAndroidAudioAttributes(
      AndroidAudioAttributes audioAttributes) async {
    if (_disposed) return;
    if (!_isAndroid() && !_isUnitTest()) return;
    if (audioAttributes == _androidAudioAttributes) return;
    _androidAudioAttributes = audioAttributes;
    await _internalSetAndroidAudioAttributes(await _platform, audioAttributes);
  }

  Future<void> _internalSetAndroidAudioAttributes(AudioPlayerPlatform platform,
      AndroidAudioAttributes audioAttributes) async {
    if (!_isAndroid() && !_isUnitTest()) return;
    await platform.setAndroidAudioAttributes(SetAndroidAudioAttributesRequest(
        contentType: audioAttributes.contentType.index,
        flags: audioAttributes.flags.value,
        usage: audioAttributes.usage.value));
  }

  /// Release all resources associated with this player. You must invoke this
  /// after you are done with the player.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    if (_nativePlatform != null) {
      await _disposePlatform(await _nativePlatform!);
      _nativePlatform = null;
    }
    if (_idlePlatform != null) {
      await _disposePlatform(_idlePlatform!);
      _idlePlatform = null;
    }
    _audioSource = null;
    for (var s in _audioSources.values) {
      s._dispose();
    }
    _audioSources.clear();
    _proxy.stop();
    await _durationSubject.close();
    await _loopModeSubject.close();
    await _shuffleModeEnabledSubject.close();
    await _playingSubject.close();
    await _volumeSubject.close();
    await _speedSubject.close();
    await _pitchSubject.close();
    await _sequenceSubject.close();
    await _shuffleIndicesSubject.close();
  }

  /// Switch to using the native platform when [active] is `true` and using the
  /// idle platform when [active] is `false`. If an audio source has been set,
  /// the returned future completes with its duration if known, or `null`
  /// otherwise.
  ///
  /// The platform will not switch if [active] == [_active] unless [force] is
  /// `true`.
  Future<Duration?>? _setPlatformActive(bool active,
      {Completer<void>? playCompleter, bool force = false}) {
    if (_disposed) return null;
    if (!force && (active == _active)) return _durationFuture;
    _platformLoading = active;

    // Warning! Tricky async code lies ahead.
    // (This should definitely be made less tricky)
    // This method itself is not asynchronous, and guarantees that _platform
    // will be set in this cycle to a Future. The platform returned by that
    // future takes time to initialise and so we need to handle the case where
    // that initialisation was interrupted by another call to
    // _setPlatformActive.

    // Store the current activation sequence number. activationNumber should
    // equal _activationCount for the duration of this call, unless it is
    // interrupted by another simultaneous call.
    final activationNumber = ++_activationCount;

    /// Tells whether we've been interrupted.
    bool wasInterrupted() => _activationCount != activationNumber;

    final durationCompleter = Completer<Duration?>();

    // Checks if we were interrupted and aborts the current activation. If we
    // are interrupted, there are two cases:
    // 1. If we were activating the native platform, abort with an exception.
    // 2. If we were activating the idle dummy, abort silently.
    //
    // We should call this after each awaited call since those are opportunities
    // for other coroutines to run and interrupt this one.
    bool checkInterruption() {
      // No interruption.
      if (!wasInterrupted()) return false;
      // An interruption that we can ignore
      if (!active) return true;
      // An interruption that should throw
      final e =
          PlatformException(code: 'abort', message: 'Loading interrupted');
      durationCompleter.completeError(e);
      throw e;
    }

    // This method updates _active and _platform before yielding to the next
    // task in the event loop.
    _active = active;
    final position = this.position;
    final currentIndex = this.currentIndex;
    final audioSource = _audioSource;

    void subscribeToEvents(AudioPlayerPlatform platform) {
      _playerDataSubscription =
          platform.playerDataMessageStream.listen((message) {
        if (message.playing != null && message.playing != playing) {
          _playingSubject.add(message.playing!);
        }
        if (message.volume != null) {
          _volumeSubject.add(message.volume!);
        }
        if (message.speed != null) {
          _speedSubject.add(message.speed!);
        }
        if (message.pitch != null) {
          _pitchSubject.add(message.pitch!);
        }
        if (message.loopMode != null) {
          _loopModeSubject.add(LoopMode.values[message.loopMode!.index]);
        }
        if (message.shuffleMode != null) {
          _shuffleModeEnabledSubject
              .add(message.shuffleMode != ShuffleModeMessage.none);
        }
      });
      _playbackEventSubscription =
          platform.playbackEventMessageStream.listen((message) {
        var duration = message.duration;
        var index = message.currentIndex ?? currentIndex;
        if (index != null && sequence != null && index < sequence!.length) {
          if (duration == null) {
            duration = sequence![index].duration;
          } else {
            sequence![index].duration = duration;
          }
        }
        if (_platformLoading &&
            message.processingState != ProcessingStateMessage.idle) {
          _platformLoading = false;
        }
        final playbackEvent = PlaybackEvent(
          // The platform may emit an idle state while it's starting up which we
          // override here.
          processingState: _platformLoading
              ? ProcessingState.loading
              : ProcessingState.values[message.processingState.index],
          updateTime: message.updateTime,
          updatePosition: message.updatePosition,
          bufferedPosition: message.bufferedPosition,
          duration: duration,
          icyMetadata: message.icyMetadata == null
              ? null
              : IcyMetadata._fromMessage(message.icyMetadata!),
          currentIndex: index,
          androidAudioSessionId: message.androidAudioSessionId,
        );
        _durationFuture = Future.value(playbackEvent.duration);
        if (playbackEvent == _playbackEvent) {
          return;
        }
        if (playbackEvent.duration != _playbackEvent.duration) {
          _durationSubject.add(playbackEvent.duration);
        }
        final oldPlaybackEvent = _playbackEvent;
        _playbackEventSubject.add(_playbackEvent = playbackEvent);
        if (_playbackEvent.processingState !=
                oldPlaybackEvent.processingState &&
            _playbackEvent.processingState == ProcessingState.idle) {
          _setPlatformActive(false)?.catchError((dynamic e) async => null);
        }
      }, onError: _playbackEventSubject.addError);
    }

    Future<AudioPlayerPlatform> setPlatform() async {
      _playbackEventSubscription?.cancel();
      _playerDataSubscription?.cancel();
      if (!force) {
        final oldPlatform = _platformValue!;
        if (oldPlatform is! _IdleAudioPlayer) {
          await _disposePlatform(oldPlatform);
        }
      }
      if (_disposed) return _platform;
      // During initialisation, we must only use this platform reference in case
      // _platform is updated again during initialisation.
      final platform = active
          ? await (_nativePlatform = _pluginPlatform.init(InitRequest(
              id: _id,
              audioLoadConfiguration: _audioLoadConfiguration?._toMessage(),
              androidAudioEffects: (_isAndroid() || _isUnitTest())
                  ? _audioPipeline.androidAudioEffects
                      .map((audioEffect) => audioEffect._toMessage())
                      .toList()
                  : [],
              darwinAudioEffects: (_isDarwin() || _isUnitTest())
                  ? _audioPipeline.darwinAudioEffects
                      .map((audioEffect) => audioEffect._toMessage())
                      .toList()
                  : [],
              androidOffloadSchedulingEnabled: _androidOffloadSchedulingEnabled,
            )))
          : (_idlePlatform =
              _IdleAudioPlayer(id: _id, sequenceStream: sequenceStream));
      if (checkInterruption()) return platform;

      _platformValue = platform;

      if (active) {
        if (audioSource != null) {
          _playbackEventSubject.add(_playbackEvent = _playbackEvent.copyWith(
            updatePosition: position,
            processingState: ProcessingState.loading,
          ));
        }

        final automaticallyWaitsToMinimizeStalling =
            this.automaticallyWaitsToMinimizeStalling;
        final playing = this.playing;
        // To avoid a glitch in ExoPlayer, ensure that any requested audio
        // attributes are set before loading the audio source.
        if (_isAndroid() || _isUnitTest()) {
          if (_androidApplyAudioAttributes) {
            final audioSession = await AudioSession.instance;
            if (checkInterruption()) return platform;
            _androidAudioAttributes ??=
                audioSession.configuration?.androidAudioAttributes;
          }
          if (_androidAudioAttributes != null) {
            await _internalSetAndroidAudioAttributes(
                platform, _androidAudioAttributes!);
            if (checkInterruption()) return platform;
          }
        }
        if (!automaticallyWaitsToMinimizeStalling) {
          // Only set if different from default.
          await platform.setAutomaticallyWaitsToMinimizeStalling(
              SetAutomaticallyWaitsToMinimizeStallingRequest(
                  enabled: automaticallyWaitsToMinimizeStalling));
          if (checkInterruption()) return platform;
        }
        await platform.setVolume(SetVolumeRequest(volume: volume));
        if (checkInterruption()) return platform;
        await platform.setSpeed(SetSpeedRequest(speed: speed));
        if (checkInterruption()) return platform;
        try {
          await platform.setPitch(SetPitchRequest(pitch: pitch));
        } catch (e) {
          // setPitch not supported on this platform.
        }
        if (checkInterruption()) return platform;
        try {
          await platform.setSkipSilence(
              SetSkipSilenceRequest(enabled: skipSilenceEnabled));
        } catch (e) {
          // setSkipSilence not supported on this platform.
        }
        if (checkInterruption()) return platform;
        await platform.setLoopMode(SetLoopModeRequest(
            loopMode: LoopModeMessage.values[loopMode.index]));
        if (checkInterruption()) return platform;
        await platform.setShuffleMode(SetShuffleModeRequest(
            shuffleMode: shuffleModeEnabled
                ? ShuffleModeMessage.all
                : ShuffleModeMessage.none));
        if (checkInterruption()) return platform;
        if (playing) {
          _sendPlayRequest(platform, playCompleter);
        }
      }

      subscribeToEvents(platform);

      if (audioSource != null) {
        try {
          final initialSeekValues = _initialSeekValues ??
              _InitialSeekValues(position: position, index: currentIndex);
          _initialSeekValues = null;
          final duration = await _load(platform, _audioSource!,
              initialSeekValues: initialSeekValues);
          if (checkInterruption()) return platform;
          durationCompleter.complete(duration);
        } catch (e, stackTrace) {
          await _setPlatformActive(false)
              ?.catchError((dynamic e) async => null);
          durationCompleter.completeError(e, stackTrace);
        }
      } else {
        durationCompleter.complete(null);
      }

      return platform;
    }

    Future<void> initAudioEffects() async {
      for (var audioEffect in _audioPipeline._audioEffects) {
        await audioEffect._activate();
        if (checkInterruption()) return;
      }
    }

    _platform = setPlatform();
    if (_active) {
      initAudioEffects().catchError((dynamic e) async {});
    }
    return durationCompleter.future;
  }

  /// Dispose of the given platform.
  Future<void> _disposePlatform(AudioPlayerPlatform platform) async {
    if (platform is _IdleAudioPlayer) {
      await platform.dispose(DisposeRequest());
    } else {
      _nativePlatform = null;
      try {
        await _pluginPlatform.disposePlayer(DisposePlayerRequest(id: _id));
      } catch (e) {
        // Fallback if disposePlayer hasn't been implemented.
        await platform.dispose(DisposeRequest());
      }
    }
  }

  /// Clears the plugin's internal asset cache directory. Call this when the
  /// app's assets have changed to force assets to be re-fetched from the asset
  /// bundle.
  static Future<void> clearAssetCache() async {
    if (kIsWeb) return;
    await for (var file in (await _getCacheDir()).list()) {
      await file.delete(recursive: true);
    }
  }
}

/// Captures the details of any error accessing, loading or playing an audio
/// source, including an invalid or inaccessible URL, or an audio encoding that
/// could not be understood.
class PlayerException implements Exception {
  /// On iOS and macOS, maps to `NSError.code`. On Android, maps to
  /// `ExoPlaybackException.type`. On Web, maps to `MediaError.code`.
  final int code;

  /// On iOS and macOS, maps to `NSError.localizedDescription`. On Android,
  /// maps to `ExoPlaybackException.getMessage()`. On Web, a generic message
  /// is provided.
  final String? message;

  PlayerException(this.code, this.message);

  @override
  String toString() => "($code) $message";
}

/// An error that occurs when one operation on the player has been interrupted
/// (e.g. by another simultaneous operation).
class PlayerInterruptedException implements Exception {
  final String? message;

  PlayerInterruptedException(this.message);

  @override
  String toString() => "$message";
}

/// Encapsulates the playback state and current position of the player.
class PlaybackEvent {
  /// The current processing state.
  final ProcessingState processingState;

  /// When the last time a position discontinuity happened, as measured in time
  /// since the epoch.
  final DateTime updateTime;

  /// The position at [updateTime].
  final Duration updatePosition;

  /// The buffer position.
  final Duration bufferedPosition;

  /// The media duration, or `null` if unknown.
  final Duration? duration;

  /// The latest ICY metadata received through the audio stream if available.
  final IcyMetadata? icyMetadata;

  /// The index of the currently playing item, or `null` if no item is selected.
  final int? currentIndex;

  /// The current Android AudioSession ID if set.
  final int? androidAudioSessionId;

  PlaybackEvent({
    this.processingState = ProcessingState.idle,
    DateTime? updateTime,
    this.updatePosition = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.duration,
    this.icyMetadata,
    this.currentIndex,
    this.androidAudioSessionId,
  }) : updateTime = updateTime ?? DateTime.now();

  /// Returns a copy of this event with given properties replaced.
  PlaybackEvent copyWith({
    ProcessingState? processingState,
    DateTime? updateTime,
    Duration? updatePosition,
    Duration? bufferedPosition,
    Duration? duration,
    IcyMetadata? icyMetadata,
    int? currentIndex,
    int? androidAudioSessionId,
  }) =>
      PlaybackEvent(
        processingState: processingState ?? this.processingState,
        updateTime: updateTime ?? this.updateTime,
        updatePosition: updatePosition ?? this.updatePosition,
        bufferedPosition: bufferedPosition ?? this.bufferedPosition,
        duration: duration ?? this.duration,
        icyMetadata: icyMetadata ?? this.icyMetadata,
        currentIndex: currentIndex ?? this.currentIndex,
        androidAudioSessionId:
            androidAudioSessionId ?? this.androidAudioSessionId,
      );

  @override
  int get hashCode => Object.hash(
        processingState,
        updateTime,
        updatePosition,
        bufferedPosition,
        duration,
        icyMetadata,
        currentIndex,
        androidAudioSessionId,
      );

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is PlaybackEvent &&
      processingState == other.processingState &&
      updateTime == other.updateTime &&
      updatePosition == other.updatePosition &&
      bufferedPosition == other.bufferedPosition &&
      duration == other.duration &&
      icyMetadata == other.icyMetadata &&
      currentIndex == other.currentIndex &&
      androidAudioSessionId == other.androidAudioSessionId;

  @override
  String toString() =>
      "{processingState=$processingState, updateTime=$updateTime, updatePosition=$updatePosition, bufferedPosition=$bufferedPosition, duration=$duration, currentIndex=$currentIndex}";
}

/// Enumerates the different processing states of a player.
enum ProcessingState {
  /// The player has not loaded an [AudioSource].
  idle,

  /// The player is loading an [AudioSource].
  loading,

  /// The player is buffering audio and unable to play.
  buffering,

  /// The player is has enough audio buffered and is able to play.
  ready,

  /// The player has reached the end of the audio.
  completed,
}

/// Encapsulates the playing and processing states. These two states vary
/// orthogonally, and so if [processingState] is [ProcessingState.buffering],
/// you can check [playing] to determine whether the buffering occurred while
/// the player was playing or while the player was paused.
class PlayerState {
  /// Whether the player will play when [processingState] is
  /// [ProcessingState.ready].
  final bool playing;

  /// The current processing state of the player.
  final ProcessingState processingState;

  PlayerState(this.playing, this.processingState);

  @override
  String toString() => 'playing=$playing,processingState=$processingState';

  @override
  int get hashCode => Object.hash(playing, processingState);

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is PlayerState &&
      other.playing == playing &&
      other.processingState == processingState;
}

class IcyInfo {
  final String? title;
  final String? url;

  static IcyInfo _fromMessage(IcyInfoMessage message) => IcyInfo(
        title: message.title,
        url: message.url,
      );

  IcyInfo({required this.title, required this.url});

  @override
  String toString() => 'title=$title,url=$url';

  @override
  int get hashCode => Object.hash(title, url);

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is IcyInfo &&
      other.title == title &&
      other.url == url;
}

class IcyHeaders {
  final int? bitrate;
  final String? genre;
  final String? name;
  final int? metadataInterval;
  final String? url;
  final bool? isPublic;

  static IcyHeaders _fromMessage(IcyHeadersMessage message) => IcyHeaders(
        bitrate: message.bitrate,
        genre: message.genre,
        name: message.name,
        metadataInterval: message.metadataInterval,
        url: message.url,
        isPublic: message.isPublic,
      );

  IcyHeaders({
    required this.bitrate,
    required this.genre,
    required this.name,
    required this.metadataInterval,
    required this.url,
    required this.isPublic,
  });

  @override
  String toString() =>
      'bitrate=$bitrate,genre=$genre,name=$name,metadataInterval=$metadataInterval,url=$url,isPublic=$isPublic';

  @override
  int get hashCode => toString().hashCode;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is IcyHeaders &&
      other.bitrate == bitrate &&
      other.genre == genre &&
      other.name == name &&
      other.metadataInterval == metadataInterval &&
      other.url == url &&
      other.isPublic == isPublic;
}

class IcyMetadata {
  final IcyInfo? info;
  final IcyHeaders? headers;

  static IcyMetadata _fromMessage(IcyMetadataMessage message) => IcyMetadata(
        info: message.info == null ? null : IcyInfo._fromMessage(message.info!),
        headers: message.headers == null
            ? null
            : IcyHeaders._fromMessage(message.headers!),
      );

  IcyMetadata({required this.info, required this.headers});

  @override
  int get hashCode => Object.hash(info, headers);

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is IcyMetadata &&
      other.info == info &&
      other.headers == headers;
}

/// Encapsulates the [sequence] and [currentIndex] state and ensures
/// consistency such that [currentIndex] is within the range of
/// `sequence.length`. If `sequence.length` is 0, then [currentIndex] is also
/// 0.
class SequenceState {
  /// The sequence of the current [AudioSource].
  final List<IndexedAudioSource> sequence;

  /// The index of the current source in the sequence.
  final int currentIndex;

  /// The current shuffle order
  final List<int> shuffleIndices;

  /// Whether shuffle mode is enabled.
  final bool shuffleModeEnabled;

  /// The current loop mode.
  final LoopMode loopMode;

  SequenceState(this.sequence, this.currentIndex, this.shuffleIndices,
      this.shuffleModeEnabled, this.loopMode);

  /// The current source in the sequence.
  IndexedAudioSource? get currentSource =>
      sequence.isEmpty ? null : sequence[currentIndex];

  /// The effective sequence. This is equivalent to [sequence]. If
  /// [shuffleModeEnabled] is true, this is modulated by [shuffleIndices].
  List<IndexedAudioSource> get effectiveSequence => shuffleModeEnabled
      ? shuffleIndices.map((i) => sequence[i]).toList()
      : sequence;
}

/// Configuration options to use when loading audio from a source.
class AudioLoadConfiguration {
  /// Bufferring and loading options for iOS/macOS.
  final DarwinLoadControl? darwinLoadControl;

  /// Buffering and loading options for Android.
  final AndroidLoadControl? androidLoadControl;

  /// Speed control for live streams on Android.
  final AndroidLivePlaybackSpeedControl? androidLivePlaybackSpeedControl;

  AudioLoadConfiguration({
    this.darwinLoadControl,
    this.androidLoadControl,
    this.androidLivePlaybackSpeedControl,
  });

  AudioLoadConfigurationMessage _toMessage() => AudioLoadConfigurationMessage(
        darwinLoadControl: darwinLoadControl?._toMessage(),
        androidLoadControl: androidLoadControl?._toMessage(),
        androidLivePlaybackSpeedControl:
            androidLivePlaybackSpeedControl?._toMessage(),
      );
}

/// Buffering and loading options for iOS/macOS.
class DarwinLoadControl {
  /// (iOS/macOS) Whether the player will wait for sufficient data to be
  /// buffered before starting playback to avoid the likelihood of stalling.
  final bool automaticallyWaitsToMinimizeStalling;

  /// (iOS/macOS) The duration of audio that should be buffered ahead of the
  /// current position. If not set or `null`, the system will try to set an
  /// appropriate buffer duration.
  final Duration? preferredForwardBufferDuration;

  /// (iOS/macOS) Whether the player can continue downloading while paused to
  /// keep the state up to date with the live stream.
  final bool canUseNetworkResourcesForLiveStreamingWhilePaused;

  /// (iOS/macOS) If specified, limits the download bandwidth in bits per
  /// second.
  final double? preferredPeakBitRate;

  DarwinLoadControl({
    this.automaticallyWaitsToMinimizeStalling = true,
    this.preferredForwardBufferDuration,
    this.canUseNetworkResourcesForLiveStreamingWhilePaused = false,
    this.preferredPeakBitRate,
  });

  DarwinLoadControlMessage _toMessage() => DarwinLoadControlMessage(
        automaticallyWaitsToMinimizeStalling:
            automaticallyWaitsToMinimizeStalling,
        preferredForwardBufferDuration: preferredForwardBufferDuration,
        canUseNetworkResourcesForLiveStreamingWhilePaused:
            canUseNetworkResourcesForLiveStreamingWhilePaused,
        preferredPeakBitRate: preferredPeakBitRate,
      );
}

/// Buffering and loading options for Android.
class AndroidLoadControl {
  /// (Android) The minimum duration of audio that should be buffered ahead of
  /// the current position.
  final Duration minBufferDuration;

  /// (Android) The maximum duration of audio that should be buffered ahead of
  /// the current position.
  final Duration maxBufferDuration;

  /// (Android) The duration of audio that must be buffered before starting
  /// playback after a user action.
  final Duration bufferForPlaybackDuration;

  /// (Android) The duration of audio that must be buffered before starting
  /// playback after a buffer depletion.
  final Duration bufferForPlaybackAfterRebufferDuration;

  /// (Android) The target buffer size in bytes.
  final int? targetBufferBytes;

  /// (Android) Whether to prioritize buffer time constraints over buffer size
  /// constraints.
  final bool prioritizeTimeOverSizeThresholds;

  /// (Android) The back buffer duration.
  final Duration backBufferDuration;

  AndroidLoadControl({
    this.minBufferDuration = const Duration(seconds: 50),
    this.maxBufferDuration = const Duration(seconds: 50),
    this.bufferForPlaybackDuration = const Duration(milliseconds: 2500),
    this.bufferForPlaybackAfterRebufferDuration = const Duration(seconds: 5),
    this.targetBufferBytes,
    this.prioritizeTimeOverSizeThresholds = false,
    this.backBufferDuration = Duration.zero,
  });

  AndroidLoadControlMessage _toMessage() => AndroidLoadControlMessage(
        minBufferDuration: minBufferDuration,
        maxBufferDuration: maxBufferDuration,
        bufferForPlaybackDuration: bufferForPlaybackDuration,
        bufferForPlaybackAfterRebufferDuration:
            bufferForPlaybackAfterRebufferDuration,
        targetBufferBytes: targetBufferBytes,
        prioritizeTimeOverSizeThresholds: prioritizeTimeOverSizeThresholds,
        backBufferDuration: backBufferDuration,
      );
}

/// Speed control for live streams on Android.
class AndroidLivePlaybackSpeedControl {
  /// (Android) The minimum playback speed to use when adjusting playback speed
  /// to approach the target live offset, if none is defined by the media.
  final double fallbackMinPlaybackSpeed;

  /// (Android) The maximum playback speed to use when adjusting playback speed
  /// to approach the target live offset, if none is defined by the media.
  final double fallbackMaxPlaybackSpeed;

  /// (Android) The minimum interval between playback speed changes on a live
  /// stream.
  final Duration minUpdateInterval;

  /// (Android) The proportional control factor used to adjust playback speed on
  /// a live stream. The adjusted speed is calculated as: `1.0 +
  /// proportionalControlFactor * (currentLiveOffsetSec - targetLiveOffsetSec)`.
  final double proportionalControlFactor;

  /// (Android) The maximum difference between the current live offset and the
  /// target live offset within which the speed 1.0 is used.
  final Duration maxLiveOffsetErrorForUnitSpeed;

  /// (Android) The increment applied to the target live offset whenever the
  /// player rebuffers.
  final Duration targetLiveOffsetIncrementOnRebuffer;

  /// (Android) The factor for smoothing the minimum possible live offset
  /// achievable during playback.
  final double minPossibleLiveOffsetSmoothingFactor;

  AndroidLivePlaybackSpeedControl({
    this.fallbackMinPlaybackSpeed = 0.97,
    this.fallbackMaxPlaybackSpeed = 1.03,
    this.minUpdateInterval = const Duration(seconds: 1),
    this.proportionalControlFactor = 1.0,
    this.maxLiveOffsetErrorForUnitSpeed = const Duration(milliseconds: 20),
    this.targetLiveOffsetIncrementOnRebuffer =
        const Duration(milliseconds: 500),
    this.minPossibleLiveOffsetSmoothingFactor = 0.999,
  });

  AndroidLivePlaybackSpeedControlMessage _toMessage() =>
      AndroidLivePlaybackSpeedControlMessage(
        fallbackMinPlaybackSpeed: fallbackMinPlaybackSpeed,
        fallbackMaxPlaybackSpeed: fallbackMaxPlaybackSpeed,
        minUpdateInterval: minUpdateInterval,
        proportionalControlFactor: proportionalControlFactor,
        maxLiveOffsetErrorForUnitSpeed: maxLiveOffsetErrorForUnitSpeed,
        targetLiveOffsetIncrementOnRebuffer:
            targetLiveOffsetIncrementOnRebuffer,
        minPossibleLiveOffsetSmoothingFactor:
            minPossibleLiveOffsetSmoothingFactor,
      );
}

/// A local proxy HTTP server for making remote GET requests with headers.
class _ProxyHttpServer {
  late HttpServer _server;
  bool _running = false;

  /// Maps request keys to [_ProxyHandler]s.
  final Map<String, _ProxyHandler> _handlerMap = {};

  /// The port this server is bound to on localhost. This is set only after
  /// [start] has completed.
  int get port => _server.port;

  /// Register a [UriAudioSource] to be served through this proxy. This may be
  /// called only after [start] has completed.
  Uri addUriAudioSource(UriAudioSource source) {
    final uri = source.uri;
    final headers = <String, String>{};
    if (source.headers != null) {
      headers.addAll(source.headers!.cast<String, String>());
    }
    final path = _requestKey(uri);
    _handlerMap[path] = _proxyHandlerForUri(
      uri,
      headers: headers,
      userAgent: source._player?._userAgent,
    );
    return uri.replace(
      scheme: 'http',
      host: InternetAddress.loopbackIPv4.address,
      port: port,
    );
  }

  /// Register a [StreamAudioSource] to be served through this proxy. This may
  /// be called only after [start] has completed.
  Uri addStreamAudioSource(StreamAudioSource source) {
    final uri = _sourceUri(source);
    final path = _requestKey(uri);
    _handlerMap[path] = _proxyHandlerForSource(source);
    return uri;
  }

  Uri _sourceUri(StreamAudioSource source) => Uri.http(
      '${InternetAddress.loopbackIPv4.address}:$port', '/id/${source._id}');

  /// A unique key for each request that can be processed by this proxy,
  /// made up of the URL path and query string. It is not possible to
  /// simultaneously track requests that have the same URL path and query
  /// but differ in other respects such as the port or headers.
  String _requestKey(Uri uri) => '${uri.path}?${uri.query}';

  /// Start the server if it is not already running.
  Future ensureRunning() async {
    if (_running) return;
    return await start();
  }

  /// Starts the server.
  Future start() async {
    _running = true;
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((request) async {
      if (request.method == 'GET') {
        final uriPath = _requestKey(request.uri);
        final handler = _handlerMap[uriPath]!;
        handler(this, request);
      }
    }, onDone: () {
      _running = false;
    }, onError: (Object e, StackTrace st) {
      _running = false;
    });
  }

  /// Stops the server
  Future stop() async {
    if (!_running) return;
    _running = false;
    return await _server.close();
  }
}

/// Encapsulates the start and end of an HTTP range request.
class _HttpRangeRequest {
  /// The starting byte position of the range request.
  final int start;

  /// The last byte position of the range request, or `null` if requesting
  /// until the end of the media.
  final int? end;

  /// The end byte position (exclusive), defaulting to `null`.
  int? get endEx => end == null ? null : end! + 1;

  _HttpRangeRequest(this.start, this.end);

  /// Format a range header for this request.
  String get header =>
      'bytes=$start-${end != null ? (end! - 1).toString() : ""}';

  /// Creates an [_HttpRangeRequest] from [header].
  static _HttpRangeRequest? parse(List<String>? header) {
    if (header == null || header.isEmpty) return null;
    final match = RegExp(r'^bytes=(\d+)(-(\d+)?)?').firstMatch(header.first);
    if (match == null) return null;
    int? intGroup(int i) => match[i] != null ? int.parse(match[i]!) : null;
    return _HttpRangeRequest(intGroup(1)!, intGroup(3));
  }
}

/// Encapsulates the range information in an HTTP range response.
class _HttpRangeResponse {
  /// The starting byte position of the range.
  final int start;

  /// The last byte position of the range.
  final int end;

  /// The total number of bytes in the entire media.
  final int? fullLength;

  _HttpRangeResponse(this.start, this.end, this.fullLength);

  /// The end byte position (exclusive).
  int? get endEx => end + 1;

  /// The number of bytes requested.
  int? get length => endEx == null ? null : endEx! - start;

  /// The content-range header value to use in HTTP responses.
  String get header => 'bytes $start-$end/${fullLength?.toString() ?? "*"}';
}

/// Specifies a source of audio to be played. Audio sources are composable
/// using the subclasses of this class. The same [AudioSource] instance should
/// not be used simultaneously by more than one [AudioPlayer].
abstract class AudioSource {
  final String _id;
  AudioPlayer? _player;

  /// Creates an [AudioSource] from a [Uri] with optional headers by
  /// attempting to guess the type of stream. On iOS, this uses Apple's SDK to
  /// automatically detect the stream type. On Android, the type of stream will
  /// be guessed from the extension.
  ///
  /// If you are loading DASH or HLS streams that do not have standard "mpd" or
  /// "m3u8" extensions in their URIs, this method will fail to detect the
  /// stream type on Android. If you know in advance what type of audio stream
  /// it is, you should instantiate [DashAudioSource] or [HlsAudioSource]
  /// directly.
  ///
  /// If headers are set, just_audio will create a cleartext local HTTP proxy on
  /// your device to forward HTTP requests with headers included.
  static UriAudioSource uri(Uri uri,
      {Map<String, String>? headers, dynamic tag}) {
    bool hasExtension(Uri uri, String extension) =>
        uri.path.toLowerCase().endsWith('.$extension') ||
        uri.fragment.toLowerCase().endsWith('.$extension');
    if (hasExtension(uri, 'mpd')) {
      return DashAudioSource(uri, headers: headers, tag: tag);
    } else if (hasExtension(uri, 'm3u8')) {
      return HlsAudioSource(uri, headers: headers, tag: tag);
    } else {
      return ProgressiveAudioSource(uri, headers: headers, tag: tag);
    }
  }

  AudioSource() : _id = _uuid.v4();

  @mustCallSuper
  Future<void> _setup(AudioPlayer player) async {
    _player = player;
    player._registerAudioSource(this);
  }

  void _shuffle({int? initialIndex});

  @mustCallSuper
  void _dispose() {
    // Without this we might make _player "late".
    _player = null;
  }

  AudioSourceMessage _toMessage();

  List<IndexedAudioSource> get sequence;

  List<int> get shuffleIndices;

  @override
  int get hashCode => _id.hashCode;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is AudioSource &&
      other._id == _id;
}

/// An [AudioSource] that can appear in a sequence.
abstract class IndexedAudioSource extends AudioSource {
  final dynamic tag;
  Duration? duration;

  IndexedAudioSource({this.tag, this.duration});

  @override
  void _shuffle({int? initialIndex}) {}

  @override
  List<IndexedAudioSource> get sequence => [this];

  @override
  List<int> get shuffleIndices => [0];
}

/// An abstract class representing audio sources that are loaded from a URI.
abstract class UriAudioSource extends IndexedAudioSource {
  final Uri uri;
  final Map<String, String>? headers;
  Uri? _overrideUri;

  UriAudioSource(this.uri, {this.headers, dynamic tag, Duration? duration})
      : super(tag: tag, duration: duration);

  /// If [uri] points to an asset, this gives us [_overrideUri] which is the URI
  /// of the copied asset on the filesystem, otherwise it gives us the original
  /// [uri].
  Uri get _effectiveUri => _overrideUri ?? uri;

  @override
  Future<void> _setup(AudioPlayer player) async {
    await super._setup(player);
    if (uri.scheme == 'asset') {
      _overrideUri = await _loadAsset(uri.pathSegments.join('/'));
    } else if (uri.scheme != 'file' &&
        !kIsWeb &&
        (headers != null || player._userAgent != null)) {
      await player._proxy.ensureRunning();
      _overrideUri = player._proxy.addUriAudioSource(this);
    }
  }

  Future<Uri> _loadAsset(String assetPath) async {
    if (kIsWeb) {
      // Mapping from extensions to content types for the web player. If an
      // extension is missing, please submit a pull request.
      const mimeTypes = {
        '.aac': 'audio/aac',
        '.mp3': 'audio/mpeg',
        '.ogg': 'audio/ogg',
        '.opus': 'audio/opus',
        '.wav': 'audio/wav',
        '.weba': 'audio/webm',
        '.mp4': 'audio/mp4',
        '.m4a': 'audio/mp4',
        '.aif': 'audio/x-aiff',
        '.aifc': 'audio/x-aiff',
        '.aiff': 'audio/x-aiff',
        '.m3u': 'audio/x-mpegurl',
      };
      // Default to 'audio/mpeg'
      final mimeType =
          mimeTypes[p.extension(assetPath).toLowerCase()] ?? 'audio/mpeg';
      return _encodeDataUrl(
          base64
              .encode((await rootBundle.load(assetPath)).buffer.asUint8List()),
          mimeType);
    } else {
      // For non-web platforms, extract the asset into a cache file and pass
      // that to the player.
      final file = await _getCacheFile(assetPath);
      // Not technically inter-isolate-safe, although low risk. Could consider
      // locking the file or creating a separate lock file.
      if (!file.existsSync()) {
        file.createSync(recursive: true);
        await file.writeAsBytes(
            (await rootBundle.load(assetPath)).buffer.asUint8List());
      }
      return Uri.file(file.path);
    }
  }

  /// Get file for caching asset media with proper extension
  Future<File> _getCacheFile(final String assetPath) async => File(p.joinAll([
        (await _getCacheDir()).path,
        'assets',
        ...Uri.parse(assetPath).pathSegments,
      ]));
}

/// An [AudioSource] representing a regular media file such as an MP3 or M4A
/// file. The following URI schemes are supported:
///
/// * file: loads from a local file (provided you give your app permission to
/// access that file).
/// * asset: loads from a Flutter asset (not supported on Web).
/// * http(s): loads from an HTTP(S) resource.
///
/// On platforms except for the web, the supplied [headers] will be passed with
/// the HTTP(S) request.
///
/// If headers are set, just_audio will create a cleartext local HTTP proxy on
/// your device to forward HTTP requests with headers included.
class ProgressiveAudioSource extends UriAudioSource {
  ProgressiveAudioSource(Uri uri,
      {Map<String, String>? headers, dynamic tag, Duration? duration})
      : super(uri, headers: headers, tag: tag, duration: duration);

  @override
  AudioSourceMessage _toMessage() => ProgressiveAudioSourceMessage(
      id: _id, uri: _effectiveUri.toString(), headers: headers, tag: tag);
}

/// An [AudioSource] representing a DASH stream. The following URI schemes are
/// supported:
///
/// * file: loads from a local file (provided you give your app permission to
/// access that file).
/// * asset: loads from a Flutter asset (not supported on Web).
/// * http(s): loads from an HTTP(S) resource.
///
/// On platforms except for the web, the supplied [headers] will be passed with
/// the HTTP(S) request. Currently headers are not recursively applied to items
/// the HTTP(S) request. Currently headers are not applied recursively.
///
/// If headers are set, just_audio will create a cleartext local HTTP proxy on
/// your device to forward HTTP requests with headers included.
class DashAudioSource extends UriAudioSource {
  DashAudioSource(Uri uri,
      {Map<String, String>? headers, dynamic tag, Duration? duration})
      : super(uri, headers: headers, tag: tag, duration: duration);

  @override
  AudioSourceMessage _toMessage() => DashAudioSourceMessage(
      id: _id, uri: _effectiveUri.toString(), headers: headers, tag: tag);
}

/// An [AudioSource] representing an HLS stream. The following URI schemes are
/// supported:
///
/// * file: loads from a local file (provided you give your app permission to
/// access that file).
/// * asset: loads from a Flutter asset (not supported on Web).
/// * http(s): loads from an HTTP(S) resource.
///
/// On platforms except for the web, the supplied [headers] will be passed with
/// the HTTP(S) request. Currently headers are not applied recursively.
///
/// If headers are set, just_audio will create a cleartext local HTTP proxy on
/// your device to forward HTTP requests with headers included.
class HlsAudioSource extends UriAudioSource {
  HlsAudioSource(Uri uri,
      {Map<String, String>? headers, dynamic tag, Duration? duration})
      : super(uri, headers: headers, tag: tag, duration: duration);

  @override
  AudioSourceMessage _toMessage() => HlsAudioSourceMessage(
      id: _id, uri: _effectiveUri.toString(), headers: headers, tag: tag);
}

/// An [AudioSource] for a period of silence.
///
/// NOTE: This is currently supported on Android only.
class SilenceAudioSource extends IndexedAudioSource {
  @override
  Duration get duration => super.duration!;

  @override
  set duration(covariant Duration duration) => super.duration = duration;

  SilenceAudioSource({
    dynamic tag,
    required Duration duration,
  }) : super(tag: tag, duration: duration);

  @override
  AudioSourceMessage _toMessage() =>
      SilenceAudioSourceMessage(id: _id, duration: duration);
}

/// An [AudioSource] representing a concatenation of multiple audio sources to
/// be played in succession. This can be used to create playlists. Playback
/// between items will be gapless on Android, iOS and macOS, while there will
/// be a slight gap on Web.
///
/// (Untested) Audio sources can be dynamically added, removed and reordered
/// while the audio is playing.
class ConcatenatingAudioSource extends AudioSource {
  final List<AudioSource> children;
  final bool useLazyPreparation;
  final ShuffleOrder _shuffleOrder;

  /// Creates a [ConcatenatingAudioSorce] with the specified [children]. If
  /// [useLazyPreparation] is `true`, children will be loaded/buffered as late
  /// as possible before needed for playback (currently supported on Android
  /// only). When [AudioPlayer.shuffleModeEnabled] is `true`, [shuffleOrder]
  /// will be used to determine the playback order (defaulting to
  /// [DefaultShuffleOrder]).
  ConcatenatingAudioSource({
    required this.children,
    this.useLazyPreparation = true,
    ShuffleOrder? shuffleOrder,
  }) : _shuffleOrder = shuffleOrder ?? DefaultShuffleOrder()
          ..insert(0, children.length);

  @override
  Future<void> _setup(AudioPlayer player) async {
    await super._setup(player);
    for (var source in children) {
      await source._setup(player);
    }
  }

  @override
  void _shuffle({int? initialIndex}) {
    int? localInitialIndex;
    // si = index in [sequence]
    // ci = index in [children] array.
    for (var ci = 0, si = 0; ci < children.length; ci++) {
      final child = children[ci];
      final childLength = child.sequence.length;
      final initialIndexWithinThisChild = initialIndex != null &&
          initialIndex >= si &&
          initialIndex < si + childLength;
      if (initialIndexWithinThisChild) {
        localInitialIndex = ci;
      }
      final childInitialIndex =
          initialIndexWithinThisChild ? (initialIndex! - si) : null;
      child._shuffle(initialIndex: childInitialIndex);
      si += childLength;
    }
    _shuffleOrder.shuffle(initialIndex: localInitialIndex);
  }

  /// (Untested) Appends an [AudioSource].
  Future<void> add(AudioSource audioSource) async {
    final index = children.length;
    children.add(audioSource);
    _shuffleOrder.insert(index, 1);
    if (_player != null) {
      _player!._broadcastSequence();
      await audioSource._setup(_player!);
      await (await _player!._platform).concatenatingInsertAll(
          ConcatenatingInsertAllRequest(
              id: _id,
              index: index,
              children: [audioSource._toMessage()],
              shuffleOrder: List.of(_shuffleOrder.indices)));
    }
  }

  /// (Untested) Inserts an [AudioSource] at [index].
  Future<void> insert(int index, AudioSource audioSource) async {
    children.insert(index, audioSource);
    _shuffleOrder.insert(index, 1);
    if (_player != null) {
      _player!._broadcastSequence();
      await audioSource._setup(_player!);
      await (await _player!._platform).concatenatingInsertAll(
          ConcatenatingInsertAllRequest(
              id: _id,
              index: index,
              children: [audioSource._toMessage()],
              shuffleOrder: List.of(_shuffleOrder.indices)));
    }
  }

  /// (Untested) Appends multiple [AudioSource]s.
  Future<void> addAll(List<AudioSource> children) async {
    final index = this.children.length;
    this.children.addAll(children);
    _shuffleOrder.insert(index, children.length);
    if (_player != null) {
      _player!._broadcastSequence();
      for (var child in children) {
        await child._setup(_player!);
      }
      await (await _player!._platform).concatenatingInsertAll(
          ConcatenatingInsertAllRequest(
              id: _id,
              index: index,
              children: children.map((child) => child._toMessage()).toList(),
              shuffleOrder: List.of(_shuffleOrder.indices)));
    }
  }

  /// (Untested) Insert multiple [AudioSource]s at [index].
  Future<void> insertAll(int index, List<AudioSource> children) async {
    this.children.insertAll(index, children);
    _shuffleOrder.insert(index, children.length);
    if (_player != null) {
      _player!._broadcastSequence();
      for (var child in children) {
        await child._setup(_player!);
      }
      await (await _player!._platform).concatenatingInsertAll(
          ConcatenatingInsertAllRequest(
              id: _id,
              index: index,
              children: children.map((child) => child._toMessage()).toList(),
              shuffleOrder: List.of(_shuffleOrder.indices)));
    }
  }

  /// (Untested) Dynamically remove an [AudioSource] at [index] after this
  /// [ConcatenatingAudioSource] has already been loaded.
  Future<void> removeAt(int index) async {
    children.removeAt(index);
    _shuffleOrder.removeRange(index, index + 1);
    if (_player != null) {
      _player!._broadcastSequence();
      await (await _player!._platform).concatenatingRemoveRange(
          ConcatenatingRemoveRangeRequest(
              id: _id,
              startIndex: index,
              endIndex: index + 1,
              shuffleOrder: List.of(_shuffleOrder.indices)));
    }
  }

  /// (Untested) Removes a range of [AudioSource]s from index [start] inclusive
  /// to [end] exclusive.
  Future<void> removeRange(int start, int end) async {
    children.removeRange(start, end);
    _shuffleOrder.removeRange(start, end);
    if (_player != null) {
      _player!._broadcastSequence();
      await (await _player!._platform).concatenatingRemoveRange(
          ConcatenatingRemoveRangeRequest(
              id: _id,
              startIndex: start,
              endIndex: end,
              shuffleOrder: List.of(_shuffleOrder.indices)));
    }
  }

  /// (Untested) Moves an [AudioSource] from [currentIndex] to [newIndex].
  Future<void> move(int currentIndex, int newIndex) async {
    children.insert(newIndex, children.removeAt(currentIndex));
    _shuffleOrder.removeRange(currentIndex, currentIndex + 1);
    _shuffleOrder.insert(newIndex, 1);
    if (_player != null) {
      _player!._broadcastSequence();
      await (await _player!._platform).concatenatingMove(
          ConcatenatingMoveRequest(
              id: _id,
              currentIndex: currentIndex,
              newIndex: newIndex,
              shuffleOrder: List.of(_shuffleOrder.indices)));
    }
  }

  /// (Untested) Removes all [AudioSource]s.
  Future<void> clear() async {
    final end = children.length;
    children.clear();
    _shuffleOrder.clear();
    if (_player != null) {
      _player!._broadcastSequence();
      await (await _player!._platform).concatenatingRemoveRange(
          ConcatenatingRemoveRangeRequest(
              id: _id,
              startIndex: 0,
              endIndex: end,
              shuffleOrder: List.of(_shuffleOrder.indices)));
    }
  }

  /// The number of [AudioSource]s.
  int get length => children.length;

  AudioSource operator [](int index) => children[index];

  @override
  List<IndexedAudioSource> get sequence =>
      children.expand((s) => s.sequence).toList();

  @override
  List<int> get shuffleIndices {
    var offset = 0;
    final childIndicesList = <List<int>>[];
    for (var child in children) {
      final childIndices = child.shuffleIndices.map((i) => i + offset).toList();
      childIndicesList.add(childIndices);
      offset += childIndices.length;
    }
    final indices = <int>[];
    for (var index in _shuffleOrder.indices) {
      indices.addAll(childIndicesList[index]);
    }
    return indices;
  }

  @override
  AudioSourceMessage _toMessage() => ConcatenatingAudioSourceMessage(
      id: _id,
      children: children.map((child) => child._toMessage()).toList(),
      useLazyPreparation: useLazyPreparation,
      shuffleOrder: _shuffleOrder.indices);
}

/// An [AudioSource] that clips the audio of a [UriAudioSource] between a
/// certain start and end time.
class ClippingAudioSource extends IndexedAudioSource {
  final UriAudioSource child;
  final Duration? start;
  final Duration? end;

  /// Creates an audio source that clips [child] to the range [start]..[end],
  /// where [start] and [end] default to the beginning and end of the original
  /// [child] source.
  ClippingAudioSource({
    required this.child,
    this.start,
    this.end,
    dynamic tag,
    Duration? duration,
  }) : super(tag: tag, duration: duration);

  @override
  Future<void> _setup(AudioPlayer player) async {
    await super._setup(player);
    await child._setup(player);
  }

  @override
  AudioSourceMessage _toMessage() => ClippingAudioSourceMessage(
      id: _id,
      child: child._toMessage() as UriAudioSourceMessage,
      start: start,
      end: end,
      tag: tag);
}

// An [AudioSource] that loops a nested [AudioSource] a finite number of times.
// NOTE: this can be inefficient when using a large loop count. If you wish to
// loop an infinite number of times, use [AudioPlayer.setLoopMode].
class LoopingAudioSource extends AudioSource {
  AudioSource child;
  final int count;

  LoopingAudioSource({
    required this.child,
    required this.count,
  }) : super();

  @override
  Future<void> _setup(AudioPlayer player) async {
    await super._setup(player);
    await child._setup(player);
  }

  @override
  void _shuffle({int? initialIndex}) {}

  @override
  List<IndexedAudioSource> get sequence =>
      List.generate(count, (i) => child).expand((s) => s.sequence).toList();

  @override
  List<int> get shuffleIndices => List.generate(count, (i) => i);

  @override
  AudioSourceMessage _toMessage() => LoopingAudioSourceMessage(
      id: _id, child: child._toMessage(), count: count);
}

Uri _encodeDataUrl(String base64Data, String mimeType) =>
    Uri.parse('data:$mimeType;base64,$base64Data');

/// An [AudioSource] that provides audio dynamically. Subclasses must override
/// [request] to provide the encoded audio data. This API is experimental.
@experimental
abstract class StreamAudioSource extends IndexedAudioSource {
  Uri? _uri;
  StreamAudioSource({dynamic tag}) : super(tag: tag);

  @override
  Future<void> _setup(AudioPlayer player) async {
    await super._setup(player);
    if (kIsWeb) {
      final response = await request();
      _uri = _encodeDataUrl(await base64.encoder.bind(response.stream).join(),
          response.contentType);
    } else {
      await player._proxy.ensureRunning();
      _uri = player._proxy.addStreamAudioSource(this);
    }
  }

  /// Used by the player to request a byte range of encoded audio data in small
  /// chunks, from byte position [start] inclusive (or from the beginning of the
  /// audio data if not specified) to [end] exclusive (or the end of the audio
  /// data if not specified). If the returned future completes with an error,
  /// a 500 response will be sent back to the player.
  Future<StreamAudioResponse> request([int? start, int? end]);

  @override
  AudioSourceMessage _toMessage() => ProgressiveAudioSourceMessage(
      id: _id, uri: _uri.toString(), headers: null, tag: tag);
}

/// The response for a [StreamAudioSource]. This API is experimental.
@experimental
class StreamAudioResponse {
  /// Indicates to the client whether or not range requests are supported for
  /// the requested media. If `true`, the client may make further requests
  /// specifying the `start` and possibly also the `end` parameters of the range
  /// request, otherwise these will both be null.
  final bool rangeRequestsSupported;

  /// When responding to a range request, this holds the byte length of the
  /// entire media, otherwise it holds `null`.
  final int? sourceLength;

  /// The number of bytes returned in this response, or `null` if unknown. Note:
  /// this may be different from the length of the entire media for a range
  /// request.
  final int? contentLength;

  /// The starting byte position of the response data if responding to a range
  /// request.
  final int? offset;

  /// The MIME type of the audio.
  final String contentType;

  /// The audio content returned by this response.
  final Stream<List<int>> stream;

  StreamAudioResponse({
    this.rangeRequestsSupported = true,
    required this.sourceLength,
    required this.contentLength,
    required this.offset,
    required this.stream,
    required this.contentType,
  });
}

/// This is an experimental audio source that caches the audio while it is being
/// downloaded and played. It is not supported on platforms that do not provide
/// access to the file system (e.g. web).
@experimental
class LockCachingAudioSource extends StreamAudioSource {
  Future<HttpClientResponse>? _response;
  final Uri uri;
  final Map<String, String>? headers;
  final Future<File> cacheFile;
  int _progress = 0;
  final _requests = <_StreamingByteRangeRequest>[];
  final _downloadProgressSubject = BehaviorSubject<double>();
  bool _downloading = false;

  /// Creates a [LockCachingAudioSource] to that provides [uri] to the player
  /// while simultaneously caching it to [cacheFile]. If no cache file is
  /// supplied, just_audio will allocate a cache file internally.
  ///
  /// If headers are set, just_audio will create a cleartext local HTTP proxy on
  /// your device to forward HTTP requests with headers included.
  LockCachingAudioSource(
    this.uri, {
    this.headers,
    File? cacheFile,
    dynamic tag,
  })  : cacheFile =
            cacheFile != null ? Future.value(cacheFile) : _getCacheFile(uri),
        super(tag: tag) {
    _init();
  }

  Future<void> _init() async {
    final cacheFile = await this.cacheFile;
    _downloadProgressSubject.add((await cacheFile.exists()) ? 1.0 : 0.0);
  }

  /// Returns a [UriAudioSource] resolving directly to the cache file if it
  /// exists, otherwise returns `this`. This can be
  Future<IndexedAudioSource> resolve() async {
    final file = await cacheFile;
    return await file.exists() ? AudioSource.uri(Uri.file(file.path)) : this;
  }

  /// Emits the current download progress as a double value from 0.0 (nothing
  /// downloaded) to 1.0 (download complete).
  Stream<double> get downloadProgressStream => _downloadProgressSubject.stream;

  /// Removes the underlying cache files. It is an error to clear the cache
  /// while a download is in progress.
  Future<void> clearCache() async {
    if (_downloading) {
      throw Exception("Cannot clear cache while download is in progress");
    }
    _response = null;
    final cacheFile = await this.cacheFile;
    if (await cacheFile.exists()) {
      await cacheFile.delete();
    }
    final mimeFile = await _mimeFile;
    if (await mimeFile.exists()) {
      await mimeFile.delete();
    }
    _progress = 0;
    _downloadProgressSubject.add(0.0);
  }

  /// Get file for caching [uri] with proper extension
  static Future<File> _getCacheFile(final Uri uri) async => File(p.joinAll([
        (await _getCacheDir()).path,
        'remote',
        sha256.convert(utf8.encode(uri.toString())).toString() +
            p.extension(uri.path),
      ]));

  Future<File> get _partialCacheFile async =>
      File('${(await cacheFile).path}.part');

  /// We use this to record the original content type of the downloaded audio.
  /// NOTE: We could instead rely on the cache file extension, but the original
  /// URL might not provide a correct extension. As a fallback, we could map the
  /// MIME type to an extension but we will need a complete dictionary.
  Future<File> get _mimeFile async => File('${(await cacheFile).path}.mime');

  Future<String> _readCachedMimeType() async {
    final file = await _mimeFile;
    if (file.existsSync()) {
      return (await _mimeFile).readAsString();
    } else {
      return 'audio/mpeg';
    }
  }

  /// Start downloading the whole audio file to the cache and fulfill byte-range
  /// requests during the download. There are 3 scenarios:
  ///
  /// 1. If the byte range request falls entirely within the cache region, it is
  /// fulfilled from the cache.
  /// 2. If the byte range request overlaps the cached region, the first part is
  /// fulfilled from the cache, and the region beyond the cache is fulfilled
  /// from a memory buffer of the downloaded data.
  /// 3. If the byte range request is entirely outside the cached region, a
  /// separate HTTP request is made to fulfill it while the download of the
  /// entire file continues in parallel.
  Future<HttpClientResponse> _fetch() async {
    _downloading = true;
    final cacheFile = await this.cacheFile;
    final partialCacheFile = await _partialCacheFile;

    File getEffectiveCacheFile() =>
        partialCacheFile.existsSync() ? partialCacheFile : cacheFile;

    final httpClient = _createHttpClient(userAgent: _player?._userAgent);
    final httpRequest = await _getUrl(httpClient, uri, headers: headers);
    final response = await httpRequest.close();
    if (response.statusCode != 200) {
      httpClient.close();
      throw Exception('HTTP Status Error: ${response.statusCode}');
    }
    (await _partialCacheFile).createSync(recursive: true);
    // TODO: Should close sink after done, but it throws an error.
    // ignore: close_sinks
    final sink = (await _partialCacheFile).openWrite();
    final sourceLength =
        response.contentLength == -1 ? null : response.contentLength;
    final mimeType = response.headers.contentType.toString();
    final acceptRanges = response.headers.value(HttpHeaders.acceptRangesHeader);
    final originSupportsRangeRequests =
        acceptRanges != null && acceptRanges != 'none';
    final mimeFile = await _mimeFile;
    await mimeFile.writeAsString(mimeType);
    final inProgressResponses = <_InProgressCacheResponse>[];
    late StreamSubscription subscription;
    var percentProgress = 0;
    void updateProgress(int newPercentProgress) {
      if (newPercentProgress != percentProgress) {
        percentProgress = newPercentProgress;
        _downloadProgressSubject.add(percentProgress / 100);
      }
    }

    _progress = 0;
    subscription = response.listen((data) async {
      _progress += data.length;
      final newPercentProgress = (sourceLength == null)
          ? 0
          : (sourceLength == 0)
              ? 100
              : (100 * _progress ~/ sourceLength);
      updateProgress(newPercentProgress);
      sink.add(data);
      final readyRequests = _requests
          .where((request) =>
              !originSupportsRangeRequests ||
              request.start == null ||
              (request.start!) < _progress)
          .toList();
      final notReadyRequests = _requests
          .where((request) =>
              originSupportsRangeRequests &&
              request.start != null &&
              (request.start!) >= _progress)
          .toList();
      // Add this live data to any responses in progress.
      for (var cacheResponse in inProgressResponses) {
        final end = cacheResponse.end;
        if (end != null && _progress >= end) {
          // We've received enough data to fulfill the byte range request.
          final subEnd =
              min(data.length, max(0, data.length - (_progress - end)));
          cacheResponse.controller.add(data.sublist(0, subEnd));
          cacheResponse.controller.close();
        } else {
          cacheResponse.controller.add(data);
        }
      }
      inProgressResponses.removeWhere((element) => element.controller.isClosed);
      if (_requests.isEmpty) return;
      // Prevent further data coming from the HTTP source until we have set up
      // an entry in inProgressResponses to continue receiving live HTTP data.
      subscription.pause();
      await sink.flush();
      // Process any requests that start within the cache.
      for (var request in readyRequests) {
        _requests.remove(request);
        int? start, end;
        if (originSupportsRangeRequests) {
          start = request.start;
          end = request.end;
        } else {
          // If the origin doesn't support range requests, the proxy should also
          // ignore range requests and instead serve a complete 200 response
          // which the client (AV or exo player) should know how to deal with.
        }
        final effectiveStart = start ?? 0;
        final effectiveEnd = end ?? sourceLength;
        Stream<List<int>> responseStream;
        if (effectiveEnd != null && effectiveEnd <= _progress) {
          responseStream =
              getEffectiveCacheFile().openRead(effectiveStart, effectiveEnd);
        } else {
          final cacheResponse = _InProgressCacheResponse(end: effectiveEnd);
          inProgressResponses.add(cacheResponse);
          responseStream = Rx.concatEager([
            // NOTE: The cache file part of the stream must not overlap with
            // the live part. "_progress" should
            // to the cache file at the time
            getEffectiveCacheFile().openRead(effectiveStart, _progress),
            cacheResponse.controller.stream,
          ]);
        }
        request.complete(StreamAudioResponse(
          rangeRequestsSupported: originSupportsRangeRequests,
          sourceLength: start != null ? sourceLength : null,
          contentLength:
              effectiveEnd != null ? effectiveEnd - effectiveStart : null,
          offset: start,
          contentType: mimeType,
          stream: responseStream.asBroadcastStream(),
        ));
      }
      subscription.resume();
      // Process any requests that start beyond the cache.
      for (var request in notReadyRequests) {
        _requests.remove(request);
        final start = request.start!;
        final end = request.end ?? sourceLength;
        final httpClient = _createHttpClient(userAgent: _player?._userAgent);

        final rangeRequest = _HttpRangeRequest(start, end);
        _getUrl(httpClient, uri, headers: {
          if (headers != null) ...headers!,
          HttpHeaders.rangeHeader: rangeRequest.header,
        }).then((httpRequest) async {
          final response = await httpRequest.close();
          if (response.statusCode != 206) {
            httpClient.close();
            throw Exception('HTTP Status Error: ${response.statusCode}');
          }
          request.complete(StreamAudioResponse(
            rangeRequestsSupported: originSupportsRangeRequests,
            sourceLength: sourceLength,
            contentLength: end != null ? end - start : null,
            offset: start,
            contentType: mimeType,
            stream: response.asBroadcastStream(),
          ));
        }, onError: (dynamic e, StackTrace? stackTrace) {
          request.fail(e, stackTrace);
        }).onError((Object e, StackTrace st) {
          request.fail(e, st);
        });
      }
    }, onDone: () async {
      if (sourceLength == null) {
        updateProgress(100);
      }
      for (var cacheResponse in inProgressResponses) {
        if (!cacheResponse.controller.isClosed) {
          cacheResponse.controller.close();
        }
      }
      (await _partialCacheFile).renameSync(cacheFile.path);
      await subscription.cancel();
      httpClient.close();
      _downloading = false;
    }, onError: (Object e, StackTrace stackTrace) async {
      (await _partialCacheFile).deleteSync();
      httpClient.close();
      // Fail all pending requests
      for (final req in _requests) {
        req.fail(e, stackTrace);
      }
      _requests.clear();
      // Close all in progress requests
      for (final res in inProgressResponses) {
        res.controller.addError(e, stackTrace);
        res.controller.close();
      }
      _downloading = false;
    }, cancelOnError: true);
    return response;
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final cacheFile = await this.cacheFile;
    if (cacheFile.existsSync()) {
      final sourceLength = cacheFile.lengthSync();
      return StreamAudioResponse(
        rangeRequestsSupported: true,
        sourceLength: start != null ? sourceLength : null,
        contentLength: (end ?? sourceLength) - (start ?? 0),
        offset: start,
        contentType: await _readCachedMimeType(),
        stream: cacheFile.openRead(start, end).asBroadcastStream(),
      );
    }
    final byteRangeRequest = _StreamingByteRangeRequest(start, end);
    _requests.add(byteRangeRequest);
    _response ??=
        _fetch().catchError((dynamic error, StackTrace? stackTrace) async {
      // So that we can restart later
      _response = null;
      // Cancel any pending request
      for (final req in _requests) {
        req.fail(error, stackTrace);
      }
      return Future<HttpClientResponse>.error(error as Object, stackTrace);
    });
    return byteRangeRequest.future.then((response) {
      response.stream.listen((event) {}, onError: (Object e, StackTrace st) {
        // So that we can restart later
        _response = null;
        // Cancel any pending request
        for (final req in _requests) {
          req.fail(e, st);
        }
      });
      return response;
    });
  }
}

/// When a byte range request on a [LockCachingAudioSource] overlaps partially
/// with the cache file and partially with the live HTTP stream, the consumer
/// needs to first consume the cached part before the live part. This class
/// provides a place to buffer the live part until the consumer reaches it, and
/// also keeps track of the [end] of the byte range so that the producer knows
/// when to stop adding data.
class _InProgressCacheResponse {
  // NOTE: This isn't necessarily memory efficient. Since the entire audio file
  // will likely be downloaded at a faster rate than the rate at which the
  // player is consuming audio data, it is also likely that this buffered data
  // will never be used.
  // TODO: Improve this code.
  // ignore: close_sinks
  final controller = ReplaySubject<List<int>>();
  final int? end;
  _InProgressCacheResponse({
    required this.end,
  });
}

/// Request parameters for a [StreamAudioSource].
class _StreamingByteRangeRequest {
  /// The start of the range request.
  final int? start;

  /// The end of the range request.
  final int? end;

  /// Completes when the response is available.
  final _completer = Completer<StreamAudioResponse>();

  _StreamingByteRangeRequest(this.start, this.end);

  /// The response for this request.
  Future<StreamAudioResponse> get future => _completer.future;

  /// Completes this request with the given [response].
  void complete(StreamAudioResponse response) {
    if (_completer.isCompleted) {
      return;
    }
    _completer.complete(response);
  }

  /// Fails this request with the given [error] and [stackTrace].
  void fail(dynamic error, [StackTrace? stackTrace]) {
    if (_completer.isCompleted) {
      return;
    }
    _completer.completeError(error as Object, stackTrace);
  }
}

/// The type of functions that can handle HTTP requests sent to the proxy.
typedef _ProxyHandler = void Function(
    _ProxyHttpServer server, HttpRequest request);

/// A proxy handler for serving audio from a [StreamAudioSource].
_ProxyHandler _proxyHandlerForSource(StreamAudioSource source) {
  Future<void> handler(_ProxyHttpServer server, HttpRequest request) async {
    final rangeRequest =
        _HttpRangeRequest.parse(request.headers[HttpHeaders.rangeHeader]);

    request.response.headers.clear();

    StreamAudioResponse sourceResponse;
    Stream<List<int>> stream;
    try {
      sourceResponse =
          await source.request(rangeRequest?.start, rangeRequest?.endEx);
      stream = sourceResponse.stream;
    } catch (e, st) {
      // ignore: avoid_print
      print("Proxy request failed: $e\n$st");

      request.response.headers.clear();
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
      return;
    }

    request.response.headers
        .set(HttpHeaders.contentTypeHeader, sourceResponse.contentType);

    if (sourceResponse.rangeRequestsSupported) {
      request.response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
    }

    if (rangeRequest != null && sourceResponse.offset != null) {
      final range = _HttpRangeResponse(
          sourceResponse.offset!,
          sourceResponse.offset! + sourceResponse.contentLength! - 1,
          sourceResponse.sourceLength);
      request.response.contentLength = range.length ?? -1;
      request.response.headers
          .set(HttpHeaders.contentRangeHeader, range.header);
      request.response.statusCode = 206;
    } else {
      request.response.contentLength = sourceResponse.contentLength ?? -1;
      request.response.statusCode = 200;
    }

    final completer = Completer<void>();
    final subscription = stream.listen((event) {
      request.response.add(event);
    }, onError: (Object e, StackTrace st) {
      source._player?._playbackEventSubject.addError(e, st);
    }, onDone: () {
      completer.complete();
    });

    request.response.done.then((dynamic value) {
      subscription.cancel();
    });

    await completer.future;

    await request.response.close();
  }

  return handler;
}

/// A proxy handler for serving audio from a URI with optional headers.
_ProxyHandler _proxyHandlerForUri(
  Uri uri, {
  Map<String, String>? headers,
  String? userAgent,
}) {
  // Keep redirected [Uri] to speed-up requests
  Uri? redirectedUri;
  Future<void> handler(_ProxyHttpServer server, HttpRequest request) async {
    final client = _createHttpClient(userAgent: userAgent);
    // Try to make normal request
    String? host;
    try {
      final requestHeaders = <String, String>{if (headers != null) ...headers};
      request.headers
          .forEach((name, value) => requestHeaders[name] = value.join(', '));
      final originRequest =
          await _getUrl(client, redirectedUri ?? uri, headers: requestHeaders);
      host = originRequest.headers.value(HttpHeaders.hostHeader);
      final originResponse = await originRequest.close();
      if (originResponse.redirects.isNotEmpty) {
        redirectedUri = originResponse.redirects.last.location;
      }

      request.response.headers.clear();
      originResponse.headers.forEach((name, value) {
        final filteredValue = value
            .map((e) => e.replaceAll(RegExp(r'[^\x09\x20-\x7F]'), '?'))
            .toList();
        request.response.headers.set(name, filteredValue);
      });
      request.response.statusCode = originResponse.statusCode;

      // Send response
      if (headers != null && request.uri.path.toLowerCase().endsWith('.m3u8') ||
          ['application/x-mpegURL', 'application/vnd.apple.mpegurl']
              .contains(request.headers.value(HttpHeaders.contentTypeHeader))) {
        // If this is an m3u8 file with headers, prepare the nested URIs.
        // TODO: Handle other playlist formats similarly?
        final m3u8 = await originResponse.transform(utf8.decoder).join();
        for (var line in const LineSplitter().convert(m3u8)) {
          line = line.replaceAll(RegExp(r'#.*$'), '').trim();
          if (line.isEmpty) continue;
          try {
            final rawNestedUri = Uri.parse(line);
            if (rawNestedUri.hasScheme) {
              // Don't propagate headers
              server.addUriAudioSource(AudioSource.uri(rawNestedUri));
            } else {
              // This is a resource on the same server, so propagate the headers.
              final basePath = rawNestedUri.path.startsWith('/')
                  ? ''
                  : uri.path.replaceAll(RegExp(r'/[^/]*$'), '/');
              final nestedUri =
                  uri.replace(path: '$basePath${rawNestedUri.path}');
              server.addUriAudioSource(
                  AudioSource.uri(nestedUri, headers: headers));
            }
          } catch (e) {
            // ignore malformed lines
          }
        }
        request.response.add(utf8.encode(m3u8));
      } else {
        request.response.bufferOutput = false;
        var done = false;
        request.response.done.then((dynamic _) => done = true);
        await for (var chunk in originResponse) {
          if (done) break;
          request.response.add(chunk);
          await request.response.flush();
        }
      }
      await request.response.flush();
      await request.response.close();
    } on HttpException {
      // We likely are dealing with a streaming protocol
      if (uri.scheme == 'http') {
        // Try parsing HTTP 0.9 response
        //request.response.headers.clear();
        final socket = await Socket.connect(uri.host, uri.port);
        final clientSocket =
            await request.response.detachSocket(writeHeaders: false);
        final done = Completer<dynamic>();
        socket.listen(
          clientSocket.add,
          onDone: () async {
            await clientSocket.flush();
            socket.close();
            clientSocket.close();
            done.complete();
          },
        );
        // Rewrite headers
        final headers = <String, String?>{};
        request.headers.forEach((name, value) {
          if (name.toLowerCase() != HttpHeaders.hostHeader) {
            headers[name] = value.join(",");
          }
        });
        for (var name in headers.keys) {
          headers[name] = headers[name];
        }
        socket.write("GET ${uri.path} HTTP/1.1\n");
        if (host != null) {
          socket.write("Host: $host\n");
        }
        for (var name in headers.keys) {
          socket.write("$name: ${headers[name]}\n");
        }
        socket.write("\n");
        await socket.flush();
        await done.future;
      }
    }
  }

  return handler;
}

Future<Directory> _getCacheDir() async =>
    Directory(p.join((await getTemporaryDirectory()).path, 'just_audio_cache'));

/// Defines the algorithm for shuffling the order of a
/// [ConcatenatingAudioSource]. See [DefaultShuffleOrder] for a default
/// implementation.
abstract class ShuffleOrder {
  /// The shuffled list of indices of [AudioSource]s to play. For example,
  /// [2,0,1] specifies to play the 3rd, then the 1st, then the 2nd item.
  List<int> get indices;

  /// Shuffles the [indices]. If the current item in the player falls within the
  /// [ConcatenatingAudioSource] being shuffled, [initialIndex] will point to
  /// that item. Subclasses may use this information as a hint, for example, to
  /// make [initialIndex] the first item in the shuffle order.
  void shuffle({int? initialIndex});

  /// Inserts [count] new consecutive indices starting from [index] into
  /// [indices], at random positions.
  void insert(int index, int count);

  /// Removes the indices that are `>= start` and `< end`.
  void removeRange(int start, int end);

  /// Removes all indices.
  void clear();
}

/// The default implementation of [ShuffleOrder] which shuffles items with the
/// currently playing item at the head of the order.
class DefaultShuffleOrder extends ShuffleOrder {
  final Random _random;
  @override
  final indices = <int>[];

  DefaultShuffleOrder({Random? random}) : _random = random ?? Random();

  @override
  void shuffle({int? initialIndex}) {
    assert(initialIndex == null || indices.contains(initialIndex));
    if (indices.length <= 1) return;
    indices.shuffle(_random);
    if (initialIndex == null) return;

    const initialPos = 0;
    final swapPos = indices.indexOf(initialIndex);
    // Swap the indices at initialPos and swapPos.
    final swapIndex = indices[initialPos];
    indices[initialPos] = initialIndex;
    indices[swapPos] = swapIndex;
  }

  @override
  void insert(int index, int count) {
    // Offset indices after insertion point.
    for (var i = 0; i < indices.length; i++) {
      if (indices[i] >= index) {
        indices[i] += count;
      }
    }
    // Insert new indices at random positions after currentIndex.
    final newIndices = List.generate(count, (i) => index + i);
    for (var newIndex in newIndices) {
      final insertionIndex = _random.nextInt(indices.length + 1);
      indices.insert(insertionIndex, newIndex);
    }
  }

  @override
  void removeRange(int start, int end) {
    final count = end - start;
    // Remove old indices.
    final oldIndices = List.generate(count, (i) => start + i).toSet();
    indices.removeWhere(oldIndices.contains);
    // Offset indices after deletion point.
    for (var i = 0; i < indices.length; i++) {
      if (indices[i] >= end) {
        indices[i] -= count;
      }
    }
  }

  @override
  void clear() {
    indices.clear();
  }
}

/// An enumeration of modes that can be passed to [AudioPlayer.setLoopMode].
enum LoopMode { off, one, all }

/// The stand-in platform implementation to use when the player is in the idle
/// state and the native platform is deallocated.
class _IdleAudioPlayer extends AudioPlayerPlatform {
  final _eventSubject = BehaviorSubject<PlaybackEventMessage>();
  late Duration _position;
  int? _index;
  List<IndexedAudioSource>? _sequence;

  /// Holds a pending request.
  SetAndroidAudioAttributesRequest? setAndroidAudioAttributesRequest;

  _IdleAudioPlayer({
    required String id,
    required Stream<List<IndexedAudioSource>?> sequenceStream,
  }) : super(id) {
    sequenceStream.listen((sequence) => _sequence = sequence);
  }

  void _broadcastPlaybackEvent() {
    var updateTime = DateTime.now();
    _eventSubject.add(PlaybackEventMessage(
      processingState: ProcessingStateMessage.idle,
      updatePosition: _position,
      updateTime: updateTime,
      bufferedPosition: Duration.zero,
      icyMetadata: null,
      duration: _getDurationAtIndex(_index),
      currentIndex: _index,
      androidAudioSessionId: null,
    ));
  }

  Duration? _getDurationAtIndex(int? index) =>
      index != null && _sequence != null && index < _sequence!.length
          ? _sequence![index].duration
          : null;

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream =>
      _eventSubject.stream;

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    _index = request.initialIndex ?? 0;
    _position = request.initialPosition ?? Duration.zero;
    _broadcastPlaybackEvent();
    return LoadResponse(duration: _getDurationAtIndex(_index));
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async {
    return PlayResponse();
  }

  @override
  Future<PauseResponse> pause(PauseRequest request) async {
    return PauseResponse();
  }

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async {
    return SetVolumeResponse();
  }

  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async {
    return SetSpeedResponse();
  }

  @override
  Future<SetPitchResponse> setPitch(SetPitchRequest request) async {
    return SetPitchResponse();
  }

  @override
  Future<SetSkipSilenceResponse> setSkipSilence(
      SetSkipSilenceRequest request) async {
    return SetSkipSilenceResponse();
  }

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async {
    return SetLoopModeResponse();
  }

  @override
  Future<SetShuffleModeResponse> setShuffleMode(
      SetShuffleModeRequest request) async {
    return SetShuffleModeResponse();
  }

  @override
  Future<SetShuffleOrderResponse> setShuffleOrder(
      SetShuffleOrderRequest request) async {
    return SetShuffleOrderResponse();
  }

  @override
  Future<SetAutomaticallyWaitsToMinimizeStallingResponse>
      setAutomaticallyWaitsToMinimizeStalling(
          SetAutomaticallyWaitsToMinimizeStallingRequest request) async {
    return SetAutomaticallyWaitsToMinimizeStallingResponse();
  }

  @override
  Future<SetCanUseNetworkResourcesForLiveStreamingWhilePausedResponse>
      setCanUseNetworkResourcesForLiveStreamingWhilePaused(
          SetCanUseNetworkResourcesForLiveStreamingWhilePausedRequest
              request) async {
    return SetCanUseNetworkResourcesForLiveStreamingWhilePausedResponse();
  }

  @override
  Future<SetPreferredPeakBitRateResponse> setPreferredPeakBitRate(
      SetPreferredPeakBitRateRequest request) async {
    return SetPreferredPeakBitRateResponse();
  }

  @override
  Future<SeekResponse> seek(SeekRequest request) async {
    _position = request.position ?? Duration.zero;
    _index = request.index ?? _index;
    _broadcastPlaybackEvent();
    return SeekResponse();
  }

  @override
  Future<SetAndroidAudioAttributesResponse> setAndroidAudioAttributes(
      SetAndroidAudioAttributesRequest request) async {
    setAndroidAudioAttributesRequest = request;
    return SetAndroidAudioAttributesResponse();
  }

  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async {
    return DisposeResponse();
  }

  @override
  Future<ConcatenatingInsertAllResponse> concatenatingInsertAll(
      ConcatenatingInsertAllRequest request) async {
    return ConcatenatingInsertAllResponse();
  }

  @override
  Future<ConcatenatingRemoveRangeResponse> concatenatingRemoveRange(
      ConcatenatingRemoveRangeRequest request) async {
    return ConcatenatingRemoveRangeResponse();
  }

  @override
  Future<ConcatenatingMoveResponse> concatenatingMove(
      ConcatenatingMoveRequest request) async {
    return ConcatenatingMoveResponse();
  }

  @override
  Future<AudioEffectSetEnabledResponse> audioEffectSetEnabled(
      AudioEffectSetEnabledRequest request) async {
    return AudioEffectSetEnabledResponse();
  }

  @override
  Future<AndroidLoudnessEnhancerSetTargetGainResponse>
      androidLoudnessEnhancerSetTargetGain(
          AndroidLoudnessEnhancerSetTargetGainRequest request) async {
    return AndroidLoudnessEnhancerSetTargetGainResponse();
  }
}

/// Holds the initial requested position and index for a newly loaded audio
/// source.
class _InitialSeekValues {
  final Duration? position;
  final int? index;

  _InitialSeekValues({required this.position, required this.index});
}

class AudioPipeline {
  final List<AndroidAudioEffect> androidAudioEffects;
  final List<DarwinAudioEffect> darwinAudioEffects;

  AudioPipeline({
    List<AndroidAudioEffect>? androidAudioEffects,
    List<DarwinAudioEffect>? darwinAudioEffects,
  })  : assert(androidAudioEffects == null ||
            androidAudioEffects.toSet().length == androidAudioEffects.length),
        assert(darwinAudioEffects == null ||
            darwinAudioEffects.toSet().length == darwinAudioEffects.length),
        androidAudioEffects = androidAudioEffects ?? const [],
        darwinAudioEffects = darwinAudioEffects ?? const [];

  List<AudioEffect> get _audioEffects =>
      <AudioEffect>[...androidAudioEffects, ...darwinAudioEffects];

  void _setup(AudioPlayer player) {
    for (var effect in _audioEffects) {
      effect._setup(player);
    }
  }
}

/// Subclasses of [AudioEffect] can be inserted into an [AudioPipeline] to
/// modify the audio signal outputted by an [AudioPlayer]. The same audio effect
/// instance cannot be set on multiple players at the same time.
///
/// An [AudioEffect] is disabled by default. For an [AudioEffect] to take
/// effect, in addition to being part of an [AudioPipeline] attached to an
/// [AudioPlayer] you must also enable the effect via [setEnabled].
abstract class AudioEffect {
  AudioPlayer? _player;
  final _enabledSubject = BehaviorSubject.seeded(false);

  AudioEffect();

  /// Called when an [AudioEffect] is attached to an [AudioPlayer].
  void _setup(AudioPlayer player) {
    assert(_player == null);
    _player = player;
  }

  /// Called when [_player] is connected to the platform.
  Future<void> _activate() async {}

  /// Whether the effect is enabled. When `true`, and if the effect is part
  /// of an [AudioPipeline] attached to an [AudioPlayer], the effect will modify
  /// the audio player's output. When `false`, the audio pipeline will still
  /// reserve platform resources for the effect but the effect will be bypassed.
  bool get enabled => _enabledSubject.nvalue!;

  /// A stream of the current [enabled] value.
  Stream<bool> get enabledStream => _enabledSubject.stream;

  bool get _active => _player?._active ?? false;

  String get _type;

  /// Set the [enabled] status of this audio effect.
  Future<void> setEnabled(bool enabled) async {
    _enabledSubject.add(enabled);
    if (_active) {
      await (await _player!._platform).audioEffectSetEnabled(
          AudioEffectSetEnabledRequest(type: _type, enabled: enabled));
    }
  }

  AudioEffectMessage _toMessage();
}

/// An [AudioEffect] that supports Android.
mixin AndroidAudioEffect on AudioEffect {}

/// An [AudioEffect] that supports iOS and macOS.
mixin DarwinAudioEffect on AudioEffect {}

/// An Android [AudioEffect] that boosts the volume of the audio signal to a
/// target gain, which defaults to zero.
class AndroidLoudnessEnhancer extends AudioEffect with AndroidAudioEffect {
  final _targetGainSubject = BehaviorSubject.seeded(0.0);

  @override
  String get _type => 'AndroidLoudnessEnhancer';

  /// The target gain in decibels.
  double get targetGain => _targetGainSubject.nvalue!;

  /// A stream of the current target gain in decibels.
  Stream<double> get targetGainStream => _targetGainSubject.stream;

  /// Sets the target gain to a value in decibels.
  Future<void> setTargetGain(double targetGain) async {
    _targetGainSubject.add(targetGain);
    if (_active) {
      await (await _player!._platform).androidLoudnessEnhancerSetTargetGain(
          AndroidLoudnessEnhancerSetTargetGainRequest(targetGain: targetGain));
    }
  }

  @override
  AudioEffectMessage _toMessage() => AndroidLoudnessEnhancerMessage(
        enabled: enabled,
        targetGain: targetGain,
      );
}

/// A frequency band within an [AndroidEqualizer].
class AndroidEqualizerBand {
  final AudioPlayer _player;

  /// A zero-based index of the position of this band within its [AndroidEqualizer].
  final int index;

  /// The lower frequency of this band in hertz.
  final double lowerFrequency;

  /// The upper frequency of this band in hertz.
  final double upperFrequency;

  /// The center frequency of this band in hertz.
  final double centerFrequency;
  final _gainSubject = BehaviorSubject<double>();

  AndroidEqualizerBand._({
    required AudioPlayer player,
    required this.index,
    required this.lowerFrequency,
    required this.upperFrequency,
    required this.centerFrequency,
    required double gain,
  }) : _player = player {
    _gainSubject.add(gain);
  }

  /// The gain for this band in decibels.
  double get gain => _gainSubject.nvalue!;

  /// A stream of the current gain for this band in decibels.
  Stream<double> get gainStream => _gainSubject.stream;

  /// Sets the gain for this band in decibels.
  Future<void> setGain(double gain) async {
    _gainSubject.add(gain);
    if (_player._active) {
      await (await _player._platform).androidEqualizerBandSetGain(
          AndroidEqualizerBandSetGainRequest(bandIndex: index, gain: gain));
    }
  }

  /// Restores the gain after reactivating.
  Future<void> _restore() async {
    await (await _player._platform).androidEqualizerBandSetGain(
        AndroidEqualizerBandSetGainRequest(bandIndex: index, gain: gain));
  }

  static AndroidEqualizerBand _fromMessage(
          AudioPlayer player, AndroidEqualizerBandMessage message) =>
      AndroidEqualizerBand._(
        player: player,
        index: message.index,
        lowerFrequency: message.lowerFrequency,
        upperFrequency: message.upperFrequency,
        centerFrequency: message.centerFrequency,
        gain: message.gain,
      );
}

/// The parameter values of an [AndroidEqualizer].
class AndroidEqualizerParameters {
  /// The minimum gain value supported by the equalizer.
  final double minDecibels;

  /// The maximum gain value supported by the equalizer.
  final double maxDecibels;

  /// The frequency bands of the equalizer.
  final List<AndroidEqualizerBand> bands;

  AndroidEqualizerParameters({
    required this.minDecibels,
    required this.maxDecibels,
    required this.bands,
  });

  /// Restore platform state after reactivating.
  Future<void> _restore() async {
    for (var band in bands) {
      await band._restore();
    }
  }

  static AndroidEqualizerParameters _fromMessage(
          AudioPlayer player, AndroidEqualizerParametersMessage message) =>
      AndroidEqualizerParameters(
        minDecibels: message.minDecibels,
        maxDecibels: message.maxDecibels,
        bands: message.bands
            .map((bandMessage) =>
                AndroidEqualizerBand._fromMessage(player, bandMessage))
            .toList(),
      );
}

/// An [AudioEffect] for Android that can adjust the gain for different
/// frequency bands of an [AudioPlayer]'s audio signal.
class AndroidEqualizer extends AudioEffect with AndroidAudioEffect {
  AndroidEqualizerParameters? _parameters;
  final Completer<AndroidEqualizerParameters> _parametersCompleter =
      Completer<AndroidEqualizerParameters>();

  @override
  String get _type => 'AndroidEqualizer';

  @override
  Future<void> _activate() async {
    await super._activate();
    if (_parametersCompleter.isCompleted) {
      await (await parameters)._restore();
      return;
    }
    final response = await (await _player!._platform)
        .androidEqualizerGetParameters(AndroidEqualizerGetParametersRequest());
    _parameters =
        AndroidEqualizerParameters._fromMessage(_player!, response.parameters);
    _parametersCompleter.complete(_parameters);
  }

  /// The parameter values of this equalizer.
  Future<AndroidEqualizerParameters> get parameters =>
      _parametersCompleter.future;

  @override
  AudioEffectMessage _toMessage() => AndroidEqualizerMessage(
        enabled: enabled,
        // Parameters are only communicated from the platform.
        parameters: null,
      );
}

bool _isAndroid() => !kIsWeb && Platform.isAndroid;
bool _isDarwin() => !kIsWeb && (Platform.isIOS || Platform.isMacOS);
bool _isUnitTest() => !kIsWeb && Platform.environment['FLUTTER_TEST'] == 'true';

/// Backwards compatible extensions on rxdart's ValueStream
extension _ValueStreamExtension<T> on ValueStream<T> {
  /// Backwards compatible version of valueOrNull.
  T? get nvalue => hasValue ? value : null;
}

/// Information collected when a position discontinuity occurs.
class PositionDiscontinuity {
  /// The reason for the position discontinuity.
  final PositionDiscontinuityReason reason;

  /// The previous event before the position discontinuity.
  final PlaybackEvent previousEvent;

  /// The event that caused the position discontinuity.
  final PlaybackEvent event;

  const PositionDiscontinuity(this.reason, this.previousEvent, this.event);
}

/// The reasons for position discontinuities.
enum PositionDiscontinuityReason {
  /// The position discontinuity was initiated by a seek.
  seek,

  /// The position discontinuity occurred because the player reached the end of
  /// the current item and auto-advanced to the next item.
  autoAdvance,
}

Future<HttpClientRequest> _getUrl(HttpClient client, Uri uri,
    {Map<String, String>? headers}) async {
  final request = await client.getUrl(uri);
  if (headers != null) {
    final host = request.headers.value(HttpHeaders.hostHeader);
    request.headers.clear();
    request.headers.set(HttpHeaders.contentLengthHeader, '0');
    headers.forEach((name, value) => request.headers.set(name, value));
    if (host != null) {
      request.headers.set(HttpHeaders.hostHeader, host);
    }
    if (client.userAgent != null) {
      request.headers.set(HttpHeaders.userAgentHeader, client.userAgent!);
    }
  }
  // Match ExoPlayer's native behavior
  request.maxRedirects = 20;
  return request;
}

HttpClient _createHttpClient({String? userAgent}) {
  final client = HttpClient();
  if (userAgent != null) {
    client.userAgent = userAgent;
  }
  return client;
}
