import 'package:inject/inject.dart';

import 'heater.dart';
import 'pump.dart';

class Thermosiphon implements Pump {
  final Heater _heater;

  @provide
  Thermosiphon(this._heater);

  @override
  void pump() {
    if (_heater.isHot) {
      print('pumping water');
    }
  }
}