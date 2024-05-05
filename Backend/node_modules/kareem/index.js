'use strict';

/**
 * Create a new instance
 */
function Kareem() {
  this._pres = new Map();
  this._posts = new Map();
}

Kareem.skipWrappedFunction = function skipWrappedFunction() {
  if (!(this instanceof Kareem.skipWrappedFunction)) {
    return new Kareem.skipWrappedFunction(...arguments);
  }

  this.args = [...arguments];
};

Kareem.overwriteResult = function overwriteResult() {
  if (!(this instanceof Kareem.overwriteResult)) {
    return new Kareem.overwriteResult(...arguments);
  }

  this.args = [...arguments];
};

/**
 * Execute all "pre" hooks for "name"
 * @param {String} name The hook name to execute
 * @param {*} context Overwrite the "this" for the hook
 * @param {Array|Function} args Optional arguments or directly the callback
 * @param {Function} [callback] The callback to call when executing all hooks are finished
 * @returns {void}
 */
Kareem.prototype.execPre = function(name, context, args, callback) {
  if (arguments.length === 3) {
    callback = args;
    args = [];
  }
  const pres = this._pres.get(name) || [];
  const numPres = pres.length;
  const numAsyncPres = pres.numAsync || 0;
  let currentPre = 0;
  let asyncPresLeft = numAsyncPres;
  let done = false;
  const $args = args;
  let shouldSkipWrappedFunction = null;

  if (!numPres) {
    return nextTick(function() {
      callback(null);
    });
  }

  function next() {
    if (currentPre >= numPres) {
      return;
    }
    const pre = pres[currentPre];

    if (pre.isAsync) {
      const args = [
        decorateNextFn(_next),
        decorateNextFn(function(error) {
          if (error) {
            if (done) {
              return;
            }
            if (error instanceof Kareem.skipWrappedFunction) {
              shouldSkipWrappedFunction = error;
            } else {
              done = true;
              return callback(error);
            }
          }
          if (--asyncPresLeft === 0 && currentPre >= numPres) {
            return callback(shouldSkipWrappedFunction);
          }
        })
      ];

      callMiddlewareFunction(pre.fn, context, args, args[0]);
    } else if (pre.fn.length > 0) {
      const args = [decorateNextFn(_next)];
      const _args = arguments.length >= 2 ? arguments : [null].concat($args);
      for (let i = 1; i < _args.length; ++i) {
        if (i === _args.length - 1 && typeof _args[i] === 'function') {
          continue; // skip callbacks to avoid accidentally calling the callback from a hook
        }
        args.push(_args[i]);
      }

      callMiddlewareFunction(pre.fn, context, args, args[0]);
    } else {
      let maybePromiseLike = null;
      try {
        maybePromiseLike = pre.fn.call(context);
      } catch (err) {
        if (err != null) {
          return callback(err);
        }
      }

      if (isPromiseLike(maybePromiseLike)) {
        maybePromiseLike.then(() => _next(), err => _next(err));
      } else {
        if (++currentPre >= numPres) {
          if (asyncPresLeft > 0) {
            // Leave parallel hooks to run
            return;
          } else {
            return nextTick(function() {
              callback(shouldSkipWrappedFunction);
            });
          }
        }
        next();
      }
    }
  }

  next.apply(null, [null].concat(args));

  function _next(error) {
    if (error) {
      if (done) {
        return;
      }
      if (error instanceof Kareem.skipWrappedFunction) {
        shouldSkipWrappedFunction = error;
      } else {
        done = true;
        return callback(error);
      }
    }

    if (++currentPre >= numPres) {
      if (asyncPresLeft > 0) {
        // Leave parallel hooks to run
        return;
      } else {
        return callback(shouldSkipWrappedFunction);
      }
    }

    next.apply(context, arguments);
  }
};

/**
 * Execute all "pre" hooks for "name" synchronously
 * @param {String} name The hook name to execute
 * @param {*} context Overwrite the "this" for the hook
 * @param {Array} [args] Apply custom arguments to the hook
 * @returns {void}
 */
Kareem.prototype.execPreSync = function(name, context, args) {
  const pres = this._pres.get(name) || [];
  const numPres = pres.length;

  for (let i = 0; i < numPres; ++i) {
    pres[i].fn.apply(context, args || []);
  }
};

/**
 * Execute all "post" hooks for "name"
 * @param {String} name The hook name to execute
 * @param {*} context Overwrite the "this" for the hook
 * @param {Array|Function} args Apply custom arguments to the hook
 * @param {*} options Optional options or directly the callback
 * @param {Function} [callback] The callback to call when executing all hooks are finished
 * @returns {void}
 */
Kareem.prototype.execPost = function(name, context, args, options, callback) {
  if (arguments.length < 5) {
    callback = options;
    options = null;
  }
  const posts = this._posts.get(name) || [];
  const numPosts = posts.length;
  let currentPost = 0;

  let firstError = null;
  if (options && options.error) {
    firstError = options.error;
  }

  if (!numPosts) {
    return nextTick(function() {
      callback.apply(null, [firstError].concat(args));
    });
  }

  function next() {
    const post = posts[currentPost].fn;
    let numArgs = 0;
    const argLength = args.length;
    const newArgs = [];
    for (let i = 0; i < argLength; ++i) {
      numArgs += args[i] && args[i]._kareemIgnore ? 0 : 1;
      if (!args[i] || !args[i]._kareemIgnore) {
        newArgs.push(args[i]);
      }
    }

    if (firstError) {
      if (isErrorHandlingMiddleware(posts[currentPost], numArgs)) {
        const _cb = decorateNextFn(function(error) {
          if (error) {
            if (error instanceof Kareem.overwriteResult) {
              args = error.args;
              if (++currentPost >= numPosts) {
                return callback.call(null, firstError);
              }
              return next();
            }
            firstError = error;
          }
          if (++currentPost >= numPosts) {
            return callback.call(null, firstError);
          }
          next();
        });

        callMiddlewareFunction(post, context,
          [firstError].concat(newArgs).concat([_cb]), _cb);
      } else {
        if (++currentPost >= numPosts) {
          return callback.call(null, firstError);
        }
        next();
      }
    } else {
      const _cb = decorateNextFn(function(error) {
        if (error) {
          if (error instanceof Kareem.overwriteResult) {
            args = error.args;
            if (++currentPost >= numPosts) {
              return callback.apply(null, [null].concat(args));
            }
            return next();
          }
          firstError = error;
          return next();
        }

        if (++currentPost >= numPosts) {
          return callback.apply(null, [null].concat(args));
        }

        next();
      });

      if (isErrorHandlingMiddleware(posts[currentPost], numArgs)) {
        // Skip error handlers if no error
        if (++currentPost >= numPosts) {
          return callback.apply(null, [null].concat(args));
        }
        return next();
      }
      if (post.length === numArgs + 1) {
        callMiddlewareFunction(post, context, newArgs.concat([_cb]), _cb);
      } else {
        let error;
        let maybePromiseLike;
        try {
          maybePromiseLike = post.apply(context, newArgs);
        } catch (err) {
          error = err;
          firstError = err;
        }

        if (isPromiseLike(maybePromiseLike)) {
          return maybePromiseLike.then(
            (res) => {
              _cb(res instanceof Kareem.overwriteResult ? res : null);
            },
            err => _cb(err)
          );
        }

        if (maybePromiseLike instanceof Kareem.overwriteResult) {
          args = maybePromiseLike.args;
        }

        if (++currentPost >= numPosts) {
          return callback.apply(null, [error].concat(args));
        }

        next();
      }
    }
  }

  next();
};

/**
 * Execute all "post" hooks for "name" synchronously
 * @param {String} name The hook name to execute
 * @param {*} context Overwrite the "this" for the hook
 * @param {Array|Function} args Apply custom arguments to the hook
 * @returns {Array} The used arguments
 */
Kareem.prototype.execPostSync = function(name, context, args) {
  const posts = this._posts.get(name) || [];
  const numPosts = posts.length;

  for (let i = 0; i < numPosts; ++i) {
    const res = posts[i].fn.apply(context, args || []);
    if (res instanceof Kareem.overwriteResult) {
      args = res.args;
    }
  }

  return args;
};

/**
 * Create a synchronous wrapper for "fn"
 * @param {String} name The name of the hook
 * @param {Function} fn The function to wrap
 * @returns {Function} The wrapped function
 */
Kareem.prototype.createWrapperSync = function(name, fn) {
  const _this = this;
  return function syncWrapper() {
    _this.execPreSync(name, this, arguments);

    const toReturn = fn.apply(this, arguments);

    const result = _this.execPostSync(name, this, [toReturn]);

    return result[0];
  };
};

function _handleWrapError(instance, error, name, context, args, options, callback) {
  if (options.useErrorHandlers) {
    return instance.execPost(name, context, args, { error: error }, function(error) {
      return typeof callback === 'function' && callback(error);
    });
  } else {
    return typeof callback === 'function' && callback(error);
  }
}

/**
 * Executes pre hooks, followed by the wrapped function, followed by post hooks.
 * @param {String} name The name of the hook
 * @param {Function} fn The function for the hook
 * @param {*} context Overwrite the "this" for the hook
 * @param {Array} args Apply custom arguments to the hook
 * @param {Object} [options]
 * @param {Boolean} [options.checkForPromise]
 * @returns {void}
 */
Kareem.prototype.wrap = function(name, fn, context, args, options) {
  const lastArg = (args.length > 0 ? args[args.length - 1] : null);
  const argsWithoutCb = Array.from(args);
  typeof lastArg === 'function' && argsWithoutCb.pop();
  const _this = this;

  options = options || {};
  const checkForPromise = options.checkForPromise;

  this.execPre(name, context, args, function(error) {
    if (error && !(error instanceof Kareem.skipWrappedFunction)) {
      const numCallbackParams = options.numCallbackParams || 0;
      const errorArgs = options.contextParameter ? [context] : [];
      for (let i = errorArgs.length; i < numCallbackParams; ++i) {
        errorArgs.push(null);
      }
      return _handleWrapError(_this, error, name, context, errorArgs,
        options, lastArg);
    }

    const numParameters = fn.length;
    let ret;

    if (error instanceof Kareem.skipWrappedFunction) {
      ret = error.args[0];
      return _cb(null, ...error.args);
    } else {
      try {
        ret = fn.apply(context, argsWithoutCb.concat(_cb));
      } catch (err) {
        return _cb(err);
      }
    }

    if (checkForPromise) {
      if (isPromiseLike(ret)) {
        // Thenable, use it
        return ret.then(
          res => _cb(null, res),
          err => _cb(err)
        );
      }

      // If `fn()` doesn't have a callback argument and doesn't return a
      // promise, assume it is sync
      if (numParameters < argsWithoutCb.length + 1) {
        return _cb(null, ret);
      }
    }

    function _cb() {
      const argsWithoutError = Array.from(arguments);
      argsWithoutError.shift();
      if (options.nullResultByDefault && argsWithoutError.length === 0) {
        argsWithoutError.push(null);
      }
      if (arguments[0]) {
        // Assume error
        return _handleWrapError(_this, arguments[0], name, context,
          argsWithoutError, options, lastArg);
      } else {
        _this.execPost(name, context, argsWithoutError, function() {
          if (lastArg === null) {
            return;
          }
          arguments[0]
            ? lastArg(arguments[0])
            : lastArg.apply(context, arguments);
        });
      }
    }
  });
};

/**
 * Filter current instance for something specific and return the filtered clone
 * @param {Function} fn The filter function
 * @returns {Kareem} The cloned and filtered instance
 */
Kareem.prototype.filter = function(fn) {
  const clone = this.clone();

  const pres = Array.from(clone._pres.keys());
  for (const name of pres) {
    const hooks = this._pres.get(name).
      map(h => Object.assign({}, h, { name: name })).
      filter(fn);

    if (hooks.length === 0) {
      clone._pres.delete(name);
      continue;
    }

    hooks.numAsync = hooks.filter(h => h.isAsync).length;

    clone._pres.set(name, hooks);
  }

  const posts = Array.from(clone._posts.keys());
  for (const name of posts) {
    const hooks = this._posts.get(name).
      map(h => Object.assign({}, h, { name: name })).
      filter(fn);

    if (hooks.length === 0) {
      clone._posts.delete(name);
      continue;
    }

    clone._posts.set(name, hooks);
  }

  return clone;
};

/**
 * Check for a "name" to exist either in pre or post hooks
 * @param {String} name The name of the hook
 * @returns {Boolean} "true" if found, "false" otherwise
 */
Kareem.prototype.hasHooks = function(name) {
  return this._pres.has(name) || this._posts.has(name);
};

/**
 * Create a Wrapper for "fn" on "name" and return the wrapped function
 * @param {String} name The name of the hook
 * @param {Function} fn The function to wrap
 * @param {*} context Overwrite the "this" for the hook
 * @param {Object} [options]
 * @returns {Function} The wrapped function
 */
Kareem.prototype.createWrapper = function(name, fn, context, options) {
  const _this = this;
  if (!this.hasHooks(name)) {
    // Fast path: if there's no hooks for this function, just return the
    // function wrapped in a nextTick()
    return function() {
      nextTick(() => fn.apply(this, arguments));
    };
  }
  return function() {
    const _context = context || this;
    _this.wrap(name, fn, _context, Array.from(arguments), options);
  };
};

/**
 * Register a new hook for "pre"
 * @param {String} name The name of the hook
 * @param {Boolean} [isAsync]
 * @param {Function} fn The function to register for "name"
 * @param {never} error Unused
 * @param {Boolean} [unshift] Wheter to "push" or to "unshift" the new hook
 * @returns {Kareem}
 */
Kareem.prototype.pre = function(name, isAsync, fn, error, unshift) {
  let options = {};
  if (typeof isAsync === 'object' && isAsync !== null) {
    options = isAsync;
    isAsync = options.isAsync;
  } else if (typeof arguments[1] !== 'boolean') {
    fn = isAsync;
    isAsync = false;
  }

  const pres = this._pres.get(name) || [];
  this._pres.set(name, pres);

  if (isAsync) {
    pres.numAsync = pres.numAsync || 0;
    ++pres.numAsync;
  }

  if (typeof fn !== 'function') {
    throw new Error('pre() requires a function, got "' + typeof fn + '"');
  }

  if (unshift) {
    pres.unshift(Object.assign({}, options, { fn: fn, isAsync: isAsync }));
  } else {
    pres.push(Object.assign({}, options, { fn: fn, isAsync: isAsync }));
  }

  return this;
};

/**
 * Register a new hook for "post"
 * @param {String} name The name of the hook
 * @param {Object} [options]
 * @param {Function} fn The function to register for "name"
 * @param {Boolean} [unshift] Wheter to "push" or to "unshift" the new hook
 * @returns {Kareem}
 */
Kareem.prototype.post = function(name, options, fn, unshift) {
  const posts = this._posts.get(name) || [];

  if (typeof options === 'function') {
    unshift = !!fn;
    fn = options;
    options = {};
  }

  if (typeof fn !== 'function') {
    throw new Error('post() requires a function, got "' + typeof fn + '"');
  }

  if (unshift) {
    posts.unshift(Object.assign({}, options, { fn: fn }));
  } else {
    posts.push(Object.assign({}, options, { fn: fn }));
  }
  this._posts.set(name, posts);
  return this;
};

/**
 * Clone the current instance
 * @returns {Kareem} The cloned instance
 */
Kareem.prototype.clone = function() {
  const n = new Kareem();

  for (const key of this._pres.keys()) {
    const clone = this._pres.get(key).slice();
    clone.numAsync = this._pres.get(key).numAsync;
    n._pres.set(key, clone);
  }
  for (const key of this._posts.keys()) {
    n._posts.set(key, this._posts.get(key).slice());
  }

  return n;
};

/**
 * Merge "other" into self or "clone"
 * @param {Kareem} other The instance to merge with
 * @param {Kareem} [clone] The instance to merge onto (if not defined, using "this")
 * @returns {Kareem} The merged instance
 */
Kareem.prototype.merge = function(other, clone) {
  clone = arguments.length === 1 ? true : clone;
  const ret = clone ? this.clone() : this;

  for (const key of other._pres.keys()) {
    const sourcePres = ret._pres.get(key) || [];
    const deduplicated = other._pres.get(key).
      // Deduplicate based on `fn`
      filter(p => sourcePres.map(_p => _p.fn).indexOf(p.fn) === -1);
    const combined = sourcePres.concat(deduplicated);
    combined.numAsync = sourcePres.numAsync || 0;
    combined.numAsync += deduplicated.filter(p => p.isAsync).length;
    ret._pres.set(key, combined);
  }
  for (const key of other._posts.keys()) {
    const sourcePosts = ret._posts.get(key) || [];
    const deduplicated = other._posts.get(key).
      filter(p => sourcePosts.indexOf(p) === -1);
    ret._posts.set(key, sourcePosts.concat(deduplicated));
  }

  return ret;
};

function callMiddlewareFunction(fn, context, args, next) {
  let maybePromiseLike;
  try {
    maybePromiseLike = fn.apply(context, args);
  } catch (error) {
    return next(error);
  }

  if (isPromiseLike(maybePromiseLike)) {
    maybePromiseLike.then(() => next(), err => next(err));
  }
}

function isPromiseLike(v) {
  return (typeof v === 'object' && v !== null && typeof v.then === 'function');
}

function decorateNextFn(fn) {
  let called = false;
  const _this = this;
  return function() {
    // Ensure this function can only be called once
    if (called) {
      return;
    }
    called = true;
    // Make sure to clear the stack so try/catch doesn't catch errors
    // in subsequent middleware
    return nextTick(() => fn.apply(_this, arguments));
  };
}

const nextTick = typeof process === 'object' && process !== null && process.nextTick || function nextTick(cb) {
  setTimeout(cb, 0);
};

function isErrorHandlingMiddleware(post, numArgs) {
  if (post.errorHandler) {
    return true;
  }
  return post.fn.length === numArgs + 2;
}

module.exports = Kareem;
