import 'package:logging/logging.dart';

final log = Logger('ExampleLogger');

/// Example of configuring a logger to print to stdout.
///
/// This example will print:
///
/// INFO: 2021-09-13 15:35:10.703401: recursion: n = 4
/// INFO: 2021-09-13 15:35:10.707974: recursion: n = 3
/// Fibonacci(4) is: 3
/// Fibonacci(5) is: 5
/// SHOUT: 2021-09-13 15:35:10.708087: Unexpected negative n: -42
/// Fibonacci(-42) is: 1
void main() {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  print('Fibonacci(4) is: ${fibonacci(4)}');

  Logger.root.level = Level.SEVERE; // skip logs less then severe.
  print('Fibonacci(5) is: ${fibonacci(5)}');

  print('Fibonacci(-42) is: ${fibonacci(-42)}');
}

int fibonacci(int n) {
  if (n <= 2) {
    if (n < 0) log.shout('Unexpected negative n: $n');
    return 1;
  } else {
    log.info('recursion: n = $n');
    return fibonacci(n - 2) + fibonacci(n - 1);
  }
}
