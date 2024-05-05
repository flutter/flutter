'use strict';

const SchemaTypeOptions = require('./schemaTypeOptions');

/**
 * The options defined on a Map schematype.
 *
 * #### Example:
 *
 *     const schema = new Schema({ socialMediaHandles: { type: Map, of: String } });
 *     schema.path('socialMediaHandles').options; // SchemaMapOptions instance
 *
 * @api public
 * @inherits SchemaTypeOptions
 * @constructor SchemaMapOptions
 */

class SchemaMapOptions extends SchemaTypeOptions {}

const opts = require('./propertyOptions');

/**
 * If set, specifies the type of this map's values. Mongoose will cast
 * this map's values to the given type.
 *
 * If not set, Mongoose will not cast the map's values.
 *
 * #### Example:
 *
 *     // Mongoose will cast `socialMediaHandles` values to strings
 *     const schema = new Schema({ socialMediaHandles: { type: Map, of: String } });
 *     schema.path('socialMediaHandles').options.of; // String
 *
 * @api public
 * @property of
 * @memberOf SchemaMapOptions
 * @type {Function|string}
 * @instance
 */

Object.defineProperty(SchemaMapOptions.prototype, 'of', opts);

module.exports = SchemaMapOptions;
