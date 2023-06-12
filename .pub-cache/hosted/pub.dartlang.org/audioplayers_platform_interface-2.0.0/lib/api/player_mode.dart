/// This represents what kind of native implementation is used by the player.
///
/// Currently, this distinction is only relevant for Android.
enum PlayerMode {
  /// Ideal for long media files or streams.
  mediaPlayer,

  /// Ideal for short audio files, since it reduces the impacts on visuals or
  /// UI performance.
  ///
  /// In this mode the backend won't fire any duration or position updates.
  /// Also, it is not possible to use the seek method to set the audio a
  /// specific position.
  lowLatency,
}
