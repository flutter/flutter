/*!
 * Module dependencies.
 */

'use strict';

const MongooseError = require('../error/mongooseError');
const SchemaType = require('../schemaType');
const SchemaSubdocument = require('./subdocument');
const getConstructor = require('../helpers/discriminator/getConstructor');

/**
 * DocumentArrayElement SchemaType constructor.
 *
 * @param {String} path
 * @param {Object} options
 * @inherits SchemaType
 * @api public
 */

function SchemaDocumentArrayElement(path, options) {
  this.$parentSchemaType = options && options.$parentSchemaType;
  if (!this.$parentSchemaType) {
    throw new MongooseError('Cannot create DocumentArrayElement schematype without a parent');
  }
  delete options.$parentSchemaType;

  SchemaType.call(this, path, options, 'DocumentArrayElement');

  this.$isMongooseDocumentArrayElement = true;
}

/**
 * This schema type's name, to defend against minifiers that mangle
 * function names.
 *
 * @api public
 */
SchemaDocumentArrayElement.schemaName = 'DocumentArrayElement';

SchemaDocumentArrayElement.defaultOptions = {};

/*!
 * Inherits from SchemaType.
 */
SchemaDocumentArrayElement.prototype = Object.create(SchemaType.prototype);
SchemaDocumentArrayElement.prototype.constructor = SchemaDocumentArrayElement;

/**
 * Casts `val` for DocumentArrayElement.
 *
 * @param {Object} value to cast
 * @api private
 */

SchemaDocumentArrayElement.prototype.cast = function(...args) {
  return this.$parentSchemaType.cast(...args)[0];
};

/**
 * Casts contents for queries.
 *
 * @param {String} $cond
 * @param {any} [val]
 * @api private
 */

SchemaDocumentArrayElement.prototype.doValidate = function(value, fn, scope, options) {
  const Constructor = getConstructor(this.caster, value);

  if (value && !(value instanceof Constructor)) {
    value = new Constructor(value, scope, null, null, options && options.index != null ? options.index : null);
  }

  return SchemaSubdocument.prototype.doValidate.call(this, value, fn, scope, options);
};

/**
 * Clone the current SchemaType
 *
 * @return {DocumentArrayElement} The cloned instance
 * @api private
 */

SchemaDocumentArrayElement.prototype.clone = function() {
  this.options.$parentSchemaType = this.$parentSchemaType;
  const ret = SchemaType.prototype.clone.apply(this, arguments);
  delete this.options.$parentSchemaType;

  ret.caster = this.caster;
  ret.schema = this.schema;

  return ret;
};

/*!
 * Module exports.
 */

module.exports = SchemaDocumentArrayElement;
