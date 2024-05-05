'use strict';

var Promise = global.Promise;

/// encapsulate a method with a node-style callback in a Promise
/// @param {object} 'this' of the encapsulated function
/// @param {function} function to be encapsulated
/// @param {Array-like} args to be passed to the called function
/// @return {Promise} a Promise encapsulating the function
module.exports.promise = function (fn, context, args) {

    if (!Array.isArray(args)) {
        args = Array.prototype.slice.call(args);
    }

    if (typeof fn !== 'function') {
        return Promise.reject(new Error('fn must be a function'));
    }

    return new Promise(function(resolve, reject) {
        args.push(function(err, data) {
            if (err) {
                reject(err);
            } else {
                resolve(data);
            }
        });

        fn.apply(context, args);
    });
};

/// @param {err} the error to be thrown
module.exports.reject = function (err) {
    return Promise.reject(err);
};

/// changes the promise implementation that bcrypt uses
/// @param {Promise} the implementation to use
module.exports.use = function(promise) {
  Promise = promise;
};
