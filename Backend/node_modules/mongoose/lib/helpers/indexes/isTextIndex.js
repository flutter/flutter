'use strict';

/**
 * Returns `true` if the given index options have a `text` option.
 */

module.exports = function isTextIndex(indexKeys) {
  let isTextIndex = false;
  for (const key of Object.keys(indexKeys)) {
    if (indexKeys[key] === 'text') {
      isTextIndex = true;
    }
  }

  return isTextIndex;
};
