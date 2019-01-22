import 'package:inject/inject.dart';

import 'drip_coffee_module.dart';
import 'heater.dart';
import 'pump.dart';

class CoffeeMaker {
  @provide
  CoffeeMaker(this._heater, this._pump, this._brand, this._model);

  final Heater _heater;
  final Pump _pump;

  @modelName
  final String _model;

  @brandName
  final String _brand;

  void brew() {
    _heater.on();
    _pump.pump();
    print(' [_]P coffee! [_]P');
    print(' Thanks for using $_model by $_brand');
    _heater.off();
  }
}