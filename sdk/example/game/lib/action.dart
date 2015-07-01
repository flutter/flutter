part of sprites;

typedef void PointSetter(Point point);

abstract class Action {
  bool _finished = false;

  void step(double dt);
  void update(double t) {
  }
}

abstract class ActionInterval extends Action {
  double _duration;

  bool _firstTick = true;
  double _elapsed = 0.0;

  double get duration => _duration;

  ActionInterval([this._duration = 0.0]);

  void step(double dt) {
    if (_firstTick) {
      _firstTick = false;
    } else {
      _elapsed += dt;
    }

    double t;
    if (this._duration == 0.0) {
      t = 1.0;
    } else {
      t = (_elapsed / _duration).clamp(0.0, 1.0);
    }

    update(t);

    if (t >= 1.0) _finished = true;
  }
}

class ActionRepeat extends ActionInterval {
  final int numRepeats;
  final ActionInterval action;

  ActionRepeat(this.action, this.numRepeats) {
    _duration = action.duration * numRepeats;
  }

  void update(double t) {
    action.update((t * numRepeats.toDouble()) % numRepeats.toDouble());
  }
}

// TODO: Implement
class ActionSequence extends ActionInterval {
  final List<ActionInterval> actions;

  ActionSequence(this.actions) {
    for (Action action in actions) {
      _duration += action._duration;
    }
  }
}

class ActionRepeatForever extends Action {
  final ActionInterval action;
  double _elapsedInAction = 0.0;

  ActionRepeatForever(this.action);

  step(double dt) {
    _elapsedInAction += dt;
    while (_elapsedInAction > action.duration) {
      _elapsedInAction -= action.duration;
    }
    _elapsedInAction = Math.max(_elapsedInAction, 0.0);

    double t;
    if (action._duration == 0.0) {
      t = 1.0;
    } else {
      t = (_elapsedInAction / action._duration).clamp(0.0, 1.0);
    }

    action.update(t);
  }
}

class ActionTween extends ActionInterval {
  final Function setter;
  final startVal;
  final endVal;

  var _delta;

  ActionTween(this.setter, this.startVal, this.endVal, double duration) : super(duration) {
    _computeDelta();
  }

  void _computeDelta() {
    if (startVal is Point) {
      double xStart = startVal.x;
      double yStart = startVal.y;
      double xEnd = endVal.x;
      double yEnd = endVal.y;
      _delta = new Point(xEnd - xStart, yEnd - yStart);
    } else if (startVal is double) {
      _delta = endVal - startVal;
    } else {
      assert(false);
    }
  }

  void update(double t) {
    var newVal;

    if (startVal is Point) {
      double xStart = startVal.x;
      double yStart = startVal.y;
      double xDelta = _delta.x;
      double yDelta = _delta.y;

      newVal = new Point(xStart + xDelta * t, yStart + yDelta * t);
    } else if (startVal is double) {
      newVal = startVal + _delta * t;
    } else {
      assert(false);
    }

    setter(newVal);
  }
}

class ActionController {

  List<Action> _actions = [];

  ActionController();

  void run(Action action) {
    _actions.add(action);
  }

  void step(double dt) {
    for (int i = _actions.length - 1; i >= 0; i--) {
      Action action = _actions[i];
      action.step(dt);

      if (action._finished) {
        _actions.removeAt(i);
      }
    }
  }
}