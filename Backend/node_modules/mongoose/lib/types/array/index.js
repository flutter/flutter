/*!
 * Module dependencies.
 */

'use strict';

const Document = require('../../document');
const mongooseArrayMethods = require('./methods');

const arrayAtomicsSymbol = require('../../helpers/symbols').arrayAtomicsSymbol;
const arrayAtomicsBackupSymbol = require('../../helpers/symbols').arrayAtomicsBackupSymbol;
const arrayParentSymbol = require('../../helpers/symbols').arrayParentSymbol;
const arrayPathSymbol = require('../../helpers/symbols').arrayPathSymbol;
const arraySchemaSymbol = require('../../helpers/symbols').arraySchemaSymbol;

/**
 * Mongoose Array constructor.
 *
 * #### Note:
 *
 * _Values always have to be passed to the constructor to initialize, otherwise `MongooseArray#push` will mark the array as modified._
 *
 * @param {Array} values
 * @param {String} path
 * @param {Document} doc parent document
 * @api private
 * @inherits Array https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array
 * @see https://bit.ly/f6CnZU
 */
const _basePush = Array.prototype.push;
const numberRE = /^\d+$/;

function MongooseArray(values, path, doc, schematype) {
  let __array;

  if (Array.isArray(values)) {
    const len = values.length;

    // Perf optimizations for small arrays: much faster to use `...` than `for` + `push`,
    // but large arrays may cause stack overflows. And for arrays of length 0/1, just
    // modifying the array is faster. Seems small, but adds up when you have a document
    // with thousands of nested arrays.
    if (len === 0) {
      __array = new Array();
    } else if (len === 1) {
      __array = new Array(1);
      __array[0] = values[0];
    } else if (len < 10000) {
      __array = new Array();
      _basePush.apply(__array, values);
    } else {
      __array = new Array();
      for (let i = 0; i < len; ++i) {
        _basePush.call(__array, values[i]);
      }
    }
  } else {
    __array = [];
  }

  const internals = {
    [arrayAtomicsSymbol]: {},
    [arrayAtomicsBackupSymbol]: void 0,
    [arrayPathSymbol]: path,
    [arraySchemaSymbol]: schematype,
    [arrayParentSymbol]: void 0,
    isMongooseArray: true,
    isMongooseArrayProxy: true,
    __array: __array
  };

  if (values && values[arrayAtomicsSymbol] != null) {
    internals[arrayAtomicsSymbol] = values[arrayAtomicsSymbol];
  }

  // Because doc comes from the context of another function, doc === global
  // can happen if there was a null somewhere up the chain (see #3020)
  // RB Jun 17, 2015 updated to check for presence of expected paths instead
  // to make more proof against unusual node environments
  if (doc != null && doc instanceof Document) {
    internals[arrayParentSymbol] = doc;
    internals[arraySchemaSymbol] = schematype || doc.schema.path(path);
  }

  const proxy = new Proxy(__array, {
    get: function(target, prop) {
      if (internals.hasOwnProperty(prop)) {
        return internals[prop];
      }
      if (mongooseArrayMethods.hasOwnProperty(prop)) {
        return mongooseArrayMethods[prop];
      }
      if (typeof prop === 'string' && numberRE.test(prop) && schematype?.$embeddedSchemaType != null) {
        return schematype.$embeddedSchemaType.applyGetters(__array[prop], doc);
      }

      return __array[prop];
    },
    set: function(target, prop, value) {
      if (typeof prop === 'string' && numberRE.test(prop)) {
        mongooseArrayMethods.set.call(proxy, prop, value, false);
      } else if (internals.hasOwnProperty(prop)) {
        internals[prop] = value;
      } else {
        __array[prop] = value;
      }

      return true;
    }
  });

  return proxy;
}

/*!
 * Module exports.
 */

module.exports = exports = MongooseArray;
