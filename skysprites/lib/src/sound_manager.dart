part of flutter_sprites;

enum SoundFadeMode {
  crossFade,
  fadeOutThenPlay,
  fadeOutThenFadeIn,
}

enum SoundEventSimultaneousPolicy {
  dontPlay,
  stopOldest,
}

enum SoundEventMinimumOverlapPolicy {
  dontPlay,
  delay,
}

class SoundEvent {
  SoundEvent(SoundEffect effect) {
    effects = <SoundEffect>[effect];
  }

  SoundEvent.withList(this.effects);

  List<SoundEffect> effects;
  double pitchVariance = 0.0;
  double volumeVariance = 0.0;
  double panVariance = 0.0;

  SoundEventSimultaneousPolicy simultaneousLimitPolicy = SoundEventSimultaneousPolicy.stopOldest;
  int simultaneousLimit = 0;

  SoundEventMinimumOverlapPolicy minimumOverlapPolicy = SoundEventMinimumOverlapPolicy.dontPlay;
  double minimumOverlap = 0.0;
}

class _PlayingSoundEvent {
  SoundEvent event;
  SoundEffectStream stream;
  int startTime;
}

SoundManager _sharedSoundManager;

class SoundManager {

  static SoundManager sharedInstance() {
    if (_sharedSoundManager == null) {
      _sharedSoundManager = new SoundManager();
    }
    return _sharedSoundManager;
  }

  static void purgeSharedInstance() {
    if (_sharedSoundManager == null) return;
    _sharedSoundManager = null;
  }

  SoundManager() {
    new Timer.periodic(new Duration(milliseconds:10), _update);
  }

  Map<SoundEvent, List<_PlayingSoundEvent>> _playingEvents = <SoundEvent, List<_PlayingSoundEvent>>{};
  SoundTrack _backgroundMusicTrack;

  SoundEffectPlayer _effectPlayer = SoundEffectPlayer.sharedInstance();
  SoundTrackPlayer _trackPlayer = SoundTrackPlayer.sharedInstance();
  ActionController actions = new ActionController();

  bool enableBackgroundMusic;
  bool enableSoundEffects;

  int _lastTimeStamp;

  void playEvent(SoundEvent evt, [double volume = 1.0, double pitch = 1.0, double pan = 0.0]) {
    List<_PlayingSoundEvent> playingList = _playingEvents[evt];
    if (playingList == null) playingList = <_PlayingSoundEvent>[];

    // Check simultaneousLimit
    if (evt.simultaneousLimit != 0 && evt.simultaneousLimit >= playingList.length) {
      // We have too many sounds playing
      if (evt.simultaneousLimitPolicy == SoundEventSimultaneousPolicy.dontPlay) {
        // Skip this sound event
        return;
      } else {
        // Stop the oldest sound
        _effectPlayer.stop(playingList[0].stream);
      }
    }

    // Check for overlap
    int playTime = new DateTime.now().millisecondsSinceEpoch;

    if (evt.minimumOverlap != 0.0 && playingList.length > 0) {
      int overlap = playTime - playingList.last.startTime;
      if (overlap.toDouble() / 1000.0 < evt.minimumOverlap) {
        // Sounds are overlapping
        if (evt.minimumOverlapPolicy == SoundEventMinimumOverlapPolicy.dontPlay) {
          return;
        } else {
          // TODO: try to play the sound a little bit later
          return;
        }
      }
    }

    // Create a new entry for the event
    _PlayingSoundEvent newPlaying = new _PlayingSoundEvent();
    newPlaying.startTime = playTime;
    newPlaying.event = evt;

    // Pick a sound effect to play
    SoundEffect effect = evt.effects.elementAt(randomInt(evt.effects.length));

    // Add the entry
    playingList.add(newPlaying);

    // Play the event
    newPlaying.stream = _effectPlayer.play(
      effect,
      false,
      (volume + evt.volumeVariance * randomSignedDouble()).clamp(0.0, 2.0),
      (pitch + evt.pitchVariance * randomSignedDouble()).clamp(0.5, 2.0),
      (pan + evt.panVariance * randomSignedDouble()).clamp(-1.0, 1.0),
      (SoundEffectStream s) {
        // Completion callback - remove the entry
        playingList.remove(newPlaying);
      }
    );
  }

  void stopAllEvents([double fadeDuration]) {
    for (List<_PlayingSoundEvent> playingList in _playingEvents.values) {
      for (_PlayingSoundEvent playing in playingList) {
        if (fadeDuration > 0.0) {
          // Fade out and stop
          ActionTween fadeOut = new ActionTween((a) => playing.stream.volume = a, playing.stream.volume, 0.0, fadeDuration);
          ActionCallFunction stop = new ActionCallFunction(() { _effectPlayer.stop(playing.stream); });
          ActionSequence seq = new ActionSequence(<Action>[fadeOut, stop]);
          actions.run(seq);
        }
        else {
          // Stop right away
          _effectPlayer.stop(playing.stream);
        }
      }
    }
  }

  void playBackgroundMusic(SoundTrack track, [double fadeDuration = 0.0, SoundFadeMode fadeMode = SoundFadeMode.fadeOutThenPlay]) {
    double fadeInDuration = 0.0;
    double fadeInDelay = 0.0;
    double fadeOutDuration = 0.0;

    // Calculate durations
    if (fadeDuration > 0.0) {
      if (fadeMode == SoundFadeMode.crossFade) {
        fadeOutDuration = fadeDuration;
        fadeInDuration = fadeDuration;
      } else if (fadeMode == SoundFadeMode.fadeOutThenPlay) {
        fadeOutDuration = fadeDuration;
        fadeInDelay = fadeDuration;
      } else if (fadeMode == SoundFadeMode.fadeOutThenFadeIn) {
        fadeOutDuration = fadeDuration / 2.0;
        fadeInDuration = fadeDuration / 2.0;
        fadeInDelay = fadeDuration / 2.0;
      }
    }

    if (_backgroundMusicTrack != null) {
      // Stop the current track
      if (fadeOutDuration == 0.0) {
        _trackPlayer.stop(_backgroundMusicTrack);
      } else {
        ActionTween fadeOut = new ActionTween((a) => _backgroundMusicTrack.volume = a, _backgroundMusicTrack.volume, 0.0, fadeOutDuration);
        ActionCallFunction stop = new ActionCallFunction(() { _trackPlayer.stop(_backgroundMusicTrack); });
        ActionSequence seq = new ActionSequence(<Action>[fadeOut, stop]);
        actions.run(seq);
      }
    } else {
      fadeInDelay = 0.0;
    }

    // Fade in new sound
    if (fadeInDelay == 0.0) {
      _fadeInTrack(track, fadeInDuration);
    } else {
      ActionDelay delay = new ActionDelay(fadeInDelay);
      ActionCallFunction fadeInCall = new ActionCallFunction(() {
        _fadeInTrack(track, fadeInDuration);
      });
      ActionSequence seq = new ActionSequence(<Action>[delay, fadeInCall]);
      actions.run(seq);
    }
  }

  void _fadeInTrack(SoundTrack track, double duration) {
    _backgroundMusicTrack = track;

    if (duration == 0.0) {
      _trackPlayer.play(track);
    } else {
      _trackPlayer.play(track, true, 0.0);
      actions.run(new ActionTween((a) => track.volume = a, 0.0, 1.0, duration));
    }
  }

  void stopBackgroundMusic([double fadeDuration = 0.0]) {
    if (fadeDuration == 0.0) {
      _trackPlayer.stop(_backgroundMusicTrack);
    } else {
      ActionTween fadeOut = new ActionTween(
        (a) => _backgroundMusicTrack.volume = a,
        _backgroundMusicTrack.volume, 0.0, fadeDuration);
      ActionCallFunction stopCall = new ActionCallFunction(() {
        _trackPlayer.stop(_backgroundMusicTrack);
      });
      ActionSequence seq = new ActionSequence(<Action>[fadeOut, stopCall]);
      actions.run(seq);
    }

    _backgroundMusicTrack = null;
  }

  void _update(Timer timer) {
    int delta = 0;
    int timestamp = new DateTime.now().millisecondsSinceEpoch;
    if (_lastTimeStamp != null) {
      delta = timestamp - _lastTimeStamp;
    }
    _lastTimeStamp = timestamp;

    actions.step(delta / 1000.0);
  }
}
