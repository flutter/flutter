'use strict';

/*!
 * Module dependencies.
 */

const Document = require('./document');
const EventEmitter = require('events').EventEmitter;
const Kareem = require('kareem');
const Schema = require('./schema');
const SchemaType = require('./schemaType');
const SchemaTypes = require('./schema/index');
const VirtualType = require('./virtualType');
const STATES = require('./connectionState');
const VALID_OPTIONS = require('./validOptions');
const Types = require('./types');
const Query = require('./query');
const Model = require('./model');
const applyPlugins = require('./helpers/schema/applyPlugins');
const builtinPlugins = require('./plugins');
const driver = require('./driver');
const legacyPluralize = require('./helpers/pluralize');
const utils = require('./utils');
const pkg = require('../package.json');
const cast = require('./cast');

const Aggregate = require('./aggregate');
const trusted = require('./helpers/query/trusted').trusted;
const sanitizeFilter = require('./helpers/query/sanitizeFilter');
const isBsonType = require('./helpers/isBsonType');
const MongooseError = require('./error/mongooseError');
const SetOptionError = require('./error/setOptionError');
const applyEmbeddedDiscriminators = require('./helpers/discriminator/applyEmbeddedDiscriminators');

const defaultMongooseSymbol = Symbol.for('mongoose:default');

require('./helpers/printJestWarning');

const objectIdHexRegexp = /^[0-9A-Fa-f]{24}$/;

/**
 * Mongoose constructor.
 *
 * The exports object of the `mongoose` module is an instance of this class.
 * Most apps will only use this one instance.
 *
 * #### Example:
 *
 *     const mongoose = require('mongoose');
 *     mongoose instanceof mongoose.Mongoose; // true
 *
 *     // Create a new Mongoose instance with its own `connect()`, `set()`, `model()`, etc.
 *     const m = new mongoose.Mongoose();
 *
 * @api public
 * @param {Object} options see [`Mongoose#set()` docs](https://mongoosejs.com/docs/api/mongoose.html#Mongoose.prototype.set())
 */
function Mongoose(options) {
  this.connections = [];
  this.nextConnectionId = 0;
  this.models = {};
  this.events = new EventEmitter();
  this.__driver = driver.get();
  // default global options
  this.options = Object.assign({
    pluralization: true,
    autoIndex: true,
    autoCreate: true,
    autoSearchIndex: false
  }, options);
  const createInitialConnection = utils.getOption('createInitialConnection', this.options);
  if (createInitialConnection == null || createInitialConnection) {
    const conn = this.createConnection(); // default connection
    conn.models = this.models;
  }

  if (this.options.pluralization) {
    this._pluralize = legacyPluralize;
  }

  // If a user creates their own Mongoose instance, give them a separate copy
  // of the `Schema` constructor so they get separate custom types. (gh-6933)
  if (!options || !options[defaultMongooseSymbol]) {
    const _this = this;
    this.Schema = function() {
      this.base = _this;
      return Schema.apply(this, arguments);
    };
    this.Schema.prototype = Object.create(Schema.prototype);

    Object.assign(this.Schema, Schema);
    this.Schema.base = this;
    this.Schema.Types = Object.assign({}, Schema.Types);
  } else {
    // Hack to work around babel's strange behavior with
    // `import mongoose, { Schema } from 'mongoose'`. Because `Schema` is not
    // an own property of a Mongoose global, Schema will be undefined. See gh-5648
    for (const key of ['Schema', 'model']) {
      this[key] = Mongoose.prototype[key];
    }
  }
  this.Schema.prototype.base = this;

  Object.defineProperty(this, 'plugins', {
    configurable: false,
    enumerable: true,
    writable: false,
    value: Object.values(builtinPlugins).map(plugin => ([plugin, { deduplicate: true }]))
  });
}

Mongoose.prototype.cast = cast;
/**
 * Expose connection states for user-land
 *
 * @memberOf Mongoose
 * @property STATES
 * @api public
 */
Mongoose.prototype.STATES = STATES;

/**
 * Expose connection states for user-land
 *
 * @memberOf Mongoose
 * @property ConnectionStates
 * @api public
 */
Mongoose.prototype.ConnectionStates = STATES;

/**
 * Object with `get()` and `set()` containing the underlying driver this Mongoose instance
 * uses to communicate with the database. A driver is a Mongoose-specific interface that defines functions
 * like `find()`.
 *
 * @deprecated
 * @memberOf Mongoose
 * @property driver
 * @api public
 */

Mongoose.prototype.driver = driver;

/**
 * Overwrites the current driver used by this Mongoose instance. A driver is a
 * Mongoose-specific interface that defines functions like `find()`.
 *
 * @memberOf Mongoose
 * @method setDriver
 * @api public
 */

Mongoose.prototype.setDriver = function setDriver(driver) {
  const _mongoose = this instanceof Mongoose ? this : mongoose;

  if (_mongoose.__driver === driver) {
    return _mongoose;
  }

  const openConnection = _mongoose.connections && _mongoose.connections.find(conn => conn.readyState !== STATES.disconnected);
  if (openConnection) {
    const msg = 'Cannot modify Mongoose driver if a connection is already open. ' +
      'Call `mongoose.disconnect()` before modifying the driver';
    throw new MongooseError(msg);
  }
  _mongoose.__driver = driver;

  const Connection = driver.Connection;
  const oldDefaultConnection = _mongoose.connections[0];
  _mongoose.connections = [new Connection(_mongoose)];
  _mongoose.connections[0].models = _mongoose.models;

  // Update all models that pointed to the old default connection to
  // the new default connection, including collections
  for (const model of Object.values(_mongoose.models)) {
    if (model.db !== oldDefaultConnection) {
      continue;
    }
    model.$__updateConnection(_mongoose.connections[0]);
  }

  return _mongoose;
};

/**
 * Sets mongoose options
 *
 * `key` can be used a object to set multiple options at once.
 * If a error gets thrown for one option, other options will still be evaluated.
 *
 * #### Example:
 *
 *     mongoose.set('test', value) // sets the 'test' option to `value`
 *
 *     mongoose.set('debug', true) // enable logging collection methods + arguments to the console/file
 *
 *     mongoose.set('debug', function(collectionName, methodName, ...methodArgs) {}); // use custom function to log collection methods + arguments
 *
 *     mongoose.set({ debug: true, autoIndex: false }); // set multiple options at once
 *
 * Currently supported options are:
 * - `allowDiskUse`: Set to `true` to set `allowDiskUse` to true to all aggregation operations by default.
 * - `applyPluginsToChildSchemas`: `true` by default. Set to false to skip applying global plugins to child schemas
 * - `applyPluginsToDiscriminators`: `false` by default. Set to true to apply global plugins to discriminator schemas. This typically isn't necessary because plugins are applied to the base schema and discriminators copy all middleware, methods, statics, and properties from the base schema.
 * - `autoCreate`: Set to `true` to make Mongoose call [`Model.createCollection()`](https://mongoosejs.com/docs/api/model.html#Model.createCollection()) automatically when you create a model with `mongoose.model()` or `conn.model()`. This is useful for testing transactions, change streams, and other features that require the collection to exist.
 * - `autoIndex`: `true` by default. Set to false to disable automatic index creation for all models associated with this Mongoose instance.
 * - `bufferCommands`: enable/disable mongoose's buffering mechanism for all connections and models
 * - `bufferTimeoutMS`: If bufferCommands is on, this option sets the maximum amount of time Mongoose buffering will wait before throwing an error. If not specified, Mongoose will use 10000 (10 seconds).
 * - `cloneSchemas`: `false` by default. Set to `true` to `clone()` all schemas before compiling into a model.
 * - `debug`: If `true`, prints the operations mongoose sends to MongoDB to the console. If a writable stream is passed, it will log to that stream, without colorization. If a callback function is passed, it will receive the collection name, the method name, then all arguments passed to the method. For example, if you wanted to replicate the default logging, you could output from the callback `Mongoose: ${collectionName}.${methodName}(${methodArgs.join(', ')})`.
 * - `id`: If `true`, adds a `id` virtual to all schemas unless overwritten on a per-schema basis.
 * - `timestamps.createdAt.immutable`: `true` by default. If `false`, it will change the `createdAt` field to be [`immutable: false`](https://mongoosejs.com/docs/api/schematype.html#SchemaType.prototype.immutable) which means you can update the `createdAt`
 * - `maxTimeMS`: If set, attaches [maxTimeMS](https://www.mongodb.com/docs/manual/reference/operator/meta/maxTimeMS/) to every query
 * - `objectIdGetter`: `true` by default. Mongoose adds a getter to MongoDB ObjectId's called `_id` that returns `this` for convenience with populate. Set this to false to remove the getter.
 * - `overwriteModels`: Set to `true` to default to overwriting models with the same name when calling `mongoose.model()`, as opposed to throwing an `OverwriteModelError`.
 * - `returnOriginal`: If `false`, changes the default `returnOriginal` option to `findOneAndUpdate()`, `findByIdAndUpdate`, and `findOneAndReplace()` to false. This is equivalent to setting the `new` option to `true` for `findOneAndX()` calls by default. Read our [`findOneAndUpdate()` tutorial](https://mongoosejs.com/docs/tutorials/findoneandupdate.html) for more information.
 * - `runValidators`: `false` by default. Set to true to enable [update validators](https://mongoosejs.com/docs/validation.html#update-validators) for all validators by default.
 * - `sanitizeFilter`: `false` by default. Set to true to enable the [sanitization of the query filters](https://mongoosejs.com/docs/api/mongoose.html#Mongoose.prototype.sanitizeFilter()) against query selector injection attacks by wrapping any nested objects that have a property whose name starts with `$` in a `$eq`.
 * - `selectPopulatedPaths`: `true` by default. Set to false to opt out of Mongoose adding all fields that you `populate()` to your `select()`. The schema-level option `selectPopulatedPaths` overwrites this one.
 * - `strict`: `true` by default, may be `false`, `true`, or `'throw'`. Sets the default strict mode for schemas.
 * - `strictQuery`: `false` by default. May be `false`, `true`, or `'throw'`. Sets the default [strictQuery](https://mongoosejs.com/docs/guide.html#strictQuery) mode for schemas.
 * - `toJSON`: `{ transform: true, flattenDecimals: true }` by default. Overwrites default objects to [`toJSON()`](https://mongoosejs.com/docs/api/document.html#Document.prototype.toJSON()), for determining how Mongoose documents get serialized by `JSON.stringify()`
 * - `toObject`: `{ transform: true, flattenDecimals: true }` by default. Overwrites default objects to [`toObject()`](https://mongoosejs.com/docs/api/document.html#Document.prototype.toObject())
 *
 * @param {String|Object} key The name of the option or a object of multiple key-value pairs
 * @param {String|Function|Boolean} value The value of the option, unused if "key" is a object
 * @returns {Mongoose} The used Mongoose instnace
 * @api public
 */

Mongoose.prototype.set = function(key, value) {
  const _mongoose = this instanceof Mongoose ? this : mongoose;

  if (arguments.length === 1 && typeof key !== 'object') {
    if (VALID_OPTIONS.indexOf(key) === -1) {
      const error = new SetOptionError();
      error.addError(key, new SetOptionError.SetOptionInnerError(key));
      throw error;
    }

    return _mongoose.options[key];
  }

  let options = {};

  if (arguments.length === 2) {
    options = { [key]: value };
  }

  if (arguments.length === 1 && typeof key === 'object') {
    options = key;
  }

  // array for errors to collect all errors for all key-value pairs, like ".validate"
  let error = undefined;

  for (const [optionKey, optionValue] of Object.entries(options)) {
    if (VALID_OPTIONS.indexOf(optionKey) === -1) {
      if (!error) {
        error = new SetOptionError();
      }
      error.addError(optionKey, new SetOptionError.SetOptionInnerError(optionKey));
      continue;
    }

    _mongoose.options[optionKey] = optionValue;

    if (optionKey === 'objectIdGetter') {
      if (optionValue) {
        Object.defineProperty(mongoose.Types.ObjectId.prototype, '_id', {
          enumerable: false,
          configurable: true,
          get: function() {
            return this;
          }
        });
      } else {
        delete mongoose.Types.ObjectId.prototype._id;
      }
    }
  }

  if (error) {
    throw error;
  }

  return _mongoose;
};

/**
 * Gets mongoose options
 *
 * #### Example:
 *
 *     mongoose.get('test') // returns the 'test' value
 *
 * @param {String} key
 * @method get
 * @api public
 */

Mongoose.prototype.get = Mongoose.prototype.set;

/**
 * Creates a Connection instance.
 *
 * Each `connection` instance maps to a single database. This method is helpful when managing multiple db connections.
 *
 *
 * _Options passed take precedence over options included in connection strings._
 *
 * #### Example:
 *
 *     // with mongodb:// URI
 *     db = mongoose.createConnection('mongodb://user:pass@127.0.0.1:port/database');
 *
 *     // and options
 *     const opts = { db: { native_parser: true }}
 *     db = mongoose.createConnection('mongodb://user:pass@127.0.0.1:port/database', opts);
 *
 *     // replica sets
 *     db = mongoose.createConnection('mongodb://user:pass@127.0.0.1:port,anotherhost:port,yetanother:port/database');
 *
 *     // and options
 *     const opts = { replset: { strategy: 'ping', rs_name: 'testSet' }}
 *     db = mongoose.createConnection('mongodb://user:pass@127.0.0.1:port,anotherhost:port,yetanother:port/database', opts);
 *
 *     // initialize now, connect later
 *     db = mongoose.createConnection();
 *     db.openUri('127.0.0.1', 'database', port, [opts]);
 *
 * @param {String} uri mongodb URI to connect to
 * @param {Object} [options] passed down to the [MongoDB driver's `connect()` function](https://mongodb.github.io/node-mongodb-native/4.9/interfaces/MongoClientOptions.html), except for 4 mongoose-specific options explained below.
 * @param {Boolean} [options.bufferCommands=true] Mongoose specific option. Set to false to [disable buffering](https://mongoosejs.com/docs/faq.html#callback_never_executes) on all models associated with this connection.
 * @param {String} [options.dbName] The name of the database you want to use. If not provided, Mongoose uses the database name from connection string.
 * @param {String} [options.user] username for authentication, equivalent to `options.auth.user`. Maintained for backwards compatibility.
 * @param {String} [options.pass] password for authentication, equivalent to `options.auth.password`. Maintained for backwards compatibility.
 * @param {Boolean} [options.autoIndex=true] Mongoose-specific option. Set to false to disable automatic index creation for all models associated with this connection.
 * @param {Class} [options.promiseLibrary] Sets the [underlying driver's promise library](https://mongodb.github.io/node-mongodb-native/4.9/interfaces/MongoClientOptions.html#promiseLibrary).
 * @param {Number} [options.maxPoolSize=5] The maximum number of sockets the MongoDB driver will keep open for this connection. Keep in mind that MongoDB only allows one operation per socket at a time, so you may want to increase this if you find you have a few slow queries that are blocking faster queries from proceeding. See [Slow Trains in MongoDB and Node.js](https://thecodebarbarian.com/slow-trains-in-mongodb-and-nodejs).
 * @param {Number} [options.minPoolSize=1] The minimum number of sockets the MongoDB driver will keep open for this connection. Keep in mind that MongoDB only allows one operation per socket at a time, so you may want to increase this if you find you have a few slow queries that are blocking faster queries from proceeding. See [Slow Trains in MongoDB and Node.js](https://thecodebarbarian.com/slow-trains-in-mongodb-and-nodejs).
 * @param {Number} [options.socketTimeoutMS=0] How long the MongoDB driver will wait before killing a socket due to inactivity _after initial connection_. Defaults to 0, which means Node.js will not time out the socket due to inactivity. A socket may be inactive because of either no activity or a long-running operation. This option is passed to [Node.js `socket#setTimeout()` function](https://nodejs.org/api/net.html#net_socket_settimeout_timeout_callback) after the MongoDB driver successfully completes.
 * @param {Number} [options.family=0] Passed transparently to [Node.js' `dns.lookup()`](https://nodejs.org/api/dns.html#dns_dns_lookup_hostname_options_callback) function. May be either `0`, `4`, or `6`. `4` means use IPv4 only, `6` means use IPv6 only, `0` means try both.
 * @return {Connection} the created Connection object. Connections are not thenable, so you can't do `await mongoose.createConnection()`. To await use `mongoose.createConnection(uri).asPromise()` instead.
 * @api public
 */

Mongoose.prototype.createConnection = function(uri, options) {
  const _mongoose = this instanceof Mongoose ? this : mongoose;

  const Connection = _mongoose.__driver.Connection;
  const conn = new Connection(_mongoose);
  _mongoose.connections.push(conn);
  _mongoose.nextConnectionId++;
  _mongoose.events.emit('createConnection', conn);

  if (arguments.length > 0) {
    conn.openUri(uri, { ...options, _fireAndForget: true });
  }

  return conn;
};

/**
 * Opens the default mongoose connection.
 *
 * #### Example:
 *
 *     mongoose.connect('mongodb://user:pass@127.0.0.1:port/database');
 *
 *     // replica sets
 *     const uri = 'mongodb://user:pass@127.0.0.1:port,anotherhost:port,yetanother:port/mydatabase';
 *     mongoose.connect(uri);
 *
 *     // with options
 *     mongoose.connect(uri, options);
 *
 *     // optional callback that gets fired when initial connection completed
 *     const uri = 'mongodb://nonexistent.domain:27000';
 *     mongoose.connect(uri, function(error) {
 *       // if error is truthy, the initial connection failed.
 *     })
 *
 * @param {String} uri mongodb URI to connect to
 * @param {Object} [options] passed down to the [MongoDB driver's `connect()` function](https://mongodb.github.io/node-mongodb-native/4.9/interfaces/MongoClientOptions.html), except for 4 mongoose-specific options explained below.
 * @param {Boolean} [options.bufferCommands=true] Mongoose specific option. Set to false to [disable buffering](https://mongoosejs.com/docs/faq.html#callback_never_executes) on all models associated with this connection.
 * @param {Number} [options.bufferTimeoutMS=10000] Mongoose specific option. If `bufferCommands` is true, Mongoose will throw an error after `bufferTimeoutMS` if the operation is still buffered.
 * @param {String} [options.dbName] The name of the database we want to use. If not provided, use database name from connection string.
 * @param {String} [options.user] username for authentication, equivalent to `options.auth.user`. Maintained for backwards compatibility.
 * @param {String} [options.pass] password for authentication, equivalent to `options.auth.password`. Maintained for backwards compatibility.
 * @param {Number} [options.maxPoolSize=100] The maximum number of sockets the MongoDB driver will keep open for this connection. Keep in mind that MongoDB only allows one operation per socket at a time, so you may want to increase this if you find you have a few slow queries that are blocking faster queries from proceeding. See [Slow Trains in MongoDB and Node.js](https://thecodebarbarian.com/slow-trains-in-mongodb-and-nodejs).
 * @param {Number} [options.minPoolSize=0] The minimum number of sockets the MongoDB driver will keep open for this connection.
 * @param {Number} [options.serverSelectionTimeoutMS] If `useUnifiedTopology = true`, the MongoDB driver will try to find a server to send any given operation to, and keep retrying for `serverSelectionTimeoutMS` milliseconds before erroring out. If not set, the MongoDB driver defaults to using `30000` (30 seconds).
 * @param {Number} [options.heartbeatFrequencyMS] If `useUnifiedTopology = true`, the MongoDB driver sends a heartbeat every `heartbeatFrequencyMS` to check on the status of the connection. A heartbeat is subject to `serverSelectionTimeoutMS`, so the MongoDB driver will retry failed heartbeats for up to 30 seconds by default. Mongoose only emits a `'disconnected'` event after a heartbeat has failed, so you may want to decrease this setting to reduce the time between when your server goes down and when Mongoose emits `'disconnected'`. We recommend you do **not** set this setting below 1000, too many heartbeats can lead to performance degradation.
 * @param {Boolean} [options.autoIndex=true] Mongoose-specific option. Set to false to disable automatic index creation for all models associated with this connection.
 * @param {Class} [options.promiseLibrary] Sets the [underlying driver's promise library](https://mongodb.github.io/node-mongodb-native/4.9/interfaces/MongoClientOptions.html#promiseLibrary).
 * @param {Number} [options.socketTimeoutMS=0] How long the MongoDB driver will wait before killing a socket due to inactivity _after initial connection_. A socket may be inactive because of either no activity or a long-running operation. `socketTimeoutMS` defaults to 0, which means Node.js will not time out the socket due to inactivity. This option is passed to [Node.js `socket#setTimeout()` function](https://nodejs.org/api/net.html#net_socket_settimeout_timeout_callback) after the MongoDB driver successfully completes.
 * @param {Number} [options.family=0] Passed transparently to [Node.js' `dns.lookup()`](https://nodejs.org/api/dns.html#dns_dns_lookup_hostname_options_callback) function. May be either `0`, `4`, or `6`. `4` means use IPv4 only, `6` means use IPv6 only, `0` means try both.
 * @param {Boolean} [options.autoCreate=false] Set to `true` to make Mongoose automatically call `createCollection()` on every model created on this connection.
 * @param {Function} [callback]
 * @see Mongoose#createConnection https://mongoosejs.com/docs/api/mongoose.html#Mongoose.prototype.createConnection()
 * @api public
 * @return {Promise} resolves to `this` if connection succeeded
 */

Mongoose.prototype.connect = async function connect(uri, options) {
  if (typeof options === 'function' || (arguments.length >= 3 && typeof arguments[2] === 'function')) {
    throw new MongooseError('Mongoose.prototype.connect() no longer accepts a callback');
  }

  const _mongoose = this instanceof Mongoose ? this : mongoose;
  const conn = _mongoose.connection;

  return conn.openUri(uri, options).then(() => _mongoose);
};

/**
 * Runs `.close()` on all connections in parallel.
 *
 * @return {Promise} resolves when all connections are closed, or rejects with the first error that occurred.
 * @api public
 */

Mongoose.prototype.disconnect = async function disconnect() {
  if (arguments.length >= 1 && typeof arguments[0] === 'function') {
    throw new MongooseError('Mongoose.prototype.disconnect() no longer accepts a callback');
  }

  const _mongoose = this instanceof Mongoose ? this : mongoose;

  const remaining = _mongoose.connections.length;
  if (remaining <= 0) {
    return;
  }
  await Promise.all(_mongoose.connections.map(conn => conn.close()));
};

/**
 * _Requires MongoDB >= 3.6.0._ Starts a [MongoDB session](https://www.mongodb.com/docs/manual/release-notes/3.6/#client-sessions)
 * for benefits like causal consistency, [retryable writes](https://www.mongodb.com/docs/manual/core/retryable-writes/),
 * and [transactions](https://thecodebarbarian.com/a-node-js-perspective-on-mongodb-4-transactions.html).
 *
 * Calling `mongoose.startSession()` is equivalent to calling `mongoose.connection.startSession()`.
 * Sessions are scoped to a connection, so calling `mongoose.startSession()`
 * starts a session on the [default mongoose connection](https://mongoosejs.com/docs/api/mongoose.html#Mongoose.prototype.connection).
 *
 * @param {Object} [options] see the [mongodb driver options](https://mongodb.github.io/node-mongodb-native/4.9/classes/MongoClient.html#startSession)
 * @param {Boolean} [options.causalConsistency=true] set to false to disable causal consistency
 * @param {Function} [callback]
 * @return {Promise<ClientSession>} promise that resolves to a MongoDB driver `ClientSession`
 * @api public
 */

Mongoose.prototype.startSession = function() {
  const _mongoose = this instanceof Mongoose ? this : mongoose;

  return _mongoose.connection.startSession.apply(_mongoose.connection, arguments);
};

/**
 * Getter/setter around function for pluralizing collection names.
 *
 * @param {Function|null} [fn] overwrites the function used to pluralize collection names
 * @return {Function|null} the current function used to pluralize collection names, defaults to the legacy function from `mongoose-legacy-pluralize`.
 * @api public
 */

Mongoose.prototype.pluralize = function(fn) {
  const _mongoose = this instanceof Mongoose ? this : mongoose;

  if (arguments.length > 0) {
    _mongoose._pluralize = fn;
  }
  return _mongoose._pluralize;
};

/**
 * Defines a model or retrieves it.
 *
 * Models defined on the `mongoose` instance are available to all connection
 * created by the same `mongoose` instance.
 *
 * If you call `mongoose.model()` with twice the same name but a different schema,
 * you will get an `OverwriteModelError`. If you call `mongoose.model()` with
 * the same name and same schema, you'll get the same schema back.
 *
 * #### Example:
 *
 *     const mongoose = require('mongoose');
 *
 *     // define an Actor model with this mongoose instance
 *     const schema = new Schema({ name: String });
 *     mongoose.model('Actor', schema);
 *
 *     // create a new connection
 *     const conn = mongoose.createConnection(..);
 *
 *     // create Actor model
 *     const Actor = conn.model('Actor', schema);
 *     conn.model('Actor') === Actor; // true
 *     conn.model('Actor', schema) === Actor; // true, same schema
 *     conn.model('Actor', schema, 'actors') === Actor; // true, same schema and collection name
 *
 *     // This throws an `OverwriteModelError` because the schema is different.
 *     conn.model('Actor', new Schema({ name: String }));
 *
 * _When no `collection` argument is passed, Mongoose uses the model name. If you don't like this behavior, either pass a collection name, use `mongoose.pluralize()`, or set your schemas collection name option._
 *
 * #### Example:
 *
 *     const schema = new Schema({ name: String }, { collection: 'actor' });
 *
 *     // or
 *
 *     schema.set('collection', 'actor');
 *
 *     // or
 *
 *     const collectionName = 'actor';
 *     const M = mongoose.model('Actor', schema, collectionName);
 *
 * @param {String|Function} name model name or class extending Model
 * @param {Schema} [schema] the schema to use.
 * @param {String} [collection] name (optional, inferred from model name)
 * @param {Object} [options]
 * @param {Boolean} [options.overwriteModels=false] If true, overwrite existing models with the same name to avoid `OverwriteModelError`
 * @return {Model} The model associated with `name`. Mongoose will create the model if it doesn't already exist.
 * @api public
 */

Mongoose.prototype.model = function(name, schema, collection, options) {
  const _mongoose = this instanceof Mongoose ? this : mongoose;

  if (typeof schema === 'string') {
    collection = schema;
    schema = false;
  }

  if (arguments.length === 1) {
    const model = _mongoose.models[name];
    if (!model) {
      throw new MongooseError.MissingSchemaError(name);
    }
    return model;
  }

  if (utils.isObject(schema) && !(schema instanceof Schema)) {
    schema = new Schema(schema);
  }
  if (schema && !(schema instanceof Schema)) {
    throw new Error('The 2nd parameter to `mongoose.model()` should be a ' +
      'schema or a POJO');
  }

  // handle internal options from connection.model()
  options = options || {};

  const originalSchema = schema;
  if (schema) {
    if (_mongoose.get('cloneSchemas')) {
      schema = schema.clone();
    }
    _mongoose._applyPlugins(schema);
  }

  // connection.model() may be passing a different schema for
  // an existing model name. in this case don't read from cache.
  const overwriteModels = _mongoose.options.hasOwnProperty('overwriteModels') ?
    _mongoose.options.overwriteModels :
    options.overwriteModels;
  if (_mongoose.models.hasOwnProperty(name) && options.cache !== false && overwriteModels !== true) {
    if (originalSchema &&
        originalSchema.instanceOfSchema &&
        originalSchema !== _mongoose.models[name].schema) {
      throw new _mongoose.Error.OverwriteModelError(name);
    }
    if (collection && collection !== _mongoose.models[name].collection.name) {
      // subclass current model with alternate collection
      const model = _mongoose.models[name];
      schema = model.prototype.schema;
      const sub = model.__subclass(_mongoose.connection, schema, collection);
      // do not cache the sub model
      return sub;
    }
    return _mongoose.models[name];
  }
  if (schema == null) {
    throw new _mongoose.Error.MissingSchemaError(name);
  }

  const model = _mongoose._model(name, schema, collection, options);
  _mongoose.connection.models[name] = model;
  _mongoose.models[name] = model;

  return model;
};

/*!
 * ignore
 */

Mongoose.prototype._model = function(name, schema, collection, options) {
  const _mongoose = this instanceof Mongoose ? this : mongoose;

  let model;
  if (typeof name === 'function') {
    model = name;
    name = model.name;
    if (!(model.prototype instanceof Model)) {
      throw new _mongoose.Error('The provided class ' + name + ' must extend Model');
    }
  }

  if (schema) {
    if (_mongoose.get('cloneSchemas')) {
      schema = schema.clone();
    }
    _mongoose._applyPlugins(schema);
  }

  // Apply relevant "global" options to the schema
  if (schema == null || !('pluralization' in schema.options)) {
    schema.options.pluralization = _mongoose.options.pluralization;
  }

  if (!collection) {
    collection = schema.get('collection') ||
      utils.toCollectionName(name, _mongoose.pluralize());
  }

  const connection = options.connection || _mongoose.connection;
  model = _mongoose.Model.compile(model || name, schema, collection, connection, _mongoose);
  // Errors handled internally, so safe to ignore error
  model.init().catch(function $modelInitNoop() {});

  connection.emit('model', model);

  if (schema._applyDiscriminators != null) {
    for (const disc of schema._applyDiscriminators.keys()) {
      const {
        schema: discriminatorSchema,
        options
      } = schema._applyDiscriminators.get(disc);
      model.discriminator(disc, discriminatorSchema, options);
    }
  }

  applyEmbeddedDiscriminators(schema);

  return model;
};

/**
 * Removes the model named `name` from the default connection, if it exists.
 * You can use this function to clean up any models you created in your tests to
 * prevent OverwriteModelErrors.
 *
 * Equivalent to `mongoose.connection.deleteModel(name)`.
 *
 * #### Example:
 *
 *     mongoose.model('User', new Schema({ name: String }));
 *     console.log(mongoose.model('User')); // Model object
 *     mongoose.deleteModel('User');
 *     console.log(mongoose.model('User')); // undefined
 *
 *     // Usually useful in a Mocha `afterEach()` hook
 *     afterEach(function() {
 *       mongoose.deleteModel(/.+/); // Delete every model
 *     });
 *
 * @api public
 * @param {String|RegExp} name if string, the name of the model to remove. If regexp, removes all models whose name matches the regexp.
 * @return {Mongoose} this
 */

Mongoose.prototype.deleteModel = function(name) {
  const _mongoose = this instanceof Mongoose ? this : mongoose;

  _mongoose.connection.deleteModel(name);
  delete _mongoose.models[name];
  return _mongoose;
};

/**
 * Returns an array of model names created on this instance of Mongoose.
 *
 * #### Note:
 *
 * _Does not include names of models created using `connection.model()`._
 *
 * @api public
 * @return {Array}
 */

Mongoose.prototype.modelNames = function() {
  const _mongoose = this instanceof Mongoose ? this : mongoose;

  const names = Object.keys(_mongoose.models);
  return names;
};

/**
 * Applies global plugins to `schema`.
 *
 * @param {Schema} schema
 * @api private
 */

Mongoose.prototype._applyPlugins = function(schema, options) {
  const _mongoose = this instanceof Mongoose ? this : mongoose;

  options = options || {};
  options.applyPluginsToDiscriminators = _mongoose.options && _mongoose.options.applyPluginsToDiscriminators || false;
  options.applyPluginsToChildSchemas = typeof (_mongoose.options && _mongoose.options.applyPluginsToChildSchemas) === 'boolean' ?
    _mongoose.options.applyPluginsToChildSchemas :
    true;
  applyPlugins(schema, _mongoose.plugins, options, '$globalPluginsApplied');
};

/**
 * Declares a global plugin executed on all Schemas.
 *
 * Equivalent to calling `.plugin(fn)` on each Schema you create.
 *
 * @param {Function} fn plugin callback
 * @param {Object} [opts] optional options
 * @return {Mongoose} this
 * @see plugins https://mongoosejs.com/docs/plugins.html
 * @api public
 */

Mongoose.prototype.plugin = function(fn, opts) {
  const _mongoose = this instanceof Mongoose ? this : mongoose;

  _mongoose.plugins.push([fn, opts]);
  return _mongoose;
};

/**
 * The Mongoose module's default connection. Equivalent to `mongoose.connections[0]`, see [`connections`](https://mongoosejs.com/docs/api/mongoose.html#Mongoose.prototype.connections).
 *
 * #### Example:
 *
 *     const mongoose = require('mongoose');
 *     mongoose.connect(...);
 *     mongoose.connection.on('error', cb);
 *
 * This is the connection used by default for every model created using [mongoose.model](https://mongoosejs.com/docs/api/mongoose.html#Mongoose.prototype.model()).
 *
 * To create a new connection, use [`createConnection()`](https://mongoosejs.com/docs/api/mongoose.html#Mongoose.prototype.createConnection()).
 *
 * @memberOf Mongoose
 * @instance
 * @property {Connection} connection
 * @api public
 */

Mongoose.prototype.__defineGetter__('connection', function() {
  return this.connections[0];
});

Mongoose.prototype.__defineSetter__('connection', function(v) {
  if (v instanceof this.__driver.Connection) {
    this.connections[0] = v;
    this.models = v.models;
  }
});

/**
 * An array containing all [connections](connection.html) associated with this
 * Mongoose instance. By default, there is 1 connection. Calling
 * [`createConnection()`](https://mongoosejs.com/docs/api/mongoose.html#Mongoose.prototype.createConnection()) adds a connection
 * to this array.
 *
 * #### Example:
 *
 *     const mongoose = require('mongoose');
 *     mongoose.connections.length; // 1, just the default connection
 *     mongoose.connections[0] === mongoose.connection; // true
 *
 *     mongoose.createConnection('mongodb://127.0.0.1:27017/test');
 *     mongoose.connections.length; // 2
 *
 * @memberOf Mongoose
 * @instance
 * @property {Array} connections
 * @api public
 */

Mongoose.prototype.connections;

/**
 * An integer containing the value of the next connection id. Calling
 * [`createConnection()`](https://mongoosejs.com/docs/api/mongoose.html#Mongoose.prototype.createConnection()) increments
 * this value.
 *
 * #### Example:
 *
 *     const mongoose = require('mongoose');
 *     mongoose.createConnection(); // id `0`, `nextConnectionId` becomes `1`
 *     mongoose.createConnection(); // id `1`, `nextConnectionId` becomes `2`
 *     mongoose.connections[0].destroy() // Removes connection with id `0`
 *     mongoose.createConnection(); // id `2`, `nextConnectionId` becomes `3`
 *
 * @memberOf Mongoose
 * @instance
 * @property {Number} nextConnectionId
 * @api private
 */

Mongoose.prototype.nextConnectionId;

/**
 * The Mongoose Aggregate constructor
 *
 * @method Aggregate
 * @api public
 */

Mongoose.prototype.Aggregate = Aggregate;

/**
 * The Mongoose Collection constructor
 *
 * @memberOf Mongoose
 * @instance
 * @method Collection
 * @api public
 */

Object.defineProperty(Mongoose.prototype, 'Collection', {
  get: function() {
    return this.__driver.Collection;
  },
  set: function(Collection) {
    this.__driver.Collection = Collection;
  }
});

/**
 * The Mongoose [Connection](https://mongoosejs.com/docs/api/connection.html#Connection()) constructor
 *
 * @memberOf Mongoose
 * @instance
 * @method Connection
 * @api public
 */

Object.defineProperty(Mongoose.prototype, 'Connection', {
  get: function() {
    return this.__driver.Connection;
  },
  set: function(Connection) {
    if (Connection === this.__driver.Connection) {
      return;
    }

    this.__driver.Connection = Connection;
  }
});

/**
 * The Mongoose version
 *
 * #### Example:
 *
 *     console.log(mongoose.version); // '5.x.x'
 *
 * @property version
 * @api public
 */

Mongoose.prototype.version = pkg.version;

/**
 * The Mongoose constructor
 *
 * The exports of the mongoose module is an instance of this class.
 *
 * #### Example:
 *
 *     const mongoose = require('mongoose');
 *     const mongoose2 = new mongoose.Mongoose();
 *
 * @method Mongoose
 * @api public
 */

Mongoose.prototype.Mongoose = Mongoose;

/**
 * The Mongoose [Schema](https://mongoosejs.com/docs/api/schema.html#Schema()) constructor
 *
 * #### Example:
 *
 *     const mongoose = require('mongoose');
 *     const Schema = mongoose.Schema;
 *     const CatSchema = new Schema(..);
 *
 * @method Schema
 * @api public
 */

Mongoose.prototype.Schema = Schema;

/**
 * The Mongoose [SchemaType](https://mongoosejs.com/docs/api/schematype.html#SchemaType()) constructor
 *
 * @method SchemaType
 * @api public
 */

Mongoose.prototype.SchemaType = SchemaType;

/**
 * The various Mongoose SchemaTypes.
 *
 * #### Note:
 *
 * _Alias of mongoose.Schema.Types for backwards compatibility._
 *
 * @property SchemaTypes
 * @see Schema.SchemaTypes https://mongoosejs.com/docs/schematypes.html
 * @api public
 */

Mongoose.prototype.SchemaTypes = Schema.Types;

/**
 * The Mongoose [VirtualType](https://mongoosejs.com/docs/api/virtualtype.html#VirtualType()) constructor
 *
 * @method VirtualType
 * @api public
 */

Mongoose.prototype.VirtualType = VirtualType;

/**
 * The various Mongoose Types.
 *
 * #### Example:
 *
 *     const mongoose = require('mongoose');
 *     const array = mongoose.Types.Array;
 *
 * #### Types:
 *
 * - [Array](https://mongoosejs.com/docs/schematypes.html#arrays)
 * - [Buffer](https://mongoosejs.com/docs/schematypes.html#buffers)
 * - [Embedded](https://mongoosejs.com/docs/schematypes.html#schemas)
 * - [DocumentArray](https://mongoosejs.com/docs/api/documentarraypath.html)
 * - [Decimal128](https://mongoosejs.com/docs/api/mongoose.html#Mongoose.prototype.Decimal128)
 * - [ObjectId](https://mongoosejs.com/docs/schematypes.html#objectids)
 * - [Map](https://mongoosejs.com/docs/schematypes.html#maps)
 * - [Subdocument](https://mongoosejs.com/docs/schematypes.html#schemas)
 *
 * Using this exposed access to the `ObjectId` type, we can construct ids on demand.
 *
 *     const ObjectId = mongoose.Types.ObjectId;
 *     const id1 = new ObjectId;
 *
 * @property Types
 * @api public
 */

Mongoose.prototype.Types = Types;

/**
 * The Mongoose [Query](https://mongoosejs.com/docs/api/query.html#Query()) constructor.
 *
 * @method Query
 * @api public
 */

Mongoose.prototype.Query = Query;

/**
 * The Mongoose [Model](https://mongoosejs.com/docs/api/model.html#Model()) constructor.
 *
 * @method Model
 * @api public
 */

Mongoose.prototype.Model = Model;

/**
 * The Mongoose [Document](https://mongoosejs.com/docs/api/document.html#Document()) constructor.
 *
 * @method Document
 * @api public
 */

Mongoose.prototype.Document = Document;

/**
 * The Mongoose DocumentProvider constructor. Mongoose users should not have to
 * use this directly
 *
 * @method DocumentProvider
 * @api public
 */

Mongoose.prototype.DocumentProvider = require('./documentProvider');

/**
 * The Mongoose ObjectId [SchemaType](https://mongoosejs.com/docs/schematypes.html). Used for
 * declaring paths in your schema that should be
 * [MongoDB ObjectIds](https://www.mongodb.com/docs/manual/reference/method/ObjectId/).
 * Do not use this to create a new ObjectId instance, use `mongoose.Types.ObjectId`
 * instead.
 *
 * #### Example:
 *
 *     const childSchema = new Schema({ parentId: mongoose.ObjectId });
 *
 * @property ObjectId
 * @api public
 */

Mongoose.prototype.ObjectId = SchemaTypes.ObjectId;

/**
 * Returns true if Mongoose can cast the given value to an ObjectId, or
 * false otherwise.
 *
 * #### Example:
 *
 *     mongoose.isValidObjectId(new mongoose.Types.ObjectId()); // true
 *     mongoose.isValidObjectId('0123456789ab'); // true
 *     mongoose.isValidObjectId(6); // true
 *     mongoose.isValidObjectId(new User({ name: 'test' })); // true
 *
 *     mongoose.isValidObjectId({ test: 42 }); // false
 *
 * @method isValidObjectId
 * @param {Any} v
 * @returns {boolean} true if `v` is something Mongoose can coerce to an ObjectId
 * @api public
 */

Mongoose.prototype.isValidObjectId = function(v) {
  const _mongoose = this instanceof Mongoose ? this : mongoose;
  return _mongoose.Types.ObjectId.isValid(v);
};

/**
 * Returns true if the given value is a Mongoose ObjectId (using `instanceof`) or if the
 * given value is a 24 character hex string, which is the most commonly used string representation
 * of an ObjectId.
 *
 * This function is similar to `isValidObjectId()`, but considerably more strict, because
 * `isValidObjectId()` will return `true` for _any_ value that Mongoose can convert to an
 * ObjectId. That includes Mongoose documents, any string of length 12, and any number.
 * `isObjectIdOrHexString()` returns true only for `ObjectId` instances or 24 character hex
 * strings, and will return false for numbers, documents, and strings of length 12.
 *
 * #### Example:
 *
 *     mongoose.isObjectIdOrHexString(new mongoose.Types.ObjectId()); // true
 *     mongoose.isObjectIdOrHexString('62261a65d66c6be0a63c051f'); // true
 *
 *     mongoose.isObjectIdOrHexString('0123456789ab'); // false
 *     mongoose.isObjectIdOrHexString(6); // false
 *     mongoose.isObjectIdOrHexString(new User({ name: 'test' })); // false
 *     mongoose.isObjectIdOrHexString({ test: 42 }); // false
 *
 * @method isObjectIdOrHexString
 * @param {Any} v
 * @returns {boolean} true if `v` is an ObjectId instance _or_ a 24 char hex string
 * @api public
 */

Mongoose.prototype.isObjectIdOrHexString = function(v) {
  return isBsonType(v, 'ObjectId') || (typeof v === 'string' && objectIdHexRegexp.test(v));
};

/**
 *
 * Syncs all the indexes for the models registered with this connection.
 *
 * @param {Object} options
 * @param {Boolean} options.continueOnError `false` by default. If set to `true`, mongoose will not throw an error if one model syncing failed, and will return an object where the keys are the names of the models, and the values are the results/errors for each model.
 * @return {Promise} Returns a Promise, when the Promise resolves the value is a list of the dropped indexes.
 */
Mongoose.prototype.syncIndexes = function(options) {
  const _mongoose = this instanceof Mongoose ? this : mongoose;
  return _mongoose.connection.syncIndexes(options);
};

/**
 * The Mongoose Decimal128 [SchemaType](https://mongoosejs.com/docs/schematypes.html). Used for
 * declaring paths in your schema that should be
 * [128-bit decimal floating points](https://thecodebarbarian.com/a-nodejs-perspective-on-mongodb-34-decimal.html).
 * Do not use this to create a new Decimal128 instance, use `mongoose.Types.Decimal128`
 * instead.
 *
 * #### Example:
 *
 *     const vehicleSchema = new Schema({ fuelLevel: mongoose.Decimal128 });
 *
 * @property Decimal128
 * @api public
 */

Mongoose.prototype.Decimal128 = SchemaTypes.Decimal128;

/**
 * The Mongoose Mixed [SchemaType](https://mongoosejs.com/docs/schematypes.html). Used for
 * declaring paths in your schema that Mongoose's change tracking, casting,
 * and validation should ignore.
 *
 * #### Example:
 *
 *     const schema = new Schema({ arbitrary: mongoose.Mixed });
 *
 * @property Mixed
 * @api public
 */

Mongoose.prototype.Mixed = SchemaTypes.Mixed;

/**
 * The Mongoose Date [SchemaType](https://mongoosejs.com/docs/schematypes.html).
 *
 * #### Example:
 *
 *     const schema = new Schema({ test: Date });
 *     schema.path('test') instanceof mongoose.Date; // true
 *
 * @property Date
 * @api public
 */

Mongoose.prototype.Date = SchemaTypes.Date;

/**
 * The Mongoose Number [SchemaType](https://mongoosejs.com/docs/schematypes.html). Used for
 * declaring paths in your schema that Mongoose should cast to numbers.
 *
 * #### Example:
 *
 *     const schema = new Schema({ num: mongoose.Number });
 *     // Equivalent to:
 *     const schema = new Schema({ num: 'number' });
 *
 * @property Number
 * @api public
 */

Mongoose.prototype.Number = SchemaTypes.Number;

/**
 * The [MongooseError](https://mongoosejs.com/docs/api/error.html#Error()) constructor.
 *
 * @method Error
 * @api public
 */

Mongoose.prototype.Error = require('./error/index');
Mongoose.prototype.MongooseError = require('./error/mongooseError');

/**
 * Mongoose uses this function to get the current time when setting
 * [timestamps](https://mongoosejs.com/docs/guide.html#timestamps). You may stub out this function
 * using a tool like [Sinon](https://www.npmjs.com/package/sinon) for testing.
 *
 * @method now
 * @returns Date the current time
 * @api public
 */

Mongoose.prototype.now = function now() { return new Date(); };

/**
 * The Mongoose CastError constructor
 *
 * @method CastError
 * @param {String} type The name of the type
 * @param {Any} value The value that failed to cast
 * @param {String} path The path `a.b.c` in the doc where this cast error occurred
 * @param {Error} [reason] The original error that was thrown
 * @api public
 */

Mongoose.prototype.CastError = require('./error/cast');

/**
 * The constructor used for schematype options
 *
 * @method SchemaTypeOptions
 * @api public
 */

Mongoose.prototype.SchemaTypeOptions = require('./options/schemaTypeOptions');

/**
 * The [mquery](https://github.com/aheckmann/mquery) query builder Mongoose uses.
 *
 * @property mquery
 * @api public
 */

Mongoose.prototype.mquery = require('mquery');

/**
 * Sanitizes query filters against [query selector injection attacks](https://thecodebarbarian.com/2014/09/04/defending-against-query-selector-injection-attacks.html)
 * by wrapping any nested objects that have a property whose name starts with `$` in a `$eq`.
 *
 * ```javascript
 * const obj = { username: 'val', pwd: { $ne: null } };
 * sanitizeFilter(obj);
 * obj; // { username: 'val', pwd: { $eq: { $ne: null } } });
 * ```
 *
 * @method sanitizeFilter
 * @param {Object} filter
 * @returns Object the sanitized object
 * @api public
 */

Mongoose.prototype.sanitizeFilter = sanitizeFilter;

/**
 * Tells `sanitizeFilter()` to skip the given object when filtering out potential [query selector injection attacks](https://thecodebarbarian.com/2014/09/04/defending-against-query-selector-injection-attacks.html).
 * Use this method when you have a known query selector that you want to use.
 *
 * ```javascript
 * const obj = { username: 'val', pwd: trusted({ $type: 'string', $eq: 'my secret' }) };
 * sanitizeFilter(obj);
 *
 * // Note that `sanitizeFilter()` did not add `$eq` around `$type`.
 * obj; // { username: 'val', pwd: { $type: 'string', $eq: 'my secret' } });
 * ```
 *
 * @method trusted
 * @param {Object} obj
 * @returns Object the passed in object
 * @api public
 */

Mongoose.prototype.trusted = trusted;

/**
 * Use this function in `pre()` middleware to skip calling the wrapped function.
 *
 * #### Example:
 *
 *     schema.pre('save', function() {
 *       // Will skip executing `save()`, but will execute post hooks as if
 *       // `save()` had executed with the result `{ matchedCount: 0 }`
 *       return mongoose.skipMiddlewareFunction({ matchedCount: 0 });
 *     });
 *
 * @method skipMiddlewareFunction
 * @param {any} result
 * @api public
 */

Mongoose.prototype.skipMiddlewareFunction = Kareem.skipWrappedFunction;

/**
 * Use this function in `post()` middleware to replace the result
 *
 * #### Example:
 *
 *     schema.post('find', function(res) {
 *       // Normally you have to modify `res` in place. But with
 *       // `overwriteMiddlewarResult()`, you can make `find()` return a
 *       // completely different value.
 *       return mongoose.overwriteMiddlewareResult(res.filter(doc => !doc.isDeleted));
 *     });
 *
 * @method overwriteMiddlewareResult
 * @param {any} result
 * @api public
 */

Mongoose.prototype.overwriteMiddlewareResult = Kareem.overwriteResult;

/**
 * The exports object is an instance of Mongoose.
 *
 * @api private
 */

const mongoose = module.exports = exports = new Mongoose({
  [defaultMongooseSymbol]: true
});
