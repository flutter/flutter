import 'globals.dart';
import 'stdio.dart' show Stdio;

/// Interface for shared functionality across all sub-commands.
///
/// Different frontends (e.g. CLI vs desktop) can share [Context]s, although
/// methods for capturing user interaction may be overridden.
abstract class Context {
  const Context();

  /// Confirm an action with the user before proceeding.
  ///
  /// The default implementation reads from STDIN. This can be overriden in UI
  /// implementations that capture user interaction differently.
  bool prompt(String message, Stdio stdio) {
    stdio.write('${message.trim()} (y/n) ');
    final String response = stdio.readLineSync().trim();
    final String firstChar = response[0].toUpperCase();
    if (firstChar == 'Y') {
      return true;
    }
    if (firstChar == 'N') {
      return false;
    }
    throw ConductorException(
      'Unknown user input (expected "y" or "n"): $response',
    );
  }
}
