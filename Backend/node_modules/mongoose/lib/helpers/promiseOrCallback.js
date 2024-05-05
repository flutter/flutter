'use strict';

const immediate = require('./immediate');

const emittedSymbol = Symbol('mongoose#emitted');

module.exports = function promiseOrCallback(callback, fn, ee, Promise) {
  if (typeof callback === 'function') {
    try {
      return fn(function(error) {
        if (error != null) {
          if (ee != null && ee.listeners != null && ee.listeners('error').length > 0 && !error[emittedSymbol]) {
            error[emittedSymbol] = true;
            ee.emit('error', error);
          }
          try {
            callback(error);
          } catch (error) {
            return immediate(() => {
              throw error;
            });
          }
          return;
        }
        callback.apply(this, arguments);
      });
    } catch (error) {
      if (ee != null && ee.listeners != null && ee.listeners('error').length > 0 && !error[emittedSymbol]) {
        error[emittedSymbol] = true;
        ee.emit('error', error);
      }

      return callback(error);
    }
  }

  Promise = Promise || global.Promise;

  return new Promise((resolve, reject) => {
    fn(function(error, res) {
      if (error != null) {
        if (ee != null && ee.listeners != null && ee.listeners('error').length > 0 && !error[emittedSymbol]) {
          error[emittedSymbol] = true;
          ee.emit('error', error);
        }
        return reject(error);
      }
      if (arguments.length > 2) {
        return resolve(Array.prototype.slice.call(arguments, 1));
      }
      resolve(res);
    });
  });
};
