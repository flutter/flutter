import 'package:pedantic/pedantic.dart';

void main() async {
  // Normally, calling a function that returns a Future from an async method
  // would require you to ignore the unawaited_futures lint with this analyzer
  // syntax:
  //
  // ignore: unawaited_futures
  doSomethingAsync();

  // Wrapping it in a call to `unawaited` avoids that, since it doesn't
  // return a Future. This is more explicit, and harder to get wrong.
  unawaited(doSomethingAsync());
}

Future<void> doSomethingAsync() async {}
