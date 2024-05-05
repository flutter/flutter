'use strict';

/**
 * Set a populated virtual value on a document's `$$populatedVirtuals` value
 *
 * @param {*} populatedVirtuals A document's `$$populatedVirtuals`
 * @param {*} name The virtual name
 * @param {*} v The result of the populate query
 * @param {*} options The populate options. This function handles `justOne` and `count` options.
 * @returns {Array<Document>|Document|Object|Array<Object>} the populated virtual value that was set
 */

module.exports = function setPopulatedVirtualValue(populatedVirtuals, name, v, options) {
  if (options.justOne || options.count) {
    populatedVirtuals[name] = Array.isArray(v) ?
      v[0] :
      v;

    if (typeof populatedVirtuals[name] !== 'object') {
      populatedVirtuals[name] = options.count ? v : null;
    }
  } else {
    populatedVirtuals[name] = Array.isArray(v) ?
      v :
      v == null ? [] : [v];

    populatedVirtuals[name] = populatedVirtuals[name].filter(function(doc) {
      return doc && typeof doc === 'object';
    });
  }

  return populatedVirtuals[name];
};
