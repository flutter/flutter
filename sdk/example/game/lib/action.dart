part of sprites;

typedef void ActionCallback();

abstract class Action {
  Object _tag;
  bool _finished = false;

  void step(double dt);
  void update(double t) {
  }

  double get duration => 0.0;
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

class ActionSequence extends ActionInterval {
  Action _a;
  Action _b;
  double _split;

  ActionSequence(List<Action> actions) {
    assert(actions.length >= 2);

    if (actions.length == 2) {
      // Base case
      _a = actions[0];
      _b = actions[1];
    } else {
      _a = actions[0];
      _b = new ActionSequence(actions.sublist(1));
    }

    // Calculate split and duration
    _duration = _a.duration + _b.duration;
    if (_duration > 0) {
      _split = _a.duration / _duration;
    } else {
      _split = 1.0;
    }
  }

  void update(double t) {
    if (t < _split) {
      // Play first action
      double ta;
      if (_split > 0.0) {
        ta = (t / _split).clamp(0.0, 1.0);
      } else {
        ta = 1.0;
      }
      _a.update(ta);
    } else if (t >= 1.0) {
      // Make sure everything is finished
      if (!_a._finished) _a.update(1.0);
      if (!_b._finished) _b.update(1.0);
    } else {
      // Play second action, but first make sure the first has finished
      if (!_a._finished) _a.update(1.0);
      double tb;
      if (_split < 1.0) {
        tb = (1.0 - (1.0 - t) / (1.0 - _split)).clamp(0.0, 1.0);
      } else {
        tb = 1.0;
      }
      _b.update(tb);
    }
  }
}

abstract class ActionInstant extends Action {

  void step(double dt) {
  }

  void update(double t) {
    fire();
    _finished = true;
  }

  void fire();
}

class ActionCallFunction extends ActionInstant {
  ActionCallback _function;

  ActionCallFunction(this._function);

  void fire() {
    _function();
  }
}

class ActionRemoveNode extends ActionInstant {
  Node _node;

  ActionRemoveNode(this._node);

  void fire() {
    _node.removeFromParent();
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
    } else if (startVal is Color) {
      int aDelta = endVal.alpha - startVal.alpha;
      int rDelta = endVal.red - startVal.red;
      int gDelta = endVal.green - startVal.green;
      int bDelta = endVal.blue - startVal.blue;
      _delta = new _ColorDiff(aDelta, rDelta, gDelta, bDelta);
    } else {
      assert(false);
    }
  }

  void update(double t) {
    var newVal;

    if (startVal is Point) {
      // Point
      double xStart = startVal.x;
      double yStart = startVal.y;
      double xDelta = _delta.x;
      double yDelta = _delta.y;
      newVal = new Point(xStart + xDelta * t, yStart + yDelta * t);
    } else if (startVal is double) {
      // Doubles
      newVal = startVal + _delta * t;
    } else if (startVal is Color) {
      // Colors
      int aNew = (startVal.alpha + (_delta.alpha * t).toInt()).clamp(0, 255);
      int rNew = (startVal.red + (_delta.red * t).toInt()).clamp(0, 255);
      int gNew = (startVal.green + (_delta.green * t).toInt()).clamp(0, 255);
      int bNew = (startVal.blue + (_delta.blue * t).toInt()).clamp(0, 255);
      newVal = new Color.fromARGB(aNew, rNew, gNew, bNew);
    } else {
      // Oopses
      assert(false);
    }

    setter(newVal);
  }
}

class ActionController {

  List<Action> _actions = [];

  ActionController();

  void run(Action action, [Object tag]) {
    action._tag = tag;
    action.update(0.0);
    _actions.add(action);
  }

  void stop(Action action) {
    _actions.remove(action);
  }

  void stopWithTag(Object tag) {
    for (int i = _actions.length - 1; i >= 0; i--) {
      Action action = _actions[i];
      if (action._tag == tag) {
        _actions.removeAt(i);
        print("removing tag: $tag");
      }
    }
  }

  void stopAll() {
    _actions.clear();
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

class _ColorDiff {
  final int alpha;
  final int red;
  final int green;
  final int blue;

  _ColorDiff(this.alpha, this.red, this.green, this.blue);
}