import 'heater.dart';

class PowerOutlet {}

class Electricity {
  Electricity(PowerOutlet outlet);
}

class ElectricHeater implements Heater {
  ElectricHeater(Electricity electricity);

  bool _heating = false;

  @override
  void on() {
    print('heating');
    _heating = true;
  }

  @override
  void off() {
    _heating = false;
  }

  @override
  bool get isHot => _heating;
}