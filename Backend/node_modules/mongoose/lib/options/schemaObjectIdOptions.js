'use strict';

const SchemaTypeOptions = require('./schemaTypeOptions');

/**
 * The options defined on an ObjectId schematype.
 *
 * #### Example:
 *
 *     const schema = new Schema({ testId: mongoose.ObjectId });
 *     schema.path('testId').options; // SchemaObjectIdOptions instance
 *
 * @api public
 * @inherits SchemaTypeOptions
 * @constructor SchemaObjectIdOptions
 */

class SchemaObjectIdOptions extends SchemaTypeOptions {}

const opts = require('./propertyOptions');

/**
 * If truthy, uses Mongoose's default built-in ObjectId path.
 *
 * @api public
 * @property auto
 * @memberOf SchemaObjectIdOptions
 * @type {Boolean}
 * @instance
 */

Object.defineProperty(SchemaObjectIdOptions.prototype, 'auto', opts);

/**
 * Sets default [populate options](https://mongoosejs.com/docs/populate.html#query-conditions).
 *
 * #### Example:
 *
 *     const schema = new Schema({
 *       child: {
 *         type: 'ObjectId',
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
 * @memberOf SchemaObjectIdOptions
 * @type {Object}
 * @instance
 */

Object.defineProperty(SchemaObjectIdOptions.prototype, 'populate', opts);

/*!
 * ignore
 */

module.exports = SchemaObjectIdOptions;
