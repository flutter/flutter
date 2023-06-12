/// This enum is meant to be used as a parameter of the AudioPlayer's
/// constructor. It represents the general mode of the AudioPlayer.
///
// In iOS and macOS, both modes have the same backend implementation.
enum PlayerMode {
  /// Ideal for long media files or streams.
  MEDIA_PLAYER,

  /// Ideal for short audio files, since it reduces the impacts on visuals or
  /// UI performance.
  ///
  /// In this mode the backend won't fire any duration or position updates.
  /// Also, it is not possible to use the seek method to set the audio a
  /// specific position.
  LOW_LATENCY,
}
