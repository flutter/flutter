'use strict';

const MongooseError = require('../../error/mongooseError');
const isPathExcluded = require('../projection/isPathExcluded');
const lookupLocalFields = require('./lookupLocalFields');
const mpath = require('mpath');
const util = require('util');
const utils = require('../../utils');

const hasNumericPropRE = /(\.\d+$|\.\d+\.)/g;

module.exports = function modelNamesFromRefPath(refPath, doc, populatedPath, modelSchema, queryProjection) {
  if (refPath == null) {
    return [];
  }

  if (typeof refPath === 'string' && queryProjection != null && isPathExcluded(queryProjection, refPath)) {
    throw new MongooseError('refPath `' + refPath + '` must not be excluded in projection, got ' +
      util.inspect(queryProjection));
  }

  // If populated path has numerics, the end `refPath` should too. For example,
  // if populating `a.0.b` instead of `a.b` and `b` has `refPath = a.c`, we
  // should return `a.0.c` for the refPath.

  if (hasNumericPropRE.test(populatedPath)) {
    const chunks = populatedPath.split(hasNumericPropRE);

    if (chunks[chunks.length - 1] === '') {
      throw new Error('Can\'t populate individual element in an array');
    }

    let _refPath = '';
    let _remaining = refPath;
    // 2nd, 4th, etc. will be numeric props. For example: `[ 'a', '.0.', 'b' ]`
    for (let i = 0; i < chunks.length; i += 2) {
      const chunk = chunks[i];
      if (_remaining.startsWith(chunk + '.')) {
        _refPath += _remaining.substring(0, chunk.length) + chunks[i + 1];
        _remaining = _remaining.substring(chunk.length + 1);
      } else if (i === chunks.length - 1) {
        _refPath += _remaining;
        _remaining = '';
        break;
      } else {
        throw new Error('Could not normalize ref path, chunk ' + chunk + ' not in populated path');
      }
    }

    const refValue = mpath.get(_refPath, doc, lookupLocalFields);
    let modelNames = Array.isArray(refValue) ? refValue : [refValue];
    modelNames = utils.array.flatten(modelNames);
    return modelNames;
  }

  const refValue = mpath.get(refPath, doc, lookupLocalFields);

  let modelNames;
  if (modelSchema != null && modelSchema.virtuals.hasOwnProperty(refPath)) {
    modelNames = [modelSchema.virtuals[refPath].applyGetters(void 0, doc)];
  } else {
    modelNames = Array.isArray(refValue) ? refValue : [refValue];
  }

  modelNames = utils.array.flatten(modelNames);

  return modelNames;
};
