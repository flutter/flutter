// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of newton;

/// Simulates kinetic scrolling behavior between a leading and trailing
/// boundary. Friction is applied within the extends and a spring action applied
/// at the boundaries. This simulation can only step forward.
class Scroll extends SimulationGroup {
  final double _leadingExtent;
  final double _trailingExtent;
  final SpringDesc _springDesc;
  final double _drag;

  bool _isSpringing = false;
  Simulation _currentSimulation;

  Scroll(double position, double velocity, double leading, double trailing,
      SpringDesc spring, double drag)
      : _leadingExtent = leading,
        _trailingExtent = trailing,
        _springDesc = spring,
        _drag = drag {
    _chooseSimulation(position, velocity);
  }

  @override
  void step(double time) => _chooseSimulation(
      _currentSimulation.x(time), _currentSimulation.dx(time));

  @override
  Simulation get currentSimulation => _currentSimulation;

  void _chooseSimulation(double position, double velocity) {
    /// This simulation can only step forward
    if (!_isSpringing) {
      if (position > _trailingExtent) {
        _isSpringing = true;
        _currentSimulation =
            new Spring(_springDesc, position, _trailingExtent, velocity);
      } else if (position < _leadingExtent) {
        _isSpringing = true;
        _currentSimulation =
            new Spring(_springDesc, position, _leadingExtent, velocity);
      }
    } else if (_currentSimulation == null) {
      _currentSimulation = new Friction(_drag, position, velocity);
    }
  }
}
