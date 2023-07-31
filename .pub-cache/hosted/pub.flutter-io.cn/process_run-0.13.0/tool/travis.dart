import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();
  await shell.run('''
# Format
dart format --set-exit-if-changed -o none .

# Analyze code
dart analyze --fatal-warnings --fatal-infos .

# Run tests
pub run test -p vm -r expanded

# Run tests using build_runner
pub run build_runner test -- -p vm -r expanded

''');
}
