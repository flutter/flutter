library inject.example.coffee;

import 'package:inject/inject.dart';

// This is a compile-time generated file and does not exist in source.
import 'coffee.inject.dart' as generated;
import 'drip_coffee_module.dart';
import 'coffee_maker.dart';

export 'coffee_maker.dart';
export 'drip_coffee_module.dart';
export 'electric_heater.dart';
export 'heater.dart';

/// An example injector class.
///
/// This injector uses [DripCoffeeModule] as a source of dependency providers.
@Injector(<Type>[DripCoffeeModule])
abstract class Coffee {
  /// A generated `async` static function, which takes a [DripCoffeeModule] and
  /// asynchronously returns an instance of [Coffee].
  static const Future<Coffee> Function(DripCoffeeModule) create = generated.Coffee$Injector.create;

  /// An accessor to an object that an application may use.
  @provide
  CoffeeMaker getCoffeeMaker();
}