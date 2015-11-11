part of flutter_sprites;

// TODO: The sound effects should probably use Android's SoundPool instead of
// MediaPlayer as it is more efficient and flexible for playing back sound effects

typedef void SoundEffectStreamCallback(SoundEffectStream stream);

class SoundEffect {
  SoundEffect(this._pipeFuture);

  // TODO: Remove load method from SoundEffect
  Future load() async {
    _data = await _pipeFuture;
  }

  Future<MojoDataPipeConsumer> _pipeFuture;
  MojoDataPipeConsumer _data;
}

class SoundEffectStream {
  SoundEffectStream(
    this.sound,
    this.loop,
    this.volume,
    this.pitch,
    this.pan,
    this.onSoundComplete
  );

  // TODO: Make these properties work
  SoundEffect sound;
  bool playing = false;
  bool loop = false;
  double volume = 1.0;
  double pitch = 1.0;
  double pan = 0.0;

  // TODO: Implement completion callback. On completion, sounds should
  // also be removed from the list of playing sounds.
  SoundEffectStreamCallback onSoundComplete;

  MediaPlayerProxy _player;
}

SoundEffectPlayer _sharedSoundEffectPlayer;

class SoundEffectPlayer {

  static SoundEffectPlayer sharedInstance() {
    if (_sharedSoundEffectPlayer == null) {
      _sharedSoundEffectPlayer = new SoundEffectPlayer();
    }
    return _sharedSoundEffectPlayer;
  }

  SoundEffectPlayer() {
    _mediaService = new MediaServiceProxy.unbound();
    shell.connectToService(null, _mediaService);
  }

  MediaServiceProxy _mediaService;
  List<SoundEffectStream> _soundEffectStreams = <SoundEffectStream>[];

  // TODO: This should no longer be needed when moving to SoundPool backing
  Map<SoundEffect,MediaPlayerProxy> _mediaPlayers = <SoundEffect, MediaPlayerProxy>{};

  Future _prepare(SoundEffectStream playingSound) async {
    await playingSound._player.ptr.prepare(playingSound.sound._data);
  }

  // TODO: Move sound loading here
  // TODO: Support loading sounds from bundles
  // Future<SoundEffect> load(url) async {
  //   ...
  // }

  // TODO: Add sound unloader
  // unload(SoundEffect effect) {
  //   ...
  // }

  // TODO: Add paused property (should pause playback of all sounds)
  bool paused;

  SoundEffectStream play(
    SoundEffect sound,
    [bool loop = false,
      double volume = 1.0,
      double pitch = 1.0,
      double pan = 0.0,
      SoundEffectStreamCallback callback = null]) {

    // Create new PlayingSound object
    SoundEffectStream playingSound = new SoundEffectStream(
      sound,
      loop,
      volume,
      pitch,
      pan,
      callback
    );

    // TODO: Replace this with calls to SoundPool
    if (_mediaPlayers[sound] == null) {
      // Create player
      playingSound._player = new MediaPlayerProxy.unbound();
      _mediaService.ptr.createPlayer(playingSound._player);

      // Prepare sound, then play it
      _prepare(playingSound).then((_) {
        playingSound._player.ptr.seekTo(0);
        playingSound._player.ptr.start();
      });

      _soundEffectStreams.add(playingSound);
      _mediaPlayers[sound] = playingSound._player;
    } else {
      // Reuse player
      playingSound._player = _mediaPlayers[sound];
      playingSound._player.ptr.seekTo(0);
      playingSound._player.ptr.start();
    }

    return playingSound;
  }

  void stop(SoundEffectStream stream) {
    stream._player.ptr.pause();
    _soundEffectStreams.remove(stream);
  }

  void stopAll() {
    for (SoundEffectStream playingSound in _soundEffectStreams) {
      playingSound._player.ptr.pause();
    }
    _soundEffectStreams = <SoundEffectStream>[];
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
