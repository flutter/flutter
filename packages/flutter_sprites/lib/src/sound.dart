part of flutter_sprites;

/// An audio asset loaded by the SoundEffectPlayer.
class SoundEffect {
  SoundEffect(this._soundId);

  int _soundId;
}

/// A sound being played by the SoundEffectPlayer.
class SoundEffectStream {
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

  void stop() {
    _soundPool.ptr.stop(_streamId);
  }

  bool get paused => _paused;
  bool _paused;
  void set paused(bool value) {
    _paused = value;
    if (_paused) {
      _soundPool.ptr.pause(_streamId);
    } else {
      _soundPool.ptr.resume(_streamId);
    }
  }

  double get leftVolume => _leftVolume;
  double _leftVolume;
  void set leftVolume(double value) {
    _leftVolume = value;
    _soundPool.ptr.setVolume(_streamId, <double>[_leftVolume, _rightVolume]);
  }

  double get rightVolume => _rightVolume;
  double _rightVolume;
  void set rightVolume(double value) {
    _rightVolume = value;
    _soundPool.ptr.setVolume(_streamId, <double>[_leftVolume, _rightVolume]);
  }

  double get pitch => _pitch;
  double _pitch;
  void set pitch(double value) {
    _pitch = value;
    _soundPool.ptr.setRate(_streamId, _pitch);
  }
}

class SoundEffectPlayer {
  SoundEffectPlayer(int maxStreams) {
    MediaServiceProxy mediaService = new MediaServiceProxy.unbound();
    shell.connectToService(null, mediaService);
    _soundPool = new SoundPoolProxy.unbound();
    mediaService.ptr.createSoundPool(_soundPool, maxStreams);
  }

  SoundPoolProxy _soundPool;
  bool _paused;
  int _nextStreamId = 0;

  Future<SoundEffect> load(MojoDataPipeConsumer data) async {
    SoundPoolLoadResponseParams result = await _soundPool.ptr.load(data);
    if (result.success)
      return new SoundEffect(result.soundId);

    throw new Exception('Unable to load sound');
  }

  Future<SoundEffectStream> play(SoundEffect sound, {
    double leftVolume: 1.0,
    double rightVolume: 1.0,
    bool loop: false,
    double pitch: 1.0
  }) async {
    int streamId = _nextStreamId++;
    SoundPoolPlayResponseParams result = await _soundPool.ptr.play(
      sound._soundId, streamId, <double>[leftVolume, rightVolume], loop, pitch
    );

    if (result.success) {
      return new SoundEffectStream(this, streamId,
        leftVolume: leftVolume,
        rightVolume: rightVolume,
        pitch: pitch
      );
    }

    throw new Exception('Unable to play sound');
  }

  bool get paused => _paused;

  void set paused(bool value) {
    _paused = value;
    if (_paused) {
      _soundPool.ptr.pauseAll();
    } else {
      _soundPool.ptr.resumeAll();
    }
  }
}

typedef void SoundTrackCallback(SoundTrack soundTrack);
typedef void SoundTrackBufferingCallback(SoundTrack soundTrack, int index);

class SoundTrack {
  MediaPlayerProxy _player;

  SoundTrackCallback onSoundComplete;
  SoundTrackCallback onSeekComplete;
  SoundTrackBufferingCallback onBufferingUpdate;
  bool loop;
  double time;
  double volume;
}

SoundTrackPlayer _sharedSoundTrackPlayer;

class SoundTrackPlayer {
  List<SoundTrack> _soundTracks = <SoundTrack>[];

  static sharedInstance() {
    if (_sharedSoundTrackPlayer == null) {
      _sharedSoundTrackPlayer = new SoundTrackPlayer();
    }
    return _sharedSoundTrackPlayer;
  }

  SoundTrackPlayer() {
    _mediaService = new MediaServiceProxy.unbound();
    shell.connectToService(null, _mediaService);
  }

  MediaServiceProxy _mediaService;

  Future<SoundTrack> load(Future<MojoDataPipeConsumer> pipe) async {
    // Create media player
    SoundTrack soundTrack = new SoundTrack();
    soundTrack._player = new MediaPlayerProxy.unbound();
    _mediaService.ptr.createPlayer(soundTrack._player);

    await soundTrack._player.ptr.prepare(await pipe);
    return soundTrack;
  }

  void unload(SoundTrack soundTrack) {
    stop(soundTrack);
    _soundTracks.remove(soundTrack);
  }

  void play(
    SoundTrack soundTrack,
    [bool loop = false,
      double volume,
      double startTime = 0.0]) {
    // TODO: Implement looping & volume
    // soundTrack._player.ptr.setLooping(loop);
    // soundTrack._player.ptr.setVolume(volume);
    soundTrack._player.ptr.seekTo((startTime * 1000.0).toInt());
    soundTrack._player.ptr.start();
  }

  void stop(SoundTrack track) {
    track._player.ptr.pause();
  }

  void stopAll() {
    for (SoundTrack soundTrack in _soundTracks) {
      soundTrack._player.ptr.pause();
    }
  }
}
