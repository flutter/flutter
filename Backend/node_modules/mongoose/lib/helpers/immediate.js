/*!
 * Centralize this so we can more easily work around issues with people
 * stubbing out `process.nextTick()` in tests using sinon:
 * https://github.com/sinonjs/lolex#automatically-incrementing-mocked-time
 * See gh-6074
 */

'use strict';

const nextTick = typeof process !== 'undefined' && typeof process.nextTick === 'function' ?
  process.nextTick.bind(process) :
  cb => setTimeout(cb, 0); // Fallback for browser build

module.exports = function immediate(cb) {
  return nextTick(cb);
};
