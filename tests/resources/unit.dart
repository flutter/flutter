
import "dart:sky.internals" as internals;

import 'package:sky/mojo/shell.dart' as shell;
import 'package:mojom/sky/test_harness.mojom.dart';

import "third_party/unittest/unittest.dart";

void notifyTestComplete(String result) {
  TestHarnessProxy test_harness = new TestHarnessProxy.unbound();
  shell.requestService("mojo:sky_viewer", test_harness);
  test_harness.ptr.onTestComplete(result, null);
  test_harness.close();

  internals.notifyTestComplete("DONE");
}

class _SkyConfig extends SimpleConfiguration {
  void onDone(bool success) {
    try {
      super.onDone(success);
    } catch (ex) {
      print(ex.toString());
    }

    notifyTestComplete("DONE");
  }
}

final _singleton = new _SkyConfig();

void initUnit() {
  unittestConfiguration = _singleton;
}
