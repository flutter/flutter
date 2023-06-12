import 'package:cli_util/cli_logging.dart';

export 'package:cli_util/cli_logging.dart' show Progress;

/// Flutter Launcher Icons Logger
class FLILogger {
  late Logger _logger;

  /// Returns true if this is a verbose logger
  final bool isVerbose;

  /// Gives access to internal logger
  Logger get rawLogger => _logger;

  /// Creates a instance of [FLILogger].
  /// In case [isVerbose] is `true`,
  /// it logs all the [verbose] logs to console
  FLILogger(this.isVerbose) {
    final ansi = Ansi(Ansi.terminalSupportsAnsi);
    _logger =
        isVerbose ? Logger.verbose(ansi: ansi) : Logger.standard(ansi: ansi);
  }

  /// Logs error messages
  void error(Object? message) => _logger.stderr('⚠️' + message.toString());

  /// Prints to console if [isVerbose] is true
  void verbose(Object? message) => _logger.trace(message.toString());

  /// Prints to console
  void info(Object? message) => _logger.stdout(message.toString());

  /// Shows progress in console
  Progress progress(String message) => _logger.progress(message);
}
