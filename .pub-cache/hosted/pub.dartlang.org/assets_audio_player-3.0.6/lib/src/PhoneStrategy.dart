enum HeadPhoneStrategy { none, pauseOnUnplug, pauseOnUnplugPlayOnPlug }

String describeHeadPhoneStrategy(HeadPhoneStrategy strategy) {
  switch (strategy) {
    case HeadPhoneStrategy.none:
      return 'none';
    case HeadPhoneStrategy.pauseOnUnplug:
      return 'pauseOnUnplug';
    case HeadPhoneStrategy.pauseOnUnplugPlayOnPlug:
      return 'pauseOnUnplugPlayOnPlug';
  }
}

class AudioFocusStrategy {
  final bool request;
  final bool resumeAfterInterruption;
  final bool resumeOthersPlayersAfterDone;

  /// Don't request focus
  AudioFocusStrategy.none()
      : request = false,
        resumeAfterInterruption = false,
        resumeOthersPlayersAfterDone = false;

  /// Request focus
  ///
  /// resumeAfterInterruption : When other app request focus (phone call, other player like spotify play), pause the AssetMediaPlayer
  ///
  /// resumeOthersPlayersAfterDone : When this player finish to play, tell others native players (like spotify), to resume
  const AudioFocusStrategy.request(
      {this.resumeAfterInterruption = false,
      this.resumeOthersPlayersAfterDone = false})
      : request = true;
}

Map<String, dynamic> describeAudioFocusStrategy(AudioFocusStrategy strategy) {
  return {
    'request': strategy.request,
    'resumeAfterInterruption': strategy.resumeAfterInterruption,
    'resumeOthersPlayersAfterDone': strategy.resumeOthersPlayersAfterDone,
  };
}
