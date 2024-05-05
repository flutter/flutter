'use strict';

const SchemaTypeOptions = require('./schemaTypeOptions');

/**
 * The options defined on an Document Array schematype.
 *
 * #### Example:
 *
 *     const schema = new Schema({ users: [{ name: string }] });
 *     schema.path('users').options; // SchemaDocumentArrayOptions instance
 *
 * @api public
 * @inherits SchemaTypeOptions
 * @constructor SchemaDocumentOptions
 */

class SchemaDocumentArrayOptions extends SchemaTypeOptions {}

const opts = require('./propertyOptions');

/**
 * If `true`, Mongoose will skip building any indexes defined in this array's schema.
 * If not set, Mongoose will build all indexes defined in this array's schema.
 *
 * #### Example:
 *
 *     const childSchema = Schema({ name: { type: String, index: true } });
 *     // If `excludeIndexes` is `true`, Mongoose will skip building an index
 *     // on `arr.name`. Otherwise, Mongoose will build an index on `arr.name`.
 *     const parentSchema = Schema({
 *       arr: { type: [childSchema], excludeIndexes: true }
 *     });
 *
 * @api public
 * @property excludeIndexes
 * @memberOf SchemaDocumentArrayOptions
 * @type {Array}
 * @instance
 */

Object.defineProperty(SchemaDocumentArrayOptions.prototype, 'excludeIndexes', opts);

/**
 * If set, overwrites the child schema's `_id` option.
 *
 * #### Example:
 *
 *     const childSchema = Schema({ name: String });
 *     const parentSchema = Schema({
 *       child: { type: childSchema, _id: false }
 *     });
 *     parentSchema.path('child').schema.options._id; // false
 *
 * @api public
 * @property _id
 * @memberOf SchemaDocumentArrayOptions
 * @type {Array}
 * @instance
 */

Object.defineProperty(SchemaDocumentArrayOptions.prototype, '_id', opts);

/*!
 * ignore
 */

module.exports = SchemaDocumentArrayOptions;
