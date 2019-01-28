import 'package:inject/inject.dart';

// This is a compile-time generated file and does not exist in source.
import 'coffee_app.inject.dart' as generated;
import 'src/coffee.dart';

@module
class PourOverCoffeeModule {
  @provide
  @brandName
  String provideBrand() => 'Coffee by Flutter Inc.';

  @provide
  @modelName
  String provideModel() => 'PourOverSupreme';

  @provide
  @asynchronous
  Future<Heater> provideHeater() async => Stove();

  @provide
  Pump providePump(Heater heater) => NoOpPump();
}

class NoOpPump extends Pump {
  @override
  void pump() {
    print('nothing to pump...');
  }
}

class Stove extends Heater {
  @override
  bool get isHot => _isHot;
  bool _isHot = false;

  @override
  void off() {
    _isHot = true;
  }

  @override
  void on() {
    _isHot = true;
  }
}

@Injector([PourOverCoffeeModule])
abstract class CoffeeApp {
  static final create = generated.Coffee$Injector.create;

  @provide
  CoffeeMaker getCoffeeMaker();
}