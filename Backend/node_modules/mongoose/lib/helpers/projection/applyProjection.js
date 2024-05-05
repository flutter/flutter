'use strict';

const hasIncludedChildren = require('./hasIncludedChildren');
const isExclusive = require('./isExclusive');
const isInclusive = require('./isInclusive');
const isPOJO = require('../../utils').isPOJO;

module.exports = function applyProjection(doc, projection, _hasIncludedChildren) {
  if (projection == null) {
    return doc;
  }
  if (doc == null) {
    return doc;
  }

  let exclude = null;
  if (isInclusive(projection)) {
    exclude = false;
  } else if (isExclusive(projection)) {
    exclude = true;
  }

  if (exclude == null) {
    return doc;
  } else if (exclude) {
    _hasIncludedChildren = _hasIncludedChildren || hasIncludedChildren(projection);
    return applyExclusiveProjection(doc, projection, _hasIncludedChildren);
  } else {
    _hasIncludedChildren = _hasIncludedChildren || hasIncludedChildren(projection);
    return applyInclusiveProjection(doc, projection, _hasIncludedChildren);
  }
};

function applyExclusiveProjection(doc, projection, hasIncludedChildren, projectionLimb, prefix) {
  if (doc == null || typeof doc !== 'object') {
    return doc;
  }
  const ret = { ...doc };
  projectionLimb = prefix ? (projectionLimb || {}) : projection;

  for (const key of Object.keys(ret)) {
    const fullPath = prefix ? prefix + '.' + key : key;
    if (projection.hasOwnProperty(fullPath) || projectionLimb.hasOwnProperty(key)) {
      if (isPOJO(projection[fullPath]) || isPOJO(projectionLimb[key])) {
        ret[key] = applyExclusiveProjection(ret[key], projection, hasIncludedChildren, projectionLimb[key], fullPath);
      } else {
        delete ret[key];
      }
    } else if (hasIncludedChildren[fullPath]) {
      ret[key] = applyExclusiveProjection(ret[key], projection, hasIncludedChildren, projectionLimb[key], fullPath);
    }
  }
  return ret;
}

function applyInclusiveProjection(doc, projection, hasIncludedChildren, projectionLimb, prefix) {
  if (doc == null || typeof doc !== 'object') {
    return doc;
  }
  const ret = { ...doc };
  projectionLimb = prefix ? (projectionLimb || {}) : projection;

  for (const key of Object.keys(ret)) {
    const fullPath = prefix ? prefix + '.' + key : key;
    if (projection.hasOwnProperty(fullPath) || projectionLimb.hasOwnProperty(key)) {
      if (isPOJO(projection[fullPath]) || isPOJO(projectionLimb[key])) {
        ret[key] = applyInclusiveProjection(ret[key], projection, hasIncludedChildren, projectionLimb[key], fullPath);
      }
      continue;
    } else if (hasIncludedChildren[fullPath]) {
      ret[key] = applyInclusiveProjection(ret[key], projection, hasIncludedChildren, projectionLimb[key], fullPath);
    } else {
      delete ret[key];
    }
  }
  return ret;
}
