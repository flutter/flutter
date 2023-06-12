import 'dart:async';
// TODO(gustl22): remove when upgrading min Flutter version to >=3.3.0
// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// This represents a single AudioPlayer, which can play one audio at a time.
/// To play several audios at the same time, you must create several instances
/// of this class.
///
/// It holds methods to play, loop, pause, stop, seek the audio, and some useful
/// hooks for handlers and callbacks.
class AudioPlayer {
  static final global = GlobalPlatformInterface.instance;
  static final _platform = AudioplayersPlatform.instance;

  /// This is the [AudioCache] instance used by this player.
  /// Unless you want to control multiple caches separately, you don't need to
  /// change anything as the global instance will be used by default.
  AudioCache audioCache = AudioCache.instance;

  PlayerState _playerState = PlayerState.stopped;

  PlayerState get state => _playerState;

  set state(PlayerState state) {
    if (!_playerStateController.isClosed) {
      _playerStateController.add(state);
    }
    _playerState = state;
  }

  late StreamSubscription _onPlayerCompleteStreamSubscription;

  final StreamController<PlayerState> _playerStateController =
      StreamController<PlayerState>.broadcast();

  /// Stream of changes on player state.
  Stream<PlayerState> get onPlayerStateChanged => _playerStateController.stream;

  /// Stream of changes on audio position.
  ///
  /// Roughly fires every 200 milliseconds. Will continuously update the
  /// position of the playback if the status is [PlayerState.playing].
  ///
  /// You can use it on a progress bar, for instance.
  Stream<Duration> get onPositionChanged =>
      _platform.positionStream.filter(playerId);

  /// Stream of changes on audio duration.
  ///
  /// An event is going to be sent as soon as the audio duration is available
  /// (it might take a while to download or buffer it).
  Stream<Duration> get onDurationChanged =>
      _platform.durationStream.filter(playerId);

  /// Stream of player completions.
  ///
  /// Events are sent every time an audio is finished, therefore no event is
  /// sent when an audio is paused or stopped.
  ///
  /// [ReleaseMode.loop] also sends events to this stream.
  Stream<void> get onPlayerComplete =>
      _platform.completeStream.filter(playerId);

  /// Stream of seek completions.
  ///
  /// An event is going to be sent as soon as the audio seek is finished.
  Stream<void> get onSeekComplete =>
      _platform.seekCompleteStream.filter(playerId);

  /// An unique ID generated for this instance of [AudioPlayer].
  ///
  /// This is used to properly exchange messages with the [MethodChannel].
  final String playerId;

  /// Current mode of the audio player. Can be updated at any time, but is going
  /// to take effect only at the next time you play the audio.
  PlayerMode _mode = PlayerMode.mediaPlayer;

  PlayerMode get mode => _mode;

  ReleaseMode _releaseMode = ReleaseMode.release;

  ReleaseMode get releaseMode => _releaseMode;

  /// Creates a new instance and assigns an unique id to it.
  AudioPlayer({String? playerId}) : playerId = playerId ?? _uuid.v4() {
    _onPlayerCompleteStreamSubscription = onPlayerComplete.listen((_) {
      state = PlayerState.completed;
    });
  }

  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    if (mode != null) {
      await setPlayerMode(mode);
    }
    if (volume != null) {
      await setVolume(volume);
    }
    if (balance != null) {
      await setBalance(balance);
    }
    if (ctx != null) {
      await setAudioContext(ctx);
    }
    if (position != null) {
      await seek(position);
    }
    await setSource(source);
    return resume();
  }

  Future<void> setAudioContext(AudioContext ctx) {
    return _platform.setAudioContext(playerId, ctx);
  }

  Future<void> setPlayerMode(PlayerMode mode) {
    _mode = mode;
    return _platform.setPlayerMode(playerId, mode);
  }

  /// Pauses the audio that is currently playing.
  ///
  /// If you call [resume] later, the audio will resume from the point that it
  /// has been paused.
  Future<void> pause() async {
    await _platform.pause(playerId);
    state = PlayerState.paused;
  }

  /// Stops the audio that is currently playing.
  ///
  /// The position is going to be reset and you will no longer be able to resume
  /// from the last point.
  Future<void> stop() async {
    await _platform.stop(playerId);
    state = PlayerState.stopped;
  }

  /// Resumes the audio that has been paused or stopped.
  Future<void> resume() async {
    await _platform.resume(playerId);
    state = PlayerState.playing;
  }

  /// Releases the resources associated with this media player.
  ///
  /// The resources are going to be fetched or buffered again as soon as you
  /// call [resume] or change the source.
  Future<void> release() async {
    await _platform.release(playerId);
    state = PlayerState.stopped;
  }

  /// Moves the cursor to the desired position.
  Future<void> seek(Duration position) {
    return _platform.seek(playerId, position);
  }

  /// Sets the stereo balance.
  ///
  /// -1 - The left channel is at full volume; the right channel is silent.
  ///  1 - The right channel is at full volume; the left channel is silent.
  ///  0 - Both channels are at the same volume.
  Future<void> setBalance(double balance) {
    return _platform.setBalance(playerId, balance);
  }

  /// Sets the volume (amplitude).
  ///
  /// 0 is mute and 1 is the max volume. The values between 0 and 1 are linearly
  /// interpolated.
  Future<void> setVolume(double volume) {
    return _platform.setVolume(playerId, volume);
  }

  /// Sets the release mode.
  ///
  /// Check [ReleaseMode]'s doc to understand the difference between the modes.
  Future<void> setReleaseMode(ReleaseMode releaseMode) {
    _releaseMode = releaseMode;
    return _platform.setReleaseMode(playerId, releaseMode);
  }

  /// Sets the playback rate - call this after first calling play() or resume().
  ///
  /// iOS and macOS have limits between 0.5 and 2x
  /// Android SDK version should be 23 or higher
  Future<void> setPlaybackRate(double playbackRate) {
    return _platform.setPlaybackRate(playerId, playbackRate);
  }

  /// Sets the audio source for this player.
  ///
  /// This will delegate to one of the specific methods below depending on
  /// the source type.
  Future<void> setSource(Source source) {
    return source.setOnPlayer(this);
  }

  /// Sets the URL to a remote link.
  ///
  /// The resources will start being fetched or buffered as soon as you call
  /// this method.
  Future<void> setSourceUrl(String url) {
    return _platform.setSourceUrl(playerId, url, isLocal: false);
  }

  /// Sets the URL to a file in the users device.
  ///
  /// The resources will start being fetched or buffered as soon as you call
  /// this method.
  Future<void> setSourceDeviceFile(String path) {
    return _platform.setSourceUrl(playerId, path, isLocal: true);
  }

  /// Sets the URL to an asset in your Flutter application.
  /// The global instance of AudioCache will be used by default.
  ///
  /// The resources will start being fetched or buffered as soon as you call
  /// this method.
  Future<void> setSourceAsset(String path) async {
    final url = await audioCache.load(path);
    return _platform.setSourceUrl(playerId, url.path, isLocal: true);
  }

  Future<void> setSourceBytes(Uint8List bytes) {
    return _platform.setSourceBytes(playerId, bytes);
  }

  /// Get audio duration after setting url.
  /// Use it in conjunction with setUrl.
  ///
  /// It will be available as soon as the audio duration is available
  /// (it might take a while to download or buffer it if file is not local).
  Future<Duration?> getDuration() async {
    final milliseconds = await _platform.getDuration(playerId);
    if (milliseconds == null) {
      return null;
    }
    return Duration(milliseconds: milliseconds);
  }

  // Gets audio current playing position
  Future<Duration?> getCurrentPosition() async {
    final milliseconds = await _platform.getCurrentPosition(playerId);
    if (milliseconds == null) {
      return null;
    }
    return Duration(milliseconds: milliseconds);
  }

  /// Closes all [StreamController]s.
  ///
  /// You must call this method when your [AudioPlayer] instance is not going to
  /// be used anymore. If you try to use it after this you will get errors.
  Future<void> dispose() async {
    // First stop and release all native resources.
    await release();

    final futures = <Future>[
      if (!_playerStateController.isClosed) _playerStateController.close(),
      _onPlayerCompleteStreamSubscription.cancel()
    ];

    await Future.wait<dynamic>(futures);
  }
}
