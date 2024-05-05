'use strict';

/**
 * MongoDB throws an error if there's unused array filters. That is, if `options.arrayFilters` defines
 * a filter, but none of the `update` keys use it. This should be enough to filter out all unused array
 * filters.
 */

module.exports = function removeUnusedArrayFilters(update, arrayFilters) {
  const updateKeys = Object.keys(update).
    map(key => Object.keys(update[key])).
    reduce((cur, arr) => cur.concat(arr), []);
  return arrayFilters.filter(obj => {
    return _checkSingleFilterKey(obj, updateKeys);
  });
};

function _checkSingleFilterKey(arrayFilter, updateKeys) {
  const firstKey = Object.keys(arrayFilter)[0];

  if (firstKey === '$and' || firstKey === '$or') {
    if (!Array.isArray(arrayFilter[firstKey])) {
      return false;
    }
    return arrayFilter[firstKey].find(filter => _checkSingleFilterKey(filter, updateKeys)) != null;
  }

  const firstDot = firstKey.indexOf('.');
  const arrayFilterKey = firstDot === -1 ? firstKey : firstKey.slice(0, firstDot);

  return updateKeys.find(key => key.includes('$[' + arrayFilterKey + ']')) != null;
}
