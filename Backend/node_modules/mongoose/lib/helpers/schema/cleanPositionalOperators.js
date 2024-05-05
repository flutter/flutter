'use strict';

/**
 * For consistency's sake, we replace positional operator `$` and array filters
 * `$[]` and `$[foo]` with `0` when looking up schema paths.
 */

module.exports = function cleanPositionalOperators(path) {
  return path.
    replace(/\.\$(\[[^\]]*\])?(?=\.)/g, '.0').
    replace(/\.\$(\[[^\]]*\])?$/g, '.0');
};
