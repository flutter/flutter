// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:inject/inject.dart';

const Qualifier brandName = Qualifier(#brandName);
const Qualifier modelName = Qualifier(#modelName);

class CoffeeMaker {
  @provide
  CoffeeMaker(this._heater, this._pump, this._brand, this._model);

  final Heater _heater;
  final Pump _pump;

  @modelName
  final String _model;

  @brandName
  final String _brand;

  String brew() {
    _heater.on();
    _pump.pump();
    print(' [_]P coffee! [_]P');
    final String message = 'Thanks for using $_model by $_brand';
    _heater.off();
    return message;
  }
}

abstract class Heater {
  void on();
  void off();
  bool get isHot;
}

abstract class Pump {
  void pump();
}
