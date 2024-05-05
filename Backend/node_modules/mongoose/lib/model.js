'use strict';

/*!
 * Module dependencies.
 */

const Aggregate = require('./aggregate');
const ChangeStream = require('./cursor/changeStream');
const Document = require('./document');
const DocumentNotFoundError = require('./error/notFound');
const DivergentArrayError = require('./error/divergentArray');
const EventEmitter = require('events').EventEmitter;
const Kareem = require('kareem');
const MongooseBuffer = require('./types/buffer');
const MongooseError = require('./error/index');
const ObjectParameterError = require('./error/objectParameter');
const OverwriteModelError = require('./error/overwriteModel');
const Query = require('./query');
const SaveOptions = require('./options/saveOptions');
const Schema = require('./schema');
const ValidationError = require('./error/validation');
const VersionError = require('./error/version');
const ParallelSaveError = require('./error/parallelSave');
const applyDefaultsHelper = require('./helpers/document/applyDefaults');
const applyDefaultsToPOJO = require('./helpers/model/applyDefaultsToPOJO');
const applyEmbeddedDiscriminators = require('./helpers/discriminator/applyEmbeddedDiscriminators');
const applyHooks = require('./helpers/model/applyHooks');
const applyMethods = require('./helpers/model/applyMethods');
const applyProjection = require('./helpers/projection/applyProjection');
const applySchemaCollation = require('./helpers/indexes/applySchemaCollation');
const applyStaticHooks = require('./helpers/model/applyStaticHooks');
const applyStatics = require('./helpers/model/applyStatics');
const applyWriteConcern = require('./helpers/schema/applyWriteConcern');
const assignVals = require('./helpers/populate/assignVals');
const castBulkWrite = require('./helpers/model/castBulkWrite');
const clone = require('./helpers/clone');
const createPopulateQueryFilter = require('./helpers/populate/createPopulateQueryFilter');
const decorateUpdateWithVersionKey = require('./helpers/update/decorateUpdateWithVersionKey');
const getDefaultBulkwriteResult = require('./helpers/getDefaultBulkwriteResult');
const getSchemaDiscriminatorByValue = require('./helpers/discriminator/getSchemaDiscriminatorByValue');
const discriminator = require('./helpers/model/discriminator');
const firstKey = require('./helpers/firstKey');
const each = require('./helpers/each');
const get = require('./helpers/get');
const getConstructorName = require('./helpers/getConstructorName');
const getDiscriminatorByValue = require('./helpers/discriminator/getDiscriminatorByValue');
const getModelsMapForPopulate = require('./helpers/populate/getModelsMapForPopulate');
const immediate = require('./helpers/immediate');
const internalToObjectOptions = require('./options').internalToObjectOptions;
const isDefaultIdIndex = require('./helpers/indexes/isDefaultIdIndex');
const isIndexEqual = require('./helpers/indexes/isIndexEqual');
const {
  getRelatedDBIndexes,
  getRelatedSchemaIndexes
} = require('./helpers/indexes/getRelatedIndexes');
const isPathExcluded = require('./helpers/projection/isPathExcluded');
const decorateDiscriminatorIndexOptions = require('./helpers/indexes/decorateDiscriminatorIndexOptions');
const isPathSelectedInclusive = require('./helpers/projection/isPathSelectedInclusive');
const leanPopulateMap = require('./helpers/populate/leanPopulateMap');
const parallelLimit = require('./helpers/parallelLimit');
const parentPaths = require('./helpers/path/parentPaths');
const prepareDiscriminatorPipeline = require('./helpers/aggregate/prepareDiscriminatorPipeline');
const pushNestedArrayPaths = require('./helpers/model/pushNestedArrayPaths');
const removeDeselectedForeignField = require('./helpers/populate/removeDeselectedForeignField');
const setDottedPath = require('./helpers/path/setDottedPath');
const STATES = require('./connectionState');
const util = require('util');
const utils = require('./utils');
const MongooseBulkWriteError = require('./error/bulkWriteError');
const minimize = require('./helpers/minimize');

const VERSION_WHERE = 1;
const VERSION_INC = 2;
const VERSION_ALL = VERSION_WHERE | VERSION_INC;

const arrayAtomicsSymbol = require('./helpers/symbols').arrayAtomicsSymbol;
const modelCollectionSymbol = Symbol('mongoose#Model#collection');
const modelDbSymbol = Symbol('mongoose#Model#db');
const modelSymbol = require('./helpers/symbols').modelSymbol;
const subclassedSymbol = Symbol('mongoose#Model#subclassed');

const saveToObjectOptions = Object.assign({}, internalToObjectOptions, {
  bson: true,
  flattenObjectIds: false
});

/**
 * A Model is a class that's your primary tool for interacting with MongoDB.
 * An instance of a Model is called a [Document](https://mongoosejs.com/docs/api/document.html#Document).
 *
 * In Mongoose, the term "Model" refers to subclasses of the `mongoose.Model`
 * class. You should not use the `mongoose.Model` class directly. The
 * [`mongoose.model()`](https://mongoosejs.com/docs/api/mongoose.html#Mongoose.prototype.model()) and
 * [`connection.model()`](https://mongoosejs.com/docs/api/connection.html#Connection.prototype.model()) functions
 * create subclasses of `mongoose.Model` as shown below.
 *
 * #### Example:
 *
 *     // `UserModel` is a "Model", a subclass of `mongoose.Model`.
 *     const UserModel = mongoose.model('User', new Schema({ name: String }));
 *
 *     // You can use a Model to create new documents using `new`:
 *     const userDoc = new UserModel({ name: 'Foo' });
 *     await userDoc.save();
 *
 *     // You also use a model to create queries:
 *     const userFromDb = await UserModel.findOne({ name: 'Foo' });
 *
 * @param {Object} doc values for initial set
 * @param {Object} [fields] optional object containing the fields that were selected in the query which returned this document. You do **not** need to set this parameter to ensure Mongoose handles your [query projection](https://mongoosejs.com/docs/api/query.html#Query.prototype.select()).
 * @param {Boolean} [skipId=false] optional boolean. If true, mongoose doesn't add an `_id` field to the document.
 * @inherits Document https://mongoosejs.com/docs/api/document.html
 * @event `error`: If listening to this event, 'error' is emitted when a document was saved and an `error` occurred. If not listening, the event bubbles to the connection used to create this Model.
 * @event `index`: Emitted after `Model#ensureIndexes` completes. If an error occurred it is passed with the event.
 * @event `index-single-start`: Emitted when an individual index starts within `Model#ensureIndexes`. The fields and options being used to build the index are also passed with the event.
 * @event `index-single-done`: Emitted when an individual index finishes within `Model#ensureIndexes`. If an error occurred it is passed with the event. The fields, options, and index name are also passed.
 * @api public
 */

function Model(doc, fields, skipId) {
  if (fields instanceof Schema) {
    throw new TypeError('2nd argument to `Model` constructor must be a POJO or string, ' +
      '**not** a schema. Make sure you\'re calling `mongoose.model()`, not ' +
      '`mongoose.Model()`.');
  }
  if (typeof doc === 'string') {
    throw new TypeError('First argument to `Model` constructor must be an object, ' +
      '**not** a string. Make sure you\'re calling `mongoose.model()`, not ' +
      '`mongoose.Model()`.');
  }
  Document.call(this, doc, fields, skipId);
}

/**
 * Inherits from Document.
 *
 * All Model.prototype features are available on
 * top level (non-sub) documents.
 * @api private
 */

Object.setPrototypeOf(Model.prototype, Document.prototype);
Model.prototype.$isMongooseModelPrototype = true;

/**
 * Connection the model uses.
 *
 * @api public
 * @property db
 * @memberOf Model
 * @instance
 */

Model.prototype.db;

/**
 * The collection instance this model uses.
 * A Mongoose collection is a thin wrapper around a [MongoDB Node.js driver collection]([MongoDB Node.js driver collection](https://mongodb.github.io/node-mongodb-native/Next/classes/Collection.html)).
 * Using `Model.collection` means you bypass Mongoose middleware, validation, and casting.
 *
 * This property is read-only. Modifying this property is a no-op.
 *
 * @api public
 * @property collection
 * @memberOf Model
 * @instance
 */

Model.prototype.collection;

/**
 * Internal collection the model uses.
 *
 * This property is read-only. Modifying this property is a no-op.
 *
 * @api private
 * @property collection
 * @memberOf Model
 * @instance
 */


Model.prototype.$__collection;

/**
 * The name of the model
 *
 * @api public
 * @property modelName
 * @memberOf Model
 * @instance
 */

Model.prototype.modelName;

/**
 * Additional properties to attach to the query when calling `save()` and
 * `isNew` is false.
 *
 * @api public
 * @property $where
 * @memberOf Model
 * @instance
 */

Model.prototype.$where;

/**
 * If this is a discriminator model, `baseModelName` is the name of
 * the base model.
 *
 * @api public
 * @property baseModelName
 * @memberOf Model
 * @instance
 */

Model.prototype.baseModelName;

/**
 * Event emitter that reports any errors that occurred. Useful for global error
 * handling.
 *
 * #### Example:
 *
 *     MyModel.events.on('error', err => console.log(err.message));
 *
 *     // Prints a 'CastError' because of the above handler
 *     await MyModel.findOne({ _id: 'Not a valid ObjectId' }).catch(noop);
 *
 * @api public
 * @property events
 * @fires error whenever any query or model function errors
 * @memberOf Model
 * @static
 */

Model.events;

/**
 * Compiled middleware for this model. Set in `applyHooks()`.
 *
 * @api private
 * @property _middleware
 * @memberOf Model
 * @static
 */

Model._middleware;

/*!
 * ignore
 */

function _applyCustomWhere(doc, where) {
  if (doc.$where == null) {
    return;
  }
  for (const key of Object.keys(doc.$where)) {
    where[key] = doc.$where[key];
  }
}

/*!
 * ignore
 */

Model.prototype.$__handleSave = function(options, callback) {
  const saveOptions = {};

  applyWriteConcern(this.$__schema, options);
  if (typeof options.writeConcern !== 'undefined') {
    saveOptions.writeConcern = {};
    if ('w' in options.writeConcern) {
      saveOptions.writeConcern.w = options.writeConcern.w;
    }
    if ('j' in options.writeConcern) {
      saveOptions.writeConcern.j = options.writeConcern.j;
    }
    if ('wtimeout' in options.writeConcern) {
      saveOptions.writeConcern.wtimeout = options.writeConcern.wtimeout;
    }
  } else {
    if ('w' in options) {
      saveOptions.w = options.w;
    }
    if ('j' in options) {
      saveOptions.j = options.j;
    }
    if ('wtimeout' in options) {
      saveOptions.wtimeout = options.wtimeout;
    }
  }
  if ('checkKeys' in options) {
    saveOptions.checkKeys = options.checkKeys;
  }

  const session = this.$session();
  if (!saveOptions.hasOwnProperty('session') && session != null) {
    saveOptions.session = session;
  }
  if (this.$isNew) {
    // send entire doc
    const obj = this.toObject(saveToObjectOptions);
    if ((obj || {})._id === void 0) {
      // documents must have an _id else mongoose won't know
      // what to update later if more changes are made. the user
      // wouldn't know what _id was generated by mongodb either
      // nor would the ObjectId generated by mongodb necessarily
      // match the schema definition.
      immediate(function() {
        callback(new MongooseError('document must have an _id before saving'));
      });
      return;
    }

    this.$__version(true, obj);
    this[modelCollectionSymbol].insertOne(obj, saveOptions).then(
      ret => callback(null, ret),
      err => {
        _setIsNew(this, true);

        callback(err, null);
      }
    );

    this.$__reset();
    _setIsNew(this, false);
    // Make it possible to retry the insert
    this.$__.inserting = true;
    return;
  }

  // Make sure we don't treat it as a new object on error,
  // since it already exists
  this.$__.inserting = false;
  const delta = this.$__delta();

  if (options.pathsToSave) {
    for (const key in delta[1]['$set']) {
      if (options.pathsToSave.includes(key)) {
        continue;
      } else if (options.pathsToSave.some(pathToSave => key.slice(0, pathToSave.length) === pathToSave && key.charAt(pathToSave.length) === '.')) {
        continue;
      } else {
        delete delta[1]['$set'][key];
      }
    }
  }
  if (delta) {
    if (delta instanceof MongooseError) {
      callback(delta);
      return;
    }

    const where = this.$__where(delta[0]);
    if (where instanceof MongooseError) {
      callback(where);
      return;
    }

    _applyCustomWhere(this, where);

    const update = delta[1];
    if (this.$__schema.options.minimize) {
      for (const updateOp of Object.values(update)) {
        if (updateOp == null) {
          continue;
        }
        for (const key of Object.keys(updateOp)) {
          if (updateOp[key] == null || typeof updateOp[key] !== 'object') {
            continue;
          }
          if (!utils.isPOJO(updateOp[key])) {
            continue;
          }
          minimize(updateOp[key]);
          if (Object.keys(updateOp[key]).length === 0) {
            delete updateOp[key];
            update.$unset = update.$unset || {};
            update.$unset[key] = 1;
          }
        }
      }
    }

    this[modelCollectionSymbol].updateOne(where, update, saveOptions).then(
      ret => {
        ret.$where = where;
        callback(null, ret);
      },
      err => {
        this.$__undoReset();

        callback(err);
      }
    );
  } else {
    handleEmptyUpdate.call(this);
    return;
  }

  // store the modified paths before the document is reset
  this.$__.modifiedPaths = this.modifiedPaths();
  this.$__reset();

  _setIsNew(this, false);

  function handleEmptyUpdate() {
    const optionsWithCustomValues = Object.assign({}, options, saveOptions);
    const where = this.$__where();
    const optimisticConcurrency = this.$__schema.options.optimisticConcurrency;
    if (optimisticConcurrency && !Array.isArray(optimisticConcurrency)) {
      const key = this.$__schema.options.versionKey;
      const val = this.$__getValue(key);
      if (val != null) {
        where[key] = val;
      }
    }
    this.constructor.collection.findOne(where, optionsWithCustomValues)
      .then(documentExists => {
        const matchedCount = !documentExists ? 0 : 1;
        callback(null, { $where: where, matchedCount });
      })
      .catch(callback);
  }
};

/*!
 * ignore
 */

Model.prototype.$__save = function(options, callback) {
  this.$__handleSave(options, (error, result) => {
    if (error) {
      const hooks = this.$__schema.s.hooks;
      return hooks.execPost('save:error', this, [this], { error: error }, (error) => {
        callback(error, this);
      });
    }
    let numAffected = 0;
    const writeConcern = options != null ?
      options.writeConcern != null ?
        options.writeConcern.w :
        options.w :
      0;
    if (writeConcern !== 0) {
      // Skip checking if write succeeded if writeConcern is set to
      // unacknowledged writes, because otherwise `numAffected` will always be 0
      if (result != null) {
        if (Array.isArray(result)) {
          numAffected = result.length;
        } else if (result.matchedCount != null) {
          numAffected = result.matchedCount;
        } else {
          numAffected = result;
        }
      }

      const versionBump = this.$__.version;
      // was this an update that required a version bump?
      if (versionBump && !this.$__.inserting) {
        const doIncrement = VERSION_INC === (VERSION_INC & this.$__.version);
        this.$__.version = undefined;
        const key = this.$__schema.options.versionKey;
        const version = this.$__getValue(key) || 0;
        if (numAffected <= 0) {
          // the update failed. pass an error back
          this.$__undoReset();
          const err = this.$__.$versionError ||
            new VersionError(this, version, this.$__.modifiedPaths);
          return callback(err);
        }

        // increment version if was successful
        if (doIncrement) {
          this.$__setValue(key, version + 1);
        }
      }
      if (result != null && numAffected <= 0) {
        this.$__undoReset();
        error = new DocumentNotFoundError(result.$where,
          this.constructor.modelName, numAffected, result);
        const hooks = this.$__schema.s.hooks;
        return hooks.execPost('save:error', this, [this], { error: error }, (error) => {
          callback(error, this);
        });
      }
    }
    this.$__.saving = undefined;
    this.$__.savedState = {};
    this.$emit('save', this, numAffected);
    this.constructor.emit('save', this, numAffected);
    callback(null, this);
  });
};

/*!
 * ignore
 */

function generateVersionError(doc, modifiedPaths) {
  const key = doc.$__schema.options.versionKey;
  if (!key) {
    return null;
  }
  const version = doc.$__getValue(key) || 0;
  return new VersionError(doc, version, modifiedPaths);
}

/**
 * Saves this document by inserting a new document into the database if [document.isNew](https://mongoosejs.com/docs/api/document.html#Document.prototype.isNew) is `true`,
 * or sends an [updateOne](https://mongoosejs.com/docs/api/document.html#Document.prototype.updateOne()) operation with just the modified paths if `isNew` is `false`.
 *
 * #### Example:
 *
 *     product.sold = Date.now();
 *     product = await product.save();
 *
 * If save is successful, the returned promise will fulfill with the document
 * saved.
 *
 * #### Example:
 *
 *     const newProduct = await product.save();
 *     newProduct === product; // true
 *
 * @param {Object} [options] options optional options
 * @param {Session} [options.session=null] the [session](https://www.mongodb.com/docs/manual/reference/server-sessions/) associated with this save operation. If not specified, defaults to the [document's associated session](https://mongoosejs.com/docs/api/document.html#Document.prototype.session()).
 * @param {Object} [options.safe] (DEPRECATED) overrides [schema's safe option](https://mongoosejs.com/docs/guide.html#safe). Use the `w` option instead.
 * @param {Boolean} [options.validateBeforeSave] set to false to save without validating.
 * @param {Boolean} [options.validateModifiedOnly=false] if `true`, Mongoose will only validate modified paths, as opposed to modified paths and `required` paths.
 * @param {Number|String} [options.w] set the [write concern](https://www.mongodb.com/docs/manual/reference/write-concern/#w-option). Overrides the [schema-level `writeConcern` option](https://mongoosejs.com/docs/guide.html#writeConcern)
 * @param {Boolean} [options.j] set to true for MongoDB to wait until this `save()` has been [journaled before resolving the returned promise](https://www.mongodb.com/docs/manual/reference/write-concern/#j-option). Overrides the [schema-level `writeConcern` option](https://mongoosejs.com/docs/guide.html#writeConcern)
 * @param {Number} [options.wtimeout] sets a [timeout for the write concern](https://www.mongodb.com/docs/manual/reference/write-concern/#wtimeout). Overrides the [schema-level `writeConcern` option](https://mongoosejs.com/docs/guide.html#writeConcern).
 * @param {Boolean} [options.checkKeys=true] the MongoDB driver prevents you from saving keys that start with '$' or contain '.' by default. Set this option to `false` to skip that check. See [restrictions on field names](https://docs.mongodb.com/manual/reference/limits/#mongodb-limit-Restrictions-on-Field-Names)
 * @param {Boolean} [options.timestamps=true] if `false` and [timestamps](https://mongoosejs.com/docs/guide.html#timestamps) are enabled, skip timestamps for this `save()`.
 * @param {Array} [options.pathsToSave] An array of paths that tell mongoose to only validate and save the paths in `pathsToSave`.
 * @throws {DocumentNotFoundError} if this [save updates an existing document](https://mongoosejs.com/docs/api/document.html#Document.prototype.isNew) but the document doesn't exist in the database. For example, you will get this error if the document is [deleted between when you retrieved the document and when you saved it](documents.html#updating).
 * @return {Promise}
 * @api public
 * @see middleware https://mongoosejs.com/docs/middleware.html
 */

Model.prototype.save = async function save(options) {
  if (typeof options === 'function' || typeof arguments[1] === 'function') {
    throw new MongooseError('Model.prototype.save() no longer accepts a callback');
  }

  let parallelSave;
  this.$op = 'save';

  if (this.$__.saving) {
    parallelSave = new ParallelSaveError(this);
  } else {
    this.$__.saving = new ParallelSaveError(this);
  }

  options = new SaveOptions(options);
  if (options.hasOwnProperty('session')) {
    this.$session(options.session);
  }
  if (this.$__.timestamps != null) {
    options.timestamps = this.$__.timestamps;
  }
  this.$__.$versionError = generateVersionError(this, this.modifiedPaths());

  if (parallelSave) {
    this.$__handleReject(parallelSave);
    throw parallelSave;
  }

  this.$__.saveOptions = options;

  await new Promise((resolve, reject) => {
    this.$__save(options, error => {
      this.$__.saving = null;
      this.$__.saveOptions = null;
      this.$__.$versionError = null;
      this.$op = null;
      if (error != null) {
        this.$__handleReject(error);
        return reject(error);
      }

      resolve();
    });
  });

  return this;
};

Model.prototype.$save = Model.prototype.save;

/**
 * Determines whether versioning should be skipped for the given path
 *
 * @param {Document} self
 * @param {String} path
 * @return {Boolean} true if versioning should be skipped for the given path
 * @api private
 */
function shouldSkipVersioning(self, path) {
  const skipVersioning = self.$__schema.options.skipVersioning;
  if (!skipVersioning) return false;

  // Remove any array indexes from the path
  path = path.replace(/\.\d+\./, '.');

  return skipVersioning[path];
}

/**
 * Apply the operation to the delta (update) clause as
 * well as track versioning for our where clause.
 *
 * @param {Document} self
 * @param {Object} where Unused
 * @param {Object} delta
 * @param {Object} data
 * @param {Mixed} val
 * @param {String} [op]
 * @api private
 */

function operand(self, where, delta, data, val, op) {
  // delta
  op || (op = '$set');
  if (!delta[op]) delta[op] = {};
  delta[op][data.path] = val;
  // disabled versioning?
  if (self.$__schema.options.versionKey === false) return;

  // path excluded from versioning?
  if (shouldSkipVersioning(self, data.path)) return;

  // already marked for versioning?
  if (VERSION_ALL === (VERSION_ALL & self.$__.version)) return;

  if (self.$__schema.options.optimisticConcurrency) {
    return;
  }

  switch (op) {
    case '$set':
    case '$unset':
    case '$pop':
    case '$pull':
    case '$pullAll':
    case '$push':
    case '$addToSet':
    case '$inc':
      break;
    default:
      // nothing to do
      return;
  }

  // ensure updates sent with positional notation are
  // editing the correct array element.
  // only increment the version if an array position changes.
  // modifying elements of an array is ok if position does not change.
  if (op === '$push' || op === '$addToSet' || op === '$pullAll' || op === '$pull') {
    if (/\.\d+\.|\.\d+$/.test(data.path)) {
      increment.call(self);
    } else {
      self.$__.version = VERSION_INC;
    }
  } else if (/^\$p/.test(op)) {
    // potentially changing array positions
    increment.call(self);
  } else if (Array.isArray(val)) {
    // $set an array
    increment.call(self);
  } else if (/\.\d+\.|\.\d+$/.test(data.path)) {
    // now handling $set, $unset
    // subpath of array
    self.$__.version = VERSION_WHERE;
  }
}

/**
 * Compiles an update and where clause for a `val` with _atomics.
 *
 * @param {Document} self
 * @param {Object} where
 * @param {Object} delta
 * @param {Object} data
 * @param {Array} value
 * @api private
 */

function handleAtomics(self, where, delta, data, value) {
  if (delta.$set && delta.$set[data.path]) {
    // $set has precedence over other atomics
    return;
  }

  if (typeof value.$__getAtomics === 'function') {
    value.$__getAtomics().forEach(function(atomic) {
      const op = atomic[0];
      const val = atomic[1];
      operand(self, where, delta, data, val, op);
    });
    return;
  }

  // legacy support for plugins

  const atomics = value[arrayAtomicsSymbol];
  const ops = Object.keys(atomics);
  let i = ops.length;
  let val;
  let op;

  if (i === 0) {
    // $set

    if (utils.isMongooseObject(value)) {
      value = value.toObject({ depopulate: 1, _isNested: true });
    } else if (value.valueOf) {
      value = value.valueOf();
    }

    return operand(self, where, delta, data, value);
  }

  function iter(mem) {
    return utils.isMongooseObject(mem)
      ? mem.toObject({ depopulate: 1, _isNested: true })
      : mem;
  }

  while (i--) {
    op = ops[i];
    val = atomics[op];

    if (utils.isMongooseObject(val)) {
      val = val.toObject({ depopulate: true, transform: false, _isNested: true });
    } else if (Array.isArray(val)) {
      val = val.map(iter);
    } else if (val.valueOf) {
      val = val.valueOf();
    }

    if (op === '$addToSet') {
      val = { $each: val };
    }

    operand(self, where, delta, data, val, op);
  }
}

/**
 * Produces a special query document of the modified properties used in updates.
 *
 * @api private
 * @method $__delta
 * @memberOf Model
 * @instance
 */

Model.prototype.$__delta = function() {
  const dirty = this.$__dirty();
  const optimisticConcurrency = this.$__schema.options.optimisticConcurrency;
  if (optimisticConcurrency) {
    if (Array.isArray(optimisticConcurrency)) {
      const optCon = new Set(optimisticConcurrency);
      const modPaths = this.modifiedPaths();
      if (modPaths.find(path => optCon.has(path))) {
        this.$__.version = dirty.length ? VERSION_ALL : VERSION_WHERE;
      }
    } else {
      this.$__.version = dirty.length ? VERSION_ALL : VERSION_WHERE;
    }
  }

  if (!dirty.length && VERSION_ALL !== this.$__.version) {
    return;
  }
  const where = {};
  const delta = {};
  const len = dirty.length;
  const divergent = [];
  let d = 0;

  where._id = this._doc._id;
  // If `_id` is an object, need to depopulate, but also need to be careful
  // because `_id` can technically be null (see gh-6406)
  if ((where && where._id && where._id.$__ || null) != null) {
    where._id = where._id.toObject({ transform: false, depopulate: true });
  }
  for (; d < len; ++d) {
    const data = dirty[d];
    let value = data.value;
    const match = checkDivergentArray(this, data.path, value);
    if (match) {
      divergent.push(match);
      continue;
    }

    const pop = this.$populated(data.path, true);
    if (!pop && this.$__.selected) {
      // If any array was selected using an $elemMatch projection, we alter the path and where clause
      // NOTE: MongoDB only supports projected $elemMatch on top level array.
      const pathSplit = data.path.split('.');
      const top = pathSplit[0];
      if (this.$__.selected[top] && this.$__.selected[top].$elemMatch) {
        // If the selected array entry was modified
        if (pathSplit.length > 1 && pathSplit[1] == 0 && typeof where[top] === 'undefined') {
          where[top] = this.$__.selected[top];
          pathSplit[1] = '$';
          data.path = pathSplit.join('.');
        }
        // if the selected array was modified in any other way throw an error
        else {
          divergent.push(data.path);
          continue;
        }
      }
    }

    // If this path is set to default, and either this path or one of
    // its parents is excluded, don't treat this path as dirty.
    if (this.$isDefault(data.path) && this.$__.selected) {
      if (data.path.indexOf('.') === -1 && isPathExcluded(this.$__.selected, data.path)) {
        continue;
      }

      const pathsToCheck = parentPaths(data.path);
      if (pathsToCheck.find(path => isPathExcluded(this.$__.isSelected, path))) {
        continue;
      }
    }

    if (divergent.length) continue;
    if (value === undefined) {
      operand(this, where, delta, data, 1, '$unset');
    } else if (value === null) {
      operand(this, where, delta, data, null);
    } else if (utils.isMongooseArray(value) && value.$path() && value[arrayAtomicsSymbol]) {
      // arrays and other custom types (support plugins etc)
      handleAtomics(this, where, delta, data, value);
    } else if (value[MongooseBuffer.pathSymbol] && Buffer.isBuffer(value)) {
      // MongooseBuffer
      value = value.toObject();
      operand(this, where, delta, data, value);
    } else {
      if (this.$__.primitiveAtomics && this.$__.primitiveAtomics[data.path] != null) {
        const val = this.$__.primitiveAtomics[data.path];
        const op = firstKey(val);
        operand(this, where, delta, data, val[op], op);
      } else {
        value = clone(value, {
          depopulate: true,
          transform: false,
          virtuals: false,
          getters: false,
          omitUndefined: true,
          _isNested: true
        });
        operand(this, where, delta, data, value);
      }
    }
  }

  if (divergent.length) {
    return new DivergentArrayError(divergent);
  }

  if (this.$__.version) {
    this.$__version(where, delta);
  }

  if (Object.keys(delta).length === 0) {
    return [where, null];
  }

  return [where, delta];
};

/**
 * Determine if array was populated with some form of filter and is now
 * being updated in a manner which could overwrite data unintentionally.
 *
 * @see https://github.com/Automattic/mongoose/issues/1334
 * @param {Document} doc
 * @param {String} path
 * @param {Any} array
 * @return {String|undefined}
 * @api private
 */

function checkDivergentArray(doc, path, array) {
  // see if we populated this path
  const pop = doc.$populated(path, true);

  if (!pop && doc.$__.selected) {
    // If any array was selected using an $elemMatch projection, we deny the update.
    // NOTE: MongoDB only supports projected $elemMatch on top level array.
    const top = path.split('.')[0];
    if (doc.$__.selected[top + '.$']) {
      return top;
    }
  }

  if (!(pop && utils.isMongooseArray(array))) return;

  // If the array was populated using options that prevented all
  // documents from being returned (match, skip, limit) or they
  // deselected the _id field, $pop and $set of the array are
  // not safe operations. If _id was deselected, we do not know
  // how to remove elements. $pop will pop off the _id from the end
  // of the array in the db which is not guaranteed to be the
  // same as the last element we have here. $set of the entire array
  // would be similarly destructive as we never received all
  // elements of the array and potentially would overwrite data.
  const check = pop.options.match ||
      pop.options.options && utils.object.hasOwnProperty(pop.options.options, 'limit') || // 0 is not permitted
      pop.options.options && pop.options.options.skip || // 0 is permitted
      pop.options.select && // deselected _id?
      (pop.options.select._id === 0 ||
      /\s?-_id\s?/.test(pop.options.select));

  if (check) {
    const atomics = array[arrayAtomicsSymbol];
    if (Object.keys(atomics).length === 0 || atomics.$set || atomics.$pop) {
      return path;
    }
  }
}

/**
 * Appends versioning to the where and update clauses.
 *
 * @api private
 * @method $__version
 * @memberOf Model
 * @instance
 */

Model.prototype.$__version = function(where, delta) {
  const key = this.$__schema.options.versionKey;
  if (where === true) {
    // this is an insert
    if (key) {
      setDottedPath(delta, key, 0);
      this.$__setValue(key, 0);
    }
    return;
  }

  if (key === false) {
    return;
  }

  // updates

  // only apply versioning if our versionKey was selected. else
  // there is no way to select the correct version. we could fail
  // fast here and force them to include the versionKey but
  // thats a bit intrusive. can we do this automatically?

  if (!this.$__isSelected(key)) {
    return;
  }

  // $push $addToSet don't need the where clause set
  if (VERSION_WHERE === (VERSION_WHERE & this.$__.version)) {
    const value = this.$__getValue(key);
    if (value != null) where[key] = value;
  }

  if (VERSION_INC === (VERSION_INC & this.$__.version)) {
    if (get(delta.$set, key, null) != null) {
      // Version key is getting set, means we'll increment the doc's version
      // after a successful save, so we should set the incremented version so
      // future saves don't fail (gh-5779)
      ++delta.$set[key];
    } else {
      delta.$inc = delta.$inc || {};
      delta.$inc[key] = 1;
    }
  }
};

/*!
 * ignore
 */

function increment() {
  this.$__.version = VERSION_ALL;
  return this;
}

/**
 * Signal that we desire an increment of this documents version.
 *
 * #### Example:
 *
 *     const doc = await Model.findById(id);
 *     doc.increment();
 *     await doc.save();
 *
 * @see versionKeys https://mongoosejs.com/docs/guide.html#versionKey
 * @memberOf Model
 * @method increment
 * @api public
 */

Model.prototype.increment = increment;

/**
 * Returns a query object
 *
 * @api private
 * @method $__where
 * @memberOf Model
 * @instance
 */

Model.prototype.$__where = function _where(where) {
  where || (where = {});

  if (!where._id) {
    where._id = this._doc._id;
  }

  if (this._doc._id === void 0) {
    return new MongooseError('No _id found on document!');
  }

  return where;
};

/**
 * Delete this document from the db.
 *
 * #### Example:
 *
 *     await product.deleteOne();
 *     await Product.findById(product._id); // null
 *
 * @return {Query} Query
 * @api public
 */

Model.prototype.deleteOne = function deleteOne(options) {
  if (typeof options === 'function' ||
      typeof arguments[1] === 'function') {
    throw new MongooseError('Model.prototype.deleteOne() no longer accepts a callback');
  }

  if (!options) {
    options = {};
  }

  if (options.hasOwnProperty('session')) {
    this.$session(options.session);
  }

  const self = this;
  const where = this.$__where();
  if (where instanceof Error) {
    throw where;
  }
  const query = self.constructor.deleteOne(where, options);

  if (this.$session() != null) {
    if (!('session' in query.options)) {
      query.options.session = this.$session();
    }
  }

  query.pre(function queryPreDeleteOne(cb) {
    self.constructor._middleware.execPre('deleteOne', self, [self], cb);
  });
  query.pre(function callSubdocPreHooks(cb) {
    each(self.$getAllSubdocs(), (subdoc, cb) => {
      subdoc.constructor._middleware.execPre('deleteOne', subdoc, [subdoc], cb);
    }, cb);
  });
  query.pre(function skipIfAlreadyDeleted(cb) {
    if (self.$__.isDeleted) {
      return cb(Kareem.skipWrappedFunction());
    }
    return cb();
  });
  query.post(function callSubdocPostHooks(cb) {
    each(self.$getAllSubdocs(), (subdoc, cb) => {
      subdoc.constructor._middleware.execPost('deleteOne', subdoc, [subdoc], {}, cb);
    }, cb);
  });
  query.post(function queryPostDeleteOne(cb) {
    self.constructor._middleware.execPost('deleteOne', self, [self], {}, cb);
  });

  return query;
};

/**
 * Returns the model instance used to create this document if no `name` specified.
 * If `name` specified, returns the model with the given `name`.
 *
 * #### Example:
 *
 *     const doc = new Tank({});
 *     doc.$model() === Tank; // true
 *     await doc.$model('User').findById(id);
 *
 * @param {String} [name] model name
 * @method $model
 * @api public
 * @return {Model}
 */

Model.prototype.$model = function $model(name) {
  if (arguments.length === 0) {
    return this.constructor;
  }
  return this[modelDbSymbol].model(name);
};

/**
 * Returns the model instance used to create this document if no `name` specified.
 * If `name` specified, returns the model with the given `name`.
 *
 * #### Example:
 *
 *     const doc = new Tank({});
 *     doc.$model() === Tank; // true
 *     await doc.$model('User').findById(id);
 *
 * @param {String} [name] model name
 * @method model
 * @api public
 * @return {Model}
 */

Model.prototype.model = Model.prototype.$model;

/**
 * Returns a document with `_id` only if at least one document exists in the database that matches
 * the given `filter`, and `null` otherwise.
 *
 * Under the hood, `MyModel.exists({ answer: 42 })` is equivalent to
 * `MyModel.findOne({ answer: 42 }).select({ _id: 1 }).lean()`
 *
 * #### Example:
 *
 *     await Character.deleteMany({});
 *     await Character.create({ name: 'Jean-Luc Picard' });
 *
 *     await Character.exists({ name: /picard/i }); // { _id: ... }
 *     await Character.exists({ name: /riker/i }); // null
 *
 * This function triggers the following middleware.
 *
 * - `findOne()`
 *
 * @param {Object} filter
 * @param {Object} [options] optional see [`Query.prototype.setOptions()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.setOptions())
 * @return {Query}
 */

Model.exists = function exists(filter, options) {
  _checkContext(this, 'exists');
  if (typeof arguments[2] === 'function') {
    throw new MongooseError('Model.exists() no longer accepts a callback');
  }

  const query = this.findOne(filter).
    select({ _id: 1 }).
    lean().
    setOptions(options);

  return query;
};

/**
 * Adds a discriminator type.
 *
 * #### Example:
 *
 *     function BaseSchema() {
 *       Schema.apply(this, arguments);
 *
 *       this.add({
 *         name: String,
 *         createdAt: Date
 *       });
 *     }
 *     util.inherits(BaseSchema, Schema);
 *
 *     const PersonSchema = new BaseSchema();
 *     const BossSchema = new BaseSchema({ department: String });
 *
 *     const Person = mongoose.model('Person', PersonSchema);
 *     const Boss = Person.discriminator('Boss', BossSchema);
 *     new Boss().__t; // "Boss". `__t` is the default `discriminatorKey`
 *
 *     const employeeSchema = new Schema({ boss: ObjectId });
 *     const Employee = Person.discriminator('Employee', employeeSchema, 'staff');
 *     new Employee().__t; // "staff" because of 3rd argument above
 *
 * @param {String} name discriminator model name
 * @param {Schema} schema discriminator model schema
 * @param {Object|String} [options] If string, same as `options.value`.
 * @param {String} [options.value] the string stored in the `discriminatorKey` property. If not specified, Mongoose uses the `name` parameter.
 * @param {Boolean} [options.clone=true] By default, `discriminator()` clones the given `schema`. Set to `false` to skip cloning.
 * @param {Boolean} [options.overwriteModels=false] by default, Mongoose does not allow you to define a discriminator with the same name as another discriminator. Set this to allow overwriting discriminators with the same name.
 * @param {Boolean} [options.mergeHooks=true] By default, Mongoose merges the base schema's hooks with the discriminator schema's hooks. Set this option to `false` to make Mongoose use the discriminator schema's hooks instead.
 * @param {Boolean} [options.mergePlugins=true] By default, Mongoose merges the base schema's plugins with the discriminator schema's plugins. Set this option to `false` to make Mongoose use the discriminator schema's plugins instead.
 * @return {Model} The newly created discriminator model
 * @api public
 */

Model.discriminator = function(name, schema, options) {
  let model;
  if (typeof name === 'function') {
    model = name;
    name = utils.getFunctionName(model);
    if (!(model.prototype instanceof Model)) {
      throw new MongooseError('The provided class ' + name + ' must extend Model');
    }
  }

  options = options || {};
  const value = utils.isPOJO(options) ? options.value : options;
  const clone = typeof options.clone === 'boolean' ? options.clone : true;
  const mergePlugins = typeof options.mergePlugins === 'boolean' ? options.mergePlugins : true;

  _checkContext(this, 'discriminator');

  if (utils.isObject(schema) && !schema.instanceOfSchema) {
    schema = new Schema(schema);
  }
  if (schema instanceof Schema && clone) {
    schema = schema.clone();
  }

  schema = discriminator(this, name, schema, value, mergePlugins, options.mergeHooks);
  if (this.db.models[name] && !schema.options.overwriteModels) {
    throw new OverwriteModelError(name);
  }

  schema.$isRootDiscriminator = true;
  schema.$globalPluginsApplied = true;

  model = this.db.model(model || name, schema, this.$__collection.name);
  this.discriminators[name] = model;
  const d = this.discriminators[name];
  Object.setPrototypeOf(d.prototype, this.prototype);
  Object.defineProperty(d, 'baseModelName', {
    value: this.modelName,
    configurable: true,
    writable: false
  });

  // apply methods and statics
  applyMethods(d, schema);
  applyStatics(d, schema);

  if (this[subclassedSymbol] != null) {
    for (const submodel of this[subclassedSymbol]) {
      submodel.discriminators = submodel.discriminators || {};
      submodel.discriminators[name] =
        model.__subclass(model.db, schema, submodel.collection.name);
    }
  }

  return d;
};

/**
 * Make sure `this` is a model
 * @api private
 */

function _checkContext(ctx, fnName) {
  // Check context, because it is easy to mistakenly type
  // `new Model.discriminator()` and get an incomprehensible error
  if (ctx == null || ctx === global) {
    throw new MongooseError('`Model.' + fnName + '()` cannot run without a ' +
      'model as `this`. Make sure you are calling `MyModel.' + fnName + '()` ' +
      'where `MyModel` is a Mongoose model.');
  } else if (ctx[modelSymbol] == null) {
    throw new MongooseError('`Model.' + fnName + '()` cannot run without a ' +
      'model as `this`. Make sure you are not calling ' +
      '`new Model.' + fnName + '()`');
  }
}

// Model (class) features

/*!
 * Give the constructor the ability to emit events.
 */

for (const i in EventEmitter.prototype) {
  Model[i] = EventEmitter.prototype[i];
}

/**
 * This function is responsible for initializing the underlying connection in MongoDB based on schema options.
 * This function performs the following operations:
 *
 * - `createCollection()` unless [`autoCreate`](https://mongoosejs.com/docs/guide.html#autoCreate) option is turned off
 * - `ensureIndexes()` unless [`autoIndex`](https://mongoosejs.com/docs/guide.html#autoIndex) option is turned off
 * - `createSearchIndex()` on all schema search indexes if `autoSearchIndex` is enabled.
 *
 * Mongoose calls this function automatically when a model is a created using
 * [`mongoose.model()`](https://mongoosejs.com/docs/api/mongoose.html#Mongoose.prototype.model()) or
 * [`connection.model()`](https://mongoosejs.com/docs/api/connection.html#Connection.prototype.model()), so you
 * don't need to call `init()` to trigger index builds.
 *
 * However, you _may_ need to call `init()`  to get back a promise that will resolve when your indexes are finished.
 * Calling `await Model.init()` is helpful if you need to wait for indexes to build before continuing.
 * For example, if you want to wait for unique indexes to build before continuing with a test case.
 *
 * #### Example:
 *
 *     const eventSchema = new Schema({ thing: { type: 'string', unique: true } })
 *     // This calls `Event.init()` implicitly, so you don't need to call
 *     // `Event.init()` on your own.
 *     const Event = mongoose.model('Event', eventSchema);
 *
 *     await Event.init();
 *     console.log('Indexes are done building!');
 *
 * @api public
 * @returns {Promise}
 */

Model.init = function init() {
  _checkContext(this, 'init');
  if (typeof arguments[0] === 'function') {
    throw new MongooseError('Model.init() no longer accepts a callback');
  }

  this.schema.emit('init', this);

  if (this.$init != null) {
    return this.$init;
  }

  const conn = this.db;
  const _ensureIndexes = async() => {
    const autoIndex = utils.getOption(
      'autoIndex',
      this.schema.options,
      conn.config,
      conn.base.options
    );
    if (!autoIndex) {
      return;
    }
    return await this.ensureIndexes({ _automatic: true });
  };
  const _createSearchIndexes = async() => {
    const autoSearchIndex = utils.getOption(
      'autoSearchIndex',
      this.schema.options,
      conn.config,
      conn.base.options
    );
    if (!autoSearchIndex) {
      return;
    }

    const results = [];
    for (const searchIndex of this.schema._searchIndexes) {
      results.push(await this.createSearchIndex(searchIndex));
    }
    return results;
  };
  const _createCollection = async() => {
    if ((conn.readyState === STATES.connecting || conn.readyState === STATES.disconnected) && conn._shouldBufferCommands()) {
      await new Promise(resolve => {
        conn._queue.push({ fn: resolve });
      });
    }
    const autoCreate = utils.getOption(
      'autoCreate',
      this.schema.options,
      conn.config,
      conn.base.options
    );
    if (!autoCreate) {
      return;
    }
    return await this.createCollection();
  };

  this.$init = _createCollection().
    then(() => _ensureIndexes()).
    then(() => _createSearchIndexes());

  const _catch = this.$init.catch;
  const _this = this;
  this.$init.catch = function() {
    _this.$caught = true;
    return _catch.apply(_this.$init, arguments);
  };

  return this.$init;
};


/**
 * Create the collection for this model. By default, if no indexes are specified,
 * mongoose will not create the collection for the model until any documents are
 * created. Use this method to create the collection explicitly.
 *
 * Note 1: You may need to call this before starting a transaction
 * See https://www.mongodb.com/docs/manual/core/transactions/#transactions-and-operations
 *
 * Note 2: You don't have to call this if your schema contains index or unique field.
 * In that case, just use `Model.init()`
 *
 * #### Example:
 *
 *     const userSchema = new Schema({ name: String })
 *     const User = mongoose.model('User', userSchema);
 *
 *     User.createCollection().then(function(collection) {
 *       console.log('Collection is created!');
 *     });
 *
 * @api public
 * @param {Object} [options] see [MongoDB driver docs](https://mongodb.github.io/node-mongodb-native/4.9/classes/Db.html#createCollection)
 * @returns {Promise}
 */

Model.createCollection = async function createCollection(options) {
  _checkContext(this, 'createCollection');
  if (typeof arguments[0] === 'function' || typeof arguments[1] === 'function') {
    throw new MongooseError('Model.createCollection() no longer accepts a callback');
  }

  const shouldSkip = await new Promise((resolve, reject) => {
    this.hooks.execPre('createCollection', this, [options], (err) => {
      if (err != null) {
        if (err instanceof Kareem.skipWrappedFunction) {
          return resolve(true);
        }
        return reject(err);
      }
      resolve();
    });
  });

  const collectionOptions = this &&
    this.schema &&
    this.schema.options &&
    this.schema.options.collectionOptions;
  if (collectionOptions != null) {
    options = Object.assign({}, collectionOptions, options);
  }

  const schemaCollation = this &&
    this.schema &&
    this.schema.options &&
    this.schema.options.collation;
  if (schemaCollation != null) {
    options = Object.assign({ collation: schemaCollation }, options);
  }
  const capped = this &&
    this.schema &&
    this.schema.options &&
    this.schema.options.capped;
  if (capped != null) {
    if (typeof capped === 'number') {
      options = Object.assign({ capped: true, size: capped }, options);
    } else if (typeof capped === 'object') {
      options = Object.assign({ capped: true }, capped, options);
    }
  }
  const timeseries = this &&
    this.schema &&
    this.schema.options &&
    this.schema.options.timeseries;
  if (timeseries != null) {
    options = Object.assign({ timeseries }, options);
    if (options.expireAfterSeconds != null) {
      // do nothing
    } else if (options.expires != null) {
      utils.expires(options);
    } else if (this.schema.options.expireAfterSeconds != null) {
      options.expireAfterSeconds = this.schema.options.expireAfterSeconds;
    } else if (this.schema.options.expires != null) {
      options.expires = this.schema.options.expires;
      utils.expires(options);
    }
  }

  const clusteredIndex = this &&
    this.schema &&
    this.schema.options &&
    this.schema.options.clusteredIndex;
  if (clusteredIndex != null) {
    options = Object.assign({ clusteredIndex: { ...clusteredIndex, unique: true } }, options);
  }

  try {
    if (!shouldSkip) {
      await this.db.createCollection(this.$__collection.collectionName, options);
    }
  } catch (err) {
    if (err != null && (err.name !== 'MongoServerError' || err.code !== 48)) {
      await new Promise((resolve, reject) => {
        const _opts = { error: err };
        this.hooks.execPost('createCollection', this, [null], _opts, (err) => {
          if (err != null) {
            return reject(err);
          }
          resolve();
        });
      });
    }
  }

  await new Promise((resolve, reject) => {
    this.hooks.execPost('createCollection', this, [this.$__collection], (err) => {
      if (err != null) {
        return reject(err);
      }
      resolve();
    });
  });

  return this.$__collection;
};

/**
 * Makes the indexes in MongoDB match the indexes defined in this model's
 * schema. This function will drop any indexes that are not defined in
 * the model's schema except the `_id` index, and build any indexes that
 * are in your schema but not in MongoDB.
 *
 * See the [introductory blog post](https://thecodebarbarian.com/whats-new-in-mongoose-5-2-syncindexes)
 * for more information.
 *
 * #### Example:
 *
 *     const schema = new Schema({ name: { type: String, unique: true } });
 *     const Customer = mongoose.model('Customer', schema);
 *     await Customer.collection.createIndex({ age: 1 }); // Index is not in schema
 *     // Will drop the 'age' index and create an index on `name`
 *     await Customer.syncIndexes();
 *
 * You should be careful about running `syncIndexes()` on production applications under heavy load,
 * because index builds are expensive operations, and unexpected index drops can lead to degraded
 * performance. Before running `syncIndexes()`, you can use the [`diffIndexes()` function](#Model.diffIndexes())
 * to check what indexes `syncIndexes()` will drop and create.
 *
 * #### Example:
 *
 *     const { toDrop, toCreate } = await Model.diffIndexes();
 *     toDrop; // Array of strings containing names of indexes that `syncIndexes()` will drop
 *     toCreate; // Array of strings containing names of indexes that `syncIndexes()` will create
 *
 * @param {Object} [options] options to pass to `ensureIndexes()`
 * @param {Boolean} [options.background=null] if specified, overrides each index's `background` property
 * @return {Promise}
 * @api public
 */

Model.syncIndexes = async function syncIndexes(options) {
  _checkContext(this, 'syncIndexes');
  if (typeof arguments[0] === 'function' || typeof arguments[1] === 'function') {
    throw new MongooseError('Model.syncIndexes() no longer accepts a callback');
  }

  const model = this;

  try {
    await model.createCollection();
  } catch (err) {
    if (err != null && (err.name !== 'MongoServerError' || err.code !== 48)) {
      throw err;
    }
  }

  const diffIndexesResult = await model.diffIndexes();
  const dropped = await model.cleanIndexes({ ...options, toDrop: diffIndexesResult.toDrop });
  await model.createIndexes({ ...options, toCreate: diffIndexesResult.toCreate });

  return dropped;
};

/**
 * Create an [Atlas search index](https://www.mongodb.com/docs/atlas/atlas-search/create-index/).
 * This function only works when connected to MongoDB Atlas.
 *
 * #### Example:
 *
 *     const schema = new Schema({ name: { type: String, unique: true } });
 *     const Customer = mongoose.model('Customer', schema);
 *     await Customer.createSearchIndex({ name: 'test', definition: { mappings: { dynamic: true } } });
 *
 * @param {Object} description index options, including `name` and `definition`
 * @param {String} description.name
 * @param {Object} description.definition
 * @return {Promise}
 * @api public
 */

Model.createSearchIndex = async function createSearchIndex(description) {
  _checkContext(this, 'createSearchIndex');

  return await this.$__collection.createSearchIndex(description);
};

/**
 * Update an existing [Atlas search index](https://www.mongodb.com/docs/atlas/atlas-search/create-index/).
 * This function only works when connected to MongoDB Atlas.
 *
 * #### Example:
 *
 *     const schema = new Schema({ name: { type: String, unique: true } });
 *     const Customer = mongoose.model('Customer', schema);
 *     await Customer.updateSearchIndex('test', { mappings: { dynamic: true } });
 *
 * @param {String} name
 * @param {Object} definition
 * @return {Promise}
 * @api public
 */

Model.updateSearchIndex = async function updateSearchIndex(name, definition) {
  _checkContext(this, 'updateSearchIndex');

  return await this.$__collection.updateSearchIndex(name, definition);
};

/**
 * Delete an existing [Atlas search index](https://www.mongodb.com/docs/atlas/atlas-search/create-index/) by name.
 * This function only works when connected to MongoDB Atlas.
 *
 * #### Example:
 *
 *     const schema = new Schema({ name: { type: String, unique: true } });
 *     const Customer = mongoose.model('Customer', schema);
 *     await Customer.dropSearchIndex('test');
 *
 * @param {String} name
 * @return {Promise}
 * @api public
 */

Model.dropSearchIndex = async function dropSearchIndex(name) {
  _checkContext(this, 'dropSearchIndex');

  return await this.$__collection.dropSearchIndex(name);
};

/**
 * Does a dry-run of `Model.syncIndexes()`, returning the indexes that `syncIndexes()` would drop and create if you were to run `syncIndexes()`.
 *
 * #### Example:
 *
 *     const { toDrop, toCreate } = await Model.diffIndexes();
 *     toDrop; // Array of strings containing names of indexes that `syncIndexes()` will drop
 *     toCreate; // Array of strings containing names of indexes that `syncIndexes()` will create
 *
 * @param {Object} [options]
 * @return {Promise<Object>} contains the indexes that would be dropped in MongoDB and indexes that would be created in MongoDB as `{ toDrop: string[], toCreate: string[] }`.
 */

Model.diffIndexes = async function diffIndexes() {
  if (typeof arguments[0] === 'function' || typeof arguments[1] === 'function') {
    throw new MongooseError('Model.syncIndexes() no longer accepts a callback');
  }

  const model = this;

  let dbIndexes = await model.listIndexes().catch(err => {
    if (err.codeName == 'NamespaceNotFound') {
      return undefined;
    }
    throw err;
  });
  if (dbIndexes === undefined) {
    dbIndexes = [];
  }
  dbIndexes = getRelatedDBIndexes(model, dbIndexes);

  const schema = model.schema;
  const schemaIndexes = getRelatedSchemaIndexes(model, schema.indexes());

  const toDrop = getIndexesToDrop(schema, schemaIndexes, dbIndexes);
  const toCreate = getIndexesToCreate(schema, schemaIndexes, dbIndexes, toDrop);

  return { toDrop, toCreate };
};

function getIndexesToCreate(schema, schemaIndexes, dbIndexes, toDrop) {
  const toCreate = [];

  for (const [schemaIndexKeysObject, schemaIndexOptions] of schemaIndexes) {
    let found = false;

    const options = decorateDiscriminatorIndexOptions(schema, clone(schemaIndexOptions));

    for (const index of dbIndexes) {
      if (isDefaultIdIndex(index)) {
        continue;
      }
      if (
        isIndexEqual(schemaIndexKeysObject, options, index) &&
        !toDrop.includes(index.name)
      ) {
        found = true;
        break;
      }
    }

    if (!found) {
      toCreate.push(schemaIndexKeysObject);
    }
  }

  return toCreate;
}

function getIndexesToDrop(schema, schemaIndexes, dbIndexes) {
  const toDrop = [];

  for (const dbIndex of dbIndexes) {
    let found = false;
    // Never try to drop `_id` index, MongoDB server doesn't allow it
    if (isDefaultIdIndex(dbIndex)) {
      continue;
    }

    for (const [schemaIndexKeysObject, schemaIndexOptions] of schemaIndexes) {
      const options = decorateDiscriminatorIndexOptions(schema, clone(schemaIndexOptions));
      applySchemaCollation(schemaIndexKeysObject, options, schema.options);

      if (isIndexEqual(schemaIndexKeysObject, options, dbIndex)) {
        found = true;
        break;
      }
    }

    if (!found) {
      toDrop.push(dbIndex.name);
    }
  }

  return toDrop;
}
/**
 * Deletes all indexes that aren't defined in this model's schema. Used by
 * `syncIndexes()`.
 *
 * The returned promise resolves to a list of the dropped indexes' names as an array
 *
 * @param {Function} [callback] optional callback
 * @return {Promise|undefined} Returns `undefined` if callback is specified, returns a promise if no callback.
 * @api public
 */

Model.cleanIndexes = async function cleanIndexes(options) {
  _checkContext(this, 'cleanIndexes');
  if (typeof arguments[0] === 'function' || typeof arguments[1] === 'function') {
    throw new MongooseError('Model.cleanIndexes() no longer accepts a callback');
  }
  const model = this;

  const collection = model.$__collection;

  if (Array.isArray(options && options.toDrop)) {
    const res = await _dropIndexes(options.toDrop, collection);
    return res;
  }

  const res = await model.diffIndexes();
  return await _dropIndexes(res.toDrop, collection);
};

async function _dropIndexes(toDrop, collection) {
  if (toDrop.length === 0) {
    return [];
  }

  await Promise.all(toDrop.map(indexName => collection.dropIndex(indexName)));
  return toDrop;
}

/**
 * Lists the indexes currently defined in MongoDB. This may or may not be
 * the same as the indexes defined in your schema depending on whether you
 * use the [`autoIndex` option](https://mongoosejs.com/docs/guide.html#autoIndex) and if you
 * build indexes manually.
 *
 * @return {Promise}
 * @api public
 */

Model.listIndexes = async function listIndexes() {
  _checkContext(this, 'listIndexes');
  if (typeof arguments[0] === 'function') {
    throw new MongooseError('Model.listIndexes() no longer accepts a callback');
  }

  if (this.$__collection.buffer) {
    await new Promise(resolve => {
      this.$__collection.addQueue(resolve);
    });
  }

  return this.$__collection.listIndexes().toArray();
};

/**
 * Sends `createIndex` commands to mongo for each index declared in the schema.
 * The `createIndex` commands are sent in series.
 *
 * #### Example:
 *
 *     await Event.ensureIndexes();
 *
 * After completion, an `index` event is emitted on this `Model` passing an error if one occurred.
 *
 * #### Example:
 *
 *     const eventSchema = new Schema({ thing: { type: 'string', unique: true } })
 *     const Event = mongoose.model('Event', eventSchema);
 *
 *     Event.on('index', function (err) {
 *       if (err) console.error(err); // error occurred during index creation
 *     });
 *
 * _NOTE: It is not recommended that you run this in production. Index creation may impact database performance depending on your load. Use with caution._
 *
 * @param {Object} [options] internal options
 * @return {Promise}
 * @api public
 */

Model.ensureIndexes = async function ensureIndexes(options) {
  _checkContext(this, 'ensureIndexes');
  if (typeof arguments[0] === 'function' || typeof arguments[1] === 'function') {
    throw new MongooseError('Model.ensureIndexes() no longer accepts a callback');
  }

  await new Promise((resolve, reject) => {
    _ensureIndexes(this, options, (err) => {
      if (err != null) {
        return reject(err);
      }
      resolve();
    });
  });
};

/**
 * Similar to `ensureIndexes()`, except for it uses the [`createIndex`](https://mongodb.github.io/node-mongodb-native/4.9/classes/Db.html#createIndex)
 * function.
 *
 * @param {Object} [options] internal options
 * @return {Promise}
 * @api public
 */

Model.createIndexes = async function createIndexes(options) {
  _checkContext(this, 'createIndexes');

  if (typeof arguments[0] === 'function' || typeof arguments[1] === 'function') {
    throw new MongooseError('Model.createIndexes() no longer accepts a callback');
  }

  return this.ensureIndexes(options);
};


/*!
 * ignore
 */

function _ensureIndexes(model, options, callback) {
  const indexes = model.schema.indexes();
  let indexError;

  options = options || {};
  const done = function(err) {
    if (err && !model.$caught) {
      model.emit('error', err);
    }
    model.emit('index', err || indexError);
    callback && callback(err || indexError);
  };

  for (const index of indexes) {
    if (isDefaultIdIndex(index)) {
      utils.warn('mongoose: Cannot specify a custom index on `_id` for ' +
        'model name "' + model.modelName + '", ' +
        'MongoDB does not allow overwriting the default `_id` index. See ' +
        'https://bit.ly/mongodb-id-index');
    }
  }

  if (!indexes.length) {
    immediate(function() {
      done();
    });
    return;
  }
  // Indexes are created one-by-one to support how MongoDB < 2.4 deals
  // with background indexes.

  const indexSingleDone = function(err, fields, options, name) {
    model.emit('index-single-done', err, fields, options, name);
  };
  const indexSingleStart = function(fields, options) {
    model.emit('index-single-start', fields, options);
  };

  const baseSchema = model.schema._baseSchema;
  const baseSchemaIndexes = baseSchema ? baseSchema.indexes() : [];

  immediate(function() {
    // If buffering is off, do this manually.
    if (options._automatic && !model.collection.collection) {
      model.collection.addQueue(create, []);
    } else {
      create();
    }
  });


  function create() {
    if (options._automatic) {
      if (model.schema.options.autoIndex === false ||
          (model.schema.options.autoIndex == null && model.db.config.autoIndex === false)) {
        return done();
      }
    }

    const index = indexes.shift();
    if (!index) {
      return done();
    }
    if (options._automatic && index[1]._autoIndex === false) {
      return create();
    }

    if (baseSchemaIndexes.find(i => utils.deepEqual(i, index))) {
      return create();
    }

    const indexFields = clone(index[0]);
    const indexOptions = clone(index[1]);

    delete indexOptions._autoIndex;
    decorateDiscriminatorIndexOptions(model.schema, indexOptions);
    applyWriteConcern(model.schema, indexOptions);
    applySchemaCollation(indexFields, indexOptions, model.schema.options);

    indexSingleStart(indexFields, options);

    if ('background' in options) {
      indexOptions.background = options.background;
    }

    if ('toCreate' in options) {
      if (options.toCreate.length === 0) {
        return done();
      }
    }

    model.collection.createIndex(indexFields, indexOptions).then(
      name => {
        indexSingleDone(null, indexFields, indexOptions, name);
        create();
      },
      err => {
        if (!indexError) {
          indexError = err;
        }
        if (!model.$caught) {
          model.emit('error', err);
        }

        indexSingleDone(err, indexFields, indexOptions);
        create();
      }
    );
  }
}

/**
 * Schema the model uses.
 *
 * @property schema
 * @static
 * @api public
 * @memberOf Model
 */

Model.schema;

/**
 * Connection instance the model uses.
 *
 * @property db
 * @static
 * @api public
 * @memberOf Model
 */

Model.db;

/**
 * Collection the model uses.
 *
 * @property collection
 * @api public
 * @memberOf Model
 */

Model.collection;

/**
 * Internal collection the model uses.
 *
 * @property collection
 * @api private
 * @memberOf Model
 */
Model.$__collection;

/**
 * Base Mongoose instance the model uses.
 *
 * @property base
 * @api public
 * @memberOf Model
 */

Model.base;

/**
 * Registered discriminators for this model.
 *
 * @property discriminators
 * @api public
 * @memberOf Model
 */

Model.discriminators;

/**
 * Translate any aliases fields/conditions so the final query or document object is pure
 *
 * #### Example:
 *
 *     await Character.find(Character.translateAliases({
 *        '名': 'Eddard Stark' // Alias for 'name'
 *     });
 *
 * By default, `translateAliases()` overwrites raw fields with aliased fields.
 * So if `n` is an alias for `name`, `{ n: 'alias', name: 'raw' }` will resolve to `{ name: 'alias' }`.
 * However, you can set the `errorOnDuplicates` option to throw an error if there are potentially conflicting paths.
 * The `translateAliases` option for queries uses `errorOnDuplicates`.
 *
 * #### Note:
 *
 * Only translate arguments of object type anything else is returned raw
 *
 * @param {Object} fields fields/conditions that may contain aliased keys
 * @param {Boolean} [errorOnDuplicates] if true, throw an error if there's both a key and an alias for that key in `fields`
 * @return {Object} the translated 'pure' fields/conditions
 */
Model.translateAliases = function translateAliases(fields, errorOnDuplicates) {
  _checkContext(this, 'translateAliases');

  const translate = (key, value) => {
    let alias;
    const translated = [];
    const fieldKeys = key.split('.');
    let currentSchema = this.schema;
    for (const i in fieldKeys) {
      const name = fieldKeys[i];
      if (currentSchema && currentSchema.aliases[name]) {
        alias = currentSchema.aliases[name];
        if (errorOnDuplicates && alias in fields) {
          throw new MongooseError(`Provided object has both field "${name}" and its alias "${alias}"`);
        }
        // Alias found,
        translated.push(alias);
      } else {
        alias = name;
        // Alias not found, so treat as un-aliased key
        translated.push(name);
      }

      // Check if aliased path is a schema
      if (currentSchema && currentSchema.paths[alias]) {
        currentSchema = currentSchema.paths[alias].schema;
      }
      else
        currentSchema = null;
    }

    const translatedKey = translated.join('.');
    if (fields instanceof Map)
      fields.set(translatedKey, value);
    else
      fields[translatedKey] = value;

    if (translatedKey !== key) {
      // We'll be using the translated key instead
      if (fields instanceof Map) {
        // Delete from map
        fields.delete(key);
      } else {
        // Delete from object
        delete fields[key]; // We'll be using the translated key instead
      }
    }
    return fields;
  };

  if (typeof fields === 'object') {
    // Fields is an object (query conditions or document fields)
    if (fields instanceof Map) {
      // A Map was supplied
      for (const field of new Map(fields)) {
        fields = translate(field[0], field[1]);
      }
    } else {
      // Infer a regular object was supplied
      for (const key of Object.keys(fields)) {
        fields = translate(key, fields[key]);
        if (key[0] === '$') {
          if (Array.isArray(fields[key])) {
            for (const i in fields[key]) {
              // Recursively translate nested queries
              fields[key][i] = this.translateAliases(fields[key][i]);
            }
          } else {
            this.translateAliases(fields[key]);
          }
        }
      }
    }

    return fields;
  } else {
    // Don't know typeof fields
    return fields;
  }
};

/**
 * Deletes the first document that matches `conditions` from the collection.
 * It returns an object with the property `deletedCount` indicating how many documents were deleted.
 * Behaves like `remove()`, but deletes at most one document regardless of the
 * `single` option.
 *
 * #### Example:
 *
 *     await Character.deleteOne({ name: 'Eddard Stark' }); // returns {deletedCount: 1}
 *
 * #### Note:
 *
 * This function triggers `deleteOne` query hooks. Read the
 * [middleware docs](https://mongoosejs.com/docs/middleware.html#naming) to learn more.
 *
 * @param {Object} conditions
 * @param {Object} [options] optional see [`Query.prototype.setOptions()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.setOptions())
 * @param {Boolean} [options.translateAliases=null] If set to `true`, translates any schema-defined aliases in `filter`, `projection`, `update`, and `distinct`. Throws an error if there are any conflicts where both alias and raw property are defined on the same object.
 * @return {Query}
 * @api public
 */

Model.deleteOne = function deleteOne(conditions, options) {
  _checkContext(this, 'deleteOne');

  if (typeof arguments[0] === 'function' || typeof arguments[1] === 'function' || typeof arguments[2] === 'function') {
    throw new MongooseError('Model.prototype.deleteOne() no longer accepts a callback');
  }

  const mq = new this.Query({}, {}, this, this.$__collection);
  mq.setOptions(options);

  return mq.deleteOne(conditions);
};

/**
 * Deletes all of the documents that match `conditions` from the collection.
 * It returns an object with the property `deletedCount` containing the number of documents deleted.
 * Behaves like `remove()`, but deletes all documents that match `conditions`
 * regardless of the `single` option.
 *
 * #### Example:
 *
 *     await Character.deleteMany({ name: /Stark/, age: { $gte: 18 } }); // returns {deletedCount: x} where x is the number of documents deleted.
 *
 * #### Note:
 *
 * This function triggers `deleteMany` query hooks. Read the
 * [middleware docs](https://mongoosejs.com/docs/middleware.html#naming) to learn more.
 *
 * @param {Object} conditions
 * @param {Object} [options] optional see [`Query.prototype.setOptions()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.setOptions())
 * @param {Boolean} [options.translateAliases=null] If set to `true`, translates any schema-defined aliases in `filter`, `projection`, `update`, and `distinct`. Throws an error if there are any conflicts where both alias and raw property are defined on the same object.
 * @return {Query}
 * @api public
 */

Model.deleteMany = function deleteMany(conditions, options) {
  _checkContext(this, 'deleteMany');

  if (typeof arguments[0] === 'function' || typeof arguments[1] === 'function' || typeof arguments[2] === 'function') {
    throw new MongooseError('Model.deleteMany() no longer accepts a callback');
  }

  const mq = new this.Query({}, {}, this, this.$__collection);
  mq.setOptions(options);

  return mq.deleteMany(conditions);
};

/**
 * Finds documents.
 *
 * Mongoose casts the `filter` to match the model's schema before the command is sent.
 * See our [query casting tutorial](https://mongoosejs.com/docs/tutorials/query_casting.html) for
 * more information on how Mongoose casts `filter`.
 *
 * #### Example:
 *
 *     // find all documents
 *     await MyModel.find({});
 *
 *     // find all documents named john and at least 18
 *     await MyModel.find({ name: 'john', age: { $gte: 18 } }).exec();
 *
 *     // executes, name LIKE john and only selecting the "name" and "friends" fields
 *     await MyModel.find({ name: /john/i }, 'name friends').exec();
 *
 *     // passing options
 *     await MyModel.find({ name: /john/i }, null, { skip: 10 }).exec();
 *
 * @param {Object|ObjectId} filter
 * @param {Object|String|String[]} [projection] optional fields to return, see [`Query.prototype.select()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.select())
 * @param {Object} [options] optional see [`Query.prototype.setOptions()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.setOptions())
 * @param {Boolean} [options.translateAliases=null] If set to `true`, translates any schema-defined aliases in `filter`, `projection`, `update`, and `distinct`. Throws an error if there are any conflicts where both alias and raw property are defined on the same object.
 * @return {Query}
 * @see field selection https://mongoosejs.com/docs/api/query.html#Query.prototype.select()
 * @see query casting https://mongoosejs.com/docs/tutorials/query_casting.html
 * @api public
 */

Model.find = function find(conditions, projection, options) {
  _checkContext(this, 'find');
  if (typeof arguments[0] === 'function' || typeof arguments[1] === 'function' || typeof arguments[2] === 'function' || typeof arguments[3] === 'function') {
    throw new MongooseError('Model.find() no longer accepts a callback');
  }

  const mq = new this.Query({}, {}, this, this.$__collection);
  mq.select(projection);
  mq.setOptions(options);

  return mq.find(conditions);
};

/**
 * Finds a single document by its _id field. `findById(id)` is almost*
 * equivalent to `findOne({ _id: id })`. If you want to query by a document's
 * `_id`, use `findById()` instead of `findOne()`.
 *
 * The `id` is cast based on the Schema before sending the command.
 *
 * This function triggers the following middleware.
 *
 * - `findOne()`
 *
 * \* Except for how it treats `undefined`. If you use `findOne()`, you'll see
 * that `findOne(undefined)` and `findOne({ _id: undefined })` are equivalent
 * to `findOne({})` and return arbitrary documents. However, mongoose
 * translates `findById(undefined)` into `findOne({ _id: null })`.
 *
 * #### Example:
 *
 *     // Find the adventure with the given `id`, or `null` if not found
 *     await Adventure.findById(id).exec();
 *
 *     // select only the adventures name and length
 *     await Adventure.findById(id, 'name length').exec();
 *
 * @param {Any} id value of `_id` to query by
 * @param {Object|String|String[]} [projection] optional fields to return, see [`Query.prototype.select()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.select())
 * @param {Object} [options] optional see [`Query.prototype.setOptions()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.setOptions())
 * @return {Query}
 * @see field selection https://mongoosejs.com/docs/api/query.html#Query.prototype.select()
 * @see lean queries https://mongoosejs.com/docs/tutorials/lean.html
 * @see findById in Mongoose https://masteringjs.io/tutorials/mongoose/find-by-id
 * @api public
 */

Model.findById = function findById(id, projection, options) {
  _checkContext(this, 'findById');
  if (typeof arguments[0] === 'function' || typeof arguments[1] === 'function' || typeof arguments[2] === 'function') {
    throw new MongooseError('Model.findById() no longer accepts a callback');
  }

  if (typeof id === 'undefined') {
    id = null;
  }

  return this.findOne({ _id: id }, projection, options);
};

/**
 * Finds one document.
 *
 * The `conditions` are cast to their respective SchemaTypes before the command is sent.
 *
 * *Note:* `conditions` is optional, and if `conditions` is null or undefined,
 * mongoose will send an empty `findOne` command to MongoDB, which will return
 * an arbitrary document. If you're querying by `_id`, use `findById()` instead.
 *
 * #### Example:
 *
 *     // Find one adventure whose `country` is 'Croatia', otherwise `null`
 *     await Adventure.findOne({ country: 'Croatia' }).exec();
 *
 *     // Model.findOne() no longer accepts a callback
 *
 *     // Select only the adventures name and length
 *     await Adventure.findOne({ country: 'Croatia' }, 'name length').exec();
 *
 * @param {Object} [conditions]
 * @param {Object|String|String[]} [projection] optional fields to return, see [`Query.prototype.select()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.select())
 * @param {Object} [options] optional see [`Query.prototype.setOptions()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.setOptions())
 * @param {Boolean} [options.translateAliases=null] If set to `true`, translates any schema-defined aliases in `filter`, `projection`, `update`, and `distinct`. Throws an error if there are any conflicts where both alias and raw property are defined on the same object.
 * @return {Query}
 * @see field selection https://mongoosejs.com/docs/api/query.html#Query.prototype.select()
 * @see lean queries https://mongoosejs.com/docs/tutorials/lean.html
 * @api public
 */

Model.findOne = function findOne(conditions, projection, options) {
  _checkContext(this, 'findOne');
  if (typeof arguments[0] === 'function' || typeof arguments[1] === 'function' || typeof arguments[2] === 'function') {
    throw new MongooseError('Model.findOne() no longer accepts a callback');
  }

  const mq = new this.Query({}, {}, this, this.$__collection);
  mq.select(projection);
  mq.setOptions(options);

  return mq.findOne(conditions);
};

/**
 * Estimates the number of documents in the MongoDB collection. Faster than
 * using `countDocuments()` for large collections because
 * `estimatedDocumentCount()` uses collection metadata rather than scanning
 * the entire collection.
 *
 * #### Example:
 *
 *     const numAdventures = await Adventure.estimatedDocumentCount();
 *
 * @param {Object} [options]
 * @return {Query}
 * @api public
 */

Model.estimatedDocumentCount = function estimatedDocumentCount(options) {
  _checkContext(this, 'estimatedDocumentCount');

  const mq = new this.Query({}, {}, this, this.$__collection);

  return mq.estimatedDocumentCount(options);
};

/**
 * Counts number of documents matching `filter` in a database collection.
 *
 * #### Example:
 *
 *     Adventure.countDocuments({ type: 'jungle' }, function (err, count) {
 *       console.log('there are %d jungle adventures', count);
 *     });
 *
 * If you want to count all documents in a large collection,
 * use the [`estimatedDocumentCount()` function](https://mongoosejs.com/docs/api/model.html#Model.estimatedDocumentCount())
 * instead. If you call `countDocuments({})`, MongoDB will always execute
 * a full collection scan and **not** use any indexes.
 *
 * The `countDocuments()` function is similar to `count()`, but there are a
 * [few operators that `countDocuments()` does not support](https://mongodb.github.io/node-mongodb-native/4.9/classes/Collection.html#countDocuments).
 * Below are the operators that `count()` supports but `countDocuments()` does not,
 * and the suggested replacement:
 *
 * - `$where`: [`$expr`](https://www.mongodb.com/docs/manual/reference/operator/query/expr/)
 * - `$near`: [`$geoWithin`](https://www.mongodb.com/docs/manual/reference/operator/query/geoWithin/) with [`$center`](https://www.mongodb.com/docs/manual/reference/operator/query/center/#op._S_center)
 * - `$nearSphere`: [`$geoWithin`](https://www.mongodb.com/docs/manual/reference/operator/query/geoWithin/) with [`$centerSphere`](https://www.mongodb.com/docs/manual/reference/operator/query/centerSphere/#op._S_centerSphere)
 *
 * @param {Object} filter
 * @return {Query}
 * @api public
 */

Model.countDocuments = function countDocuments(conditions, options) {
  _checkContext(this, 'countDocuments');
  if (typeof arguments[0] === 'function' || typeof arguments[1] === 'function' || typeof arguments[2] === 'function') {
    throw new MongooseError('Model.countDocuments() no longer accepts a callback');
  }

  const mq = new this.Query({}, {}, this, this.$__collection);
  if (options != null) {
    mq.setOptions(options);
  }

  return mq.countDocuments(conditions);
};


/**
 * Creates a Query for a `distinct` operation.
 *
 * #### Example:
 *
 *     const query = Link.distinct('url');
 *     query.exec();
 *
 * @param {String} field
 * @param {Object} [conditions] optional
 * @return {Query}
 * @api public
 */

Model.distinct = function distinct(field, conditions) {
  _checkContext(this, 'distinct');
  if (typeof arguments[0] === 'function' || typeof arguments[1] === 'function') {
    throw new MongooseError('Model.distinct() no longer accepts a callback');
  }

  const mq = new this.Query({}, {}, this, this.$__collection);

  return mq.distinct(field, conditions);
};

/**
 * Creates a Query, applies the passed conditions, and returns the Query.
 *
 * For example, instead of writing:
 *
 *     User.find({ age: { $gte: 21, $lte: 65 } });
 *
 * we can instead write:
 *
 *     User.where('age').gte(21).lte(65).exec();
 *
 * Since the Query class also supports `where` you can continue chaining
 *
 *     User
 *     .where('age').gte(21).lte(65)
 *     .where('name', /^b/i)
 *     ... etc
 *
 * @param {String} path
 * @param {Object} [val] optional value
 * @return {Query}
 * @api public
 */

Model.where = function where(path, val) {
  _checkContext(this, 'where');

  void val; // eslint
  const mq = new this.Query({}, {}, this, this.$__collection).find({});
  return mq.where.apply(mq, arguments);
};

/**
 * Creates a `Query` and specifies a `$where` condition.
 *
 * Sometimes you need to query for things in mongodb using a JavaScript expression. You can do so via `find({ $where: javascript })`, or you can use the mongoose shortcut method $where via a Query chain or from your mongoose Model.
 *
 *     Blog.$where('this.username.indexOf("val") !== -1').exec(function (err, docs) {});
 *
 * @param {String|Function} argument is a javascript string or anonymous function
 * @method $where
 * @memberOf Model
 * @return {Query}
 * @see Query.$where https://mongoosejs.com/docs/api/query.html#Query.prototype.$where
 * @api public
 */

Model.$where = function $where() {
  _checkContext(this, '$where');

  const mq = new this.Query({}, {}, this, this.$__collection).find({});
  return mq.$where.apply(mq, arguments);
};

/**
 * Issues a mongodb findOneAndUpdate command.
 *
 * Finds a matching document, updates it according to the `update` arg, passing any `options`, and returns the found document (if any) to the callback. The query executes if `callback` is passed else a Query object is returned.
 *
 * #### Example:
 *
 *     A.findOneAndUpdate(conditions, update, options)  // returns Query
 *     A.findOneAndUpdate(conditions, update)           // returns Query
 *     A.findOneAndUpdate()                             // returns Query
 *
 * #### Note:
 *
 * All top level update keys which are not `atomic` operation names are treated as set operations:
 *
 * #### Example:
 *
 *     const query = { name: 'borne' };
 *     Model.findOneAndUpdate(query, { name: 'jason bourne' }, options)
 *
 *     // is sent as
 *     Model.findOneAndUpdate(query, { $set: { name: 'jason bourne' }}, options)
 *
 * #### Note:
 *
 * `findOneAndX` and `findByIdAndX` functions support limited validation that
 * you can enable by setting the `runValidators` option.
 *
 * If you need full-fledged validation, use the traditional approach of first
 * retrieving the document.
 *
 *     const doc = await Model.findById(id);
 *     doc.name = 'jason bourne';
 *     await doc.save();
 *
 * @param {Object} [conditions]
 * @param {Object} [update]
 * @param {Object} [options] optional see [`Query.prototype.setOptions()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.setOptions())
 * @param {String} [options.returnDocument='before'] Has two possible values, `'before'` and `'after'`. By default, it will return the document before the update was applied.
 * @param {Object} [options.lean] if truthy, mongoose will return the document as a plain JavaScript object rather than a mongoose document. See [`Query.lean()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.lean()) and [the Mongoose lean tutorial](https://mongoosejs.com/docs/tutorials/lean.html).
 * @param {ClientSession} [options.session=null] The session associated with this query. See [transactions docs](https://mongoosejs.com/docs/transactions.html).
 * @param {Boolean|String} [options.strict] overwrites the schema's [strict mode option](https://mongoosejs.com/docs/guide.html#strict)
 * @param {Boolean} [options.timestamps=null] If set to `false` and [schema-level timestamps](https://mongoosejs.com/docs/guide.html#timestamps) are enabled, skip timestamps for this update. Note that this allows you to overwrite timestamps. Does nothing if schema-level timestamps are not set.
 * @param {Boolean} [options.upsert=false] if true, and no documents found, insert a new document
 * @param {Object|String|String[]} [options.projection=null] optional fields to return, see [`Query.prototype.select()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.select())
 * @param {Boolean} [options.new=false] if true, return the modified document rather than the original
 * @param {Object|String} [options.fields] Field selection. Equivalent to `.select(fields).findOneAndUpdate()`
 * @param {Number} [options.maxTimeMS] puts a time limit on the query - requires mongodb >= 2.6.0
 * @param {Object|String} [options.sort] if multiple docs are found by the conditions, sets the sort order to choose which doc to update.
 * @param {Boolean} [options.runValidators] if true, runs [update validators](https://mongoosejs.com/docs/validation.html#update-validators) on this command. Update validators validate the update operation against the model's schema
 * @param {Boolean} [options.setDefaultsOnInsert=true] If `setDefaultsOnInsert` and `upsert` are true, mongoose will apply the [defaults](https://mongoosejs.com/docs/defaults.html) specified in the model's schema if a new document is created
 * @param {Boolean} [options.includeResultMetadata] if true, returns the [raw result from the MongoDB driver](https://mongodb.github.io/node-mongodb-native/4.9/interfaces/ModifyResult.html)
 * @param {Boolean} [options.translateAliases=null] If set to `true`, translates any schema-defined aliases in `filter`, `projection`, `update`, and `distinct`. Throws an error if there are any conflicts where both alias and raw property are defined on the same object.
 * @param {Boolean} [options.overwriteDiscriminatorKey=false] Mongoose removes discriminator key updates from `update` by default, set `overwriteDiscriminatorKey` to `true` to allow updating the discriminator key
 * @return {Query}
 * @see Tutorial https://mongoosejs.com/docs/tutorials/findoneandupdate.html
 * @see mongodb https://www.mongodb.com/docs/manual/reference/command/findAndModify/
 * @api public
 */

Model.findOneAndUpdate = function(conditions, update, options) {
  _checkContext(this, 'findOneAndUpdate');
  if (typeof arguments[0] === 'function' || typeof arguments[1] === 'function' || typeof arguments[2] === 'function' || typeof arguments[3] === 'function') {
    throw new MongooseError('Model.findOneAndUpdate() no longer accepts a callback');
  }

  if (arguments.length === 1) {
    update = conditions;
    conditions = null;
    options = null;
  }

  let fields;
  if (options) {
    fields = options.fields || options.projection;
  }

  update = clone(update, {
    depopulate: true,
    _isNested: true
  });

  decorateUpdateWithVersionKey(update, options, this.schema.options.versionKey);

  const mq = new this.Query({}, {}, this, this.$__collection);
  mq.select(fields);

  return mq.findOneAndUpdate(conditions, update, options);
};

/**
 * Issues a mongodb findOneAndUpdate command by a document's _id field.
 * `findByIdAndUpdate(id, ...)` is equivalent to `findOneAndUpdate({ _id: id }, ...)`.
 *
 * Finds a matching document, updates it according to the `update` arg,
 * passing any `options`, and returns the found document (if any).
 *
 * This function triggers the following middleware.
 *
 * - `findOneAndUpdate()`
 *
 * #### Example:
 *
 *     A.findByIdAndUpdate(id, update, options)  // returns Query
 *     A.findByIdAndUpdate(id, update)           // returns Query
 *     A.findByIdAndUpdate()                     // returns Query
 *
 * #### Note:
 *
 * All top level update keys which are not `atomic` operation names are treated as set operations:
 *
 * #### Example:
 *
 *     Model.findByIdAndUpdate(id, { name: 'jason bourne' }, options)
 *
 *     // is sent as
 *     Model.findByIdAndUpdate(id, { $set: { name: 'jason bourne' }}, options)
 *
 * #### Note:
 *
 * `findOneAndX` and `findByIdAndX` functions support limited validation. You can
 * enable validation by setting the `runValidators` option.
 *
 * If you need full-fledged validation, use the traditional approach of first
 * retrieving the document.
 *
 *     const doc = await Model.findById(id)
 *     doc.name = 'jason bourne';
 *     await doc.save();
 *
 * @param {Object|Number|String} id value of `_id` to query by
 * @param {Object} [update]
 * @param {Object} [options] optional see [`Query.prototype.setOptions()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.setOptions())
 * @param {String} [options.returnDocument='before'] Has two possible values, `'before'` and `'after'`. By default, it will return the document before the update was applied.
 * @param {Object} [options.lean] if truthy, mongoose will return the document as a plain JavaScript object rather than a mongoose document. See [`Query.lean()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.lean()) and [the Mongoose lean tutorial](https://mongoosejs.com/docs/tutorials/lean.html).
 * @param {ClientSession} [options.session=null] The session associated with this query. See [transactions docs](https://mongoosejs.com/docs/transactions.html).
 * @param {Boolean|String} [options.strict] overwrites the schema's [strict mode option](https://mongoosejs.com/docs/guide.html#strict)
 * @param {Boolean} [options.timestamps=null] If set to `false` and [schema-level timestamps](https://mongoosejs.com/docs/guide.html#timestamps) are enabled, skip timestamps for this update. Note that this allows you to overwrite timestamps. Does nothing if schema-level timestamps are not set.
 * @param {Object|String} [options.sort] if multiple docs are found by the conditions, sets the sort order to choose which doc to update.
 * @param {Boolean} [options.runValidators] if true, runs [update validators](https://mongoosejs.com/docs/validation.html#update-validators) on this command. Update validators validate the update operation against the model's schema
 * @param {Boolean} [options.setDefaultsOnInsert=true] If `setDefaultsOnInsert` and `upsert` are true, mongoose will apply the [defaults](https://mongoosejs.com/docs/defaults.html) specified in the model's schema if a new document is created
 * @param {Boolean} [options.includeResultMetadata] if true, returns the full [ModifyResult from the MongoDB driver](https://mongodb.github.io/node-mongodb-native/4.9/interfaces/ModifyResult.html) rather than just the document
 * @param {Boolean} [options.upsert=false] if true, and no documents found, insert a new document
 * @param {Boolean} [options.new=false] if true, return the modified document rather than the original
 * @param {Object|String} [options.select] sets the document fields to return.
 * @param {Boolean} [options.translateAliases=null] If set to `true`, translates any schema-defined aliases in `filter`, `projection`, `update`, and `distinct`. Throws an error if there are any conflicts where both alias and raw property are defined on the same object.
 * @param {Boolean} [options.overwriteDiscriminatorKey=false] Mongoose removes discriminator key updates from `update` by default, set `overwriteDiscriminatorKey` to `true` to allow updating the discriminator key
 * @return {Query}
 * @see Model.findOneAndUpdate https://mongoosejs.com/docs/api/model.html#Model.findOneAndUpdate()
 * @see mongodb https://www.mongodb.com/docs/manual/reference/command/findAndModify/
 * @api public
 */

Model.findByIdAndUpdate = function(id, update, options) {
  _checkContext(this, 'findByIdAndUpdate');
  if (typeof arguments[0] === 'function' || typeof arguments[1] === 'function' || typeof arguments[2] === 'function' || typeof arguments[3] === 'function') {
    throw new MongooseError('Model.findByIdAndUpdate() no longer accepts a callback');
  }

  // if a model is passed in instead of an id
  if (id instanceof Document) {
    id = id._id;
  }

  return this.findOneAndUpdate.call(this, { _id: id }, update, options);
};

/**
 * Issue a MongoDB `findOneAndDelete()` command.
 *
 * Finds a matching document, removes it, and returns the found document (if any).
 *
 * This function triggers the following middleware.
 *
 * - `findOneAndDelete()`
 *
 * #### Example:
 *
 *     A.findOneAndDelete(conditions, options)  // return Query
 *     A.findOneAndDelete(conditions) // returns Query
 *     A.findOneAndDelete()           // returns Query
 *
 * `findOneAndX` and `findByIdAndX` functions support limited validation. You can
 * enable validation by setting the `runValidators` option.
 *
 * If you need full-fledged validation, use the traditional approach of first
 * retrieving the document.
 *
 *     const doc = await Model.findById(id)
 *     doc.name = 'jason bourne';
 *     await doc.save();
 *
 * @param {Object} conditions
 * @param {Object} [options] optional see [`Query.prototype.setOptions()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.setOptions())
 * @param {Boolean|String} [options.strict] overwrites the schema's [strict mode option](https://mongoosejs.com/docs/guide.html#strict)
 * @param {Object|String|String[]} [options.projection=null] optional fields to return, see [`Query.prototype.select()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.select())
 * @param {ClientSession} [options.session=null] The session associated with this query. See [transactions docs](https://mongoosejs.com/docs/transactions.html).
 * @param {Boolean} [options.includeResultMetadata] if true, returns the full [ModifyResult from the MongoDB driver](https://mongodb.github.io/node-mongodb-native/4.9/interfaces/ModifyResult.html) rather than just the document
 * @param {Object|String} [options.sort] if multiple docs are found by the conditions, sets the sort order to choose which doc to update.
 * @param {Object|String} [options.select] sets the document fields to return.
 * @param {Number} [options.maxTimeMS] puts a time limit on the query - requires mongodb >= 2.6.0
 * @param {Boolean} [options.translateAliases=null] If set to `true`, translates any schema-defined aliases in `filter`, `projection`, `update`, and `distinct`. Throws an error if there are any conflicts where both alias and raw property are defined on the same object.
 * @return {Query}
 * @api public
 */

Model.findOneAndDelete = function(conditions, options) {
  _checkContext(this, 'findOneAndDelete');

  if (typeof arguments[0] === 'function' || typeof arguments[1] === 'function' || typeof arguments[2] === 'function') {
    throw new MongooseError('Model.findOneAndDelete() no longer accepts a callback');
  }

  let fields;
  if (options) {
    fields = options.select;
    options.select = undefined;
  }

  const mq = new this.Query({}, {}, this, this.$__collection);
  mq.select(fields);

  return mq.findOneAndDelete(conditions, options);
};

/**
 * Issue a MongoDB `findOneAndDelete()` command by a document's _id field.
 * In other words, `findByIdAndDelete(id)` is a shorthand for
 * `findOneAndDelete({ _id: id })`.
 *
 * This function triggers the following middleware.
 *
 * - `findOneAndDelete()`
 *
 * @param {Object|Number|String} id value of `_id` to query by
 * @param {Object} [options] optional see [`Query.prototype.setOptions()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.setOptions())
 * @param {Boolean|String} [options.strict] overwrites the schema's [strict mode option](https://mongoosejs.com/docs/guide.html#strict)
 * @param {Boolean} [options.translateAliases=null] If set to `true`, translates any schema-defined aliases in `filter`, `projection`, `update`, and `distinct`. Throws an error if there are any conflicts where both alias and raw property are defined on the same object.
 * @return {Query}
 * @see Model.findOneAndDelete https://mongoosejs.com/docs/api/model.html#Model.findOneAndDelete()
 * @see mongodb https://www.mongodb.com/docs/manual/reference/command/findAndModify/
 */

Model.findByIdAndDelete = function(id, options) {
  _checkContext(this, 'findByIdAndDelete');

  if (typeof arguments[0] === 'function' || typeof arguments[1] === 'function' || typeof arguments[2] === 'function') {
    throw new MongooseError('Model.findByIdAndDelete() no longer accepts a callback');
  }

  return this.findOneAndDelete({ _id: id }, options);
};

/**
 * Issue a MongoDB `findOneAndReplace()` command.
 *
 * Finds a matching document, replaces it with the provided doc, and returns the document.
 *
 * This function triggers the following query middleware.
 *
 * - `findOneAndReplace()`
 *
 * #### Example:
 *
 *     A.findOneAndReplace(filter, replacement, options)  // return Query
 *     A.findOneAndReplace(filter, replacement) // returns Query
 *     A.findOneAndReplace()                    // returns Query
 *
 * @param {Object} filter Replace the first document that matches this filter
 * @param {Object} [replacement] Replace with this document
 * @param {Object} [options] optional see [`Query.prototype.setOptions()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.setOptions())
 * @param {String} [options.returnDocument='before'] Has two possible values, `'before'` and `'after'`. By default, it will return the document before the update was applied.
 * @param {Object} [options.lean] if truthy, mongoose will return the document as a plain JavaScript object rather than a mongoose document. See [`Query.lean()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.lean()) and [the Mongoose lean tutorial](https://mongoosejs.com/docs/tutorials/lean.html).
 * @param {ClientSession} [options.session=null] The session associated with this query. See [transactions docs](https://mongoosejs.com/docs/transactions.html).
 * @param {Boolean|String} [options.strict] overwrites the schema's [strict mode option](https://mongoosejs.com/docs/guide.html#strict)
 * @param {Boolean} [options.timestamps=null] If set to `false` and [schema-level timestamps](https://mongoosejs.com/docs/guide.html#timestamps) are enabled, skip timestamps for this update. Note that this allows you to overwrite timestamps. Does nothing if schema-level timestamps are not set.
 * @param {Object|String|String[]} [options.projection=null] optional fields to return, see [`Query.prototype.select()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.select())
 * @param {Object|String} [options.sort] if multiple docs are found by the conditions, sets the sort order to choose which doc to update.
 * @param {Boolean} [options.includeResultMetadata] if true, returns the full [ModifyResult from the MongoDB driver](https://mongodb.github.io/node-mongodb-native/4.9/interfaces/ModifyResult.html) rather than just the document
 * @param {Object|String} [options.select] sets the document fields to return.
 * @param {Number} [options.maxTimeMS] puts a time limit on the query - requires mongodb >= 2.6.0
 * @param {Boolean} [options.translateAliases=null] If set to `true`, translates any schema-defined aliases in `filter`, `projection`, `update`, and `distinct`. Throws an error if there are any conflicts where both alias and raw property are defined on the same object.
 * @return {Query}
 * @api public
 */

Model.findOneAndReplace = function(filter, replacement, options) {
  _checkContext(this, 'findOneAndReplace');

  if (typeof arguments[0] === 'function' || typeof arguments[1] === 'function' || typeof arguments[2] === 'function' || typeof arguments[3] === 'function') {
    throw new MongooseError('Model.findOneAndReplace() no longer accepts a callback');
  }

  let fields;
  if (options) {
    fields = options.select;
    options.select = undefined;
  }

  const mq = new this.Query({}, {}, this, this.$__collection);
  mq.select(fields);

  return mq.findOneAndReplace(filter, replacement, options);
};

/**
 * Shortcut for saving one or more documents to the database.
 * `MyModel.create(docs)` does `new MyModel(doc).save()` for every doc in
 * docs.
 *
 * This function triggers the following middleware.
 *
 * - `save()`
 *
 * #### Example:
 *
 *     // Insert one new `Character` document
 *     await Character.create({ name: 'Jean-Luc Picard' });
 *
 *     // Insert multiple new `Character` documents
 *     await Character.create([{ name: 'Will Riker' }, { name: 'Geordi LaForge' }]);
 *
 *     // Create a new character within a transaction. Note that you **must**
 *     // pass an array as the first parameter to `create()` if you want to
 *     // specify options.
 *     await Character.create([{ name: 'Jean-Luc Picard' }], { session });
 *
 * @param {Array|Object} docs Documents to insert, as a spread or array
 * @param {Object} [options] Options passed down to `save()`. To specify `options`, `docs` **must** be an array, not a spread. See [Model.save](https://mongoosejs.com/docs/api/model.html#Model.prototype.save()) for available options.
 * @param {Boolean} [options.ordered] saves the docs in series rather than parallel.
 * @param {Boolean} [options.aggregateErrors] Aggregate Errors instead of throwing the first one that occurs. Default: false
 * @return {Promise}
 * @api public
 */

Model.create = async function create(doc, options) {
  if (typeof options === 'function' ||
      typeof arguments[2] === 'function') {
    throw new MongooseError('Model.create() no longer accepts a callback');
  }

  _checkContext(this, 'create');

  let args;
  const discriminatorKey = this.schema.options.discriminatorKey;

  if (Array.isArray(doc)) {
    args = doc;
    options = options != null && typeof options === 'object' ? options : {};
  } else {
    const last = arguments[arguments.length - 1];
    options = {};
    const hasCallback = typeof last === 'function' ||
      typeof options === 'function' ||
      typeof arguments[2] === 'function';
    if (hasCallback) {
      throw new MongooseError('Model.create() no longer accepts a callback');
    } else {
      args = [...arguments];
      // For backwards compatibility with 6.x, because of gh-5061 Mongoose 6.x and
      // older would treat a falsy last arg as a callback. We don't want to throw
      // an error here, because it would look strange if `Test.create({}, void 0)`
      // threw a callback error. But we also don't want to create an unnecessary document.
      if (args.length > 1 && !last) {
        args.pop();
      }
    }

    if (args.length === 2 &&
        args[0] != null &&
        args[1] != null &&
        args[0].session == null &&
        last &&
        getConstructorName(last.session) === 'ClientSession' &&
        !this.schema.path('session')) {
      // Probably means the user is running into the common mistake of trying
      // to use a spread to specify options, see gh-7535
      utils.warn('WARNING: to pass a `session` to `Model.create()` in ' +
        'Mongoose, you **must** pass an array as the first argument. See: ' +
        'https://mongoosejs.com/docs/api/model.html#Model.create()');
    }
  }

  if (args.length === 0) {
    return Array.isArray(doc) ? [] : null;
  }
  let res = [];
  const immediateError = typeof options.aggregateErrors === 'boolean' ? !options.aggregateErrors : true;

  delete options.aggregateErrors; // dont pass on the option to "$save"

  if (options.ordered) {
    for (let i = 0; i < args.length; i++) {
      try {
        const doc = args[i];
        const Model = this.discriminators && doc[discriminatorKey] != null ?
          this.discriminators[doc[discriminatorKey]] || getDiscriminatorByValue(this.discriminators, doc[discriminatorKey]) :
          this;
        if (Model == null) {
          throw new MongooseError(`Discriminator "${doc[discriminatorKey]}" not ` +
          `found for model "${this.modelName}"`);
        }
        let toSave = doc;
        if (!(toSave instanceof Model)) {
          toSave = new Model(toSave);
        }

        await toSave.$save(options);
        res.push(toSave);
      } catch (err) {
        if (!immediateError) {
          res.push(err);
        } else {
          throw err;
        }
      }
    }
    return res;
  } else if (!immediateError) {
    res = await Promise.allSettled(args.map(async doc => {
      const Model = this.discriminators && doc[discriminatorKey] != null ?
        this.discriminators[doc[discriminatorKey]] || getDiscriminatorByValue(this.discriminators, doc[discriminatorKey]) :
        this;
      if (Model == null) {
        throw new MongooseError(`Discriminator "${doc[discriminatorKey]}" not ` +
            `found for model "${this.modelName}"`);
      }
      let toSave = doc;

      if (!(toSave instanceof Model)) {
        toSave = new Model(toSave);
      }

      await toSave.$save(options);

      return toSave;
    }));
    res = res.map(result => result.status === 'fulfilled' ? result.value : result.reason);
  } else {
    let firstError = null;
    res = await Promise.all(args.map(async doc => {
      const Model = this.discriminators && doc[discriminatorKey] != null ?
        this.discriminators[doc[discriminatorKey]] || getDiscriminatorByValue(this.discriminators, doc[discriminatorKey]) :
        this;
      if (Model == null) {
        throw new MongooseError(`Discriminator "${doc[discriminatorKey]}" not ` +
            `found for model "${this.modelName}"`);
      }
      try {
        let toSave = doc;

        if (!(toSave instanceof Model)) {
          toSave = new Model(toSave);
        }

        await toSave.$save(options);

        return toSave;
      } catch (err) {
        if (!firstError) {
          firstError = err;
        }
      }
    }));
    if (firstError) {
      throw firstError;
    }
  }


  if (!Array.isArray(doc) && args.length === 1) {
    return res[0];
  }

  return res;
};

/**
 * _Requires a replica set running MongoDB >= 3.6.0._ Watches the
 * underlying collection for changes using
 * [MongoDB change streams](https://www.mongodb.com/docs/manual/changeStreams/).
 *
 * This function does **not** trigger any middleware. In particular, it
 * does **not** trigger aggregate middleware.
 *
 * The ChangeStream object is an event emitter that emits the following events:
 *
 * - 'change': A change occurred, see below example
 * - 'error': An unrecoverable error occurred. In particular, change streams currently error out if they lose connection to the replica set primary. Follow [this GitHub issue](https://github.com/Automattic/mongoose/issues/6799) for updates.
 * - 'end': Emitted if the underlying stream is closed
 * - 'close': Emitted if the underlying stream is closed
 *
 * #### Example:
 *
 *     const doc = await Person.create({ name: 'Ned Stark' });
 *     const changeStream = Person.watch().on('change', change => console.log(change));
 *     // Will print from the above `console.log()`:
 *     // { _id: { _data: ... },
 *     //   operationType: 'delete',
 *     //   ns: { db: 'mydb', coll: 'Person' },
 *     //   documentKey: { _id: 5a51b125c5500f5aa094c7bd } }
 *     await doc.remove();
 *
 * @param {Array} [pipeline]
 * @param {Object} [options] see the [mongodb driver options](https://mongodb.github.io/node-mongodb-native/4.9/classes/Collection.html#watch)
 * @param {Boolean} [options.hydrate=false] if true and `fullDocument: 'updateLookup'` is set, Mongoose will automatically hydrate `fullDocument` into a fully fledged Mongoose document
 * @return {ChangeStream} mongoose-specific change stream wrapper, inherits from EventEmitter
 * @api public
 */

Model.watch = function(pipeline, options) {
  _checkContext(this, 'watch');

  const changeStreamThunk = cb => {
    pipeline = pipeline || [];
    prepareDiscriminatorPipeline(pipeline, this.schema, 'fullDocument');
    if (this.$__collection.buffer) {
      this.$__collection.addQueue(() => {
        if (this.closed) {
          return;
        }
        const driverChangeStream = this.$__collection.watch(pipeline, options);
        cb(null, driverChangeStream);
      });
    } else {
      const driverChangeStream = this.$__collection.watch(pipeline, options);
      cb(null, driverChangeStream);
    }
  };

  options = options || {};
  options.model = this;

  return new ChangeStream(changeStreamThunk, pipeline, options);
};

/**
 * _Requires MongoDB >= 3.6.0._ Starts a [MongoDB session](https://www.mongodb.com/docs/manual/release-notes/3.6/#client-sessions)
 * for benefits like causal consistency, [retryable writes](https://www.mongodb.com/docs/manual/core/retryable-writes/),
 * and [transactions](https://thecodebarbarian.com/a-node-js-perspective-on-mongodb-4-transactions.html).
 *
 * Calling `MyModel.startSession()` is equivalent to calling `MyModel.db.startSession()`.
 *
 * This function does not trigger any middleware.
 *
 * #### Example:
 *
 *     const session = await Person.startSession();
 *     let doc = await Person.findOne({ name: 'Ned Stark' }, null, { session });
 *     await doc.remove();
 *     // `doc` will always be null, even if reading from a replica set
 *     // secondary. Without causal consistency, it is possible to
 *     // get a doc back from the below query if the query reads from a
 *     // secondary that is experiencing replication lag.
 *     doc = await Person.findOne({ name: 'Ned Stark' }, null, { session, readPreference: 'secondary' });
 *
 * @param {Object} [options] see the [mongodb driver options](https://mongodb.github.io/node-mongodb-native/4.9/classes/MongoClient.html#startSession)
 * @param {Boolean} [options.causalConsistency=true] set to false to disable causal consistency
 * @return {Promise<ClientSession>} promise that resolves to a MongoDB driver `ClientSession`
 * @api public
 */

Model.startSession = function() {
  _checkContext(this, 'startSession');

  return this.db.startSession.apply(this.db, arguments);
};

/**
 * Shortcut for validating an array of documents and inserting them into
 * MongoDB if they're all valid. This function is faster than `.create()`
 * because it only sends one operation to the server, rather than one for each
 * document.
 *
 * Mongoose always validates each document **before** sending `insertMany`
 * to MongoDB. So if one document has a validation error, no documents will
 * be saved, unless you set
 * [the `ordered` option to false](https://www.mongodb.com/docs/manual/reference/method/db.collection.insertMany/#error-handling).
 *
 * This function does **not** trigger save middleware.
 *
 * This function triggers the following middleware.
 *
 * - `insertMany()`
 *
 * #### Example:
 *
 *     await Movies.insertMany([
 *       { name: 'Star Wars' },
 *       { name: 'The Empire Strikes Back' }
 *     ]);
 *
 * @param {Array|Object|*} doc(s)
 * @param {Object} [options] see the [mongodb driver options](https://mongodb.github.io/node-mongodb-native/4.9/classes/Collection.html#insertMany)
 * @param {Boolean} [options.ordered=true] if true, will fail fast on the first error encountered. If false, will insert all the documents it can and report errors later. An `insertMany()` with `ordered = false` is called an "unordered" `insertMany()`.
 * @param {Boolean} [options.rawResult=false] if false, the returned promise resolves to the documents that passed mongoose document validation. If `true`, will return the [raw result from the MongoDB driver](https://mongodb.github.io/node-mongodb-native/4.9/interfaces/InsertManyResult.html) with a `mongoose` property that contains `validationErrors` and `results` if this is an unordered `insertMany`.
 * @param {Boolean} [options.lean=false] if `true`, skips hydrating the documents. This means Mongoose will **not** cast or validate any of the documents passed to `insertMany()`. This option is useful if you need the extra performance, but comes with data integrity risk. Consider using with [`castObject()`](https://mongoosejs.com/docs/api/model.html#Model.castObject()).
 * @param {Number} [options.limit=null] this limits the number of documents being processed (validation/casting) by mongoose in parallel, this does **NOT** send the documents in batches to MongoDB. Use this option if you're processing a large number of documents and your app is running out of memory.
 * @param {String|Object|Array} [options.populate=null] populates the result documents. This option is a no-op if `rawResult` is set.
 * @param {Boolean} [options.throwOnValidationError=false] If true and `ordered: false`, throw an error if one of the operations failed validation, but all valid operations completed successfully.
 * @return {Promise} resolving to the raw result from the MongoDB driver if `options.rawResult` was `true`, or the documents that passed validation, otherwise
 * @api public
 */

Model.insertMany = async function insertMany(arr, options) {
  _checkContext(this, 'insertMany');
  if (typeof options === 'function' ||
    typeof arguments[2] === 'function') {
    throw new MongooseError('Model.insertMany() no longer accepts a callback');
  }

  return new Promise((resolve, reject) => {
    this.$__insertMany(arr, options, (err, res) => {
      if (err != null) {
        return reject(err);
      }
      resolve(res);
    });
  });
};

/**
 * ignore
 *
 * @param {Array} arr
 * @param {Object} options
 * @param {Function} callback
 * @api private
 * @memberOf Model
 * @method $__insertMany
 * @static
 */

Model.$__insertMany = function(arr, options, callback) {
  const _this = this;
  if (typeof options === 'function') {
    callback = options;
    options = null;
  }

  callback = callback || utils.noop;
  options = options || {};
  const limit = options.limit || 1000;
  const rawResult = !!options.rawResult;
  const ordered = typeof options.ordered === 'boolean' ? options.ordered : true;
  const throwOnValidationError = typeof options.throwOnValidationError === 'boolean' ? options.throwOnValidationError : false;
  const lean = !!options.lean;

  if (!Array.isArray(arr)) {
    arr = [arr];
  }

  const validationErrors = [];
  const validationErrorsToOriginalOrder = new Map();
  const results = ordered ? null : new Array(arr.length);
  const toExecute = arr.map((doc, index) =>
    callback => {
      // If option `lean` is set to true bypass validation and hydration
      if (lean) {
        // we have to execute callback at the nextTick to be compatible
        // with parallelLimit, as `results` variable has TDZ issue if we
        // execute the callback synchronously
        return immediate(() => callback(null, doc));
      }
      if (!(doc instanceof _this)) {
        if (doc != null && typeof doc !== 'object') {
          return callback(new ObjectParameterError(doc, 'arr.' + index, 'insertMany'));
        }
        try {
          doc = new _this(doc);
        } catch (err) {
          return callback(err);
        }
      }
      if (options.session != null) {
        doc.$session(options.session);
      }
      // If option `lean` is set to true bypass validation
      if (lean) {
        // we have to execute callback at the nextTick to be compatible
        // with parallelLimit, as `results` variable has TDZ issue if we
        // execute the callback synchronously
        return immediate(() => callback(null, doc));
      }
      doc.$validate().then(
        () => { callback(null, doc); },
        error => {
          if (ordered === false) {
            validationErrors.push(error);
            validationErrorsToOriginalOrder.set(error, index);
            results[index] = error;
            return callback(null, null);
          }
          callback(error);
        }
      );
    });

  parallelLimit(toExecute, limit, function(error, docs) {
    if (error) {
      callback(error, null);
      return;
    }

    const originalDocIndex = new Map();
    const validDocIndexToOriginalIndex = new Map();
    for (let i = 0; i < docs.length; ++i) {
      originalDocIndex.set(docs[i], i);
    }

    // We filter all failed pre-validations by removing nulls
    const docAttributes = docs.filter(function(doc) {
      return doc != null;
    });
    for (let i = 0; i < docAttributes.length; ++i) {
      validDocIndexToOriginalIndex.set(i, originalDocIndex.get(docAttributes[i]));
    }

    // Make sure validation errors are in the same order as the
    // original documents, so if both doc1 and doc2 both fail validation,
    // `Model.insertMany([doc1, doc2])` will always have doc1's validation
    // error before doc2's. Re: gh-12791.
    if (validationErrors.length > 0) {
      validationErrors.sort((err1, err2) => {
        return validationErrorsToOriginalOrder.get(err1) - validationErrorsToOriginalOrder.get(err2);
      });
    }

    // Quickly escape while there aren't any valid docAttributes
    if (docAttributes.length === 0) {
      if (rawResult) {
        const res = {
          acknowledged: true,
          insertedCount: 0,
          insertedIds: {},
          mongoose: {
            validationErrors: validationErrors
          }
        };
        return callback(null, res);
      }
      callback(null, []);
      return;
    }
    const docObjects = lean ? docAttributes : docAttributes.map(function(doc) {
      if (doc.$__schema.options.versionKey) {
        doc[doc.$__schema.options.versionKey] = 0;
      }
      const shouldSetTimestamps = (!options || options.timestamps !== false) && doc.initializeTimestamps && (!doc.$__ || doc.$__.timestamps !== false);
      if (shouldSetTimestamps) {
        return doc.initializeTimestamps().toObject(internalToObjectOptions);
      }
      return doc.toObject(internalToObjectOptions);
    });

    _this.$__collection.insertMany(docObjects, options).then(
      res => {
        if (!lean) {
          for (const attribute of docAttributes) {
            attribute.$__reset();
            _setIsNew(attribute, false);
          }
        }

        if (ordered === false && throwOnValidationError && validationErrors.length > 0) {
          for (let i = 0; i < results.length; ++i) {
            if (results[i] === void 0) {
              results[i] = docs[i];
            }
          }
          return callback(new MongooseBulkWriteError(
            validationErrors,
            results,
            res,
            'insertMany'
          ));
        }

        if (rawResult) {
          if (ordered === false) {
            for (let i = 0; i < results.length; ++i) {
              if (results[i] === void 0) {
                results[i] = docs[i];
              }
            }

            // Decorate with mongoose validation errors in case of unordered,
            // because then still do `insertMany()`
            res.mongoose = {
              validationErrors: validationErrors,
              results: results
            };
          }
          return callback(null, res);
        }

        if (options.populate != null) {
          return _this.populate(docAttributes, options.populate).then(
            docs => { callback(null, docs); },
            err => {
              if (err != null) {
                err.insertedDocs = docAttributes;
              }
              throw err;
            }
          );
        }

        callback(null, docAttributes);
      },
      error => {
        // `writeErrors` is a property reported by the MongoDB driver,
        // just not if there's only 1 error.
        if (error.writeErrors == null &&
            (error.result && error.result.result && error.result.result.writeErrors) != null) {
          error.writeErrors = error.result.result.writeErrors;
        }

        // `insertedDocs` is a Mongoose-specific property
        const hasWriteErrors = error && error.writeErrors;
        const erroredIndexes = new Set((error && error.writeErrors || []).map(err => err.index));

        if (error.writeErrors != null) {
          for (let i = 0; i < error.writeErrors.length; ++i) {
            const originalIndex = validDocIndexToOriginalIndex.get(error.writeErrors[i].index);
            error.writeErrors[i] = {
              ...error.writeErrors[i],
              index: originalIndex
            };
            if (!ordered) {
              results[originalIndex] = error.writeErrors[i];
            }
          }
        }

        if (!ordered) {
          for (let i = 0; i < results.length; ++i) {
            if (results[i] === void 0) {
              results[i] = docs[i];
            }
          }

          error.results = results;
        }

        let firstErroredIndex = -1;
        error.insertedDocs = docAttributes.
          filter((doc, i) => {
            const isErrored = !hasWriteErrors || erroredIndexes.has(i);

            if (ordered) {
              if (firstErroredIndex > -1) {
                return i < firstErroredIndex;
              }

              if (isErrored) {
                firstErroredIndex = i;
              }
            }

            return !isErrored;
          }).
          map(function setIsNewForInsertedDoc(doc) {
            if (lean) {
              return doc;
            }
            doc.$__reset();
            _setIsNew(doc, false);
            return doc;
          });

        if (rawResult && ordered === false) {
          error.mongoose = {
            validationErrors: validationErrors,
            results: results
          };
        }

        callback(error, null);
      }
    );
  });
};

/*!
 * ignore
 */

function _setIsNew(doc, val) {
  doc.$isNew = val;
  doc.$emit('isNew', val);
  doc.constructor.emit('isNew', val);

  const subdocs = doc.$getAllSubdocs();
  for (const subdoc of subdocs) {
    subdoc.$isNew = val;
    subdoc.$emit('isNew', val);
  }
}

/**
 * Sends multiple `insertOne`, `updateOne`, `updateMany`, `replaceOne`,
 * `deleteOne`, and/or `deleteMany` operations to the MongoDB server in one
 * command. This is faster than sending multiple independent operations (e.g.
 * if you use `create()`) because with `bulkWrite()` there is only one round
 * trip to MongoDB.
 *
 * Mongoose will perform casting on all operations you provide.
 * The only exception is [setting the `update` operator for `updateOne` or `updateMany` to a pipeline](https://www.mongodb.com/docs/manual/reference/method/db.collection.bulkWrite/#updateone-and-updatemany): Mongoose does **not** cast update pipelines.
 *
 * This function does **not** trigger any middleware, neither `save()`, nor `update()`.
 * If you need to trigger
 * `save()` middleware for every document use [`create()`](https://mongoosejs.com/docs/api/model.html#Model.create()) instead.
 *
 * #### Example:
 *
 *     Character.bulkWrite([
 *       {
 *         insertOne: {
 *           document: {
 *             name: 'Eddard Stark',
 *             title: 'Warden of the North'
 *           }
 *         }
 *       },
 *       {
 *         updateOne: {
 *           filter: { name: 'Eddard Stark' },
 *           // If you were using the MongoDB driver directly, you'd need to do
 *           // `update: { $set: { title: ... } }` but mongoose adds $set for
 *           // you.
 *           update: { title: 'Hand of the King' }
 *         }
 *       },
 *       {
 *         deleteOne: {
 *           filter: { name: 'Eddard Stark' }
 *         }
 *       }
 *     ]).then(res => {
 *      // Prints "1 1 1"
 *      console.log(res.insertedCount, res.modifiedCount, res.deletedCount);
 *     });
 *
 *     // Mongoose does **not** cast update pipelines, so no casting for the `update` option below.
 *     // Mongoose does still cast `filter`
 *     await Character.bulkWrite([{
 *       updateOne: {
 *         filter: { name: 'Annika Hansen' },
 *         update: [{ $set: { name: 7 } }] // Array means update pipeline, so Mongoose skips casting
 *       }
 *     }]);
 *
 * The [supported operations](https://www.mongodb.com/docs/manual/reference/method/db.collection.bulkWrite/#db.collection.bulkWrite) are:
 *
 * - `insertOne`
 * - `updateOne`
 * - `updateMany`
 * - `deleteOne`
 * - `deleteMany`
 * - `replaceOne`
 *
 * @param {Array} ops
 * @param {Object} [ops.insertOne.document] The document to insert
 * @param {Object} [ops.updateOne.filter] Update the first document that matches this filter
 * @param {Object} [ops.updateOne.update] An object containing [update operators](https://www.mongodb.com/docs/manual/reference/operator/update/)
 * @param {Boolean} [ops.updateOne.upsert=false] If true, insert a doc if none match
 * @param {Boolean} [ops.updateOne.timestamps=true] If false, do not apply [timestamps](https://mongoosejs.com/docs/guide.html#timestamps) to the operation
 * @param {Object} [ops.updateOne.collation] The [MongoDB collation](https://thecodebarbarian.com/a-nodejs-perspective-on-mongodb-34-collations) to use
 * @param {Array} [ops.updateOne.arrayFilters] The [array filters](https://thecodebarbarian.com/a-nodejs-perspective-on-mongodb-36-array-filters.html) used in `update`
 * @param {Object} [ops.updateMany.filter] Update all the documents that match this filter
 * @param {Object} [ops.updateMany.update] An object containing [update operators](https://www.mongodb.com/docs/manual/reference/operator/update/)
 * @param {Boolean} [ops.updateMany.upsert=false] If true, insert a doc if no documents match `filter`
 * @param {Boolean} [ops.updateMany.timestamps=true] If false, do not apply [timestamps](https://mongoosejs.com/docs/guide.html#timestamps) to the operation
 * @param {Object} [ops.updateMany.collation] The [MongoDB collation](https://thecodebarbarian.com/a-nodejs-perspective-on-mongodb-34-collations) to use
 * @param {Array} [ops.updateMany.arrayFilters] The [array filters](https://thecodebarbarian.com/a-nodejs-perspective-on-mongodb-36-array-filters.html) used in `update`
 * @param {Object} [ops.deleteOne.filter] Delete the first document that matches this filter
 * @param {Object} [ops.deleteMany.filter] Delete all documents that match this filter
 * @param {Object} [ops.replaceOne.filter] Replace the first document that matches this filter
 * @param {Object} [ops.replaceOne.replacement] The replacement document
 * @param {Boolean} [ops.replaceOne.upsert=false] If true, insert a doc if no documents match `filter`
 * @param {Object} [options]
 * @param {Boolean} [options.ordered=true] If true, execute writes in order and stop at the first error. If false, execute writes in parallel and continue until all writes have either succeeded or errored.
 * @param {ClientSession} [options.session=null] The session associated with this bulk write. See [transactions docs](https://mongoosejs.com/docs/transactions.html).
 * @param {String|number} [options.w=1] The [write concern](https://www.mongodb.com/docs/manual/reference/write-concern/). See [`Query#w()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.w()) for more information.
 * @param {number} [options.wtimeout=null] The [write concern timeout](https://www.mongodb.com/docs/manual/reference/write-concern/#wtimeout).
 * @param {Boolean} [options.j=true] If false, disable [journal acknowledgement](https://www.mongodb.com/docs/manual/reference/write-concern/#j-option)
 * @param {Boolean} [options.skipValidation=false] Set to true to skip Mongoose schema validation on bulk write operations. Mongoose currently runs validation on `insertOne` and `replaceOne` operations by default.
 * @param {Boolean} [options.bypassDocumentValidation=false] If true, disable [MongoDB server-side schema validation](https://www.mongodb.com/docs/manual/core/schema-validation/) for all writes in this bulk.
 * @param {Boolean} [options.throwOnValidationError=false] If true and `ordered: false`, throw an error if one of the operations failed validation, but all valid operations completed successfully.
 * @param {Boolean} [options.strict=null] Overwrites the [`strict` option](https://mongoosejs.com/docs/guide.html#strict) on schema. If false, allows filtering and writing fields not defined in the schema for all writes in this bulk.
 * @return {Promise} resolves to a [`BulkWriteOpResult`](https://mongodb.github.io/node-mongodb-native/4.9/classes/BulkWriteResult.html) if the operation succeeds
 * @api public
 */

Model.bulkWrite = async function bulkWrite(ops, options) {
  _checkContext(this, 'bulkWrite');

  if (typeof options === 'function' ||
      typeof arguments[2] === 'function') {
    throw new MongooseError('Model.bulkWrite() no longer accepts a callback');
  }
  options = options || {};

  const shouldSkip = await new Promise((resolve, reject) => {
    this.hooks.execPre('bulkWrite', this, [ops, options], (err) => {
      if (err != null) {
        if (err instanceof Kareem.skipWrappedFunction) {
          return resolve(err);
        }
        return reject(err);
      }
      resolve();
    });
  });

  if (shouldSkip) {
    return shouldSkip.args[0];
  }

  const ordered = options.ordered == null ? true : options.ordered;

  if (ops.length === 0) {
    return getDefaultBulkwriteResult();
  }

  const validations = ops.map(op => castBulkWrite(this, op, options));

  let res = null;
  if (ordered) {
    await new Promise((resolve, reject) => {
      each(validations, (fn, cb) => fn(cb), error => {
        if (error) {
          return reject(error);
        }

        resolve();
      });
    });

    try {
      res = await this.$__collection.bulkWrite(ops, options);
    } catch (error) {
      await new Promise((resolve, reject) => {
        const _opts = { error: error };
        this.hooks.execPost('bulkWrite', this, [null], _opts, (err) => {
          if (err != null) {
            return reject(err);
          }
          resolve();
        });
      });
    }
  } else {
    let remaining = validations.length;
    let validOps = [];
    let validationErrors = [];
    const results = [];
    await new Promise((resolve) => {
      for (let i = 0; i < validations.length; ++i) {
        validations[i]((err) => {
          if (err == null) {
            validOps.push(i);
          } else {
            validationErrors.push({ index: i, error: err });
            results[i] = err;
          }
          if (--remaining <= 0) {
            resolve();
          }
        });
      }
    });

    validationErrors = validationErrors.
      sort((v1, v2) => v1.index - v2.index).
      map(v => v.error);

    const validOpIndexes = validOps;
    validOps = validOps.sort().map(index => ops[index]);

    if (validOps.length === 0) {
      return getDefaultBulkwriteResult();
    }

    let error;
    [res, error] = await this.$__collection.bulkWrite(validOps, options).
      then(res => ([res, null])).
      catch(err => ([null, err]));

    if (error) {
      if (validationErrors.length > 0) {
        error.mongoose = error.mongoose || {};
        error.mongoose.validationErrors = validationErrors;
      }

      await new Promise((resolve, reject) => {
        const _opts = { error: error };
        this.hooks.execPost('bulkWrite', this, [null], _opts, (err) => {
          if (err != null) {
            return reject(err);
          }
          resolve();
        });
      });
    }

    for (let i = 0; i < validOpIndexes.length; ++i) {
      results[validOpIndexes[i]] = null;
    }
    if (validationErrors.length > 0) {
      if (options.throwOnValidationError) {
        throw new MongooseBulkWriteError(
          validationErrors,
          results,
          res,
          'bulkWrite'
        );
      } else {
        res.mongoose = res.mongoose || {};
        res.mongoose.validationErrors = validationErrors;
        res.mongoose.results = results;
      }
    }
  }

  await new Promise((resolve, reject) => {
    this.hooks.execPost('bulkWrite', this, [res], (err) => {
      if (err != null) {
        return reject(err);
      }
      resolve();
    });
  });

  return res;
};

/**
 *  takes an array of documents, gets the changes and inserts/updates documents in the database
 *  according to whether or not the document is new, or whether it has changes or not.
 *
 * `bulkSave` uses `bulkWrite` under the hood, so it's mostly useful when dealing with many documents (10K+)
 *
 * @param {Array<Document>} documents
 * @param {Object} [options] options passed to the underlying `bulkWrite()`
 * @param {Boolean} [options.timestamps] defaults to `null`, when set to false, mongoose will not add/update timestamps to the documents.
 * @param {ClientSession} [options.session=null] The session associated with this bulk write. See [transactions docs](https://mongoosejs.com/docs/transactions.html).
 * @param {String|number} [options.w=1] The [write concern](https://www.mongodb.com/docs/manual/reference/write-concern/). See [`Query#w()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.w()) for more information.
 * @param {number} [options.wtimeout=null] The [write concern timeout](https://www.mongodb.com/docs/manual/reference/write-concern/#wtimeout).
 * @param {Boolean} [options.j=true] If false, disable [journal acknowledgement](https://www.mongodb.com/docs/manual/reference/write-concern/#j-option)
 *
 */
Model.bulkSave = async function bulkSave(documents, options) {
  options = options || {};

  if (options.timestamps != null) {
    for (const document of documents) {
      document.$__.saveOptions = document.$__.saveOptions || {};
      document.$__.saveOptions.timestamps = options.timestamps;
    }
  } else {
    for (const document of documents) {
      if (document.$__.timestamps != null) {
        document.$__.saveOptions = document.$__.saveOptions || {};
        document.$__.saveOptions.timestamps = document.$__.timestamps;
      }
    }
  }

  await Promise.all(documents.map(buildPreSavePromise));

  const writeOperations = this.buildBulkWriteOperations(documents, { skipValidation: true, timestamps: options.timestamps });

  const { bulkWriteResult, bulkWriteError } = await this.bulkWrite(writeOperations, options).then(
    (res) => ({ bulkWriteResult: res, bulkWriteError: null }),
    (err) => ({ bulkWriteResult: null, bulkWriteError: err })
  );

  await Promise.all(
    documents.map(async(document) => {
      const documentError = bulkWriteError && bulkWriteError.writeErrors.find(writeError => {
        const writeErrorDocumentId = writeError.err.op._id || writeError.err.op.q._id;
        return writeErrorDocumentId.toString() === document._id.toString();
      });

      if (documentError == null) {
        await handleSuccessfulWrite(document);
      }
    })
  );

  if (bulkWriteError && bulkWriteError.writeErrors && bulkWriteError.writeErrors.length) {
    throw bulkWriteError;
  }

  return bulkWriteResult;
};

function buildPreSavePromise(document) {
  return new Promise((resolve, reject) => {
    document.schema.s.hooks.execPre('save', document, (err) => {
      if (err) {
        reject(err);
        return;
      }
      resolve();
    });
  });
}

function handleSuccessfulWrite(document) {
  return new Promise((resolve, reject) => {
    if (document.$isNew) {
      _setIsNew(document, false);
    }

    document.$__reset();
    document.schema.s.hooks.execPost('save', document, [document], {}, (err) => {
      if (err) {
        reject(err);
        return;
      }
      resolve();
    });

  });
}

/**
 * Apply defaults to the given document or POJO.
 *
 * @param {Object|Document} obj object or document to apply defaults on
 * @returns {Object|Document}
 * @api public
 */

Model.applyDefaults = function applyDefaults(doc) {
  if (doc.$__ != null) {
    applyDefaultsHelper(doc, doc.$__.fields, doc.$__.exclude);

    for (const subdoc of doc.$getAllSubdocs()) {
      applyDefaults(subdoc, subdoc.$__.fields, subdoc.$__.exclude);
    }

    return doc;
  }

  applyDefaultsToPOJO(doc, this.schema);

  return doc;
};

/**
 * Cast the given POJO to the model's schema
 *
 * #### Example:
 *
 *     const Test = mongoose.model('Test', Schema({ num: Number }));
 *
 *     const obj = Test.castObject({ num: '42' });
 *     obj.num; // 42 as a number
 *
 *     Test.castObject({ num: 'not a number' }); // Throws a ValidationError
 *
 * @param {Object} obj object or document to cast
 * @param {Object} options options passed to castObject
 * @param {Boolean} options.ignoreCastErrors If set to `true` will not throw a ValidationError and only return values that were successfully cast.
 * @returns {Object} POJO casted to the model's schema
 * @throws {ValidationError} if casting failed for at least one path
 * @api public
 */

Model.castObject = function castObject(obj, options) {
  options = options || {};
  const ret = {};

  const schema = this.schema;
  const paths = Object.keys(schema.paths);

  for (const path of paths) {
    const schemaType = schema.path(path);
    if (!schemaType || !schemaType.$isMongooseArray) {
      continue;
    }

    const val = get(obj, path);
    pushNestedArrayPaths(paths, val, path);
  }

  let error = null;

  for (const path of paths) {
    const schemaType = schema.path(path);
    if (schemaType == null) {
      continue;
    }

    let val = get(obj, path, void 0);

    if (val == null) {
      continue;
    }

    const pieces = path.indexOf('.') === -1 ? [path] : path.split('.');
    let cur = ret;
    for (let i = 0; i < pieces.length - 1; ++i) {
      if (cur[pieces[i]] == null) {
        cur[pieces[i]] = isNaN(pieces[i + 1]) ? {} : [];
      }
      cur = cur[pieces[i]];
    }

    if (schemaType.$isMongooseDocumentArray) {
      continue;
    }
    if (schemaType.$isSingleNested || schemaType.$isMongooseDocumentArrayElement) {
      try {
        val = Model.castObject.call(schemaType.caster, val);
      } catch (err) {
        if (!options.ignoreCastErrors) {
          error = error || new ValidationError();
          error.addError(path, err);
        }
        continue;
      }

      cur[pieces[pieces.length - 1]] = val;
      continue;
    }

    try {
      val = schemaType.cast(val);
      cur[pieces[pieces.length - 1]] = val;
    } catch (err) {
      if (!options.ignoreCastErrors) {
        error = error || new ValidationError();
        error.addError(path, err);
      }

      continue;
    }
  }

  if (error != null) {
    throw error;
  }

  return ret;
};

/**
 * Build bulk write operations for `bulkSave()`.
 *
 * @param {Array<Document>} documents The array of documents to build write operations of
 * @param {Object} options
 * @param {Boolean} options.skipValidation defaults to `false`, when set to true, building the write operations will bypass validating the documents.
 * @param {Boolean} options.timestamps defaults to `null`, when set to false, mongoose will not add/update timestamps to the documents.
 * @return {Array<Promise>} Returns a array of all Promises the function executes to be awaited.
 * @api private
 */

Model.buildBulkWriteOperations = function buildBulkWriteOperations(documents, options) {
  if (!Array.isArray(documents)) {
    throw new Error(`bulkSave expects an array of documents to be passed, received \`${documents}\` instead`);
  }

  setDefaultOptions();
  const discriminatorKey = this.schema.options.discriminatorKey;

  const writeOperations = documents.reduce((accumulator, document, i) => {
    if (!options.skipValidation) {
      if (!(document instanceof Document)) {
        throw new Error(`documents.${i} was not a mongoose document, documents must be an array of mongoose documents (instanceof mongoose.Document).`);
      }
      const validationError = document.validateSync();
      if (validationError) {
        throw validationError;
      }
    }

    const isANewDocument = document.isNew;
    if (isANewDocument) {
      const writeOperation = { insertOne: { document } };
      utils.injectTimestampsOption(writeOperation.insertOne, options.timestamps);
      accumulator.push(writeOperation);

      return accumulator;
    }

    const delta = document.$__delta();
    const isDocumentWithChanges = delta != null && !utils.isEmptyObject(delta[0]);

    if (isDocumentWithChanges) {
      const where = document.$__where(delta[0]);
      const changes = delta[1];

      _applyCustomWhere(document, where);

      // Set the discriminator key, so bulk write casting knows which
      // schema to use re: gh-13907
      if (document[discriminatorKey] != null && !(discriminatorKey in where)) {
        where[discriminatorKey] = document[discriminatorKey];
      }

      document.$__version(where, delta);
      const writeOperation = { updateOne: { filter: where, update: changes } };
      utils.injectTimestampsOption(writeOperation.updateOne, options.timestamps);
      accumulator.push(writeOperation);

      return accumulator;
    }

    return accumulator;
  }, []);

  return writeOperations;


  function setDefaultOptions() {
    options = options || {};
    if (options.skipValidation == null) {
      options.skipValidation = false;
    }
  }
};


/**
 * Shortcut for creating a new Document from existing raw data, pre-saved in the DB.
 * The document returned has no paths marked as modified initially.
 *
 * #### Example:
 *
 *     // hydrate previous data into a Mongoose document
 *     const mongooseCandy = Candy.hydrate({ _id: '54108337212ffb6d459f854c', type: 'jelly bean' });
 *
 * @param {Object} obj
 * @param {Object|String|String[]} [projection] optional projection containing which fields should be selected for this document
 * @param {Object} [options] optional options
 * @param {Boolean} [options.setters=false] if true, apply schema setters when hydrating
 * @param {Boolean} [options.hydratedPopulatedDocs=false] if true, populates the docs if passing pre-populated data
 * @return {Document} document instance
 * @api public
 */

Model.hydrate = function(obj, projection, options) {
  _checkContext(this, 'hydrate');

  if (projection != null) {
    if (obj != null && obj.$__ != null) {
      obj = obj.toObject(internalToObjectOptions);
    }
    obj = applyProjection(obj, projection);
  }
  const document = require('./queryHelpers').createModel(this, obj, projection);
  document.$init(obj, options);
  return document;
};

/**
 * Same as `updateOne()`, except MongoDB will update _all_ documents that match
 * `filter` (as opposed to just the first one) regardless of the value of
 * the `multi` option.
 *
 * **Note** updateMany will _not_ fire update middleware. Use `pre('updateMany')`
 * and `post('updateMany')` instead.
 *
 * #### Example:
 *
 *     const res = await Person.updateMany({ name: /Stark$/ }, { isDeleted: true });
 *     res.matchedCount; // Number of documents matched
 *     res.modifiedCount; // Number of documents modified
 *     res.acknowledged; // Boolean indicating everything went smoothly.
 *     res.upsertedId; // null or an id containing a document that had to be upserted.
 *     res.upsertedCount; // Number indicating how many documents had to be upserted. Will either be 0 or 1.
 *
 * This function triggers the following middleware.
 *
 * - `updateMany()`
 *
 * @param {Object} filter
 * @param {Object|Array} update. If array, this update will be treated as an update pipeline and not casted.
 * @param {Object} [options] optional see [`Query.prototype.setOptions()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.setOptions())
 * @param {Boolean|String} [options.strict] overwrites the schema's [strict mode option](https://mongoosejs.com/docs/guide.html#strict)
 * @param {Boolean} [options.upsert=false] if true, and no documents found, insert a new document
 * @param {Object} [options.writeConcern=null] sets the [write concern](https://www.mongodb.com/docs/manual/reference/write-concern/) for replica sets. Overrides the [schema-level write concern](https://mongoosejs.com/docs/guide.html#writeConcern)
 * @param {Boolean} [options.timestamps=null] If set to `false` and [schema-level timestamps](https://mongoosejs.com/docs/guide.html#timestamps) are enabled, skip timestamps for this update. Does nothing if schema-level timestamps are not set.
 * @param {Boolean} [options.translateAliases=null] If set to `true`, translates any schema-defined aliases in `filter`, `projection`, `update`, and `distinct`. Throws an error if there are any conflicts where both alias and raw property are defined on the same object.
 * @param {Boolean} [options.overwriteDiscriminatorKey=false] Mongoose removes discriminator key updates from `update` by default, set `overwriteDiscriminatorKey` to `true` to allow updating the discriminator key
 * @return {Query}
 * @see Query docs https://mongoosejs.com/docs/queries.html
 * @see MongoDB docs https://www.mongodb.com/docs/manual/reference/command/update/#update-command-output
 * @see UpdateResult https://mongodb.github.io/node-mongodb-native/4.9/interfaces/UpdateResult.html
 * @api public
 */

Model.updateMany = function updateMany(conditions, doc, options) {
  _checkContext(this, 'updateMany');

  return _update(this, 'updateMany', conditions, doc, options);
};

/**
 * Update _only_ the first document that matches `filter`.
 *
 * - Use `replaceOne()` if you want to overwrite an entire document rather than using atomic operators like `$set`.
 *
 * #### Example:
 *
 *     const res = await Person.updateOne({ name: 'Jean-Luc Picard' }, { ship: 'USS Enterprise' });
 *     res.matchedCount; // Number of documents matched
 *     res.modifiedCount; // Number of documents modified
 *     res.acknowledged; // Boolean indicating everything went smoothly.
 *     res.upsertedId; // null or an id containing a document that had to be upserted.
 *     res.upsertedCount; // Number indicating how many documents had to be upserted. Will either be 0 or 1.
 *
 * This function triggers the following middleware.
 *
 * - `updateOne()`
 *
 * @param {Object} filter
 * @param {Object|Array} update. If array, this update will be treated as an update pipeline and not casted.
 * @param {Object} [options] optional see [`Query.prototype.setOptions()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.setOptions())
 * @param {Boolean|String} [options.strict] overwrites the schema's [strict mode option](https://mongoosejs.com/docs/guide.html#strict)
 * @param {Boolean} [options.upsert=false] if true, and no documents found, insert a new document
 * @param {Object} [options.writeConcern=null] sets the [write concern](https://www.mongodb.com/docs/manual/reference/write-concern/) for replica sets. Overrides the [schema-level write concern](https://mongoosejs.com/docs/guide.html#writeConcern)
 * @param {Boolean} [options.timestamps=null] If set to `false` and [schema-level timestamps](https://mongoosejs.com/docs/guide.html#timestamps) are enabled, skip timestamps for this update. Note that this allows you to overwrite timestamps. Does nothing if schema-level timestamps are not set.
 * @param {Boolean} [options.translateAliases=null] If set to `true`, translates any schema-defined aliases in `filter`, `projection`, `update`, and `distinct`. Throws an error if there are any conflicts where both alias and raw property are defined on the same object.
 * @param {Boolean} [options.overwriteDiscriminatorKey=false] Mongoose removes discriminator key updates from `update` by default, set `overwriteDiscriminatorKey` to `true` to allow updating the discriminator key
 * @return {Query}
 * @see Query docs https://mongoosejs.com/docs/queries.html
 * @see MongoDB docs https://www.mongodb.com/docs/manual/reference/command/update/#update-command-output
 * @see UpdateResult https://mongodb.github.io/node-mongodb-native/4.9/interfaces/UpdateResult.html
 * @api public
 */

Model.updateOne = function updateOne(conditions, doc, options) {
  _checkContext(this, 'updateOne');

  return _update(this, 'updateOne', conditions, doc, options);
};

/**
 * Replace the existing document with the given document (no atomic operators like `$set`).
 *
 * #### Example:
 *
 *     const res = await Person.replaceOne({ _id: 24601 }, { name: 'Jean Valjean' });
 *     res.matchedCount; // Number of documents matched
 *     res.modifiedCount; // Number of documents modified
 *     res.acknowledged; // Boolean indicating everything went smoothly.
 *     res.upsertedId; // null or an id containing a document that had to be upserted.
 *     res.upsertedCount; // Number indicating how many documents had to be upserted. Will either be 0 or 1.
 *
 * This function triggers the following middleware.
 *
 * - `replaceOne()`
 *
 * @param {Object} filter
 * @param {Object} doc
 * @param {Object} [options] optional see [`Query.prototype.setOptions()`](https://mongoosejs.com/docs/api/query.html#Query.prototype.setOptions())
 * @param {Boolean|String} [options.strict] overwrites the schema's [strict mode option](https://mongoosejs.com/docs/guide.html#strict)
 * @param {Boolean} [options.upsert=false] if true, and no documents found, insert a new document
 * @param {Object} [options.writeConcern=null] sets the [write concern](https://www.mongodb.com/docs/manual/reference/write-concern/) for replica sets. Overrides the [schema-level write concern](https://mongoosejs.com/docs/guide.html#writeConcern)
 * @param {Boolean} [options.timestamps=null] If set to `false` and [schema-level timestamps](https://mongoosejs.com/docs/guide.html#timestamps) are enabled, skip timestamps for this update. Does nothing if schema-level timestamps are not set.
 * @param {Boolean} [options.translateAliases=null] If set to `true`, translates any schema-defined aliases in `filter`, `projection`, `update`, and `distinct`. Throws an error if there are any conflicts where both alias and raw property are defined on the same object.
 * @return {Query}
 * @see Query docs https://mongoosejs.com/docs/queries.html
 * @see UpdateResult https://mongodb.github.io/node-mongodb-native/4.9/interfaces/UpdateResult.html
 * @return {Query}
 * @api public
 */

Model.replaceOne = function replaceOne(conditions, doc, options) {
  _checkContext(this, 'replaceOne');

  const versionKey = this && this.schema && this.schema.options && this.schema.options.versionKey || null;
  if (versionKey && !doc[versionKey]) {
    doc[versionKey] = 0;
  }

  return _update(this, 'replaceOne', conditions, doc, options);
};

/**
 * Common code for `updateOne()`, `updateMany()`, `replaceOne()`, and `update()`
 * because they need to do the same thing
 * @api private
 */

function _update(model, op, conditions, doc, options) {
  const mq = new model.Query({}, {}, model, model.collection);

  // gh-2406
  // make local deep copy of conditions
  if (conditions instanceof Document) {
    conditions = conditions.toObject();
  } else {
    conditions = clone(conditions);
  }
  options = typeof options === 'function' ? options : clone(options);

  const versionKey = model &&
  model.schema &&
  model.schema.options &&
  model.schema.options.versionKey || null;
  decorateUpdateWithVersionKey(doc, options, versionKey);

  return mq[op](conditions, doc, options);
}

/**
 * Performs [aggregations](https://www.mongodb.com/docs/manual/aggregation/) on the models collection.
 *
 * If a `callback` is passed, the `aggregate` is executed and a `Promise` is returned. If a callback is not passed, the `aggregate` itself is returned.
 *
 * This function triggers the following middleware.
 *
 * - `aggregate()`
 *
 * #### Example:
 *
 *     // Find the max balance of all accounts
 *     const res = await Users.aggregate([
 *       { $group: { _id: null, maxBalance: { $max: '$balance' }}},
 *       { $project: { _id: 0, maxBalance: 1 }}
 *     ]);
 *
 *     console.log(res); // [ { maxBalance: 98000 } ]
 *
 *     // Or use the aggregation pipeline builder.
 *     const res = await Users.aggregate().
 *       group({ _id: null, maxBalance: { $max: '$balance' } }).
 *       project('-id maxBalance').
 *       exec();
 *     console.log(res); // [ { maxBalance: 98 } ]
 *
 * #### Note:
 *
 * - Mongoose does **not** cast aggregation pipelines to the model's schema because `$project` and `$group` operators allow redefining the "shape" of the documents at any stage of the pipeline, which may leave documents in an incompatible format. You can use the [mongoose-cast-aggregation plugin](https://github.com/AbdelrahmanHafez/mongoose-cast-aggregation) to enable minimal casting for aggregation pipelines.
 * - The documents returned are plain javascript objects, not mongoose documents (since any shape of document can be returned).
 *
 * #### More About Aggregations:
 *
 * - [Mongoose `Aggregate`](https://mongoosejs.com/docs/api/aggregate.html)
 * - [An Introduction to Mongoose Aggregate](https://masteringjs.io/tutorials/mongoose/aggregate)
 * - [MongoDB Aggregation docs](https://www.mongodb.com/docs/manual/applications/aggregation/)
 *
 * @see Aggregate https://mongoosejs.com/docs/api/aggregate.html#Aggregate()
 * @see MongoDB https://www.mongodb.com/docs/manual/applications/aggregation/
 * @param {Array} [pipeline] aggregation pipeline as an array of objects
 * @param {Object} [options] aggregation options
 * @return {Aggregate}
 * @api public
 */

Model.aggregate = function aggregate(pipeline, options) {
  _checkContext(this, 'aggregate');

  if (typeof options === 'function' || typeof arguments[2] === 'function') {
    throw new MongooseError('Model.aggregate() no longer accepts a callback');
  }

  const aggregate = new Aggregate(pipeline || []);
  aggregate.model(this);
  if (options != null) {
    aggregate.option(options);
  }

  if (typeof callback === 'undefined') {
    return aggregate;
  }

  return aggregate;
};

/**
 * Casts and validates the given object against this model's schema, passing the
 * given `context` to custom validators.
 *
 * #### Example:
 *
 *     const Model = mongoose.model('Test', Schema({
 *       name: { type: String, required: true },
 *       age: { type: Number, required: true }
 *     });
 *
 *     try {
 *       await Model.validate({ name: null }, ['name'])
 *     } catch (err) {
 *       err instanceof mongoose.Error.ValidationError; // true
 *       Object.keys(err.errors); // ['name']
 *     }
 *
 * @param {Object} obj
 * @param {Object|Array|String} pathsOrOptions
 * @param {Object} [context]
 * @return {Promise<Object>} casted and validated copy of `obj` if validation succeeded
 * @api public
 */

Model.validate = async function validate(obj, pathsOrOptions, context) {
  if ((arguments.length < 3) || (arguments.length === 3 && typeof arguments[2] === 'function')) {
    // For convenience, if we're validating a document or an object, make `context` default to
    // the model so users don't have to always pass `context`, re: gh-10132, gh-10346
    context = obj;
  }
  if (typeof context === 'function' || typeof arguments[3] === 'function') {
    throw new MongooseError('Model.validate() no longer accepts a callback');
  }

  let schema = this.schema;
  const discriminatorKey = schema.options.discriminatorKey;
  if (schema.discriminators != null && obj != null && obj[discriminatorKey] != null) {
    schema = getSchemaDiscriminatorByValue(schema, obj[discriminatorKey]) || schema;
  }
  let paths = Object.keys(schema.paths);

  if (pathsOrOptions != null) {
    const _pathsToValidate = typeof pathsOrOptions === 'string' ? new Set(pathsOrOptions.split(' ')) : Array.isArray(pathsOrOptions) ? new Set(pathsOrOptions) : new Set(paths);
    paths = paths.filter(p => {
      if (pathsOrOptions.pathsToSkip) {
        if (Array.isArray(pathsOrOptions.pathsToSkip)) {
          if (pathsOrOptions.pathsToSkip.find(x => x == p)) {
            return false;
          }
        } else if (typeof pathsOrOptions.pathsToSkip == 'string') {
          if (pathsOrOptions.pathsToSkip.includes(p)) {
            return false;
          }
        }
      }
      const pieces = p.split('.');
      let cur = pieces[0];

      for (const piece of pieces) {
        if (_pathsToValidate.has(cur)) {
          return true;
        }
        cur += '.' + piece;
      }

      return _pathsToValidate.has(p);
    });
  }

  for (const path of paths) {
    const schemaType = schema.path(path);
    if (!schemaType || !schemaType.$isMongooseArray || schemaType.$isMongooseDocumentArray) {
      continue;
    }

    const val = get(obj, path);
    pushNestedArrayPaths(paths, val, path);
  }

  let error = null;
  paths = new Set(paths);

  try {
    obj = this.castObject(obj);
  } catch (err) {
    error = err;
    for (const key of Object.keys(error.errors || {})) {
      paths.delete(key);
    }
  }

  let remaining = paths.size;

  return new Promise((resolve, reject) => {
    for (const path of paths) {
      const schemaType = schema.path(path);
      if (schemaType == null) {
        _checkDone();
        continue;
      }

      const pieces = path.indexOf('.') === -1 ? [path] : path.split('.');
      let cur = obj;
      for (let i = 0; i < pieces.length - 1; ++i) {
        cur = cur[pieces[i]];
      }

      const val = get(obj, path, void 0);

      schemaType.doValidate(val, err => {
        if (err) {
          error = error || new ValidationError();
          error.addError(path, err);
        }
        _checkDone();
      }, context, { path: path });
    }

    function _checkDone() {
      if (--remaining <= 0) {
        if (error) {
          reject(error);
        } else {
          resolve(obj);
        }
      }
    }
  });
};

/**
 * Populates document references.
 *
 * Changed in Mongoose 6: the model you call `populate()` on should be the
 * "local field" model, **not** the "foreign field" model.
 *
 * #### Available top-level options:
 *
 * - path: space delimited path(s) to populate
 * - select: optional fields to select
 * - match: optional query conditions to match
 * - model: optional name of the model to use for population
 * - options: optional query options like sort, limit, etc
 * - justOne: optional boolean, if true Mongoose will always set `path` to a document, or `null` if no document was found. If false, Mongoose will always set `path` to an array, which will be empty if no documents are found. Inferred from schema by default.
 * - strictPopulate: optional boolean, set to `false` to allow populating paths that aren't in the schema.
 *
 * #### Example:
 *
 *     const Dog = mongoose.model('Dog', new Schema({ name: String, breed: String }));
 *     const Person = mongoose.model('Person', new Schema({
 *       name: String,
 *       pet: { type: mongoose.ObjectId, ref: 'Dog' }
 *     }));
 *
 *     const pets = await Pet.create([
 *       { name: 'Daisy', breed: 'Beagle' },
 *       { name: 'Einstein', breed: 'Catalan Sheepdog' }
 *     ]);
 *
 *     // populate many plain objects
 *     const users = [
 *       { name: 'John Wick', dog: pets[0]._id },
 *       { name: 'Doc Brown', dog: pets[1]._id }
 *     ];
 *     await User.populate(users, { path: 'dog', select: 'name' });
 *     users[0].dog.name; // 'Daisy'
 *     users[0].dog.breed; // undefined because of `select`
 *
 * @param {Document|Array} docs Either a single document or array of documents to populate.
 * @param {Object|String} options Either the paths to populate or an object specifying all parameters
 * @param {string} [options.path=null] The path to populate.
 * @param {string|PopulateOptions} [options.populate=null] Recursively populate paths in the populated documents. See [deep populate docs](https://mongoosejs.com/docs/populate.html#deep-populate).
 * @param {boolean} [options.retainNullValues=false] By default, Mongoose removes null and undefined values from populated arrays. Use this option to make `populate()` retain `null` and `undefined` array entries.
 * @param {boolean} [options.getters=false] If true, Mongoose will call any getters defined on the `localField`. By default, Mongoose gets the raw value of `localField`. For example, you would need to set this option to `true` if you wanted to [add a `lowercase` getter to your `localField`](https://mongoosejs.com/docs/schematypes.html#schematype-options).
 * @param {boolean} [options.clone=false] When you do `BlogPost.find().populate('author')`, blog posts with the same author will share 1 copy of an `author` doc. Enable this option to make Mongoose clone populated docs before assigning them.
 * @param {Object|Function} [options.match=null] Add an additional filter to the populate query. Can be a filter object containing [MongoDB query syntax](https://www.mongodb.com/docs/manual/tutorial/query-documents/), or a function that returns a filter object.
 * @param {Boolean} [options.skipInvalidIds=false] By default, Mongoose throws a cast error if `localField` and `foreignField` schemas don't line up. If you enable this option, Mongoose will instead filter out any `localField` properties that cannot be casted to `foreignField`'s schema type.
 * @param {Number} [options.perDocumentLimit=null] For legacy reasons, `limit` with `populate()` may give incorrect results because it only executes a single query for every document being populated. If you set `perDocumentLimit`, Mongoose will ensure correct `limit` per document by executing a separate query for each document to `populate()`. For example, `.find().populate({ path: 'test', perDocumentLimit: 2 })` will execute 2 additional queries if `.find()` returns 2 documents.
 * @param {Boolean} [options.strictPopulate=true] Set to false to allow populating paths that aren't defined in the given model's schema.
 * @param {Object} [options.options=null] Additional options like `limit` and `lean`.
 * @param {Function} [options.transform=null] Function that Mongoose will call on every populated document that allows you to transform the populated document.
 * @param {Function} [callback(err,doc)] Optional callback, executed upon completion. Receives `err` and the `doc(s)`.
 * @return {Promise}
 * @api public
 */

Model.populate = async function populate(docs, paths) {
  _checkContext(this, 'populate');
  if (typeof paths === 'function' || typeof arguments[2] === 'function') {
    throw new MongooseError('Model.populate() no longer accepts a callback');
  }
  const _this = this;
  // normalized paths
  paths = utils.populate(paths);
  // data that should persist across subPopulate calls
  const cache = {};

  return new Promise((resolve, reject) => {
    _populate(_this, docs, paths, cache, (err, res) => {
      if (err) {
        return reject(err);
      }
      resolve(res);
    });
  });
};

/**
 * Populate helper
 *
 * @param {Model} model the model to use
 * @param {Document|Array} docs Either a single document or array of documents to populate.
 * @param {Object} paths
 * @param {never} cache Unused
 * @param {Function} [callback] Optional callback, executed upon completion. Receives `err` and the `doc(s)`.
 * @return {Function}
 * @api private
 */

function _populate(model, docs, paths, cache, callback) {
  let pending = paths.length;
  if (paths.length === 0) {
    return callback(null, docs);
  }
  // each path has its own query options and must be executed separately
  for (const path of paths) {
    populate(model, docs, path, next);
  }

  function next(err) {
    if (err) {
      return callback(err, null);
    }
    if (--pending) {
      return;
    }
    callback(null, docs);
  }
}

/*!
 * Populates `docs`
 */
const excludeIdReg = /\s?-_id\s?/;
const excludeIdRegGlobal = /\s?-_id\s?/g;

function populate(model, docs, options, callback) {
  const populateOptions = options;
  if (options.strictPopulate == null) {
    if (options._localModel != null && options._localModel.schema._userProvidedOptions.strictPopulate != null) {
      populateOptions.strictPopulate = options._localModel.schema._userProvidedOptions.strictPopulate;
    } else if (options._localModel != null && model.base.options.strictPopulate != null) {
      populateOptions.strictPopulate = model.base.options.strictPopulate;
    } else if (model.base.options.strictPopulate != null) {
      populateOptions.strictPopulate = model.base.options.strictPopulate;
    }
  }

  // normalize single / multiple docs passed
  if (!Array.isArray(docs)) {
    docs = [docs];
  }
  if (docs.length === 0 || docs.every(utils.isNullOrUndefined)) {
    return callback();
  }

  const modelsMap = getModelsMapForPopulate(model, docs, populateOptions);

  if (modelsMap instanceof MongooseError) {
    return immediate(function() {
      callback(modelsMap);
    });
  }
  const len = modelsMap.length;
  let vals = [];

  function flatten(item) {
    // no need to include undefined values in our query
    return undefined !== item;
  }

  let _remaining = len;
  let hasOne = false;
  const params = [];
  for (let i = 0; i < len; ++i) {
    const mod = modelsMap[i];
    let select = mod.options.select;
    let ids = utils.array.flatten(mod.ids, flatten);
    ids = utils.array.unique(ids);

    const assignmentOpts = {};
    assignmentOpts.sort = mod &&
      mod.options &&
      mod.options.options &&
      mod.options.options.sort || void 0;
    assignmentOpts.excludeId = excludeIdReg.test(select) || (select && select._id === 0);

    // Lean transform may delete `_id`, which would cause assignment
    // to fail. So delay running lean transform until _after_
    // `_assign()`
    if (mod.options &&
        mod.options.options &&
        mod.options.options.lean &&
        mod.options.options.lean.transform) {
      mod.options.options._leanTransform = mod.options.options.lean.transform;
      mod.options.options.lean = true;
    }

    if (ids.length === 0 || ids.every(utils.isNullOrUndefined)) {
      // Ensure that we set to 0 or empty array even
      // if we don't actually execute a query to make sure there's a value
      // and we know this path was populated for future sets. See gh-7731, gh-8230
      --_remaining;
      _assign(model, [], mod, assignmentOpts);
      continue;
    }

    hasOne = true;
    if (typeof populateOptions.foreignField === 'string') {
      mod.foreignField.clear();
      mod.foreignField.add(populateOptions.foreignField);
    }
    const match = createPopulateQueryFilter(ids, mod.match, mod.foreignField, mod.model, mod.options.skipInvalidIds);
    if (assignmentOpts.excludeId) {
      // override the exclusion from the query so we can use the _id
      // for document matching during assignment. we'll delete the
      // _id back off before returning the result.
      if (typeof select === 'string') {
        select = select.replace(excludeIdRegGlobal, ' ');
      } else if (Array.isArray(select)) {
        select = select.filter(field => field !== '-_id');
      } else {
        // preserve original select conditions by copying
        select = { ...select };
        delete select._id;
      }
    }

    if (mod.options.options && mod.options.options.limit != null) {
      assignmentOpts.originalLimit = mod.options.options.limit;
    } else if (mod.options.limit != null) {
      assignmentOpts.originalLimit = mod.options.limit;
    }
    params.push([mod, match, select, assignmentOpts, _next]);
  }
  if (!hasOne) {
    // If models but no docs, skip further deep populate.
    if (modelsMap.length !== 0) {
      return callback();
    }
    // If no models to populate but we have a nested populate,
    // keep trying, re: gh-8946
    if (populateOptions.populate != null) {
      const opts = utils.populate(populateOptions.populate).map(pop => Object.assign({}, pop, {
        path: populateOptions.path + '.' + pop.path
      }));
      model.populate(docs, opts).then(res => { callback(null, res); }, err => { callback(err); });
      return;
    }
    return callback();
  }

  for (const arr of params) {
    _execPopulateQuery.apply(null, arr);
  }
  function _next(err, valsFromDb) {
    if (err != null) {
      return callback(err, null);
    }
    vals = vals.concat(valsFromDb);
    if (--_remaining === 0) {
      _done();
    }
  }

  function _done() {
    for (const arr of params) {
      const mod = arr[0];
      const assignmentOpts = arr[3];
      for (const val of vals) {
        mod.options._childDocs.push(val);
      }
      try {
        _assign(model, vals, mod, assignmentOpts);
      } catch (err) {
        return callback(err);
      }
    }

    for (const arr of params) {
      removeDeselectedForeignField(arr[0].foreignField, arr[0].options, vals);
    }
    for (const arr of params) {
      const mod = arr[0];
      if (mod.options && mod.options.options && mod.options.options._leanTransform) {
        for (const doc of vals) {
          mod.options.options._leanTransform(doc);
        }
      }
    }
    callback();
  }
}

/*!
 * ignore
 */

function _execPopulateQuery(mod, match, select, assignmentOpts, callback) {
  let subPopulate = clone(mod.options.populate);
  const queryOptions = Object.assign({
    skip: mod.options.skip,
    limit: mod.options.limit,
    perDocumentLimit: mod.options.perDocumentLimit
  }, mod.options.options);

  if (mod.count) {
    delete queryOptions.skip;
  }

  if (queryOptions.perDocumentLimit != null) {
    queryOptions.limit = queryOptions.perDocumentLimit;
    delete queryOptions.perDocumentLimit;
  } else if (queryOptions.limit != null) {
    queryOptions.limit = queryOptions.limit * mod.ids.length;
  }

  const query = mod.model.find(match, select, queryOptions);
  // If we're doing virtual populate and projection is inclusive and foreign
  // field is not selected, automatically select it because mongoose needs it.
  // If projection is exclusive and client explicitly unselected the foreign
  // field, that's the client's fault.
  for (const foreignField of mod.foreignField) {
    if (foreignField !== '_id' &&
        query.selectedInclusively() &&
        !isPathSelectedInclusive(query._fields, foreignField)) {
      query.select(foreignField);
    }
  }

  // If using count, still need the `foreignField` so we can match counts
  // to documents, otherwise we would need a separate `count()` for every doc.
  if (mod.count) {
    for (const foreignField of mod.foreignField) {
      query.select(foreignField);
    }
  }

  // If we need to sub-populate, call populate recursively
  if (subPopulate) {
    // If subpopulating on a discriminator, skip check for non-existent
    // paths. Because the discriminator may not have the path defined.
    if (mod.model.baseModelName != null) {
      if (Array.isArray(subPopulate)) {
        subPopulate.forEach(pop => { pop.strictPopulate = false; });
      } else if (typeof subPopulate === 'string') {
        subPopulate = { path: subPopulate, strictPopulate: false };
      } else {
        subPopulate.strictPopulate = false;
      }
    }
    const basePath = mod.options._fullPath || mod.options.path;

    if (Array.isArray(subPopulate)) {
      for (const pop of subPopulate) {
        pop._fullPath = basePath + '.' + pop.path;
      }
    } else if (typeof subPopulate === 'object') {
      subPopulate._fullPath = basePath + '.' + subPopulate.path;
    }

    query.populate(subPopulate);
  }

  query.exec().then(
    docs => {
      for (const val of docs) {
        leanPopulateMap.set(val, mod.model);
      }
      callback(null, docs);
    },
    err => {
      callback(err);
    }
  );
}

/*!
 * ignore
 */

function _assign(model, vals, mod, assignmentOpts) {
  const options = mod.options;
  const isVirtual = mod.isVirtual;
  const justOne = mod.justOne;
  let _val;
  const lean = options &&
    options.options &&
    options.options.lean || false;
  const len = vals.length;
  const rawOrder = {};
  const rawDocs = {};
  let key;
  let val;

  // Clone because `assignRawDocsToIdStructure` will mutate the array
  const allIds = clone(mod.allIds);
  // optimization:
  // record the document positions as returned by
  // the query result.
  for (let i = 0; i < len; i++) {
    val = vals[i];
    if (val == null) {
      continue;
    }
    for (const foreignField of mod.foreignField) {
      _val = utils.getValue(foreignField, val);
      if (Array.isArray(_val)) {
        _val = utils.array.unique(utils.array.flatten(_val));

        for (let __val of _val) {
          if (__val instanceof Document) {
            __val = __val._id;
          }
          key = String(__val);
          if (rawDocs[key]) {
            if (Array.isArray(rawDocs[key])) {
              rawDocs[key].push(val);
              rawOrder[key].push(i);
            } else {
              rawDocs[key] = [rawDocs[key], val];
              rawOrder[key] = [rawOrder[key], i];
            }
          } else {
            if (isVirtual && !justOne) {
              rawDocs[key] = [val];
              rawOrder[key] = [i];
            } else {
              rawDocs[key] = val;
              rawOrder[key] = i;
            }
          }
        }
      } else {
        if (_val instanceof Document) {
          _val = _val._id;
        }
        key = String(_val);
        if (rawDocs[key]) {
          if (Array.isArray(rawDocs[key])) {
            rawDocs[key].push(val);
            rawOrder[key].push(i);
          } else if (isVirtual ||
            rawDocs[key].constructor !== val.constructor ||
            String(rawDocs[key]._id) !== String(val._id)) {
            // May need to store multiple docs with the same id if there's multiple models
            // if we have discriminators or a ref function. But avoid converting to an array
            // if we have multiple queries on the same model because of `perDocumentLimit` re: gh-9906
            rawDocs[key] = [rawDocs[key], val];
            rawOrder[key] = [rawOrder[key], i];
          }
        } else {
          rawDocs[key] = val;
          rawOrder[key] = i;
        }
      }
      // flag each as result of population
      if (!lean) {
        val.$__.wasPopulated = val.$__.wasPopulated || { value: _val };
      }
    }
  }

  assignVals({
    originalModel: model,
    // If virtual, make sure to not mutate original field
    rawIds: mod.isVirtual ? allIds : mod.allIds,
    allIds: allIds,
    unpopulatedValues: mod.unpopulatedValues,
    foreignField: mod.foreignField,
    rawDocs: rawDocs,
    rawOrder: rawOrder,
    docs: mod.docs,
    path: options.path,
    options: assignmentOpts,
    justOne: mod.justOne,
    isVirtual: mod.isVirtual,
    allOptions: mod,
    populatedModel: mod.model,
    lean: lean,
    virtual: mod.virtual,
    count: mod.count,
    match: mod.match
  });
}

/**
 * Compiler utility.
 *
 * @param {String|Function} name model name or class extending Model
 * @param {Schema} schema
 * @param {String} collectionName
 * @param {Connection} connection
 * @param {Mongoose} base mongoose instance
 * @api private
 */

Model.compile = function compile(name, schema, collectionName, connection, base) {
  const versioningEnabled = schema.options.versionKey !== false;

  if (versioningEnabled && !schema.paths[schema.options.versionKey]) {
    // add versioning to top level documents only
    const o = {};
    o[schema.options.versionKey] = Number;
    schema.add(o);
  }
  let model;
  if (typeof name === 'function' && name.prototype instanceof Model) {
    model = name;
    name = model.name;
    schema.loadClass(model, false);
    model.prototype.$isMongooseModelPrototype = true;
  } else {
    // generate new class
    model = function model(doc, fields, skipId) {
      model.hooks.execPreSync('createModel', doc);
      if (!(this instanceof model)) {
        return new model(doc, fields, skipId);
      }
      const discriminatorKey = model.schema.options.discriminatorKey;

      if (model.discriminators == null || doc == null || doc[discriminatorKey] == null) {
        Model.call(this, doc, fields, skipId);
        return;
      }

      // If discriminator key is set, use the discriminator instead (gh-7586)
      const Discriminator = model.discriminators[doc[discriminatorKey]] ||
        getDiscriminatorByValue(model.discriminators, doc[discriminatorKey]);
      if (Discriminator != null) {
        return new Discriminator(doc, fields, skipId);
      }

      // Otherwise, just use the top-level model
      Model.call(this, doc, fields, skipId);
    };
  }

  model.hooks = schema.s.hooks.clone();
  model.base = base;
  model.modelName = name;

  if (!(model.prototype instanceof Model)) {
    Object.setPrototypeOf(model, Model);
    Object.setPrototypeOf(model.prototype, Model.prototype);
  }
  model.model = function model(name) {
    return this.db.model(name);
  };

  model.db = connection;
  model.prototype.db = connection;
  model.prototype[modelDbSymbol] = connection;
  model.discriminators = model.prototype.discriminators = undefined;
  model[modelSymbol] = true;
  model.events = new EventEmitter();

  schema._preCompile();

  const _userProvidedOptions = schema._userProvidedOptions || {};

  const collectionOptions = {
    schemaUserProvidedOptions: _userProvidedOptions,
    capped: schema.options.capped,
    Promise: model.base.Promise,
    modelName: name
  };
  if (schema.options.autoCreate !== void 0) {
    collectionOptions.autoCreate = schema.options.autoCreate;
  }

  const collection = connection.collection(
    collectionName,
    collectionOptions
  );

  model.prototype.collection = collection;
  model.prototype.$collection = collection;
  model.prototype[modelCollectionSymbol] = collection;

  model.prototype.$__setSchema(schema);

  // apply methods and statics
  applyMethods(model, schema);
  applyStatics(model, schema);
  applyHooks(model, schema);
  applyStaticHooks(model, schema.s.hooks, schema.statics);

  model.schema = model.prototype.$__schema;
  model.collection = collection;
  model.$__collection = collection;

  // Create custom query constructor
  model.Query = function() {
    Query.apply(this, arguments);
  };
  Object.setPrototypeOf(model.Query.prototype, Query.prototype);
  model.Query.base = Query.base;
  model.Query.prototype.constructor = Query;
  model._applyQueryMiddleware();
  applyQueryMethods(model, schema.query);

  return model;
};

/**
 * Update this model to use the new connection, including updating all internal
 * references and creating a new `Collection` instance using the new connection.
 * Not for external use, only used by `setDriver()` to ensure that you can still
 * call `setDriver()` after creating a model using `mongoose.model()`.
 *
 * @param {Connection} newConnection the new connection to use
 * @api private
 */

Model.$__updateConnection = function $__updateConnection(newConnection) {
  this.db = newConnection;
  this.prototype.db = newConnection;
  this.prototype[modelDbSymbol] = newConnection;

  const collection = newConnection.collection(
    this.collection.collectionName,
    this.collection.opts
  );

  this.prototype.collection = collection;
  this.prototype.$collection = collection;
  this.prototype[modelCollectionSymbol] = collection;

  this.collection = collection;
  this.$__collection = collection;
};

/**
 * Register custom query methods for this model
 *
 * @param {Model} model
 * @param {Schema} schema
 * @api private
 */

function applyQueryMethods(model, methods) {
  for (const i in methods) {
    model.Query.prototype[i] = methods[i];
  }
}

/**
 * Subclass this model with `conn`, `schema`, and `collection` settings.
 *
 * @param {Connection} conn
 * @param {Schema} [schema]
 * @param {String} [collection]
 * @return {Model}
 * @api private
 * @memberOf Model
 * @static
 * @method __subclass
 */

Model.__subclass = function subclass(conn, schema, collection) {
  // subclass model using this connection and collection name
  const _this = this;

  const Model = function Model(doc, fields, skipId) {
    if (!(this instanceof Model)) {
      return new Model(doc, fields, skipId);
    }
    _this.call(this, doc, fields, skipId);
  };

  Object.setPrototypeOf(Model, _this);
  Object.setPrototypeOf(Model.prototype, _this.prototype);
  Model.db = conn;
  Model.prototype.db = conn;
  Model.prototype[modelDbSymbol] = conn;

  _this[subclassedSymbol] = _this[subclassedSymbol] || [];
  _this[subclassedSymbol].push(Model);
  if (_this.discriminators != null) {
    Model.discriminators = {};
    for (const key of Object.keys(_this.discriminators)) {
      Model.discriminators[key] = _this.discriminators[key].
        __subclass(_this.db, _this.discriminators[key].schema, collection);
    }
  }

  const s = schema && typeof schema !== 'string'
    ? schema
    : _this.prototype.$__schema;

  const options = s.options || {};
  const _userProvidedOptions = s._userProvidedOptions || {};

  if (!collection) {
    collection = _this.prototype.$__schema.get('collection') ||
      utils.toCollectionName(_this.modelName, this.base.pluralize());
  }

  const collectionOptions = {
    schemaUserProvidedOptions: _userProvidedOptions,
    capped: s && options.capped
  };

  Model.prototype.collection = conn.collection(collection, collectionOptions);
  Model.prototype.$collection = Model.prototype.collection;
  Model.prototype[modelCollectionSymbol] = Model.prototype.collection;
  Model.collection = Model.prototype.collection;
  Model.$__collection = Model.collection;
  // Errors handled internally, so ignore
  Model.init().catch(() => {});
  return Model;
};

/**
 * Apply changes made to this model's schema after this model was compiled.
 * By default, adding virtuals and other properties to a schema after the model is compiled does nothing.
 * Call this function to apply virtuals and properties that were added later.
 *
 * #### Example:
 *
 *     const schema = new mongoose.Schema({ field: String });
 *     const TestModel = mongoose.model('Test', schema);
 *     TestModel.schema.virtual('myVirtual').get(function() {
 *       return this.field + ' from myVirtual';
 *     });
 *     const doc = new TestModel({ field: 'Hello' });
 *     doc.myVirtual; // undefined
 *
 *     TestModel.recompileSchema();
 *     doc.myVirtual; // 'Hello from myVirtual'
 *
 * @return {undefined}
 * @api public
 * @memberOf Model
 * @static
 * @method recompileSchema
 */

Model.recompileSchema = function recompileSchema() {
  this.prototype.$__setSchema(this.schema);

  if (this.schema._applyDiscriminators != null) {
    for (const disc of this.schema._applyDiscriminators.keys()) {
      this.discriminator(disc, this.schema._applyDiscriminators.get(disc));
    }
  }

  applyEmbeddedDiscriminators(this.schema, new WeakSet(), true);
};

/**
 * Helper for console.log. Given a model named 'MyModel', returns the string
 * `'Model { MyModel }'`.
 *
 * #### Example:
 *
 *     const MyModel = mongoose.model('Test', Schema({ name: String }));
 *     MyModel.inspect(); // 'Model { Test }'
 *     console.log(MyModel); // Prints 'Model { Test }'
 *
 * @api public
 */

Model.inspect = function() {
  return `Model { ${this.modelName} }`;
};

if (util.inspect.custom) {
  // Avoid Node deprecation warning DEP0079
  Model[util.inspect.custom] = Model.inspect;
}

/*!
 * Applies query middleware from this model's schema to this model's
 * Query constructor.
 */

Model._applyQueryMiddleware = function _applyQueryMiddleware() {
  const Query = this.Query;
  const queryMiddleware = this.schema.s.hooks.filter(hook => {
    const contexts = _getContexts(hook);
    if (hook.name === 'validate') {
      return !!contexts.query;
    }
    if (hook.name === 'deleteOne' || hook.name === 'updateOne') {
      return !!contexts.query || Object.keys(contexts).length === 0;
    }
    if (hook.query != null || hook.document != null) {
      return !!hook.query;
    }
    return true;
  });

  Query.prototype._queryMiddleware = queryMiddleware;
};

function _getContexts(hook) {
  const ret = {};
  if (hook.hasOwnProperty('query')) {
    ret.query = hook.query;
  }
  if (hook.hasOwnProperty('document')) {
    ret.document = hook.document;
  }
  return ret;
}

/*!
 * Module exports.
 */

module.exports = exports = Model;
