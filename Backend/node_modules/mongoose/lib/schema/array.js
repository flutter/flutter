'use strict';

/*!
 * Module dependencies.
 */

const $exists = require('./operators/exists');
const $type = require('./operators/type');
const MongooseError = require('../error/mongooseError');
const SchemaArrayOptions = require('../options/schemaArrayOptions');
const SchemaType = require('../schemaType');
const CastError = SchemaType.CastError;
const Mixed = require('./mixed');
const arrayDepth = require('../helpers/arrayDepth');
const cast = require('../cast');
const clone = require('../helpers/clone');
const isOperator = require('../helpers/query/isOperator');
const util = require('util');
const utils = require('../utils');
const castToNumber = require('./operators/helpers').castToNumber;
const geospatial = require('./operators/geospatial');
const getDiscriminatorByValue = require('../helpers/discriminator/getDiscriminatorByValue');

let MongooseArray;
let EmbeddedDoc;

const isNestedArraySymbol = Symbol('mongoose#isNestedArray');
const emptyOpts = Object.freeze({});

/**
 * Array SchemaType constructor
 *
 * @param {String} key
 * @param {SchemaType} cast
 * @param {Object} options
 * @param {Object} schemaOptions
 * @inherits SchemaType
 * @api public
 */

function SchemaArray(key, cast, options, schemaOptions) {
  // lazy load
  EmbeddedDoc || (EmbeddedDoc = require('../types').Embedded);

  let typeKey = 'type';
  if (schemaOptions && schemaOptions.typeKey) {
    typeKey = schemaOptions.typeKey;
  }
  this.schemaOptions = schemaOptions;

  if (cast) {
    let castOptions = {};

    if (utils.isPOJO(cast)) {
      if (cast[typeKey]) {
        // support { type: Woot }
        castOptions = clone(cast); // do not alter user arguments
        delete castOptions[typeKey];
        cast = cast[typeKey];
      } else {
        cast = Mixed;
      }
    }

    if (options != null && options.ref != null && castOptions.ref == null) {
      castOptions.ref = options.ref;
    }

    if (cast === Object) {
      cast = Mixed;
    }

    // support { type: 'String' }
    const name = typeof cast === 'string'
      ? cast
      : utils.getFunctionName(cast);

    const Types = require('./index.js');
    const caster = Types.hasOwnProperty(name) ? Types[name] : cast;

    this.casterConstructor = caster;

    if (this.casterConstructor instanceof SchemaArray) {
      this.casterConstructor[isNestedArraySymbol] = true;
    }

    if (typeof caster === 'function' &&
        !caster.$isArraySubdocument &&
        !caster.$isSchemaMap) {
      const path = this.caster instanceof EmbeddedDoc ? null : key;
      this.caster = new caster(path, castOptions);
    } else {
      this.caster = caster;
      if (!(this.caster instanceof EmbeddedDoc)) {
        this.caster.path = key;
      }
    }

    this.$embeddedSchemaType = this.caster;
  }

  this.$isMongooseArray = true;

  SchemaType.call(this, key, options, 'Array');

  let defaultArr;
  let fn;

  if (this.defaultValue != null) {
    defaultArr = this.defaultValue;
    fn = typeof defaultArr === 'function';
  }

  if (!('defaultValue' in this) || this.defaultValue !== void 0) {
    const defaultFn = function() {
      // Leave it up to `cast()` to convert the array
      return fn
        ? defaultArr.call(this)
        : defaultArr != null
          ? [].concat(defaultArr)
          : [];
    };
    defaultFn.$runBeforeSetters = !fn;
    this.default(defaultFn);
  }
}

/**
 * This schema type's name, to defend against minifiers that mangle
 * function names.
 *
 * @api public
 */
SchemaArray.schemaName = 'Array';


/**
 * Options for all arrays.
 *
 * - `castNonArrays`: `true` by default. If `false`, Mongoose will throw a CastError when a value isn't an array. If `true`, Mongoose will wrap the provided value in an array before casting.
 *
 * @static
 * @api public
 */

SchemaArray.options = { castNonArrays: true };

/*!
 * ignore
 */

SchemaArray.defaultOptions = {};

/**
 * Sets a default option for all Array instances.
 *
 * #### Example:
 *
 *     // Make all Array instances have `required` of true by default.
 *     mongoose.Schema.Array.set('required', true);
 *
 *     const User = mongoose.model('User', new Schema({ test: Array }));
 *     new User({ }).validateSync().errors.test.message; // Path `test` is required.
 *
 * @param {String} option The option you'd like to set the value for
 * @param {Any} value value for option
 * @return {undefined}
 * @function set
 * @api public
 */
SchemaArray.set = SchemaType.set;

SchemaArray.setters = [];

/**
 * Attaches a getter for all Array instances
 *
 * @param {Function} getter
 * @return {this}
 * @function get
 * @static
 * @api public
 */

SchemaArray.get = SchemaType.get;

/*!
 * Inherits from SchemaType.
 */
SchemaArray.prototype = Object.create(SchemaType.prototype);
SchemaArray.prototype.constructor = SchemaArray;
SchemaArray.prototype.OptionsConstructor = SchemaArrayOptions;

/*!
 * ignore
 */

SchemaArray._checkRequired = SchemaType.prototype.checkRequired;

/**
 * Override the function the required validator uses to check whether an array
 * passes the `required` check.
 *
 * #### Example:
 *
 *     // Require non-empty array to pass `required` check
 *     mongoose.Schema.Types.Array.checkRequired(v => Array.isArray(v) && v.length);
 *
 *     const M = mongoose.model({ arr: { type: Array, required: true } });
 *     new M({ arr: [] }).validateSync(); // `null`, validation fails!
 *
 * @param {Function} fn
 * @return {Function}
 * @function checkRequired
 * @api public
 */

SchemaArray.checkRequired = SchemaType.checkRequired;

/**
 * Check if the given value satisfies the `required` validator.
 *
 * @param {Any} value
 * @param {Document} doc
 * @return {Boolean}
 * @api public
 */

SchemaArray.prototype.checkRequired = function checkRequired(value, doc) {
  if (typeof value === 'object' && SchemaType._isRef(this, value, doc, true)) {
    return !!value;
  }

  // `require('util').inherits()` does **not** copy static properties, and
  // plugins like mongoose-float use `inherits()` for pre-ES6.
  const _checkRequired = typeof this.constructor.checkRequired === 'function' ?
    this.constructor.checkRequired() :
    SchemaArray.checkRequired();

  return _checkRequired(value);
};

/**
 * Adds an enum validator if this is an array of strings or numbers. Equivalent to
 * `SchemaString.prototype.enum()` or `SchemaNumber.prototype.enum()`
 *
 * @param {...String|Object} [args] enumeration values
 * @return {SchemaArray} this
 */

SchemaArray.prototype.enum = function() {
  let arr = this;
  while (true) {
    const instance = arr &&
    arr.caster &&
    arr.caster.instance;
    if (instance === 'Array') {
      arr = arr.caster;
      continue;
    }
    if (instance !== 'String' && instance !== 'Number') {
      throw new Error('`enum` can only be set on an array of strings or numbers ' +
        ', not ' + instance);
    }
    break;
  }

  let enumArray = arguments;
  if (!Array.isArray(arguments) && utils.isObject(arguments)) {
    enumArray = utils.object.vals(enumArray);
  }

  arr.caster.enum.apply(arr.caster, enumArray);
  return this;
};

/**
 * Overrides the getters application for the population special-case
 *
 * @param {Object} value
 * @param {Object} scope
 * @api private
 */

SchemaArray.prototype.applyGetters = function(value, scope) {
  if (scope != null && scope.$__ != null && scope.$populated(this.path)) {
    // means the object id was populated
    return value;
  }

  const ret = SchemaType.prototype.applyGetters.call(this, value, scope);
  return ret;
};

SchemaArray.prototype._applySetters = function(value, scope, init, priorVal) {
  if (this.casterConstructor.$isMongooseArray &&
      SchemaArray.options.castNonArrays &&
      !this[isNestedArraySymbol]) {
    // Check nesting levels and wrap in array if necessary
    let depth = 0;
    let arr = this;
    while (arr != null &&
      arr.$isMongooseArray &&
      !arr.$isMongooseDocumentArray) {
      ++depth;
      arr = arr.casterConstructor;
    }

    // No need to wrap empty arrays
    if (value != null && value.length !== 0) {
      const valueDepth = arrayDepth(value);
      if (valueDepth.min === valueDepth.max && valueDepth.max < depth && valueDepth.containsNonArrayItem) {
        for (let i = valueDepth.max; i < depth; ++i) {
          value = [value];
        }
      }
    }
  }

  return SchemaType.prototype._applySetters.call(this, value, scope, init, priorVal);
};

/**
 * Casts values for set().
 *
 * @param {Object} value
 * @param {Document} doc document that triggers the casting
 * @param {Boolean} init whether this is an initialization cast
 * @api private
 */

SchemaArray.prototype.cast = function(value, doc, init, prev, options) {
  // lazy load
  MongooseArray || (MongooseArray = require('../types').Array);

  let i;
  let l;

  if (Array.isArray(value)) {
    const len = value.length;
    if (!len && doc) {
      const indexes = doc.schema.indexedPaths();

      const arrayPath = this.path;
      for (i = 0, l = indexes.length; i < l; ++i) {
        const pathIndex = indexes[i][0][arrayPath];
        if (pathIndex === '2dsphere' || pathIndex === '2d') {
          return;
        }
      }

      // Special case: if this index is on the parent of what looks like
      // GeoJSON, skip setting the default to empty array re: #1668, #3233
      const arrayGeojsonPath = this.path.endsWith('.coordinates') ?
        this.path.substring(0, this.path.lastIndexOf('.')) : null;
      if (arrayGeojsonPath != null) {
        for (i = 0, l = indexes.length; i < l; ++i) {
          const pathIndex = indexes[i][0][arrayGeojsonPath];
          if (pathIndex === '2dsphere') {
            return;
          }
        }
      }
    }

    options = options || emptyOpts;

    let rawValue = utils.isMongooseArray(value) ? value.__array : value;
    let path = options.path || this.path;
    if (options.arrayPathIndex != null) {
      path += '.' + options.arrayPathIndex;
    }
    value = MongooseArray(rawValue, path, doc, this);
    rawValue = value.__array;

    if (init && doc != null && doc.$__ != null && doc.$populated(this.path)) {
      return value;
    }

    const caster = this.caster;
    const isMongooseArray = caster.$isMongooseArray;
    if (caster && this.casterConstructor !== Mixed) {
      try {
        const len = rawValue.length;
        for (i = 0; i < len; i++) {
          const opts = {};
          // Perf: creating `arrayPath` is expensive for large arrays.
          // We only need `arrayPath` if this is a nested array, so
          // skip if possible.
          if (isMongooseArray) {
            if (options.arrayPath != null) {
              opts.arrayPathIndex = i;
            } else if (caster._arrayParentPath != null) {
              opts.arrayPathIndex = i;
            }
          }
          rawValue[i] = caster.applySetters(rawValue[i], doc, init, void 0, opts);
        }
      } catch (e) {
        // rethrow
        throw new CastError('[' + e.kind + ']', util.inspect(value), this.path + '.' + i, e, this);
      }
    }

    return value;
  }

  const castNonArraysOption = this.options.castNonArrays != null ? this.options.castNonArrays : SchemaArray.options.castNonArrays;
  if (init || castNonArraysOption) {
    // gh-2442: if we're loading this from the db and its not an array, mark
    // the whole array as modified.
    if (!!doc && !!init) {
      doc.markModified(this.path);
    }
    return this.cast([value], doc, init);
  }

  throw new CastError('Array', util.inspect(value), this.path, null, this);
};

/*!
 * ignore
 */

SchemaArray.prototype._castForPopulate = function _castForPopulate(value, doc) {
  // lazy load
  MongooseArray || (MongooseArray = require('../types').Array);

  if (Array.isArray(value)) {
    let i;
    const rawValue = value.__array ? value.__array : value;
    const len = rawValue.length;

    const caster = this.caster;
    if (caster && this.casterConstructor !== Mixed) {
      try {
        for (i = 0; i < len; i++) {
          const opts = {};
          // Perf: creating `arrayPath` is expensive for large arrays.
          // We only need `arrayPath` if this is a nested array, so
          // skip if possible.
          if (caster.$isMongooseArray && caster._arrayParentPath != null) {
            opts.arrayPathIndex = i;
          }

          rawValue[i] = caster.cast(rawValue[i], doc, false, void 0, opts);
        }
      } catch (e) {
        // rethrow
        throw new CastError('[' + e.kind + ']', util.inspect(value), this.path + '.' + i, e, this);
      }
    }

    return value;
  }

  throw new CastError('Array', util.inspect(value), this.path, null, this);
};

SchemaArray.prototype.$toObject = SchemaArray.prototype.toObject;

/*!
 * ignore
 */

SchemaArray.prototype.discriminator = function(...args) {
  let arr = this;
  while (arr.$isMongooseArray && !arr.$isMongooseDocumentArray) {
    arr = arr.casterConstructor;
    if (arr == null || typeof arr === 'function') {
      throw new MongooseError('You can only add an embedded discriminator on ' +
        'a document array, ' + this.path + ' is a plain array');
    }
  }
  return arr.discriminator(...args);
};

/*!
 * ignore
 */

SchemaArray.prototype.clone = function() {
  const options = Object.assign({}, this.options);
  const schematype = new this.constructor(this.path, this.caster, options, this.schemaOptions);
  schematype.validators = this.validators.slice();
  if (this.requiredValidator !== undefined) {
    schematype.requiredValidator = this.requiredValidator;
  }
  return schematype;
};

SchemaArray.prototype._castForQuery = function(val, context) {
  let Constructor = this.casterConstructor;

  if (val &&
      Constructor.discriminators &&
      Constructor.schema &&
      Constructor.schema.options &&
      Constructor.schema.options.discriminatorKey) {
    if (typeof val[Constructor.schema.options.discriminatorKey] === 'string' &&
        Constructor.discriminators[val[Constructor.schema.options.discriminatorKey]]) {
      Constructor = Constructor.discriminators[val[Constructor.schema.options.discriminatorKey]];
    } else {
      const constructorByValue = getDiscriminatorByValue(Constructor.discriminators, val[Constructor.schema.options.discriminatorKey]);
      if (constructorByValue) {
        Constructor = constructorByValue;
      }
    }
  }

  const proto = this.casterConstructor.prototype;
  const protoCastForQuery = proto && proto.castForQuery;
  const protoCast = proto && proto.cast;
  const constructorCastForQuery = Constructor.castForQuery;
  const caster = this.caster;

  if (Array.isArray(val)) {
    this.setters.reverse().forEach(setter => {
      val = setter.call(this, val, this);
    });
    val = val.map(function(v) {
      if (utils.isObject(v) && v.$elemMatch) {
        return v;
      }
      if (protoCastForQuery) {
        v = protoCastForQuery.call(caster, null, v, context);
        return v;
      } else if (protoCast) {
        v = protoCast.call(caster, v);
        return v;
      } else if (constructorCastForQuery) {
        v = constructorCastForQuery.call(caster, null, v, context);
        return v;
      }
      if (v != null) {
        v = new Constructor(v);
        return v;
      }
      return v;
    });
  } else if (protoCastForQuery) {
    val = protoCastForQuery.call(caster, null, val, context);
  } else if (protoCast) {
    val = protoCast.call(caster, val);
  } else if (constructorCastForQuery) {
    val = constructorCastForQuery.call(caster, null, val, context);
  } else if (val != null) {
    val = new Constructor(val);
  }

  return val;
};

/**
 * Casts values for queries.
 *
 * @param {String} $conditional
 * @param {any} [value]
 * @api private
 */

SchemaArray.prototype.castForQuery = function($conditional, val, context) {
  let handler;

  if ($conditional != null) {
    handler = this.$conditionalHandlers[$conditional];

    if (!handler) {
      throw new Error('Can\'t use ' + $conditional + ' with Array.');
    }

    return handler.call(this, val, context);
  } else {
    return this._castForQuery(val, context);
  }
};

function cast$all(val, context) {
  if (!Array.isArray(val)) {
    val = [val];
  }

  val = val.map((v) => {
    if (!utils.isObject(v)) {
      return v;
    }
    if (v.$elemMatch != null) {
      return { $elemMatch: cast(this.casterConstructor.schema, v.$elemMatch, null, this && this.$$context) };
    }

    const o = {};
    o[this.path] = v;
    return cast(this.casterConstructor.schema, o, null, this && this.$$context)[this.path];
  }, this);

  return this.castForQuery(null, val, context);
}

function cast$elemMatch(val, context) {
  const keys = Object.keys(val);
  const numKeys = keys.length;
  for (let i = 0; i < numKeys; ++i) {
    const key = keys[i];
    const value = val[key];
    if (isOperator(key) && value != null) {
      val[key] = this.castForQuery(key, value, context);
    }
  }

  // Is this an embedded discriminator and is the discriminator key set?
  // If so, use the discriminator schema. See gh-7449
  const discriminatorKey = this &&
    this.casterConstructor &&
    this.casterConstructor.schema &&
    this.casterConstructor.schema.options &&
    this.casterConstructor.schema.options.discriminatorKey;
  const discriminators = this &&
  this.casterConstructor &&
  this.casterConstructor.schema &&
  this.casterConstructor.schema.discriminators || {};
  if (discriminatorKey != null &&
      val[discriminatorKey] != null &&
      discriminators[val[discriminatorKey]] != null) {
    return cast(discriminators[val[discriminatorKey]], val, null, this && this.$$context);
  }
  const schema = this.casterConstructor.schema ?? context.schema;
  return cast(schema, val, null, this && this.$$context);
}

const handle = SchemaArray.prototype.$conditionalHandlers = {};

handle.$all = cast$all;
handle.$options = String;
handle.$elemMatch = cast$elemMatch;
handle.$geoIntersects = geospatial.cast$geoIntersects;
handle.$or = createLogicalQueryOperatorHandler('$or');
handle.$and = createLogicalQueryOperatorHandler('$and');
handle.$nor = createLogicalQueryOperatorHandler('$nor');

function createLogicalQueryOperatorHandler(op) {
  return function logicalQueryOperatorHandler(val, context) {
    if (!Array.isArray(val)) {
      throw new TypeError('conditional ' + op + ' requires an array');
    }

    const ret = [];
    for (const obj of val) {
      ret.push(cast(this.casterConstructor.schema ?? context.schema, obj, null, this && this.$$context));
    }

    return ret;
  };
}

handle.$near =
handle.$nearSphere = geospatial.cast$near;

handle.$within =
handle.$geoWithin = geospatial.cast$within;

handle.$size =
handle.$minDistance =
handle.$maxDistance = castToNumber;

handle.$exists = $exists;
handle.$type = $type;

handle.$eq =
handle.$gt =
handle.$gte =
handle.$lt =
handle.$lte =
handle.$not =
handle.$regex =
handle.$ne = SchemaArray.prototype._castForQuery;

// `$in` is special because you can also include an empty array in the query
// like `$in: [1, []]`, see gh-5913
handle.$nin = SchemaType.prototype.$conditionalHandlers.$nin;
handle.$in = SchemaType.prototype.$conditionalHandlers.$in;

/*!
 * Module exports.
 */

module.exports = SchemaArray;
