// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'coffee_app.dart';
import 'src/coffee.dart';

Future<void> main() async {
  final CoffeeApp coffeeApp = await CoffeeApp.create(PourOverCoffeeModule());
  final CoffeeMaker coffeeMaker = coffeeApp.getCoffeeMaker();
  coffeeMaker.brew();
}