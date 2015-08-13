part of sprites;

// TODO: The sound effects should probably use Android's SoundPool instead of
// MediaPlayer as it is more efficient and flexible for playing back sound effects

typedef void SoundCompleteCallback();

class SoundEffect {
  SoundEffect(this._url);

  // TODO: Remove load method from SoundEffect
  Future load() async {
    UrlResponse response = await fetchUrl(_url);
    _data = response.body;
  }

  String _url;
  Object _data;
}

class SoundStream {
  SoundStream(
    this.sound,
    this.tag,
    this.loop,
    this.time,
    this.volume,
    this.pitch,
    this.pan,
    this.callback
  );

  // TODO: Make these properties work
  SoundEffect sound;
  bool playing = false;
  bool loop = false;
  double time = 0.0;
  double volume = 1.0;
  double pitch = 1.0;
  double pan = 0.0;
  Object tag;

  // TODO: Implement completion callback. On completion, sounds should
  // also be removed from the list of playing sounds.
  SoundCompleteCallback callback;

  MediaPlayerProxy _player;
}

SoundPool _sharedSoundPool;

class SoundPool {

  static SoundPool sharedInstance() {
    if (_sharedSoundPool == null) {
      _sharedSoundPool = new SoundPool();
    }
    return _sharedSoundPool;
  }

  SoundPool() {
    _mediaService = new MediaServiceProxy.unbound();
    shell.requestService(null, _mediaService);
  }

  MediaServiceProxy _mediaService;
  List<SoundStream> _playingSounds = [];

  // TODO: This should no longer be needed when moving to SoundPool backing
  Map<SoundEffect,MediaPlayerProxy> _mediaPlayers = {};

  Future _prepare(SoundStream playingSound) async {
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

  SoundStream play(
    SoundEffect sound,
    [Object tag,
      bool loop = false,
      double volume = 1.0,
      double pitch = 1.0,
      double pan = 0.0,
      double startTime = 0.0,
      SoundCompleteCallback callback = null]) {

    // Create new PlayingSound object
    SoundStream playingSound = new SoundStream(
      sound,
      tag,
      loop,
      startTime,
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
        playingSound._player.ptr.seekTo((startTime * 1000.0).toInt());
        playingSound._player.ptr.start();
      });

      _playingSounds.add(playingSound);
      _mediaPlayers[sound] = playingSound._player;
    } else {
      // Reuse player
      playingSound._player = _mediaPlayers[sound];
      playingSound._player.ptr.seekTo((startTime * 1000.0).toInt());
      playingSound._player.ptr.start();
    }

    return playingSound;
  }

  void stop(Object tag) {
    for (int i = _playingSounds.length; i >= 0; i--) {
      SoundStream playingSound = _playingSounds[i];
      if (playingSound.tag == tag) {
        playingSound._player.ptr.pause();
        _playingSounds.removeAt(i);
      }
    }
  }

  List<SoundStream> playingSoundsForTag(Object tag) {
    List<SoundStream> list = [];
    for (SoundStream playingSound in _playingSounds) {
      if (playingSound.tag == tag) {
        list.add(playingSound);
      }
    }
    return list;
  }

  void stopAll() {
    for (SoundStream playingSound in _playingSounds) {
      playingSound._player.ptr.pause();
    }
    _playingSounds = [];
  }
}
