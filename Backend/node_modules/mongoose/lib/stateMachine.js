
/*!
 * Module dependencies.
 */

'use strict';

const utils = require('./utils'); // eslint-disable-line no-unused-vars

/**
 * StateMachine represents a minimal `interface` for the
 * constructors it builds via StateMachine.ctor(...).
 *
 * @api private
 */

const StateMachine = module.exports = exports = function StateMachine() {
};

/**
 * StateMachine.ctor('state1', 'state2', ...)
 * A factory method for subclassing StateMachine.
 * The arguments are a list of states. For each state,
 * the constructor's prototype gets state transition
 * methods named after each state. These transition methods
 * place their path argument into the given state.
 *
 * @param {String} state
 * @param {String} [state]
 * @return {Function} subclass constructor
 * @api private
 */

StateMachine.ctor = function() {
  const states = [...arguments];

  const ctor = function() {
    StateMachine.apply(this, arguments);
    this.paths = {};
    this.states = {};
  };

  ctor.prototype = new StateMachine();

  ctor.prototype.stateNames = states;

  states.forEach(function(state) {
    // Changes the `path`'s state to `state`.
    ctor.prototype[state] = function(path) {
      this._changeState(path, state);
    };
  });

  return ctor;
};

/**
 * This function is wrapped by the state change functions:
 *
 * - `require(path)`
 * - `modify(path)`
 * - `init(path)`
 *
 * @api private
 */

StateMachine.prototype._changeState = function _changeState(path, nextState) {
  const prevState = this.paths[path];
  if (prevState === nextState) {
    return;
  }
  const prevBucket = this.states[prevState];
  if (prevBucket) delete prevBucket[path];

  this.paths[path] = nextState;
  this.states[nextState] = this.states[nextState] || {};
  this.states[nextState][path] = true;
};

/*!
 * ignore
 */

StateMachine.prototype.clear = function clear(state) {
  if (this.states[state] == null) {
    return;
  }
  const keys = Object.keys(this.states[state]);
  let i = keys.length;
  let path;

  while (i--) {
    path = keys[i];
    delete this.states[state][path];
    delete this.paths[path];
  }
};

/*!
 * ignore
 */

StateMachine.prototype.clearPath = function clearPath(path) {
  const state = this.paths[path];
  if (!state) {
    return;
  }
  delete this.paths[path];
  delete this.states[state][path];
};

/**
 * Gets the paths for the given state, or empty object `{}` if none.
 * @api private
 */

StateMachine.prototype.getStatePaths = function getStatePaths(state) {
  if (this.states[state] != null) {
    return this.states[state];
  }
  return {};
};

/**
 * Checks to see if at least one path is in the states passed in via `arguments`
 * e.g., this.some('required', 'inited')
 *
 * @param {String} state that we want to check for.
 * @api private
 */

StateMachine.prototype.some = function some() {
  const _this = this;
  const what = arguments.length ? arguments : this.stateNames;
  return Array.prototype.some.call(what, function(state) {
    if (_this.states[state] == null) {
      return false;
    }
    return Object.keys(_this.states[state]).length;
  });
};

/**
 * This function builds the functions that get assigned to `forEach` and `map`,
 * since both of those methods share a lot of the same logic.
 *
 * @param {String} iterMethod is either 'forEach' or 'map'
 * @return {Function}
 * @api private
 */

StateMachine.prototype._iter = function _iter(iterMethod) {
  return function() {
    let states = [...arguments];
    const callback = states.pop();

    if (!states.length) states = this.stateNames;

    const _this = this;

    const paths = states.reduce(function(paths, state) {
      if (_this.states[state] == null) {
        return paths;
      }
      return paths.concat(Object.keys(_this.states[state]));
    }, []);

    return paths[iterMethod](function(path, i, paths) {
      return callback(path, i, paths);
    });
  };
};

/**
 * Iterates over the paths that belong to one of the parameter states.
 *
 * The function profile can look like:
 * this.forEach(state1, fn);         // iterates over all paths in state1
 * this.forEach(state1, state2, fn); // iterates over all paths in state1 or state2
 * this.forEach(fn);                 // iterates over all paths in all states
 *
 * @param {String} [state]
 * @param {String} [state]
 * @param {Function} callback
 * @api private
 */

StateMachine.prototype.forEach = function forEach() {
  this.forEach = this._iter('forEach');
  return this.forEach.apply(this, arguments);
};

/**
 * Maps over the paths that belong to one of the parameter states.
 *
 * The function profile can look like:
 * this.forEach(state1, fn);         // iterates over all paths in state1
 * this.forEach(state1, state2, fn); // iterates over all paths in state1 or state2
 * this.forEach(fn);                 // iterates over all paths in all states
 *
 * @param {String} [state]
 * @param {String} [state]
 * @param {Function} callback
 * @return {Array}
 * @api private
 */

StateMachine.prototype.map = function map() {
  this.map = this._iter('map');
  return this.map.apply(this, arguments);
};
