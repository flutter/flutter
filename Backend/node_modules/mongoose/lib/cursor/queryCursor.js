/*!
 * Module dependencies.
 */

'use strict';

const MongooseError = require('../error/mongooseError');
const Readable = require('stream').Readable;
const eachAsync = require('../helpers/cursor/eachAsync');
const helpers = require('../queryHelpers');
const kareem = require('kareem');
const immediate = require('../helpers/immediate');
const util = require('util');

/**
 * A QueryCursor is a concurrency primitive for processing query results
 * one document at a time. A QueryCursor fulfills the Node.js streams3 API,
 * in addition to several other mechanisms for loading documents from MongoDB
 * one at a time.
 *
 * QueryCursors execute the model's pre `find` hooks before loading any documents
 * from MongoDB, and the model's post `find` hooks after loading each document.
 *
 * Unless you're an advanced user, do **not** instantiate this class directly.
 * Use [`Query#cursor()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.cursor()) instead.
 *
 * @param {Query} query
 * @param {Object} options query options passed to `.find()`
 * @inherits Readable https://nodejs.org/api/stream.html#class-streamreadable
 * @event `cursor`: Emitted when the cursor is created
 * @event `error`: Emitted when an error occurred
 * @event `data`: Emitted when the stream is flowing and the next doc is ready
 * @event `end`: Emitted when the stream is exhausted
 * @api public
 */

function QueryCursor(query) {
  // set autoDestroy=true because on node 12 it's by default false
  // gh-10902 need autoDestroy to destroy correctly and emit 'close' event
  Readable.call(this, { autoDestroy: true, objectMode: true });

  this.cursor = null;
  this.skipped = false;
  this.query = query;
  const model = query.model;
  this._mongooseOptions = {};
  this._transforms = [];
  this.model = model;
  this.options = {};
  model.hooks.execPre('find', query, (err) => {
    if (err != null) {
      if (err instanceof kareem.skipWrappedFunction) {
        const resultValue = err.args[0];
        if (resultValue != null && (!Array.isArray(resultValue) || resultValue.length)) {
          const err = new MongooseError(
            'Cannot `skipMiddlewareFunction()` with a value when using ' +
            '`.find().cursor()`, value must be nullish or empty array, got "' +
            util.inspect(resultValue) +
            '".'
          );
          this._markError(err);
          this.listeners('error').length > 0 && this.emit('error', err);
          return;
        }
        this.skipped = true;
        this.emit('cursor', null);
        return;
      }
      this._markError(err);
      this.listeners('error').length > 0 && this.emit('error', err);
      return;
    }
    Object.assign(this.options, query._optionsForExec());
    this._transforms = this._transforms.concat(query._transforms.slice());
    if (this.options.transform) {
      this._transforms.push(this.options.transform);
    }
    // Re: gh-8039, you need to set the `cursor.batchSize` option, top-level
    // `batchSize` option doesn't work.
    if (this.options.batchSize) {
      // Max out the number of documents we'll populate in parallel at 5000.
      this.options._populateBatchSize = Math.min(this.options.batchSize, 5000);
    }

    if (model.collection._shouldBufferCommands() && model.collection.buffer) {
      model.collection.queue.push([
        () => _getRawCursor(query, this)
      ]);
    } else {
      _getRawCursor(query, this);
    }
  });
}

util.inherits(QueryCursor, Readable);

/*!
 * ignore
 */

function _getRawCursor(query, queryCursor) {
  try {
    const cursor = query.model.collection.find(query._conditions, queryCursor.options);
    queryCursor.cursor = cursor;
    queryCursor.emit('cursor', cursor);
  } catch (err) {
    queryCursor._markError(err);
    queryCursor.listeners('error').length > 0 && queryCursor.emit('error', queryCursor._error);
  }
}

/**
 * Necessary to satisfy the Readable API
 * @method _read
 * @memberOf QueryCursor
 * @instance
 * @api private
 */

QueryCursor.prototype._read = function() {
  _next(this, (error, doc) => {
    if (error) {
      return this.emit('error', error);
    }
    if (!doc) {
      this.push(null);
      this.cursor.close(function(error) {
        if (error) {
          return this.emit('error', error);
        }
      });
      return;
    }
    this.push(doc);
  });
};

/**
 * Registers a transform function which subsequently maps documents retrieved
 * via the streams interface or `.next()`
 *
 * #### Example:
 *
 *     // Map documents returned by `data` events
 *     Thing.
 *       find({ name: /^hello/ }).
 *       cursor().
 *       map(function (doc) {
 *        doc.foo = "bar";
 *        return doc;
 *       })
 *       on('data', function(doc) { console.log(doc.foo); });
 *
 *     // Or map documents returned by `.next()`
 *     const cursor = Thing.find({ name: /^hello/ }).
 *       cursor().
 *       map(function (doc) {
 *         doc.foo = "bar";
 *         return doc;
 *       });
 *     cursor.next(function(error, doc) {
 *       console.log(doc.foo);
 *     });
 *
 * @param {Function} fn
 * @return {QueryCursor}
 * @memberOf QueryCursor
 * @api public
 * @method map
 */

Object.defineProperty(QueryCursor.prototype, 'map', {
  value: function(fn) {
    this._transforms.push(fn);
    return this;
  },
  enumerable: true,
  configurable: true,
  writable: true
});

/**
 * Marks this cursor as errored
 * @method _markError
 * @memberOf QueryCursor
 * @instance
 * @api private
 */

QueryCursor.prototype._markError = function(error) {
  this._error = error;
  return this;
};

/**
 * Marks this cursor as closed. Will stop streaming and subsequent calls to
 * `next()` will error.
 *
 * @return {Promise}
 * @api public
 * @method close
 * @emits close
 * @see AggregationCursor.close https://mongodb.github.io/node-mongodb-native/4.9/classes/AggregationCursor.html#close
 */

QueryCursor.prototype.close = async function close() {
  if (typeof arguments[0] === 'function') {
    throw new MongooseError('QueryCursor.prototype.close() no longer accepts a callback');
  }
  try {
    await this.cursor.close();
    this.emit('close');
  } catch (error) {
    this.listeners('error').length > 0 && this.emit('error', error);
    throw error;
  }
};

/**
 * Rewind this cursor to its uninitialized state. Any options that are present on the cursor will
 * remain in effect. Iterating this cursor will cause new queries to be sent to the server, even
 * if the resultant data has already been retrieved by this cursor.
 *
 * @return {AggregationCursor} this
 * @api public
 * @method rewind
 */

QueryCursor.prototype.rewind = function() {
  _waitForCursor(this, () => {
    this.cursor.rewind();
  });
  return this;
};

/**
 * Get the next document from this cursor. Will return `null` when there are
 * no documents left.
 *
 * @return {Promise}
 * @api public
 * @method next
 */

QueryCursor.prototype.next = async function next() {
  if (typeof arguments[0] === 'function') {
    throw new MongooseError('QueryCursor.prototype.next() no longer accepts a callback');
  }
  return new Promise((resolve, reject) => {
    _next(this, function(error, doc) {
      if (error) {
        return reject(error);
      }
      resolve(doc);
    });
  });
};

/**
 * Execute `fn` for every document in the cursor. If `fn` returns a promise,
 * will wait for the promise to resolve before iterating on to the next one.
 * Returns a promise that resolves when done.
 *
 * #### Example:
 *
 *     // Iterate over documents asynchronously
 *     Thing.
 *       find({ name: /^hello/ }).
 *       cursor().
 *       eachAsync(async function (doc, i) {
 *         doc.foo = doc.bar + i;
 *         await doc.save();
 *       })
 *
 * @param {Function} fn
 * @param {Object} [options]
 * @param {Number} [options.parallel] the number of promises to execute in parallel. Defaults to 1.
 * @param {Number} [options.batchSize] if set, will call `fn()` with arrays of documents with length at most `batchSize`
 * @param {Boolean} [options.continueOnError=false] if true, `eachAsync()` iterates through all docs even if `fn` throws an error. If false, `eachAsync()` throws an error immediately if the given function `fn()` throws an error.
 * @return {Promise}
 * @api public
 * @method eachAsync
 */

QueryCursor.prototype.eachAsync = function(fn, opts) {
  if (typeof arguments[2] === 'function') {
    throw new MongooseError('QueryCursor.prototype.eachAsync() no longer accepts a callback');
  }
  if (typeof opts === 'function') {
    opts = {};
  }
  opts = opts || {};

  return eachAsync((cb) => _next(this, cb), fn, opts);
};

/**
 * The `options` passed in to the `QueryCursor` constructor.
 *
 * @api public
 * @property options
 */

QueryCursor.prototype.options;

/**
 * Adds a [cursor flag](https://mongodb.github.io/node-mongodb-native/4.9/classes/FindCursor.html#addCursorFlag).
 * Useful for setting the `noCursorTimeout` and `tailable` flags.
 *
 * @param {String} flag
 * @param {Boolean} value
 * @return {AggregationCursor} this
 * @api public
 * @method addCursorFlag
 */

QueryCursor.prototype.addCursorFlag = function(flag, value) {
  _waitForCursor(this, () => {
    this.cursor.addCursorFlag(flag, value);
  });
  return this;
};

/*!
 * ignore
 */

QueryCursor.prototype.transformNull = function(val) {
  if (arguments.length === 0) {
    val = true;
  }
  this._mongooseOptions.transformNull = val;
  return this;
};

/*!
 * ignore
 */

QueryCursor.prototype._transformForAsyncIterator = function() {
  if (this._transforms.indexOf(_transformForAsyncIterator) === -1) {
    this.map(_transformForAsyncIterator);
  }
  return this;
};

/**
 * Returns an asyncIterator for use with [`for/await/of` loops](https://thecodebarbarian.com/getting-started-with-async-iterators-in-node-js).
 * You do not need to call this function explicitly, the JavaScript runtime
 * will call it for you.
 *
 * #### Example:
 *
 *     // Works without using `cursor()`
 *     for await (const doc of Model.find([{ $sort: { name: 1 } }])) {
 *       console.log(doc.name);
 *     }
 *
 *     // Can also use `cursor()`
 *     for await (const doc of Model.find([{ $sort: { name: 1 } }]).cursor()) {
 *       console.log(doc.name);
 *     }
 *
 * Node.js 10.x supports async iterators natively without any flags. You can
 * enable async iterators in Node.js 8.x using the [`--harmony_async_iteration` flag](https://github.com/tc39/proposal-async-iteration/issues/117#issuecomment-346695187).
 *
 * **Note:** This function is not if `Symbol.asyncIterator` is undefined. If
 * `Symbol.asyncIterator` is undefined, that means your Node.js version does not
 * support async iterators.
 *
 * @method [Symbol.asyncIterator]
 * @memberOf QueryCursor
 * @instance
 * @api public
 */

if (Symbol.asyncIterator != null) {
  QueryCursor.prototype[Symbol.asyncIterator] = function() {
    return this.transformNull()._transformForAsyncIterator();
  };
}

/*!
 * ignore
 */

function _transformForAsyncIterator(doc) {
  return doc == null ? { done: true } : { value: doc, done: false };
}

/**
 * Get the next doc from the underlying cursor and mongooseify it
 * (populate, etc.)
 * @param {Any} ctx
 * @param {Function} cb
 * @api private
 */

function _next(ctx, cb) {
  let callback = cb;
  if (ctx._transforms.length) {
    callback = function(err, doc) {
      if (err || (doc === null && !ctx._mongooseOptions.transformNull)) {
        return cb(err, doc);
      }
      cb(err, ctx._transforms.reduce(function(doc, fn) {
        return fn.call(ctx, doc);
      }, doc));
    };
  }

  if (ctx._error) {
    return immediate(function() {
      callback(ctx._error);
    });
  }
  if (ctx.skipped) {
    return immediate(() => callback(null, null));
  }

  if (ctx.cursor) {
    if (ctx.query._mongooseOptions.populate && !ctx._pop) {
      ctx._pop = helpers.preparePopulationOptionsMQ(ctx.query,
        ctx.query._mongooseOptions);
      ctx._pop.__noPromise = true;
    }
    if (ctx.query._mongooseOptions.populate && ctx.options._populateBatchSize > 1) {
      if (ctx._batchDocs && ctx._batchDocs.length) {
        // Return a cached populated doc
        return _nextDoc(ctx, ctx._batchDocs.shift(), ctx._pop, callback);
      } else if (ctx._batchExhausted) {
        // Internal cursor reported no more docs. Act the same here
        return callback(null, null);
      } else {
        // Request as many docs as batchSize, to populate them also in batch
        ctx._batchDocs = [];
        ctx.cursor.next().then(
          res => { _onNext.call({ ctx, callback }, null, res); },
          err => { _onNext.call({ ctx, callback }, err); }
        );
        return;
      }
    } else {
      return ctx.cursor.next().then(
        doc => {
          if (!doc) {
            callback(null, null);
            return;
          }

          if (!ctx.query._mongooseOptions.populate) {
            return _nextDoc(ctx, doc, null, callback);
          }

          ctx.query.model.populate(doc, ctx._pop).then(
            doc => {
              _nextDoc(ctx, doc, ctx._pop, callback);
            },
            err => {
              callback(err);
            }
          );
        },
        error => {
          callback(error);
        }
      );
    }
  } else {
    ctx.once('error', cb);

    ctx.once('cursor', function(cursor) {
      ctx.removeListener('error', cb);
      if (cursor == null) {
        if (ctx.skipped) {
          return cb(null, null);
        }
        return;
      }
      _next(ctx, cb);
    });
  }
}

/*!
 * ignore
 */

function _onNext(error, doc) {
  if (error) {
    return this.callback(error);
  }
  if (!doc) {
    this.ctx._batchExhausted = true;
    return _populateBatch.call(this);
  }

  this.ctx._batchDocs.push(doc);

  if (this.ctx._batchDocs.length < this.ctx.options._populateBatchSize) {
    // If both `batchSize` and `_populateBatchSize` are huge, calling `next()` repeatedly may
    // cause a stack overflow. So make sure we clear the stack regularly.
    if (this.ctx._batchDocs.length > 0 && this.ctx._batchDocs.length % 1000 === 0) {
      return immediate(() => this.ctx.cursor.next().then(
        res => { _onNext.call(this, null, res); },
        err => { _onNext.call(this, err); }
      ));
    }
    this.ctx.cursor.next().then(
      res => { _onNext.call(this, null, res); },
      err => { _onNext.call(this, err); }
    );
  } else {
    _populateBatch.call(this);
  }
}

/*!
 * ignore
 */

function _populateBatch() {
  if (!this.ctx._batchDocs.length) {
    return this.callback(null, null);
  }
  this.ctx.query.model.populate(this.ctx._batchDocs, this.ctx._pop).then(
    () => {
      _nextDoc(this.ctx, this.ctx._batchDocs.shift(), this.ctx._pop, this.callback);
    },
    err => {
      this.callback(err);
    }
  );
}

/*!
 * ignore
 */

function _nextDoc(ctx, doc, pop, callback) {
  if (ctx.query._mongooseOptions.lean) {
    return ctx.model.hooks.execPost('find', ctx.query, [[doc]], err => {
      if (err != null) {
        return callback(err);
      }
      callback(null, doc);
    });
  }

  const { model, _fields, _userProvidedFields, options } = ctx.query;
  helpers.createModelAndInit(model, doc, _fields, _userProvidedFields, options, pop, (err, doc) => {
    if (err != null) {
      return callback(err);
    }
    ctx.model.hooks.execPost('find', ctx.query, [[doc]], err => {
      if (err != null) {
        return callback(err);
      }
      callback(null, doc);
    });
  });
}

/*!
 * ignore
 */

function _waitForCursor(ctx, cb) {
  if (ctx.cursor) {
    return cb();
  }
  ctx.once('cursor', function(cursor) {
    if (cursor == null) {
      return;
    }
    cb();
  });
}

module.exports = QueryCursor;
