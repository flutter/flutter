import 'package:recase/recase.dart';

void main() {
  final sw = Stopwatch()..start();
  String? result = null;
  const N = 10000;
  for (var i = 0; i < N; i++) {
    result = ReCase('This is-Some_sampleText. YouDig?').titleCase;
  }
  print(
      'done in ${sw.elapsedMilliseconds} (${sw.elapsedMilliseconds / N} ms. per iteration)');
  print('$result');
}
