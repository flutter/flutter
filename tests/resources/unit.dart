import "third_party/unittest/unittest.dart";
import "dart:sky.internals" as internals;

class _SkyConfig extends SimpleConfiguration {
  void onDone(bool success) {
    try {
      super.onDone(success);
    } catch (ex) {
      print(ex.toString());
    }

    internals.notifyTestComplete("DONE");
  }
}

final _singleton = new _SkyConfig();

void initUnit() {
  unittestConfiguration = _singleton;
}
