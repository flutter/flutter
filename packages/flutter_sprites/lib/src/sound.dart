// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of flutter_sprites;

/// An audio asset loaded by the SoundEffectPlayer.
class SoundEffect {

  /// Creates a new sound effect with the given sound id. Normally,
  /// SoundEffect objects are created through the [SoundEffectPlayer].
  SoundEffect(this._soundId);

  int _soundId;
}

/// A sound being played by the SoundEffectPlayer.
class SoundEffectStream {

  /// Creates a new SoundEffectStream. Typically SoundEffectStream objects are
  /// created by the SoundEffectPlayer.
  SoundEffectStream(SoundEffectPlayer player, int streamId, {
    double leftVolume,
    double rightVolume,
    double pitch
  }) {
    _player = player;
    _streamId = streamId;
    _paused = false;
    _leftVolume = leftVolume;
    _rightVolume = rightVolume;
    _pitch = pitch;
  }

  SoundEffectPlayer _player;
  int _streamId;

  SoundPoolProxy get _soundPool => _player._soundPool;

  /// Stop the sound effect.
  void stop() {
    _soundPool.stop(_streamId);
  }

  /// True if the sound effect is paused.
  bool get paused => _paused;
  bool _paused;
  set paused(bool value) {
    _paused = value;
    if (_paused) {
      _soundPool.pause(_streamId);
    } else {
      _soundPool.resume(_streamId);
    }
  }

  /// Left volume of the sound effect, valid values are 0.0 to 1.0.
  double get leftVolume => _leftVolume;
  double _leftVolume;
  set leftVolume(double value) {
    _leftVolume = value;
    _soundPool.setVolume(_streamId, <double>[_leftVolume, _rightVolume]);
  }

  /// Right volume of the sound effect, valid values are 0.0 to 1.0.
  double get rightVolume => _rightVolume;
  double _rightVolume;
  set rightVolume(double value) {
    _rightVolume = value;
    _soundPool.setVolume(_streamId, <double>[_leftVolume, _rightVolume]);
  }

  /// The pitch of the sound effect, a value of 1.0 plays back the sound effect
  /// at normal speed. Cannot be negative.
  double get pitch => _pitch;
  double _pitch;
  set pitch(double value) {
    _pitch = value;
    _soundPool.setRate(_streamId, _pitch);
  }
}

/// The SoundEffectPlayer loads and plays sound effects.
class SoundEffectPlayer {

  /// Creates a new SoundEffectPlayer with a max number of simultaneous
  /// streams specified.
  SoundEffectPlayer(int maxStreams) {
    MediaServiceProxy mediaService = shell.connectToApplicationService(
      'mojo:media_service', MediaService.connectToService
    );
    _soundPool = new SoundPoolProxy.unbound();
    mediaService.createSoundPool(_soundPool, maxStreams);
  }

  SoundPoolProxy _soundPool;
  bool _paused;
  int _nextStreamId = 0;

  /// Loads a sound effect.
  Future<SoundEffect> load(MojoDataPipeConsumer data) {
    Completer<SoundEffect> completer = new Completer<SoundEffect>();
    _soundPool.load(data, (bool success, int soundId) {
      if (success)
        completer.complete(new SoundEffect(soundId));
      else
        completer.completeError(new Exception('Unable to load sound'));
    });
    return completer.future;
  }

  /// Plays a sound effect.
  Future<SoundEffectStream> play(SoundEffect sound, {
    double leftVolume: 1.0,
    double rightVolume: 1.0,
    bool loop: false,
    double pitch: 1.0
  }) {
    Completer<SoundEffectStream> completer = new Completer<SoundEffectStream>();
    int streamId = _nextStreamId++;
    _soundPool.play(sound._soundId,
                    streamId,
                    <double>[leftVolume, rightVolume],
                    loop,
                    pitch,
                    (bool success) {
      if (success) {
        completer.complete(new SoundEffectStream(this, streamId,
          leftVolume: leftVolume,
          rightVolume: rightVolume,
          pitch: pitch
        ));
      } else {
        completer.completeError(new Exception('Unable to play sound'));
      }
    });
    return completer.future;
  }

  /// Set to true to pause a sound effect.
  bool get paused => _paused;

  set paused(bool value) {
    _paused = value;
    if (_paused) {
      _soundPool.pauseAll();
    } else {
      _soundPool.resumeAll();
    }
  }
}

/// Signature for callbacks used by [SoundTrack].
typedef void SoundTrackCallback(SoundTrack soundTrack);

/// Signature for callbacks used by [SoundTrack].
typedef void SoundTrackBufferingCallback(SoundTrack soundTrack, int index);

/// A sound track is typically longer than a [SoundEffect]. Use sound tracks to
/// play back music or ambient sounds.
class SoundTrack {
  MediaPlayerProxy _player;

  /// Called when the sound has finished playing.
  SoundTrackCallback onSoundComplete;

  /// Called when a seek operation has finished.
  SoundTrackCallback onSeekComplete;

  /// Called when buffering is being performed.
  SoundTrackBufferingCallback onBufferingUpdate;

  /// If true, the sound track will automatically loop.
  bool loop;

  /// The current playback time in seconds.
  double time;

  /// The volume the sound track is currently played at, valid range is 0.0 to
  /// 1.0.
  double volume;
}

SoundTrackPlayer _sharedSoundTrackPlayer;

/// Loads and plays [SoundTrack]s.
class SoundTrackPlayer {

  /// Creates a new [SoundTrackPlayer], typically you will want to use the
  /// [sharedInstance] method to receive the player.
  SoundTrackPlayer() {
    _mediaService = shell.connectToApplicationService(
      'mojo:media_service', MediaService.connectToService
    );
  }

  MediaServiceProxy _mediaService;

  Set<SoundTrack> _soundTracks = new HashSet<SoundTrack>();

  /// Retrives a singleton object of the SoundTrackPlayer, use this method
  /// in favor for the constructor.
  static SoundTrackPlayer sharedInstance() {
    return _sharedSoundTrackPlayer ??= new SoundTrackPlayer();
  }

  /// Loads a [SoundTrack].
  Future<SoundTrack> load(Future<MojoDataPipeConsumer> pipe) async {
    // Create media player
    SoundTrack soundTrack = new SoundTrack();
    soundTrack._player = new MediaPlayerProxy.unbound();
    _mediaService.createPlayer(soundTrack._player);

    Completer<SoundTrack> completer = new Completer<SoundTrack>();
    soundTrack._player.prepare(await pipe, (bool ignored) {
      completer.complete(soundTrack);
    });
    return await completer.future;
  }

  /// Unloads a [SoundTrack] from memory.
  void unload(SoundTrack soundTrack) {
    stop(soundTrack);
    _soundTracks.remove(soundTrack);
  }

  /// Plays a [SoundTrack].
  void play(SoundTrack soundTrack, {
    bool loop: false,
    double volume: 1.0,
    double startTime: 0.0
  }) {
    soundTrack._player
      ..setLooping(loop)
      ..setVolume(volume)
      ..seekTo((startTime * 1000.0).toInt())
      ..start();
    _soundTracks.add(soundTrack);
  }

  /// Stops a [SoundTrack]. You may also want to call the [unload] method to
  /// remove if from memory if you are not planning to play it again.
  void stop(SoundTrack track) {
    track._player.pause();
  }

  /// Pauses all [SoundTrack]s that are currently playing.
  void pauseAll() {
    for (SoundTrack soundTrack in _soundTracks)
      soundTrack._player.pause();
  }

  /// Resumes all [SoundTrack]s that have been loaded by this player.
  void resumeAll() {
    for (SoundTrack soundTrack in _soundTracks)
      soundTrack._player.start();
  }
}
