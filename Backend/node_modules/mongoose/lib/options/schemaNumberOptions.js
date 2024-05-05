'use strict';

const SchemaTypeOptions = require('./schemaTypeOptions');

/**
 * The options defined on a Number schematype.
 *
 * #### Example:
 *
 *     const schema = new Schema({ count: Number });
 *     schema.path('count').options; // SchemaNumberOptions instance
 *
 * @api public
 * @inherits SchemaTypeOptions
 * @constructor SchemaNumberOptions
 */

class SchemaNumberOptions extends SchemaTypeOptions {}

const opts = require('./propertyOptions');

/**
 * If set, Mongoose adds a validator that checks that this path is at least the
 * given `min`.
 *
 * @api public
 * @property min
 * @memberOf SchemaNumberOptions
 * @type {Number}
 * @instance
 */

Object.defineProperty(SchemaNumberOptions.prototype, 'min', opts);

/**
 * If set, Mongoose adds a validator that checks that this path is less than the
 * given `max`.
 *
 * @api public
 * @property max
 * @memberOf SchemaNumberOptions
 * @type {Number}
 * @instance
 */

Object.defineProperty(SchemaNumberOptions.prototype, 'max', opts);

/**
 * If set, Mongoose adds a validator that checks that this path is strictly
 * equal to one of the given values.
 *
 * #### Example:
 *
 *     const schema = new Schema({
 *       favoritePrime: {
 *         type: Number,
 *         enum: [3, 5, 7]
 *       }
 *     });
 *     schema.path('favoritePrime').options.enum; // [3, 5, 7]
 *
 * @api public
 * @property enum
 * @memberOf SchemaNumberOptions
 * @type {Array}
 * @instance
 */

Object.defineProperty(SchemaNumberOptions.prototype, 'enum', opts);

/**
 * Sets default [populate options](https://mongoosejs.com/docs/populate.html#query-conditions).
 *
 * #### Example:
 *
 *     const schema = new Schema({
 *       child: {
 *         type: Number,
 *         ref: 'Child',
 *         populate: { select: 'name' }
 *       }
 *     });
 *     const Parent = mongoose.model('Parent', schema);
 *
 *     // Automatically adds `.select('name')`
 *     Parent.findOne().populate('child');
 *
 * @api public
 * @property populate
 * @memberOf SchemaNumberOptions
 * @type {Object}
 * @instance
 */

Object.defineProperty(SchemaNumberOptions.prototype, 'populate', opts);

/*!
 * ignore
 */

module.exports = SchemaNumberOptions;
