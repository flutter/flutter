'use strict';

const SchemaTypeOptions = require('./schemaTypeOptions');

/**
 * The options defined on a single nested schematype.
 *
 * #### Example:
 *
 *     const schema = Schema({ child: Schema({ name: String }) });
 *     schema.path('child').options; // SchemaSubdocumentOptions instance
 *
 * @api public
 * @inherits SchemaTypeOptions
 * @constructor SchemaSubdocumentOptions
 */

class SchemaSubdocumentOptions extends SchemaTypeOptions {}

const opts = require('./propertyOptions');

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
 * @property of
 * @memberOf SchemaSubdocumentOptions
 * @type {Function|string}
 * @instance
 */

Object.defineProperty(SchemaSubdocumentOptions.prototype, '_id', opts);

module.exports = SchemaSubdocumentOptions;
