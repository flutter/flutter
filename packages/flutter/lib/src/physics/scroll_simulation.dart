// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'friction_simulation.dart';
import 'simulation_group.dart';
import 'simulation.dart';
import 'spring_simulation.dart';

/// Composite simulation for scrollable interfaces.
///
/// Simulates kinetic scrolling behavior between a leading and trailing
/// boundary. Friction is applied within the extents and a spring action is
/// applied at the boundaries. This simulation can only step forward.
class ScrollSimulation extends SimulationGroup {
  /// Creates a [ScrollSimulation] with the given parameters.
  ///
  /// The position and velocity arguments must use the same units as will be
  /// expected from the [x] and [dx] methods respectively.
  ///
  /// The leading and trailing extents must use the unit of length, the same
  /// unit as used for the position argument and as expected from the [x]
  /// method.
  ///
  /// The units used with the provided [SpringDescription] must similarly be
  /// consistent with the other arguments.
  ///
  /// The final argument is the coefficient of friction, which is unitless.
  ScrollSimulation(
    double position,
    double velocity,
    this._leadingExtent,
    this._trailingExtent,
    this._spring,
    this._drag) {
    _chooseSimulation(position, velocity, 0.0);
  }

  final double _leadingExtent;
  final double _trailingExtent;
  final SpringDescription _spring;
  final double _drag;

  bool _isSpringing = false;
  Simulation _currentSimulation;
  double _offset = 0.0;

  @override
  bool step(double time) => _chooseSimulation(
      _currentSimulation.x(time - _offset),
      _currentSimulation.dx(time - _offset), time);

  @override
  Simulation get currentSimulation => _currentSimulation;

  @override
  double get currentIntervalOffset => _offset;

  bool _chooseSimulation(double position, double velocity, double intervalOffset) {
    if (_spring == null && (position > _trailingExtent || position < _leadingExtent))
      return false;

    // This simulation can only step forward.
    if (!_isSpringing) {
      if (position > _trailingExtent) {
        _isSpringing = true;
        _offset = intervalOffset;
        _currentSimulation = new ScrollSpringSimulation(_spring, position, _trailingExtent, velocity);
        return true;
      } else if (position < _leadingExtent) {
        _isSpringing = true;
        _offset = intervalOffset;
        _currentSimulation = new ScrollSpringSimulation(_spring, position, _leadingExtent, velocity);
        return true;
      }
    }

    if (_currentSimulation == null) {
      _currentSimulation = new FrictionSimulation(_drag, position, velocity);
      return true;
    }

    return false;
  }

  @override
  String toString() {
    return 'ScrollSimulation(leadingExtent: $_leadingExtent, trailingExtent: $_trailingExtent)';
  }
}
