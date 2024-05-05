'use strict';

/*!
 * ignore
 */

module.exports = function combinePathErrors(err) {
  const keys = Object.keys(err.errors || {});
  const len = keys.length;
  const msgs = [];
  let key;

  for (let i = 0; i < len; ++i) {
    key = keys[i];
    if (err === err.errors[key]) {
      continue;
    }
    msgs.push(key + ': ' + err.errors[key].message);
  }

  return msgs.join(', ');
};
