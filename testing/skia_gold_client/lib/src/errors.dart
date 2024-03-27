/// Skia Gold errors thrown by intepreting process exits and [stdout]/[stderr].
final class SkiaGoldProcessError extends Error {
  /// Creates a new [SkiaGoldProcessError] from the provided origin.
  ///
  /// - [command] is the command that was executed.
  /// - [stdout] is the result of the process's standard output.
  /// - [stderr] is the result of the process's standard error.
  ///
  /// Optionally, [message] as context for the error.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final io.ProcessResult result = await _runCommand(someCommand);
  /// if (result.exitCode != 0) {
  ///   throw SkiaGoldProcessError(
  ///     command: someCommand,
  ///     stdout: result.stdout.toString(),
  ///     stderr: result.stderr.toString(),
  ///     message: 'Authentication failed <or whatever we were doing>',
  ///   );
  /// }
  /// ```
  SkiaGoldProcessError({
    required Iterable<String> command,
    required this.stdout,
    required this.stderr,
    this.message,
  }) : command = List<String>.unmodifiable(command);

  /// Optional message to include as context for the error.
  final String? message;

  /// Command that was executed.
  final List<String> command;

  /// The result of the process's standard output.
  final String stdout;

  /// The result of the process's standard error.
  final String stderr;

  @override
  String toString() {
    return <String>[
      'Error when running Skia Gold: ${command.join(' ')}',
      if (message != null) message!,
      '',
      'stdout: $stdout',
      'stderr: $stderr',
    ].join('\n');
  }
}

/// Error thrown when the Skia Gold process exits due to a negative image.
final class SkiaGoldNegativeImageError extends SkiaGoldProcessError {
  /// Creates a new [SkiaGoldNegativeImageError] from the provided origin.
  ///
  /// See [SkiaGoldProcessError.new] for more information.
  SkiaGoldNegativeImageError({
    required this.testName,
    required super.command,
    required super.stdout,
    required super.stderr,
  });

  /// Name of the test that produced the negative image.
  final String testName;

  @override
  String get message => 'Negative image detected for test: "$testName".\n\n'
      'The flutter/engine workflow should never produce negative images; it is '
      'possible that someone accidentally (or without knowing our policy) '
      'marked a test as negative.\n\n'
      'See https://github.com/flutter/flutter/issues/145043 for details.';
}
