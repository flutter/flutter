'use strict';

module.exports = handleTimestampOption;

/*!
 * ignore
 */

function handleTimestampOption(arg, prop) {
  if (arg == null) {
    return null;
  }

  if (typeof arg === 'boolean') {
    return prop;
  }
  if (typeof arg[prop] === 'boolean') {
    return arg[prop] ? prop : null;
  }
  if (!(prop in arg)) {
    return prop;
  }
  return arg[prop];
}
