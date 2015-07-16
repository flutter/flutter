import "dart:sky.internals" as internals;

import 'package:sky/mojo/shell.dart' as shell;
import 'package:mojom/sky/test_harness.mojom.dart';

void notifyTestComplete(String result) {
  TestHarnessProxy test_harness = new TestHarnessProxy.unbound();
  shell.requestService("mojo:sky_viewer", test_harness);
  test_harness.ptr.onTestComplete(result, null);
  test_harness.close();

  // FIXME(eseidel): Remove this once all tests run in sky_shell.
  internals.notifyTestComplete(result);
}
