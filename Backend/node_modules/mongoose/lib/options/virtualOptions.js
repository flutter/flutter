'use strict';

const opts = require('./propertyOptions');

class VirtualOptions {
  constructor(obj) {
    Object.assign(this, obj);

    if (obj != null && obj.options != null) {
      this.options = Object.assign({}, obj.options);
    }
  }
}

/**
 * Marks this virtual as a populate virtual, and specifies the model to
 * use for populate.
 *
 * @api public
 * @property ref
 * @memberOf VirtualOptions
 * @type {String|Model|Function}
 * @instance
 */

Object.defineProperty(VirtualOptions.prototype, 'ref', opts);

/**
 * Marks this virtual as a populate virtual, and specifies the path that
 * contains the name of the model to populate
 *
 * @api public
 * @property refPath
 * @memberOf VirtualOptions
 * @type {String|Function}
 * @instance
 */

Object.defineProperty(VirtualOptions.prototype, 'refPath', opts);

/**
 * The name of the property in the local model to match to `foreignField`
 * in the foreign model.
 *
 * @api public
 * @property localField
 * @memberOf VirtualOptions
 * @type {String|Function}
 * @instance
 */

Object.defineProperty(VirtualOptions.prototype, 'localField', opts);

/**
 * The name of the property in the foreign model to match to `localField`
 * in the local model.
 *
 * @api public
 * @property foreignField
 * @memberOf VirtualOptions
 * @type {String|Function}
 * @instance
 */

Object.defineProperty(VirtualOptions.prototype, 'foreignField', opts);

/**
 * Whether to populate this virtual as a single document (true) or an
 * array of documents (false).
 *
 * @api public
 * @property justOne
 * @memberOf VirtualOptions
 * @type {Boolean}
 * @instance
 */

Object.defineProperty(VirtualOptions.prototype, 'justOne', opts);

/**
 * If true, populate just the number of documents where `localField`
 * matches `foreignField`, as opposed to the documents themselves.
 *
 * If `count` is set, it overrides `justOne`.
 *
 * @api public
 * @property count
 * @memberOf VirtualOptions
 * @type {Boolean}
 * @instance
 */

Object.defineProperty(VirtualOptions.prototype, 'count', opts);

/**
 * Add an additional filter to populate, in addition to `localField`
 * matches `foreignField`.
 *
 * @api public
 * @property match
 * @memberOf VirtualOptions
 * @type {Object|Function}
 * @instance
 */

Object.defineProperty(VirtualOptions.prototype, 'match', opts);

/**
 * Additional options to pass to the query used to `populate()`:
 *
 * - `sort`
 * - `skip`
 * - `limit`
 *
 * @api public
 * @property options
 * @memberOf VirtualOptions
 * @type {Object}
 * @instance
 */

Object.defineProperty(VirtualOptions.prototype, 'options', opts);

/**
 * If true, add a `skip` to the query used to `populate()`.
 *
 * @api public
 * @property skip
 * @memberOf VirtualOptions
 * @type {Number}
 * @instance
 */

Object.defineProperty(VirtualOptions.prototype, 'skip', opts);

/**
 * If true, add a `limit` to the query used to `populate()`.
 *
 * @api public
 * @property limit
 * @memberOf VirtualOptions
 * @type {Number}
 * @instance
 */

Object.defineProperty(VirtualOptions.prototype, 'limit', opts);

/**
 * The `limit` option for `populate()` has [some unfortunate edge cases](https://mongoosejs.com/docs/populate.html#query-conditions)
 * when working with multiple documents, like `.find().populate()`. The
 * `perDocumentLimit` option makes `populate()` execute a separate query
 * for each document returned from `find()` to ensure each document
 * gets up to `perDocumentLimit` populated docs if possible.
 *
 * @api public
 * @property perDocumentLimit
 * @memberOf VirtualOptions
 * @type {Number}
 * @instance
 */

Object.defineProperty(VirtualOptions.prototype, 'perDocumentLimit', opts);

module.exports = VirtualOptions;
