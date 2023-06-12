import 'package:cli_util/cli_util.dart';

void main() {
  try {
    print(applicationConfigHome('dart'));
  } on EnvironmentNotFoundException catch (e) {
    print('Caught: $e');
  }
}
