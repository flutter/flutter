'use strict';

const SchemaTypeOptions = require('./schemaTypeOptions');

/**
 * The options defined on a string schematype.
 *
 * #### Example:
 *
 *     const schema = new Schema({ name: String });
 *     schema.path('name').options; // SchemaStringOptions instance
 *
 * @api public
 * @inherits SchemaTypeOptions
 * @constructor SchemaStringOptions
 */

class SchemaStringOptions extends SchemaTypeOptions {}

const opts = require('./propertyOptions');

/**
 * Array of allowed values for this path
 *
 * @api public
 * @property enum
 * @memberOf SchemaStringOptions
 * @type {Array}
 * @instance
 */

Object.defineProperty(SchemaStringOptions.prototype, 'enum', opts);

/**
 * Attach a validator that succeeds if the data string matches the given regular
 * expression, and fails otherwise.
 *
 * @api public
 * @property match
 * @memberOf SchemaStringOptions
 * @type {RegExp}
 * @instance
 */

Object.defineProperty(SchemaStringOptions.prototype, 'match', opts);

/**
 * If truthy, Mongoose will add a custom setter that lowercases this string
 * using JavaScript's built-in `String#toLowerCase()`.
 *
 * @api public
 * @property lowercase
 * @memberOf SchemaStringOptions
 * @type {Boolean}
 * @instance
 */

Object.defineProperty(SchemaStringOptions.prototype, 'lowercase', opts);

/**
 * If truthy, Mongoose will add a custom setter that removes leading and trailing
 * whitespace using [JavaScript's built-in `String#trim()`](https://masteringjs.io/tutorials/fundamentals/trim-string).
 *
 * @api public
 * @property trim
 * @memberOf SchemaStringOptions
 * @type {Boolean}
 * @instance
 */

Object.defineProperty(SchemaStringOptions.prototype, 'trim', opts);

/**
 * If truthy, Mongoose will add a custom setter that uppercases this string
 * using JavaScript's built-in [`String#toUpperCase()`](https://masteringjs.io/tutorials/fundamentals/uppercase).
 *
 * @api public
 * @property uppercase
 * @memberOf SchemaStringOptions
 * @type {Boolean}
 * @instance
 */

Object.defineProperty(SchemaStringOptions.prototype, 'uppercase', opts);

/**
 * If set, Mongoose will add a custom validator that ensures the given
 * string's `length` is at least the given number.
 *
 * Mongoose supports two different spellings for this option: `minLength` and `minlength`.
 * `minLength` is the recommended way to specify this option, but Mongoose also supports
 * `minlength` (lowercase "l").
 *
 * @api public
 * @property minLength
 * @memberOf SchemaStringOptions
 * @type {Number}
 * @instance
 */

Object.defineProperty(SchemaStringOptions.prototype, 'minLength', opts);
Object.defineProperty(SchemaStringOptions.prototype, 'minlength', opts);

/**
 * If set, Mongoose will add a custom validator that ensures the given
 * string's `length` is at most the given number.
 *
 * Mongoose supports two different spellings for this option: `maxLength` and `maxlength`.
 * `maxLength` is the recommended way to specify this option, but Mongoose also supports
 * `maxlength` (lowercase "l").
 *
 * @api public
 * @property maxLength
 * @memberOf SchemaStringOptions
 * @type {Number}
 * @instance
 */

Object.defineProperty(SchemaStringOptions.prototype, 'maxLength', opts);
Object.defineProperty(SchemaStringOptions.prototype, 'maxlength', opts);

/**
 * Sets default [populate options](https://mongoosejs.com/docs/populate.html#query-conditions).
 *
 * @api public
 * @property populate
 * @memberOf SchemaStringOptions
 * @type {Object}
 * @instance
 */

Object.defineProperty(SchemaStringOptions.prototype, 'populate', opts);

/*!
 * ignore
 */

module.exports = SchemaStringOptions;
