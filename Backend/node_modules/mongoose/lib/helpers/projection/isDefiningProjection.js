'use strict';

/*!
 * ignore
 */

module.exports = function isDefiningProjection(val) {
  if (val == null) {
    // `undefined` or `null` become exclusive projections
    return true;
  }
  if (typeof val === 'object') {
    // Only cases where a value does **not** define whether the whole projection
    // is inclusive or exclusive are `$meta` and `$slice`.
    return !('$meta' in val) && !('$slice' in val);
  }
  return true;
};
