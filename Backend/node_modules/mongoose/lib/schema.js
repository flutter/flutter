'use strict';

/*!
 * Module dependencies.
 */

const EventEmitter = require('events').EventEmitter;
const Kareem = require('kareem');
const MongooseError = require('./error/mongooseError');
const SchemaType = require('./schemaType');
const SchemaTypeOptions = require('./options/schemaTypeOptions');
const VirtualOptions = require('./options/virtualOptions');
const VirtualType = require('./virtualType');
const addAutoId = require('./helpers/schema/addAutoId');
const clone = require('./helpers/clone');
const get = require('./helpers/get');
const getConstructorName = require('./helpers/getConstructorName');
const getIndexes = require('./helpers/schema/getIndexes');
const handleReadPreferenceAliases = require('./helpers/query/handleReadPreferenceAliases');
const idGetter = require('./helpers/schema/idGetter');
const merge = require('./helpers/schema/merge');
const mpath = require('mpath');
const setPopulatedVirtualValue = require('./helpers/populate/setPopulatedVirtualValue');
const setupTimestamps = require('./helpers/timestamps/setupTimestamps');
const utils = require('./utils');
const validateRef = require('./helpers/populate/validateRef');
const util = require('util');

const hasNumericSubpathRegex = /\.\d+(\.|$)/;

let MongooseTypes;

const queryHooks = require('./constants').queryMiddlewareFunctions;
const documentHooks = require('./helpers/model/applyHooks').middlewareFunctions;
const hookNames = queryHooks.concat(documentHooks).
  reduce((s, hook) => s.add(hook), new Set());

const isPOJO = utils.isPOJO;

let id = 0;

const numberRE = /^\d+$/;

/**
 * Schema constructor.
 *
 * #### Example:
 *
 *     const child = new Schema({ name: String });
 *     const schema = new Schema({ name: String, age: Number, children: [child] });
 *     const Tree = mongoose.model('Tree', schema);
 *
 *     // setting schema options
 *     new Schema({ name: String }, { id: false, autoIndex: false })
 *
 * #### Options:
 *
 * - [autoIndex](https://mongoosejs.com/docs/guide.html#autoIndex): bool - defaults to null (which means use the connection's autoIndex option)
 * - [autoCreate](https://mongoosejs.com/docs/guide.html#autoCreate): bool - defaults to null (which means use the connection's autoCreate option)
 * - [bufferCommands](https://mongoosejs.com/docs/guide.html#bufferCommands): bool - defaults to true
 * - [bufferTimeoutMS](https://mongoosejs.com/docs/guide.html#bufferTimeoutMS): number - defaults to 10000 (10 seconds). If `bufferCommands` is enabled, the amount of time Mongoose will wait for connectivity to be restablished before erroring out.
 * - [capped](https://mongoosejs.com/docs/guide.html#capped): bool | number | object - defaults to false
 * - [collection](https://mongoosejs.com/docs/guide.html#collection): string - no default
 * - [discriminatorKey](https://mongoosejs.com/docs/guide.html#discriminatorKey): string - defaults to `__t`
 * - [id](https://mongoosejs.com/docs/guide.html#id): bool - defaults to true
 * - [_id](https://mongoosejs.com/docs/guide.html#_id): bool - defaults to true
 * - [minimize](https://mongoosejs.com/docs/guide.html#minimize): bool - controls [document#toObject](https://mongoosejs.com/docs/api/document.html#Document.prototype.toObject()) behavior when called manually - defaults to true
 * - [read](https://mongoosejs.com/docs/guide.html#read): string
 * - [writeConcern](https://mongoosejs.com/docs/guide.html#writeConcern): object - defaults to null, use to override [the MongoDB server's default write concern settings](https://www.mongodb.com/docs/manual/reference/write-concern/)
 * - [shardKey](https://mongoosejs.com/docs/guide.html#shardKey): object - defaults to `null`
 * - [strict](https://mongoosejs.com/docs/guide.html#strict): bool - defaults to true
 * - [strictQuery](https://mongoosejs.com/docs/guide.html#strictQuery): bool - defaults to false
 * - [toJSON](https://mongoosejs.com/docs/guide.html#toJSON) - object - no default
 * - [toObject](https://mongoosejs.com/docs/guide.html#toObject) - object - no default
 * - [typeKey](https://mongoosejs.com/docs/guide.html#typeKey) - string - defaults to 'type'
 * - [validateBeforeSave](https://mongoosejs.com/docs/guide.html#validateBeforeSave) - bool - defaults to `true`
 * - [validateModifiedOnly](https://mongoosejs.com/docs/api/document.html#Document.prototype.validate()) - bool - defaults to `false`
 * - [versionKey](https://mongoosejs.com/docs/guide.html#versionKey): string or object - defaults to "__v"
 * - [optimisticConcurrency](https://mongoosejs.com/docs/guide.html#optimisticConcurrency): bool - defaults to false. Set to true to enable [optimistic concurrency](https://thecodebarbarian.com/whats-new-in-mongoose-5-10-optimistic-concurrency.html).
 * - [collation](https://mongoosejs.com/docs/guide.html#collation): object - defaults to null (which means use no collation)
 * - [timeseries](https://mongoosejs.com/docs/guide.html#timeseries): object - defaults to null (which means this schema's collection won't be a timeseries collection)
 * - [selectPopulatedPaths](https://mongoosejs.com/docs/guide.html#selectPopulatedPaths): boolean - defaults to `true`
 * - [skipVersioning](https://mongoosejs.com/docs/guide.html#skipVersioning): object - paths to exclude from versioning
 * - [timestamps](https://mongoosejs.com/docs/guide.html#timestamps): object or boolean - defaults to `false`. If true, Mongoose adds `createdAt` and `updatedAt` properties to your schema and manages those properties for you.
 * - [pluginTags](https://mongoosejs.com/docs/guide.html#pluginTags): array of strings - defaults to `undefined`. If set and plugin called with `tags` option, will only apply that plugin to schemas with a matching tag.
 * - [virtuals](https://mongoosejs.com/docs/tutorials/virtuals.html#virtuals-via-schema-options): object - virtuals to define, alias for [`.virtual`](https://mongoosejs.com/docs/api/schema.html#Schema.prototype.virtual())
 * - [collectionOptions]: object with options passed to [`createCollection()`](https://www.mongodb.com/docs/manual/reference/method/db.createCollection/) when calling `Model.createCollection()` or `autoCreate` set to true.
 *
 * #### Options for Nested Schemas:
 *
 * - `excludeIndexes`: bool - defaults to `false`. If `true`, skip building indexes on this schema's paths.
 *
 * #### Note:
 *
 * _When nesting schemas, (`children` in the example above), always declare the child schema first before passing it into its parent._
 *
 * @param {Object|Schema|Array} [definition] Can be one of: object describing schema paths, or schema to copy, or array of objects and schemas
 * @param {Object} [options]
 * @inherits NodeJS EventEmitter https://nodejs.org/api/events.html#class-eventemitter
 * @event `init`: Emitted after the schema is compiled into a `Model`.
 * @api public
 */

function Schema(obj, options) {
  if (!(this instanceof Schema)) {
    return new Schema(obj, options);
  }

  this.obj = obj;
  this.paths = {};
  this.aliases = {};
  this.subpaths = {};
  this.virtuals = {};
  this.singleNestedPaths = {};
  this.nested = {};
  this.inherits = {};
  this.callQueue = [];
  this._indexes = [];
  this._searchIndexes = [];
  this.methods = (options && options.methods) || {};
  this.methodOptions = {};
  this.statics = (options && options.statics) || {};
  this.tree = {};
  this.query = (options && options.query) || {};
  this.childSchemas = [];
  this.plugins = [];
  // For internal debugging. Do not use this to try to save a schema in MDB.
  this.$id = ++id;
  this.mapPaths = [];

  this.s = {
    hooks: new Kareem()
  };
  this.options = this.defaultOptions(options);

  // build paths
  if (Array.isArray(obj)) {
    for (const definition of obj) {
      this.add(definition);
    }
  } else if (obj) {
    this.add(obj);
  }

  // build virtual paths
  if (options && options.virtuals) {
    const virtuals = options.virtuals;
    const pathNames = Object.keys(virtuals);
    for (const pathName of pathNames) {
      const pathOptions = virtuals[pathName].options ? virtuals[pathName].options : undefined;
      const virtual = this.virtual(pathName, pathOptions);

      if (virtuals[pathName].get) {
        virtual.get(virtuals[pathName].get);
      }

      if (virtuals[pathName].set) {
        virtual.set(virtuals[pathName].set);
      }
    }
  }

  // check if _id's value is a subdocument (gh-2276)
  const _idSubDoc = obj && obj._id && utils.isObject(obj._id);

  // ensure the documents get an auto _id unless disabled
  const auto_id = !this.paths['_id'] &&
      (this.options._id) && !_idSubDoc;

  if (auto_id) {
    addAutoId(this);
  }

  this.setupTimestamp(this.options.timestamps);
}

/**
 * Create virtual properties with alias field
 * @api private
 */
function aliasFields(schema, paths) {
  for (const path of Object.keys(paths)) {
    let alias = null;
    if (paths[path] != null) {
      alias = paths[path];
    } else {
      const options = get(schema.paths[path], 'options');
      if (options == null) {
        continue;
      }

      alias = options.alias;
    }

    if (!alias) {
      continue;
    }

    const prop = schema.paths[path].path;
    if (Array.isArray(alias)) {
      for (const a of alias) {
        if (typeof a !== 'string') {
          throw new Error('Invalid value for alias option on ' + prop + ', got ' + a);
        }

        schema.aliases[a] = prop;

        schema.
          virtual(a).
          get((function(p) {
            return function() {
              if (typeof this.get === 'function') {
                return this.get(p);
              }
              return this[p];
            };
          })(prop)).
          set((function(p) {
            return function(v) {
              return this.$set(p, v);
            };
          })(prop));
      }

      continue;
    }

    if (typeof alias !== 'string') {
      throw new Error('Invalid value for alias option on ' + prop + ', got ' + alias);
    }

    schema.aliases[alias] = prop;

    schema.
      virtual(alias).
      get((function(p) {
        return function() {
          if (typeof this.get === 'function') {
            return this.get(p);
          }
          return this[p];
        };
      })(prop)).
      set((function(p) {
        return function(v) {
          return this.$set(p, v);
        };
      })(prop));
  }
}

/*!
 * Inherit from EventEmitter.
 */
Schema.prototype = Object.create(EventEmitter.prototype);
Schema.prototype.constructor = Schema;
Schema.prototype.instanceOfSchema = true;

/*!
 * ignore
 */

Object.defineProperty(Schema.prototype, '$schemaType', {
  configurable: false,
  enumerable: false,
  writable: true
});

/**
 * Array of child schemas (from document arrays and single nested subdocs)
 * and their corresponding compiled models. Each element of the array is
 * an object with 2 properties: `schema` and `model`.
 *
 * This property is typically only useful for plugin authors and advanced users.
 * You do not need to interact with this property at all to use mongoose.
 *
 * @api public
 * @property childSchemas
 * @memberOf Schema
 * @instance
 */

Object.defineProperty(Schema.prototype, 'childSchemas', {
  configurable: false,
  enumerable: true,
  writable: true
});

/**
 * Object containing all virtuals defined on this schema.
 * The objects' keys are the virtual paths and values are instances of `VirtualType`.
 *
 * This property is typically only useful for plugin authors and advanced users.
 * You do not need to interact with this property at all to use mongoose.
 *
 * #### Example:
 *
 *     const schema = new Schema({});
 *     schema.virtual('answer').get(() => 42);
 *
 *     console.log(schema.virtuals); // { answer: VirtualType { path: 'answer', ... } }
 *     console.log(schema.virtuals['answer'].getters[0].call()); // 42
 *
 * @api public
 * @property virtuals
 * @memberOf Schema
 * @instance
 */

Object.defineProperty(Schema.prototype, 'virtuals', {
  configurable: false,
  enumerable: true,
  writable: true
});

/**
 * The original object passed to the schema constructor
 *
 * #### Example:
 *
 *     const schema = new Schema({ a: String }).add({ b: String });
 *     schema.obj; // { a: String }
 *
 * @api public
 * @property obj
 * @memberOf Schema
 * @instance
 */

Schema.prototype.obj;

/**
 * The paths defined on this schema. The keys are the top-level paths
 * in this schema, and the values are instances of the SchemaType class.
 *
 * #### Example:
 *
 *     const schema = new Schema({ name: String }, { _id: false });
 *     schema.paths; // { name: SchemaString { ... } }
 *
 *     schema.add({ age: Number });
 *     schema.paths; // { name: SchemaString { ... }, age: SchemaNumber { ... } }
 *
 * @api public
 * @property paths
 * @memberOf Schema
 * @instance
 */

Schema.prototype.paths;

/**
 * Schema as a tree
 *
 * #### Example:
 *
 *     {
 *         '_id'     : ObjectId
 *       , 'nested'  : {
 *             'key' : String
 *         }
 *     }
 *
 * @api private
 * @property tree
 * @memberOf Schema
 * @instance
 */

Schema.prototype.tree;

/**
 * Returns a deep copy of the schema
 *
 * #### Example:
 *
 *     const schema = new Schema({ name: String });
 *     const clone = schema.clone();
 *     clone === schema; // false
 *     clone.path('name'); // SchemaString { ... }
 *
 * @return {Schema} the cloned schema
 * @api public
 * @memberOf Schema
 * @instance
 */

Schema.prototype.clone = function() {
  const s = this._clone();

  // Bubble up `init` for backwards compat
  s.on('init', v => this.emit('init', v));

  return s;
};

/*!
 * ignore
 */

Schema.prototype._clone = function _clone(Constructor) {
  Constructor = Constructor || (this.base == null ? Schema : this.base.Schema);

  const s = new Constructor({}, this._userProvidedOptions);
  s.base = this.base;
  s.obj = this.obj;
  s.options = clone(this.options);
  s.callQueue = this.callQueue.map(function(f) { return f; });
  s.methods = clone(this.methods);
  s.methodOptions = clone(this.methodOptions);
  s.statics = clone(this.statics);
  s.query = clone(this.query);
  s.plugins = Array.prototype.slice.call(this.plugins);
  s._indexes = clone(this._indexes);
  s._searchIndexes = clone(this._searchIndexes);
  s.s.hooks = this.s.hooks.clone();

  s.tree = clone(this.tree);
  s.paths = Object.fromEntries(
    Object.entries(this.paths).map(([key, value]) => ([key, value.clone()]))
  );
  s.nested = clone(this.nested);
  s.subpaths = clone(this.subpaths);
  for (const schemaType of Object.values(s.paths)) {
    if (schemaType.$isSingleNested) {
      const path = schemaType.path;
      for (const key of Object.keys(schemaType.schema.paths)) {
        s.singleNestedPaths[path + '.' + key] = schemaType.schema.paths[key];
      }
      for (const key of Object.keys(schemaType.schema.singleNestedPaths)) {
        s.singleNestedPaths[path + '.' + key] =
          schemaType.schema.singleNestedPaths[key];
      }
      for (const key of Object.keys(schemaType.schema.subpaths)) {
        s.singleNestedPaths[path + '.' + key] =
          schemaType.schema.subpaths[key];
      }
      for (const key of Object.keys(schemaType.schema.nested)) {
        s.singleNestedPaths[path + '.' + key] = 'nested';
      }
    }
  }
  s.childSchemas = gatherChildSchemas(s);

  s.virtuals = clone(this.virtuals);
  s.$globalPluginsApplied = this.$globalPluginsApplied;
  s.$isRootDiscriminator = this.$isRootDiscriminator;
  s.$implicitlyCreated = this.$implicitlyCreated;
  s.$id = ++id;
  s.$originalSchemaId = this.$id;
  s.mapPaths = [].concat(this.mapPaths);

  if (this.discriminatorMapping != null) {
    s.discriminatorMapping = Object.assign({}, this.discriminatorMapping);
  }
  if (this.discriminators != null) {
    s.discriminators = Object.assign({}, this.discriminators);
  }
  if (this._applyDiscriminators != null) {
    s._applyDiscriminators = new Map(this._applyDiscriminators);
  }

  s.aliases = Object.assign({}, this.aliases);

  return s;
};

/**
 * Returns a new schema that has the picked `paths` from this schema.
 *
 * This method is analagous to [Lodash's `pick()` function](https://lodash.com/docs/4.17.15#pick) for Mongoose schemas.
 *
 * #### Example:
 *
 *     const schema = Schema({ name: String, age: Number });
 *     // Creates a new schema with the same `name` path as `schema`,
 *     // but no `age` path.
 *     const newSchema = schema.pick(['name']);
 *
 *     newSchema.path('name'); // SchemaString { ... }
 *     newSchema.path('age'); // undefined
 *
 * @param {String[]} paths List of Paths to pick for the new Schema
 * @param {Object} [options] Options to pass to the new Schema Constructor (same as `new Schema(.., Options)`). Defaults to `this.options` if not set.
 * @return {Schema}
 * @api public
 */

Schema.prototype.pick = function(paths, options) {
  const newSchema = new Schema({}, options || this.options);
  if (!Array.isArray(paths)) {
    throw new MongooseError('Schema#pick() only accepts an array argument, ' +
      'got "' + typeof paths + '"');
  }

  for (const path of paths) {
    if (this.nested[path]) {
      newSchema.add({ [path]: get(this.tree, path) });
    } else {
      const schematype = this.path(path);
      if (schematype == null) {
        throw new MongooseError('Path `' + path + '` is not in the schema');
      }
      newSchema.add({ [path]: schematype });
    }
  }

  return newSchema;
};

/**
 * Returns a new schema that has the `paths` from the original schema, minus the omitted ones.
 *
 * This method is analagous to [Lodash's `omit()` function](https://lodash.com/docs/#omit) for Mongoose schemas.
 *
 * #### Example:
 *
 *     const schema = Schema({ name: String, age: Number });
 *     // Creates a new schema omitting the `age` path
 *     const newSchema = schema.omit(['age']);
 *
 *     newSchema.path('name'); // SchemaString { ... }
 *     newSchema.path('age'); // undefined
 *
 * @param {String[]} paths List of Paths to omit for the new Schema
 * @param {Object} [options] Options to pass to the new Schema Constructor (same as `new Schema(.., Options)`). Defaults to `this.options` if not set.
 * @return {Schema}
 * @api public
 */

Schema.prototype.omit = function(paths, options) {
  const newSchema = new Schema(this, options || this.options);
  if (!Array.isArray(paths)) {
    throw new MongooseError(
      'Schema#omit() only accepts an array argument, ' +
        'got "' +
        typeof paths +
        '"'
    );
  }

  newSchema.remove(paths);

  for (const nested in newSchema.singleNestedPaths) {
    if (paths.includes(nested)) {
      delete newSchema.singleNestedPaths[nested];
    }
  }

  return newSchema;
};

/**
 * Returns default options for this schema, merged with `options`.
 *
 * @param {Object} [options] Options to overwrite the default options
 * @return {Object} The merged options of `options` and the default options
 * @api private
 */

Schema.prototype.defaultOptions = function(options) {
  this._userProvidedOptions = options == null ? {} : clone(options);
  const baseOptions = this.base && this.base.options || {};
  const strict = 'strict' in baseOptions ? baseOptions.strict : true;
  const strictQuery = 'strictQuery' in baseOptions ? baseOptions.strictQuery : false;
  const id = 'id' in baseOptions ? baseOptions.id : true;
  options = {
    strict,
    strictQuery,
    bufferCommands: true,
    capped: false, // { size, max, autoIndexId }
    versionKey: '__v',
    optimisticConcurrency: false,
    minimize: true,
    autoIndex: null,
    discriminatorKey: '__t',
    shardKey: null,
    read: null,
    validateBeforeSave: true,
    validateModifiedOnly: false,
    // the following are only applied at construction time
    _id: true,
    id: id,
    typeKey: 'type',
    ...options
  };

  if (options.versionKey && typeof options.versionKey !== 'string') {
    throw new MongooseError('`versionKey` must be falsy or string, got `' + (typeof options.versionKey) + '`');
  }

  if (typeof options.read === 'string') {
    options.read = handleReadPreferenceAliases(options.read);
  } else if (Array.isArray(options.read) && typeof options.read[0] === 'string') {
    options.read = {
      mode: handleReadPreferenceAliases(options.read[0]),
      tags: options.read[1]
    };
  }

  if (options.optimisticConcurrency && !options.versionKey) {
    throw new MongooseError('Must set `versionKey` if using `optimisticConcurrency`');
  }

  return options;
};

/**
 * Inherit a Schema by applying a discriminator on an existing Schema.
 *
 *
 * #### Example:
 *
 *     const eventSchema = new mongoose.Schema({ timestamp: Date }, { discriminatorKey: 'kind' });
 *
 *     const clickedEventSchema = new mongoose.Schema({ element: String }, { discriminatorKey: 'kind' });
 *     const ClickedModel = eventSchema.discriminator('clicked', clickedEventSchema);
 *
 *     const Event = mongoose.model('Event', eventSchema);
 *
 *     Event.discriminators['clicked']; // Model { clicked }
 *
 *     const doc = await Event.create({ kind: 'clicked', element: '#hero' });
 *     doc.element; // '#hero'
 *     doc instanceof ClickedModel; // true
 *
 * @param {String} name the name of the discriminator
 * @param {Schema} schema the discriminated Schema
 * @param {Object} [options] discriminator options
 * @param {String} [options.value] the string stored in the `discriminatorKey` property. If not specified, Mongoose uses the `name` parameter.
 * @param {Boolean} [options.clone=true] By default, `discriminator()` clones the given `schema`. Set to `false` to skip cloning.
 * @param {Boolean} [options.overwriteModels=false] by default, Mongoose does not allow you to define a discriminator with the same name as another discriminator. Set this to allow overwriting discriminators with the same name.
 * @param {Boolean} [options.mergeHooks=true] By default, Mongoose merges the base schema's hooks with the discriminator schema's hooks. Set this option to `false` to make Mongoose use the discriminator schema's hooks instead.
 * @param {Boolean} [options.mergePlugins=true] By default, Mongoose merges the base schema's plugins with the discriminator schema's plugins. Set this option to `false` to make Mongoose use the discriminator schema's plugins instead.
 * @return {Schema} the Schema instance
 * @api public
 */
Schema.prototype.discriminator = function(name, schema, options) {
  this._applyDiscriminators = this._applyDiscriminators || new Map();
  this._applyDiscriminators.set(name, { schema, options });

  return this;
};

/**
 * Adds key path / schema type pairs to this schema.
 *
 * #### Example:
 *
 *     const ToySchema = new Schema();
 *     ToySchema.add({ name: 'string', color: 'string', price: 'number' });
 *
 *     const TurboManSchema = new Schema();
 *     // You can also `add()` another schema and copy over all paths, virtuals,
 *     // getters, setters, indexes, methods, and statics.
 *     TurboManSchema.add(ToySchema).add({ year: Number });
 *
 * @param {Object|Schema} obj plain object with paths to add, or another schema
 * @param {String} [prefix] path to prefix the newly added paths with
 * @return {Schema} the Schema instance
 * @api public
 */

Schema.prototype.add = function add(obj, prefix) {
  if (obj instanceof Schema || (obj != null && obj.instanceOfSchema)) {
    merge(this, obj);

    return this;
  }

  // Special case: setting top-level `_id` to false should convert to disabling
  // the `_id` option. This behavior never worked before 5.4.11 but numerous
  // codebases use it (see gh-7516, gh-7512).
  if (obj._id === false && prefix == null) {
    this.options._id = false;
  }

  prefix = prefix || '';
  // avoid prototype pollution
  if (prefix === '__proto__.' || prefix === 'constructor.' || prefix === 'prototype.') {
    return this;
  }

  const keys = Object.keys(obj);
  const typeKey = this.options.typeKey;
  for (const key of keys) {
    if (utils.specialProperties.has(key)) {
      continue;
    }

    const fullPath = prefix + key;
    const val = obj[key];

    if (val == null) {
      throw new TypeError('Invalid value for schema path `' + fullPath +
        '`, got value "' + val + '"');
    }
    // Retain `_id: false` but don't set it as a path, re: gh-8274.
    if (key === '_id' && val === false) {
      continue;
    }
    // Deprecate setting schema paths to primitive types (gh-7558)
    let isMongooseTypeString = false;
    if (typeof val === 'string') {
      // Handle the case in which the type is specified as a string (eg. 'date', 'oid', ...)
      const MongooseTypes = this.base != null ? this.base.Schema.Types : Schema.Types;
      const upperVal = val.charAt(0).toUpperCase() + val.substring(1);
      isMongooseTypeString = MongooseTypes[upperVal] != null;
    }
    if (
      key !== '_id' &&
      ((typeof val !== 'object' && typeof val !== 'function' && !isMongooseTypeString) ||
      val == null)
    ) {
      throw new TypeError(`Invalid schema configuration: \`${val}\` is not ` +
        `a valid type at path \`${key}\`. See ` +
        'https://bit.ly/mongoose-schematypes for a list of valid schema types.');
    }
    if (val instanceof VirtualType || (val.constructor && val.constructor.name || null) === 'VirtualType') {
      this.virtual(val);
      continue;
    }

    if (Array.isArray(val) && val.length === 1 && val[0] == null) {
      throw new TypeError('Invalid value for schema Array path `' + fullPath +
        '`, got value "' + val[0] + '"');
    }

    if (!(isPOJO(val) || val instanceof SchemaTypeOptions)) {
      // Special-case: Non-options definitely a path so leaf at this node
      // Examples: Schema instances, SchemaType instances
      if (prefix) {
        this.nested[prefix.substring(0, prefix.length - 1)] = true;
      }
      this.path(prefix + key, val);
      if (val[0] != null && !(val[0].instanceOfSchema) && utils.isPOJO(val[0].discriminators)) {
        const schemaType = this.path(prefix + key);
        for (const key in val[0].discriminators) {
          schemaType.discriminator(key, val[0].discriminators[key]);
        }
      }
    } else if (Object.keys(val).length < 1) {
      // Special-case: {} always interpreted as Mixed path so leaf at this node
      if (prefix) {
        this.nested[prefix.substring(0, prefix.length - 1)] = true;
      }
      this.path(fullPath, val); // mixed type
    } else if (!val[typeKey] || (typeKey === 'type' && isPOJO(val.type) && val.type.type)) {
      // Special-case: POJO with no bona-fide type key - interpret as tree of deep paths so recurse
      // nested object `{ last: { name: String } }`. Avoid functions with `.type` re: #10807 because
      // NestJS sometimes adds `Date.type`.
      this.nested[fullPath] = true;
      this.add(val, fullPath + '.');
    } else {
      // There IS a bona-fide type key that may also be a POJO
      const _typeDef = val[typeKey];
      if (isPOJO(_typeDef) && Object.keys(_typeDef).length > 0) {
        // If a POJO is the value of a type key, make it a subdocument
        if (prefix) {
          this.nested[prefix.substring(0, prefix.length - 1)] = true;
        }

        const childSchemaOptions = {};
        if (this._userProvidedOptions.typeKey) {
          childSchemaOptions.typeKey = this._userProvidedOptions.typeKey;
        }
        // propagate 'strict' option to child schema
        if (this._userProvidedOptions.strict != null) {
          childSchemaOptions.strict = this._userProvidedOptions.strict;
        }
        if (this._userProvidedOptions.toObject != null) {
          childSchemaOptions.toObject = utils.omit(this._userProvidedOptions.toObject, ['transform']);
        }
        if (this._userProvidedOptions.toJSON != null) {
          childSchemaOptions.toJSON = utils.omit(this._userProvidedOptions.toJSON, ['transform']);
        }

        const _schema = new Schema(_typeDef, childSchemaOptions);
        _schema.$implicitlyCreated = true;
        const schemaWrappedPath = Object.assign({}, val, { [typeKey]: _schema });
        this.path(prefix + key, schemaWrappedPath);
      } else {
        // Either the type is non-POJO or we interpret it as Mixed anyway
        if (prefix) {
          this.nested[prefix.substring(0, prefix.length - 1)] = true;
        }
        this.path(prefix + key, val);
        if (val != null && !(val.instanceOfSchema) && utils.isPOJO(val.discriminators)) {
          const schemaType = this.path(prefix + key);
          for (const key in val.discriminators) {
            schemaType.discriminator(key, val.discriminators[key]);
          }
        }
      }
    }
  }

  const aliasObj = Object.fromEntries(
    Object.entries(obj).map(([key]) => ([prefix + key, null]))
  );
  aliasFields(this, aliasObj);
  return this;
};

/**
 * Add an alias for `path`. This means getting or setting the `alias`
 * is equivalent to getting or setting the `path`.
 *
 * #### Example:
 *
 *     const toySchema = new Schema({ n: String });
 *
 *     // Make 'name' an alias for 'n'
 *     toySchema.alias('n', 'name');
 *
 *     const Toy = mongoose.model('Toy', toySchema);
 *     const turboMan = new Toy({ n: 'Turbo Man' });
 *
 *     turboMan.name; // 'Turbo Man'
 *     turboMan.n; // 'Turbo Man'
 *
 *     turboMan.name = 'Turbo Man Action Figure';
 *     turboMan.n; // 'Turbo Man Action Figure'
 *
 *     await turboMan.save(); // Saves { _id: ..., n: 'Turbo Man Action Figure' }
 *
 *
 * @param {String} path real path to alias
 * @param {String|String[]} alias the path(s) to use as an alias for `path`
 * @return {Schema} the Schema instance
 * @api public
 */

Schema.prototype.alias = function alias(path, alias) {
  aliasFields(this, { [path]: alias });
  return this;
};

/**
 * Remove an index by name or index specification.
 *
 * removeIndex only removes indexes from your schema object. Does **not** affect the indexes
 * in MongoDB.
 *
 * #### Example:
 *
 *     const ToySchema = new Schema({ name: String, color: String, price: Number });
 *
 *     // Add a new index on { name, color }
 *     ToySchema.index({ name: 1, color: 1 });
 *
 *     // Remove index on { name, color }
 *     // Keep in mind that order matters! `removeIndex({ color: 1, name: 1 })` won't remove the index
 *     ToySchema.removeIndex({ name: 1, color: 1 });
 *
 *     // Add an index with a custom name
 *     ToySchema.index({ color: 1 }, { name: 'my custom index name' });
 *     // Remove index by name
 *     ToySchema.removeIndex('my custom index name');
 *
 * @param {Object|string} index name or index specification
 * @return {Schema} the Schema instance
 * @api public
 */

Schema.prototype.removeIndex = function removeIndex(index) {
  if (arguments.length > 1) {
    throw new Error('removeIndex() takes only 1 argument');
  }

  if (typeof index !== 'object' && typeof index !== 'string') {
    throw new Error('removeIndex() may only take either an object or a string as an argument');
  }

  if (typeof index === 'object') {
    for (let i = this._indexes.length - 1; i >= 0; --i) {
      if (util.isDeepStrictEqual(this._indexes[i][0], index)) {
        this._indexes.splice(i, 1);
      }
    }
  } else {
    for (let i = this._indexes.length - 1; i >= 0; --i) {
      if (this._indexes[i][1] != null && this._indexes[i][1].name === index) {
        this._indexes.splice(i, 1);
      }
    }
  }

  return this;
};

/**
 * Remove all indexes from this schema.
 *
 * clearIndexes only removes indexes from your schema object. Does **not** affect the indexes
 * in MongoDB.
 *
 * #### Example:
 *
 *     const ToySchema = new Schema({ name: String, color: String, price: Number });
 *     ToySchema.index({ name: 1 });
 *     ToySchema.index({ color: 1 });
 *
 *     // Remove all indexes on this schema
 *     ToySchema.clearIndexes();
 *
 *     ToySchema.indexes(); // []
 *
 * @return {Schema} the Schema instance
 * @api public
 */

Schema.prototype.clearIndexes = function clearIndexes() {
  this._indexes.length = 0;

  return this;
};

/**
 * Add an [Atlas search index](https://www.mongodb.com/docs/atlas/atlas-search/create-index/) that Mongoose will create using `Model.createSearchIndex()`.
 * This function only works when connected to MongoDB Atlas.
 *
 * #### Example:
 *
 *     const ToySchema = new Schema({ name: String, color: String, price: Number });
 *     ToySchema.searchIndex({ name: 'test', definition: { mappings: { dynamic: true } } });
 *
 * @param {Object} description index options, including `name` and `definition`
 * @param {String} description.name
 * @param {Object} description.definition
 * @return {Schema} the Schema instance
 * @api public
 */

Schema.prototype.searchIndex = function searchIndex(description) {
  this._searchIndexes.push(description);

  return this;
};

/**
 * Reserved document keys.
 *
 * Keys in this object are names that are warned in schema declarations
 * because they have the potential to break Mongoose/ Mongoose plugins functionality. If you create a schema
 * using `new Schema()` with one of these property names, Mongoose will log a warning.
 *
 * - _posts
 * - _pres
 * - collection
  * - emit
 * - errors
 * - get
 * - init
 * - isModified
 * - isNew
 * - listeners
 * - modelName
 * - on
 * - once
 * - populated
 * - prototype
 * - remove
 * - removeListener
 * - save
 * - schema
 * - toObject
 * - validate
 *
 * _NOTE:_ Use of these terms as method names is permitted, but play at your own risk, as they may be existing mongoose document methods you are stomping on.
 *
 *      const schema = new Schema(..);
 *      schema.methods.init = function () {} // potentially breaking
 *
 * @property reserved
 * @memberOf Schema
 * @static
 */

Schema.reserved = Object.create(null);
Schema.prototype.reserved = Schema.reserved;

const reserved = Schema.reserved;
// Core object
reserved['prototype'] =
// EventEmitter
reserved.emit =
reserved.listeners =
reserved.removeListener =

// document properties and functions
reserved.collection =
reserved.errors =
reserved.get =
reserved.init =
reserved.isModified =
reserved.isNew =
reserved.populated =
reserved.remove =
reserved.save =
reserved.toObject =
reserved.validate = 1;
reserved.collection = 1;

/**
 * Gets/sets schema paths.
 *
 * Sets a path (if arity 2)
 * Gets a path (if arity 1)
 *
 * #### Example:
 *
 *     schema.path('name') // returns a SchemaType
 *     schema.path('name', Number) // changes the schemaType of `name` to Number
 *
 * @param {String} path The name of the Path to get / set
 * @param {Object} [obj] The Type to set the path to, if provided the path will be SET, otherwise the path will be GET
 * @api public
 */

Schema.prototype.path = function(path, obj) {
  if (obj === undefined) {
    if (this.paths[path] != null) {
      return this.paths[path];
    }
    // Convert to '.$' to check subpaths re: gh-6405
    const cleanPath = _pathToPositionalSyntax(path);
    let schematype = _getPath(this, path, cleanPath);
    if (schematype != null) {
      return schematype;
    }

    // Look for maps
    const mapPath = getMapPath(this, path);
    if (mapPath != null) {
      return mapPath;
    }

    // Look if a parent of this path is mixed
    schematype = this.hasMixedParent(cleanPath);
    if (schematype != null) {
      return schematype;
    }

    // subpaths?
    return hasNumericSubpathRegex.test(path)
      ? getPositionalPath(this, path, cleanPath)
      : undefined;
  }

  // some path names conflict with document methods
  const firstPieceOfPath = path.split('.')[0];
  if (reserved[firstPieceOfPath] && !this.options.suppressReservedKeysWarning) {
    const errorMessage = `\`${firstPieceOfPath}\` is a reserved schema pathname and may break some functionality. ` +
      'You are allowed to use it, but use at your own risk. ' +
      'To disable this warning pass `suppressReservedKeysWarning` as a schema option.';

    utils.warn(errorMessage);
  }

  if (typeof obj === 'object' && utils.hasUserDefinedProperty(obj, 'ref')) {
    validateRef(obj.ref, path);
  }

  // update the tree
  const subpaths = path.split(/\./);
  const last = subpaths.pop();
  let branch = this.tree;
  let fullPath = '';

  for (const sub of subpaths) {
    if (utils.specialProperties.has(sub)) {
      throw new Error('Cannot set special property `' + sub + '` on a schema');
    }
    fullPath = fullPath += (fullPath.length > 0 ? '.' : '') + sub;
    if (!branch[sub]) {
      this.nested[fullPath] = true;
      branch[sub] = {};
    }
    if (typeof branch[sub] !== 'object') {
      const msg = 'Cannot set nested path `' + path + '`. '
          + 'Parent path `'
          + fullPath
          + '` already set to type ' + branch[sub].name
          + '.';
      throw new Error(msg);
    }
    branch = branch[sub];
  }

  branch[last] = clone(obj);

  this.paths[path] = this.interpretAsType(path, obj, this.options);
  const schemaType = this.paths[path];

  if (schemaType.$isSchemaMap) {
    // Maps can have arbitrary keys, so `$*` is internal shorthand for "any key"
    // The '$' is to imply this path should never be stored in MongoDB so we
    // can easily build a regexp out of this path, and '*' to imply "any key."
    const mapPath = path + '.$*';

    this.paths[mapPath] = schemaType.$__schemaType;
    this.mapPaths.push(this.paths[mapPath]);
  }

  if (schemaType.$isSingleNested) {
    for (const key of Object.keys(schemaType.schema.paths)) {
      this.singleNestedPaths[path + '.' + key] = schemaType.schema.paths[key];
    }
    for (const key of Object.keys(schemaType.schema.singleNestedPaths)) {
      this.singleNestedPaths[path + '.' + key] =
        schemaType.schema.singleNestedPaths[key];
    }
    for (const key of Object.keys(schemaType.schema.subpaths)) {
      this.singleNestedPaths[path + '.' + key] =
        schemaType.schema.subpaths[key];
    }
    for (const key of Object.keys(schemaType.schema.nested)) {
      this.singleNestedPaths[path + '.' + key] = 'nested';
    }

    Object.defineProperty(schemaType.schema, 'base', {
      configurable: true,
      enumerable: false,
      writable: false,
      value: this.base
    });

    schemaType.caster.base = this.base;
    this.childSchemas.push({
      schema: schemaType.schema,
      model: schemaType.caster
    });
  } else if (schemaType.$isMongooseDocumentArray) {
    Object.defineProperty(schemaType.schema, 'base', {
      configurable: true,
      enumerable: false,
      writable: false,
      value: this.base
    });

    schemaType.casterConstructor.base = this.base;
    this.childSchemas.push({
      schema: schemaType.schema,
      model: schemaType.casterConstructor
    });
  }

  if (schemaType.$isMongooseArray && schemaType.caster instanceof SchemaType) {
    let arrayPath = path;
    let _schemaType = schemaType;

    const toAdd = [];
    while (_schemaType.$isMongooseArray) {
      arrayPath = arrayPath + '.$';

      // Skip arrays of document arrays
      if (_schemaType.$isMongooseDocumentArray) {
        _schemaType.$embeddedSchemaType._arrayPath = arrayPath;
        _schemaType.$embeddedSchemaType._arrayParentPath = path;
        _schemaType = _schemaType.$embeddedSchemaType;
      } else {
        _schemaType.caster._arrayPath = arrayPath;
        _schemaType.caster._arrayParentPath = path;
        _schemaType = _schemaType.caster;
      }

      this.subpaths[arrayPath] = _schemaType;
    }

    for (const _schemaType of toAdd) {
      this.subpaths[_schemaType.path] = _schemaType;
    }
  }

  if (schemaType.$isMongooseDocumentArray) {
    for (const key of Object.keys(schemaType.schema.paths)) {
      const _schemaType = schemaType.schema.paths[key];
      this.subpaths[path + '.' + key] = _schemaType;
      if (typeof _schemaType === 'object' && _schemaType != null && _schemaType.$parentSchemaDocArray == null) {
        _schemaType.$parentSchemaDocArray = schemaType;
      }
    }
    for (const key of Object.keys(schemaType.schema.subpaths)) {
      const _schemaType = schemaType.schema.subpaths[key];
      this.subpaths[path + '.' + key] = _schemaType;
      if (typeof _schemaType === 'object' && _schemaType != null && _schemaType.$parentSchemaDocArray == null) {
        _schemaType.$parentSchemaDocArray = schemaType;
      }
    }
    for (const key of Object.keys(schemaType.schema.singleNestedPaths)) {
      const _schemaType = schemaType.schema.singleNestedPaths[key];
      this.subpaths[path + '.' + key] = _schemaType;
      if (typeof _schemaType === 'object' && _schemaType != null && _schemaType.$parentSchemaDocArray == null) {
        _schemaType.$parentSchemaDocArray = schemaType;
      }
    }
  }

  return this;
};

/*!
 * ignore
 */

function gatherChildSchemas(schema) {
  const childSchemas = [];

  for (const path of Object.keys(schema.paths)) {
    const schematype = schema.paths[path];
    if (schematype.$isMongooseDocumentArray || schematype.$isSingleNested) {
      childSchemas.push({ schema: schematype.schema, model: schematype.caster });
    }
  }

  return childSchemas;
}

/*!
 * ignore
 */

function _getPath(schema, path, cleanPath) {
  if (schema.paths.hasOwnProperty(path)) {
    return schema.paths[path];
  }
  if (schema.subpaths.hasOwnProperty(cleanPath)) {
    const subpath = schema.subpaths[cleanPath];
    if (subpath === 'nested') {
      return undefined;
    }
    return subpath;
  }
  if (schema.singleNestedPaths.hasOwnProperty(cleanPath) && typeof schema.singleNestedPaths[cleanPath] === 'object') {
    const singleNestedPath = schema.singleNestedPaths[cleanPath];
    if (singleNestedPath === 'nested') {
      return undefined;
    }
    return singleNestedPath;
  }

  return null;
}

/*!
 * ignore
 */

function _pathToPositionalSyntax(path) {
  if (!/\.\d+/.test(path)) {
    return path;
  }
  return path.replace(/\.\d+\./g, '.$.').replace(/\.\d+$/, '.$');
}

/*!
 * ignore
 */

function getMapPath(schema, path) {
  if (schema.mapPaths.length === 0) {
    return null;
  }
  for (const val of schema.mapPaths) {
    const _path = val.path;
    const re = new RegExp('^' + _path.replace(/\.\$\*/g, '\\.[^.]+') + '$');
    if (re.test(path)) {
      return schema.paths[_path];
    }
  }

  return null;
}

/**
 * The Mongoose instance this schema is associated with
 *
 * @property base
 * @api private
 */

Object.defineProperty(Schema.prototype, 'base', {
  configurable: true,
  enumerable: false,
  writable: true,
  value: null
});

/**
 * Converts type arguments into Mongoose Types.
 *
 * @param {String} path
 * @param {Object} obj constructor
 * @param {Object} options
 * @api private
 */

Schema.prototype.interpretAsType = function(path, obj, options) {
  if (obj instanceof SchemaType) {
    if (obj.path === path) {
      return obj;
    }
    const clone = obj.clone();
    clone.path = path;
    return clone;
  }


  // If this schema has an associated Mongoose object, use the Mongoose object's
  // copy of SchemaTypes re: gh-7158 gh-6933
  const MongooseTypes = this.base != null ? this.base.Schema.Types : Schema.Types;
  const Types = this.base != null ? this.base.Types : require('./types');

  if (!utils.isPOJO(obj) && !(obj instanceof SchemaTypeOptions)) {
    const constructorName = utils.getFunctionName(obj.constructor);
    if (constructorName !== 'Object') {
      const oldObj = obj;
      obj = {};
      obj[options.typeKey] = oldObj;
    }
  }

  // Get the type making sure to allow keys named "type"
  // and default to mixed if not specified.
  // { type: { type: String, default: 'freshcut' } }
  let type = obj[options.typeKey] && (obj[options.typeKey] instanceof Function || options.typeKey !== 'type' || !obj.type.type)
    ? obj[options.typeKey]
    : {};
  let name;

  if (utils.isPOJO(type) || type === 'mixed') {
    return new MongooseTypes.Mixed(path, obj);
  }

  if (Array.isArray(type) || type === Array || type === 'array' || type === MongooseTypes.Array) {
    // if it was specified through { type } look for `cast`
    let cast = (type === Array || type === 'array')
      ? obj.cast || obj.of
      : type[0];

    // new Schema({ path: [new Schema({ ... })] })
    if (cast && cast.instanceOfSchema) {
      if (!(cast instanceof Schema)) {
        if (this.options._isMerging) {
          cast = new Schema(cast);
        } else {
          throw new TypeError('Schema for array path `' + path +
            '` is from a different copy of the Mongoose module. ' +
            'Please make sure you\'re using the same version ' +
            'of Mongoose everywhere with `npm list mongoose`. If you are still ' +
            'getting this error, please add `new Schema()` around the path: ' +
            `${path}: new Schema(...)`);
        }
      }
      return new MongooseTypes.DocumentArray(path, cast, obj);
    }
    if (cast &&
        cast[options.typeKey] &&
        cast[options.typeKey].instanceOfSchema) {
      if (!(cast[options.typeKey] instanceof Schema)) {
        if (this.options._isMerging) {
          cast[options.typeKey] = new Schema(cast[options.typeKey]);
        } else {
          throw new TypeError('Schema for array path `' + path +
            '` is from a different copy of the Mongoose module. ' +
            'Please make sure you\'re using the same version ' +
            'of Mongoose everywhere with `npm list mongoose`. If you are still ' +
            'getting this error, please add `new Schema()` around the path: ' +
            `${path}: new Schema(...)`);
        }
      }
      return new MongooseTypes.DocumentArray(path, cast[options.typeKey], obj, cast);
    }
    if (typeof cast !== 'undefined') {
      if (Array.isArray(cast) || cast.type === Array || cast.type == 'Array') {
        if (cast && cast.type == 'Array') {
          cast.type = Array;
        }
        return new MongooseTypes.Array(path, this.interpretAsType(path, cast, options), obj);
      }
    }

    // Handle both `new Schema({ arr: [{ subpath: String }] })` and `new Schema({ arr: [{ type: { subpath: string } }] })`
    const castFromTypeKey = (cast != null && cast[options.typeKey] && (options.typeKey !== 'type' || !cast.type.type)) ?
      cast[options.typeKey] :
      cast;
    if (typeof cast === 'string') {
      cast = MongooseTypes[cast.charAt(0).toUpperCase() + cast.substring(1)];
    } else if (utils.isPOJO(castFromTypeKey)) {
      if (Object.keys(castFromTypeKey).length) {
        // The `minimize` and `typeKey` options propagate to child schemas
        // declared inline, like `{ arr: [{ val: { $type: String } }] }`.
        // See gh-3560
        const childSchemaOptions = { minimize: options.minimize };
        if (options.typeKey) {
          childSchemaOptions.typeKey = options.typeKey;
        }
        // propagate 'strict' option to child schema
        if (options.hasOwnProperty('strict')) {
          childSchemaOptions.strict = options.strict;
        }
        if (options.hasOwnProperty('strictQuery')) {
          childSchemaOptions.strictQuery = options.strictQuery;
        }
        if (options.hasOwnProperty('toObject')) {
          childSchemaOptions.toObject = utils.omit(options.toObject, ['transform']);
        }
        if (options.hasOwnProperty('toJSON')) {
          childSchemaOptions.toJSON = utils.omit(options.toJSON, ['transform']);
        }

        if (this._userProvidedOptions.hasOwnProperty('_id')) {
          childSchemaOptions._id = this._userProvidedOptions._id;
        } else if (Schema.Types.DocumentArray.defaultOptions._id != null) {
          childSchemaOptions._id = Schema.Types.DocumentArray.defaultOptions._id;
        }

        const childSchema = new Schema(castFromTypeKey, childSchemaOptions);
        childSchema.$implicitlyCreated = true;
        return new MongooseTypes.DocumentArray(path, childSchema, obj);
      } else {
        // Special case: empty object becomes mixed
        return new MongooseTypes.Array(path, MongooseTypes.Mixed, obj);
      }
    }

    if (cast) {
      type = cast[options.typeKey] && (options.typeKey !== 'type' || !cast.type.type)
        ? cast[options.typeKey]
        : cast;
      if (Array.isArray(type)) {
        return new MongooseTypes.Array(path, this.interpretAsType(path, type, options), obj);
      }

      name = typeof type === 'string'
        ? type
        : type.schemaName || utils.getFunctionName(type);

      // For Jest 26+, see #10296
      if (name === 'ClockDate') {
        name = 'Date';
      }

      if (name === void 0) {
        throw new TypeError('Invalid schema configuration: ' +
          `Could not determine the embedded type for array \`${path}\`. ` +
          'See https://mongoosejs.com/docs/guide.html#definition for more info on supported schema syntaxes.');
      }
      if (!MongooseTypes.hasOwnProperty(name)) {
        throw new TypeError('Invalid schema configuration: ' +
          `\`${name}\` is not a valid type within the array \`${path}\`.` +
          'See https://bit.ly/mongoose-schematypes for a list of valid schema types.');
      }
    }

    return new MongooseTypes.Array(path, cast || MongooseTypes.Mixed, obj, options);
  }

  if (type && type.instanceOfSchema) {
    return new MongooseTypes.Subdocument(type, path, obj);
  }

  if (Buffer.isBuffer(type)) {
    name = 'Buffer';
  } else if (typeof type === 'function' || typeof type === 'object') {
    name = type.schemaName || utils.getFunctionName(type);
  } else if (type === Types.ObjectId) {
    name = 'ObjectId';
  } else if (type === Types.Decimal128) {
    name = 'Decimal128';
  } else {
    name = type == null ? '' + type : type.toString();
  }

  if (name) {
    name = name.charAt(0).toUpperCase() + name.substring(1);
  }
  // Special case re: gh-7049 because the bson `ObjectID` class' capitalization
  // doesn't line up with Mongoose's.
  if (name === 'ObjectID') {
    name = 'ObjectId';
  }
  // For Jest 26+, see #10296
  if (name === 'ClockDate') {
    name = 'Date';
  }

  if (name === void 0) {
    throw new TypeError(`Invalid schema configuration: \`${path}\` schematype definition is ` +
      'invalid. See ' +
      'https://mongoosejs.com/docs/guide.html#definition for more info on supported schema syntaxes.');
  }
  if (MongooseTypes[name] == null) {
    throw new TypeError(`Invalid schema configuration: \`${name}\` is not ` +
      `a valid type at path \`${path}\`. See ` +
      'https://bit.ly/mongoose-schematypes for a list of valid schema types.');
  }

  const schemaType = new MongooseTypes[name](path, obj);

  if (schemaType.$isSchemaMap) {
    createMapNestedSchemaType(this, schemaType, path, obj, options);
  }

  return schemaType;
};

/*!
 * ignore
 */

function createMapNestedSchemaType(schema, schemaType, path, obj, options) {
  const mapPath = path + '.$*';
  let _mapType = { type: {} };
  if (utils.hasUserDefinedProperty(obj, 'of')) {
    const isInlineSchema = utils.isPOJO(obj.of) &&
      Object.keys(obj.of).length > 0 &&
      !utils.hasUserDefinedProperty(obj.of, schema.options.typeKey);
    if (isInlineSchema) {
      _mapType = { [schema.options.typeKey]: new Schema(obj.of) };
    } else if (utils.isPOJO(obj.of)) {
      _mapType = Object.assign({}, obj.of);
    } else {
      _mapType = { [schema.options.typeKey]: obj.of };
    }

    if (_mapType[schema.options.typeKey] && _mapType[schema.options.typeKey].instanceOfSchema) {
      const subdocumentSchema = _mapType[schema.options.typeKey];
      subdocumentSchema.eachPath((subpath, type) => {
        if (type.options.select === true || type.options.select === false) {
          throw new MongooseError('Cannot use schema-level projections (`select: true` or `select: false`) within maps at path "' + path + '.' + subpath + '"');
        }
      });
    }

    if (utils.hasUserDefinedProperty(obj, 'ref')) {
      _mapType.ref = obj.ref;
    }
  }
  schemaType.$__schemaType = schema.interpretAsType(mapPath, _mapType, options);
}

/**
 * Iterates the schemas paths similar to Array#forEach.
 *
 * The callback is passed the pathname and the schemaType instance.
 *
 * #### Example:
 *
 *     const userSchema = new Schema({ name: String, registeredAt: Date });
 *     userSchema.eachPath((pathname, schematype) => {
 *       // Prints twice:
 *       // name SchemaString { ... }
 *       // registeredAt SchemaDate { ... }
 *       console.log(pathname, schematype);
 *     });
 *
 * @param {Function} fn callback function
 * @return {Schema} this
 * @api public
 */

Schema.prototype.eachPath = function(fn) {
  const keys = Object.keys(this.paths);
  const len = keys.length;

  for (let i = 0; i < len; ++i) {
    fn(keys[i], this.paths[keys[i]]);
  }

  return this;
};

/**
 * Returns an Array of path strings that are required by this schema.
 *
 * #### Example:
 *
 *     const s = new Schema({
 *       name: { type: String, required: true },
 *       age: { type: String, required: true },
 *       notes: String
 *     });
 *     s.requiredPaths(); // [ 'age', 'name' ]
 *
 * @api public
 * @param {Boolean} invalidate Refresh the cache
 * @return {Array}
 */

Schema.prototype.requiredPaths = function requiredPaths(invalidate) {
  if (this._requiredpaths && !invalidate) {
    return this._requiredpaths;
  }

  const paths = Object.keys(this.paths);
  let i = paths.length;
  const ret = [];

  while (i--) {
    const path = paths[i];
    if (this.paths[path].isRequired) {
      ret.push(path);
    }
  }
  this._requiredpaths = ret;
  return this._requiredpaths;
};

/**
 * Returns indexes from fields and schema-level indexes (cached).
 *
 * @api private
 * @return {Array}
 */

Schema.prototype.indexedPaths = function indexedPaths() {
  if (this._indexedpaths) {
    return this._indexedpaths;
  }
  this._indexedpaths = this.indexes();
  return this._indexedpaths;
};

/**
 * Returns the pathType of `path` for this schema.
 *
 * Given a path, returns whether it is a real, virtual, nested, or ad-hoc/undefined path.
 *
 * #### Example:
 *
 *     const s = new Schema({ name: String, nested: { foo: String } });
 *     s.virtual('foo').get(() => 42);
 *     s.pathType('name'); // "real"
 *     s.pathType('nested'); // "nested"
 *     s.pathType('foo'); // "virtual"
 *     s.pathType('fail'); // "adhocOrUndefined"
 *
 * @param {String} path
 * @return {String}
 * @api public
 */

Schema.prototype.pathType = function(path) {
  if (this.paths.hasOwnProperty(path)) {
    return 'real';
  }
  if (this.virtuals.hasOwnProperty(path)) {
    return 'virtual';
  }
  if (this.nested.hasOwnProperty(path)) {
    return 'nested';
  }

  // Convert to '.$' to check subpaths re: gh-6405
  const cleanPath = _pathToPositionalSyntax(path);

  if (this.subpaths.hasOwnProperty(cleanPath) || this.subpaths.hasOwnProperty(path)) {
    return 'real';
  }

  const singleNestedPath = this.singleNestedPaths.hasOwnProperty(cleanPath) || this.singleNestedPaths.hasOwnProperty(path);
  if (singleNestedPath) {
    return singleNestedPath === 'nested' ? 'nested' : 'real';
  }

  // Look for maps
  const mapPath = getMapPath(this, path);
  if (mapPath != null) {
    return 'real';
  }

  if (/\.\d+\.|\.\d+$/.test(path)) {
    return getPositionalPathType(this, path, cleanPath);
  }
  return 'adhocOrUndefined';
};

/**
 * Returns true iff this path is a child of a mixed schema.
 *
 * @param {String} path
 * @return {Boolean}
 * @api private
 */

Schema.prototype.hasMixedParent = function(path) {
  const subpaths = path.split(/\./g);
  path = '';
  for (let i = 0; i < subpaths.length; ++i) {
    path = i > 0 ? path + '.' + subpaths[i] : subpaths[i];
    if (this.paths.hasOwnProperty(path) &&
        this.paths[path] instanceof MongooseTypes.Mixed) {
      return this.paths[path];
    }
  }

  return null;
};

/**
 * Setup updatedAt and createdAt timestamps to documents if enabled
 *
 * @param {Boolean|Object} timestamps timestamps options
 * @api private
 */
Schema.prototype.setupTimestamp = function(timestamps) {
  return setupTimestamps(this, timestamps);
};

/**
 * ignore. Deprecated re: #6405
 * @param {Any} self
 * @param {String} path
 * @api private
 */

function getPositionalPathType(self, path, cleanPath) {
  const subpaths = path.split(/\.(\d+)\.|\.(\d+)$/).filter(Boolean);
  if (subpaths.length < 2) {
    return self.paths.hasOwnProperty(subpaths[0]) ?
      self.paths[subpaths[0]] :
      'adhocOrUndefined';
  }

  let val = self.path(subpaths[0]);
  let isNested = false;
  if (!val) {
    return 'adhocOrUndefined';
  }

  const last = subpaths.length - 1;

  for (let i = 1; i < subpaths.length; ++i) {
    isNested = false;
    const subpath = subpaths[i];

    if (i === last && val && !/\D/.test(subpath)) {
      if (val.$isMongooseDocumentArray) {
        val = val.$embeddedSchemaType;
      } else if (val instanceof MongooseTypes.Array) {
        // StringSchema, NumberSchema, etc
        val = val.caster;
      } else {
        val = undefined;
      }
      break;
    }

    // ignore if its just a position segment: path.0.subpath
    if (!/\D/.test(subpath)) {
      // Nested array
      if (val instanceof MongooseTypes.Array && i !== last) {
        val = val.caster;
      }
      continue;
    }

    if (!(val && val.schema)) {
      val = undefined;
      break;
    }

    const type = val.schema.pathType(subpath);
    isNested = (type === 'nested');
    val = val.schema.path(subpath);
  }

  self.subpaths[cleanPath] = val;
  if (val) {
    return 'real';
  }
  if (isNested) {
    return 'nested';
  }
  return 'adhocOrUndefined';
}


/*!
 * ignore
 */

function getPositionalPath(self, path, cleanPath) {
  getPositionalPathType(self, path, cleanPath);
  return self.subpaths[cleanPath];
}

/**
 * Adds a method call to the queue.
 *
 * #### Example:
 *
 *     schema.methods.print = function() { console.log(this); };
 *     schema.queue('print', []); // Print the doc every one is instantiated
 *
 *     const Model = mongoose.model('Test', schema);
 *     new Model({ name: 'test' }); // Prints '{"_id": ..., "name": "test" }'
 *
 * @param {String} name name of the document method to call later
 * @param {Array} args arguments to pass to the method
 * @api public
 */

Schema.prototype.queue = function(name, args) {
  this.callQueue.push([name, args]);
  return this;
};

/**
 * Defines a pre hook for the model.
 *
 * #### Example:
 *
 *     const toySchema = new Schema({ name: String, created: Date });
 *
 *     toySchema.pre('save', function(next) {
 *       if (!this.created) this.created = new Date;
 *       next();
 *     });
 *
 *     toySchema.pre('validate', function(next) {
 *       if (this.name !== 'Woody') this.name = 'Woody';
 *       next();
 *     });
 *
 *     // Equivalent to calling `pre()` on `find`, `findOne`, `findOneAndUpdate`.
 *     toySchema.pre(/^find/, function(next) {
 *       console.log(this.getFilter());
 *     });
 *
 *     // Equivalent to calling `pre()` on `updateOne`, `findOneAndUpdate`.
 *     toySchema.pre(['updateOne', 'findOneAndUpdate'], function(next) {
 *       console.log(this.getFilter());
 *     });
 *
 *     toySchema.pre('deleteOne', function() {
 *       // Runs when you call `Toy.deleteOne()`
 *     });
 *
 *     toySchema.pre('deleteOne', { document: true }, function() {
 *       // Runs when you call `doc.deleteOne()`
 *     });
 *
 * @param {String|RegExp|String[]} methodName The method name or regular expression to match method name
 * @param {Object} [options]
 * @param {Boolean} [options.document] If `name` is a hook for both document and query middleware, set to `true` to run on document middleware. For example, set `options.document` to `true` to apply this hook to `Document#deleteOne()` rather than `Query#deleteOne()`.
 * @param {Boolean} [options.query] If `name` is a hook for both document and query middleware, set to `true` to run on query middleware.
 * @param {Function} callback
 * @api public
 */

Schema.prototype.pre = function(name) {
  if (name instanceof RegExp) {
    const remainingArgs = Array.prototype.slice.call(arguments, 1);
    for (const fn of hookNames) {
      if (name.test(fn)) {
        this.pre.apply(this, [fn].concat(remainingArgs));
      }
    }
    return this;
  }
  if (Array.isArray(name)) {
    const remainingArgs = Array.prototype.slice.call(arguments, 1);
    for (const el of name) {
      this.pre.apply(this, [el].concat(remainingArgs));
    }
    return this;
  }
  this.s.hooks.pre.apply(this.s.hooks, arguments);
  return this;
};

/**
 * Defines a post hook for the document
 *
 *     const schema = new Schema(..);
 *     schema.post('save', function (doc) {
 *       console.log('this fired after a document was saved');
 *     });
 *
 *     schema.post('find', function(docs) {
 *       console.log('this fired after you ran a find query');
 *     });
 *
 *     schema.post(/Many$/, function(res) {
 *       console.log('this fired after you ran `updateMany()` or `deleteMany()`');
 *     });
 *
 *     const Model = mongoose.model('Model', schema);
 *
 *     const m = new Model(..);
 *     m.save(function(err) {
 *       console.log('this fires after the `post` hook');
 *     });
 *
 *     m.find(function(err, docs) {
 *       console.log('this fires after the post find hook');
 *     });
 *
 * @param {String|RegExp|String[]} methodName The method name or regular expression to match method name
 * @param {Object} [options]
 * @param {Boolean} [options.document] If `name` is a hook for both document and query middleware, set to `true` to run on document middleware.
 * @param {Boolean} [options.query] If `name` is a hook for both document and query middleware, set to `true` to run on query middleware.
 * @param {Function} fn callback
 * @see middleware https://mongoosejs.com/docs/middleware.html
 * @see kareem https://npmjs.org/package/kareem
 * @api public
 */

Schema.prototype.post = function(name) {
  if (name instanceof RegExp) {
    const remainingArgs = Array.prototype.slice.call(arguments, 1);
    for (const fn of hookNames) {
      if (name.test(fn)) {
        this.post.apply(this, [fn].concat(remainingArgs));
      }
    }
    return this;
  }
  if (Array.isArray(name)) {
    const remainingArgs = Array.prototype.slice.call(arguments, 1);
    for (const el of name) {
      this.post.apply(this, [el].concat(remainingArgs));
    }
    return this;
  }
  this.s.hooks.post.apply(this.s.hooks, arguments);
  return this;
};

/**
 * Registers a plugin for this schema.
 *
 * #### Example:
 *
 *     const s = new Schema({ name: String });
 *     s.plugin(schema => console.log(schema.path('name').path));
 *     mongoose.model('Test', s); // Prints 'name'
 *
 * Or with Options:
 *
 *     const s = new Schema({ name: String });
 *     s.plugin((schema, opts) => console.log(opts.text, schema.path('name').path), { text: "Schema Path Name:" });
 *     mongoose.model('Test', s); // Prints 'Schema Path Name: name'
 *
 * @param {Function} plugin The Plugin's callback
 * @param {Object} [opts] Options to pass to the plugin
 * @param {Boolean} [opts.deduplicate=false] If true, ignore duplicate plugins (same `fn` argument using `===`)
 * @see plugins https://mongoosejs.com/docs/plugins.html
 * @api public
 */

Schema.prototype.plugin = function(fn, opts) {
  if (typeof fn !== 'function') {
    throw new Error('First param to `schema.plugin()` must be a function, ' +
      'got "' + (typeof fn) + '"');
  }


  if (opts && opts.deduplicate) {
    for (const plugin of this.plugins) {
      if (plugin.fn === fn) {
        return this;
      }
    }
  }
  this.plugins.push({ fn: fn, opts: opts });

  fn(this, opts);
  return this;
};

/**
 * Adds an instance method to documents constructed from Models compiled from this schema.
 *
 * #### Example:
 *
 *     const schema = kittySchema = new Schema(..);
 *
 *     schema.method('meow', function () {
 *       console.log('meeeeeoooooooooooow');
 *     })
 *
 *     const Kitty = mongoose.model('Kitty', schema);
 *
 *     const fizz = new Kitty;
 *     fizz.meow(); // meeeeeooooooooooooow
 *
 * If a hash of name/fn pairs is passed as the only argument, each name/fn pair will be added as methods.
 *
 *     schema.method({
 *         purr: function () {}
 *       , scratch: function () {}
 *     });
 *
 *     // later
 *     const fizz = new Kitty;
 *     fizz.purr();
 *     fizz.scratch();
 *
 * NOTE: `Schema.method()` adds instance methods to the `Schema.methods` object. You can also add instance methods directly to the `Schema.methods` object as seen in the [guide](https://mongoosejs.com/docs/guide.html#methods)
 *
 * @param {String|Object} name The Method Name for a single function, or a Object of "string-function" pairs.
 * @param {Function} [fn] The Function in a single-function definition.
 * @api public
 */

Schema.prototype.method = function(name, fn, options) {
  if (typeof name !== 'string') {
    for (const i in name) {
      this.methods[i] = name[i];
      this.methodOptions[i] = clone(options);
    }
  } else {
    this.methods[name] = fn;
    this.methodOptions[name] = clone(options);
  }
  return this;
};

/**
 * Adds static "class" methods to Models compiled from this schema.
 *
 * #### Example:
 *
 *     const schema = new Schema(..);
 *     // Equivalent to `schema.statics.findByName = function(name) {}`;
 *     schema.static('findByName', function(name) {
 *       return this.find({ name: name });
 *     });
 *
 *     const Drink = mongoose.model('Drink', schema);
 *     await Drink.findByName('LaCroix');
 *
 * If a hash of name/fn pairs is passed as the only argument, each name/fn pair will be added as methods.
 *
 *     schema.static({
 *         findByName: function () {..}
 *       , findByCost: function () {..}
 *     });
 *
 *     const Drink = mongoose.model('Drink', schema);
 *     await Drink.findByName('LaCroix');
 *     await Drink.findByCost(3);
 *
 * If a hash of name/fn pairs is passed as the only argument, each name/fn pair will be added as statics.
 *
 * @param {String|Object} name The Method Name for a single function, or a Object of "string-function" pairs.
 * @param {Function} [fn] The Function in a single-function definition.
 * @api public
 * @see Statics https://mongoosejs.com/docs/guide.html#statics
 */

Schema.prototype.static = function(name, fn) {
  if (typeof name !== 'string') {
    for (const i in name) {
      this.statics[i] = name[i];
    }
  } else {
    this.statics[name] = fn;
  }
  return this;
};

/**
 * Defines an index (most likely compound) for this schema.
 *
 * #### Example:
 *
 *     schema.index({ first: 1, last: -1 })
 *
 * @param {Object} fields The Fields to index, with the order, available values: `1 | -1 | '2d' | '2dsphere' | 'geoHaystack' | 'hashed' | 'text'`
 * @param {Object} [options] Options to pass to [MongoDB driver's `createIndex()` function](https://mongodb.github.io/node-mongodb-native/4.9/classes/Collection.html#createIndex)
 * @param {String | number} [options.expires=null] Mongoose-specific syntactic sugar, uses [ms](https://www.npmjs.com/package/ms) to convert `expires` option into seconds for the `expireAfterSeconds` in the above link.
 * @param {String} [options.language_override=null] Tells mongodb to use the specified field instead of `language` for parsing text indexes.
 * @api public
 */

Schema.prototype.index = function(fields, options) {
  fields || (fields = {});
  options || (options = {});

  if (options.expires) {
    utils.expires(options);
  }
  for (const key in fields) {
    if (this.aliases[key]) {
      fields = utils.renameObjKey(fields, key, this.aliases[key]);
    }
  }
  for (const field of Object.keys(fields)) {
    if (fields[field] === 'ascending' || fields[field] === 'asc') {
      fields[field] = 1;
    } else if (fields[field] === 'descending' || fields[field] === 'desc') {
      fields[field] = -1;
    }
  }

  this._indexes.push([fields, options]);
  return this;
};

/**
 * Sets a schema option.
 *
 * #### Example:
 *
 *     schema.set('strict'); // 'true' by default
 *     schema.set('strict', false); // Sets 'strict' to false
 *     schema.set('strict'); // 'false'
 *
 * @param {String} key The name of the option to set the value to
 * @param {Object} [value] The value to set the option to, if not passed, the option will be reset to default
 * @param {Array<string>} [tags] tags to add to read preference if key === 'read'
 * @see Schema https://mongoosejs.com/docs/api/schema.html#Schema()
 * @api public
 */

Schema.prototype.set = function(key, value, tags) {
  if (arguments.length === 1) {
    return this.options[key];
  }

  switch (key) {
    case 'read':
      if (typeof value === 'string') {
        this.options[key] = { mode: handleReadPreferenceAliases(value), tags };
      } else if (Array.isArray(value) && typeof value[0] === 'string') {
        this.options[key] = {
          mode: handleReadPreferenceAliases(value[0]),
          tags: value[1]
        };
      } else {
        this.options[key] = value;
      }
      this._userProvidedOptions[key] = this.options[key];
      break;
    case 'timestamps':
      this.setupTimestamp(value);
      this.options[key] = value;
      this._userProvidedOptions[key] = this.options[key];
      break;
    case '_id':
      this.options[key] = value;
      this._userProvidedOptions[key] = this.options[key];

      if (value && !this.paths['_id']) {
        addAutoId(this);
      } else if (!value && this.paths['_id'] != null && this.paths['_id'].auto) {
        this.remove('_id');
      }
      break;
    default:
      this.options[key] = value;
      this._userProvidedOptions[key] = this.options[key];
      break;
  }

  // Propagate `strict` and `strictQuery` changes down to implicitly created schemas
  if (key === 'strict') {
    _propagateOptionsToImplicitlyCreatedSchemas(this, { strict: value });
  }
  if (key === 'strictQuery') {
    _propagateOptionsToImplicitlyCreatedSchemas(this, { strictQuery: value });
  }
  if (key === 'toObject') {
    value = { ...value };
    // Avoid propagating transform to implicitly created schemas re: gh-3279
    delete value.transform;
    _propagateOptionsToImplicitlyCreatedSchemas(this, { toObject: value });
  }
  if (key === 'toJSON') {
    value = { ...value };
    // Avoid propagating transform to implicitly created schemas re: gh-3279
    delete value.transform;
    _propagateOptionsToImplicitlyCreatedSchemas(this, { toJSON: value });
  }

  return this;
};

/*!
 * Recursively set options on implicitly created schemas
 */

function _propagateOptionsToImplicitlyCreatedSchemas(baseSchema, options) {
  for (const { schema } of baseSchema.childSchemas) {
    if (!schema.$implicitlyCreated) {
      continue;
    }
    Object.assign(schema.options, options);
    _propagateOptionsToImplicitlyCreatedSchemas(schema, options);
  }
}

/**
 * Gets a schema option.
 *
 * #### Example:
 *
 *     schema.get('strict'); // true
 *     schema.set('strict', false);
 *     schema.get('strict'); // false
 *
 * @param {String} key The name of the Option to get the current value for
 * @api public
 * @return {Any} the option's value
 */

Schema.prototype.get = function(key) {
  return this.options[key];
};

const indexTypes = '2d 2dsphere hashed text'.split(' ');

/**
 * The allowed index types
 *
 * @property {String[]} indexTypes
 * @memberOf Schema
 * @static
 * @api public
 */

Object.defineProperty(Schema, 'indexTypes', {
  get: function() {
    return indexTypes;
  },
  set: function() {
    throw new Error('Cannot overwrite Schema.indexTypes');
  }
});

/**
 * Returns a list of indexes that this schema declares, via `schema.index()` or by `index: true` in a path's options.
 * Indexes are expressed as an array `[spec, options]`.
 *
 * #### Example:
 *
 *     const userSchema = new Schema({
 *       email: { type: String, required: true, unique: true },
 *       registeredAt: { type: Date, index: true }
 *     });
 *
 *     // [ [ { email: 1 }, { unique: true, background: true } ],
 *     //   [ { registeredAt: 1 }, { background: true } ] ]
 *     userSchema.indexes();
 *
 * [Plugins](https://mongoosejs.com/docs/plugins.html) can use the return value of this function to modify a schema's indexes.
 * For example, the below plugin makes every index unique by default.
 *
 *     function myPlugin(schema) {
 *       for (const index of schema.indexes()) {
 *         if (index[1].unique === undefined) {
 *           index[1].unique = true;
 *         }
 *       }
 *     }
 *
 * @api public
 * @return {Array} list of indexes defined in the schema
 */

Schema.prototype.indexes = function() {
  return getIndexes(this);
};

/**
 * Creates a virtual type with the given name.
 *
 * @param {String} name The name of the Virtual
 * @param {Object} [options]
 * @param {String|Model} [options.ref] model name or model instance. Marks this as a [populate virtual](https://mongoosejs.com/docs/populate.html#populate-virtuals).
 * @param {String|Function} [options.localField] Required for populate virtuals. See [populate virtual docs](https://mongoosejs.com/docs/populate.html#populate-virtuals) for more information.
 * @param {String|Function} [options.foreignField] Required for populate virtuals. See [populate virtual docs](https://mongoosejs.com/docs/populate.html#populate-virtuals) for more information.
 * @param {Boolean|Function} [options.justOne=false] Only works with populate virtuals. If [truthy](https://masteringjs.io/tutorials/fundamentals/truthy), will be a single doc or `null`. Otherwise, the populate virtual will be an array.
 * @param {Boolean} [options.count=false] Only works with populate virtuals. If [truthy](https://masteringjs.io/tutorials/fundamentals/truthy), this populate virtual will contain the number of documents rather than the documents themselves when you `populate()`.
 * @param {Function|null} [options.get=null] Adds a [getter](https://mongoosejs.com/docs/tutorials/getters-setters.html) to this virtual to transform the populated doc.
 * @param {Object|Function} [options.match=null] Apply a default [`match` option to populate](https://mongoosejs.com/docs/populate.html#match), adding an additional filter to the populate query.
 * @return {VirtualType}
 */

Schema.prototype.virtual = function(name, options) {
  if (name instanceof VirtualType || getConstructorName(name) === 'VirtualType') {
    return this.virtual(name.path, name.options);
  }
  options = new VirtualOptions(options);

  if (utils.hasUserDefinedProperty(options, ['ref', 'refPath'])) {
    if (options.localField == null) {
      throw new Error('Reference virtuals require `localField` option');
    }

    if (options.foreignField == null) {
      throw new Error('Reference virtuals require `foreignField` option');
    }

    this.pre('init', function virtualPreInit(obj) {
      if (mpath.has(name, obj)) {
        const _v = mpath.get(name, obj);
        if (!this.$$populatedVirtuals) {
          this.$$populatedVirtuals = {};
        }

        if (options.justOne || options.count) {
          this.$$populatedVirtuals[name] = Array.isArray(_v) ?
            _v[0] :
            _v;
        } else {
          this.$$populatedVirtuals[name] = Array.isArray(_v) ?
            _v :
            _v == null ? [] : [_v];
        }

        mpath.unset(name, obj);
      }
    });

    const virtual = this.virtual(name);
    virtual.options = options;

    virtual.
      set(function(v) {
        if (!this.$$populatedVirtuals) {
          this.$$populatedVirtuals = {};
        }

        return setPopulatedVirtualValue(
          this.$$populatedVirtuals,
          name,
          v,
          options
        );
      });

    if (typeof options.get === 'function') {
      virtual.get(options.get);
    }

    // Workaround for gh-8198: if virtual is under document array, make a fake
    // virtual. See gh-8210, gh-13189
    const parts = name.split('.');
    let cur = parts[0];
    for (let i = 0; i < parts.length - 1; ++i) {
      if (this.paths[cur] == null) {
        continue;
      }

      if (this.paths[cur].$isMongooseDocumentArray || this.paths[cur].$isSingleNested) {
        const remnant = parts.slice(i + 1).join('.');
        this.paths[cur].schema.virtual(remnant, options);
        break;
      }

      cur += '.' + parts[i + 1];
    }

    return virtual;
  }

  const virtuals = this.virtuals;
  const parts = name.split('.');

  if (this.pathType(name) === 'real') {
    throw new Error('Virtual path "' + name + '"' +
      ' conflicts with a real path in the schema');
  }

  virtuals[name] = parts.reduce(function(mem, part, i) {
    mem[part] || (mem[part] = (i === parts.length - 1)
      ? new VirtualType(options, name)
      : {});
    return mem[part];
  }, this.tree);

  return virtuals[name];
};

/**
 * Returns the virtual type with the given `name`.
 *
 * @param {String} name The name of the Virtual to get
 * @return {VirtualType|null}
 */

Schema.prototype.virtualpath = function(name) {
  return this.virtuals.hasOwnProperty(name) ? this.virtuals[name] : null;
};

/**
 * Removes the given `path` (or [`paths`]).
 *
 * #### Example:
 *
 *     const schema = new Schema({ name: String, age: Number });
 *     schema.remove('name');
 *     schema.path('name'); // Undefined
 *     schema.path('age'); // SchemaNumber { ... }
 *
 * Or as a Array:
 *
 *     schema.remove(['name', 'age']);
 *     schema.path('name'); // Undefined
 *     schema.path('age'); // Undefined
 *
 * @param {String|Array} path The Path(s) to remove
 * @return {Schema} the Schema instance
 * @api public
 */
Schema.prototype.remove = function(path) {
  if (typeof path === 'string') {
    path = [path];
  }
  if (Array.isArray(path)) {
    path.forEach(function(name) {
      if (this.path(name) == null && !this.nested[name]) {
        return;
      }
      if (this.nested[name]) {
        const allKeys = Object.keys(this.paths).
          concat(Object.keys(this.nested));
        for (const path of allKeys) {
          if (path.startsWith(name + '.')) {
            delete this.paths[path];
            delete this.nested[path];
            _deletePath(this, path);
          }
        }

        delete this.nested[name];
        _deletePath(this, name);
        return;
      }

      delete this.paths[name];
      _deletePath(this, name);
    }, this);
  }
  return this;
};

/*!
 * ignore
 */

function _deletePath(schema, name) {
  const pieces = name.split('.');
  const last = pieces.pop();

  let branch = schema.tree;

  for (const piece of pieces) {
    branch = branch[piece];
  }

  delete branch[last];
}

/**
 * Removes the given virtual or virtuals from the schema.
 *
 * @param {String|Array} path The virutal path(s) to remove.
 * @returns {Schema} the Schema instance, or a mongoose error if the virtual does not exist.
 * @api public
 */

Schema.prototype.removeVirtual = function(path) {
  if (typeof path === 'string') {
    path = [path];
  }
  if (Array.isArray(path)) {
    for (const virtual of path) {
      if (this.virtuals[virtual] == null) {
        throw new MongooseError(`Attempting to remove virtual "${virtual}" that does not exist.`);
      }
    }

    for (const virtual of path) {
      delete this.paths[virtual];
      delete this.virtuals[virtual];
      if (virtual.indexOf('.') !== -1) {
        mpath.unset(virtual, this.tree);
      } else {
        delete this.tree[virtual];
      }
    }
  }
  return this;
};

/**
 * Loads an ES6 class into a schema. Maps [setters](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/set) + [getters](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/get), [static methods](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Classes/static),
 * and [instance methods](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Classes#Class_body_and_method_definitions)
 * to schema [virtuals](https://mongoosejs.com/docs/guide.html#virtuals),
 * [statics](https://mongoosejs.com/docs/guide.html#statics), and
 * [methods](https://mongoosejs.com/docs/guide.html#methods).
 *
 * #### Example:
 *
 * ```javascript
 * const md5 = require('md5');
 * const userSchema = new Schema({ email: String });
 * class UserClass {
 *   // `gravatarImage` becomes a virtual
 *   get gravatarImage() {
 *     const hash = md5(this.email.toLowerCase());
 *     return `https://www.gravatar.com/avatar/${hash}`;
 *   }
 *
 *   // `getProfileUrl()` becomes a document method
 *   getProfileUrl() {
 *     return `https://mysite.com/${this.email}`;
 *   }
 *
 *   // `findByEmail()` becomes a static
 *   static findByEmail(email) {
 *     return this.findOne({ email });
 *   }
 * }
 *
 * // `schema` will now have a `gravatarImage` virtual, a `getProfileUrl()` method,
 * // and a `findByEmail()` static
 * userSchema.loadClass(UserClass);
 * ```
 *
 * @param {Function} model The Class to load
 * @param {Boolean} [virtualsOnly] if truthy, only pulls virtuals from the class, not methods or statics
 */
Schema.prototype.loadClass = function(model, virtualsOnly) {
  // Stop copying when hit certain base classes
  if (model === Object.prototype ||
      model === Function.prototype ||
      model.prototype.hasOwnProperty('$isMongooseModelPrototype') ||
      model.prototype.hasOwnProperty('$isMongooseDocumentPrototype')) {
    return this;
  }

  this.loadClass(Object.getPrototypeOf(model), virtualsOnly);

  // Add static methods
  if (!virtualsOnly) {
    Object.getOwnPropertyNames(model).forEach(function(name) {
      if (name.match(/^(length|name|prototype|constructor|__proto__)$/)) {
        return;
      }
      const prop = Object.getOwnPropertyDescriptor(model, name);
      if (prop.hasOwnProperty('value')) {
        this.static(name, prop.value);
      }
    }, this);
  }

  // Add methods and virtuals
  Object.getOwnPropertyNames(model.prototype).forEach(function(name) {
    if (name.match(/^(constructor)$/)) {
      return;
    }
    const method = Object.getOwnPropertyDescriptor(model.prototype, name);
    if (!virtualsOnly) {
      if (typeof method.value === 'function') {
        this.method(name, method.value);
      }
    }
    if (typeof method.get === 'function') {
      if (this.virtuals[name]) {
        this.virtuals[name].getters = [];
      }
      this.virtual(name).get(method.get);
    }
    if (typeof method.set === 'function') {
      if (this.virtuals[name]) {
        this.virtuals[name].setters = [];
      }
      this.virtual(name).set(method.set);
    }
  }, this);

  return this;
};

/*!
 * ignore
 */

Schema.prototype._getSchema = function(path) {
  const _this = this;
  const pathschema = _this.path(path);
  const resultPath = [];

  if (pathschema) {
    pathschema.$fullPath = path;
    return pathschema;
  }

  function search(parts, schema) {
    let p = parts.length + 1;
    let foundschema;
    let trypath;

    while (p--) {
      trypath = parts.slice(0, p).join('.');
      foundschema = schema.path(trypath);
      if (foundschema) {
        resultPath.push(trypath);

        if (foundschema.caster) {
          // array of Mixed?
          if (foundschema.caster instanceof MongooseTypes.Mixed) {
            foundschema.caster.$fullPath = resultPath.join('.');
            return foundschema.caster;
          }

          // Now that we found the array, we need to check if there
          // are remaining document paths to look up for casting.
          // Also we need to handle array.$.path since schema.path
          // doesn't work for that.
          // If there is no foundschema.schema we are dealing with
          // a path like array.$
          if (p !== parts.length) {
            if (foundschema.schema) {
              let ret;
              if (parts[p] === '$' || isArrayFilter(parts[p])) {
                if (p + 1 === parts.length) {
                  // comments.$
                  return foundschema.$embeddedSchemaType;
                }
                // comments.$.comments.$.title
                ret = search(parts.slice(p + 1), foundschema.schema);
                if (ret) {
                  ret.$parentSchemaDocArray = ret.$parentSchemaDocArray ||
                    (foundschema.schema.$isSingleNested ? null : foundschema);
                }
                return ret;
              }
              // this is the last path of the selector
              ret = search(parts.slice(p), foundschema.schema);
              if (ret) {
                ret.$parentSchemaDocArray = ret.$parentSchemaDocArray ||
                  (foundschema.schema.$isSingleNested ? null : foundschema);
              }
              return ret;
            }
          }
        } else if (foundschema.$isSchemaMap) {
          if (p >= parts.length) {
            return foundschema;
          }
          // Any path in the map will be an instance of the map's embedded schematype
          if (p + 1 >= parts.length) {
            return foundschema.$__schemaType;
          }

          if (foundschema.$__schemaType instanceof MongooseTypes.Mixed) {
            return foundschema.$__schemaType;
          }
          if (foundschema.$__schemaType.schema != null) {
            // Map of docs
            const ret = search(parts.slice(p + 1), foundschema.$__schemaType.schema);
            return ret;
          }
        }

        foundschema.$fullPath = resultPath.join('.');

        return foundschema;
      }
    }
  }

  // look for arrays
  const parts = path.split('.');
  for (let i = 0; i < parts.length; ++i) {
    if (parts[i] === '$' || isArrayFilter(parts[i])) {
      // Re: gh-5628, because `schema.path()` doesn't take $ into account.
      parts[i] = '0';
    }
    if (numberRE.test(parts[i])) {
      parts[i] = '$';
    }
  }
  return search(parts, _this);
};

/*!
 * ignore
 */

Schema.prototype._getPathType = function(path) {
  const _this = this;
  const pathschema = _this.path(path);

  if (pathschema) {
    return 'real';
  }

  function search(parts, schema) {
    let p = parts.length + 1,
        foundschema,
        trypath;

    while (p--) {
      trypath = parts.slice(0, p).join('.');
      foundschema = schema.path(trypath);
      if (foundschema) {
        if (foundschema.caster) {
          // array of Mixed?
          if (foundschema.caster instanceof MongooseTypes.Mixed) {
            return { schema: foundschema, pathType: 'mixed' };
          }

          // Now that we found the array, we need to check if there
          // are remaining document paths to look up for casting.
          // Also we need to handle array.$.path since schema.path
          // doesn't work for that.
          // If there is no foundschema.schema we are dealing with
          // a path like array.$
          if (p !== parts.length && foundschema.schema) {
            if (parts[p] === '$' || isArrayFilter(parts[p])) {
              if (p === parts.length - 1) {
                return { schema: foundschema, pathType: 'nested' };
              }
              // comments.$.comments.$.title
              return search(parts.slice(p + 1), foundschema.schema);
            }
            // this is the last path of the selector
            return search(parts.slice(p), foundschema.schema);
          }
          return {
            schema: foundschema,
            pathType: foundschema.$isSingleNested ? 'nested' : 'array'
          };
        }
        return { schema: foundschema, pathType: 'real' };
      } else if (p === parts.length && schema.nested[trypath]) {
        return { schema: schema, pathType: 'nested' };
      }
    }
    return { schema: foundschema || schema, pathType: 'undefined' };
  }

  // look for arrays
  return search(path.split('.'), _this);
};

/*!
 * ignore
 */

function isArrayFilter(piece) {
  return piece.startsWith('$[') && piece.endsWith(']');
}

/**
 * Called by `compile()` _right before_ compiling. Good for making any changes to
 * the schema that should respect options set by plugins, like `id`
 * @method _preCompile
 * @memberOf Schema
 * @instance
 * @api private
 */

Schema.prototype._preCompile = function _preCompile() {
  this.plugin(idGetter, { deduplicate: true });
};

/*!
 * Module exports.
 */

module.exports = exports = Schema;

// require down here because of reference issues

/**
 * The various built-in Mongoose Schema Types.
 *
 * #### Example:
 *
 *     const mongoose = require('mongoose');
 *     const ObjectId = mongoose.Schema.Types.ObjectId;
 *
 * #### Types:
 *
 * - [String](https://mongoosejs.com/docs/schematypes.html#strings)
 * - [Number](https://mongoosejs.com/docs/schematypes.html#numbers)
 * - [Boolean](https://mongoosejs.com/docs/schematypes.html#booleans) | Bool
 * - [Array](https://mongoosejs.com/docs/schematypes.html#arrays)
 * - [Buffer](https://mongoosejs.com/docs/schematypes.html#buffers)
 * - [Date](https://mongoosejs.com/docs/schematypes.html#dates)
 * - [ObjectId](https://mongoosejs.com/docs/schematypes.html#objectids) | Oid
 * - [Mixed](https://mongoosejs.com/docs/schematypes.html#mixed)
 * - [UUID](https://mongoosejs.com/docs/schematypes.html#uuid)
 * - [BigInt](https://mongoosejs.com/docs/schematypes.html#bigint)
 *
 * Using this exposed access to the `Mixed` SchemaType, we can use them in our schema.
 *
 *     const Mixed = mongoose.Schema.Types.Mixed;
 *     new mongoose.Schema({ _user: Mixed })
 *
 * @api public
 */

Schema.Types = MongooseTypes = require('./schema/index');

/*!
 * ignore
 */

exports.ObjectId = MongooseTypes.ObjectId;
