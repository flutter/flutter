'use strict';

/*!
 * Module dependencies.
 */

const MongooseCollection = require('../../collection');
const MongooseError = require('../../error/mongooseError');
const Collection = require('mongodb').Collection;
const ObjectId = require('../../types/objectid');
const getConstructorName = require('../../helpers/getConstructorName');
const internalToObjectOptions = require('../../options').internalToObjectOptions;
const stream = require('stream');
const util = require('util');

/**
 * A [node-mongodb-native](https://github.com/mongodb/node-mongodb-native) collection implementation.
 *
 * All methods methods from the [node-mongodb-native](https://github.com/mongodb/node-mongodb-native) driver are copied and wrapped in queue management.
 *
 * @inherits Collection https://mongodb.github.io/node-mongodb-native/4.9/classes/Collection.html
 * @api private
 */

function NativeCollection(name, conn, options) {
  this.collection = null;
  this.Promise = options.Promise || Promise;
  this.modelName = options.modelName;
  delete options.modelName;
  this._closed = false;
  MongooseCollection.apply(this, arguments);
}

/*!
 * Inherit from abstract Collection.
 */

Object.setPrototypeOf(NativeCollection.prototype, MongooseCollection.prototype);

/**
 * Called when the connection opens.
 *
 * @api private
 */

NativeCollection.prototype.onOpen = function() {
  this.collection = this.conn.db.collection(this.name);
  MongooseCollection.prototype.onOpen.call(this);
  return this.collection;
};

/**
 * Called when the connection closes
 *
 * @api private
 */

NativeCollection.prototype.onClose = function(force) {
  MongooseCollection.prototype.onClose.call(this, force);
};

/**
 * Helper to get the collection, in case `this.collection` isn't set yet.
 * May happen if `bufferCommands` is false and created the model when
 * Mongoose was disconnected.
 *
 * @api private
 */

NativeCollection.prototype._getCollection = function _getCollection() {
  if (this.collection) {
    return this.collection;
  }
  if (this.conn.db != null) {
    this.collection = this.conn.db.collection(this.name);
    return this.collection;
  }
  return null;
};

/*!
 * ignore
 */

const syncCollectionMethods = { watch: true, find: true, aggregate: true };

/**
 * Copy the collection methods and make them subject to queues
 * @param {Number|String} I
 * @api private
 */

function iter(i) {
  NativeCollection.prototype[i] = function() {
    const collection = this._getCollection();
    const args = Array.from(arguments);
    const _this = this;
    const globalDebug = _this &&
      _this.conn &&
      _this.conn.base &&
      _this.conn.base.options &&
      _this.conn.base.options.debug;
    const connectionDebug = _this &&
      _this.conn &&
      _this.conn.options &&
      _this.conn.options.debug;
    const debug = connectionDebug == null ? globalDebug : connectionDebug;
    const lastArg = arguments[arguments.length - 1];
    const opId = new ObjectId();

    // If user force closed, queueing will hang forever. See #5664
    if (this.conn.$wasForceClosed) {
      const error = new MongooseError('Connection was force closed');
      if (args.length > 0 &&
        typeof args[args.length - 1] === 'function') {
        args[args.length - 1](error);
        return;
      } else {
        throw error;
      }
    }

    let _args = args;
    let callback = null;
    if (this._shouldBufferCommands() && this.buffer) {
      this.conn.emit('buffer', {
        _id: opId,
        modelName: _this.modelName,
        collectionName: _this.name,
        method: i,
        args: args
      });

      let callback;
      let _args = args;
      let promise = null;
      let timeout = null;
      if (syncCollectionMethods[i] && typeof lastArg === 'function') {
        this.addQueue(i, _args);
        callback = lastArg;
      } else if (syncCollectionMethods[i]) {
        promise = new this.Promise((resolve, reject) => {
          callback = function collectionOperationCallback(err, res) {
            if (timeout != null) {
              clearTimeout(timeout);
            }
            if (err != null) {
              return reject(err);
            }
            resolve(res);
          };
          _args = args.concat([callback]);
          this.addQueue(i, _args);
        });
      } else if (typeof lastArg === 'function') {
        callback = function collectionOperationCallback() {
          if (timeout != null) {
            clearTimeout(timeout);
          }
          return lastArg.apply(this, arguments);
        };
        _args = args.slice(0, args.length - 1).concat([callback]);
      } else {
        promise = new Promise((resolve, reject) => {
          callback = function collectionOperationCallback(err, res) {
            if (timeout != null) {
              clearTimeout(timeout);
            }
            if (err != null) {
              return reject(err);
            }
            resolve(res);
          };
          _args = args.concat([callback]);
          this.addQueue(i, _args);
        });
      }

      const bufferTimeoutMS = this._getBufferTimeoutMS();
      timeout = setTimeout(() => {
        const removed = this.removeQueue(i, _args);
        if (removed) {
          const message = 'Operation `' + this.name + '.' + i + '()` buffering timed out after ' +
            bufferTimeoutMS + 'ms';
          const err = new MongooseError(message);
          this.conn.emit('buffer-end', { _id: opId, modelName: _this.modelName, collectionName: _this.name, method: i, error: err });
          callback(err);
        }
      }, bufferTimeoutMS);

      if (!syncCollectionMethods[i] && typeof lastArg === 'function') {
        this.addQueue(i, _args);
        return;
      }

      return promise;
    } else if (!syncCollectionMethods[i] && typeof lastArg === 'function') {
      callback = function collectionOperationCallback(err, res) {
        if (err != null) {
          _this.conn.emit('operation-end', { _id: opId, modelName: _this.modelName, collectionName: _this.name, method: i, error: err });
        } else {
          _this.conn.emit('operation-end', { _id: opId, modelName: _this.modelName, collectionName: _this.name, method: i, result: res });
        }
        return lastArg.apply(this, arguments);
      };
      _args = args.slice(0, args.length - 1).concat([callback]);
    }

    if (debug) {
      if (typeof debug === 'function') {
        let argsToAdd = null;
        if (typeof args[args.length - 1] == 'function') {
          argsToAdd = args.slice(0, args.length - 1);
        } else {
          argsToAdd = args;
        }
        debug.apply(_this,
          [_this.name, i].concat(argsToAdd));
      } else if (debug instanceof stream.Writable) {
        this.$printToStream(_this.name, i, args, debug);
      } else {
        const color = debug.color == null ? true : debug.color;
        const shell = debug.shell == null ? false : debug.shell;
        this.$print(_this.name, i, args, color, shell);
      }
    }

    this.conn.emit('operation-start', { _id: opId, modelName: _this.modelName, collectionName: this.name, method: i, params: _args });

    try {
      if (collection == null) {
        const message = 'Cannot call `' + this.name + '.' + i + '()` before initial connection ' +
          'is complete if `bufferCommands = false`. Make sure you `await mongoose.connect()` if ' +
          'you have `bufferCommands = false`.';
        throw new MongooseError(message);
      }

      if (syncCollectionMethods[i] && typeof lastArg === 'function') {
        const ret = collection[i].apply(collection, _args.slice(0, _args.length - 1));
        return lastArg.call(this, null, ret);
      }

      const ret = collection[i].apply(collection, _args);
      if (ret != null && typeof ret.then === 'function') {
        return ret.then(
          res => {
            typeof lastArg === 'function' && lastArg(null, res);
            return res;
          },
          err => {
            if (typeof lastArg === 'function') {
              lastArg(err);
              return;
            }
            throw err;
          }
        );
      }
      return ret;
    } catch (error) {
      // Collection operation may throw because of max bson size, catch it here
      // See gh-3906
      if (typeof lastArg === 'function') {
        return lastArg(error);
      } else {
        this.conn.emit('operation-end', { _id: opId, modelName: _this.modelName, collectionName: this.name, method: i, error: error });

        throw error;
      }
    }
  };
}

for (const key of Object.getOwnPropertyNames(Collection.prototype)) {
  // Janky hack to work around gh-3005 until we can get rid of the mongoose
  // collection abstraction
  const descriptor = Object.getOwnPropertyDescriptor(Collection.prototype, key);
  // Skip properties with getters because they may throw errors (gh-8528)
  if (descriptor.get !== undefined) {
    continue;
  }
  if (typeof Collection.prototype[key] !== 'function') {
    continue;
  }

  iter(key);
}

/**
 * Debug print helper
 *
 * @api public
 * @method $print
 */

NativeCollection.prototype.$print = function(name, i, args, color, shell) {
  const moduleName = color ? '\x1B[0;36mMongoose:\x1B[0m ' : 'Mongoose: ';
  const functionCall = [name, i].join('.');
  const _args = [];
  for (let j = args.length - 1; j >= 0; --j) {
    if (this.$format(args[j]) || _args.length) {
      _args.unshift(this.$format(args[j], color, shell));
    }
  }
  const params = '(' + _args.join(', ') + ')';

  console.info(moduleName + functionCall + params);
};

/**
 * Debug print helper
 *
 * @api public
 * @method $print
 */

NativeCollection.prototype.$printToStream = function(name, i, args, stream) {
  const functionCall = [name, i].join('.');
  const _args = [];
  for (let j = args.length - 1; j >= 0; --j) {
    if (this.$format(args[j]) || _args.length) {
      _args.unshift(this.$format(args[j]));
    }
  }
  const params = '(' + _args.join(', ') + ')';

  stream.write(functionCall + params, 'utf8');
};

/**
 * Formatter for debug print args
 *
 * @api public
 * @method $format
 */

NativeCollection.prototype.$format = function(arg, color, shell) {
  const type = typeof arg;
  if (type === 'function' || type === 'undefined') return '';
  return format(arg, false, color, shell);
};

/**
 * Debug print helper
 * @param {Any} representation
 * @api private
 */

function inspectable(representation) {
  const ret = {
    inspect: function() { return representation; }
  };
  if (util.inspect.custom) {
    ret[util.inspect.custom] = ret.inspect;
  }
  return ret;
}
function map(o) {
  return format(o, true);
}
function formatObjectId(x, key) {
  x[key] = inspectable('ObjectId("' + x[key].toHexString() + '")');
}
function formatDate(x, key, shell) {
  if (shell) {
    x[key] = inspectable('ISODate("' + x[key].toUTCString() + '")');
  } else {
    x[key] = inspectable('new Date("' + x[key].toUTCString() + '")');
  }
}
function format(obj, sub, color, shell) {
  if (obj && typeof obj.toBSON === 'function') {
    obj = obj.toBSON();
  }
  if (obj == null) {
    return obj;
  }

  const clone = require('../../helpers/clone');
  let x = clone(obj, internalToObjectOptions);
  const constructorName = getConstructorName(x);

  if (constructorName === 'Binary') {
    x = 'BinData(' + x.sub_type + ', "' + x.toString('base64') + '")';
  } else if (constructorName === 'ObjectId') {
    x = inspectable('ObjectId("' + x.toHexString() + '")');
  } else if (constructorName === 'Date') {
    x = inspectable('new Date("' + x.toUTCString() + '")');
  } else if (constructorName === 'Object') {
    const keys = Object.keys(x);
    const numKeys = keys.length;
    let key;
    for (let i = 0; i < numKeys; ++i) {
      key = keys[i];
      if (x[key]) {
        let error;
        if (typeof x[key].toBSON === 'function') {
          try {
            // `session.toBSON()` throws an error. This means we throw errors
            // in debug mode when using transactions, see gh-6712. As a
            // workaround, catch `toBSON()` errors, try to serialize without
            // `toBSON()`, and rethrow if serialization still fails.
            x[key] = x[key].toBSON();
          } catch (_error) {
            error = _error;
          }
        }
        const _constructorName = getConstructorName(x[key]);
        if (_constructorName === 'Binary') {
          x[key] = 'BinData(' + x[key].sub_type + ', "' +
            x[key].buffer.toString('base64') + '")';
        } else if (_constructorName === 'Object') {
          x[key] = format(x[key], true);
        } else if (_constructorName === 'ObjectId') {
          formatObjectId(x, key);
        } else if (_constructorName === 'Date') {
          formatDate(x, key, shell);
        } else if (_constructorName === 'ClientSession') {
          x[key] = inspectable('ClientSession("' +
            (
              x[key] &&
              x[key].id &&
              x[key].id.id &&
              x[key].id.id.buffer || ''
            ).toString('hex') + '")');
        } else if (Array.isArray(x[key])) {
          x[key] = x[key].map(map);
        } else if (error != null) {
          // If there was an error with `toBSON()` and the object wasn't
          // already converted to a string representation, rethrow it.
          // Open to better ideas on how to handle this.
          throw error;
        }
      }
    }
  }
  if (sub) {
    return x;
  }

  return util.
    inspect(x, false, 10, color).
    replace(/\n/g, '').
    replace(/\s{2,}/g, ' ');
}

/**
 * Retrieves information about this collections indexes.
 *
 * @param {Function} callback
 * @method getIndexes
 * @api public
 */

NativeCollection.prototype.getIndexes = NativeCollection.prototype.indexInformation;

/*!
 * Module exports.
 */

module.exports = NativeCollection;
