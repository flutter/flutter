import 'dart:async';

import 'package:inject/inject.dart';

import 'electric_heater.dart';
import 'heater.dart';
import 'pump.dart';
import 'thermosiphon.dart';

// Examples of a named/qualified globally scoped token for injection.
const Qualifier brandName = Qualifier(#brandName);
const Qualifier modelName = Qualifier(#modelName);

/// Provides various objects to create a drip coffee brewer.
@module
class DripCoffeeModule {
  /// An example of a provider that uses a [Qualifier].
  @provide
  @brandName
  String provideBrand() => 'Coffee by FLUTTER Inc.';

  /// Also a qualified provider.
  ///
  /// Just like [provideBrand], it also returns a `String`. The qualifier
  /// `modelName` is used to distinguish between this provider and
  /// [provideBrand].
  @provide
  @modelName
  String provideModel() => 'DripCoffeeStandard';

  /// This demonstrates that a dependency can be instantiated asynchronously
  /// (even though there's no need for it in this artificial example).
  ///
  /// An asynchronous dependency is returned by a provider as a [Future], and
  /// is annotated with `@asynchronous`. This tell the injection framework that
  /// it needs to `await` on this dependency before instantiating other objects
  /// that depend on it. In our example, [provideElectricity] depends on
  /// [PowerOutlet]. Note that [provideElectricity] is not aware of the
  /// asynchronous nature of [PowerOutlet]. This feature allows you to switch
  /// between synchronous and asynchronous providers without a major refactoring
  /// downstream.
  @provide
  @asynchronous
  Future<PowerOutlet> providePowerOutlet() async => PowerOutlet();

  /// An example of a singleton provider.
  ///
  /// Calling it multiple times will return the same instance.
  @provide
  @singleton
  Electricity provideElectricity(PowerOutlet outlet) => Electricity(outlet);

  /// Another example of an asynchronous dependency.
  ///
  /// Note that this provider depends on the synchronously provided
  /// [Electricity], which in turn depends on asynchronously provided
  /// [PowerOutlet]. The big point here is that _a provider does not need to be
  /// aware of how its dependencies are resolved_.
  @provide
  @asynchronous
  Future<Heater> provideHeater(Electricity e) async => ElectricHeater(e);

  /// A most basic provider that provides synchronously instantiated
  /// non-singleton [Heater] objects.
  @provide
  Pump providePump(Heater heater) => Thermosiphon(heater);
}
