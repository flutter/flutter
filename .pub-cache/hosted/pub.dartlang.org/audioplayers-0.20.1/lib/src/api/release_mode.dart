/// This enum is meant to be used as a parameter of setReleaseMode method.
///
/// It represents the behaviour of AudioPlayer when an audio is finished or
/// stopped.
enum ReleaseMode {
  /// Releases all resources, just like calling release method.
  ///
  /// In Android, the media player is quite resource-intensive, and this will
  /// let it go. Data will be buffered again when needed (if it's a remote file,
  /// it will be downloaded again).
  /// In iOS and macOS, works just like stop method.
  ///
  /// This is the default behaviour.
  RELEASE,

  /// Keeps buffered data and plays again after completion, creating a loop.
  /// Notice that calling stop method is not enough to release the resources
  /// when this mode is being used.
  LOOP,

  /// Stops audio playback but keep all resources intact.
  /// Use this if you intend to play again later.
  STOP,
}
