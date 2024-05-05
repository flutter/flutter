'use strict';

/*!
 * Module dependencies.
 */

const CastError = require('../error/cast');
const EventEmitter = require('events').EventEmitter;
const ObjectExpectedError = require('../error/objectExpected');
const SchemaSubdocumentOptions = require('../options/schemaSubdocumentOptions');
const SchemaType = require('../schemaType');
const applyDefaults = require('../helpers/document/applyDefaults');
const $exists = require('./operators/exists');
const castToNumber = require('./operators/helpers').castToNumber;
const discriminator = require('../helpers/model/discriminator');
const geospatial = require('./operators/geospatial');
const getConstructor = require('../helpers/discriminator/getConstructor');
const handleIdOption = require('../helpers/schema/handleIdOption');
const internalToObjectOptions = require('../options').internalToObjectOptions;
const isExclusive = require('../helpers/projection/isExclusive');
const utils = require('../utils');
const InvalidSchemaOptionError = require('../error/invalidSchemaOption');

let SubdocumentType;

module.exports = SchemaSubdocument;

/**
 * Single nested subdocument SchemaType constructor.
 *
 * @param {Schema} schema
 * @param {String} path
 * @param {Object} options
 * @inherits SchemaType
 * @api public
 */

function SchemaSubdocument(schema, path, options) {
  if (schema.options.timeseries) {
    throw new InvalidSchemaOptionError(path, 'timeseries');
  }
  const schemaTypeIdOption = SchemaSubdocument.defaultOptions &&
    SchemaSubdocument.defaultOptions._id;
  if (schemaTypeIdOption != null) {
    options = options || {};
    options._id = schemaTypeIdOption;
  }

  schema = handleIdOption(schema, options);

  this.caster = _createConstructor(schema, null, options);
  this.caster.path = path;
  this.caster.prototype.$basePath = path;
  this.schema = schema;
  this.$isSingleNested = true;
  this.base = schema.base;
  SchemaType.call(this, path, options, 'Embedded');
}

/*!
 * ignore
 */

SchemaSubdocument.prototype = Object.create(SchemaType.prototype);
SchemaSubdocument.prototype.constructor = SchemaSubdocument;
SchemaSubdocument.prototype.OptionsConstructor = SchemaSubdocumentOptions;

/*!
 * ignore
 */

function _createConstructor(schema, baseClass, options) {
  // lazy load
  SubdocumentType || (SubdocumentType = require('../types/subdocument'));

  const _embedded = function SingleNested(value, path, parent) {
    this.$__parent = parent;
    SubdocumentType.apply(this, arguments);

    if (parent == null) {
      return;
    }
    this.$session(parent.$session());
  };

  schema._preCompile();

  const proto = baseClass != null ? baseClass.prototype : SubdocumentType.prototype;
  _embedded.prototype = Object.create(proto);
  _embedded.prototype.$__setSchema(schema);
  _embedded.prototype.constructor = _embedded;
  _embedded.$__required = options?.required;
  _embedded.base = schema.base;
  _embedded.schema = schema;
  _embedded.$isSingleNested = true;
  _embedded.events = new EventEmitter();
  _embedded.prototype.toBSON = function() {
    return this.toObject(internalToObjectOptions);
  };

  // apply methods
  for (const i in schema.methods) {
    _embedded.prototype[i] = schema.methods[i];
  }

  // apply statics
  for (const i in schema.statics) {
    _embedded[i] = schema.statics[i];
  }

  for (const i in EventEmitter.prototype) {
    _embedded[i] = EventEmitter.prototype[i];
  }

  return _embedded;
}

/**
 * Special case for when users use a common location schema to represent
 * locations for use with $geoWithin.
 * https://www.mongodb.com/docs/manual/reference/operator/query/geoWithin/
 *
 * @param {Object} val
 * @api private
 */

SchemaSubdocument.prototype.$conditionalHandlers.$geoWithin = function handle$geoWithin(val, context) {
  return { $geometry: this.castForQuery(null, val.$geometry, context) };
};

/*!
 * ignore
 */

SchemaSubdocument.prototype.$conditionalHandlers.$near =
SchemaSubdocument.prototype.$conditionalHandlers.$nearSphere = geospatial.cast$near;

SchemaSubdocument.prototype.$conditionalHandlers.$within =
SchemaSubdocument.prototype.$conditionalHandlers.$geoWithin = geospatial.cast$within;

SchemaSubdocument.prototype.$conditionalHandlers.$geoIntersects =
  geospatial.cast$geoIntersects;

SchemaSubdocument.prototype.$conditionalHandlers.$minDistance = castToNumber;
SchemaSubdocument.prototype.$conditionalHandlers.$maxDistance = castToNumber;

SchemaSubdocument.prototype.$conditionalHandlers.$exists = $exists;

/**
 * Casts contents
 *
 * @param {Object} value
 * @api private
 */

SchemaSubdocument.prototype.cast = function(val, doc, init, priorVal, options) {
  if (val && val.$isSingleNested && val.parent === doc) {
    return val;
  }

  if (val != null && (typeof val !== 'object' || Array.isArray(val))) {
    throw new ObjectExpectedError(this.path, val);
  }

  const discriminatorKeyPath = this.schema.path(this.schema.options.discriminatorKey);
  const defaultDiscriminatorValue = discriminatorKeyPath == null ? null : discriminatorKeyPath.getDefault(doc);
  const Constructor = getConstructor(this.caster, val, defaultDiscriminatorValue);

  let subdoc;

  // Only pull relevant selected paths and pull out the base path
  const parentSelected = doc && doc.$__ && doc.$__.selected;
  const path = this.path;
  const selected = parentSelected == null ? null : Object.keys(parentSelected).reduce((obj, key) => {
    if (key.startsWith(path + '.')) {
      obj = obj || {};
      obj[key.substring(path.length + 1)] = parentSelected[key];
    }
    return obj;
  }, null);
  if (init) {
    subdoc = new Constructor(void 0, selected, doc, false, { defaults: false });
    delete subdoc.$__.defaults;
    subdoc.$init(val);
    const exclude = isExclusive(selected);
    applyDefaults(subdoc, selected, exclude);
  } else {
    options = Object.assign({}, options, { priorDoc: priorVal });
    if (Object.keys(val).length === 0) {
      return new Constructor({}, selected, doc, undefined, options);
    }

    return new Constructor(val, selected, doc, undefined, options);
  }

  return subdoc;
};

/**
 * Casts contents for query
 *
 * @param {string} [$conditional] optional query operator (like `$eq` or `$in`)
 * @param {any} value
 * @api private
 */

SchemaSubdocument.prototype.castForQuery = function($conditional, val, context, options) {
  let handler;
  if ($conditional != null) {
    handler = this.$conditionalHandlers[$conditional];
    if (!handler) {
      throw new Error('Can\'t use ' + $conditional);
    }
    return handler.call(this, val);
  }
  if (val == null) {
    return val;
  }

  const Constructor = getConstructor(this.caster, val);
  if (val instanceof Constructor) {
    return val;
  }

  if (this.options.runSetters) {
    val = this._applySetters(val, context);
  }

  const overrideStrict = options != null && options.strict != null ?
    options.strict :
    void 0;

  try {
    val = new Constructor(val, overrideStrict);
  } catch (error) {
    // Make sure we always wrap in a CastError (gh-6803)
    if (!(error instanceof CastError)) {
      throw new CastError('Embedded', val, this.path, error, this);
    }
    throw error;
  }
  return val;
};

/**
 * Async validation on this single nested doc.
 *
 * @api private
 */

SchemaSubdocument.prototype.doValidate = function(value, fn, scope, options) {
  const Constructor = getConstructor(this.caster, value);

  if (value && !(value instanceof Constructor)) {
    value = new Constructor(value, null, (scope != null && scope.$__ != null) ? scope : null);
  }

  if (options && options.skipSchemaValidators) {
    if (!value) {
      return fn(null);
    }
    return value.validate().then(() => fn(null), err => fn(err));
  }

  SchemaType.prototype.doValidate.call(this, value, function(error) {
    if (error) {
      return fn(error);
    }
    if (!value) {
      return fn(null);
    }

    value.validate().then(() => fn(null), err => fn(err));
  }, scope, options);
};

/**
 * Synchronously validate this single nested doc
 *
 * @api private
 */

SchemaSubdocument.prototype.doValidateSync = function(value, scope, options) {
  if (!options || !options.skipSchemaValidators) {
    const schemaTypeError = SchemaType.prototype.doValidateSync.call(this, value, scope);
    if (schemaTypeError) {
      return schemaTypeError;
    }
  }
  if (!value) {
    return;
  }
  return value.validateSync();
};

/**
 * Adds a discriminator to this single nested subdocument.
 *
 * #### Example:
 *
 *     const shapeSchema = Schema({ name: String }, { discriminatorKey: 'kind' });
 *     const schema = Schema({ shape: shapeSchema });
 *
 *     const singleNestedPath = parentSchema.path('shape');
 *     singleNestedPath.discriminator('Circle', Schema({ radius: Number }));
 *
 * @param {String} name
 * @param {Schema} schema fields to add to the schema for instances of this sub-class
 * @param {Object|string} [options] If string, same as `options.value`.
 * @param {String} [options.value] the string stored in the `discriminatorKey` property. If not specified, Mongoose uses the `name` parameter.
 * @param {Boolean} [options.clone=true] By default, `discriminator()` clones the given `schema`. Set to `false` to skip cloning.
 * @return {Function} the constructor Mongoose will use for creating instances of this discriminator model
 * @see discriminators https://mongoosejs.com/docs/discriminators.html
 * @api public
 */

SchemaSubdocument.prototype.discriminator = function(name, schema, options) {
  options = options || {};
  const value = utils.isPOJO(options) ? options.value : options;
  const clone = typeof options.clone === 'boolean'
    ? options.clone
    : true;

  if (schema.instanceOfSchema && clone) {
    schema = schema.clone();
  }

  schema = discriminator(this.caster, name, schema, value, null, null, options.overwriteExisting);

  this.caster.discriminators[name] = _createConstructor(schema, this.caster);

  return this.caster.discriminators[name];
};

/*!
 * ignore
 */

SchemaSubdocument.defaultOptions = {};

/**
 * Sets a default option for all Subdocument instances.
 *
 * #### Example:
 *
 *     // Make all numbers have option `min` equal to 0.
 *     mongoose.Schema.Subdocument.set('required', true);
 *
 * @param {String} option The option you'd like to set the value for
 * @param {Any} value value for option
 * @return {void}
 * @function set
 * @static
 * @api public
 */

SchemaSubdocument.set = SchemaType.set;

SchemaSubdocument.setters = [];

/**
 * Attaches a getter for all Subdocument instances
 *
 * @param {Function} getter
 * @return {this}
 * @function get
 * @static
 * @api public
 */

SchemaSubdocument.get = SchemaType.get;

/*!
 * ignore
 */

SchemaSubdocument.prototype.toJSON = function toJSON() {
  return { path: this.path, options: this.options };
};

/*!
 * ignore
 */

SchemaSubdocument.prototype.clone = function() {
  const schematype = new this.constructor(
    this.schema,
    this.path,
    { ...this.options, _skipApplyDiscriminators: true }
  );
  schematype.validators = this.validators.slice();
  if (this.requiredValidator !== undefined) {
    schematype.requiredValidator = this.requiredValidator;
  }
  schematype.caster.discriminators = Object.assign({}, this.caster.discriminators);
  return schematype;
};
