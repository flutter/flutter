import 'package:process_run/process_run.dart';
import 'package:test/test.dart';

void main() {
  test('run', () async {
    await run('echo test');
  });
}
