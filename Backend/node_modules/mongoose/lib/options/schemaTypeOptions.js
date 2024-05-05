'use strict';

const clone = require('../helpers/clone');

/**
 * The options defined on a schematype.
 *
 * #### Example:
 *
 *     const schema = new Schema({ name: String });
 *     schema.path('name').options instanceof mongoose.SchemaTypeOptions; // true
 *
 * @api public
 * @constructor SchemaTypeOptions
 */

class SchemaTypeOptions {
  constructor(obj) {
    if (obj == null) {
      return this;
    }
    Object.assign(this, clone(obj));
  }
}

const opts = require('./propertyOptions');

/**
 * The type to cast this path to.
 *
 * @api public
 * @property type
 * @memberOf SchemaTypeOptions
 * @type {Function|String|Object}
 * @instance
 */

Object.defineProperty(SchemaTypeOptions.prototype, 'type', opts);

/**
 * Function or object describing how to validate this schematype.
 *
 * @api public
 * @property validate
 * @memberOf SchemaTypeOptions
 * @type {Function|Object}
 * @instance
 */

Object.defineProperty(SchemaTypeOptions.prototype, 'validate', opts);

/**
 * Allows overriding casting logic for this individual path. If a string, the
 * given string overwrites Mongoose's default cast error message.
 *
 * #### Example:
 *
 *     const schema = new Schema({
 *       num: {
 *         type: Number,
 *         cast: '{VALUE} is not a valid number'
 *       }
 *     });
 *
 *     // Throws 'CastError: "bad" is not a valid number'
 *     schema.path('num').cast('bad');
 *
 *     const Model = mongoose.model('Test', schema);
 *     const doc = new Model({ num: 'fail' });
 *     const err = doc.validateSync();
 *
 *     err.errors['num']; // 'CastError: "fail" is not a valid number'
 *
 * @api public
 * @property cast
 * @memberOf SchemaTypeOptions
 * @type {String}
 * @instance
 */

Object.defineProperty(SchemaTypeOptions.prototype, 'cast', opts);

/**
 * If true, attach a required validator to this path, which ensures this path
 * cannot be set to a nullish value. If a function, Mongoose calls the
 * function and only checks for nullish values if the function returns a truthy value.
 *
 * @api public
 * @property required
 * @memberOf SchemaTypeOptions
 * @type {Function|Boolean}
 * @instance
 */

Object.defineProperty(SchemaTypeOptions.prototype, 'required', opts);

/**
 * The default value for this path. If a function, Mongoose executes the function
 * and uses the return value as the default.
 *
 * @api public
 * @property default
 * @memberOf SchemaTypeOptions
 * @type {Function|Any}
 * @instance
 */

Object.defineProperty(SchemaTypeOptions.prototype, 'default', opts);

/**
 * The model that `populate()` should use if populating this path.
 *
 * @api public
 * @property ref
 * @memberOf SchemaTypeOptions
 * @type {Function|String}
 * @instance
 */

Object.defineProperty(SchemaTypeOptions.prototype, 'ref', opts);

/**
 * The path in the document that `populate()` should use to find the model
 * to use.
 *
 * @api public
 * @property ref
 * @memberOf SchemaTypeOptions
 * @type {Function|String}
 * @instance
 */

Object.defineProperty(SchemaTypeOptions.prototype, 'refPath', opts);

/**
 * Whether to include or exclude this path by default when loading documents
 * using `find()`, `findOne()`, etc.
 *
 * @api public
 * @property select
 * @memberOf SchemaTypeOptions
 * @type {Boolean|Number}
 * @instance
 */

Object.defineProperty(SchemaTypeOptions.prototype, 'select', opts);

/**
 * If [truthy](https://masteringjs.io/tutorials/fundamentals/truthy), Mongoose will
 * build an index on this path when the model is compiled.
 *
 * @api public
 * @property index
 * @memberOf SchemaTypeOptions
 * @type {Boolean|Number|Object}
 * @instance
 */

Object.defineProperty(SchemaTypeOptions.prototype, 'index', opts);

/**
 * If [truthy](https://masteringjs.io/tutorials/fundamentals/truthy), Mongoose
 * will build a unique index on this path when the
 * model is compiled. [The `unique` option is **not** a validator](https://mongoosejs.com/docs/validation.html#the-unique-option-is-not-a-validator).
 *
 * @api public
 * @property unique
 * @memberOf SchemaTypeOptions
 * @type {Boolean|Number}
 * @instance
 */

Object.defineProperty(SchemaTypeOptions.prototype, 'unique', opts);

/**
 * If [truthy](https://masteringjs.io/tutorials/fundamentals/truthy), Mongoose will
 * disallow changes to this path once the document
 * is saved to the database for the first time. Read more about [immutability in Mongoose here](https://thecodebarbarian.com/whats-new-in-mongoose-5-6-immutable-properties.html).
 *
 * @api public
 * @property immutable
 * @memberOf SchemaTypeOptions
 * @type {Function|Boolean}
 * @instance
 */

Object.defineProperty(SchemaTypeOptions.prototype, 'immutable', opts);

/**
 * If [truthy](https://masteringjs.io/tutorials/fundamentals/truthy), Mongoose will
 * build a sparse index on this path.
 *
 * @api public
 * @property sparse
 * @memberOf SchemaTypeOptions
 * @type {Boolean|Number}
 * @instance
 */

Object.defineProperty(SchemaTypeOptions.prototype, 'sparse', opts);

/**
 * If [truthy](https://masteringjs.io/tutorials/fundamentals/truthy), Mongoose
 * will build a text index on this path.
 *
 * @api public
 * @property text
 * @memberOf SchemaTypeOptions
 * @type {Boolean|Number|Object}
 * @instance
 */

Object.defineProperty(SchemaTypeOptions.prototype, 'text', opts);

/**
 * Define a transform function for this individual schema type.
 * Only called when calling `toJSON()` or `toObject()`.
 *
 * #### Example:
 *
 *     const schema = Schema({
 *       myDate: {
 *         type: Date,
 *         transform: v => v.getFullYear()
 *       }
 *     });
 *     const Model = mongoose.model('Test', schema);
 *
 *     const doc = new Model({ myDate: new Date('2019/06/01') });
 *     doc.myDate instanceof Date; // true
 *
 *     const res = doc.toObject({ transform: true });
 *     res.myDate; // 2019
 *
 * @api public
 * @property transform
 * @memberOf SchemaTypeOptions
 * @type {Function}
 * @instance
 */

Object.defineProperty(SchemaTypeOptions.prototype, 'transform', opts);

module.exports = SchemaTypeOptions;
