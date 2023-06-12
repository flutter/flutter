/// Indicates the state of the audio player.
enum PlayerState {
  /// initial state, stop has been called or an error occurred.
  STOPPED,

  /// Currently playing audio.
  PLAYING,

  /// Pause has been called.
  PAUSED,

  /// The audio successfully completed (reached the end).
  COMPLETED,
}
