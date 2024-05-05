'use strict';

const SchemaTypeOptions = require('./schemaTypeOptions');

/**
 * The options defined on a Buffer schematype.
 *
 * #### Example:
 *
 *     const schema = new Schema({ bitmap: Buffer });
 *     schema.path('bitmap').options; // SchemaBufferOptions instance
 *
 * @api public
 * @inherits SchemaTypeOptions
 * @constructor SchemaBufferOptions
 */

class SchemaBufferOptions extends SchemaTypeOptions {}

const opts = require('./propertyOptions');

/**
 * Set the default subtype for this buffer.
 *
 * @api public
 * @property subtype
 * @memberOf SchemaBufferOptions
 * @type {Number}
 * @instance
 */

Object.defineProperty(SchemaBufferOptions.prototype, 'subtype', opts);

/*!
 * ignore
 */

module.exports = SchemaBufferOptions;
