// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:inject/inject.dart';

// This is a compile-time generated file and does not exist in source.
import 'coffee_app.inject.dart' as generated; // ignore: uri_does_not_exist
import 'src/coffee.dart';

@module
class PourOverCoffeeModule {
  @provide
  @brandName
  String provideBrand() => 'Coffee by Flutter Inc.';

  @provide
  @modelName
  String provideModel() => 'PourOverSupremeFiesta';

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

@Injector(<Type>[PourOverCoffeeModule])
abstract class CoffeeApp {
  static final Future<CoffeeApp> Function(PourOverCoffeeModule) create = generated.CoffeeApp$Injector.create;

  @provide
  CoffeeMaker getCoffeeMaker();
}
