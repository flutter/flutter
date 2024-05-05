'use strict';

/*!
 * ignore
 */

module.exports = function isPathSelectedInclusive(fields, path) {
  const chunks = path.split('.');
  let cur = '';
  let j;
  let keys;
  let numKeys;
  for (let i = 0; i < chunks.length; ++i) {
    cur += cur.length ? '.' : '' + chunks[i];
    if (fields[cur]) {
      keys = Object.keys(fields);
      numKeys = keys.length;
      for (j = 0; j < numKeys; ++j) {
        if (keys[i].indexOf(cur + '.') === 0 && keys[i].indexOf(path) !== 0) {
          continue;
        }
      }
      return true;
    }
  }

  return false;
};
