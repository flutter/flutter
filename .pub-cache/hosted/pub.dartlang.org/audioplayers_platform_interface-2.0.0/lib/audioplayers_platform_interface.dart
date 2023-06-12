import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers_platform_interface/api/audio_context_config.dart';
import 'package:audioplayers_platform_interface/api/for_player.dart';
import 'package:audioplayers_platform_interface/api/player_mode.dart';
import 'package:audioplayers_platform_interface/api/release_mode.dart';
import 'package:audioplayers_platform_interface/method_channel_audioplayers_platform.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The interface that implementations of audioplayers must implement.
///
/// Platform implementations should extend this class rather than implement it
/// as `audioplayers` does not consider newly added methods to be breaking
/// changes. Extending this class (using `extends`) ensures that the subclass
/// will get the default implementation, while platform implementations that
/// `implements` this interface will be broken by newly added
/// [AudioplayersPlatform] methods.
abstract class AudioplayersPlatform extends PlatformInterface {
  AudioplayersPlatform() : super(token: _token);

  static final Object _token = Object();

  /// The default instance of [AudioplayersPlatform] to use.
  ///
  /// Defaults to [MethodChannelAudioplayersPlatform].
  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [AudioplayersPlatform] when they register themselves.
  static AudioplayersPlatform instance = MethodChannelAudioplayersPlatform();

  /// Pauses the audio that is currently playing.
  ///
  /// If you call [resume] later, the audio will resume from the point that it
  /// has been paused.
  Future<void> pause(String playerId);

  /// Stops the audio that is currently playing.
  ///
  /// The position is going to be reset and you will no longer be able to resume
  /// from the last point.
  Future<void> stop(String playerId);

  /// Resumes the audio that has been paused or stopped.
  Future<void> resume(String playerId);

  /// Releases the resources associated with this media player.
  ///
  /// The resources are going to be fetched or buffered again as needed.
  Future<void> release(String playerId);

  /// Moves the cursor to the desired position.
  Future<void> seek(String playerId, Duration position);

  /// Sets the stereo balance.
  ///
  /// -1 - The left channel is at full volume; the right channel is silent.
  ///  1 - The right channel is at full volume; the left channel is silent.
  ///  0 - Both channels are at the same volume.
  Future<void> setBalance(String playerId, double balance);

  /// Sets the volume (amplitude).
  ///
  /// 0 is mute and 1 is the max volume. The values between 0 and 1 are linearly
  /// interpolated.
  Future<void> setVolume(String playerId, double volume);

  /// Sets the release mode.
  ///
  /// Check [ReleaseMode]'s doc to understand the difference between the modes.
  Future<void> setReleaseMode(String playerId, ReleaseMode releaseMode);

  /// Sets the playback rate.
  ///
  /// iOS and macOS have limits between 0.5 and 2x
  /// Android SDK version should be 23 or higher
  Future<void> setPlaybackRate(String playerId, double playbackRate);

  /// Configures the player to read the audio from a URL.
  ///
  /// The resources will start being fetched or buffered as soon as you call
  /// this method.
  Future<void> setSourceUrl(
    String playerId,
    String url, {
    bool? isLocal,
  });

  /// Configures the play to read the audio from a byte array.
  Future<void> setSourceBytes(
    String playerId,
    Uint8List bytes,
  );

  Future<void> setAudioContext(
    String playerId,
    AudioContext audioContext,
  );

  Future<void> setPlayerMode(
    String playerId,
    PlayerMode playerMode,
  );

  /// Returns the duration of the media, in milliseconds, if available.
  ///
  /// Might not be available if:
  ///  * source has not been set or prepared yet (for remote audios it must be
  ///    downloaded and buffered first)
  ///  * source does not support operation (e.g. streams)
  ///  * otherwise not supported (e.g. LOW_LATENCY mode on Android)
  Future<int?> getDuration(String playerId);

  /// Returns the current position of playback, in milliseconds, if available.
  ///
  /// Might not be available if:
  ///  * source has not been set or prepared yet (for remote audios it must be
  ///    downloaded and buffered first)
  ///  * source does not support operation (e.g. streams)
  ///  * otherwise not supported (e.g. LOW_LATENCY mode on Android)
  Future<int?> getCurrentPosition(String playerId);

  Stream<ForPlayer<Duration>> get positionStream;

  Stream<ForPlayer<Duration>> get durationStream;

  Stream<ForPlayer<void>> get completeStream;

  Stream<ForPlayer<void>> get seekCompleteStream;
}
