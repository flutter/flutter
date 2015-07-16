part of sprites;

typedef void ActionCallback();

abstract class Action {
  Object _tag;
  bool _finished = false;
  bool _added = false;

  void step(double dt);
  void update(double t) {
  }

  void _reset() {
    _finished = false;
  }

  double get duration => 0.0;
}

abstract class ActionInterval extends Action {
  double _duration;

  bool _firstTick = true;
  double _elapsed = 0.0;

  double get duration => _duration;
  Curve curve;

  ActionInterval([this._duration = 0.0, this.curve]);

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

    if (curve == null) {
      update(t);
    } else {
      update(curve.transform(t));
    }

    if (t >= 1.0) _finished = true;
  }
}

class ActionRepeat extends ActionInterval {
  final int numRepeats;
  final ActionInterval action;
  int _lastFinishedRepeat = -1;

  ActionRepeat(this.action, this.numRepeats) {
    _duration = action.duration * numRepeats;
  }

  void update(double t) {
    int currentRepeat = math.min((t * numRepeats.toDouble()).toInt(), numRepeats - 1);
    for (int i = math.max(_lastFinishedRepeat, 0); i < currentRepeat; i++) {
      if (!action._finished) action.update(1.0);
      action._reset();
    }
    _lastFinishedRepeat = currentRepeat;

    double ta = (t * numRepeats.toDouble()) % 1.0;
    action.update(ta);

    if (t >= 1.0) {
      action.update(1.0);
      action._finished = true;
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
      if (!action._finished) action.update(1.0);
      action._reset();
    }
    _elapsedInAction = math.max(_elapsedInAction, 0.0);

    double t;
    if (action._duration == 0.0) {
      t = 1.0;
    } else {
      t = (_elapsedInAction / action._duration).clamp(0.0, 1.0);
    }

    action.update(t);
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
      _updateWithCurve(_a, ta);
    } else if (t >= 1.0) {
      // Make sure everything is finished
      if (!_a._finished) _finish(_a);
      if (!_b._finished) _finish(_b);
    } else {
      // Play second action, but first make sure the first has finished
      if (!_a._finished) _finish(_a);
      double tb;
      if (_split < 1.0) {
        tb = (1.0 - (1.0 - t) / (1.0 - _split)).clamp(0.0, 1.0);
      } else {
        tb = 1.0;
      }
      _updateWithCurve(_b, tb);
    }
  }

  void _updateWithCurve(Action action, double t) {
    if (action is ActionInterval) {
      ActionInterval actionInterval = action;
      if (actionInterval.curve == null) {
        action.update(t);
      } else {
        action.update(actionInterval.curve.transform(t));
      }
    } else {
      action.update(t);
    }

    if (t >= 1.0) {
      action._finished = true;
    }
  }

  void _finish(Action action) {
    action.update(1.0);
    action._finished = true;
  }

  void _reset() {
    super._reset();
    _a._reset();
    _b._reset();
  }
}

class ActionGroup extends ActionInterval {
  List<Action> _actions;

  ActionGroup(this._actions) {
    for (Action action in _actions) {
      if (action.duration > _duration) {
        _duration = action.duration;
      }
    }
  }

  void update(double t) {
    if (t >= 1.0) {
      // Finish all unfinished actions
      for (Action action in _actions) {
        if (!action._finished) {
          action.update(1.0);
          action._finished = true;
        }
      }
    } else {
      for (Action action in _actions) {
        if (action.duration == 0.0) {
          // Fire all instant actions immediately
          if (!action._finished) {
            action.update(1.0);
            action._finished = true;
          }
        } else {
          // Update child actions
          double ta = (t / (action.duration / duration)).clamp(0.0, 1.0);
          if (ta < 1.0) {
            if (action is ActionInterval) {
              ActionInterval actionInterval = action;
              if (actionInterval.curve == null) {
                action.update(ta);
              } else {
                action.update(actionInterval.curve.transform(ta));
              }
            } else {
              action.update(ta);
            }
          } else if (!action._finished){
            action.update(1.0);
            action._finished = true;
          }
        }
      }
    }
  }

  void _reset() {
    for (Action action in _actions) {
      action._reset();
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

class ActionTween extends ActionInterval {
  final Function setter;
  final startVal;
  final endVal;

  var _delta;

  ActionTween(this.setter, this.startVal, this.endVal, double duration, [Curve curve]) : super(duration, curve) {
    _computeDelta();
  }

  void _computeDelta() {
    if (startVal is Point) {
      // Point
      double xStart = startVal.x;
      double yStart = startVal.y;
      double xEnd = endVal.x;
      double yEnd = endVal.y;
      _delta = new Point(xEnd - xStart, yEnd - yStart);
    } else if (startVal is Size) {
      // Size
      double wStart = startVal.width;
      double hStart = startVal.height;
      double wEnd = endVal.width;
      double hEnd = endVal.height;
      _delta = new Size(wEnd - wStart, hEnd - hStart);
    } else if (startVal is Rect) {
      // Rect
      double lStart = startVal.left;
      double tStart = startVal.top;
      double rStart = startVal.right;
      double bStart = startVal.bottom;
      double lEnd = endVal.left;
      double tEnd = endVal.top;
      double rEnd = endVal.right;
      double bEnd = endVal.bottom;
      _delta = new Rect.fromLTRB(lEnd - lStart, tEnd - tStart, rEnd - rStart, bEnd - bStart);
    } else if (startVal is double) {
      // Double
      _delta = endVal - startVal;
    } else if (startVal is Color) {
      // Color
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
    } else if (startVal is Size) {
      // Size
      double wStart = startVal.width;
      double hStart = startVal.height;
      double wDelta = _delta.width;
      double hDelta = _delta.height;
      newVal = new Size(wStart + wDelta * t, hStart + hDelta * t);
    } else if (startVal is Rect) {
      // Rect
      double lStart = startVal.left;
      double tStart = startVal.top;
      double rStart = startVal.right;
      double bStart = startVal.bottom;
      double lDelta = _delta.left;
      double tDelta = _delta.top;
      double rDelta = _delta.right;
      double bDelta = _delta.bottom;
      newVal = new Rect.fromLTRB(lStart + lDelta * t, tStart + tDelta * t, rStart + rDelta * t, bStart + bDelta * t);
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
    assert(!action._added);

    action._tag = tag;
    action._added = true;
    action.update(0.0);
    _actions.add(action);
  }

  void stop(Action action) {
    if (_actions.remove(action)) {
      action._added = false;
      action._reset();
    }
  }

  void _stopAtIndex(int i) {
    Action action = _actions[i];
    action._added = false;
    action._reset();
    _actions.removeAt(i);
  }

  void stopWithTag(Object tag) {
    for (int i = _actions.length - 1; i >= 0; i--) {
      Action action = _actions[i];
      if (action._tag == tag) {
        _stopAtIndex(i);
      }
    }
  }

  void stopAll() {
    for (int i = _actions.length - 1; i >= 0; i--) {
      _stopAtIndex(i);
    }
  }

  void step(double dt) {
    for (int i = _actions.length - 1; i >= 0; i--) {
      Action action = _actions[i];
      action.step(dt);

      if (action._finished) {
        action._added = false;
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

double _bounce(double t)
{
  if (t < 1.0 / 2.75) {
    return 7.5625 * t * t;
  } else if (t < 2 / 2.75) {
    t -= 1.5 / 2.75;
    return 7.5625 * t * t + 0.75;
  } else if (t < 2.5 / 2.75) {
    t -= 2.25 / 2.75;
    return 7.5625 * t * t + 0.9375;
  }
  t -= 2.625 / 2.75;
  return 7.5625 * t * t + 0.984375;
}

class BounceOutCurve implements Curve {
  const BounceOutCurve();

  double transform(double t) {
    return _bounce(t);
  }
}

const BounceOutCurve bounceOut = const BounceOutCurve();
