'use strict';

const MongooseMap = require('../../types/map');
const SkipPopulateValue = require('./skipPopulateValue');
const assignRawDocsToIdStructure = require('./assignRawDocsToIdStructure');
const get = require('../get');
const getVirtual = require('./getVirtual');
const leanPopulateMap = require('./leanPopulateMap');
const lookupLocalFields = require('./lookupLocalFields');
const markArraySubdocsPopulated = require('./markArraySubdocsPopulated');
const mpath = require('mpath');
const sift = require('sift').default;
const utils = require('../../utils');
const { populateModelSymbol } = require('../symbols');

module.exports = function assignVals(o) {
  // Options that aren't explicitly listed in `populateOptions`
  const userOptions = Object.assign({}, get(o, 'allOptions.options.options'), get(o, 'allOptions.options'));
  // `o.options` contains options explicitly listed in `populateOptions`, like
  // `match` and `limit`.
  const populateOptions = Object.assign({}, o.options, userOptions, {
    justOne: o.justOne,
    isVirtual: o.isVirtual
  });
  populateOptions.$nullIfNotFound = o.isVirtual;
  const populatedModel = o.populatedModel;

  const originalIds = [].concat(o.rawIds);

  // replace the original ids in our intermediate _ids structure
  // with the documents found by query
  o.allIds = [].concat(o.allIds);
  assignRawDocsToIdStructure(o.rawIds, o.rawDocs, o.rawOrder, populateOptions);

  // now update the original documents being populated using the
  // result structure that contains real documents.
  const docs = o.docs;
  const rawIds = o.rawIds;
  const options = o.options;
  const count = o.count && o.isVirtual;
  let i;
  let setValueIndex = 0;

  function setValue(val) {
    ++setValueIndex;
    if (count) {
      return val;
    }
    if (val instanceof SkipPopulateValue) {
      return val.val;
    }
    if (val === void 0) {
      return val;
    }

    const _allIds = o.allIds[i];

    if (o.path.endsWith('.$*')) {
      // Skip maps re: gh-12494
      return valueFilter(val, options, populateOptions, _allIds);
    }

    if (o.justOne === true && Array.isArray(val)) {
      // Might be an embedded discriminator (re: gh-9244) with multiple models, so make sure to pick the right
      // model before assigning.
      const ret = [];
      for (const doc of val) {
        const _docPopulatedModel = leanPopulateMap.get(doc);
        if (_docPopulatedModel == null || _docPopulatedModel === populatedModel) {
          ret.push(doc);
        }
      }
      // Since we don't want to have to create a new mongoosearray, make sure to
      // modify the array in place
      while (val.length > ret.length) {
        Array.prototype.pop.apply(val, []);
      }
      for (let i = 0; i < ret.length; ++i) {
        val[i] = ret[i];
      }

      return valueFilter(val[0], options, populateOptions, _allIds);
    } else if (o.justOne === false && !Array.isArray(val)) {
      return valueFilter([val], options, populateOptions, _allIds);
    } else if (o.justOne === true && !Array.isArray(val) && Array.isArray(_allIds)) {
      return valueFilter(val, options, populateOptions, val == null ? val : _allIds[setValueIndex - 1]);
    }
    return valueFilter(val, options, populateOptions, _allIds);
  }

  for (i = 0; i < docs.length; ++i) {
    setValueIndex = 0;
    const _path = o.path.endsWith('.$*') ? o.path.slice(0, -3) : o.path;
    const existingVal = mpath.get(_path, docs[i], lookupLocalFields);
    if (existingVal == null && !getVirtual(o.originalModel.schema, _path)) {
      continue;
    }

    let valueToSet;
    if (count) {
      valueToSet = numDocs(rawIds[i]);
    } else if (Array.isArray(o.match)) {
      valueToSet = Array.isArray(rawIds[i]) ?
        rawIds[i].filter(v => v == null || sift(o.match[i])(v)) :
        [rawIds[i]].filter(v => v == null || sift(o.match[i])(v))[0];
    } else {
      valueToSet = rawIds[i];
    }

    // If we're populating a map, the existing value will be an object, so
    // we need to transform again
    const originalSchema = o.originalModel.schema;
    const isDoc = get(docs[i], '$__', null) != null;
    let isMap = isDoc ?
      existingVal instanceof Map :
      utils.isPOJO(existingVal);
    // If we pass the first check, also make sure the local field's schematype
    // is map (re: gh-6460)
    isMap = isMap && get(originalSchema._getSchema(_path), '$isSchemaMap');
    if (!o.isVirtual && isMap) {
      const _keys = existingVal instanceof Map ?
        Array.from(existingVal.keys()) :
        Object.keys(existingVal);
      valueToSet = valueToSet.reduce((cur, v, i) => {
        cur.set(_keys[i], v);
        return cur;
      }, new Map());
    }

    if (isDoc && Array.isArray(valueToSet)) {
      for (const val of valueToSet) {
        if (val != null && val.$__ != null) {
          val.$__.parent = docs[i];
        }
      }
    } else if (isDoc && valueToSet != null && valueToSet.$__ != null) {
      valueToSet.$__.parent = docs[i];
    }

    if (o.isVirtual && isDoc) {
      docs[i].$populated(_path, o.justOne ? originalIds[0] : originalIds, o.allOptions);
      // If virtual populate and doc is already init-ed, need to walk through
      // the actual doc to set rather than setting `_doc` directly
      if (Array.isArray(valueToSet)) {
        valueToSet = valueToSet.map(v => v == null ? void 0 : v);
      }
      mpath.set(_path, valueToSet, docs[i], void 0, setValue, false);
      continue;
    }

    const parts = _path.split('.');
    let cur = docs[i];
    for (let j = 0; j < parts.length - 1; ++j) {
      // If we get to an array with a dotted path, like `arr.foo`, don't set
      // `foo` on the array.
      if (Array.isArray(cur) && !utils.isArrayIndex(parts[j])) {
        break;
      }

      if (parts[j] === '$*') {
        break;
      }

      if (cur[parts[j]] == null) {
        // If nothing to set, avoid creating an unnecessary array. Otherwise
        // we'll end up with a single doc in the array with only defaults.
        // See gh-8342, gh-8455
        const curPath = parts.slice(0, j + 1).join('.');
        const schematype = originalSchema._getSchema(curPath);
        if (valueToSet == null && schematype != null && schematype.$isMongooseArray) {
          break;
        }
        cur[parts[j]] = {};
      }
      cur = cur[parts[j]];
      // If the property in MongoDB is a primitive, we won't be able to populate
      // the nested path, so skip it. See gh-7545
      if (typeof cur !== 'object') {
        break;
      }
    }
    if (docs[i].$__) {
      o.allOptions.options[populateModelSymbol] = o.allOptions.model;
      docs[i].$populated(_path, o.unpopulatedValues[i], o.allOptions.options);

      if (valueToSet != null && valueToSet.$__ != null) {
        valueToSet.$__.wasPopulated = { value: o.unpopulatedValues[i] };
      }

      if (valueToSet instanceof Map && !valueToSet.$isMongooseMap) {
        valueToSet = new MongooseMap(valueToSet, _path, docs[i], docs[i].schema.path(_path).$__schemaType);
      }
    }

    // If lean, need to check that each individual virtual respects
    // `justOne`, because you may have a populated virtual with `justOne`
    // underneath an array. See gh-6867
    mpath.set(_path, valueToSet, docs[i], lookupLocalFields, setValue, false);

    if (docs[i].$__) {
      markArraySubdocsPopulated(docs[i], [o.allOptions.options]);
    }
  }
};

function numDocs(v) {
  if (Array.isArray(v)) {
    // If setting underneath an array of populated subdocs, we may have an
    // array of arrays. See gh-7573
    if (v.some(el => Array.isArray(el) || el === null)) {
      return v.map(el => {
        if (el == null) {
          return 0;
        }
        if (Array.isArray(el)) {
          return el.filter(el => el != null).length;
        }
        return 1;
      });
    }
    return v.filter(el => el != null).length;
  }
  return v == null ? 0 : 1;
}

/**
 * 1) Apply backwards compatible find/findOne behavior to sub documents
 *
 *    find logic:
 *      a) filter out non-documents
 *      b) remove _id from sub docs when user specified
 *
 *    findOne
 *      a) if no doc found, set to null
 *      b) remove _id from sub docs when user specified
 *
 * 2) Remove _ids when specified by users query.
 *
 * background:
 * _ids are left in the query even when user excludes them so
 * that population mapping can occur.
 * @param {Any} val
 * @param {Object} assignmentOpts
 * @param {Object} populateOptions
 * @param {Function} [populateOptions.transform]
 * @param {Boolean} allIds
 * @api private
 */

function valueFilter(val, assignmentOpts, populateOptions, allIds) {
  const userSpecifiedTransform = typeof populateOptions.transform === 'function';
  const transform = userSpecifiedTransform ? populateOptions.transform : noop;
  if (Array.isArray(val)) {
    // find logic
    const ret = [];
    const numValues = val.length;
    for (let i = 0; i < numValues; ++i) {
      let subdoc = val[i];
      const _allIds = Array.isArray(allIds) ? allIds[i] : allIds;
      if (!isPopulatedObject(subdoc) && (!populateOptions.retainNullValues || subdoc != null) && !userSpecifiedTransform) {
        continue;
      } else if (!populateOptions.retainNullValues && subdoc == null) {
        continue;
      } else if (userSpecifiedTransform) {
        subdoc = transform(isPopulatedObject(subdoc) ? subdoc : null, _allIds);
      }
      maybeRemoveId(subdoc, assignmentOpts);
      ret.push(subdoc);
      if (assignmentOpts.originalLimit &&
          ret.length >= assignmentOpts.originalLimit) {
        break;
      }
    }

    const rLen = ret.length;
    // Since we don't want to have to create a new mongoosearray, make sure to
    // modify the array in place
    while (val.length > rLen) {
      Array.prototype.pop.apply(val, []);
    }
    let i = 0;
    if (utils.isMongooseArray(val)) {
      for (i = 0; i < rLen; ++i) {
        val.set(i, ret[i], true);
      }
    } else {
      for (i = 0; i < rLen; ++i) {
        val[i] = ret[i];
      }
    }
    return val;
  }

  // findOne
  if (isPopulatedObject(val) || utils.isPOJO(val)) {
    maybeRemoveId(val, assignmentOpts);
    return transform(val, allIds);
  }
  if (val instanceof Map) {
    return val;
  }

  if (populateOptions.justOne === false) {
    return [];
  }

  return val == null ? transform(val, allIds) : transform(null, allIds);
}

/**
 * Remove _id from `subdoc` if user specified "lean" query option
 * @param {Document} subdoc
 * @param {Object} assignmentOpts
 * @api private
 */

function maybeRemoveId(subdoc, assignmentOpts) {
  if (subdoc != null && assignmentOpts.excludeId) {
    if (typeof subdoc.$__setValue === 'function') {
      delete subdoc._doc._id;
    } else {
      delete subdoc._id;
    }
  }
}

/**
 * Determine if `obj` is something we can set a populated path to. Can be a
 * document, a lean document, or an array/map that contains docs.
 * @param {Any} obj
 * @api private
 */

function isPopulatedObject(obj) {
  if (obj == null) {
    return false;
  }

  return Array.isArray(obj) ||
    obj.$isMongooseMap ||
    obj.$__ != null ||
    leanPopulateMap.has(obj);
}

function noop(v) {
  return v;
}
